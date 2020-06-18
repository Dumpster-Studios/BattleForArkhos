function weapons.register_weapon(name, def, def_alt, def_reload, texture, class_name)
	-- Red Team
	
	local node = table.copy(def)
	local node_alt = table.copy(def_alt)
	local node_reload = table.copy(def_reload)
	
	node.tiles = {texture, class_name .. "_red.png"}
	node._alt_mode = name .. "_alt_red"
	node._reload_node = name .. "_reload_red"
	node.node_placement_prediction = ""
	
	node_alt.tiles = {texture, class_name .. "_red.png"}
	node_alt._alt_mode = name .. "_red"
	node_alt._reload_node = name .. "_reload_red"
	node_alt.node_placement_prediction = ""
	
	node_reload.tiles = {texture, class_name .. "_red.png"}
	node_reload._reset_node = name .. "_red"
	node_reload.node_placement_prediction = ""

	minetest.register_node(name .. "_red", node)
	minetest.register_node(name .. "_alt_red", node_alt)
	minetest.register_node(name .. "_reload_red", node_reload)

	-- Blue Team

	node = table.copy(def)
	node_alt = table.copy(def_alt)
	node_reload = table.copy(def_reload)
	
	node.tiles = {texture, class_name .. "_blue.png"}
	node._alt_mode = name .. "_alt_blue"
	node._reload_node = name .. "_reload_blue"
	node.node_placement_prediction = ""

	node_alt.tiles = {texture, class_name .. "_blue.png"}
	node_alt._alt_mode = name .. "_blue"
	node_alt._reload_node = name .. "_reload_blue"
	node_alt.node_placement_prediction = ""

	node_reload.tiles = {texture, class_name .. "_blue.png"}
	node_reload._reset_node = name .. "_blue"
	node_alt.node_placement_prediction = ""
	
	minetest.register_node(name .. "_blue", node)
	minetest.register_node(name .. "_alt_blue", node_alt)
	minetest.register_node(name .. "_reload_blue", node_reload)
end

function weapons.raycast_bullet(player, weapon)
	local pname = player:get_player_name()

	-- Handle recoil of the equipped weapon
	solarsail.util.functions.apply_recoil(player, weapon)

	for i=1, weapon._pellets do
		-- Ray calculations.
		local raybegin = vector.add(player:get_pos(), {x=0, y=1.64, z=0})
		local raygunbegin = vector.add(player:get_pos(), {x=0, y=1.2, z=0})
		local raymod = vector.add(
			vector.multiply(player:get_look_dir(), weapon._range), 
			{
				x=math.random(weapon._spread_min, weapon._spread_max),
				y=math.random(weapon._spread_min, weapon._spread_max),
				z=math.random(weapon._spread_min, weapon._spread_max)
			}
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
				vector.add(player:get_pos(), vector.new(0, 1.64, 0)),
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
end

function weapons.bullet_on_hit(pointed, player, weapon, target_pos, dist)
	if pointed.type == "object" then
		local t_pos = pointed.ref:get_pos()
		if t_pos == nil then return end
		local diff = solarsail.util.functions.pos_to_dist(t_pos, target_pos)
		if diff < 0.31 then
			if pointed.ref:is_player() then
				weapons.handle_damage(weapon, player, pointed.ref, dist)
			end
		end
	else
		for _, players in ipairs(minetest.get_connected_players()) do
			if player:get_player_name() ~= players:get_player_name() then
				local ppos = players:get_pos()
				local splash_dist = solarsail.util.functions.pos_to_dist(ppos, pointed.intersection_point)
				if splash_dist < 0.61 then
					weapons.handle_damage(weapon, player, players, dist)
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
	local raybegin = vector.add(player:get_pos(), {x=0, y=1.64, z=0})
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
			weapons.handle_damage(weapon, player, pointed.ref, dist)
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
	local raybegin = vector.add(player:get_pos(), {x=0, y=1.64, z=0})
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
			weapons.handle_damage(weapon, player, pointed.ref, dist)
		end
	end
end

function weapons.place_block(player, weapon)
	-- Ray calculations.
	local raybegin = vector.add(player:get_pos(), {x=0, y=1.64, z=0})
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