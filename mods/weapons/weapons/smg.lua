local bounce_factor = 0.36
local casing_ent = {
	visual = "mesh",
	mesh = "smg_casing.obj",
	textures = {"casing.png"},
	physical = true,
	collide_with_objects = false,
	pointable = false,
	collisionbox = {-0.05, -0.05, -0.05, 0.05, 0.05, 0.05},
	visual_size = {x=3, y=3},
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
				{object=self.object, max_hear_distance=8, gain=0.035, pitch=math.random(85, 115)/100}, true)
		elseif moveresult.collisions[1].axis == "y" then
			velocity.x = old_vel.x
			velocity.y = -(old_vel.y * bounce_factor)
			velocity.z = old_vel.z
			if math.abs(old_vel.y) > 0.38 then
				minetest.sound_play({name = "ar_casing"},
					{object=self.object, max_hear_distance=8, gain=0.035, pitch=math.random(85, 115)/100}, true)
			end
		elseif moveresult.collisions[1].axis == "z" then
			velocity.x = old_vel.x
			velocity.y = old_vel.y
			velocity.z = -(old_vel.z * bounce_factor)
			minetest.sound_play({name = "ar_casing"},
				{object=self.object, max_hear_distance=8, gain=0.035, pitch=math.random(85, 115)/100}, true)
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

minetest.register_entity("weapons:smg_casing", casing_ent)

local function add_extras(player)
	local ldir = player:get_look_dir()
	local ppos = vector.add(player:get_pos(), vector.new(0, 1.2+ldir.y/3.5, 0))
	
	local px, pz = solarsail.util.functions.yaw_to_vec(player:get_look_horizontal(), 1, false)
	ppos = vector.add(ppos, vector.multiply(vector.new(px, 0, pz), 0.1))

	local dir = vector.new(pz, 0, -px)
	local res

	local pvel = player:get_velocity()
	pvel.x = pvel.x/2
	pvel.y = pvel.y/2
	pvel.z = pvel.z/2
	for i=0, 1 do
		if i == 0 then
			res = vector.add(ppos, vector.multiply(dir, 0.25))
		else
			res = vector.add(ppos, vector.multiply(dir, -0.25))
		end
		
		local ent = minetest.add_entity(res, "weapons:smg_casing")
		local vel = vector.add(pvel, vector.new(-px*2, 0, -pz*2))
		vel = vector.add(vel, vector.new(math.random(-25, 25)/100, 0, math.random(-25, 25)/100))
		ent:set_acceleration({x=0, y=-9.80, z=0})
		ent:set_velocity(vel)
	end
end

weapons.register_weapon("weapons:smg",
{
	drawtype = "mesh",
	mesh = "smg_fp.b3d",
	range = 1,

	_kf_name = "SMG",
	_alt_mode = "weapons:smg_alt",
	_fov_mult = 0,
	_crosshair = "smg_crosshair.png",
	_type = "gun",
	_ammo_type = "smg",
	_firing_sound = "smg_fire",
	_casing_sound = "smg_casing",
	_reload_sound = "smg_reload",
	_name = "smg",
	_pellets = 2,
	_mag = 48,
	_rpm = 1800,
	_reload = 5.7,
	_reload_node = "weapons:smg_reload",
	_speed = 950,
	_range = 140,
	_damage = 6,
	_heals = 5,
	_break_hits = 1,
	_recoil = 1.05,
	_spread_min = -6,
	_spread_max = 6,
	_tracer = "smg",
	_phys_alt = 1,
	_block_chance = 25,
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
{
	drawtype = "mesh",
	mesh = "smg_alt_fp.b3d",
	range = 1,

	_kf_name = "SMG",
	_alt_mode = "weapons:smg",
	_fov_mult = 0.8,
	_crosshair = "assault_crosshair.png",
	_type = "gun",
	_ammo_type = "smg",
	_firing_sound = "smg_fire",
	_casing_sound = "smg_casing",
	_reload_sound = "smg_reload",
	_name = "smg",
	_pellets = 2,
	_mag = 48,
	_rpm = 900,
	_reload = 5.7,
	_reload_node = "weapons:smg_reload",
	_speed = 1250,
	_range = 140,
	_damage = 4,
	_heals = 10,
	_break_hits = 1,
	_recoil = 0.75,
	_spread_min = -3,
	_spread_max = 3,
	_tracer = "smg_alt",
	_phys_alt = 0.65,
	_is_alt = true,
	_block_chance = 25,
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
{
	drawtype = "mesh",
	mesh = "smg_reload_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_kf_name = "SMG",
	_damage = 8,
	_mag = 65,
	_tp_model = "smg_tp.x",
	_reset_node = "weapons:smg",
	_fov_mult = 0,
	_type = "gun",
	_ammo_type = "smg",
	_phys_alt = 0.9,
	
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
},
"smg.png", "medic_class")