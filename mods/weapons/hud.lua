weapons.hud = {}

local ammo_x_offset = -32
local ammo_y_offset = 64+16
local max_vig_opacity = 255
local min_vig_opacity = 128
local red_value = 128
local ammo_bar_max = 256
local ammo_fill_mark = -254
local ammo_fill_mult = -63.5
local ammo_mark_opac = 63

local ammo_scale = {
	bar_x = 2,
	bar_y = 32,
	count = 2.5,
	reload = 1,
	reload_offset = 76
}

local hp_x_offset = -256
local hp_y_offset = 32
local hp_scale = {
	bar_x = 2,
	bar_y = 24,
	count = 1.25
}

local last_ammo_count = {}
local last_weapon = {}
local last_crosshair = {}

local function reset_hud_offsets(pname)
	weapons.player_data[pname].offsets.hp = {x=0, y=0}
	weapons.player_data[pname].offsets.ammo = {x=0, y=0}
	weapons.player_data[pname].offsets.score = {x=0, y=0}
	weapons.player_data[pname].offsets.killfeed = {x=0, y=0}
	persistence.save_data("weapons_player_data", weapons.player_data)
	minetest.log("action", pname .. " reset their HUD offsets.")

	-- Force the HUDs to delete and re-position
	scale_ammo(pname, weapons.player_data[pname].ammo_scale, true)
	scale_health(pname, weapons.player_data[pname].hp_scale, true)
end

-- Used for the ammo overlay and ammo marks
local function cap_scale_to_int(scale)
	local s = tonumber(scale)
	if s < 1 then
		return 0.5
	elseif s >= 1 then
		return math.floor(s)
	end
end

-- Vignette things:

local function calc_falling_health_curve(player, value)
	local pname = player:get_player_name()
	return value - ((value/(weapons.player_list[pname].hp_max/weapons.player_list[pname].hp)))
end

function weapons.hud.update_vignette(player)
	local pname = player:get_player_name()
	
	-- Get min and max vignette opacity based on health level
	local opacity = calc_falling_health_curve(player, max_vig_opacity)
	-- Clamp to prevent impossible values
	if opacity < min_vig_opacity then opacity = min_vig_opacity end
	if opacity > max_vig_opacity then opacity = max_vig_opacity end
	
	-- Get how red the screen should be.
	local red = calc_falling_health_curve(player, red_value)
	if weapons.player_list[pname].hp < 5 then red = red_value end
	if red > red_value then red = red_value end -- Prevent impossible colour_string
	if red < 0 then red = 0 end -- Another bug that occurs in negative numbers
	local rgba = minetest.rgba(red, 0, 0)

	-- Set the fucker
	player:hud_change(weapons.player_huds[player:get_player_name()].misc.vignette, "text",
		"(hud_vignette.png^[multiply:"..rgba..")^[opacity:"..opacity)

	-- Update health bar on the same update to save adding another callback.
	weapons.hud.force_hp_refresh(player)
end

function weapons.hud.remove_blackout(player)
	player:hud_change(weapons.player_huds[player:get_player_name()].misc.blackout, "text",
		"transparent.png")
end

function weapons.hud.blackout(player)
	player:hud_change(weapons.player_huds[player:get_player_name()].misc.blackout, "text",
		"blackout.png^(hud_vignette.png^[multiply:#880000)")
end

-- Ammo management:

local function calc_ammo_bar_pos(player, weapon)
	local pname = player:get_player_name()
	if weapon._ammo_type == nil then
		return 256
	elseif weapons.player_list[pname][weapon._ammo_type.."_max"] == nil then
		return 256
	elseif weapons.player_list[pname][weapon._ammo_type] == nil then
		return 256
	else

		return math.floor(
			(256/weapons.player_list[pname][weapon._ammo_type.."_max"]) * weapons.player_list[pname][weapon._ammo_type]
		)
	end
end

