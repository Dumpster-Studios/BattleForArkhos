local bounce_factor = 0.36
local casing_ent = {
	visual = "mesh",
	mesh = "ar_casing.obj",
	textures = {"casing.png"},
	physical = true,
	collide_with_objects = false,
	pointable = false,
	collisionbox = {-0.05, -0.05, -0.05, 0.05, 0.05, 0.05},
	visual_size = {x=5, y=5},
	_ttl = 4,
	_timer = 0
}

function casing_ent:on_step(dtime, moveresult)
	local rot = self.object:get_rotation()
	local velocity = {x=0, y=0, z=0}
	if moveresult.collides then
		local old_vel 
		-- Check for velocities:
		if moveresult.collisions[1] == nil then
			old_vel = self.object:get_velocity()
		else
			old_vel = table.copy(moveresult.collisions[1].old_velocity)
		end
		-- Handle air resistance, friction:
		if moveresult.touching_ground then
			old_vel.x = old_vel.x * 0.75
			old_vel.z = old_vel.z * 0.75
		else
			old_vel.x = old_vel.x * 0.975
			old_vel.z = old_vel.z * 0.975
		end

		if moveresult.collisions[1] == nil then
			if not moveresult.touching_ground then
				velocity.x = old_vel.x
				velocity.z = old_vel.z
			end
			velocity.y = old_vel.y
		elseif moveresult.collisions[1].axis == "x" then
			velocity.x = -(old_vel.x * bounce_factor)
			velocity.y = old_vel.y
			velocity.z = old_vel.z
			minetest.sound_play({name = "ar_casing"},
				{object=self.object, max_hear_distance=8, gain=0.15, pitch=math.random(85, 115)/100}, true)
		elseif moveresult.collisions[1].axis == "y" then
			velocity.x = old_vel.x
			velocity.y = -(old_vel.y * bounce_factor)
			velocity.z = old_vel.z
			if math.abs(old_vel.y) > 0.38 then
				minetest.sound_play({name = "ar_casing"},
					{object=self.object, max_hear_distance=8, gain=0.15, pitch=math.random(85, 115)/100}, true)
			end
		elseif moveresult.collisions[1].axis == "z" then
			velocity.x = old_vel.x
			velocity.y = old_vel.y
			velocity.z = -(old_vel.z * bounce_factor)
			minetest.sound_play({name = "ar_casing"},
				{object=self.object, max_hear_distance=8, gain=0.15, pitch=math.random(85, 115)/100}, true)
		end

		-- Rotate object for rolling and shit:
		local xz, y = solarsail.util.functions.get_3d_angles(
			vector.new(0, 0, 0), velocity
		)
		rot.x = xz + math.rad(math.pi/2)

		self.object:set_velocity(velocity)
	end

	local norm = vector.normalize(self.object:get_velocity())
	rot.y = rot.y + ((norm.x + norm.z) / 3)
	self.object:set_rotation(rot)

	if self._timer > self._ttl then
		self.object:remove()
	end
	self._timer = self._timer + dtime
end

minetest.register_entity("weapons:ar_casing", casing_ent)

local function add_extras(player)
	local ldir = player:get_look_dir()
	local ppos = vector.add(player:get_pos(), vector.new(0, 1.2+ldir.y/3.5, 0))
	
	local px, pz = solarsail.util.functions.yaw_to_vec(player:get_look_horizontal(), 1, false)
	ppos = vector.add(ppos, vector.multiply(vector.new(px, 0, pz), 0.225))
	local dir = vector.new(pz, 0, -px)
	local res = vector.add(ppos, vector.multiply(dir, 0.25))

	local ent = minetest.add_entity(res, "weapons:ar_casing")
	local pvel = player:get_player_velocity()
	pvel.x = pvel.x/2
	pvel.y = pvel.y/2
	pvel.z = pvel.z/2
	local vel = vector.multiply(vector.new(pz/1.5, ldir.y+1, -px/1.5), 3)
	vel = vector.add(vel, vector.new(math.random(-25, 25)/100, 0, math.random(-25, 25)/100))
	ent:set_acceleration({x=0, y=-9.80, z=0})
	ent:set_velocity(vector.add(pvel, vel))
end

weapons.register_weapon("weapons:assault_rifle",
{ -- Default
	drawtype = "mesh",
	mesh = "assault_rifle_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "bullet_bg",
	_kf_name = "Assault Rifle",
	_fov_mult = 0,
	_crosshair = "assault_crosshair.png",
	_type = "gun",
	_ammo_type = "primary",
	_firing_sound = "ass_rifle_fire",
	_casing_sound = "ass_rifle_casing",
	_reload_sound = "ass_rifle_reload",
	_name = "assault_rifle",
	_pellets = 1,
	_mag = 30,
	_rpm = 500,
	_reload = 3,
	_speed = 1200, -- Meters per second
	_range = 150,
	_damage = 10,
	_break_hits = 1,
	_recoil = 2.5,
	_spread_min = -4,
	_spread_max = 4,
	_tracer = "ar",
	_phys_alt = 1,
	_block_chance = 85,

	on_fire = weapons.raycast_bullet,
	on_fire_visual = add_extras,
	bullet_on_hit = weapons.bullet_on_hit,
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
}, 
{ -- Alt
	drawtype = "mesh",
	mesh = "assault_rifle_alt_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "bullet_bg",
	_kf_name = "Assault Rifle",
	_fov_mult = 0.6,
	_crosshair = "railgun_crosshair.png",
	_type = "gun",
	_ammo_type = "primary",
	_firing_sound = "ass_rifle_fire",
	_casing_sound = "ass_rifle_casing", 
	_reload_sound = "ass_rifle_reload",
	_name = "assault_rifle",
	_pellets = 1,
	_mag = 30,
	_rpm = 125,
	_reload = 3,
	_speed = 1500, -- Meters per second
	_range = 150,
	_damage = 20,
	_break_hits = 3,
	_recoil = 1.5,
	_spread_min = 0,
	_spread_max = 0,
	_tracer = "ar",
	_phys_alt = 0.45,
	_is_alt = true,

	on_fire = weapons.raycast_bullet,
	on_fire_visual = add_extras,
	bullet_on_hit = weapons.bullet_on_hit,
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
},
{ -- Reloading
	--tiles = {"assault_rifle.png", "assault_class_blue.png"},
	drawtype = "mesh",
	mesh = "assault_rifle_reload_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "bullet_bg",
	_kf_name = "Assault Rifle",
	_damage = 10,
	_mag = 30,
	_fov_mult = 0,
	_type = "gun",
	_ammo_type = "primary",
	_phys_alt = 0.75,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
}, "assault_rifle.png", "assault_class")
