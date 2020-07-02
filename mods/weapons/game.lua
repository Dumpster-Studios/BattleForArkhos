-- Logic for Super CTF:
-- Author: Jordach
-- License: Reserved

weapons.game_mode = "ctf"
weapons.list_of_games = {"ctf", "reverse_ctf", "one_flag", "koth", "assault"}
weapons.teams = {}
weapons.teams.red = 0
weapons.teams.blue = 0
weapons.teams.red_colour = 0xFF6464
weapons.teams.red_string = "#ff6464"
weapons.teams.blue_colour = 0x7575FF
weapons.teams.blue_string = "#7575ff"
weapons.score = {}
weapons.score.red = 0
weapons.score.blue = 0

weapons.team_names = {}
weapons.team_names.red = "Red Team"
weapons.team_names.red_icon = "red_team.png"
weapons.team_names.blue = "Blue Team"
weapons.team_names.blue_icon = "blue_team.png"

weapons.flag_pos = {}
weapons.flag_ref = {}

function weapons.assign_team(player, team)
	local pname = player:get_player_name()
	weapons.player_list[pname].waypoints = {}
	-- Auto assign player
	if team == nil then
		if weapons.teams.red == weapons.teams.blue then
			local rando = math.random(0, 1)
			if rando == 1 then
				weapons.teams.red = weapons.teams.red + 1
				weapons.player_list[pname].team = "red"
				minetest.chat_send_all(minetest.colorize(weapons.teams.red_string, pname) ..
										" has joined the " .. 
										minetest.colorize(weapons.teams.red_string, weapons.team_names.red))
				minetest.log("action", 
					pname.. " has been automatically assigned to " .. weapons.team_names.red)
				weapons.discord_send_message("**" .. pname .. "**" .. " has joined the " .. weapons.team_names.red)
			else
				weapons.teams.blue = weapons.teams.blue + 1
				weapons.player_list[pname].team = "blue"
				minetest.chat_send_all(minetest.colorize(weapons.teams.blue_string, pname) ..
										" has joined the " .. 
										minetest.colorize(weapons.teams.blue_string, weapons.team_names.blue))
				minetest.log("action", 
					pname.. " has been automatically assigned to " .. weapons.team_names.blue)
				weapons.discord_send_message("**" .. pname .. "**" .. " has joined the " .. weapons.team_names.blue)
			end
		elseif weapons.teams.red < weapons.teams.blue then
			weapons.teams.red = weapons.teams.red + 1
			weapons.player_list[pname].team = "red"
			minetest.chat_send_all(minetest.colorize(weapons.teams.red_string, pname) ..
										" has joined the " .. 
										minetest.colorize(weapons.teams.red_string, weapons.team_names.red))
			minetest.log("action", 
				pname.. " has been automatically assigned to " .. weapons.team_names.red)
			weapons.discord_send_message("**" .. pname .. "**" .. " has joined the " .. weapons.team_names.red)
		elseif weapons.teams.red > weapons.teams.blue then
			weapons.teams.blue = weapons.teams.blue + 1
			weapons.player_list[pname].team = "blue"
			minetest.chat_send_all(minetest.colorize(weapons.teams.blue_string, pname) ..
										" has joined the " .. 
										minetest.colorize(weapons.teams.blue_string, weapons.team_names.blue))
			minetest.log("action", 
				pname.. " has been automatically assigned to " .. weapons.team_names.blue)
			weapons.discord_send_message("**" .. pname .. "**" .. " has joined the " .. weapons.team_names.blue)
		end
	elseif team == "blue" then
		weapons.teams.blue = weapons.teams.blue + 1
		weapons.player_list[pname].team = "blue"
		minetest.chat_send_all(minetest.colorize(weapons.teams.blue_string, pname) ..
										" has joined the " .. 
										minetest.colorize(weapons.teams.blue_string, weapons.team_names.blue))
		minetest.log("action", 
			pname.. " has switched to " .. weapons.team_names.blue)
		weapons.discord_send_message("**" .. pname .. "**" .. " has joined the " .. weapons.team_names.blue)
	elseif team == "red" then
		weapons.teams.red = weapons.teams.red + 1
		weapons.player_list[pname].team = "red"
		minetest.chat_send_all(minetest.colorize(weapons.teams.red_string, pname) ..
										" has joined the " .. 
										minetest.colorize(weapons.teams.red_string, weapons.team_names.red))
		minetest.log("action", 
			pname.. " has switched to " .. weapons.team_names.red)
		weapons.discord_send_message("**" .. pname .. "**" .. " has joined the " .. weapons.team_names.red)
	end
