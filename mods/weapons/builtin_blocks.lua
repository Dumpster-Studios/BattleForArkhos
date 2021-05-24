-- Minetest Bullshit

minetest.register_alias("mapgen_stone", "core:stone_4")
minetest.register_alias("mapgen_dirt", "core:dirt_4")
minetest.register_alias("mapgen_dirt_with_grass", "core:grass_4")
minetest.register_alias("mapgen_sand", "core:sand_4")
minetest.register_alias("mapgen_water_source", "core:water_source")
minetest.register_alias("mapgen_river_water_source", "core:water_source")
minetest.register_alias("mapgen_gravel", "core:gravel_4")
minetest.register_alias("mapgen_dirt_with_snow", "core:grass_snow_4")
minetest.register_alias("mapgen_snowblock", "core:snowblock_4")
minetest.register_alias("mapgen_snow", "core:snow_4")
minetest.register_alias("mapgen_ice", "core:ice_4")

-- Mapgen Specific:

minetest.register_node(":core:mg_oak_sapling", {
	description = "Impossible to get node.",
	drawtype = "airlike",
	paramtype = "light",
	groups = {not_in_creative_inventory=1},
})

minetest.register_node(":core:mg_pine_sapling", {
	description = "Impossible to get node.",
	drawtype = "airlike",
	paramtype = "light",
	groups = {not_in_creative_inventory=1},
})

minetest.register_node(":core:mg_pine_snowy_sapling", {
	description = "Impossible to get node.",
	drawtype = "airlike",
	paramtype = "light",
	groups = {not_in_creative_inventory=1},
})

minetest.register_node(":core:water_source", {
	description = "Water Source (Can Self Replish)",
	drawtype = "liquid",
	tiles = {
		{
			name = "core_water_source_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5,
			},
		},
	},
	special_tiles = {
		{
			name = "core_water_source_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5,
			},
			backface_culling = true,
		},
	},
	--alpha = 153,
	use_texture_alpha = true,
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "core:water_flowing",
	liquid_alternative_source = "core:water_source",
	liquid_viscosity = 1,
	post_effect_color = {a = 153, r = 18, g = 78, b = 137},
	groups = {water = 3, source = 1, puts_out_fire = 1, can_grow = 1},
	_no_particles = true,
})

minetest.register_node(":core:water_flowing", {
	description = "Flowing Water",
	drawtype = "flowingliquid",
	tiles = {"core_water.png"},
	special_tiles = {
		{
			name = "core_water_flowing_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.8,
			},
		},
		{
			name = "core_water_flowing_animated.png",
			backface_culling = true,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.8,
			},
		},
	},
	--alpha = 153,
	use_texture_alpha = true,
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "core:water_flowing",
	liquid_alternative_source = "core:water_source",
	liquid_viscosity = 1,
	post_effect_color = {a = 153, r = 18, g = 78, b = 137},
	groups = {water = 3, flowing = 1, puts_out_fire = 1, can_grow = 1, not_in_creative_inventory = 1},
	_no_particles = true,
})

-- Grasses:

for i=1, 3 do
	minetest.register_node(":core:longgrass_"..i, {
		tiles = {"core_long_grass_"..i..".png"},
		waving = 1,
		drawtype = "plantlike",
		paramtype = "light",
		paramtype2 = "meshoptions",
		visual_scale = 1.0,
		walkable = false,
		buildable_to = true,
		sunlight_propagates = true,
		groups = {attached_node=1},
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
		_no_particles = true,
		--sounds = mcore.sound_plants,
	})
end

