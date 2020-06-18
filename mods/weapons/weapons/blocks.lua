minetest.register_node(":core:team_neutral", {
	tiles = {"core_neutral.png"},
	range = 3,
	node_placement_prediction = "",

	_ammo_bg = "block_bg",
	_ammo_type = "blocks",
	_alt_mode = "core:slab_neutral",
	_fov_mult = 0,
	_crosshair = "railgun_crosshair.png",
	_type = "block",
	_node = "team",
	_firing_sound = "block_place.ogg",
	_casing_sound = "no_sound",
	_reload_sound = "no_sound",
	_tp_model = "cube.x",
	_name = "block",
	_pellets = 1,
	--_mag = 50,
	_rpm = 480,
	_reload = 10,
	_speed = 2000,
	_range = 3,
	_break_hits = 4,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = false,
	_phys_alt = 1,
	on_fire = weapons.place_block,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
	--sounds = weapons.sound_wood,
})

minetest.register_node(":core:lamp_neutral", {
	tiles = {"core_neutral_lamp.png"},
	range = 3,
	node_placement_prediction = "",

	_ammo_bg = "block_bg",
	_ammo_type = "blocks",
	_alt_mode = "core:team_neutral",
	_fov_mult = 0,
	_crosshair = "railgun_crosshair.png",
	_node = "lamp",
	_type = "block",
	_firing_sound = "block_place.ogg",
	_casing_sound = "no_sound",
	_reload_sound = "no_sound",
	_tp_model = "cube.x",
	_name = "block",
	_pellets = 1,
	--_mag = 50,
	_rpm = 480,
	_reload = 10,
	_speed = 2000,
	_range = 3,
	_break_hits = 4,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = false,
	_phys_alt = 1,
	on_fire = weapons.place_block,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
	--sounds = weapons.sound_wood,
})

minetest.register_node(":core:slab_neutral", {
	tiles = {"core_neutral.png"},
	range = 3,
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
	},
	node_placement_prediction = "",

	_ammo_bg = "block_bg",
	_ammo_type = "blocks",
	_alt_mode = "core:lamp_neutral",
	_fov_mult = 0,
	_crosshair = "railgun_crosshair.png",
	_node = "slab",
	_type = "block",
	_firing_sound = "block_place.ogg",
	_casing_sound = "no_sound",
	_reload_sound = "no_sound",
	_tp_model = "slab.x",
	_name = "block",
	_pellets = 1,
	--_mag = 50,
	_rpm = 480,
	_reload = 10,
	_speed = 2000,
	_range = 3,
	_break_hits = 4,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = false,
	_phys_alt = 1,
	on_fire = weapons.place_block,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})