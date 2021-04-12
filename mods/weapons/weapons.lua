--[[
 NOTE:

 Topping off reloads are always 10% faster than an empty magazine.

]]-- 

local function no_drop_place(itemstack)
	return itemstack
end

function weapons.register_weapon(name, creator_allowed, def)
	local node = table.copy(def)
	node.drawtype = "glasslike"
	node.tiles = {"transparent.png"}
	if node.range == nil then
		node.range = 0
	end
	node.node_placement_prediction = ""
	
	if creator_allowed then
		if type(node._localisation) ~= "table" then
			error([[Invalid weapon registry: ]]..name..[[._localisation needs to be a table.]])
		end
		if node._slot == nil then
			error([[Invalid weapon registry: ]]..name..[[._slot does not exist.]])
			elseif node._slot == "grenade" then
				weapons.creator.register_weapon(node._localisation, node._slot)
			elseif node._slot == "primary" then
				weapons.creator.register_weapon(node._localisation, node._slot)
			elseif node._slot == "secondary" then
				weapons.creator.register_weapon(node._localisation, node._slot)
			else
				error([[Invalid weapon registry: ]]..name..[[._slot needs to be one of the following:
					"primary" "secondary" or "grenade".]])
			end
		end
	node.on_place = no_drop_place
	node.on_drop = no_drop_place
	minetest.register_node(name, node)
	weapons.registry[name] = node
end

function weapons.energy_overheat(player, weapon, wield, keypressed)
	-- Energy weapons don't have manually started reloads
	if keypressed then return end
	local pname = player:get_player_name()
	if not weapons.is_reloading[pname][wield] then
		weapons.is_reloading[pname][wield] = true
		weapons.player_list[pname].anim_mode = false
		minetest.after(weapon._reload, weapons.finish_energy_weapon, player, weapon, wield, false)

		minetest.sound_play({name=weapon._reload_sound},
			{object=player, max_hear_distance=8, gain=0.15})
		if weapon._no_reload_hud then
		else
			player:hud_change(weapons.player_huds[pname].ammo.reloading, 
				"text", "reloading.png")
		end
	end
end

function weapons.veteran_reload(player, weapon, wield, keypressed)
	local pname = player:get_player_name()
	if weapon == nil then
	elseif weapon._mag ~= nil then
		local ammo = weapon._ammo_type
		if weapons.player_list[pname][ammo] == 0 then
			if not weapons.is_reloading[pname][wield] then
				weapons.is_reloading[pname][wield] = true
				weapons.player_list[pname].anim_mode = false
				minetest.after(weapon._reload, weapons.finish_magazine, player, weapon, wield, false)
				minetest.sound_play({name=weapon._reload_sound},
					{object=player, max_hear_distance=8, gain=0.32})
				if weapon._no_reload_hud then
				else
					player:hud_change(weapons.player_huds[pname].ammo.reloading, 
						"text", "reloading.png")
				end
			end
		end
	end
end

function weapons.magazine_reload(player, weapon, wield, keypressed)
	local pname = player:get_player_name()
	if weapon == nil then
	elseif weapon._mag ~= nil then
		local ammo = weapon._ammo_type
		if weapons.player_list[pname][ammo] < weapons.player_list[pname][ammo.."_max"] then
			if weapons.player_list[pname][ammo] >= 0 then
				local chambered = false
				local chamber_bonus = 1 -- Normal reload speed
				weapons.player_list[pname].anim_mode = false
				if weapons.player_list[pname][ammo] > 0 then -- Ensure there's a round in the chamber
					chambered = true
					chamber_bonus = 0.9
					weapons.player_list[pname].anim_mode = true
				end
				weapons.player_list[pname][ammo] = 0
				if not weapons.is_reloading[pname][wield] then
					weapons.is_reloading[pname][wield] = true
					minetest.after(weapon._reload * chamber_bonus, weapons.finish_magazine, player, weapon, wield, chambered)
					if weapons.player_list[pname].anim_mode then
						minetest.sound_play({name=weapon._reload_sound_alt},
							{object=player, max_hear_distance=8, gain=0.15})
					else
						minetest.sound_play({name=weapon._reload_sound},
							{object=player, max_hear_distance=8, gain=0.15})
					end
					if weapon._no_reload_hud then
					else
						player:hud_change(weapons.player_huds[pname].ammo.reloading, 
						"text", "reloading.png")
					end
				end
			end
		end
	end
