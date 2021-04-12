local wep_rpm = 76
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

12 Damage per pellet, of a total of 9 pellets.
1 second reload when empty, 0.9 seconds when topping off.
Unaimed spread +- 14 nodes at maximum range.
Aimed spread +- 12 nodes at maximum range.
Range 150 nodes.]],
	preview = "preview_shotgun.obj"
	},

	-- HUD / Visual
	_tracer = "shotgun",
	_name = "pump_shotgun",
	_crosshair = "shotgun_crosshair.png",
	_crosshair_aim = "shotgun_crosshair.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.95,
	_min_arm_angle = -45,
	_max_arm_angle = 50,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "shotgun_fire",
	_reload_sound = "ass_rifle_reload",
	
	-- Base Stats:
	_pellets = 9,
	_mag = 6,
	_rpm = wep_rpm,
	_reload = 0.81,
	_speed = 1200,
	_range = 150,
	_damage = 12,
	_headshot_multiplier = 1.0125,
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

	_fatigue = 85,
	_fatigue_timer = 0.12,
	_fatigue_recovery = 0.955,

	_break_hits = 1,
	_block_chance = 25,

	-- Arm Animations + Arm visual settings;
	_anim = {
		idle = {x=0, y=179},
		idle_fire = {x=190, y=237},
		aim = {x=250, y=429},
		aim_fire = {x=440, y=487},
		reload = {x=500, y=559},
		reload_alt = {x=570, y=619} -- 10% faster btw
	},
	_arms = {
		mesh = "arms_shotgun.x",
		skin_pos = 1,
		textures = {"transarent.png", "rubber.png", "steel_dark.png", "steel_light.png", "steel_grey.png", "sight_green.png"},
	},
	on_fire = weapons.raycast_bullet,
	--on_fire_visual = add_extras,
	on_reload = weapons.tube_reload,
	bullet_on_hit = weapons.bullet_on_hit,
})