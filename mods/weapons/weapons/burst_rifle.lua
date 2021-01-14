local wep_rpm = 65
local shots_used = 3

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

weapons.register_weapon("weapons:burst_rifle", true,
{
	-- Config
	_type = "gun",
	_ammo_type = "burst_rifle",
	_slot = "primary",
	_localisation = {
		itemstring = "weapons:burst_rifle",
		name = "Burst Rifle",
		tooltip =
[[A standard burst rifle. Good at short to medium range.

Stats:

25 Damage per shot.
2.85 second reload.
Unaimed spread +- 3.75 nodes at maximum range.
Aimed spread +- 0.5 nodes at maximum range.
Range 150 nodes.]],
	},

	-- HUD / Visual
	_tracer = "ar",
	_name = "burst_rifle",
	_ammo_bg = "bullet_bg",
	_crosshair = "assault_crosshair.png",
	_crosshair_aim = "railgun_crosshair.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.5,
	_min_arm_angle = -45,
	_max_arm_angle = 75,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "burst_rifle",
	_reload_sound = "ass_rifle_reload",
	_casing = "Armature_Casing",
	
	-- Base Stats:
	_pellets = 1,
	_mag = 24,
	_rpm = wep_rpm,
	_reload = 2.85,
	_speed = 1200,
	_range = 150,
	_damage = 25,
	_movespeed = 0.95,
	_movespeed_aim = 0.45,
	_shots_used = shots_used,

	_recoil = 2.5,
	_recoil_vert_min = 1,
	_recoil_vert_max = 2.25,
	_recoil_hori = 3,
	_recoil_factor = 0.8/2,
	_recoil_aim_factor = 0.5/2,
	
	_spread = 3.75,
	_spread_aim = 0.5,

	_break_hits = 2,
	_block_chance = 50,

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
	on_fire = function(player, weapon)
		for i=1, shots_used do
			minetest.after(((((60/wep_rpm)/shots_used)-0.25)*i), weapons.raycast_bullet, player, weapon)
		end
	end,
	on_reload = weapons.magazine_reload,
	on_fire_visual = add_extras,
	bullet_on_hit = weapons.bullet_on_hit,
})