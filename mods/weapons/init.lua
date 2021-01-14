-- Weapons for Super CTF:
-- Author: Jordach
-- License: Reserved

-- global stuff.

weapons = {}
worldedit = {}
weapons.player = {}
weapons.player_list = {}
weapons.player_data = {}
weapons.is_reloading = {}
weapons.default_eye_height = 1.58	
weapons.status = {}

-- uptime counting

function conv_to_hms(seconds)
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
		msg = msg .. ", due to network error."
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
			status = status .. weapons.team_colourize(nplayers[num].user, nplayers[num].nick) .. "."
		end
	end
	return status
end

-- Main game stuff begins.

local player_timers = {}
weapons.player_huds = {}
local player_fov = {}

local death_formspec = 
	"size[6,3]"..
	"label[2,1;Respawning in 5 seconds...]"

function weapons.get_nick(player)
	local pname = player:get_player_name()
	if weapons.player_data[pname] == nil then
		return pname
	elseif weapons.player_data[pname].nick == nil then
		return pname
	else
		return weapons.player_data[pname].nick
	end
end

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

function solarsail.util.functions.y_direction(rads, recoil)
	return math.sin(rads) * recoil
end

function solarsail.util.functions.xz_amount(rads)
	local pi = math.pi
	return math.sin(rads+(pi/2))
end

-- Takes vector based velocities or positions (as vec_a to vec_b)
function solarsail.util.functions.get_3d_angles(vector_a, vector_b)
	-- Does the usual Pythagoras bullshit:
	local x_dist = vector_a.x - vector_b.x + 1
	local z_dist = vector_a.z - vector_b.z + 1
	local hypo = math.sqrt(x_dist^2 + z_dist^2)

	-- But here's the kicker: we're using arctan to get the cotangent of the angle,
	-- but also applies to *negative* numbers. In such cases where the positions
	-- are northbound (positive z); the angle is 180 degrees off.
	local xz_angle = -math.atan(x_dist/z_dist)
	
	-- For the pitch angle we do it very similar, but use the 
	-- Hypotenuse as the Adjacent side, and the Y distance as the
	-- Opposite, so arctangents are needed.
	local y_dist = vector_a.y - vector_b.y
	local y_angle = math.atan(y_dist/hypo)
	
	-- Fixes radians using south facing (-Z) radians when heading north (+Z)
	if z_dist < 0 then
		xz_angle = xz_angle - math.rad(180)
	end
	return xz_angle, y_angle
end

function solarsail.util.functions.apply_recoil(player, weapon)
	local yaw_rad = player:get_look_horizontal()
	local pitch_rad = player:get_look_vertical()
	-- Physical knockback; can be canceled out
	local result_x, result_z = 
			solarsail.util.functions.yaw_to_vec(yaw_rad, weapon._recoil, true)
	local result_y = 
			solarsail.util.functions.y_direction(pitch_rad, weapon._recoil)
	local pitch_mult = solarsail.util.functions.xz_amount(pitch_rad)
	player:add_velocity({
		x=result_x * pitch_mult, 
		y=result_y, 
		z=result_z * pitch_mult
	})
	
	-- Camera recoil; cannot be canceled out
	local vert_deg, hori_deg, look_pitch, look_hori = 0
	vert_deg = math.random(weapon._recoil_vert_min * 100, weapon._recoil_vert_max * 100) / 100
	hori_deg = math.random(-weapon._recoil_hori * 100, weapon._recoil_hori * 100) / 100
	
	-- Handle aiming
	local pname = player:get_player_name()
	if weapons.player_list[pname].aim_mode then
		look_pitch = player:get_look_vertical() + (math.rad(-vert_deg) * weapon._recoil_aim_factor)
		look_hori = player:get_look_horizontal() + (math.rad(hori_deg) * weapon._recoil_aim_factor)
	else
		look_pitch = player:get_look_vertical() + (math.rad(-vert_deg) * weapon._recoil_factor)
		look_hori = player:get_look_horizontal() + (math.rad(hori_deg) * weapon._recoil_factor)
	end
	player:set_look_vertical(look_pitch)
	player:set_look_horizontal(look_hori)
end

function solarsail.util.functions.apply_explosion_recoil(player, multiplier, origin)
	local ppos = player:get_pos()
	ppos.y = ppos.y + 0.5
	local result_vel = vector.multiply(vector.direction(origin, ppos), multiplier)
	player:add_velocity(result_vel)
end

function solarsail.util.functions.pos_to_dist(pos_1, pos_2)
	local res = {}
	res.x = (pos_1.x - pos_2.x)
	res.y = (pos_1.y - pos_2.y)
	res.z = (pos_1.z - pos_2.z)
	return math.sqrt(res.x*res.x + res.y*res.y + res.z*res.z)
end