end

function weapons.finish_magazine(player, weapon, wieldname, oneic)
	local pname = player:get_player_name()
	if weapons.is_reloading[pname] == nil then
		return
	elseif weapons.is_reloading[pname][wieldname] then
		weapons.is_reloading[pname][wieldname] = false
		if weapons.player_list[pname] == nil then
			return
		end

		local ammo = weapon._ammo_type
		if oneic then
			weapons.player_list[pname][ammo] =
				weapons.player_list[pname][ammo.."_max"] + 1
		else
			weapons.player_list[pname][ammo] =
				weapons.player_list[pname][ammo.."_max"]
		end

		-- Avoid sending HUD updates unless needed
		if weapon._no_reload_hud then
		else
			player:hud_change(weapons.player_huds[pname].ammo.reloading,
				"text", "transparent.png")
		end
	end
end

function weapons.finish_energy_weapon(player, weapon, wieldname, oneic)
	local pname = player:get_player_name()
	if weapons.is_reloading[pname] == nil then
		return
	elseif weapons.is_reloading[pname][wieldname] then
		weapons.is_reloading[pname][wieldname] = false

		-- Avoid sending HUD updates unless needed
		if weapon._no_reload_hud then
		else
			player:hud_change(weapons.player_huds[pname].ammo.reloading,
				"text", "transparent.png")
		end
	end
end

function weapons.tube_reload(player, weapon, wield, keypressed)
	local pname = player:get_player_name()
	if weapon == nil then
	elseif weapon._mag ~= nil then
		local ammo = weapon._ammo_type
		if weapons.player_list[pname][ammo] < weapons.player_list[pname][ammo.."_max"] + 1 then
			if not keypressed then return end -- Manual reloading only
			if not weapons.is_reloading[pname][wield] then
				weapons.is_reloading[pname][wield] = true
				if weapons.player_list[pname][ammo] == 0 then
					minetest.after(weapon._reload, weapons.finish_tube, player, weapon, wield)
					weapons.player_list[pname].anim_mode = false
					minetest.sound_play({name=weapon._reload_sound},
						{object=player, max_hear_distance=8, gain=0.15})
				else
					minetest.after(weapon._reload*0.9, weapons.finish_tube, player, weapon, wield)
					weapons.player_list[pname].anim_mode = true
					minetest.sound_play({name=weapon._reload_sound_alt},
						{object=player, max_hear_distance=8, gain=0.15})
				end

				if weapon._no_reload_hud then
				else
					player:hud_change(weapons.player_huds[pname].ammo.reloading, 
						"text", "reloading.png")
				end
			end
		end
	end
end

function weapons.finish_tube(player, weapon, wieldname)
	local pname = player:get_player_name()
	if weapons.is_reloading[pname] == nil then
		return
	elseif weapons.is_reloading[pname][wieldname] then
		weapons.is_reloading[pname][wieldname] = false
		if weapons.player_list[pname] == nil then
			return
		end

		local ammo = weapon._ammo_type
		local max_shells = weapons.player_list[pname][ammo.."_max"] + 1

		if weapons.player_list[pname][ammo] < max_shells then
			weapons.player_list[pname][ammo] = weapons.player_list[pname][ammo] + 1
		end
		-- Avoid sending HUD updates unless needed
		if weapon._no_reload_hud then
		else
			player:hud_change(weapons.player_huds[pname].ammo.reloading,
				"text", "transparent.png")
		end
	end
end

