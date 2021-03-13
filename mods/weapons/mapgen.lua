local c_mg_oak_sap = minetest.get_content_id("core:mg_oak_sapling")
local c_mg_pine_sap = minetest.get_content_id("core:mg_pine_sapling")
local c_mg_pine_snowy_sap = minetest.get_content_id("core:mg_pine_snowy_sapling")

mcore = {}

local path = minetest.get_modpath("weapons")
local base = "/base.mts"

local function generate_base_at(pos, area, area_max)
	for x=area.x, area_max.x do
		for z=area.z, area_max.z do
			for y=area.y, area_max.y do
				minetest.forceload_block({x=x, y=y, z=z}, false)
			end
		end
	end
	minetest.place_schematic(pos, path..base, "0", nil, true)
end

local red = 207-42
local blu = 192-42

local function generate_base_schem()
	--42 blocks from map edge
	generate_base_at(
		{x=red, y=weapons.red_base_y-2, z=red}, 
		{x=165, y=weapons.red_base_y-2, z=165}, 
		{x=171, y=weapons.red_base_y+12, z=171}
	)

	-- 42 blocks from map edge
	generate_base_at(
		{x=-blu, y=weapons.blu_base_y-2, z=-blu}, 
		{x=-150, y=weapons.blu_base_y-2, z=-150}, 
		{x=-144, y=weapons.blu_base_y+12, z=-144}
	)

	-- Fix broken things due to caves
	minetest.after(15, generate_base_schem)
end

local rattempts = 1
local battempts = 1
local function set_base_y()
	weapons.red_base_y = minetest.get_spawn_level(red, red)
	weapons.blu_base_y = minetest.get_spawn_level(-blu, -blu)
	local rb_found = false
	local bb_found = false
	local after
	if rattempts > 10 then
		weapons.red_base_y = 192
		rb_found = true
	elseif weapons.red_base_y == nil then
		after = minetest.after(1, set_base_y)
		rattempts = rattempts + 1
	else
		rb_found = true
	end
	
	if battempts > 10 then
		weapons.blu_base_y = 192
		bb_found = true
	elseif weapons.blu_base_y == nil then
		if after == nil then
			minetest.after(1, set_base_y)
		end
		battempts = battempts + 1
	else
		bb_found = true
	end

	if rb_found and bb_found then
		minetest.after(2, generate_base_schem)
		weapons.hud.update_base_waypoint()
		minetest.chat_send_all("Bases correctly generated, respawns now functional.")
	end
end

minetest.after(1, set_base_y)


function plant_options(meshtype, horizontal, height, size)
	local pshape, bit1, bit2, bit3 = 0, 0, 0, 0

	if meshtype == "cross" then
		pshape = 0
	elseif meshtype == "plus" then
		pshape = 1
	elseif meshtype == "asterisk" then
		pshape = 2
	elseif meshtype == "croplike" then
		pshape = 3
	elseif meshtype == "excroplike" then
		pshape = 4
	end
	
	if horizontal then
		bit1 = 8
	end
	
	if size then
		bit2 = 16
	end
	
	if height then
		bit3 = 32
	end
	
	return pshape+bit1+bit2+bit3
end

minetest.register_on_generated(function(minp, maxp, seed)
	local timer = os.clock()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	for z=minp.z, maxp.z, 1 do
		for y=minp.y, maxp.y, 1 do
			for x=minp.x, maxp.x, 1 do
				local p_pos = area:index(x,y,z)
				local content_id = data[p_pos]				
				if content_id == c_mg_oak_sap then
					mcore.grow_tree({x=x, y=y, z=z}, false, "core:azan_log_4", "core:azan_leaves_4", nil, nil)
				elseif content_id == c_mg_pine_sap then
					mcore.grow_pine({x=x, y=y, z=z}, false)
				elseif content_id == c_mg_pine_snowy_sap then
					mcore.grow_pine({x=x, y=y, z=z}, true)
				end
			end
		end
	end	
	vm:set_data(data)
	vm:update_liquids()
	vm:update_map()
end)

