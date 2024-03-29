local wep_rpm = 30
local shots_used = 1

weapons.register_weapon("weapons:sniper_rifle", true,
{
	-- Config
	_type = "gun",
	_ammo_type = "snip_rifle",
	_slot = "primary",
	_localisation = {
		itemstring = "weapons:sniper_rifle",
		name = "Sniper Rifle",
		tooltip =
[[A standard sniper rifle. Good at extreme distances.

Stats:

85 Damage.
5.3 second reload.
Range 250 nodes.]],
	},

	-- HUD / Visual
	_tracer = "railgun",
	_name = "sniper_rifle",
	_crosshair = "sniper_unaim.png",
	_crosshair_aim = "crosshair022.png",
	_fov_mult = 0,
	_fov_mult_aim = 0.2,
	_min_arm_angle = -45,
	_max_arm_angle = 75,
	_arm_angle_offset = 0,
	-- Sounds
	_firing_sound = "ass_rifle_fire",
	_reload_sound = "ass_rifle_reload",
	_casing = "Armature_Casing",
	
	-- Base Stats:
	_fire_mode = "semi",
	_pellets = 1,
	_mag = 5,
	_rpm = wep_rpm,
	_reload = 5.3,
	_speed = 1200,
	_range = 250,
	_damage = 85,
	_headshot_multiplier = 2.5,
	_movespeed = 0.85,
	_movespeed_aim = 0.15,
	_shots_used = shots_used,

	_recoil = 4.5,
	_recoil_vert_min = 4,
	_recoil_vert_max = 6.25,
	_recoil_hori = 6,
	_recoil_factor = 1,
	_recoil_aim_factor = 0.8,
	
	_offset = {pitch_min=-12.5, pitch_max=12.5, yaw_min=-12.5, yaw_max=12.5},
	_offset_aim = {pitch_min=-0.01, pitch_max=0.01, yaw_min=-0.01, yaw_max=0.01},

	_fatigue = 75,
	_fatigue_timer = 0.06,
	_fatigue_recovery = 0.98,

	_break_hits = 4,
	_block_chance = 100,

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
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})