function weapons.raycast_bullet(player, weapon)
	local wield = player:get_wielded_item():get_name()
	local pname = player:get_player_name()
	local ammo = weapon._ammo_type
	
	if weapons.player_list[pname][ammo] > 0 then -- Ensure there's actually bullets in the mag/chamber
		minetest.sound_play({name=weapon._firing_sound}, 
			{pos=player:get_pos(), max_hear_distance=128, gain=1.75, pitch=math.random(95, 105)/100})
		weapons.player_list[pname][ammo] = 
			weapons.player_list[pname][ammo] - 1
		if weapons.player_list[pname][ammo] == 0 then
			if weapon.on_reload == nil then
			else
				weapon.on_reload(player, weapon, wield, false)
			end
		end

		if weapon.on_fire_visual == nil then
		else
			weapon.on_fire_visual(player)
		end

		for i=1, weapon._pellets do
			-- Ray calculations.
			local raybegin = vector.add(player:get_pos(), {x=0, y=weapons.default_eye_height, z=0})
			local raygunbegin = vector.add(player:get_pos(), {x=0, y=1.2, z=0})
			local vec_x, vec_y, vec_z

			-- Handle aiming
			local fatigue_mult = weapons.player_list[pname].fatigue / 100
			if weapons.player_list[pname].fatigue < weapon._fatigue then
				-- This only applies to shotguns.
				if weapon._pellets > 1 then
					fatigue_mult = (weapon._fatigue/2.5) / 100
				end
			end
			if weapons.player_list[pname].aim_mode then
				local spread = weapon._spread_aim * fatigue_mult
				vec_x = math.random(-spread * 100, spread * 100) / 100
				vec_y = math.random(-spread * 100, spread * 100) / 100
				vec_z = math.random(-spread * 100, spread * 100) / 100
			else
				local spread = weapon._spread * fatigue_mult
				vec_x = math.random(-spread * 100, spread * 100) / 100
				vec_y = math.random(-spread * 100, spread * 100) / 100
				vec_z = math.random(-spread * 100, spread * 100) / 100
			end

			local aim_mod = {x=vec_x, y=vec_y, z=vec_z}
			local raymod = vector.add(
				vector.multiply(player:get_look_dir(), weapon._range), aim_mod
			)
			local rayend = vector.add(raybegin, raymod)
			local ray = minetest.raycast(raybegin, rayend, true, false)
			local pointed = ray:next()
			pointed = ray:next()
			local target_pos

			if weapon._tracer == nil then
			else
				local tracer_pos = vector.add(
					vector.add(player:get_pos(), vector.new(0, 1.2, 0)), 
						vector.multiply(player:get_look_dir(), 1)
				)
				local yp = solarsail.util.functions.y_direction(player:get_look_vertical(), 20)
				local px, pz = solarsail.util.functions.yaw_to_vec(player:get_look_horizontal(), 20, false)
				local pv = vector.add(raybegin, {x=px, y=yp, z=pz})
				local pr = vector.add(pv, raymod)

				local tracer_vel = vector.add(
					vector.multiply(vector.direction(pv, pr), 120), 
						vector.new(0, 0.44, 0)
				)
				
				local xz, y = solarsail.util.functions.get_3d_angles(
					vector.add(player:get_pos(), vector.new(0, weapons.default_eye_height, 0)),
					vector.add(tracer_pos, tracer_vel)				
				)

				local ent = minetest.add_entity(tracer_pos, 
								"weapons:tracer_" .. weapon._tracer)

				ent:set_velocity(tracer_vel)
				ent:set_rotation(vector.new(y, xz, 0))
			end

			if pointed == nil then
			else
				-- Handle target;
				if pointed.type == "object" then
					target_pos = pointed.ref:get_pos()
				else
					target_pos = pointed.under
				end
			end

			-- Calculate time to target and distance to target;
			if target_pos == nil then
			else
				local dist = solarsail.util.functions.pos_to_dist(raybegin, target_pos)

				minetest.after(dist/weapon._speed, weapon.bullet_on_hit, pointed, player,
					weapon, target_pos, dist)
			end
		end
		weapons.player_list[pname].fatigue = weapons.player_list[pname].fatigue + weapon._fatigue
		if weapons.player_list[pname].fatigue > 100 then
			weapons.player_list[pname].fatigue = 100
		end
		-- Handle recoil of the equipped weapon
		solarsail.util.functions.apply_recoil(player, weapon)
	end
end

function weapons.bullet_on_hit(pointed, player, weapon, target_pos, dist)
	if pointed.type == "object" then
		local t_pos = pointed.ref:get_pos()
		if t_pos == nil then return end
		local diff = solarsail.util.functions.pos_to_dist(t_pos, target_pos)
		if diff < 0.31 then
			if pointed.ref:is_player() then
				weapons.handle_damage(weapon, player, pointed.ref, dist, pointed)
			end
		end
	else
		for _, players in ipairs(minetest.get_connected_players()) do
			if player:get_player_name() ~= players:get_player_name() then
				local ppos = players:get_pos()
				local splash_dist = solarsail.util.functions.pos_to_dist(ppos, pointed.intersection_point)
				if splash_dist < 0.61 then
					weapons.handle_damage(weapon, player, players, dist, nil)
					return
				end
			end
		end

		local nodedef = minetest.registered_nodes[minetest.get_node(target_pos).name]
		minetest.sound_play("block_impact", {pos=target_pos, 
			max_hear_distance=8, gain=0.875}, true)

		if nodedef == nil then
		else
			local damage, node, result = weapons.calc_block_damage(nodedef, weapon, target_pos, pointed)
			if result == nil then
				minetest.set_node(target_pos, {name=node})
				minetest.check_for_falling(target_pos)
			end
		end
	end