local function get_ammo_appearances(player, weapon)
	local over_colour = minetest.rgba(0, 25, 75)
	local over_string = "hud_bar_overlay.png^[opacity:127"
	local weapon = minetest.registered_nodes[player:get_wielded_item():get_name()]
	local is_thermal = false
	if weapon == nil then
	elseif weapon._is_energy == nil then
	elseif weapon._is_energy then
		is_thermal = true
	end

	-- Handle a case where the gradient may need to be flipped for thermal/energy weapons
	if is_thermal then
		over_colour = minetest.rgba(255, 0, 0) -- Define from the equipped weapon
	end
	-- Apply a colour from the weapon
	over_string = over_string.."^[multiply:"..over_colour

	-- Handle ammo bar texture-y things here, such as the gradient
	local ab_fg_colour = minetest.rgba(255, 255, 255)
	local ab_bg_colour = minetest.rgba(64, 64, 64)
	local ammo_bar_fg = "hud_bar.png"
	local ammo_bar_bg = "hud_bar.png"

	if is_thermal then -- Make the darker bar on top, instead of the lower bar
		ab_fg_colour = minetest.rgba(64, 64, 64)
		ab_bg_colour = minetest.rgba(255, 255, 255)
	end
	ammo_bar_fg = ammo_bar_fg .. "^[multiply:" .. ab_fg_colour
	ammo_bar_bg = ammo_bar_bg .. "^[multiply:" .. ab_bg_colour

	return over_string, ammo_bar_fg, ammo_bar_bg
end

local function hud_update_ammo(player, bar_pos, weapon)
	local pname = player:get_player_name()
	player:hud_change(weapons.player_huds[pname].ammo.ammo_bar, "number", bar_pos)
	if weapon._ammo_type == nil then
		player:hud_change(weapons.player_huds[pname].ammo.ammo_count, "text", "err()")
	else
		local ammostring = ""
		if weapon._is_energy == nil then
			if weapons.player_list[pname][weapon._ammo_type.."_max"] == nil then
				ammostring = "nil"
			elseif weapons.player_list[pname][weapon._ammo_type] == nil then
				ammostring = "nil"
			else
				ammostring = 
					weapons.player_list[pname][weapon._ammo_type] .. "/" .. weapons.player_list[pname][weapon._ammo_type.."_max"]
			end
		elseif weapon._is_energy then
			if weapons.player_list[pname][weapon._ammo_type.."_max"] == nil then
				ammostring = "nil"
			elseif weapons.player_list[pname][weapon._ammo_type] == nil then
				ammostring = "nil"
			else
				ammostring = weapons.player_list[pname][weapon._ammo_type] .. "%"
			end
		else
			if weapons.player_list[pname][weapon._ammo_type.."_max"] == nil then
				ammostring = "nil"
			elseif weapons.player_list[pname][weapon._ammo_type] == nil then
				ammostring = "nil"
			else
				ammostring = 
					weapons.player_list[pname][weapon._ammo_type] .. "/" .. weapons.player_list[pname][weapon._ammo_type.."_max"]
			end
		end
		player:hud_change(weapons.player_huds[pname].ammo.ammo_count, "text", ammostring)

	end
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local weapon = minetest.registered_nodes[player:get_wielded_item():get_name()]
		if weapon == nil then
		else
			local bar_count = calc_ammo_bar_pos(player, weapon)
			if last_ammo_count[pname] ~= weapons.player_list[pname][weapon._ammo_type] then
				last_ammo_count[pname] = weapons.player_list[pname][weapon._ammo_type]
				hud_update_ammo(player, bar_count, weapon)
			end
		end
	end
end)

function weapons.hud.force_ammo_refresh(player)
	local pname = player:get_player_name()
	local weapon = minetest.registered_nodes[player:get_wielded_item():get_name()]
	if weapon == nil then
	else
		local bar_count = calc_ammo_bar_pos(player, weapon)
		hud_update_ammo(player, bar_count, weapon)
	end
end

