-- Weapons for Super CTF:
-- Author: Jordach
-- License: Reserved

-- global stuff.

weapons = {}
weapons.disable_visual_recoil = true
weapons.master_recoil_mult = 0.9
weapons.status = {} -- Server status info
weapons.modchannels = {} -- Per-player mod channels, stored by player name
weapons.registry = {} -- Read only weapons thing
weapons.player = {} -- Some functions
weapons.player_list = {} -- Current game related data
weapons.player_data = {} -- Save data and config
weapons.is_reloading = {} -- This should be part of player_list
weapons.default_eye_height = 1.58 -- Defaults
weapons.default_modchannel = "battleforarkhos_" -- Defaults

-- Handle a one time file load at bootup to ensure data is properly loaded
if true then
	local loaded, wpd, file_created = persistence.load_data("weapons_player_data", true)
	weapons.player_data = table.copy(wpd)
	wpd = nil
end

-- Handle world persistent login as we delete worlds between games.
dofile(minetest.get_modpath("weapons").."/auth.lua")
dofile(minetest.get_modpath("weapons").."/ban.lua")

-- Special usecase, load the additions to the solarsail global before anything else.
-- Ideally, this should be at the bottom with the others, but we make do.
dofile(minetest.get_modpath("weapons").."/functions.lua")

-- uptime counting
local function conv_to_hms(seconds)
	local seconds = tonumber(seconds)
	if seconds <= 0 then
		return "00h00m00s";
	else
		local hours = string.format("%02.f", math.floor(seconds/3600))
		local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)))
		local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60))
		return hours.."h"..mins.."m"..secs.."s"
	end
end

weapons.status.uptime = 0
local function uptime_count()
	weapons.status.uptime = weapons.status.uptime + 1
	minetest.after(1, uptime_count)
end
minetest.after(1, uptime_count)

-- Minetest Engine overrides:

function core.spawn_item(pos, item)
	return
end

function core.send_join_message(player_name)
	if not core.is_singleplayer() then
		local loaded, wpd, file_created = persistence.load_data("weapons_player_data", true)
		weapons.player_data = table.copy(wpd)
		wpd = nil
	
		if weapons.player_data[player_name] == nil then
			-- Create userdata if it doesn't exist, otherwise we do so
			weapons.player_data[player_name] = {}
			weapons.player_data[player_name].nick = player_name
			minetest.log("action", "No user settings for user: " .. player_name .. 
				", detected; creating it now.")
			persistence.save_data("weapons_player_data", weapons.player_data)
		end
	
		core.chat_send_all(weapons.team_colourize(minetest.get_player_by_name(player_name), weapons.player_data[player_name].nick) .. " joined the game.")
	end
end

function core.send_leave_message(player_name, timed_out)
	local msg = weapons.team_colourize(minetest.get_player_by_name(player_name), weapons.player_data[player_name].nick) .. " left the game"
	if timed_out then
		msg = msg .. ", due to network interruption or error."
	else
		msg = msg .. "."
	end
	minetest.chat_send_all(msg)
end

function core.get_server_status(player_name, joined)
	local status = "Server Version: Minetest " .. minetest.get_version().string .. ".\n"
	status = status .. "Server Uptime: " .. conv_to_hms(weapons.status.uptime) .. ".\n"

	status = status .. "Connected Players: "
	local nplayers = {}
	local count = 0
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		count = count + 1
		nplayers[count] = {}
		if weapons.player_data[pname] == nil then
			nplayers[count].nick = pname
		elseif weapons.player_data[pname].nick == nil then
			nplayers[count].nick = pname
		else	
			nplayers[count].nick = weapons.player_data[player:get_player_name()].nick
		end
		nplayers[count].user = player
	end
	for num, nick in ipairs(nplayers) do
		if num < #nplayers then
			status = status .. weapons.team_colourize(nplayers[num].user, nplayers[num].nick) .. ", "
		else
			status = status .. weapons.team_colourize(nplayers[num].user, nplayers[num].nick) .. ".\n"
		end
	end

	if solarsail.avg_dtime == nil or solarsail.avg_dtime == 0 then
		local _chance = math.random(1, 100)
		local _msg = "Excuse me, but why are you launching the server as a client?"
		print(_chance)
		if _chance < 11 then
			-- https://discord.com/channels/369122544273588224/369122544273588226/807084993854701608
			-- From @ElCeejus
			_msg = "Excuse me bruv? Why are yeh laoonching Minetaest hes a client yeh? Kinda schtewpid innit?"
		end
		status = status .. minetest.colorize("#ff0000", _msg)
	else
		status = status .. "Average Server Lag: " ..
			minetest.colorize(
				solarsail.util.functions.blend_colours(
					solarsail.avg_dtime,
					0.03,
					0.12,
					"#00ff00",
					"#ff0000"
				),
				string.format("%.2f", tostring(solarsail.avg_dtime)) .. "s"
			)
	end

	if weapons.auth[player_name] == nil then
	elseif weapons.auth[player_name].last_login == nil then
	else
		local date = os.date("%Y/%m/%d %H:%M:%S", weapons.auth[player_name].last_login)
		status = status .. "\nLast Join: " ..
			minetest.colorize(weapons.teams.no_team, date)
	end
	return status
