-- Weapons for Super CTF:
-- Author: Jordach
-- License: Reserved

weapons = {}
worldedit = {}
weapons.player = {}
weapons.player_list = {}
weapons.is_reloading = {}

local player_timers = {}
local player_huds = {}
local player_fov = {}

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
	local result_x, result_z = 
			solarsail.util.functions.yaw_to_vec(yaw_rad, weapon._recoil, true)
	local result_y = 
			solarsail.util.functions.y_direction(pitch_rad, weapon._recoil)
	local pitch_mult = solarsail.util.functions.xz_amount(pitch_rad)
	player:add_player_velocity({
		x=result_x * pitch_mult, 
		y=result_y, 
		z=result_z * pitch_mult
	})
end

function solarsail.util.functions.apply_explosion_recoil(player, multiplier, origin)
	local ppos = player:get_pos()
	ppos.y = ppos.y + 0.5
	local result_vel = vector.multiply(vector.direction(origin, ppos), multiplier)
	player:add_player_velocity(result_vel)
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
		local nodedamage = nodedef._health - weapon._break_hits
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
		node_tile = 0,
		node = minetest.get_node(npos_floor).name,
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
		minsize = 1,
		maxsize = 1,
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
		" commited die ", " died ", " commited suicide ", " couldn't stand living "
	}

	local verb, form
	local figs = 10^(2)

	if tname == pname then
		verb = math.random(1, #suicide_verbs)
		form = death_formspec ..
		"label[2,2;You" .. suicide_verbs[verb] .. "with the " .. weapon._kf_name
		minetest.chat_send_all(pname .. suicide_verbs[verb] .. "with the " ..
			weapon._kf_name .. ".")
	else
		verb = math.random(1, #kill_verbs)
		form = death_formspec ..
		"label[2,2;You " .. kill_verbs[verb] .. "by: "..pname.."]"
		minetest.chat_send_all(pname .. kill_verbs[verb] .. tname .. " with the " .. weapon._kf_name
		.. ", (" .. (math.floor(dist * figs + 0.5) / 100) .. "m)")
	end

	minetest.show_formspec(tname, "death", form)
end

function weapons.reset_health(player)
	local pname = player:get_player_name()
	weapons.player_list[pname].hp = weapons.player_list[pname].hp_max
	minetest.close_formspec(pname, "death")
	weapons.update_health(player)
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
	player:set_properties({
		eye_height = 1.64
	})
	if respawn then
		weapons.set_ammo(player, weapons.player_list[pname].class)
		weapons.clear_inv(player)
		weapons.add_class_items(player, weapons.player_list[pname].class)
	end
end

function weapons.kill_player(player, target_player, weapon, dist)
	local tname = target_player:get_player_name()
	local pname = player:get_player_name()
	weapons.update_killfeed(player, target_player, weapon, dist)
	target_player:set_properties({
		eye_height = 0.35
	})
	weapons.player.cancel_reload(target_player)
	minetest.after(4.9, weapons.respawn_player, target_player, true)
	minetest.after(5, weapons.reset_health, target_player)
end



function weapons.update_health(target_player)
	local pname = target_player:get_player_name()
	if weapons.player_list[pname].hp < 10 then
		target_player:hud_change(player_huds[pname].hp_1, "text", "0.png")
		target_player:hud_change(player_huds[pname].hp_2, "text", "0.png")
		target_player:hud_change(player_huds[pname].hp_3, "text",
			tostring(weapons.player_list[pname].hp):sub(1,1) .. ".png")
	elseif weapons.player_list[pname].hp < 100 then
		target_player:hud_change(player_huds[pname].hp_1, "text", "0.png")
		target_player:hud_change(player_huds[pname].hp_2, "text", 
			tostring(weapons.player_list[pname].hp):sub(1,1) .. ".png")
		target_player:hud_change(player_huds[pname].hp_3, "text",
			tostring(weapons.player_list[pname].hp):sub(2,2) .. ".png")
	elseif weapons.player_list[pname].hp > 99 then
		target_player:hud_change(player_huds[pname].hp_1, "text",
			tostring(weapons.player_list[pname].hp):sub(1,1) .. ".png")
		target_player:hud_change(player_huds[pname].hp_2, "text", 
			tostring(weapons.player_list[pname].hp):sub(2,2) .. ".png")
		target_player:hud_change(player_huds[pname].hp_3, "text",
			tostring(weapons.player_list[pname].hp):sub(3,3) .. ".png")
	end
end

local function hide_hitmarker(player)
	player:hud_change(player_huds[player:get_player_name()].hitmarker, "text",
		"transparent.png")
end

local function render_hitmarker(player)
	player:hud_change(player_huds[player:get_player_name()].hitmarker, "text",
		"hitmarker.png")
	minetest.after(0.45, hide_hitmarker, player)
end

function weapons.handle_damage(weapon, player, target_player, dist)
	local pname = player:get_player_name()
	local tname = target_player:get_player_name()
	if weapons.player_list[tname].hp == nil then return end
	local new_hp = weapons.player_list[tname].hp - weapon._damage
	
	if weapons.player_list[tname].hp < 1 then
		return
	end

	if weapon._heals == nil then
	elseif weapon._heals > 0 then
		if weapons.player_list[pname].team ==
				weapons.player_list[tname].team then
			if weapons.player_list[tname].hp < 
				weapons.player_list[tname].hp_max then
					new_hp = weapons.player_list[tname].hp + weapon._heals
			else
				new_hp = weapons.player_list[tname].hp_max
			end
		end
	end

	if weapons.player_list[pname].team ~=
			weapons.player_list[tname].team then
		if new_hp < 1 then
			weapons.player_list[tname].hp = 0
			weapons.kill_player(player, target_player, weapon, dist)
			render_hitmarker(player)
			minetest.sound_play("hitsound", {to_player=pname})
			minetest.sound_play("player_impact", {pos=target_player:get_pos(),
				max_hear_distance=6, gain=0.85})
		else
			weapons.player_list[tname].hp = new_hp
			render_hitmarker(player)
			minetest.sound_play("hitsound", {to_player=pname})	
			minetest.sound_play("player_impact", {pos=target_player:get_pos(),
				max_hear_distance=6, gain=0.98})
		end
	elseif pname == tname then
		if new_hp < 1 then
			weapons.player_list[tname].hp = 0
			weapons.kill_player(player, player, weapon, dist)
		else
			weapons.player_list[tname].hp = new_hp
		end
	else
		if weapon._heals == nil then return 
		elseif weapon._heals > 0 then
			weapons.player_list[tname].hp = new_hp
			render_hitmarker(player)
			minetest.sound_play("hitsound", {to_player=pname})
			minetest.sound_play("player_heal", {pos=target_player:get_pos(),
				max_hear_distance=6, gain=0.98})
		end
	end
	weapons.update_health(target_player)
end

local function wait(pointed, player, weapon, target_pos, dist)
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

		if weapon._type == "gun" then
			minetest.sound_play("block_impact", {pos=target_pos, 
				max_hear_distance=8, gain=0.875}, true)
		end

		if nodedef == nil then
		elseif nodedef._takes_damage == nil then
			local damage, node = weapons.calc_block_damage(nodedef, weapon, target_pos, pointed)
			minetest.set_node(target_pos, {name=node})
			if damage < 1 then
				if weapon._type == "tool" then
					if weapons.player_list[player:get_player_name()].blocks <
					weapons.player_list[player:get_player_name()].blocks_max then
						weapons.player_list[player:get_player_name()].blocks =
						weapons.player_list[player:get_player_name()].blocks + 1
					end
					
				end
				if weapon._type == "tool_alt" then
					minetest.set_node({x=target_pos.x, y=target_pos.y-1, z=target_pos.z},
					{name="air"})
					weapons.spray_particles(nil, nodedef,
						{x=target_pos.x, y=target_pos.y-1, z=target_pos.z})
				end
			end
			minetest.check_for_falling(target_pos)
		else
			weapons.spray_particles(pointed, nodedef)
		end
	end
end

local health_pos = {x=0.325, y=0.825}
local ammo_pos = {x=0.675, y=0.825}
local player_phys = {}
local player_key_timer = {}

local function set_keys(pname)
	player_key_timer[pname] = 0
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

	player_huds[pname] = {}
	player_key_timer[pname] = 0

	player_huds[pname].visual_1 = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=-100, y=-100},
		text = "hud_vignette.png",
		offset = {x=0, y=-1}
	})

	player_huds[pname].visual_2 = player:hud_add({
		hud_elem_type = "image",
		position = health_pos,
		scale = {x=1, y=1},
		text = "hud_overlay_left.png",
	})

	player_huds[pname].visual_3 = player:hud_add({
		hud_elem_type = "image",
		position = ammo_pos,
		scale = {x=1, y=1},
		text = "hud_overlay_right.png"
	})

	player_huds[pname].crosshair = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[pname].ammo_bg = player:hud_add({
		hud_elem_type = "image",
		position = ammo_pos,
		offset = {x=65, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[pname].hp_bg = player:hud_add({
		hud_elem_type = "image",
		position = health_pos,
		offset = {x=0, y=12},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[pname].hp_1 = player:hud_add({
		hud_elem_type = "image",
		position = health_pos,
		offset = {x=-50, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[pname].hp_2 = player:hud_add({
		hud_elem_type = "image",
		position = health_pos,
		offset = {x=0, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[pname].hp_3 = player:hud_add({
		hud_elem_type = "image",
		position = health_pos,
		offset = {x=50, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[pname].ammo_1 = player:hud_add({
		hud_elem_type = "image",
		position = ammo_pos,
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[pname].ammo_2 = player:hud_add({
		hud_elem_type = "image",
		position = ammo_pos,
		offset = {x=50, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[pname].ammo_s = player:hud_add({
		hud_elem_type = "image",
		position = ammo_pos,
		offset = {x=100, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[pname].ammo_m1 = player:hud_add({
		hud_elem_type = "image",
		position = ammo_pos,
		offset = {x=150, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[pname].ammo_m2 = player:hud_add({
		hud_elem_type = "image",
		position = ammo_pos,
		offset = {x=200, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[pname].reloading = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.6},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[pname].hitmarker = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
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
			player:hud_change(player_huds[pname].reloading,
				"text", "transparent.png")
		end
	end
end

local function finish_reload(player, weapon, new_wep, slot, wieldname)
	local pname = player:get_player_name()
	if weapons.is_reloading[pname][wieldname] then
		weapons.is_reloading[pname][wieldname] = false
		if weapons.player_list[pname] == nil then
			return
		end

		local ammo = new_wep._ammo_type
		weapons.player_list[pname][ammo] =
			weapons.player_list[pname][ammo.."_max"]
		
		local p_inv = player:get_inventory()
		p_inv:set_stack("main", slot, ItemStack(new_wep._reset_node.." 1"))

		-- Avoid sending HUD updates unless needed
		if weapon._no_reload_hud then
		else
			player:hud_change(player_huds[pname].reloading,
				"text", "transparent.png")
		end
	end
end

local function reload_controls()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()

		if solarsail.controls.player[pname] == nil then
		elseif solarsail.controls.player[pname].aux1 then
			local wield = player:get_wielded_item():get_name()
			local weapon = minetest.registered_nodes[wield]
			if weapon == nil then
			elseif weapon._mag ~= nil then
				local ammo = weapon._ammo_type
				if weapons.player_list[pname][ammo] < weapons.player_list[pname][ammo.."_max"] then
					if weapons.player_list[pname][ammo] > 0 then
						weapons.player_list[pname][ammo] = 0
						if not weapons.is_reloading[pname][wield] then
							weapons.is_reloading[pname][wield] = true
							local p_inv = player:get_inventory()
							local p_ind = player:get_wield_index()
							local rel_node = minetest.registered_nodes[weapon._reload_node]
							minetest.after(weapon._reload, finish_reload, player, weapon,
								rel_node, p_ind, wield)
							minetest.sound_play({name=weapon._reload_sound},
								{object=player, max_hear_distance=8, gain=0.15})
							if weapon._no_reload_hud then
							else
								player:hud_change(player_huds[player:get_player_name()].reloading, 
									"text", "reloading.png")
							end
							p_inv:set_stack("main", p_ind, ItemStack(weapon._reload_node.." 1"))
						end
					end
				end
			end
		end
	end
	minetest.after(0.03, reload_controls)
end
minetest.after(2, reload_controls)

local function weapon_controls()
	for _, player in ipairs(minetest.get_connected_players()) do
		player_timers[player:get_player_name()].fire =
			player_timers[player:get_player_name()].fire + 0.03
		-- Get player's wieled weapon:
		local wield = player:get_wielded_item():get_name()
		local weapon = minetest.registered_nodes[wield]
		local pname = player:get_player_name()

		if weapon == nil then
		elseif weapon._name == nil then
		elseif weapon._rpm == nil then
		elseif player_timers[pname].fire > 60 / weapon._rpm  then
			if solarsail.controls.player[pname].LMB then
				player_timers[pname].fire = 0
				if weapon._mag ~= nil then
					local ammo = weapon._ammo_type
					if weapons.player_list[pname][ammo] > 0 then
						if not weapons.is_reloading[pname][wield] then
							weapon.on_fire(player, weapon)
							minetest.sound_play({name=weapon._firing_sound}, 
								{pos=player:get_pos(), max_hear_distance=128, gain=1.75})
							weapons.player_list[player:get_player_name()][ammo] = 
								weapons.player_list[player:get_player_name()][ammo] - 1
							if weapons.player_list[player:get_player_name()][ammo] == 0 then
								weapons.is_reloading[pname][wield] = true
								local p_inv = player:get_inventory()
								local p_ind = player:get_wield_index()
								if weapon._no_reload_hud then
								else
									player:hud_change(player_huds[player:get_player_name()].reloading, 
										"text", "reloading.png")
								end
								minetest.sound_play({name=weapon._reload_sound},
									{object=player, max_hear_distance=8, gain=0.15})
								minetest.after(weapon._reload, finish_reload, player, weapon,
									minetest.registered_nodes[weapon._reload_node], p_ind, wield)
								p_inv:set_stack("main", p_ind, ItemStack(weapon._reload_node.." 1"))
							end
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
	minetest.after(0.03, weapon_controls)
end
minetest.after(1, weapon_controls)

local function render_hud()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if weapons.player_list[pname].class ~= nil then
			local wield = player:get_wielded_item():get_name()
			local weapon = minetest.registered_nodes[wield]
			
			if weapon == nil then
			elseif weapon._type == nil then
			elseif weapon._ammo_type ~= nil then
				local ammo = weapon._ammo_type
				if weapons.player_list[pname][ammo] > 9 then
					local a1 = tostring(weapons.player_list[pname][ammo]):sub(1,1)
					local a2 = tostring(weapons.player_list[pname][ammo]):sub(2,2)
					-- Prevent resending of HUD packets causing client desyncronisation
					if a1 ~= weapons.player_list[pname].a1 then
						player:hud_change(player_huds[pname].ammo_1, "text",
							a1..".png")
						weapons.player_list[pname].a1 = a1
					end
					if a2 ~= weapons.player_list[pname].a2 then
						player:hud_change(player_huds[pname].ammo_2, "text",
							a2..".png")
						weapons.player_list[pname].a2 = a2
					end
				else
					local a1 = "0"
					local a2 = tostring(weapons.player_list[pname][ammo]):sub(1,1)
					
					-- Prevent resending of HUD packets
					if a1 ~= weapons.player_list[pname].a1 then
						player:hud_change(player_huds[pname].ammo_1, "text", "0.png")
						weapons.player_list[pname].a1 = "0"
					end
					if a2 ~= weapons.player_list[pname].a2 then
						player:hud_change(player_huds[pname].ammo_2, "text",
							a2..".png")
						weapons.player_list[pname].a2 = a2
					end
				end

				if weapons.player_list[pname][ammo.."_max"] > 9 then
					local m1 = tostring(weapons.player_list[pname][ammo.."_max"]):sub(1,1)
					local m2 = tostring(weapons.player_list[pname][ammo.."_max"]):sub(2,2)

					-- Prevent resending of HUD packets
					if m1 ~= weapons.player_list[pname].m1 then
						player:hud_change(player_huds[pname].ammo_m1, "text",
							m1..".png")
						weapons.player_list[pname].m1 = m1
					end
					if m2 ~= weapons.player_list[pname].m2 then
						player:hud_change(player_huds[pname].ammo_m2, "text",
							m2..".png")
						weapons.player_list[pname].m2 = m2
					end
				else
					local m1 = "0"
					local m2 = tostring(weapons.player_list[pname][ammo.."_max"]):sub(1,1)
					
					if m1 ~= weapons.player_list[pname].m1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_m1, "text", "0.png")
						weapons.player_list[pname].m1 = "0"
					end

					if m2 ~= weapons.player_list[pname].m2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_m2, "text",
							m2..".png")
						weapons.player_list[pname].m2 = m2
					end
				end

				if not weapons.player_list[pname].slash then
					player:hud_change(player_huds[player:get_player_name()].ammo_s, "text", "slash.png")
					weapons.player_list[pname].slash = true
				end
			else
				weapons.player_list[pname].a1 = "nil"
				weapons.player_list[pname].a2 = "nil"
				weapons.player_list[pname].m1 = "nil"
				weapons.player_list[pname].m2 = "nil"
				weapons.player_list[pname].slash = false
				player:hud_change(player_huds[pname].ammo_1, "text", "transparent.png")
				player:hud_change(player_huds[pname].ammo_m1, "text", "transparent.png")
				player:hud_change(player_huds[pname].ammo_2, "text", "transparent.png")
				player:hud_change(player_huds[pname].ammo_m2, "text", "transparent.png")
				player:hud_change(player_huds[pname].ammo_s, "text", "transparent.png")
			end
			
			if weapon == nil then
				if weapons.player_list[pname].cross ~= "transparent" then
					weapons.player_list[pname].cross = "transparent"
					player:hud_change(player_huds[pname].crosshair, "text", "transparent.png")
				end
			elseif weapon._crosshair == nil then
				if weapons.player_list[pname].cross ~= "transparent" then
					weapons.player_list[pname].cross = "transparent"
					player:hud_change(player_huds[pname].crosshair, "text", "transparent.png")
				end
			else
				if weapons.player_list[pname].cross ~= weapon._crosshair then
					player:hud_change(player_huds[pname].crosshair,
						"text", weapon._crosshair)
					weapons.player_list[pname].cross = weapon._crosshair
				end
			end

			if weapon == nil then
				if weapons.player_list[pname].ammo_bg ~= "transparent" then
					player:hud_change(player_huds[pname].ammo_bg, "text", "transparent.png")
					weapons.player_list[pname].ammo_bg = "transparent"
				end
			elseif weapon._ammo_bg == nil then
				if weapons.player_list[pname].ammo_bg ~= "transparent" then
					player:hud_change(player_huds[pname].ammo_bg, "text", "transparent.png")
					weapons.player_list[pname].ammo_bg = "transparent"
				end
			else
				if weapons.player_list[pname].ammo_bg ~= weapon._ammo_bg then
					player:hud_change(player_huds[pname].ammo_bg, "text", weapon._ammo_bg .. ".png^[opacity:200")
					weapons.player_list[pname].ammo_bg = weapon._ammo_bg
				end
			end
		end
	end
	minetest.after(0.01, render_hud)
end

local function alternate_mode()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local wield = player:get_wielded_item():get_name()
		local weapon = minetest.registered_nodes[wield]

		player_key_timer[pname] =
			player_key_timer[pname] + 0.03

		if solarsail.controls.player[pname] == nil then
		elseif weapon == nil then
		elseif weapon._type == nil then
		elseif weapon._alt_mode == nil then
		-- Handle tools with the reload key as they lack reloads
		elseif solarsail.controls.player[pname].aux1 then
			if player_key_timer[pname] > 0.25 then
				if weapon._type ~= "gun" then
					player_key_timer[pname] = 0
					player:set_wielded_item(ItemStack(weapon._alt_mode .. " 1"))
				end
			end
		-- Handle aiming down sights:
		elseif weapon._type == "gun" then
			if solarsail.controls.player[pname].RMB then
				if weapon._is_alt then
				else
					player:set_wielded_item(ItemStack(weapon._alt_mode .. " 1"))
				end
				elseif not solarsail.controls.player[pname].RMB then
				if weapon._is_alt then
					player:set_wielded_item(ItemStack(weapon._alt_mode .. " 1"))
				else
				end
			end
		end
	end
	minetest.after(0.03, alternate_mode)
end
minetest.after(2, alternate_mode)
minetest.after(2, render_hud)

local function handle_fov()
	for _, player in ipairs(minetest.get_connected_players()) do
		local wield = player:get_wielded_item():get_name()
		local weapon = minetest.registered_nodes[wield]
		if weapon == nil then
		elseif weapon._fov_mult == nil then
			player:set_fov(0, false, 0.2)
			player_fov[player:get_player_name()] = 0
		elseif player_fov[player:get_player_name()] ~= weapon._fov_mult then
			if weapon._fov_mult == 0 then
				player:set_fov(0, false, 0.2)
				player_fov[player:get_player_name()] = 0
			else
				player:set_fov(weapon._fov_mult, true, 0.2)
				player_fov[player:get_player_name()] = weapon._fov_mult
			end
		end
	end
	minetest.after(0.03, handle_fov)
end
minetest.after(1, handle_fov)

local function handle_alt_physics()
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
	minetest.after(0.03, handle_alt_physics)
end
handle_alt_physics()

function core.spawn_item(pos, item)
	return
end

-- We now have access to other functions defined here:
dofile(minetest.get_modpath("weapons").."/skybox.lua")
dofile(minetest.get_modpath("weapons").."/builtin_blocks.lua")
dofile(minetest.get_modpath("weapons").."/weapons.lua")
dofile(minetest.get_modpath("weapons").."/player.lua")
dofile(minetest.get_modpath("weapons").."/game.lua")
dofile(minetest.get_modpath("weapons").."/mapgen.lua")
dofile(minetest.get_modpath("weapons").."/tracers.lua")

-- External weapons
dofile(minetest.get_modpath("weapons").."/weapons/assault_rifle.lua")
dofile(minetest.get_modpath("weapons").."/weapons/railgun.lua")
dofile(minetest.get_modpath("weapons").."/weapons/smg.lua")
dofile(minetest.get_modpath("weapons").."/weapons/shotgun.lua")
dofile(minetest.get_modpath("weapons").."/weapons/tools.lua")
dofile(minetest.get_modpath("weapons").."/weapons/blocks.lua")
dofile(minetest.get_modpath("weapons").."/weapons/rocketry.lua")
dofile(minetest.get_modpath("weapons").."/weapons/grenades.lua")


minetest.register_on_player_receive_fields(
			function(player, formname, fields)
	if formname == "class_select" then
		local pname = player:get_player_name()
		if fields.lefty then
			player:set_eye_offset({x=0,y=0,z=0}, {x=-15,y=-1,z=20})
			minetest.chat_send_player(pname, "Third person camera and crosshair set to over the left shoulder.")
			minetest.after(0.1, minetest.show_formspec,
				player:get_player_name(), "class_select",
				weapons.class_formspec)
		elseif fields.righty then
			player:set_eye_offset({x=0,y=0,z=0}, {x=15,y=-1,z=20})
			minetest.chat_send_player(pname, "Third person camera and crosshair set to over the right shoulder.")
			minetest.after(0.1, minetest.show_formspec,
				player:get_player_name(), "class_select",
				weapons.class_formspec)
		end
		if weapons.player_list[pname].hp_bg == nil then
			player:hud_change(player_huds[pname].hp_bg, "text", "health_bg.png^[opacity:200")
			weapons.player_list[pname].hp_bg = true
		end
	end
end)