function weapons.register_block(name, params)
	local n_tiles_3 = {}
	local n_tiles_2 = {}
	local n_tiles_1 = {}

	for k, v in pairs(params.tiles) do
		n_tiles_3[k] = v .. "^core_block_health_3.png"
		n_tiles_2[k] = v .. "^core_block_health_2.png"
		n_tiles_1[k] = v .. "^core_block_health_1.png"
	end
	
	local n_params_4 = table.copy(params)
	local n_params_3 = table.copy(params)
	local n_params_2 = table.copy(params)
	local n_params_1 = table.copy(params)

	n_params_3.tiles = n_tiles_3
	n_params_2.tiles = n_tiles_2
	n_params_1.tiles = n_tiles_1

	n_params_4._health = 4
	n_params_3._health = 3
	n_params_2._health = 2
	n_params_1._health = 1

	n_params_4._name = name
	n_params_3._name = name
	n_params_2._name = name
	n_params_1._name = name

	n_params_1.groups = {falling_node=1}
	n_params_2.groups = {falling_node=1}
	
	minetest.register_node(":"..name.."_4", n_params_4)
	minetest.register_node(":"..name.."_3", n_params_3)
	minetest.register_node(":"..name.."_2", n_params_2)
	minetest.register_node(":"..name.."_1", n_params_1)
end

-- Game blocks:

weapons.register_block("core:dirt", {
	tiles = {"core_dirt.png"},
	is_ground_content = true,
	--sounds = weapons.sound_dirt,
})

weapons.register_block("core:grass", {
	tiles = {"core_grass.png", "core_dirt.png", "core_dirt.png^core_grass_side.png"},
	is_ground_content = true,
	--sounds = weapons.sound_dirt,
})

weapons.register_block("core:grass_snow", {
	tiles = {"core_snow.png", "core_dirt.png", "core_dirt.png^core_snow_side.png"},
	is_ground_content = true,
	--sounds = weapons.sound_dirt,
})

weapons.register_block("core:sand", {
	tiles = {"core_sand.png"},
	is_ground_content = true,
	groups = {falling_node=1},
	--sounds = weapons.sound_sand,
})

weapons.register_block("core:gravel", {
	tiles = {"core_gravel.png"},
	is_ground_content = true,
	groups = {falling_node=1},
	--sounds = weapons.sound_gravel,
})

weapons.register_block("core:snow", {
	tiles = {"core_snow.png"},
	paramtype = "light",
	buildable_to = true,
	floodable = true,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.2, 0.5},
		},
	},
	walkable = false,
	is_ground_content = true,
	groups = {falling_node=1},
	--sounds = weapons.sound_snow,
})

weapons.register_block("core:snowblock", {
	tiles = {"core_snow.png"},
	is_ground_content = true,
	--sounds = weapons.sound_snow,
})

weapons.register_block("core:ice", {
	tiles = {"core_ice.png"},
	is_ground_content = true,
	paramtype = "light",
	--sounds = weapons.sound_glass,
})

weapons.register_block("core:stone", {
	tiles = {"core_stone.png"},
	is_ground_content = true,
	--sounds = weapons.sound_stone,
})

weapons.register_block("core:cobble", {
	tiles = {"core_cobble.png"},
	is_ground_content = true,
	--sounds = weapons.sound_stone,
})

weapons.register_block("core:mossycobble", {
	tiles = {"core_cobble_mossy.png"},
	is_ground_content = true,
	--sounds = weapons.sound_stone,
})

weapons.register_block("core:azan_log", {
	tiles = {"core_azan_log_top.png", "core_azan_log_top.png", "core_azan_log.png"},
	--sounds = weapons.sound_wood,
})

weapons.register_block("core:azan_leaves", {
	tiles = {"core_azan_leaves.png"},
	drawtype = "allfaces_optional",
	waving = 1,
	paramtype = "light",
	--sounds = weapons.sound_plants,
})

weapons.register_block("core:reiz_log", {
	tiles = {"core_reiz_log_top.png", "core_reiz_log_top.png", "core_reiz_log.png"},
	--sounds = weapons.sound_wood,
})

weapons.register_block("core:reiz_needles", {
	tiles = {"core_reiz_needles.png"},
	drawtype = "allfaces_optional",
	waving = 1,
	paramtype = "light",
	--sounds = weapons.sound_plants,
})

