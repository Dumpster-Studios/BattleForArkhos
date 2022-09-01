-- Fists, Battle for Arkhos
-- Author: Jordach
-- License: RESERVED

local wep_rpm = 120
local shots_used = 1

weapons.register_weapon("weapons:fists", false,
{
	-- Config
	--_type = "fists",
	_ammo_type = "blocks",
	_slot = "tertiary",
	_localisation = {
		itemstring = "weapons:fists",
		name = "Fists",
		tooltip = [[]],
	},

	-- HUD / Visual
	--_tracer = "ar",
	_name = "fists",
	_crosshair = "railgun_crosshair.png",
	_crosshair_aim = "railgun_crosshair.png",
	_fov_mult = 0,
	_fov_mult_aim = 0,
	_min_arm_angle = -75,
	_max_arm_angle = 75,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "fist_punch",
	--_reload_sound = "ass_rifle_reload",
	--_casing = "Armature_Casing",
	
	-- Base Stats:
	_fire_mode = "auto",
	_pellets = 1,
	--_mag = 0,
	_rpm = wep_rpm,
	--_reload = 0.03,
	_speed = 1200,
    range = 4,
	_range = 4,
	_damage = 5,
	_movespeed = 1,
	_movespeed_aim = 1,
	_shots_used = shots_used,

	_recoil = 0,
	_recoil_vert_min = 0,
	_recoil_vert_max = 0,
	_recoil_hori = 0,
	_recoil_factor = 0,
	_recoil_aim_factor = 0,

	_fatigue = 0,
	_fatigue_timer = 0.03,
	_fatigue_recovery = 0.95,
	
	_spread = 0,
	_spread_aim = 0,

	_break_hits = 1,
	_block_chance = 100,

	-- Arm Animations + Arm visual settings;
	_anim = {
		idle = {x=0, y=179},
		idle_fire = {x=190, y=249},
		aim = {x=260, y=439},
		aim_fire = {x=450, y=509},
		reload = {x=0, y=179}
	},
	_arms = {
		mesh = "arms_fists.x",
        skin_pos = 1,
		textures = {"transparent.png", "transparent.png"},
        pos = vector.new(0, 10, -0.2)
	},
	on_fire = weapons.raycast_melee,
	melee_on_hit = weapons.melee_on_hit,
	--on_fire_visual = add_extras,
	--on_reload = weapons.magazine_reload,
})