end

weapons.player_huds = {}

-- Main game stuff begins.

local death_formspec = 
	"size[6,3]"..
	"label[2,1;Respawning in 5 seconds...]"

minetest.register_on_player_receive_fields(function(player, 
		formname, fields)
	if formname == "death" then
		if fields.quit then
			minetest.after(0.1, minetest.show_formspec,
				player:get_player_name(), "death",
				death_formspec)
			return
		end
	end
end)

-- TODO move into hud.lua

function weapons.update_killfeed(player, dead_player, weapon, dist)
	local tname = dead_player:get_player_name()
	local pname = player:get_player_name()
	local kill_verbs = {
		" killed ", " yeeted ", " spirit bombed ", " dumpstered ",
		" flossed on ", " flexed on ", " meme'd ", " rekt ", " is dominating ",
		" montaged ", " outplayed ", " default danced on ", " exterminated ",
		" deleted ", " recycled ", " pwned ", " coughed at ",
		" shrekt ", " exploded ", " ended ", " drilled ", " flattened ",
		" splattered ", " shredded ", " obliterated ", " cheese grated ",
		" shadow-realmed ", " voided ", " ceased ", " evicted ",
		" booked ", " executed ", " mercy killed ", " stopped ",
		" autistically screeched at ", " melted ", " #lounge'd ",
		" moderated ", " banhammered ", " 13373D ",	" Flex Taped ",
		" cronched ", " destroyed ", " blown out ", " sawn "
	}
	local special_verbs = { "'s Ankha killed " }
	local suicide_verbs = {
		" commited die ", " died ", " commited suicide ", " couldn't stand living ",
		" hated everything ", " realised existence was pointless ", " gave up on their team "
	}

	local verb, form
	local figs = 10^(2)

	if tname == pname then
		verb = math.random(1, #suicide_verbs)
		form = death_formspec ..
		"label[2,2;You" .. suicide_verbs[verb] .. "with the " .. weapon._localisation.name
		minetest.chat_send_all(weapons.get_nick(player) .. suicide_verbs[verb] .. "with the " ..
			weapon._localisation.name .. ".")
		weapons.discord_send_message("**" .. weapons.get_nick(player) .. "**" .. suicide_verbs[verb] .. "with the "
			.. weapon._localisation.name .. ".")
	else
		verb = math.random(1, #kill_verbs)
		form = death_formspec ..
		"label[2,2;You " .. kill_verbs[verb] .. "by: "..pname.."]"
		minetest.chat_send_all(weapons.get_nick(player) .. kill_verbs[verb] .. weapons.get_nick(dead_player) .. " with the " .. weapon._localisation.name
		.. ", (" .. (math.floor(dist * figs + 0.5) / 100) .. "m)")
		weapons.discord_send_message("**" .. weapons.get_nick(player) .. "**" .. kill_verbs[verb] .. weapons.get_nick(dead_player) .. " with the " .. weapon._localisation.name
		.. ", (" .. (math.floor(dist * figs + 0.5) / 100) .. "m)")
	end

	minetest.show_formspec(tname, "death", form)
end


-- TODO move to a more suitable place than functions.lua
function weapons.handle_damage(weapon, player, target_player, dist)
	local pname = player:get_player_name()
	local tname = target_player:get_player_name()
	if weapons.player_list[tname].hp == nil then return end
	local new_hp = weapons.player_list[tname].hp - weapon._damage
	
	print(weapons.player_list[tname].hp, new_hp, tname)

	--if weapons.player_list[tname] == 0 then
		--weapons.player_list[tname].hp = weapons.player_list[tname].hp_max
	if weapons.player_list[tname].hp < 1 then
		return
	end

	if weapon._heals == nil then
	elseif weapon._heals > 0 then
		if weapons.player_list[pname].team ==
				weapons.player_list[tname].team then
			if weapons.player_list[tname].hp < 
				weapons.player_list[tname].hp_max * 1.25 then
					new_hp = weapons.player_list[tname].hp + weapon._heals
			else
				new_hp = weapons.player_list[tname].hp_max
			end
		end
	end

	if weapons.player_list[pname].team ~=
			weapons.player_list[tname].team then
		if new_hp < 1 then
			weapons.kill_player(player, target_player, weapon, dist)
			weapons.hud.render_hitmarker(player)
			minetest.sound_play("hitsound", {to_player=pname})
			minetest.sound_play("player_impact", {pos=target_player:get_pos(),
				max_hear_distance=6, gain=0.85})
		else
			weapons.player_list[tname].hp = new_hp
			weapons.hud.render_hitmarker(player)
			minetest.sound_play("hitsound", {to_player=pname})	
			minetest.sound_play("player_impact", {pos=target_player:get_pos(),
				max_hear_distance=6, gain=0.98})
		end
	elseif pname == tname then
		if new_hp < 1 then
			weapons.kill_player(player, player, weapon, dist)
			minetest.sound_play("player_impact", {pos=target_player:get_pos(),
				max_hear_distance=6, gain=0.85})
		else
			weapons.player_list[tname].hp = new_hp
		end
	else
		if weapon._heals == nil then return 
		else
			weapons.player_list[tname].hp = new_hp
			weapons.hud.render_hitmarker(player)
			minetest.sound_play("hitsound", {to_player=pname})
			minetest.sound_play("player_heal", {pos=target_player:get_pos(),
				max_hear_distance=6, gain=0.98})
		end
	end
	weapons.hud.update_vignette(target_player)
end

--[[ TODO: fix physics intergration with create a class

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local wield = player:get_wielded_item():get_name()
		local weapon = minetest.registered_nodes[wield]
		local pname = player:get_player_name()
		
		if weapons.player_list[pname].class == nil then
		elseif weapon == nil then
			player:set_physics_override(
				weapons[weapons.player_list[pname].class].physics
			)
			player_phys[pname] = 1
		elseif weapon._phys_alt == nil then
			player:set_physics_override(
				weapons[weapons.player_list[pname].class].physics
			)
			player_phys[pname] = 1
		elseif player_phys[pname] ~= weapon._phys_alt then
			local new_phys = 
			table.copy(weapons[weapons.player_list[pname].class].physics)
			new_phys.speed = new_phys.speed * weapon._phys_alt
			--new_phys.jump = new_phys.jump * weapon._phys_alt
			player:set_physics_override(new_phys)
			player_phys[pname] = weapon._phys_alt
		end
	end
end)
	
]]

-- We now have access to other functions defined here:
dofile(minetest.get_modpath("weapons").."/skybox.lua")
dofile(minetest.get_modpath("weapons").."/chat.lua")
dofile(minetest.get_modpath("weapons").."/hud.lua")
dofile(minetest.get_modpath("weapons").."/builtin_blocks.lua")
dofile(minetest.get_modpath("weapons").."/weapons.lua")

-- Player viewmodel settings:
dofile(minetest.get_modpath("weapons").."/arms/player_arms.lua")
dofile(minetest.get_modpath("weapons").."/arms/player_body.lua")

-- More game related data
dofile(minetest.get_modpath("weapons").."/player.lua")
dofile(minetest.get_modpath("weapons").."/game.lua")
dofile(minetest.get_modpath("weapons").."/mapgen.lua")
dofile(minetest.get_modpath("weapons").."/controls.lua")
dofile(minetest.get_modpath("weapons").."/tracers.lua")

-- Built in items
dofile(minetest.get_modpath("weapons").."/weapons/tools.lua")
dofile(minetest.get_modpath("weapons").."/weapons/blocks.lua")

-- External weapons
dofile(minetest.get_modpath("weapons").."/weapons/assault_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/burst_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/sniper_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/veteran_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/auto_shotgun.lua")
dofile(minetest.get_modpath("weapons").."/weapons/plasma_autorifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/light_machine_gun.lua")
dofile(minetest.get_modpath("weapons").."/weapons/minigun.lua")

--dofile(minetest.get_modpath("weapons").."/weapons/railgun.lua")
--dofile(minetest.get_modpath("weapons").."/weapons/smg.lua")
--dofile(minetest.get_modpath("weapons").."/weapons/shotgun.lua")
--dofile(minetest.get_modpath("weapons").."/weapons/rocketry.lua")
--dofile(minetest.get_modpath("weapons").."/weapons/grenades.lua")

weapons.default_first_person_eyes = vector.new(0, 0, 2.25)
minetest.register_on_player_receive_fields(
			function(player, formname, fields)
	if formname == "camera_control" then
		local pname = player:get_player_name()
		if fields.lefty then
			player:set_eye_offset(weapons.default_first_person_eyes, {x=-15,y=-1,z=20})
			minetest.chat_send_player(pname, "Third person camera and crosshair set to over the left shoulder.")
			minetest.after(0.1, minetest.show_formspec,
				player:get_player_name(), "camera_control",
				weapons.class_formspec)
		elseif fields.righty then
			player:set_eye_offset(weapons.default_first_person_eyes, {x=15,y=-1,z=20})
			minetest.chat_send_player(pname, "Third person camera and crosshair set to over the right shoulder.")
			minetest.after(0.1, minetest.show_formspec,
				player:get_player_name(), "camera_control",
				weapons.class_formspec)
		end
	end
end)