-- Boring Pistol for BfA
-- Author: Jordach
-- License: RESERVED

-- Spamshrapnel
local sharapnel = {
	visual = "sprite",
	texture = "spamton_projectile.png",

}

-- Grenade entity
local pipis_grenade = {
    visual = "mesh",
    mesh = "particulate_cubic.obj",
    textures = {"core_ice.png", "core_ice.png", "core_ice.png", "core_ice.png", "core_ice.png", "core_ice.png"},
	visual_size = {x=5, y=5},
    physical = true,
    collide_with_objects = true,
    pointable = true,
    collisionbox = {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
    _ttl = 15,
    _timer = 0,
    _owner = "",
    _weapon_name = "weapons:pipis_cannon"
}

function pipis_grenade:explode(self, movereuslt)

end

function pipis_grenade:on_step(dtime, moveresult, target)
	if self._timer > self._ttl or self._owner == "" then
		self.object:remove()
		return
	end
	self._timer = self._timer + dtime

	local pos = self.object:get_pos()
	local nearby = minetest.get_objects_inside_radius(pos, 3)
	for k, nobject in ipairs(nearby) do
		if nobject == nil then
		elseif nobject:is_player() then
			local pname = self._owner:get_player_name()
			local tname = nobject:get_player_name()
			-- Explode and scatter 
			if weapons.player_list[pname].team ~= weapons.player_list[tname].team then
				self:explode(moveresult, nobject)
				return
			end
		end
	end
	
	local velocity = {x=0, y=0, z=0}
	if moveresult.collides then
		local pname = self._owner:get_player_name()
		local old_vel 
		-- Check for velocities:
		if moveresult.collisions[1] == nil then
			return
		else
			if moveresult.collisions[1].type == "object" then
				if moveresult.collisions[1].object:is_player() then
					local tname = moveresult.collisions[1].object:get_player_name()
					
					-- Heal teammates on impact
					if weapons.player_list[pname].team == weapons.player_list[tname].team then
						weapons.handle_damage({_heals=math.random(-10, 50), _damage=5}, self._owner, moveresult.collisions[1].object, 0, nil)
						self.object:remove()
						return
					end
				end
			end
			old_vel = table.copy(moveresult.collisions[1].old_velocity)
		end
		-- Handle air resistance, friction:
		if moveresult.touching_ground then
			old_vel.x = old_vel.x * math.random(75, 85) / 100
			old_vel.z = old_vel.z * math.random(75, 85) / 100
		else
			old_vel.x = old_vel.x * math.random(90, 100) / 100
			old_vel.z = old_vel.z * math.random(90, 100) / 100
		end
		local factor = math.random(90, 130) / 100
		if moveresult.collisions[1] == nil then
			if not moveresult.touching_ground then
				velocity.x = old_vel.x
				velocity.z = old_vel.z
			end
			velocity.y = old_vel.y
		end
		if moveresult.collisions[1].axis == "y" then
			velocity.x = old_vel.x * math.random(95, 105) / 100
			velocity.y = -(old_vel.y * math.random(90, 110) / 100)
			velocity.z = old_vel.z * math.random(95, 105) / 100
			if math.abs(old_vel.y) > 0.38 then
				-- minetest.sound_play({name = self._sound_name}, 
				-- 	{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
			end
		else
			if moveresult.collisions[1].axis == "x" then
				velocity.x = -(old_vel.x * factor)
				velocity.y = old_vel.y
				velocity.z = old_vel.z
				-- minetest.sound_play({name = self._sound_name}, 
				-- 	{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
			end
			if moveresult.collisions[1].axis == "z" then
				velocity.x = old_vel.x
				velocity.y = old_vel.y
				velocity.z = -(old_vel.z * factor)
				-- minetest.sound_play({name = self._sound_name}, 
				-- 	{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
			end
		end
		self.object:set_velocity(velocity)
	end
end

minetest.register_entity("weapons:pipis_grenade", pipis_grenade)

-- on_fire() function
local function launch_pipis(player, weapon)
	local pname = player:get_player_name()
	local ammo = weapon._ammo_type
	if weapons.player_list[pname][ammo] <= 100 then
		-- Fire on mouse up event, otherwise add more charge;
		if not solarsail.controls.player[pname].LMB and weapons.player_list[pname][ammo] > 0 then
			minetest.sound_play({name=weapon._firing_sound},
				{pos=player:get_pos(), max_hear_distance=128, gain=1.75, pitch=math.random(85, 115)/100})

			weapons.player_list[pname].fatigue = weapons.player_list[pname].fatigue + weapon._fatigue
			if weapons.player_list[pname].fatigue > 100 then
				weapons.player_list[pname].fatigue = 100
			end
			
			local pipis_arc = solarsail.util.functions.remap(weapons.player_list[pname][ammo], 0, 100, 1.5, 7.5)

			weapons.player_list[pname][ammo] = 100
			weapon.on_reload(player, weapon, player:get_wielded_item():get_name(), false)

			local pyaw = player:get_look_horizontal()
			local ppit = player:get_look_vertical()

			local myaw, mpitch = 0, 0

			if weapons.player_list[pname].aim_mode then
				myaw = math.random(weapon._offset_aim.yaw_min*100, weapon._offset_aim.yaw_max*100) / 100
				mpitch = math.random(weapon._offset_aim.pitch_min*100, weapon._offset_aim.pitch_max*100) / 100
			else
				myaw = (math.random(weapon._offset.yaw_min*100, weapon._offset.yaw_max*100) / 100)
				mpitch = math.random(weapon._offset.pitch_min*100, weapon._offset.pitch_max*100) / 100
			end

			local fyaw = pyaw + math.rad(myaw)
			local fpit = ppit + math.rad(mpitch)
			local new_look = solarsail.util.functions.look_vector(fyaw, fpit)

			local pipis_rot = vector.new(-ppit, pyaw, 0)
			local pipis_vel = vector.add(player:get_velocity(), vector.multiply(new_look, pipis_arc))
			local pipis_pos = vector.add(
				vector.add(player:get_pos(), vector.new(0, weapons.default_eye_height, 0)),
				vector.multiply(player:get_look_dir(), 1)
			)

			local ent = minetest.add_entity(pipis_pos, "weapons:pipis_grenade")
			local luaent = ent:get_luaentity()
			luaent._owner = player
			ent:set_velocity(pipis_vel)
			ent:set_acceleration(vector.new(0, -9.8, 0))
		elseif solarsail.controls.player[pname].LMB then
			weapons.player_list[pname][ammo] = weapons.player_list[pname][ammo] + 6
			if weapons.player_list[pname][ammo] > 100 then
				weapons.player_list[pname][ammo] = 100
			end
		end
	end
end

weapons.register_weapon("weapons:pipis_cannon", true, {
    _localisation = {
        itemstring = "weapons:pipis_cannon",
        name = minetest.formspec_escape("[PIPIS CANNON]"),
        tooltip = 
[[CUTS STRINGS.

Stats:
5 Damage per shrapnel pellet.
Hold fire to change launch strengh.
Fires erratic grenades that explode into shotgun like shrapnel near targets.
Direct hits against friendly targets will restore 25 health.
Single shot, forced 2.5 second reload between shots.]]
    },

    -- HUD / Visual
	_type = "gun",
    _ammo_type = "pipis",
    _slot = "primary",
    _name = "pipis_cannon",
    _crosshair = "crosshair163.png",
    _crosshair_aim = "crosshair163.png",
    _fov_mult = 0,
    _fov_mult_aim = 0.95,
    _min_arm_angle = -45,
    _max_arm_angle = 75,
    _arm_angle_offset = 0,
	_uses_mouse_up = true, 

    -- Sounds
    _firing_sound = "pipis_fire",
    _reload_sound = "pipis_cooldown",
    
    -- Base stats
    _pellets = 1,
    _mag = 0,
    _rpm = 900,
    _reload = 2.5,
    _damage = 5,
	_movespeed = 0.8,
	_movespeed_aim = 0.3,
	_shots_used = 1,
    _heals = 25,
	_is_energy = true,
    _heat_accelerated = false,
    _cool_rate = 0.99,
    _cool_timer = 0.25,
    
    _recoil = 3.5,
    _recoil_vert_min = 1.5,
    _recoil_vert_max = 4,
    _recoil_hori = 5,
    _recoil_factor = 1,
    _recoil_aim_factor = 0.9,

    _fatigue = 100,
    _fatigue_timer = 0.2,
    _fatigue_recovery = 2,

    _offset = {pitch_min=-2, pitch_max=2, yaw_min=-2, yaw_max=2},
    _offset_aim = {pitch_min=-0.5, pitch_max=0.5, yaw_min=-0.5, yaw_max=0.5},

    _break_hits = 1,
    _block_chance = 25,

    _anim = {
		idle = {x=0, y=0},
		idle_fire = {x=0, y=8},
		aim = {x=10, y=10},
		aim_fire = {x=10, y=18},
		reload = {x=60, y=219}
	},
	_arms = {
		mesh = "assault_arms.x",
		skin_pos = 1,
		textures = {"transarent.png", "assault_rifle.png"},
	},

    on_fire = launch_pipis,
    on_reload = weapons.energy_overheat,
})