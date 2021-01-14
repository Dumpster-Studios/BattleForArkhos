-- Persistence, a Lua library to load and save Minetest variable states on the fly without using world-saves.
-- Should be merged with SolarSail at some time in the near future.

persistence = {}
local path = minetest.get_modpath("persistence").."/db"
local filetype = ".prs"

local function log_message(message, filename)
	minetest.log("action", "[Persistence] "..message..": "..path.."/"..filename..".prs")
end

function persistence.load_data(filename, create_file)
	local data
	local file = io.open(path.."/"..filename..filetype, "r")

	if file then -- If a valid serialized DB exists, load it and return it.
		data = file:read()
		file:close()
		log_message("Loaded savedata from file", filename)
		return true, minetest.deserialize(data), false
	elseif create_file then -- If it doesn't but we want to create a file, do so here:
		local new_file = io.open(path.."/")
		log_message("Could not load savedata from missing file", filename)
		log_message("Created an empty savedata file at", filename)
		return false, {}, true
	else -- Otherwise, we just return a failover with no data.
		log_message("Could not load savedata from missing file", filename)
		return false, {}, false
	end
end

function persistence.save_data(filename, var)
	local file = io.open(path.."/"..filename..filetype, "w+")
	file:write(minetest.serialize(var))
	file:close()
	log_message("Saved savedata for file", filename)
	return true
end