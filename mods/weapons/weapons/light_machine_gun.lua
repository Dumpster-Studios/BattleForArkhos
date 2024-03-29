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

local wep_rpm = 465
local shots_used = 1

weapons.register_weapon("weapons:light_machine_gun", true,
{
	-- Config
	_type = "gun",
	_ammo_type = "lmg",
	_slot = "primary",
	_localisation = {
		itemstring = "weapons:light_machine_gun",
		name = "Light Machine Gun",
		tooltip =
[[A light machine gun. Good at suppressive fire.

Stats:

10 Damage.
6.65 second reload.
Range 125 nodes.]],
	},

	-- HUD / Visual
	_tracer = "ar",
	_name = "light_machine_gun",
	_crosshair = "crosshair027.png",
	_crosshair_aim = "crosshair027.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.6,
	_min_arm_angle = -45,
	_max_arm_angle = 75,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "lmg_fire",
	_reload_sound = "ass_rifle_reload",
	_casing = "Armature_Casing",
	
	-- Base Stats:
	_pellets = 1,
	_mag = 100,
	_rpm = wep_rpm,
	_reload = 6.65,
	_speed = 1200,
	_range = 125,
	_damage = 10,
	_movespeed = 0.5,
	_movespeed_aim = 0.15,
	_shots_used = shots_used,

	_recoil = 1.5,
	_recoil_vert_min = 2,
	_recoil_vert_max = 4.25,
	_recoil_hori = 6,
	_recoil_factor = 0.8,
	_recoil_aim_factor = 0.5,

	_offset = {pitch_min=-2.35, pitch_max=2.35, yaw_min=-2.35, yaw_max=2.35},
	_offset_aim = {pitch_min=-0.55, pitch_max=0.55, yaw_min=-0.55, yaw_max=0.55},

	_fatigue = 3,
	_fatigue_timer = 0.09,
	_fatigue_recovery = 0.95,

	_break_hits = 1,
	_block_chance = 90,

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
	on_fire = weapons.raycast_bullet,
	on_fire_visual = add_extras,
	on_reload = weapons.magazine_reload,
	bullet_on_hit = weapons.bullet_on_hit,
})