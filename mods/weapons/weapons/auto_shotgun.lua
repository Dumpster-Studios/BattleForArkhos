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

minetest.register_entity("weapons:shotgun_casing", casing_ent)

local function add_extras(player)
	local ldir = player:get_look_dir()
	local ppos = vector.add(player:get_pos(), vector.new(0, 1.2+ldir.y/3.5, 0))
	
	local px, pz = solarsail.util.functions.yaw_to_vec(player:get_look_horizontal(), 1, false)
	ppos = vector.add(ppos, vector.multiply(vector.new(px, 0, pz), 0.225))
	local dir = vector.new(pz, 0, -px)
	local res = vector.add(ppos, vector.multiply(dir, 0.25))

	local ent = minetest.add_entity(res, "weapons:shotgun_casing")
	local pvel = player:get_velocity()
	pvel.x = pvel.x/2
	pvel.y = pvel.y/2
	pvel.z = pvel.z/2
	local vel = vector.multiply(vector.new(pz/1.5, ldir.y+1, -px/1.5), 3)
	vel = vector.add(vel, vector.new(math.random(-25, 25)/100, 0, math.random(-25, 25)/100))
	ent:set_acceleration({x=0, y=-9.80, z=0})
	ent:set_velocity(vector.add(pvel, vel))
end

local wep_rpm = 75
local shots_used = 1

weapons.register_weapon("weapons:pump_shotgun", true,
{
	-- Config
	_type = "gun",
	_ammo_type = "pump_shotgun",
	_slot = "primary",
	_localisation = {
		itemstring = "weapons:pump_shotgun",
		name = "Pump Shotgun",
		tooltip =
[[A standard pump shotgun. Good at short range.

Stats:

5 Damage per pellet, of a total of 9 pellets.
0.65 second reload per shell.
Unaimed spread +- 14 nodes at maximum range.
Aimed spread +- 12 nodes at maximum range.
Range 150 nodes.]],
	},

	-- HUD / Visual
	_tracer = "ar",
	_name = "pump_shotgun",
	_ammo_bg = "shotgun_bg",
	_crosshair = "shotgun_crosshair.png",
	_crosshair_aim = "shotgun_crosshair.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.95,
	_min_arm_angle = -45,
	_max_arm_angle = 75,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "shotgun_fire",
	_reload_sound = "ass_rifle_reload",
	_casing = "Armature_Casing",
	
	-- Base Stats:
	_pellets = 9,
	_mag = 6,
	_rpm = wep_rpm,
	_reload = 0.65,
	_speed = 1200,
	_range = 150,
	_damage = 25,
	_movespeed = 1,
	_movespeed_aim = 0.45,
	_shots_used = shots_used,

	_recoil = 12.75,
	_recoil_vert_min = 10,
	_recoil_vert_max = 14.25,
	_recoil_hori = 9,
	_recoil_factor = 0.85,
	_recoil_aim_factor = 0.55,
	
	_spread = 14,
	_spread_aim = 12,

	_break_hits = 1,
	_block_chance = 25,

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
	on_fire = weapons.raycast_bullet,
	on_fire_visual = add_extras,
	on_reload = weapons.tube_reload,
	bullet_on_hit = weapons.bullet_on_hit,
})