function weapons.register_weapon(name, def, def_alt, def_reload, texture, class_name)
	-- Red Team
	
	local node = table.copy(def)
	local node_alt = table.copy(def_alt)
	local node_reload = table.copy(def_reload)
	
	node.tiles = {texture, class_name .. "_red.png"}
	node._alt_mode = name .. "_alt_red"
	node._reload_node = name .. "_reload_red"
	node.node_placement_prediction = ""
	
	node_alt.tiles = {texture, class_name .. "_red.png"}
	node_alt._alt_mode = name .. "_red"
	node_alt._reload_node = name .. "_reload_red"
	node_alt.node_placement_prediction = ""
	
	node_reload.tiles = {texture, class_name .. "_red.png"}
	node_reload._reset_node = name .. "_red"
	node_reload.node_placement_prediction = ""

	minetest.register_node(name .. "_red", node)
	minetest.register_node(name .. "_alt_red", node_alt)
	minetest.register_node(name .. "_reload_red", node_reload)

	-- Blue Team

	node = table.copy(def)
	node_alt = table.copy(def_alt)
	node_reload = table.copy(def_reload)
	
	node.tiles = {texture, class_name .. "_blue.png"}
	node._alt_mode = name .. "_alt_blue"
	node._reload_node = name .. "_reload_blue"
	node.node_placement_prediction = ""

	node_alt.tiles = {texture, class_name .. "_blue.png"}
	node_alt._alt_mode = name .. "_blue"
	node_alt._reload_node = name .. "_reload_blue"
	node_alt.node_placement_prediction = ""

	node_reload.tiles = {texture, class_name .. "_blue.png"}
	node_reload._reset_node = name .. "_blue"
	node_alt.node_placement_prediction = ""
	
	minetest.register_node(name .. "_blue", node)
	minetest.register_node(name .. "_alt_blue", node_alt)
	minetest.register_node(name .. "_reload_blue", node_reload)
end

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
	_recoil = 3,
	_spread_min = -4,
	_spread_max = 4,
	_tracer = "ar",
	_phys_alt = 1,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
}, 
{ -- Alt
	drawtype = "mesh",
	mesh = "rocket_launcher_fp.b3d", --assault_rifle_alt_fp.b3d
	use_texture_alpha = true,
	range = 1,

	_ammo_bg = "rocket_bg",
	_kf_name = "Rocket Launcher",
	_fov_mult = 0.75,
	_crosshair = "railgun_crosshair.png",
	_type = "rocket", --gun
	_ammo_type = "primary",
	_firing_sound = "rocket_launch", --ass_rifle_fire
	_casing_sound = "ass_rifle_casing", --ass_rifle_casing
	_reload_sound = "ass_rifle_reload", --ass_rifle_reload
	_name = "assault_rifle",
	_pellets = 1,
	_mag = 30,
	_rpm = 125,
	_reload = 3,
	_speed = 800, -- Meters per second
	_range = 150,
	_damage = 65,
	_break_hits = 3,
	_recoil = 0,--1.5
	_spread_min = 0,
	_spread_max = 0,
	_tracer = "ar",
	_phys_alt = 1, --0.45

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
	_damage = 8,
	_heals = 5,
	_break_hits = 1,
	_recoil = 1.05,
	_spread_min = -7,
	_spread_max = 7,
	_tracer = "smg",
	_phys_alt = 1,

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
	_damage = 4,
	_heals = 10,
	_break_hits = 1,
	_recoil = 0.75,
	_spread_min = -4,
	_spread_max = 4,
	_tracer = "smg_alt",
	_phys_alt = 0.65,

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

weapons.register_weapon("weapons:shotgun",
{
	drawtype = "mesh",
	mesh = "shotgun_fp.b3d",
	range = 1,

	_ammo_bg = "shotgun_bg",
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
	_kf_name = "Shotgun",
	_damage = 6,
	_tp_model = "shotgun_tp.x",
	_reset_node = "weapons:shotgun",
	_mag = 2,
	_fov_mult = 0,
	_type = "gun",
	_phys_alt = 0.7,
	
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
},
"shotgun.png", "scout_class")

minetest.register_node(":core:team_neutral", {
	tiles = {"core_neutral.png"},
	range = 3,
	node_placement_prediction = "",

	_ammo_bg = "block_bg",
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
	_mag = 50,
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
	_mag = 50,
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
	_mag = 50,
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

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})

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
	_kf_name = "Pickaxe",
	_alt_mode = "weapons:pickaxe_alt",
	_fov_mult = 0,
	_type = "tool",
	_crosshair = "railgun_crosshair.png",
	_firing_sound = "pickaxe_swing.ogg",
	_name = "pickaxe",
	_pellets = 1,
	_damage = 75,
	_mag = 90,
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
	_pellets = 1,
	_mag = 90,
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
	
	_kf_name = "motherfuckin' Red Flag",
	_fov_mult = 0,
	_type = "flag",
	_crosshair = "railgun_crosshair.png",
	_firing_sound = "flag_swing",
	_tp_model = "flag_tp.x",
	_name = "flag_red",
	_pellets = 1,
	_mag = 90,
	_damage = 55,
	_rpm = 50,
	_reload = 0.01,
	_speed = 2000,
	_range = 3,
	_break_hits = 0,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = 0,
	_phys_alt = 0.75,

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

	_kf_name = "motherfuckin' Blue Flag",
	_fov_mult = 0,
	_type = "flag",
	_crosshair = "railgun_crosshair.png",
	_firing_sound = "flag_swing",
	_tp_model = "flag_tp.x",
	_name = "flag_red",
	_pellets = 1,
	_mag = 90,
	_damage = 75,
	_rpm = 50,
	_reload = 0.01,
	_speed = 2000,
	_range = 3,
	_break_hits = 0,
	_recoil = 0,
	_spread_min = 0,
	_spread_max = 0,
	_has_tracer = 0,
	_phys_alt = 0.75,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,

	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})