function weapons.hud.draw_ammo(pname, scale, count_text, count_ammo)
	local player = minetest.get_player_by_name(pname)
	weapons.player_huds[pname].ammo.reloading = player:hud_add({
		hud_elem_type = "image",
		position = {x=1, y=0},
		offset = {x=ammo_x_offset, y=ammo_y_offset+(ammo_scale.reload_offset*scale)},
		alignment = {x=-1, y=0},
		text = "transparent.png",
		scale = {x=ammo_scale.reload*scale, y=(ammo_scale.reload*scale)},
		z_index = -998
	})

	weapons.player_huds[pname].ammo.ammo_count = player:hud_add({
		hud_elem_type = "text",
		position = {x=1, y=0},
		offset = {x=(ammo_x_offset-(256*scale))+(8*scale), y=ammo_y_offset-(24*scale)},
		alignment = {x=1, y=0},
		text = count_text,
		number = 0xffffff,
		size = {x=ammo_scale.bar_x*scale, y=ammo_scale.bar_y*scale},
		z_index = -996
	})

	for i=1, 4 do
		weapons.player_huds[pname].ammo["ammo_fill_" .. i] = player:hud_add({
			hud_elem_type = "image",
			position = {x=1, y=0},
			offset = {x=((ammo_fill_mult*i)*scale)+ammo_x_offset, y=ammo_y_offset+(16*scale)},
			alignment = {x=0, y=0},
			text = "hud_bar_chamber.png^[opacity:".. math.floor(ammo_mark_opac*i),
			scale = {x=2.5*scale, y=1*scale},
			z_index = -995		
		})
	end

	local over_string, ammo_bar_fg, ammo_bar_bg = get_ammo_appearances(player, weapon)

	weapons.player_huds[pname].ammo.ammo_overlay = player:hud_add({
		hud_elem_type = "image",
		position = {x=1, y=0},
		offset = {x=ammo_x_offset+(2*scale), y=ammo_y_offset},
		alignment = {x=-1, y=1},
		text = over_string,
		scale = {x=scale, y=scale},
		z_index = -995
	})

	weapons.player_huds[pname].ammo.ammo_bar = player:hud_add({
		hud_elem_type = "statbar",
		position = {x=1, y=0},
		offset = {x=ammo_x_offset, y=ammo_y_offset},
		text = ammo_bar_fg.."^(hud_bar_grad.png^[opacity:127)",
		number = count_ammo, -- FG
		direction = 1,
		size = {x=ammo_scale.bar_x*scale, y=ammo_scale.bar_y*scale},
		z_index = -997
	})

	weapons.player_huds[pname].ammo.ammo_bar_bg = player:hud_add({
		hud_elem_type = "statbar",
		position = {x=1, y=0},
		offset = {x=ammo_x_offset, y=ammo_y_offset},
		text = ammo_bar_bg.."^(hud_bar_grad.png^[opacity:127)",
		number = 256, -- FG
		direction = 1,
		size = {x=ammo_scale.bar_x*scale, y=ammo_scale.bar_y*scale},
		z_index = -998
	})
end

-- This function isn't run often so updating or replacing huds isn't expensive as it's
-- generally expected to be run once or twice
local function scale_ammo(pname, scale, remove_huds)
	local player = minetest.get_player_by_name(pname)
	local weapon
	local count_text = ""
	local count_ammo = 256
	if remove_huds then
		-- Obliterate the original huds as adding new huds is a lot less
		-- than manually hud_change() a large number of values
		player:hud_remove(weapons.player_huds[pname].ammo.reloading)
		player:hud_remove(weapons.player_huds[pname].ammo.ammo_bar)
		player:hud_remove(weapons.player_huds[pname].ammo.ammo_bar_bg)
		player:hud_remove(weapons.player_huds[pname].ammo.ammo_count)
		player:hud_remove(weapons.player_huds[pname].ammo.ammo_overlay)
		for i=1, 4 do
			player:hud_remove(weapons.player_huds[pname].ammo["ammo_fill_"..i])
		end

		-- Fix text for regenerating the ammo readout
		weapon = minetest.registered_nodes[player:get_wielded_item():get_name()]
		count_ammo = calc_ammo_bar_pos(player, weapon)
		if weapon._ammo_type == nil then
			count_text = ""
		else
			count_text = weapons.player_list[pname][weapon._ammo_type] .. 
				"/" .. weapons.player_list[pname][weapon._ammo_type.."_max"]
		end
	end

	-- Prevent non-linear scaling of things
	local px_perfect = cap_scale_to_int(scale)
	weapons.hud.draw_ammo(pname, px_perfect, count_text, count_ammo)

	if remove_huds then
		weapons.hud.force_ammo_refresh(player)
	end
