local function apply_recoil(player, weapon, ammo)
	local pname = player:get_player_name()
	local yaw_rad = player:get_look_horizontal()
	local pitch_rad = player:get_look_vertical()
	-- Physical knockback; can be canceled out
	local result_x, result_z = 
			solarsail.util.functions.yaw_to_vec(yaw_rad, weapon._recoil, true)
	local result_y = 
			solarsail.util.functions.y_direction(pitch_rad, weapon._recoil)
	local pitch_mult = solarsail.util.functions.xz_amount(pitch_rad)
	player:add_velocity({
		x=result_x * pitch_mult, 
		y=result_y, 
		z=result_z * pitch_mult
	})
	
	if not weapons.disable_visual_recoil then
		-- Camera recoil; cannot be canceled out
		local vert_deg, hori_deg, look_pitch, look_hori = 0, 0, 0, 0
		local pammo = weapons.player_list[pname][ammo]
		local vert_curve =
			solarsail.util.functions.remap(pammo, 0, 100, weapon._recoil_vert_min, weapon._recoil_vert_max) * weapons.master_recoil_mult
		local hori_curve =
			solarsail.util.functions.remap(pammo, 0, 100, weapon._recoil_hori, weapon._recoil_hori_max) * weapons.master_recoil_mult
		
		if math.random(0, 1) == 1 then
			hori_curve = -hori_curve
		end

		-- Handle aiming
		local pname = player:get_player_name()
		if weapons.player_list[pname].aim_mode then
			look_pitch = player:get_look_vertical() + (math.rad(-vert_curve) * weapon._recoil_aim_factor)
			look_hori = player:get_look_horizontal() + (math.rad(hori_curve) * weapon._recoil_aim_factor)
		else
			look_pitch = player:get_look_vertical() + (math.rad(-vert_curve) * weapon._recoil_factor)
			look_hori = player:get_look_horizontal() + (math.rad(hori_curve) * weapon._recoil_factor)
		end
		player:set_look_vertical(look_pitch)
		player:set_look_horizontal(look_hori)
	end
end


local function raycast_minigun(player, weapon)
	local wield = player:get_wielded_item():get_name()
	local pname = player:get_player_name()
	local ammo = weapon._ammo_type
	
	if weapons.player_list[pname][ammo] < 101 then -- Ensure there's actually bullets in the mag/chamber
		minetest.sound_play({name=weapon._firing_sound}, 
			{pos=player:get_pos(), max_hear_distance=128, gain=1.75, pitch=math.random(95, 105)/100})

		if weapon.on_fire_visual == nil then
		else
			weapon.on_fire_visual(player)
		end

		local pyaw = player:get_look_horizontal()
		local ppit = player:get_look_vertical()
		for i=1, weapon._pellets do
			-- Ray calculations.
			local raybegin = vector.add(player:get_pos(), {x=0, y=weapons.default_eye_height, z=0})
			local vec_x, vec_y, vec_z

			local fatigue_mult = 1 + (weapons.player_list[pname].fatigue / 100)
			
			-- Handle aiming
			local myaw, mpitch = 0, 0
			if weapons.player_list[pname].aim_mode then
				if weapon._offset_aim == nil then
					myaw = math.random(weapon._spread_aim*-100, weapon._spread_aim*100) / 100
					mpitch = math.random(weapon._spread_aim*-100, weapon._spread_aim*100) / 100
				else
					myaw = math.random(weapon._offset_aim.yaw_min*100, weapon._offset_aim.yaw_max*100) / 100
					mpitch = math.random(weapon._offset_aim.pitch_min*100, weapon._offset_aim.pitch_max*100) / 100
				end
			else
				if weapon._offset == nil then
					myaw = math.random(weapon._spread*-100, weapon._spread_aim*100) / 100
					mpitch = math.random(weapon._spread*-100, weapon._spread_aim*100) / 100
				else
					myaw = (math.random(weapon._offset.yaw_min*100, weapon._offset.yaw_max*100) / 100)
					mpitch = math.random(weapon._offset.pitch_min*100, weapon._offset.pitch_max*100) / 100
				end
			end

			fyaw = pyaw + math.rad(myaw * fatigue_mult)
			fpit = ppit + math.rad(mpitch * fatigue_mult)
			local new_look = solarsail.util.functions.look_vector(fyaw, fpit)

			local rayend = vector.add(raybegin,	vector.multiply(new_look, weapon._range))
			local ray = minetest.raycast(raybegin, rayend, true, false)
			local pointed = ray:next()
			pointed = ray:next()
			local target_pos

			if weapon._tracer == nil then
			else
				local tracer_pos = vector.add(raybegin, vector.multiply(new_look, 1))

				local tracer_vel = vector.multiply(vector.direction(raybegin, rayend), 120)
				local xz, y = solarsail.util.functions.get_3d_angles(raybegin, rayend)

				local ent = minetest.add_entity(tracer_pos, 
								"weapons:tracer_" .. weapon._tracer)


				ent:set_velocity(tracer_vel)
				local tracer_rot = vector.new(
					-fpit,
					fyaw,
					0
				)
				ent:set_rotation(tracer_rot)
			end

			if pointed == nil then
			else
				-- Handle target;
				if pointed.type == "object" then
					target_pos = pointed.ref:get_pos()
				else
					target_pos = pointed.under
				end
			end

			-- Calculate time to target and distance to target;
			if target_pos == nil then
			else
				local dist = solarsail.util.functions.pos_to_dist(raybegin, target_pos)

				minetest.after(dist/weapon._speed, weapon.bullet_on_hit, pointed, player,
					weapon, target_pos, dist)
			end
		end
		-- Handle recoil of the equipped weapon
		apply_recoil(player, weapon, ammo)

		local res = 1
		weapons.player_list[pname][ammo] = weapons.player_list[pname][ammo] + res
		if weapons.player_list[pname][ammo] > 100 then
			weapons.player_list[pname][ammo] = 100
		end
	end

