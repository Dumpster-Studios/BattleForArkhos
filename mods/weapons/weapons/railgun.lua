weapons.register_weapon("weapons:railgun",
{
	drawtype = "mesh",
	mesh = "railgun_fp.b3d",
	range = 1,

	_ammo_bg = "rail_bg",
	_kf_name = "Railgun",
	_alt_mode = "weapons:railgun_alt",
	_fov_mult = 0,
	_crosshair = "railgun_crosshair.png",
	_type = "gun",
	_ammo_type = "primary",
	_firing_sound = "railgun_fire",
	_casing_sound = "railgun_charge",
	_reload_sound = "railgun_reload",
	_tp_model = "railgun_tp.x",
	_name = "railgun",
	_pellets = 1,
	_mag = 4,
	_rpm = 75,
	_reload = 5.25,
	_reload_node = "weapons:railgun_reload",
	_speed = 2000,
	_range = 500,
	_damage = 85,
	_break_hits = 4,
	_recoil = 20,
	_spread_min = -50,
	_spread_max = 50,
	_tracer = "railgun",
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
	mesh = "railgun_fp.b3d",
	range = 1,
	
	_ammo_bg = "rail_bg",
	_kf_name = "Railgun",
	_alt_mode = "weapons:railgun",
	_fov_mult = 0.2,
	_crosshair = "railgun_crosshair.png",
	_type = "gun",
	_ammo_type = "primary",
	_firing_sound = "railgun_fire",
	_casing_sound = "railgun_charge",
	_reload_sound = "railgun_reload",
	_tp_model = "railgun_tp.x",
	_name = "railgun",
	_pellets = 1,
	_mag = 4,
	_rpm = 75,
	_reload = 5.25,
	_reload_node = "weapons:railgun_reload",
	_speed = 2000,
	_range = 500,
	_damage = 85,
	_break_hits = 4,
	_recoil = 10,
	_spread_min = 0,
	_spread_max = 0,
	_tracer = "railgun",
	_phys_alt = 0.25,
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
	mesh = "railgun_reload_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "rail_bg",
	_kf_name = "Railgun",
	_damage = 85,
	_mag = 4,
	_reset_node = "weapons:railgun",
	_tp_model = "railgun_tp.x",
	_fov_mult = 0,
	_type = "gun",
	_ammo_type = "primary",
	_phys_alt = 0.85,
	
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
}, "railgun.png", "sniper_class")