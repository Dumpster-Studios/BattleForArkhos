-- Rocket Science for BfA:
-- Author: Jordach
-- License: Reserved

local r_block_chance = 100
local inside_chance = 100
local outside_chance = 90

local function rocket_explode_damage_blocks(pos)
	local bpos = table.copy(pos)
	local weapon = table.copy(minetest.registered_nodes["weapons:rocket_launcher"])
	for x=-2, 2 do
		for y=-2, 2 do
			for z=-2, 2 do
				local npos = {x=bpos.x+x, y=bpos.y+y, z=bpos.z+z}
				local nodedef = table.copy(minetest.registered_nodes[minetest.get_node(npos).name])
				weapon._block_chance = r_block_chance
				if x == -2 or x == 2 then
					weapon._block_chance = outside_chance
					if y == -2 or y == 2 then
						if z == -2 or z == 2 then
							-- Remove corners
							weapon._block_chance = 0
						end
					end
				elseif z == -2 or z == 2 then
					weapon._block_chance = outside_chance
				elseif x == -1 or x == 1 then
					weapon._block_chance = inside_chance
				elseif z == -1 or z == 1 then
					weapon._block_chance = inside_chance
				end

				local damage, node, result = weapons.calc_block_damage(nodedef, weapon, npos, nil)
				local p2 = minetest.get_node(npos).param2
				minetest.set_node(npos, {name=node, param2=p2})
				minetest.check_for_falling(npos)
			end
		end
	end
end

local function launch_rocket(player, weapon)
	-- Handle recoil of the equipped weapon
	--solarsail.util.functions.apply_recoil(player, weapon)

	local pname = player:get_player_name()
	local ammo = weapon._ammo_type

	if weapons.player_list[pname][ammo] > 0 then
		weapons.player_list[pname][ammo] = weapons.player_list[pname][ammo] - 1

		local rocket_pos = vector.add(
			vector.add(player:get_pos(), vector.new(0, weapons.default_eye_height, 0)), 
				vector.multiply(player:get_look_dir(), 1)
		)

		local rocket_vel = vector.multiply(player:get_look_dir(), 20)

		local ent = minetest.add_entity(rocket_pos, "weapons:rocket_ent")
		local luaent = ent:get_luaentity()
		luaent._player_ref = player
		luaent._loop_sound_ref = 
				minetest.sound_play({name="rocket_fly"}, 
					{object=ent, max_hear_distance=32, gain=1.2, loop=true})

		-- Commit audio suicide when attached audio stops working:tm:
		minetest.after(15, minetest.sound_stop, luaent._loop_sound_ref)
		local look_vertical = player:get_look_vertical()
		local look_horizontal = player:get_look_horizontal()
		
		ent:set_velocity(rocket_vel)
		ent:set_rotation(vector.new(-look_vertical, look_horizontal, 0))
		weapons.veteran_reload(player, weapon, player:get_wielded_item():get_name()
		, false)
	end
end

local rocket_ent = {
	visual = "mesh",
	mesh = "rocket_ent.obj",
	textures = {
		"rocket_ent.png",
	},
	physical = true,
	collide_with_objects = true,
	pointable = false,
	collision_box = {-0.15, -0.15, -0.15, 0.15, 0.15, 0.15},
	visual_size = {x=5, y=5},
	_player_ref = nil,
	_loop_sound_ref = nil,
	_timer = 0,
	_stimer = 2
}

function rocket_ent:explode(self, moveresult)
	if self._player_ref == nil then 
		self.object:remove()
		return
	end

	local pos = self.object:get_pos()
	local pos_block, collided = {}, false

	if moveresult.collisions[1] == nil then
		pos_block = table.copy(self.object:get_pos())
		pos_block.x = math.floor(pos_block.x)
		pos_block.y = math.floor(pos_block.y)
		pos_block.z = math.floor(pos_block.z)
	else
		for index, coll_table in pairs(moveresult.collisions) do
			if moveresult.collisions[index].type == "object" then
				if moveresult.collisions[index].object:is_player() then
					collided = true
					local col_pos = moveresult.collisions[index].object:get_pos()
					pos_block = vector.new(
						math.floor(col_pos.x),
						math.floor(col_pos.y),
						math.floor(col_pos.z)
					)
					 -- If we find a player that we did collide with, deal extra damage and finish this loop
					 -- otherwise we continue searching the list of possible players, else we just explode
					 -- at our current position.
					break
				else
					pos_block = vector.new(
						math.floor(pos.x),
						math.floor(pos.y),
						math.floor(pos.z)
					)
				end
			elseif moveresult.collisions[index].type == "node" then
				pos_block = table.copy(moveresult.collisions[1].node_pos)
			end
		end
	end

	local node = minetest.registered_nodes[minetest.get_node(pos).name]
	local rocket = table.copy(minetest.registered_nodes["weapons:rocket_launcher"])

	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local pname = player:get_player_name()
		local dist = solarsail.util.functions.pos_to_dist(pos, ppos)
		if dist < 4.01 then
			if player == self._player_ref then
				rocket._damage = math.floor(rocket._damage / 2.75)
				weapons.handle_damage(rocket, self._player_ref, player, dist, nil)
			else
				dist = solarsail.util.functions.pos_to_dist(self._player_ref:get_pos(), ppos)
				if collided then
					rocket._damage = rocket._damage_direct
					weapons.handle_damage(rocket, self._player_ref, player, dist, nil)
				else
					weapons.handle_damage(rocket, self._player_ref, player, dist, nil)
				end
			end
			-- Add player knockback:
			solarsail.util.functions.apply_explosion_recoil(player, 25, pos)
		end
	end

	rocket_explode_damage_blocks(pos_block)

	minetest.sound_play({name="rocket_explode"}, 
		{pos=pos_block, max_hear_distance=96, gain=7}, true)

	if self._loop_sound_ref ~= nil then
		minetest.sound_stop(self._loop_sound_ref)
	end
	self.object:remove()