-- Pine Trees

local random = math.random

local function add_pine_needles(data, vi, c_air, c_ignore)
	if data[vi] == c_air or data[vi] == c_ignore then
		data[vi] = minetest.get_content_id("core:reiz_needles_4")
	end
end

local function add_pine_snow(data, vi, c_air, c_ignore)
	if data[vi] == c_air or data[vi] == c_ignore then
		data[vi] = minetest.get_content_id("core:reiz_needles_snowy_4")
	end
end

local function add_snow(data, vi, c_air, c_ignore)
	if data[vi] == c_air or data[vi] == c_ignore then
		data[vi] = minetest.get_content_id("core:snow_4")
	end
end

function mcore.grow_pine(pos, boolsnow)
	local x, y, z = pos.x, pos.y, pos.z
	local maxy = y + math.random(7, 13) --trunk top
	
	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")
	local c_pinetree = minetest.get_content_id("core:reiz_log_4")
	local c_pine_needles = minetest.get_content_id("core:reiz_needles_4")
	local c_snow = minetest.get_content_id("core:snow_4")
	local c_snowblock = minetest.get_content_id("core:snowblock_4")
	local c_dirtsnow = minetest.get_content_id("core:grass_snow_4")
	
	local vm = minetest.get_voxel_manip()
	local minp, maxp = vm:read_from_map(
		{x = x - 3, y = y - 1, z = z - 3},
		{x = x + 3, y = maxy + 3, z = z + 3}
	)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()
	
	--upper branches
	
	local dev = 3
	for yy = maxy - 1, maxy + 1 do
		for zz = z - dev, z + dev do
			local vi = a:index(x - dev, yy, zz)
			for xx = x - dev, x + dev do
				if math.random() < 0.95 - dev * 0.05 then
					if boolsnow == false then
						add_pine_needles(data, vi, c_air, c_ignore)
					elseif boolsnow == true then
						add_pine_snow(data, vi, c_air, c_ignore)
					else
						add_pine_needles(data, vi, c_air, c_ignore)
					end
				end
				vi  = vi + 1
			end
		end
		dev = dev - 1
	end
	
	--center top nodes
	
	if boolsnow == false then
		add_pine_needles(data, a:index(x, maxy + 1, z), c_air, c_ignore)
		add_pine_needles(data, a:index(x, maxy + 2, z), c_air, c_ignore)
		-- Paramat added a pointy top node
	elseif boolsnow == true then
		add_pine_snow(data, a:index(x, maxy + 1, z), c_air, c_ignore)
		add_pine_snow(data, a:index(x, maxy + 1, z), c_air, c_ignore)
	-- Lower branches layer
	else
		add_pine_needles(data, a:index(x, maxy + 1, z), c_air, c_ignore)
		add_pine_needles(data, a:index(x, maxy + 1, z), c_air, c_ignore)
	end
	
	local my = 0
	for i = 1, 20 do -- Random 2x2 squares of needles
		local xi = x + math.random(-3, 2)
		local yy = maxy + math.random(-6, -5)
		local zi = z + math.random(-3, 2)
		if yy > my then
			my = yy
		end
		for zz = zi, zi+1 do
			local vi = a:index(xi, yy, zz)
			for xx = xi, xi + 1 do
				if boolsnow == false then
					add_pine_needles(data, vi, c_air, c_ignore)
				elseif boolsnow == true then
					add_pine_snow(data, vi, c_air, c_ignore)
					add_pine_needles(data, vi, c_air, c_ignore)
				else
					add_pine_snow(data, vi, c_air, c_ignore)
				end
				vi  = vi + 1
			end
		end
	end

	local dev = 2
	for yy = my + 1, my + 2 do
		for zz = z - dev, z + dev do
			local vi = a:index(x - dev, yy, zz)
			for xx = x - dev, x + dev do
				if random() < 0.95 - dev * 0.05 then
					if boolsnow == false then
						add_pine_needles(data, vi, c_air, c_ignore)
					elseif boolsnow == true then
						add_pine_snow(data, vi, c_air, c_ignore)
						add_pine_needles(data, vi, c_air, c_ignore)
					else
						add_pine_snow(data, vi, c_air, c_ignore)
					end
				end
				vi  = vi + 1
			end
		end
		dev = dev - 1
	end

	-- Trunk
	for yy = y, maxy do
		local vi = a:index(x, yy, z)
		data[vi] = c_pinetree
	end

	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