end

minetest.register_on_chatcommand(function(name, command, params)
	if command == "scale_ammo" then
		weapons.player_data[name].ammo_scale = tonumber(params)
		persistence.save_data("weapons_player_data", weapons.player_data)
		scale_ammo(name, weapons.player_data[name].ammo_scale, true)
		minetest.log("action", name .. " set their ammo scaling to: " .. params)
		return true
	end
end)

-- Health bar and shit:

local function calc_hp_bar_pos(player)
	local pname = player:get_player_name()
	-- try the call again after a short period to avoid accessing nil
	-- as these values are probably needed immediately
	if weapons.player_list[pname].hp == nil then
		return 512
	elseif weapons.player_list[pname].hp_max == nil then
		return 512
	else
		-- actually return a hp bar value since we can guarantee the player is alive.
		return math.floor(
			(512/weapons.player_list[pname].hp_max) * weapons.player_list[pname].hp
		)
	end
end

local function calc_hp_text(player)
	local pname = player:get_player_name()
	local msg = ""
	if weapons.player_list[pname] == nil then
		return msg, msg
	elseif weapons.player_list[pname].hp == nil then
		return msg, msg
	elseif weapons.player_list[pname].hp_max == nil then
		return msg, msg
	else
		local msg1 = weapons.player_list[pname].hp.."hp"
		local perc_v = (weapons.player_list[pname].hp/weapons.player_list[pname].hp_max) * 100
		local msg2 = string.format(perc_v, "%%.2f").."%"
		return msg1, msg2			
	end
end

function weapons.hud.draw_hp(pname, scale, hp_num, hp_count, hp_perc)
	local player = minetest.get_player_by_name(pname)
	weapons.player_huds[pname].health.health_bar = player:hud_add({
		hud_elem_type = "statbar",
		position = {x=0.5, y=0},
		offset = {x=hp_x_offset*scale, y=hp_y_offset*scale},
		text = "hud_hp_bar.png",
		number = hp_count,
		direction = 0,
		size = {x=hp_scale.bar_x*scale, y=hp_scale.bar_y*scale},
		z_index = -989
	})

	weapons.player_huds[pname].health.health_overlay = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0},
		alignment = {x=0, y=1},
		offset = {x=0, y=(hp_y_offset-4)*scale},
		text = "hud_hp_overlay.png",
		scale = {x=scale, y=scale},
		z_index = -988
	})

	weapons.player_huds[pname].health.health_count = player:hud_add({
		hud_elem_type = "text",
		position = {x=0.5, y=0},
		offset = {x=hp_x_offset*scale, y=(hp_y_offset+26)*scale},
		number = 0xffffff,
		alignment = {x=1, y=1},
		text = hp_num,
		size = {x=hp_scale.count*scale, y=hp_scale.count*scale},
		z_index = -985
	})

	weapons.player_huds[pname].health.health_perc = player:hud_add({
		hud_elem_type = "text",
		position = {x=0.5, y=0},
		offset = {x=-hp_x_offset*scale, y=(hp_y_offset+26)*scale},
		number = 0xffffff,
		alignment = {x=-1, y=1},
		text = hp_perc,
		size = {x=hp_scale.count*scale, y=hp_scale.count*scale},
		z_index = -985
	})
end

function weapons.hud.force_hp_refresh(player)
	local pname = player:get_player_name()
	if weapons.player_huds[pname].health.health_bar == nil then
	else
		local num = calc_hp_bar_pos(player)
		player:hud_change(weapons.player_huds[pname].health.health_bar, "number", num)
	end
	if weapons.player_huds[pname].health.health_bar == nil then
	else
		local hp, perc = calc_hp_text(player)
		player:hud_change(weapons.player_huds[pname].health.health_count, "text", hp)
		player:hud_change(weapons.player_huds[pname].health.health_perc, "text", perc)
	end
