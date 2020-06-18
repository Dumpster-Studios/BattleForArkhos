weapons.register_weapon("weapons:shotgun",
{
	drawtype = "mesh",
	mesh = "shotgun_fp.b3d",
	range = 1,

	_ammo_bg = "shotgun_bg",
	_ammo_type = "primary",
	_kf_name = "Shotgun",
	_alt_mode = "weapons:shotgun_alt",
	_fov_mult = 0,
	_crosshair = "shotgun_crosshair.png",
	_type = "gun",
	_firing_sound = "shotgun_fire",
	_casing_sound = "shotgun_casing",
	_reload_sound = "shotgun_reload",
	_tp_model = "shotgun_tp.x",
	_name = "shotgun",
	_pellets = 16,
	_mag = 2,
	_rpm = 225,
	_reload = 3.75,
	_reload_node = "weapons:shotgun_reload",
	_speed = 750,
	_range = 150,
	_damage = 7,
	_break_hits = 1,
	_recoil = 14,
	_spread_min = -14,
	_spread_max = 14,
	_tracer = "shotgun",
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
	mesh = "shotgun_alt_fp.b3d",
	range = 1,

	_ammo_bg = "shotgun_bg",
	_ammo_type = "primary",
	_kf_name = "Shotgun",
	_alt_mode = "weapons:shotgun",
	_fov_mult = 0.925,
	_crosshair = "shotgun_crosshair.png",
	_type = "gun",
	_firing_sound = "shotgun_fire",
	_casing_sound = "shotgun_casing",
	_reload_sound = "shotgun_reload",
	_tp_model = "shotgun_tp.x",
	_name = "shotgun",
	_pellets = 16,
	_mag = 2,
	_rpm = 225,
	_reload = 3.75,
	_reload_node = "weapons:shotgun_reload",
	_speed = 750,
	_range = 150,
	_damage = 7,
	_break_hits = 1,
	_recoil = 10,
	_spread_min = -11,
	_spread_max = 11,
	_tracer = "shotgun",
	_phys_alt = 0.45,
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
	mesh = "shotgun_reload_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "shotgun_bg",
	_ammo_type = "primary",
	_kf_name = "Shotgun",
	_damage = 6,
	_tp_model = "shotgun_tp.x",
	_reset_node = "weapons:shotgun",
	_mag = 2,
	_fov_mult = 0,
	_type = "gun",
	_phys_alt = 0.7,

	on_fire = weapons.raycast_bullet,
	bullet_on_hit = weapons.bullet_on_hit,
	
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
},
"shotgun.png", "scout_class")