end

function rocket_ent:on_step(dtime, moveresult)
	if moveresult.collides then
		rocket_ent:explode(self, moveresult)
		return
	elseif self._timer > 15 then
		rocket_ent:explode(self, moveresult)
		return
	end
	local vel = self.object:get_velocity()
	if vel == nil then
	else
		vel.x = vel.x * 1.01
		vel.y = vel.y * 1.01
		vel.z = vel.z * 1.01
		self.object:set_velocity(vel)
	end

	self._timer = self._timer + dtime
	self._stimer = self._stimer + dtime

	if self._stimer > 0.15 then
		local tex = {}
		for i=1, 6 do
			tex[i] = weapons.create_2x2_node_texture("rocket_smoke_cubic.png")
		end
		local nvel = vector.new(0, 0.25, 0)

		local props = {
			pos = self.object:get_pos(),
			vel = nvel,
			offset_min = -0.15,
			offset_max = 0.15,
			vel_min = -0.5,
			vel_max = 0.5,
			size_min = 2.5,
			size_max = 3.25,
		}
		particulate.spawn_gas_particles("weapons:smoke_particle", 2, props, tex)
		self._stimer = 0
	end
end

minetest.register_entity("weapons:rocket_ent", rocket_ent)

local rl_name = "SPNKr Model X"
local chance = math.random(1, 20)
if chance == 1 then
	rl_name = "Locket Rauncher"
elseif chance == 2 then
	rl_name = "Rocket LawnChair"
end

weapons.register_weapon("weapons:rocket_launcher", true, {
	-- Config
	_type = "gun",
	_ammo_type = "single_rocket",
	_slot = "primary",
	_localisation = {
		itemstring = "weapons:rocket_launcher",
		name = rl_name,
		tooltip = rl_name ..
[[

Stats:
65 Splash Damage.
185 Direct Hit Damage.
3.4 second reload.
Explodes after 6 seconds of flight.
Accelerates as it moves faster.

TIP: These rockets hurt you less, and can be used to propel you to greater heights.]],
		preview = "preview_spnkrx.obj"
	},

	-- HUD stuff.
	_name = "rocket_launcher",
	_crosshair = "railgun_crosshair.png",
	_crosshair_aim = "railgun_crosshair.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.5,
	_min_arm_angle = -65,
	_max_arm_angle = 70,
	_arm_angle_offset = 0,
	
	-- Sound:
	_firing_sound = "rocket_launch",
	_reload_sound = "rocket_reload",
	_reload_sound_alt = "rocket_swap",

	-- Base Stats:
	_pellets = 1,
	_mag = 2,
	_rpm = 95,
	_reload = 3.43,
	_damage = 65,
	_damage_direct = 185,
	_movespeed = 0.75,
	_movespeed_aim = 0.45,

	_fatigue = 0,
	_fatigue_timer = 0.1,
	_fatigue_recovery = 0.99,

	_break_hits = 4,
	_block_chance = 98,

	-- Arm Animations + Arm visual settings;
	_anim = {
		idle = {x=0, y=179},
		idle_fire = {x=190, y=225},
		aim = {x=0, y=179},
		aim_fire = {x=190, y=225},
		reload = {x=270, y=476},
		reload_alt = {x=270, y=476},
	},
	_arms = {
		mesh = "arms_spnkrx.x",
		skin_pos = 1,
		textures = {"transarent.png", "rubber.png", "steel_dark.png", "steel_grey.png^SPNKR.png", "steel_light.png", "warning_mark.png"},
	},
	on_fire = launch_rocket,
	on_reload = function(player, weapon, wield, keypressed)
		weapons.magazine_reload(player, weapon, wield, false)
	end,
})