end

local function scale_health(pname, scale, remove_huds)
	local player = minetest.get_player_by_name(pname)
	local hp_num, hp_perc
	local hp_count = 512

	if remove_huds then
		player:hud_remove(weapons.player_huds[pname].health.health_bar)
		player:hud_remove(weapons.player_huds[pname].health.health_count)
		player:hud_remove(weapons.player_huds[pname].health.health_perc)
		player:hud_remove(weapons.player_huds[pname].health.health_overlay)
		--player:hud_remove(weapons.player_huds[pname].health.)
		--player:hud_remove(weapons.player_huds[pname].health.)
		--player:hud_remove(weapons.player_huds[pname].health.)
		hp_count = calc_hp_bar_pos(player)
		hp_num, hp_perc = calc_hp_text(player)
	end

	-- Prevent non-linear scaling of things
	local px_perfect = cap_scale_to_int(scale)
	weapons.hud.draw_hp(pname, px_perfect, hp_num, hp_count, hp_perc)

	if remove_huds then
		weapons.hud.force_hp_refresh(player)
	end
end

minetest.register_on_chatcommand(function(name, command, params)
	if command == "scale_health" then
		weapons.player_data[name].hp_scale = tonumber(params)
		persistence.save_data("weapons_player_data", weapons.player_data)
		scale_health(name, weapons.player_data[name].hp_scale, true)
		minetest.log("action", name .. " set their health bar scaling to: " .. params)
		return true
	end
end)

minetest.register_chatcommand("set_health", {
	description = "testing feature.",
	func = function(name, param)
		weapons.player_list[name].hp = tonumber(param)
		weapons.hud.update_vignette(minetest.get_player_by_name(name))
	end,
})

-- Crosshair management:

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local weapon = minetest.registered_nodes[player:get_wielded_item():get_name()]
		if weapon == nil then
		else
			if weapons.player_list[pname].aim_mode then
				if weapon._crosshair_aim == nil then
				elseif weapon._crosshair_aim ~= last_crosshair[pname] then
					last_crosshair[pname] = weapon._crosshair_aim
					player:hud_change(weapons.player_huds[pname].misc.crosshair, "text", weapon._crosshair_aim)
				end
			else
				if weapon._crosshair == nil then
				elseif weapon._crosshair ~= last_crosshair[pname] then
					last_crosshair[pname] = weapon._crosshair
					player:hud_change(weapons.player_huds[pname].misc.crosshair, "text", weapon._crosshair)
				end
			end
		end
		
	end
end)

-- Misc hud things:

function weapons.hud.hide_hitmarker(player)
	player:hud_change(weapons.player_huds[player:get_player_name()].misc.hitmarker, "text",
		"transparent.png")
end

-- Prevent overlapping afters
local hitmarker_after = {}

function weapons.hud.render_hitmarker(player, headshot)
	local pname = player:get_player_name()

	if headshot == nil then
		player:hud_change(weapons.player_huds[pname].misc.hitmarker, "text", "hitmarker.png")
	elseif headshot then
		player:hud_change(weapons.player_huds[pname].misc.hitmarker, "text", "hitmarker_headshot.png")
	else
		player:hud_change(weapons.player_huds[pname].misc.hitmarker, "text", "hitmarker.png")
	end

	if hitmarker_after[pname] ~= nil then -- Cancel any outstanding hitmarker.
		hitmarker_after[pname]:cancel()
		hitmarker_after[pname] = nil
	end
	hitmarker_after[pname] = minetest.after(0.25, weapons.hud.hide_hitmarker, player)
end