end

function weapons.raycast_melee(player, weapon)
	-- Ray calculations.
	local raybegin = vector.add(player:get_pos(), {x=0, y=weapons.default_eye_height, z=0})
	local raymod = vector.multiply(player:get_look_dir(), weapon._range)
	local rayend = vector.add(raybegin, raymod)
	local ray = minetest.raycast(raybegin, rayend, true, false)
	local pointed = ray:next()
	pointed = ray:next()
	local target_pos

	if pointed == nil then
	else
		-- Handle target;
		if pointed.type == "object" then
			target_pos = pointed.ref:get_pos()
		else
			target_pos = pointed.under
		end
	end

	-- Calculate time to target and distance to target;
	if target_pos == nil then
	else
		local dist = solarsail.util.functions.pos_to_dist(raybegin, target_pos)
		minetest.after(dist/weapon._speed, weapon.melee_on_hit, pointed, player,
			weapon, target_pos, dist)
	end
end

function weapons.melee_on_hit(pointed, player, weapon, target_pos, dist)
	if pointed.type == "object" then
		if pointed.ref:is_player() then
			weapons.handle_damage(weapon, player, pointed.ref, dist, pointed)
		end
	else
		local nodedef = minetest.registered_nodes[minetest.get_node(target_pos).name]

		if nodedef == nil then
		else
			local damage, node, result = weapons.calc_block_damage(nodedef, weapon, target_pos, pointed)
			if result == nil then
				minetest.set_node(target_pos, {name=node})
			end
			if damage < 1 then
				if weapon._type == "tool" then
					if weapons.player_list[player:get_player_name()].blocks <
					weapons.player_list[player:get_player_name()].blocks_max then
						weapons.player_list[player:get_player_name()].blocks =
						weapons.player_list[player:get_player_name()].blocks + 1
					end
				elseif weapon._type == "tool_alt" then
					local alt_pos = {x=target_pos.x, y=target_pos.y-1, z=target_pos.z}
					local alt_node = minetest.registered_nodes[minetest.get_node(alt_pos).name]

					-- Stop entrenching tools digging into bases
					if alt_node._takes_damage == nil then
						if result == nil then
							minetest.set_node(alt_pos, {name="air"})
							weapons.spray_particles(nil, nodedef,
								{x=target_pos.x, y=target_pos.y-1, z=target_pos.z})
						end
					end
				end
			end
			minetest.check_for_falling(target_pos)
		end
	end
end

function weapons.raycast_flag_melee(player, weapon)
	-- Ray calculations.
	local raybegin = vector.add(player:get_pos(), {x=0, y=weapons.default_eye_height, z=0})
	local raymod = vector.multiply(player:get_look_dir(), weapon._range)
	local rayend = vector.add(raybegin, raymod)
	local ray = minetest.raycast(raybegin, rayend, true, false)
	local pointed = ray:next()
	pointed = ray:next()
	local target_pos

	if pointed == nil then
	else
		-- Handle target;
		if pointed.type == "object" then
			target_pos = pointed.ref:get_pos()
		else
			target_pos = pointed.under
		end
	end

	-- Calculate time to target and distance to target;
	if target_pos == nil then
	else
		local dist = solarsail.util.functions.pos_to_dist(raybegin, target_pos)
		minetest.after(dist/weapon._speed, weapon.flag_on_hit, pointed, player,
			weapon, target_pos, dist)
	end
end

function weapons.flag_on_hit(pointed, player, weapon, target_pos, dist)
	if pointed.type == "object" then
		if pointed.ref:is_player() then
			weapons.handle_damage(weapon, player, pointed.ref, dist, pointed)
		end
	end
end