function weapons.calc_block_damage(nodedef, weapon, target_pos, pointed)
	if nodedef == nil then
	elseif nodedef.name == "air" then
		return 0, "air", nil
	elseif nodedef.name == "ignore" then
		return 0, "air", nil
	elseif nodedef._health == nil then
		weapons.spray_particles(pointed, nodedef, target_pos)
		return 0, "air", nil
	elseif nodedef._takes_damage == nil then
		local nodedamage
		if weapon._block_chance == nil then
			nodedamage = nodedef._health - weapon._break_hits
		elseif math.random(1, 100) < 25 then
			nodedamage = nodedef._health - weapon._break_hits
		else
			nodedamage = nodedef._health
		end

		if nodedamage < 1 then
			weapons.spray_particles(pointed, nodedef, target_pos)
			return 0, "air", nil
		else
			weapons.spray_particles(pointed, nodedef, target_pos)
			return nodedamage, nodedef._name.."_"..nodedamage, nil
		end
	else
		weapons.spray_particles(pointed, nodedef, target_pos)
		return 0, nodedef.name, false
	end
end

function weapons.spray_particles(pointed, nodedef, target_pos)
	local npos, npos_floor
	if pointed == nil then
		npos = table.copy(target_pos)
		npos_floor = table.copy(target_pos)
		npos_floor.x = math.floor(npos_floor.x)
		npos_floor.y = math.floor(npos_floor.y)
		npos_floor.z = math.floor(npos_floor.z)
	else
		npos = table.copy(pointed.intersection_point)
		npos_floor = table.copy(pointed.under)
	end
	
	if nodedef.tiles == nil then return end
	minetest.add_particlespawner({
		amount = math.random(8, 12),
		time = 0.03,
		texture = nodedef.tiles[1],
		node = {name=minetest.get_node(npos_floor).name},
		collisiondetection = true,
		collision_removal = false,
		object_collision = false,
		vertical = false,
		minpos = vector.new(npos.x-0.05,npos.y-0.05,npos.z-0.05),
		maxpos = vector.new(npos.x+0.05,npos.y+0.05,npos.z+0.05),
		minvel = vector.new(-1, -1, -1),
		maxvel = vector.new(1, 1, 1),
		minacc = vector.new(0,-5,0),
		maxacc = vector.new(0,-5,0),
		minsize = 0.95,
		maxsize = 1.15,
		minexptime = 1,
		maxexptime = 3
	})
end

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

function weapons.reset_health(player)
	local pname = player:get_player_name()
	weapons.player_list[pname].hp = weapons.player_list[pname].hp_max
	weapons.hud.update_vignette(player)
	minetest.close_formspec(pname, "death")
end

function weapons.respawn_player(player, respawn)
	local pname = player:get_player_name()
	local x, y, z = 0
	local blu = 192-42
	if weapons.player_list[pname].team == "red" then
		x = math.random(168, 176)
		z = math.random(168, 176)
		y = weapons.red_base_y
		if y == nil then y = 2 end
	else
		x = math.random(-147, -139)
		z = math.random(-147, -139)
		y = weapons.blu_base_y
		if y == nil then y = 2 end
	end

	player:set_pos({x=x, y=y+0.5, z=z})
	if respawn then
		weapons.set_ammo(player, weapons.player_list[pname].class)
		weapons.clear_inv(player)
		weapons.add_class_items(player, weapons.player_list[pname].class)
	end
	weapons.hud.remove_blackout(player)
end

function weapons.kill_player(player, target_player, weapon, dist)
	weapons.update_killfeed(player, target_player, weapon, dist)
	weapons.player_list[target_player:get_player_name()].hp = 0
	weapons.player.cancel_reload(target_player)
	weapons.hud.blackout(target_player)
	minetest.after(4.9, weapons.respawn_player, target_player, true)
	minetest.after(5, weapons.reset_health, target_player)
end

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

local health_pos = {x=0.325, y=0.825}
local ammo_pos = {x=0.675, y=0.825}
local player_phys = {}
local player_key_timer = {}

local function set_keys(pname)
	player_key_timer[pname] = 0
end

-- Handle a one time file load at bootup to ensure data is properly loaded
if true then
	local loaded, wpd, file_created = persistence.load_data("weapons_player_data", true)
	weapons.player_data = table.copy(wpd)
	wpd = nil
end

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()

	player_timers[pname] = {}
	player_timers[pname].fire = 0
	player_timers[pname].reload = 0
	weapons.is_reloading[pname] = {}
	player_fov[pname] = 120
	player_phys[pname] = 1
	player:hud_set_flags({
		hotbar = true,
		healthbar = false,
		crosshair = false,
		wielditem = true,
		breathbar = false,
		minimap = false,
		minimap_radar = false
	})

	player_key_timer[pname] = 0
	return false
end)

