-- Boring Pistol for BfA
-- Author: Jordach
-- License: RESERVED


local wep_rpm = 160

local shots_used = 1

weapons.register_weapon("weapons:boring_pistol", true,
{
	-- Config
	_type = "gun",
	_ammo_type = "boring_pistol",
	_slot = "secondary",
	_localisation = {
		itemstring = "weapons:boring_pistol",
		name = "Boring Pistol",
		tooltip =
[[A boring pistol. It does it's job extremely well.
...It's really really boring.

Stats:

18 Damage.
1.31 second reload.
Range 100 nodes.]],
		preview = "preview_boringpistol.obj"
	},

	-- HUD / Visual
	_tracer = "ar",
	_name = "boring_pistol",
	_crosshair = "crosshair010.png",
	_crosshair_aim = "crosshair008.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.9,
	_min_arm_angle = -65,
	_max_arm_angle = 70,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "bpistol_fire",
	_reload_sound = "bpistol_reload",
	_reload_sound_alt = "bpistol_reload_alt",
	_casing = "Armature_Casing",
	
	-- Base Stats:
	_fire_mode = "semi",
	_pellets = 1,
	_mag = 12,
	_rpm = wep_rpm,
	_reload = 1.3125,
	_speed = 1200,
	_range = 100,
	_damage = 18,
	_headshot_multiplier = 1.5,
	_movespeed = 1.1,
	_movespeed_aim = 0.85,
	_shots_used = shots_used,

	_recoil = 1.5,
	_recoil_vert_min = 1,
	_recoil_vert_max = 1.75,
	_recoil_hori = 2.25,
	_recoil_factor = 0.8,
	_recoil_aim_factor = 0.5,

	_fatigue = 15,
	_fatigue_timer = 0.06,
	_fatigue_recovery = 0.95,
	
	_spread = 5,
	_spread_aim = 2.5,

	_offset = {pitch_min=-1.7, pitch_max=1.7, yaw_min=-1.7, yaw_max=1.7},
	_offset_aim = {pitch_min=-0.65, pitch_max=0.65, yaw_min=-0.65, yaw_max=0.65},

	_break_hits = 1,
	_block_chance = 35,

	-- Arm Animations + Arm visual settings;
	_anim = {
		idle = {x=0, y=179},
		idle_fire = {x=200, y=219},
		aim = {x=230, y=409},
		aim_fire = {x=420, y=439},
		reload = {x=450, y=554},
		reload_alt = {x=570, y=663},
	},
	_arms = {
		ph = {min=vector.new(0, 9.5, 1.25), max=vector.new(0, 12, 1.45), center=vector.new(0, 9.9, -0.25)},
		mesh = "arms_boringpistol.x",
		skin_pos = 1,
		textures = {"transarent.png", "rubber.png", "steel_dark.png", "steel_grey.png", "sight_green.png"},
	},
	on_fire = weapons.raycast_bullet,
	--on_fire_visual = add_extras,
	on_reload = weapons.magazine_reload,
	bullet_on_hit = weapons.bullet_on_hit,
})