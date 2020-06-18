weapons.register_weapon("weapons:smg",
{
	drawtype = "mesh",
	mesh = "smg_fp.b3d",
	range = 1,

	_ammo_bg = "bullet_bg",
	_kf_name = "SMG",
	_alt_mode = "weapons:smg_alt",
	_fov_mult = 0,
	_crosshair = "smg_crosshair.png",
	_type = "gun",
	_ammo_type = "primary",
	_firing_sound = "smg_fire",
	_casing_sound = "smg_casing",
	_reload_sound = "smg_reload",
	_name = "smg",
	_pellets = 1,
	_mag = 65,
	_rpm = 1200,
	_reload = 3.7,
	_reload_node = "weapons:smg_reload",
	_speed = 650,
	_range = 140,
	_damage = 3,
	_heals = 5,
	_break_hits = 1,
	_recoil = 1.05,
	_spread_min = -7,
	_spread_max = 7,
	_tracer = "smg",
	_phys_alt = 1,
	on_fire = weapons.raycast_bullet,
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

	_ammo_bg = "bullet_bg",
	_kf_name = "SMG",
	_alt_mode = "weapons:smg",
	_fov_mult = 0.85,
	_crosshair = "assault_crosshair.png",
	_type = "gun",
	_ammo_type = "primary",
	_firing_sound = "smg_fire",
	_casing_sound = "smg_casing",
	_reload_sound = "smg_reload",
	_name = "smg",
	_pellets = 1,
	_mag = 65,
	_rpm = 900,
	_reload = 3.7,
	_reload_node = "weapons:smg_reload",
	_speed = 650,
	_range = 140,
	_damage = 2,
	_heals = 10,
	_break_hits = 1,
	_recoil = 0.75,
	_spread_min = -4,
	_spread_max = 4,
	_tracer = "smg_alt",
	_phys_alt = 0.65,
	_is_alt = true,
	on_fire = weapons.raycast_bullet,
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

	_ammo_bg = "bullet_bg",
	_kf_name = "SMG",
	_damage = 8,
	_mag = 65,
	_tp_model = "smg_tp.x",
	_reset_node = "weapons:smg",
	_fov_mult = 0,
	_type = "gun",
	_ammo_type = "primary",
	_phys_alt = 0.9,
	
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
},
"smg.png", "medic_class")