function weapons.player.cancel_reload(player)
	local pname = player:get_player_name()
	local weapon 
	local is_canceled = false
	for wname, bool in pairs(weapons.is_reloading[pname]) do
		if bool then
			weapons.is_reloading[pname][wname] = false
			is_canceled = true
			-- Probably very CPU heavy; but needed
		end
		weapon = minetest.registered_nodes[wname]
	end
	if weapon == nil then
	elseif weapon._no_reload_hud then
	else
		-- Only if there's an actual reload happening
		-- we remember that clients are spuds
		-- who can't handle 100ms packet decode times
		if is_canceled then
			player:hud_change(weapons.player_huds[pname].ammo.reloading,
				"text", "transparent.png")
		end
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()

		if solarsail.controls.player[pname] == nil then
		elseif solarsail.controls.player[pname].aux1 then
			local wield = player:get_wielded_item():get_name()
			local weapon = minetest.registered_nodes[wield]
			if weapon.on_reload == nil then
			else
				weapon.on_reload(player, weapon, wield, true)
			end
		end
	end
end)

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if player_timers[pname] == nil then
		else
			player_timers[pname].fire =
				player_timers[pname].fire + dtime
			-- Get player's wieled weapon:
			local wield = player:get_wielded_item():get_name()
			local weapon = minetest.registered_nodes[wield]

			if weapon == nil then
			elseif weapon._name == nil then
			elseif weapon._rpm == nil then
			elseif player_timers[pname].fire > 60 / weapon._rpm  then
				if solarsail.controls.player[pname].LMB then
					player_timers[pname].fire = 0
					if weapon._type == "gun" then
						local ammo = weapon._ammo_type
						if weapons.player_list[pname][ammo] > 0 then
							if not weapons.is_reloading[pname][wield] then
								weapon.on_fire(player, weapon)
							end
						end
					elseif weapon._type == "block" then
						if weapons.player_list[player:get_player_name()].blocks > 0 then
							weapon.on_fire(player, weapon)
							weapons.player_list[player:get_player_name()].blocks = 
								weapons.player_list[player:get_player_name()].blocks - 1
						end
					elseif weapon._type == "tool" then
						weapon.on_fire(player, weapon)
					elseif weapon._type == "tool_alt" then
						weapon.on_fire(player, weapon)
					end
				end
			end
		end
	end
end)

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local wield = player:get_wielded_item():get_name()
		local weapon = minetest.registered_nodes[wield]
		
		if player_key_timer[pname] == nil then
		else
			player_key_timer[pname] =
				player_key_timer[pname] + 0.03
		
			if solarsail.controls.player[pname] == nil then
			elseif weapon == nil then
				weapons.player_list[pname].aim_mode = false
			elseif weapon._type == nil then
				weapons.player_list[pname].aim_mode = false
			-- Handle tools with the reload key as they lack reloads
			elseif solarsail.controls.player[pname].aux1 then
				if player_key_timer[pname] > 0.25 then
					if weapon._type ~= "gun" then
						player_key_timer[pname] = 0
						player:set_wielded_item(ItemStack(weapon._alt_mode .. " 1"))
					end
				end
				weapons.player_list[pname].aim_mode = false
			-- Handle aiming down sights or alternate modes but not when reloading:
			elseif weapon._type == "gun" then
				if not weapons.is_reloading[pname][wield] then
					weapons.player_list[pname].aim_mode = solarsail.controls.player[pname].RMB
				else
					weapons.player_list[pname].aim_mode = false
				end
			else
				weapons.player_list[pname].aim_mode = false
			end
		end
	end
end)

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local wield = player:get_wielded_item():get_name()
		local weapon = minetest.registered_nodes[wield]
		if weapon == nil then
		elseif weapons.player_list[pname].aim_mode then
			if weapon._fov_mult_aim == nil then
				player:set_fov(0, false, 0.2)
				player_fov[player:get_player_name()] = 0
			elseif player_fov[player:get_player_name()] ~= weapon._fov_mult_aim then
				if weapon._fov_mult_aim == 0 then
					player:set_fov(0, false, 0.2)
					player_fov[player:get_player_name()] = 0
				else
					player:set_fov(weapon._fov_mult_aim, true, 0.2)
					player_fov[player:get_player_name()] = weapon._fov_mult_aim
				end
			end
		else
			if weapon._fov_mult == nil then
				player:set_fov(0, false, 0.2)
				player_fov[player:get_player_name()] = 0
			elseif player_fov[player:get_player_name()] ~= weapon._fov_mult then
				if weapon._fov_mult == 0 then
					player:set_fov(0, false, 0.2)
					player_fov[player:get_player_name()] = 0
				else
					player:set_fov(weapon._fov_mult_aim, true, 0.2)
					player_fov[player:get_player_name()] = weapon._fov_mult
				end
			end
		end
	end
end)

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

dofile(minetest.get_modpath("weapons").."/player.lua")
dofile(minetest.get_modpath("weapons").."/game.lua")
dofile(minetest.get_modpath("weapons").."/mapgen.lua")
dofile(minetest.get_modpath("weapons").."/tracers.lua")

-- Built in items
dofile(minetest.get_modpath("weapons").."/weapons/tools.lua")
dofile(minetest.get_modpath("weapons").."/weapons/blocks.lua")
-- External weapons
dofile(minetest.get_modpath("weapons").."/weapons/assault_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/burst_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/sniper_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/scout_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/auto_shotgun.lua")
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