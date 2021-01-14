-- Dumpster Studios presents a Steam Like username system:
-- Author: Jordach
-- License: Reserved

weapons.discord_loaded = minetest.get_modpath("discord")

-- Handle prototype Discord intergration
function weapons.discord_send_message(message)
end
if weapons.discord_loaded == nil then
	local function send_discord_message(message)
		return
	end

	weapons.discord_send_message = send_discord_message
else
	local function send_discord_message(message)
		discord.send_message(message)
	end
	weapons.discord_send_message = send_discord_message
	discord.automated_chat_send = false
end

minetest.register_on_chat_message(function(name, message)
	local colour_string = "<" .. weapons.player_data[name].nick .. "> "
	local result = weapons.team_colourize(minetest.get_player_by_name(name), colour_string)	
	minetest.chat_send_all(result .. message)
	weapons.discord_send_message("<**" .. weapons.player_data[name].nick .. "**> " .. message)

	-- Players can't hide from us admins
	minetest.log("action", "<" .. name .. "> " .. message)
	return true
end)

-- Command to manually set the nickname in game:

minetest.register_on_chatcommand(function(name, command, params)
	if command == "nick" then
		weapons.player_data[name].nick = params
		minetest.chat_send_player(name, "Nickname set as: " .. minetest.colorize(weapons.teams.no_team, params))
		minetest.log("action", name .. " set their nickname to: " .. params)
		persistence.save_data("weapons_player_data", weapons.player_data)
		return true
	end
end)