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
				if keypressed then
					if weapons.player_list[pname][ammo] > 0 then -- Ensure there's a round in the chamber
						chambered = true
						chamber_bonus = 0.9
						weapons.player_list[pname].anim_mode = true
					end
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
		local ammo = weapon._ammo_type
		weapons.player_list[pname][ammo] = 0
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

		local pyaw = player:get_look_horizontal()
		local ppit = player:get_look_vertical()
		for i=1, weapon._pellets do
			-- Ray calculations.
			local raybegin = vector.add(player:get_pos(), {x=0, y=weapons.default_eye_height, z=0})
			local vec_x, vec_y, vec_z

			local fatigue_mult = 1 + (weapons.player_list[pname].fatigue / 100)
			
			-- Handle aiming
			local myaw, mpitch = 0, 0
			if weapons.player_list[pname].aim_mode then
				if weapon._offset_aim == nil then
					myaw = math.random(weapon._spread_aim*-100, weapon._spread_aim*100) / 100
					mpitch = math.random(weapon._spread_aim*-100, weapon._spread_aim*100) / 100
				else
					myaw = math.random(weapon._offset_aim.yaw_min*100, weapon._offset_aim.yaw_max*100) / 100
					mpitch = math.random(weapon._offset_aim.pitch_min*100, weapon._offset_aim.pitch_max*100) / 100
				end
			else
				if weapon._offset == nil then
					myaw = math.random(weapon._spread*-100, weapon._spread_aim*100) / 100
					mpitch = math.random(weapon._spread*-100, weapon._spread_aim*100) / 100
				else
					myaw = (math.random(weapon._offset.yaw_min*100, weapon._offset.yaw_max*100) / 100)
					mpitch = math.random(weapon._offset.pitch_min*100, weapon._offset.pitch_max*100) / 100
				end
			end

			local fyaw = pyaw + math.rad(myaw * fatigue_mult)
			local fpit = ppit + math.rad(mpitch * fatigue_mult)
			local new_look = solarsail.util.functions.look_vector(fyaw, fpit)

			local rayend = vector.add(raybegin,	vector.multiply(new_look, weapon._range))
			local ray = minetest.raycast(raybegin, rayend, true, false)
			local pointed = ray:next()
			pointed = ray:next()
			local target_pos

			if weapon._tracer == nil then
			else
				local tracer_pos = vector.add(raybegin, vector.multiply(new_look, 1))

				local tracer_vel = vector.multiply(vector.direction(raybegin, rayend), 120)
				local xz, y = solarsail.util.functions.get_3d_angles(raybegin, rayend)

				local ent = minetest.add_entity(tracer_pos, 
								"weapons:tracer_" .. weapon._tracer)


				ent:set_velocity(tracer_vel)
				local tracer_rot = vector.new(
					-fpit,
					fyaw,
					0
				)
				ent:set_rotation(tracer_rot)
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

				weapon.bullet_on_hit(pointed, player, weapon, target_pos, dist)
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
	local pname = player:get_player_name()
	if pointed.type == "object" then
		local t_pos = pointed.ref:get_pos()
		if t_pos == nil then return end
		weapons.handle_damage(weapon, player, pointed.ref, dist, pointed)
	else
		for _, players in ipairs(minetest.get_connected_players()) do
			if pname ~= players:get_player_name() then
				local ppos = players:get_pos()
				local splash_dist = solarsail.util.functions.pos_to_dist(ppos, pointed.intersection_point)
				if math.abs(splash_dist) < 0.61 then
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
			local recover_fatigue = false
			if weapons.is_reloading[pname][ammo] then
				recover_fatigue = true
			elseif not solarsail.controls.player[pname].LMB then
				recover_fatigue = true
			-- Special case for semi auto weapons where firing the weapon can be considered safe
			elseif solarsail.controls.player[pname].LMB and (weapon._fire_mode == "semi" and not solarsail.controls.player_last[pname].LMB) then
				recover_fatigue = true
			end
			if recover_fatigue then
				if weapons.player_list[pname].fatigue <= 0.01 then
					weapons.player_list[pname].fatigue = 0
				elseif weapons.player_list[pname].fatigue > 0.01 then
					weapons.player_list[pname].fatigue = weapons.player_list[pname].fatigue * weapon._fatigue_recovery
				end
			end
			player_fatigue_timer[pname] = 0
		end
	end
end)