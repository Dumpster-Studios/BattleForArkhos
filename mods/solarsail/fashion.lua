-- SolarSail Engine Texture, Model Attachment Handling:
-- Author: Jordach
-- License: Reserved

--[[ solarsail.fashion.clothing[player]

Clothing in the solarsail engine is defined as the following internal format;
it does not have to follow the named table entries listed, as it is a named table;
but should be used for people attempting to make their own game.

solarsail.fashion.clothing[player] = {
	body_lower = {}
	body_upper = {}
	arms_lower = {}
	arms_upper = {}
	legs_lower = {}
	legs_upper = {}
	face = {}
}

All tables inside solarsail.fashion.clothing[player] follow the same format, which is as follows:
Note: These are INTEGER INDEXED.

body_lower = {
	[1] = {
		texture = "texture_here.png",
		color = "#rrggbbaa" or {r=255, g=255, b=255, a=255} (Colorspec.)
	},
	[34] = {
		texture = "another_texture.png",
		color = "#deadbeef"
	}
}

]]

--[[ solarsail.fashion.base[player]

Basic things like eyes, eyebrows, skin colour, etc, and is defined in this manner;
it does not have to follow the named table entries listed, as it is a named table;
but should be used for people attempting to make their own game.

solarsail.fashion.base[player] = {
	eyes = {
		eye_left_texture = "eyes.png",
		eye_left_texture_alt = "eyes_alt.png",
		eye_left_color = "#rrggbbaa" or {r=255, g=255, b=255, a=255} (Colorspec.)
		eye_left_color_alt = "#rrggbbaa" or {r=255, g=255, b=255, a=255} (Colorspec.)
		eye_right_texture = "eyes_right.png",
		eye_right_texture_alt = "eyes_right_alt.png",
		eye_right_color = "#rrggbbaa" or {r=255, g=255, b=255, a=255} (Colorspec.)
		eye_right_color_alt = "#rrggbbaa" or {r=255, g=255, b=255, a=255} (Colorspec.)
	}
	body = {
		skin = "skin_texture.png",
		skin_color = "#rrggbbaa" or {r=255, g=255, b=255, a=255} (Colorspec.)
		pattern = "fur_pattern.png",
		pattern_color = "#rrggbbaa" or {r=255, g=255, b=255, a=255} (Colorspec.)
	}
}

]]

--[[ solarsail.fashion.attachments[player]


]]

--[[ solarsail.fashion.get_texture(player_ref)

Returns the texture of the player.

Expected return values as strings:

"player_texture.png"
"(player_skin.png^[multiply:#123456)^(player_clothing.png^[multiply:#654321)"

Define this function if you want to use solarsail.fashion.
]]

function solarsail.fashion.get_texture()
end

--[[ solarsail.fashion.set_default_texture(player_ref)

Constructs a default skin for the player and sets their skin to it,
as long as save data isn't found.

Define this function if you want to use solarsail.fashion.
]]

function solarsail.fashion.set_default_texture()
end

--[[ solarsail.fashion.check_valid_textures(mod_path, files, start_value, metadata)

mod_path = minetest.get_modpath("your_mod")
filename = "texture_string_"
metadata = bool

Note: filename should leave out any extras like digits and filenames.

start_value = integer

Returns: table of filenames, number of files.
]]

function solarsail.fashion.check_valid_textures(mod_path, filename, start_value, metadata)
	local increment = start_value
	if start_value == nil then start_value = 1 end
	local valid_files = {}
	local metadata = {}
	while true do
		local file = io.open(mod_path .. "/textures/" .. filename .. increment .. ".png")
		if not file then break end
		-- Add to return list of files
		table.insert(valid_files, increment, filename .. increment .. ".png")
		file:close()
		table.insert(metadata, increment, metadata_scan(mod_path, filename, increment))
		increment = increment + 1
	end
	return increment, valid_files
end

local function metadata_scan(modpath, filename, increment)
	local metainfo = {} 
	local file = io.open(mod_path .. "/metadata/" .. filename .. increment .. ".tex")
	if not file then
		metainfo[1] = "Unknown Author"
		metainfo[2] = "Unknown"
	else
		local metainc = 1
		for line in io.lines(file) do
			if metainc > 2 then break end
			metainfo[metainc] = line
			metainc = metainc + 1
		end
	end
	return metainfo
end