end

--standard trees

local function add_trunk_and_leaves(data, a, pos, tree_cid, leaves_cid,
		height, size, iters, is_apple_tree, log_grass)
	local x, y, z = pos.x, pos.y, pos.z
	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")
	local c_apple = minetest.get_content_id("air")
	
	-- Trunk
	for y_dist = 0, height - 1 do
		local vi = a:index(x, y + y_dist, z)
		local node_id = data[vi]
		
		if y_dist == 0 then
		
			data[vi] = log_grass
		
		elseif node_id == c_air or node_id == c_ignore
		or node_id == leaves_cid then
			
			data[vi] = tree_cid
			
		end
		
	end

	-- Force leaves near the trunk
	for z_dist = -1, 1 do
	for y_dist = -size, 1 do
		local vi = a:index(x - 1, y + height + y_dist, z + z_dist)
		for x_dist = -1, 1 do
			if data[vi] == c_air or data[vi] == c_ignore then
				if is_apple_tree and random(1, 8) == 1 then
					data[vi] = c_apple
				else
					data[vi] = leaves_cid
				end
			end
			vi = vi + 1
		end
	end
	end

	-- Randomly add leaves in 2x2x2 clusters.
	for i = 1, iters do
		local clust_x = x + random(-size, size - 1)
		local clust_y = y + height + random(-size, 0)
		local clust_z = z + random(-size, size - 1)

		for xi = 0, 1 do
		for yi = 0, 1 do
		for zi = 0, 1 do
			local vi = a:index(clust_x + xi, clust_y + yi, clust_z + zi)
			if data[vi] == c_air or data[vi] == c_ignore then
				if is_apple_tree and random(1, 8) == 1 then
					data[vi] = c_apple
				else
					data[vi] = leaves_cid
				end
			end
		end
		end
		end
	end
end

function mcore.grow_tree(pos, is_apple_tree, trunk_node, leaves_node, fallen_leaves_node, chance)
	--[[
		NOTE: Tree-placing code is currently duplicated in the engine
		and in games that have saplings; both are deprecated but not
		replaced yet
	--]]
	
	if fallen_leaves_node ~= nil or chance ~= nil then
		place_leaves_on_ground(pos, chance, fallen_leaves_node)
	end
	
	local x, y, z = pos.x, pos.y, pos.z
	local height = random(4, 7)
	local c_tree = minetest.get_content_id(trunk_node)
	local c_leaves = minetest.get_content_id(leaves_node)
	local log_grass = minetest.get_content_id(trunk_node)
	
	local vm = minetest.get_voxel_manip()
	local minp, maxp = vm:read_from_map(
		{x = pos.x - 2, y = pos.y, z = pos.z - 2},
		{x = pos.x + 2, y = pos.y + height + 1, z = pos.z + 2}
	)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()
	
	add_trunk_and_leaves(data, a, pos, c_tree, c_leaves, height, 2, 8, is_apple_tree, log_grass)
	
	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
end

-- Biomes

minetest.register_biome({
	name = "plains",
	node_top = "core:grass_4",
	depth_top = 1,
	node_filler = "core:dirt_4",
	depth_filler = 3,
	y_min = 1,
	y_max = 120,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	heat_point = 45,
	humidity_point = 50,
})