weapons.register_block("core:reiz_needles_snowy", {
	tiles = {"core_reiz_needles_snowy.png"},
	drawtype = "allfaces_optional",
	waving = 1,
	paramtype = "light",
	--sounds = weapons.sound_plants,
})

weapons.register_block("core:team_red", {
	tiles = {"core_team_red.png"},
	--sounds = weapons.sound_wood
})

weapons.register_block("core:team_blue", {
	tiles = {"core_team_blue.png"},
	--sounds = weapons.sound_wood
})

weapons.register_block("core:lamp_red", {
	tiles = {"core_lamp_red.png"},
	paramtype = "light",
	light_source = 14
})

weapons.register_block("core:lamp_blue", {
	tiles = {"core_lamp_blue.png"},
	paramtype = "light",
	light_source = 14
})

weapons.register_block("core:slab_red", {
	tiles = {"core_team_red.png"},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
	},
})

weapons.register_block("core:slab_blue", {
	tiles = {"core_team_blue.png"},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
	},
})

minetest.register_node(":core:base_block", {
	tiles = {"core_neutral.png"},
	_takes_damage = false,
	_health = 100,
})

minetest.register_node(":core:base_door", {
	walkable = false,
	paramtype = "light",
	pointable = false,
	drawtype = "airlike",
	_takes_damage = false,
	sunlight_propagates = true,
	--tiles = {"core_azan_leaves.png"},
	--drawtype = "allfaces_optional",
	_health = 100,
})

local function rotate_and_place(itemstack, placer, pointed_thing)
	local p0 = pointed_thing.under
	local p1 = pointed_thing.above
	local param2 = 0

	if placer then
		local placer_pos = placer:get_pos()
		if placer_pos then
			param2 = minetest.dir_to_facedir(vector.subtract(p1, placer_pos))
		end

		local finepos = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
		local fpos = finepos.y % 1

		if p0.y - 1 == p1.y or (fpos > 0 and fpos < 0.5)
				or (fpos < -0.5 and fpos > -0.999999999) then
			param2 = param2 + 20
			if param2 == 21 then
				param2 = 23
			elseif param2 == 23 then
				param2 = 21
			end
		end
	end
	return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

minetest.register_node(":core:base_slab", {
	_takes_damage = false,
	_health = 100,
	tiles = {"core_neutral.png"},
	paramtype = "light",
	drawtype = "nodebox",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
	},
	on_place = function(itemstack, placer, pointed_thing)
		local under = minetest.get_node(pointed_thing.under)
		local wield_item = itemstack:get_name()
		local player_name = placer and placer:get_player_name() or ""
		local creative_enabled = (creative and creative.is_enabled_for
				and creative.is_enabled_for(player_name))

		if under and under.name:find("^stairs:slab_") then
			-- place slab using under node orientation
			local dir = minetest.dir_to_facedir(vector.subtract(
				pointed_thing.above, pointed_thing.under), true)

			local p2 = under.param2

			-- Placing a slab on an upside down slab should make it right-side up.
			if p2 >= 20 and dir == 8 then
				p2 = p2 - 20
			-- same for the opposite case: slab below normal slab
			elseif p2 <= 3 and dir == 4 then
				p2 = p2 + 20
			end

			-- else attempt to place node with proper param2
			minetest.item_place_node(ItemStack(wield_item), placer, pointed_thing, p2)
			if not creative_enabled then
				itemstack:take_item()
			end
			return itemstack
		else
			return rotate_and_place(itemstack, placer, pointed_thing)
		end
	end,
})

minetest.register_node(":core:base_stair", {
	_takes_damage = false,
	_health = 100,
	tiles = {"core_neutral.png"},
	paramtype = "light",
	drawtype = "nodebox",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
			{-0.5, 0, 0, 0.5, 0.5, 0.5},
		},
	},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		return rotate_and_place(itemstack, placer, pointed_thing)
	end,
})

minetest.register_node(":core:base_lamp", {
	_takes_damage = false,
	_health = 100,
	tiles = {"core_neutral_lamp.png"},
	paramtype = "light",
	light_source = 14
})