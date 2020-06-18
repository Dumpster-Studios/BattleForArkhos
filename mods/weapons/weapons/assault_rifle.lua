weapons.register_weapon("weapons:assault_rifle",
{ -- Default
	drawtype = "mesh",
	mesh = "assault_rifle_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "bullet_bg",
	_kf_name = "Assault Rifle",
	_fov_mult = 0,
	_crosshair = "assault_crosshair.png",
	_type = "gun",
	_ammo_type = "primary",
	_firing_sound = "ass_rifle_fire",
	_casing_sound = "ass_rifle_casing",
	_reload_sound = "ass_rifle_reload",
	_name = "assault_rifle",
	_pellets = 1,
	_mag = 30,
	_rpm = 500,
	_reload = 3,
	_speed = 800, -- Meters per second
	_range = 150,
	_damage = 10,
	_break_hits = 1,
	_recoil = 2.5,
	_spread_min = -4,
	_spread_max = 4,
	_tracer = "ar",
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
{ -- Alt
	drawtype = "mesh",
	mesh = "assault_rifle_alt_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "bullet_bg",
	_kf_name = "Assault Rifle",
	_fov_mult = 0.75,
	_crosshair = "railgun_crosshair.png",
	_type = "gun",
	_ammo_type = "primary",
	_firing_sound = "ass_rifle_fire",
	_casing_sound = "ass_rifle_casing", 
	_reload_sound = "ass_rifle_reload",
	_name = "assault_rifle",
	_pellets = 1,
	_mag = 30,
	_rpm = 125,
	_reload = 3,
	_speed = 800, -- Meters per second
	_range = 150,
	_damage = 20,
	_break_hits = 3,
	_recoil = 1.5,
	_spread_min = 0,
	_spread_max = 0,
	_tracer = "ar",
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
{ -- Reloading
	--tiles = {"assault_rifle.png", "assault_class_blue.png"},
	drawtype = "mesh",
	mesh = "assault_rifle_reload_fp.b3d",
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "bullet_bg",
	_kf_name = "Assault Rifle",
	_damage = 10,
	_mag = 30,
	_fov_mult = 0,
	_type = "gun",
	_ammo_type = "primary",
	_phys_alt = 0.75,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
}, "assault_rifle.png", "assault_class")