end


local function add_extras(player)
	local ldir = player:get_look_dir()
	local ppos = vector.add(player:get_pos(), vector.new(0, 1.2+ldir.y/3.5, 0))
	
	local px, pz = solarsail.util.functions.yaw_to_vec(player:get_look_horizontal(), 1, false)
	ppos = vector.add(ppos, vector.multiply(vector.new(px, 0, pz), 0.225))
	local dir = vector.new(pz, 0, -px)
	local res = vector.add(ppos, vector.multiply(dir, 0.25))

	local ent = minetest.add_entity(res, "weapons:ar_casing")
	local pvel = player:get_velocity()
	pvel.x = pvel.x/2
	pvel.y = pvel.y/2
	pvel.z = pvel.z/2
	local vel = vector.multiply(vector.new(pz/1.5, ldir.y+1, -px/1.5), 3)
	vel = vector.add(vel, vector.new(math.random(-25, 25)/100, 0, math.random(-25, 25)/100))
	ent:set_acceleration({x=0, y=-9.80, z=0})
	ent:set_velocity(vector.add(pvel, vel))
end

local wep_rpm = 125
local shots_used = 1

weapons.register_weapon("weapons:minigun", true,
{
	-- Config
	_type = "gun",
	_ammo_type = "minigun",
	_is_energy = true,
	_heat_accelerated = true,
	_accel_mult = 16,
	_cool_rate = 1,
	_cool_timer = 0.325,
	_slot = "primary",
	_localisation = {
		itemstring = "weapons:minigun",
		name = "Minigun",
		tooltip =
[[A Minigun.
Nothing saturates a target better.
Stats:

5 Damage.
Infinite Ammo!.
Range 125 nodes.]],
	},

	-- HUD / Visual
	_tracer = "ar",
	_name = "minigun",
	_crosshair = "shotgun_crosshair.png",
	_crosshair_aim = "assault_crosshair.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.9,
	_min_arm_angle = -45,
	_max_arm_angle = 75,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "ass_rifle_fire",
	_reload_sound = "ass_rifle_reload",
	_casing = "Armature_Casing",
	
	-- Base Stats:
	_pellets = 1,
	_mag = 0,
	_rpm = wep_rpm,
	_reload = 6.65,
	_speed = 1200,
	_range = 125,
	_damage = 5,
	_movespeed = 0.25,
	_movespeed_aim = 0.05,
	_shots_used = shots_used,

	_recoil = 1.5,
	_recoil_vert_min = 0.2,
	_recoil_vert_max = 5.5,
	_recoil_hori = 0.2,
	_recoil_hori_max = 7.5,
	_recoil_factor = 0.8,
	_recoil_aim_factor = 0.5,

	-- Not required, but to avoid crashes where data is nil.
	_fatigue = 15,
	_fatigue_timer = 0.12,
	_fatigue_recovery = 0.85, 

	_offset = {pitch_min=-2.95, pitch_max=2.95, yaw_min=-2.95, yaw_max=2.95},
	_offset_aim = {pitch_min=-2.05, pitch_max=2.05, yaw_min=-2.05, yaw_max=2.05},

	_break_hits = 1,
	_block_chance = 55,

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
		skin_pos = 1,
		textures = {"transarent.png", "assault_rifle.png"},
	},
	on_fire = raycast_minigun,
	on_fire_visual = add_extras,
	on_reload = weapons.energy_overheat,
	bullet_on_hit = weapons.bullet_on_hit,
})