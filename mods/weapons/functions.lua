-- Dumpster Studios, Battle for Arkhos
-- Author Jordach
-- License Reserved

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

--[[
	solarsail.util.function.normalize_pos()
		
	pos_a = vector.new(); considered the zero point
	pos_b = vector.new(); considered the space around the zero point
	returns pos_b localised by pos_a.
]]

function solarsail.util.functions.get_local_pos(pos_a, pos_b)
	local pa = table.copy(pos_a)
	local pb = table.copy(pos_b)
	local res = vector.new(
		pb.x - pa.x,
		pb.y - pa.y,
		pb.z - pa.z
	)
	return res
end

--[[
	solarsail.util.functions.convert_from_hex()

	input = ColorSpec
	returns three variables red, green and blue in base 10 values.
]]--

function solarsail.util.functions.convert_from_hex(input)
	local r, g, b = input:match("^#(%x%x)(%x%x)(%x%x)")
	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

--[[
	solarsail.util.functions.lerp()

	var_a = input number to blend from. (at ratio 0)
	var_b = input number to blend to. (at ratio 1)
	returns the blended value depending on ratio.
]]--

function solarsail.util.functions.lerp(var_a, var_b, ratio)
	return (1-ratio)*var_a + (ratio*var_b)
end

--[[
	solarsail.util.functions.remap()
	
	val = Input value
	min_val = minimum value of your expected range
	max_val = maximum value of your expected range
	min_map = minimum value of your remapped range
	max_map = maximum value of your remapped range
	returns a value between min_map and max_map based on where val is relative to min_val and max_val.
]]

function solarsail.util.functions.remap(val, min_val, max_val, min_map, max_map)
	return (val-min_val)/(max_val-min_val) * (max_map-min_map) + min_map
end

--[[
	solarsail.util.functions.blend_colours()

	val = Input Value
	min_val = Minimum value (values less than this are capped)
	max_val = Maximum value (values more than this are capped)
	min_col = ColorSpec defining the colour of the minimum value.
	returns a ColorSpec blended or capped as one of the two input colours.
]]--

function solarsail.util.functions.blend_colours(val, min_val, max_val, min_col, max_col)
	if val <= min_val then
		return min_col
	elseif val >= max_val then
		return max_col
	end

	local min_r, min_g, min_b = solarsail.util.functions.convert_from_hex(min_col)
	local max_r, max_g, max_b = solarsail.util.functions.convert_from_hex(max_col)
	
	local blend = solarsail.util.functions.remap(val, min_val, max_val, 0, 1)
	local res_r = solarsail.util.functions.lerp(min_r, max_r, blend)
	local res_g = solarsail.util.functions.lerp(min_g, max_g, blend)
	local res_b = solarsail.util.functions.lerp(min_b, max_b, blend)
	return minetest.rgba(res_r, res_g, res_b)
end

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
	
	if not weapons.disable_visual_recoil then
		-- Camera recoil; cannot be canceled out
		local vert_deg, hori_deg, look_pitch, look_hori = 0, 0, 0, 0
		vert_deg = (math.random(weapon._recoil_vert_min * 100, weapon._recoil_vert_max * 100) / 100) * weapons.master_recoil_mult
		hori_deg = (math.random(-weapon._recoil_hori * 100, weapon._recoil_hori * 100) / 100) * weapons.master_recoil_mult
		
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
		return 0, "air", nil
	elseif nodedef.name == "air" then
		return 0, "air", nil
	elseif nodedef.name == "ignore" then
		return 0, "air", nil
	elseif nodedef._health == nil then
		weapons.spray_particles(pointed, nodedef, target_pos, true)
		return 0, "air", nil
	elseif nodedef._takes_damage == nil then
		local nodedamage
		if weapon._block_chance == nil then
			nodedamage = nodedef._health - weapon._break_hits
		elseif math.random(1, 100) < weapon._block_chance then
			nodedamage = nodedef._health - weapon._break_hits
		else
			nodedamage = nodedef._health
		end

		if nodedamage < 1 then
			weapons.spray_particles(pointed, nodedef, target_pos, true)
			return 0, "air", nil
		else
			weapons.spray_particles(pointed, nodedef, target_pos, false)
			return nodedamage, nodedef._name.."_"..nodedamage, nil
		end
	else
		weapons.spray_particles(pointed, nodedef, target_pos, false)
		return 0, nodedef.name, false
	end
end

function weapons.create_2x2_node_texture(texture_string)
	local xmod = math.random(-14, 0)
	local ymod = math.random(-14, 0)
	local splits = string.split(texture_string, "^")
	local modifier = "[combine:2x2:"
	for k, v in pairs(splits) do
		if k ~= #splits then
			modifier = modifier ..xmod..","..ymod.."="..v..":"
		else
			modifier = modifier ..xmod..","..ymod.."="..v
		end
	end
	return modifier
end

function weapons.reset_health(player)
	local pname = player:get_player_name()
	weapons.player_list[pname].hp = weapons.player_list[pname].hp_max
	weapons.hud.update_vignette(player)
	minetest.close_formspec(pname, "death")
end

function weapons.respawn_player(player, respawn)
	local pname = player:get_player_name()
	local x, y, z = 0, 0, 0
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
	weapons.hud.remove_blackout(player)
end

function weapons.kill_player(player, target_player, weapon, dist, headshot)
	weapons.update_killfeed(player, target_player, weapon, dist, headshot)
	weapons.player_list[target_player:get_player_name()].hp = 0
	weapons.player.cancel_reload(target_player)
	weapons.hud.blackout(target_player)
	weapons.creator.creator_to_class(player, player:get_player_name())
	minetest.after(4.9, weapons.respawn_player, target_player, true)
	minetest.after(5, weapons.reset_health, target_player)
end