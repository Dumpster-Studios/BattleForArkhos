local wep_rpm = 325
local shots_used = 1

local plas_ent = {
	visual = "mesh",
	mesh = "par_bolt.b3d",
	textures = {"plasma_autorifle_bolt.png"},
	physical = true,
	collide_with_objects = true,
	pointable = false,
	collision_box = {-0.05, -0.05, -0.05, 0.05, 0.05, 0.05},
	visual_size = {x=2, y=2},
	_player_ref = nil,
	_timer = nil,
	backface_culling = true,
	glow = -1
}

local function dmg_block(pos, weapon)
	local damage, node, result =
		weapons.calc_block_damage(minetest.registered_nodes[minetest.get_node(pos).name], weapon, pos)
	local p2 = minetest.get_node(pos).param2
	minetest.set_node(pos, {name=node, param2=p2})
end

function plas_ent:collide(self, moveresult)
	local pos = self.object:get_pos()

	local pos_block
	if moveresult.collisions[1] == nil then
	elseif moveresult.collisions[1].type == "node" then
		pos_block = table.copy(moveresult.collisions[1].node_pos)
		dmg_block(pos_block, minetest.registered_nodes["weapons:plasma_autorifle"])
	end
	
	if self._player_ref == nil then 
		self.object:remove()
		return
	end
	
	local weapon = minetest.registered_nodes["weapons:plasma_autorifle"]
	
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local dist = solarsail.util.functions.pos_to_dist(pos, ppos)
		if dist < 0.2 then
			if  self._player_ref == nil then
			elseif player == self._player_ref then
				return
			else
				dist = solarsail.util.functions.pos_to_dist(self._player_ref:get_pos(), ppos)
				weapons.handle_damage(weapon, self._player_ref, player, dist)
			end
		end
	end
	self.object:remove()
end

function plas_ent:on_step(dtime, moveresult)
	if moveresult.collides then
		plas_ent:collide(self, moveresult)
	elseif self._timer == nil then
		return
	elseif self._timer > 15 then
		self.object:remove()
	else
		self._timer = self._timer + dtime
	end
end

minetest.register_entity("weapons:par_bolt", plas_ent)

local function shoot_plasma(player, weapon)
	local pname = player:get_player_name()
	local ammo = weapon._ammo_type
	if weapons.player_list[pname][ammo] < 100 then 
		local plas_pos = vector.add(
			vector.add(player:get_pos(), vector.new(0, 1.2, 0)), 
				vector.multiply(player:get_look_dir(), 1)
		)

		local aim_diff    
		if weapons.player_list[pname].aim_mode then
			aim_diff = vector.new(
				math.random(-weapon._spread_aim * 100, weapon._spread_aim * 100) / 100,
				math.random(-weapon._spread_aim * 100, weapon._spread_aim * 100) / 100,
				math.random(-weapon._spread_aim * 100, weapon._spread_aim * 100) / 100
			)
		else
			aim_diff = vector.new(
				math.random(-weapon._spread * 100, weapon._spread * 100) / 100,
				math.random(-weapon._spread * 100, weapon._spread * 100) / 100,
				math.random(-weapon._spread * 100, weapon._spread * 100) / 100
			)
		end

		local plas_vel = vector.add(
			vector.multiply(player:get_look_dir(), 85), vector.add(aim_diff, vector.new(0, weapons.default_eye_height-1.2, 0))
		)

		local ent = minetest.add_entity(plas_pos, "weapons:par_bolt")
		ent:set_velocity(plas_vel)
		ent:set_rotation(vector.new(-player:get_look_vertical(), player:get_look_horizontal(), 0))
		local luaent = ent:get_luaentity()
		luaent._player_ref = player
		luaent._timer = 0

		local perc
		if weapons.player_list[pname][ammo] == 0 then
			perc = 1
		else
			perc = weapons.player_list[pname][ammo]/15
		end
		local res = math.floor(weapons.player_list[pname][ammo] + perc) + 2
		if res > 99 then
			res = 100
			weapon.on_reload(player, weapon, player:get_wielded_item():get_name(), false)
		end
		weapons.player_list[pname][ammo] = res
		minetest.sound_play({name=weapon._firing_sound}, 
			{pos=player:get_pos(), max_hear_distance=128, gain=1.75, pitch=math.random(85, 115)/100})
		-- Handle recoil of the equipped weapon
		solarsail.util.functions.apply_recoil(player, weapon)
	end
end

weapons.register_weapon("weapons:plasma_autorifle", true,
{
	-- Config
	_type = "gun",
	_ammo_type = "plasma_autorifle",
	_is_energy = true,
	_heat_accelerated = true,
	_accel_mult = 3.5,
	_cool_rate = 0.95,
	_cool_timer = 0.075,
	_slot = "primary",
	_localisation = {
		itemstring = "weapons:plasma_autorifle",
		name = "Plasma Autorifle",
		tooltip =
[[A standard plasma autorifle. Good at short to medium range.

Stats:

25 Damage.
Unaimed spread +- 7 nodes at maximum range.
Aimed spread +- 0.5 nodes at maximum range.
Range 150 nodes.]],
	},

	-- HUD / Visual
	_name = "plasma_autorifle",
	_crosshair = "assault_crosshair.png",
	_crosshair_aim = "railgun_crosshair.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.6,
	_min_arm_angle = -45,
	_max_arm_angle = 75,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "par_fire",
	_reload_sound = "par_reload",
	--_casing = "Armature_Casing",
	
	-- Base Stats:
	_pellets = 1,
	_mag = 0,
	_rpm = wep_rpm,
	_reload = 2.65,
	--_speed = 1200,
	--_range = 150,
	_damage = 10,
	_movespeed = 0.95,
	_movespeed_aim = 0.45,
	_shots_used = shots_used,

	_recoil = 2.5/1.5,
	_recoil_vert_min = 1/1.5,
	_recoil_vert_max = 2.25/1.5,
	_recoil_hori = 3/1.5,
	_recoil_factor = 0.8/1.5,
	_recoil_aim_factor = 0.5/1.5,
	
	_break_hits = 1,
	_block_chance = 75,
	_spread = 6.5,
	_spread_aim = 0.5,

	-- Arm Animations + Arm visual settings;
	_anim = {
		idle = {x=0, y=0},
		idle_fire = {x=0, y=8},
		aim = {x=10, y=10},
		aim_fire = {x=10, y=18},
		reload = {x=60, y=219}
	},
	_arms = {
		mesh = "assault_arms.x",
		texture = "assault_rifle.png",
	},
	on_fire = shoot_plasma,
	on_reload = weapons.energy_overheat,
	--on_fire_visual = nil,
	--bullet_on_hit = weapons.bullet_on_hit,
})