-- Worldedit shite:

--- Copies and modifies positions `pos1` and `pos2` so that each component of
-- `pos1` is less than or equal to the corresponding component of `pos2`.
-- Returns the new positions.
function worldedit.sort_pos(pos1, pos2)
	pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
	pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end

--- Determines the volume of the region defined by positions `pos1` and `pos2`.
-- @return The volume.
function worldedit.volume(pos1, pos2)
	local pos1, pos2 = worldedit.sort_pos(pos1, pos2)
	return (pos2.x - pos1.x + 1) *
		(pos2.y - pos1.y + 1) *
		(pos2.z - pos1.z + 1)
end

--- Gets other axes given an axis.
-- @raise Axis must be x, y, or z!
function worldedit.get_axis_others(axis)
	if axis == "x" then
		return "y", "z"
	elseif axis == "y" then
		return "x", "z"
	elseif axis == "z" then
		return "x", "y"
	else
		error("Axis must be x, y, or z!")
	end
end

function worldedit.keep_loaded(pos1, pos2)
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(pos1, pos2)
end

local mh = {}
worldedit.manip_helpers = mh

--- Generates an empty VoxelManip data table for an area.
-- @return The empty data table.
function mh.get_empty_data(area)
	-- Fill emerged area with ignore so that blocks in the area that are
	-- only partially modified aren't overwriten.
	local data = {}
	local c_ignore = minetest.get_content_id("ignore")
	for i = 1, worldedit.volume(area.MinEdge, area.MaxEdge) do
		data[i] = c_ignore
	end
	return data
end


function mh.init(pos1, pos2)
	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	return manip, area
end


function mh.init_radius(pos, radius)
	local pos1 = vector.subtract(pos, radius)
	local pos2 = vector.add(pos, radius)
	return mh.init(pos1, pos2)
end


function mh.init_axis_radius(base_pos, axis, radius)
	return mh.init_axis_radius_length(base_pos, axis, radius, radius)
end


function mh.init_axis_radius_length(base_pos, axis, radius, length)
	local other1, other2 = worldedit.get_axis_others(axis)
	local pos1 = {
		[axis]   = base_pos[axis],
		[other1] = base_pos[other1] - radius,
		[other2] = base_pos[other2] - radius
	}
	local pos2 = {
		[axis]   = base_pos[axis] + length,
		[other1] = base_pos[other1] + radius,
		[other2] = base_pos[other2] + radius
	}
	return mh.init(pos1, pos2)
end


function mh.finish(manip, data)
	-- Update map
	if data ~= nil then
		manip:set_data(data)
	end
	manip:write_to_map()
	manip:calc_lighting(nil, true)
	manip:update_liquids()
end

--- Adds a sphere of `node_name` centered at `pos`.
-- @param pos Position to center sphere at.
-- @param radius Sphere radius.
-- @param node_name Name of node to make shere of.
-- @param hollow Whether the sphere should be hollow.
-- @return The number of nodes added.

function worldedit.sphere(pos, radius, node_name, hollow)
	local manip, area = mh.init_radius(pos, radius)

	local data = mh.get_empty_data(area)

	-- Fill selected area with node
	local node_id = minetest.get_content_id(node_name)
	local base_blocks = {}
	base_blocks[1] = "core:base_block"
	base_blocks[2] = "core:base_door"
	base_blocks[3] = "core:base_slab"
	base_blocks[4] = "core:base_stair"
	base_blocks[5] = "core:base_lamp"
	base_blocks[6] = "core:water_source"
	base_blocks[7] = "core:water_flowing"
	
	local min_radius, max_radius = radius * (radius - 1), radius * (radius + 1)
	local offset_x, offset_y, offset_z = pos.x - area.MinEdge.x, pos.y - area.MinEdge.y, pos.z - area.MinEdge.z
	local stride_z, stride_y = area.zstride, area.ystride
	local count = 0
	local npos = table.copy(pos)
	for z = -radius, radius do
		-- Offset contributed by z plus 1 to make it 1-indexed
		local new_z = (z + offset_z) * stride_z + 1
		for y = -radius, radius do
			local new_y = new_z + (y + offset_y) * stride_y
			for x = -radius, radius do
				local squared = x * x + y * y + z * z
				if squared <= max_radius and (not hollow or squared >= min_radius) then
					-- Position is on surface of sphere
					local i = new_y + (x + offset_x)
					local node_data = manip:get_node_at({
						x = npos.x + x,
						y = npos.y + y,
						z = npos.z + z
					})

					if node_data.name == base_blocks[1] then
					elseif node_data.name == base_blocks[2] then
					elseif node_data.name == base_blocks[3] then
					elseif node_data.name == base_blocks[4] then
					elseif node_data.name == base_blocks[5] then
					elseif node_data.name == base_blocks[6] then
					elseif node_data.name == base_blocks[7] then
					else data[i] = node_id
						count = count + 1
					end
				end
			end
		end
	end
	mh.finish(manip, data)
	return count
end