-- This functions sole existance is to update waypoints if bases fail to generate on-time or properly
-- Ideally - this funtion should never be called except once or twice.
function weapons.hud.update_base_waypoint()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		player:hud_remove(weapons.player_huds[pname].misc.red_base)
		player:hud_remove(weapons.player_huds[pname].misc.blu_base)
		-- Red Base waypoint
		local red = 207-35
		weapons.player_huds[pname].misc.red_base = player:hud_add({
			hud_elem_type = "waypoint",
			name = "Red Base",
			text = "m",
			number = weapons.teams.red_colour,
			world_pos = {x=red, y=weapons.red_base_y, z=red}
		})
	
		-- Blue Base waypoint
		local blu = 147-4
		weapons.player_huds[pname].misc.blu_base = player:hud_add({
			hud_elem_type = "waypoint",
			name = "Blue Base",
			text = "m",
			number = weapons.teams.blue_colour,
			world_pos = {x=-blu, y=weapons.blu_base_y, z=-blu}
		})
	end
end

function weapons.hud.create_base_waypoint(player)
	local pname = player:get_player_name()
	-- Red Base waypoint
	local red = 207-35
	weapons.player_huds[pname].misc.red_base = player:hud_add({
		hud_elem_type = "waypoint",
		name = "Red Base",
		text = "m",
		number = weapons.teams.red_colour,
		world_pos = {x=red, y=weapons.red_base_y, z=red}
	})

	-- Blue Base waypoint
	local blu = 147-4
	weapons.player_huds[pname].misc.blu_base = player:hud_add({
		hud_elem_type = "waypoint",
		name = "Blue Base",
		text = "m",
		number = weapons.teams.blue_colour,
		world_pos = {x=-blu, y=weapons.blu_base_y, z=-blu}
	})
end

-- All important on_joinplayer things:

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	weapons.player_huds[pname] = {}
	weapons.player_huds[pname].ammo = {}
	weapons.player_huds[pname].health = {}
	weapons.player_huds[pname].misc = {}
	last_ammo_count[pname] = 0
	last_crosshair[pname] = "InVaLiD TeXtUrE.mP4"
	last_weapon[pname] = "InVaLiD WeApOn.webm"

	weapons.player_huds[pname].misc.vignette = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=-100, y=-100},
		text = "(hud_vignette.png^[multiply:#000000)^[opacity:"..min_vig_opacity,
		offset = {x=0, y=-1},
		z_index = -999
	})

	weapons.player_huds[pname].misc.crosshair = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	
	weapons.player_huds[pname].misc.hitmarker = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	weapons.player_huds[pname].misc.blackout = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=-100, y=-100},
		text = "transparent.png",
		offset = {x=0, y=-1},
		z_index = 999
	})

	weapons.hud.create_base_waypoint(player)

	-- Handle user offsets first. (This should only be created here once, and then never occur again.)
	if weapons.player_data[pname] == nil then
	else
		if weapons.player_data[pname].offsets == nil then
			weapons.player_data[pname].offsets = {}
			weapons.player_data[pname].offsets.hp = {x=0, y=0}
			weapons.player_data[pname].offsets.ammo = {x=0, y=0}
			weapons.player_data[pname].offsets.score = {x=0, y=0}
			weapons.player_data[pname].offsets.killfeed = {x=0, y=0}
			persistence.save_data("weapons_player_data", weapons.player_data)
			minetest.log("action", pname .. " lacks user settings for definable HUD offsets, creating defaults now.")
		end

		if weapons.player_data[pname].ammo_scale == nil then
			-- Should be a weapons.save_player_data() func, but i'm lazy TODO
			weapons.player_data[pname].ammo_scale = 1
			persistence.save_data("weapons_player_data", weapons.player_data)
			minetest.log("action", pname .. " lacked an ammo scaling setting, defaulting to 1.")
		end
		
		if weapons.player_data[pname].hp_scale == nil then
			weapons.player_data[pname].hp_scale = 1
			persistence.save_data("weapons_player_data", weapons.player_data)
			minetest.log("action", pname .. " lacked a health scaling setting, defaulting to 1.")
		end

		scale_ammo(pname, weapons.player_data[pname].ammo_scale, false)
		scale_health(pname, weapons.player_data[pname].hp_scale, false)
	end
end)