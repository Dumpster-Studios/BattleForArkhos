minetest.register_node("weapons:pickaxe", {
	tiles = {
		"pickaxe.png",
		"transparent.png",
	},
	drawtype = "mesh",
	mesh = "pickaxe_fp.b3d",
	range = 3,
	node_placement_prediction = "",

	_ammo_bg = "block_bg",
	_ammo_type = "blocks",
	_kf_name = "Pickaxe",
	_alt_mode = "weapons:pickaxe_alt",
	_fov_mult = 0,
	_type = "tool",
	_crosshair = "railgun_crosshair.png",
	_firing_sound = "pickaxe_swing.ogg",
	_name = "pickaxe",
	_damage = 75,
	_rpm = 50,
	_reload = 0.01,
	_speed = 2000,
	_range = 3,
	_break_hits = 2,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = false,
	_phys_alt = 1,
	on_fire = weapons.raycast_melee,
	melee_on_hit = weapons.melee_on_hit,
	_fatigue = 0,
	_fatigue_timer = 0.1,
	_fatigue_recovery = 0.09,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})

minetest.register_node("weapons:pickaxe_alt", {
	tiles = {
		"pickaxe.png",
		"transparent.png",
	},
	drawtype = "mesh",
	mesh = "pickaxe_alt_fp.b3d",
	range = 3,
	node_placement_prediction = "",

	_kf_name = "Entrenching Tool",
	_alt_mode = "weapons:pickaxe",
	_fov_mult = 0,
	_type = "tool_alt",
	_crosshair = "railgun_crosshair.png",
	_firing_sound = "pickaxe_swing.ogg",
	_tp_model = "pickaxe_alt.x",
	_name = "pickaxe",
	_damage = 75,
	_rpm = 50,
	_reload = 0.01,
	_speed = 2000,
	_range = 3,
	_break_hits = 4,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = false,
	_phys_alt = 1,
	_is_alt = true,
	on_fire = weapons.raycast_melee,
	melee_on_hit = weapons.melee_on_hit,
	_fatigue = 0,
	_fatigue_timer = 0.1,
	_fatigue_recovery = 0.09,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})

minetest.register_node("weapons:flag_red", {
	tiles = {
		"flag_red.png",
		"transparent.png"
	},
	drawtype = "mesh",
	mesh = "flag_fp.b3d",
	range = 0,
	node_placement_prediction = "",
	stack_max = 1,
	
	_ammo_bg = "flag_bg",
	_kf_name = "motherfuckin' Red Flag",
	_fov_mult = 0,
	_type = "flag",
	_crosshair = "railgun_crosshair.png",
	_firing_sound = "flag_swing",
	_tp_model = "flag_tp.x",
	_name = "flag_red",
	_damage = 55,
	_rpm = 50,
	_reload = 0.01,
	_speed = 2000,
	_range = 3,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = 0,
	_phys_alt = 0.75,
	on_fire = weapons.raycast_flag_melee,
	flag_on_hit = weapons.flag_on_hit,
	_fatigue = 0,
	_fatigue_timer = 0.1,
	_fatigue_recovery = 0.09,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})

minetest.register_node("weapons:flag_blue", {
	tiles = {
		"flag_blue.png",
		"transparent.png"
	},
	drawtype = "mesh",
	mesh = "flag_fp.b3d",
	range = 0,
	node_placement_prediction = "",
	stack_max = 1,

	_ammo_bg = "flag_bg",
	_kf_name = "motherfuckin' Blue Flag",
	_fov_mult = 0,
	_type = "flag",
	_crosshair = "railgun_crosshair.png",
	_firing_sound = "flag_swing",
	_tp_model = "flag_tp.x",
	_name = "flag_blue",
	_damage = 75,
	_rpm = 50,
	_reload = 0.01,
	_speed = 2000,
	_range = 3,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = 0,
	_phys_alt = 0.75,
	_fatigue = 0,
	_fatigue_timer = 0.1,
	_fatigue_recovery = 0.09,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})