end

minetest.register_on_leaveplayer(function(player, timed_out)
	local pname = player:get_player_name()
	if weapons.player_list[pname].team == "red" then
		weapons.teams.red = weapons.teams.red - 1
	elseif weapons.player_list[pname].team == "blue" then
		weapons.teams.blue = weapons.teams.blue - 1
	end
	weapons.player_list[pname] = {}
end)

local function add_global_waypoint(pos, id, name, color)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		weapons.player_list[pname].waypoints[id] = player:hud_add({
			hud_elem_type = "waypoint",
			name = name,
			text = "m",
			number = color,
			world_pos = pos
		})
	end
end

weapons.add_global_waypoint = add_global_waypoint


local function remove_global_waypoint(id)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if weapons.player_list[pname].waypoints[id] == nil then
		else
			player:hud_remove(weapons.player_list[pname].waypoints[id])
		end
	end
end

weapons.remove_global_waypoint = remove_global_waypoint

local function add_team_waypoint(pos, id, name, color, team)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if team == weapons.player_list[pname].team then
			weapons.player_list[pname].waypoints[id] = player:hud_add({
				hud_elem_type = "waypoint",
				name = name,
				text = "m",
				number = color,
				world_pos = pos
			})
		end
	end
end

local function remove_team_waypoint(id, team)
	for _, player in ipairs(minetest.get_connected_players()) do
		if weapons.player_list[pname].waypoints[id] == nil then
		elseif team == weapons.player_list[pname].team then
			local pname = player:get_player_name()
			player:hud_remove(weapons.player_list[pname].waypoints[id])
		end
	end
end

weapons.lock = {}
weapons.lock.red = false
weapons.lock.blue = false

function weapons.unlock_red()
	weapons.lock.red = false
end

function weapons.lock_red()
	weapons.lock.red = true
	minetest.after(5, weapons.unlock_red)
end

function weapons.unlock_blue()
	weapons.lock.blue = false
end

function weapons.lock_blue()
	weapons.lock.blue = true
	minetest.after(5, weapons.unlock_blue)
end

weapons.update_blue_flag = false
weapons.update_red_flag = false

dofile(minetest.get_modpath("weapons").."/flag_blue.lua")
dofile(minetest.get_modpath("weapons").."/flag_red.lua")

-- perform flag cleanup on restart
minetest.clear_objects({mode = "full"})

minetest.after(1, minetest.clear_objects, {mode = "full"})

local function ctf_spawn_flags()
	local blu2 = 147-4
	local redb = 207-35

	minetest.add_entity({x=redb, y=weapons.red_base_y+8.5, z=redb}, "weapons:flag_red")
	minetest.add_entity({x=-blu2, y=weapons.blu_base_y+8.5, z=-blu2}, "weapons:flag_blue")
end

local map_seed = minetest.get_mapgen_setting("seed")
local map_gen = minetest.get_mapgen_setting("mg_name")
minetest.after(1, discord.send_message, "Starting game mode CTF on map seed: `" .. map_seed .. "` on map generator " .. 
					map_gen:sub(1,1):upper()..map_gen:sub(2) .. ".")

minetest.after(10, ctf_spawn_flags)