minetest.register_biome({
	name = "highlands",
	node_top = "core:grass_4",
	depth_top = 1,
	node_filler = "core:dirt_4",
	depth_filler = 3,
	y_min = 4,
	y_max = 220,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	heat_point = 45,
	humidity_point = 76,
})

minetest.register_biome({
	name = "plains_forest",
	node_top = "core:grass_4",
	depth_top = 1,
	node_filler = "core:dirt_4",
	depth_filler = 3,
	y_min = 4,
	y_max = 80,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	heat_point = 45,
	humidity_point = 10,
})

minetest.register_biome({
	name = "beach",
	node_top = "core:sand_4",
	depth_top = 1,
	node_filler = "core:sand_4",
	depth_filler = 3,
	y_min = 0,
	y_max = 4,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	heat_point = 45,
	humidity_point = 35,
})

minetest.register_biome({
	name = "gravel_beach",
	node_top = "core:sand_4",
	depth_top = 1,
	node_filler = "core:sand_4",
	depth_filler = 3,
	y_min = 0,
	y_max = 4,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	heat_point = 45,
	humidity_point = 76,
})

minetest.register_biome({
	name = "beach_cold",
	node_dust = "core:snow_4",
	node_top = "core:sand_4",
	depth_top = 1,
	node_filler = "core:sand_4",
	depth_filler = 3,
	y_min = 0,
	y_max = 4,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	node_water_top = "core:ice_4",
	depth_water_top = 1,
	heat_point = 20,
	humidity_point = 35,
})

minetest.register_biome({
	name = "snowy_plains",
	node_dust = "core:snow_4",
	node_top = "core:grass_snow_4",
	depth_top = 1,
	node_filler = "core:dirt_4",
	depth_filler = 3,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	node_water_top = "core:ice_4",
	depth_water_top = 1,
	y_min = 4,
	y_max = 150,
	heat_point = 20,
	humidity_point = 50,
})

minetest.register_biome({
	name = "snowy_mountain",
	node_dust = "core:snow_4",
	node_top = "core:snowblock_4",
	depth_top = 1,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	node_water_top = "core:ice_4",
	depth_water_top = 1,
	y_min = 150,
	y_max = 1000,
	heat_point = 50,
	humidity_point = 50,
})

minetest.register_biome({
	name = "snowy_forest",
	node_dust = "core:snow_4",
	node_top = "core:grass_snow_4",
	depth_top = 1,
	node_filler = "core:dirt_4",
	depth_filler = 3,
	y_min = 30,
	y_max = 150,
	node_water = "core:water_source",
	node_river_water = "core:water_source",
	node_water_top = "core:ice_4",
	depth_water_top = 1,
	heat_point = 12,
	humidity_point = 25,
})

-- Decorations

minetest.register_decoration({
	deco_type = "simple",
	place_on = "core:grass_4",
	decoration = {"core:mg_pine_sapling"},
	sidelen = 16,
	fill_ratio = 0.025,
	biomes = {"highlands"},
	height = 1,
})

minetest.register_decoration({
	deco_type = "simple",
	place_on = "core:grass_4",
	decoration = {"core:mg_oak_sapling"},
	sidelen = 16,
	fill_ratio = 0.01,
	biomes = {"plains_forest"},
	height = 1,
})

minetest.register_decoration({
	deco_type = "simple",
	place_on = {"core:grass_4"},
	decoration = {"core:mg_oak_sapling"},
	sidelen = 80,
	fill_ratio = 0.0001,
	biomes = {"plains"},
	height = 1,
})

minetest.register_decoration({
	deco_type = "simple",
	place_on = "core:grass_4",
	decoration = {"core:longgrass_1", "core:longgrass_2", "core:longgrass_3"},
	sidelen = 16,
	fill_ratio = 0.2,
	biomes = {"plains", "plains_forest", "highlands"},
	height = 1,
	param2 = plant_options("cross", true, true, false),
})