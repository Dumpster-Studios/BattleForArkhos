-- Dumpster Studios, Battle for Arkhos
-- Author Jordach
-- License Reserved

local player_phys = {}
local player_key_timer = {}
local player_timers = {}
local player_fov = {}

local function set_keys(pname)
	player_key_timer[pname] = 0
end

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

local function conv_heat_to_rpm(weapon, player)
	local pname = player:get_player_name()
	local current_heat = weapons.player_list[pname][weapon._ammo_type]
	local mult = weapon._accel_mult or 1
	if current_heat == nil then
		return 1
	elseif current_heat > 99 then
		return 1
	elseif current_heat < 100 then
		return solarsail.util.functions.remap(current_heat, 0, 100, 1, weapon._accel_mult)
	else
		return 1
	end
end

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
			local rpm_modifier = 1

			if weapon == nil then
			elseif weapon._heat_accelerated == nil then
			elseif weapon._heat_accelerated then
				rpm_modifier = conv_heat_to_rpm(weapon, player)
			end

			if weapon == nil then
			elseif weapon._name == nil then
			elseif weapon._rpm == nil then
			elseif player_timers[pname].fire > (60 / weapon._rpm) / rpm_modifier  then
				if solarsail.controls.player[pname].LMB then
					player_timers[pname].fire = 0
					if weapon._type == "gun" then
						local ammo = weapon._ammo_type
						if weapons.player_list[pname][ammo] >= 0 then
							if not weapons.is_reloading[pname][wield] then
								weapon.on_fire(player, weapon)
							end
						end
					elseif weapon._type == "block" then
						-- TODO: Move to custom on_place function
						if weapons.player_list[player:get_player_name()].blocks > 0 then
							weapon.on_fire(player, weapon)
							weapons.player_list[player:get_player_name()].blocks = 
								weapons.player_list[player:get_player_name()].blocks - 1
						end
					else
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