function weapons.place_block(player, weapon)
	-- Ray calculations.
	local raybegin = vector.add(player:get_pos(), {x=0, y=weapons.default_eye_height, z=0})
	local raymod = vector.multiply(player:get_look_dir(), weapon._range)
	local rayend = vector.add(raybegin, raymod)
	local ray = minetest.raycast(raybegin, rayend, true, false)
	local pointed = ray:next()
	pointed = ray:next()
	local target_pos

	local pname = player:get_player_name()
	if pointed == nil then
		if weapon._type == "block" then
			weapons.player_list[pname].blocks =
				weapons.player_list[pname].blocks + 1
		end
	else
		-- Handle targets, refund if a player or entity;
		if pointed.type == "object" then
			target_pos = pointed.ref:get_pos()
			weapons.player_list[pname].blocks =
				weapons.player_list[pname].blocks + 1
			return
		else
			target_pos = pointed.under
		end
	end

	-- Place blocks;
	if target_pos == nil then
	else
		if pointed.type ~= "object" then
			local block_pos = table.copy(pointed.above)
			if pointed.intersection_normal.y < 1 then
				-- Fixes placing on sides and below
				block_pos.y = block_pos.y + 1
			end
			local check = minetest.get_node(block_pos).name
			if check == "core:base_door" then
				weapons.player_list[pname].blocks =
					weapons.player_list[pname].blocks + 1
				return
			end
			minetest.place_node(block_pos, 
				{name="core:"..weapon._node.."_"
					..weapons.player_list[pname].team.."_4"})
		end
	end
end

local player_cooldown_timer = {}
-- Handle energy weapon cooldowns:
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local weapon = minetest.registered_nodes[player:get_wielded_item():get_name()]

		if player_cooldown_timer[pname] == nil then
			player_cooldown_timer[pname] = 0 - dtime
		end

		if weapon == nil then
		elseif weapon._is_energy == nil then
		elseif weapon._is_energy then
			local ammo = weapon._ammo_type
			if not solarsail.controls.player[pname].LMB then
				if player_cooldown_timer[pname] > weapon._cool_timer then
					local cng = math.floor(weapons.player_list[pname][ammo] * weapon._cool_rate) - 1
					if cng < 0 then cng = 0 end
					weapons.player_list[pname][ammo] = cng
					player_cooldown_timer[pname] = 0
				else
					player_cooldown_timer[pname] = player_cooldown_timer[pname] + dtime
				end
			elseif weapons.is_reloading[pname][player:get_wielded_item():get_name()] then
				if player_cooldown_timer[pname] > weapon._cool_timer then
					local cng = math.floor(weapons.player_list[pname][ammo] * weapon._cool_rate) - 1
					if cng < 0 then cng = 0 end
					weapons.player_list[pname][ammo] = cng
					player_cooldown_timer[pname] = 0
				else
					player_cooldown_timer[pname] = player_cooldown_timer[pname] + dtime
				end
			elseif solarsail.controls.player[pname].LMB then
				player_cooldown_timer[pname] = 0
			end
		end
	end
end)

local player_fatigue_timer = {}
-- Handle weapon sway cooldowns from firing too long
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local weapon = minetest.registered_nodes[player:get_wielded_item():get_name()]
		if player_fatigue_timer[pname] == nil then
			player_fatigue_timer[pname] = 0 - dtime
		end

		player_fatigue_timer[pname] = player_fatigue_timer[pname] + dtime

		if weapon == nil then
		elseif weapon._fatigue_timer == nil then
			error("weapon: " .. weapon._localisation.itemstring .. " missing ._fatigue_timer field.")
		elseif weapons.player_list[pname].fatigue == 0 then -- don't even bother trying
		elseif player_fatigue_timer[pname] > weapon._fatigue_timer then
			local ammo = weapon._ammo_type
			if weapon._fatigue_recovery == nil then
				error("weapon: " .. weapon._localisation.itemstring .. " missing ._fatigue_recovery")
			end
			if weapons.is_reloading[pname][ammo] then
				if weapons.player_list[pname].fatigue > 0 then
					weapons.player_list[pname].fatigue = weapons.player_list[pname].fatigue * weapon._fatigue_recovery
				end
			elseif not solarsail.controls.player[pname].LMB then
				if weapons.player_list[pname].fatigue <= 0.01 then
					weapons.player_list[pname].fatigue = 0
				elseif weapons.player_list[pname].fatigue > 0.01 then
					weapons.player_list[pname].fatigue = weapons.player_list[pname].fatigue * weapon._fatigue_recovery
				end
			else
			end
			player_fatigue_timer[pname] = 0
		end
	end
end)