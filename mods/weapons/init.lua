-- Weapons for Super CTF:
-- Author: Jordach
-- License: Reserved

weapons = {}
worldedit = {}
weapons.player = {}
weapons.player_list = {}

local player_timers = {}
local is_reloading = {}
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

local function spray_particles(pointed, nodedef, target_pos)
	local npos
	if pointed == nil then
		npos = table.copy(target_pos)
	else
		npos = table.copy(pointed.above)
	end
	if nodedef.tiles == nil then return end
	for i=8, math.random(12, 16) do
		minetest.add_particle({
			pos = npos,
			expirationtime = 2,
			collisiondetection = true,
			velocity = {x=math.random(-1, 1), y=0, z=math.random(-1, 1)},
			acceleration = {x=0, y=-5, z=0},
			texture = nodedef.tiles[1]
		})
	end
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
	local x = 0
	local z = 0
	local y = 0 
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
		local nodedef = minetest.registered_nodes[minetest.get_node(target_pos).name]

		if weapon._type == "gun" then
			minetest.sound_play("block_impact", {pos=target_pos, 
				max_hear_distance=8, gain=0.875}, true)
		end

		if nodedef == nil then
		elseif nodedef._takes_damage == nil then
		elseif not nodedef._takes_damage then
			return
		end

		if nodedef == nil then
		elseif nodedef._health == nil then
			minetest.set_node(target_pos, {name="air"})
			spray_particles(pointed, nodedef)
			if weapon._type == "tool_alt" then
				minetest.set_node({x=target_pos.x, y=target_pos.y-1, z=target_pos.z},
					{name="air"})
				spray_particles(nil, nodedef,
					{x=target_pos.x, y=target_pos.y-1, z=target_pos.z})
			end
			minetest.check_for_falling(target_pos)
			if weapon._type == "tool" then
				if weapons.player_list[player:get_player_name()].blocks <
					weapons.player_list[player:get_player_name()].blocks_max then
						weapons.player_list[player:get_player_name()].blocks =
							weapons.player_list[player:get_player_name()].blocks + 1
				end
			end
		else
			local nodedamage = nodedef._health - weapon._break_hits
			if nodedamage < 1 then
				minetest.set_node(target_pos, {name="air"})
				spray_particles(nil, nodedef, target_pos)
				if weapon._type == "tool_alt" then
					minetest.set_node({x=target_pos.x, y=target_pos.y-1, z=target_pos.z},
						{name="air"})
					spray_particles(nil, nodedef,
						{x=target_pos.x, y=target_pos.y-1, z=target_pos.z})
				end
				minetest.check_for_falling(target_pos)
				
				if weapon._type == "tool" then
					if weapons.player_list[player:get_player_name()].blocks < 
						weapons.player_list[player:get_player_name()].blocks_max then
							weapons.player_list[player:get_player_name()].blocks =
								weapons.player_list[player:get_player_name()].blocks + 1
					end
				end
			else
				minetest.set_node(target_pos, {name=nodedef._name.."_"..nodedamage})
				minetest.check_for_falling(target_pos)
				spray_particles(pointed, nodedef)
			end
		end
	end
end

local function shoot(player, weapon)
	local pname = player:get_player_name()
	-- Handle recoil;
	solarsail.util.functions.apply_recoil(player, weapon)
	
	if weapon._type == "rocket" then
		local rocket_pos = vector.add(
			vector.add(player:get_pos(), vector.new(0, 1.64, 0)), 
				vector.multiply(player:get_look_dir(), 1)
		)

		local rocket_vel = vector.add(
				vector.multiply(player:get_look_dir(), 45), vector.new(0, 0, 0)
			)
		local ent = minetest.add_entity(rocket_pos, "weapons:rocket_ent")

		local luaent = ent:get_luaentity()
		luaent._player_ref = player

		luaent._loop_sound_ref = 
				minetest.sound_play({name="rocket_fly"}, 
					{object=ent, max_hear_distance=32, gain=1.2, loop=true})
		-- Commit audio suicide when attached audio stops working:tm:
		minetest.after(15, minetest.sound_stop, luaent._loop_sound_ref)
		local look_vertical = player:get_look_vertical()
		local look_horizontal = player:get_look_horizontal()
		for i=1, 3 do
			minetest.add_particlespawner({
				attached = ent,
				amount = 30,
				time = 0,
				texture = "rocket_smoke_" .. i .. ".png",
				collisiondetection = true,
				collision_removal = false,
				object_collision = false,
				vertical = false,
				minpos = vector.new(-0.15,-0.15,-0.15),
				maxpos = vector.new(0.15,0.15,0.15),
				minvel = vector.new(-1, 0.1, 1),
				maxvel = vector.new(1, 0.75, 1),
				minacc = vector.new(0,0,0),
				maxacc = vector.new(0,0,0),
				minsize = 7,
				maxsize = 12,
				minexptime = 2,
				maxexptime = 6
			})
		end
		minetest.add_particlespawner({
			attached = ent,
			amount = 15,
			time = 0,
			texture = "rocket_fire.png",
			collisiondetection = true,
			collision_removal = false,
			vertical = false,
			minpos = vector.new(0,0,0),
			maxpos = vector.new(0,0,0),
			minvel = vector.new(0,0,0),
			maxvel = vector.new(0,0,0),
			minacc = vector.new(0,0,0),
			maxacc = vector.new(0,0,0),
			minsize = 4.5,
			maxsize = 9,
			minexptime = 0.1,
			maxexptime = 0.3,
			glow = 14
		})
		ent:set_velocity(rocket_vel)
		ent:set_rotation(vector.new(-look_vertical, look_horizontal, 0))
		return
	end
	
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
		
		if weapon._type == nil then
		elseif weapon._type == "gun" then
			local yp = solarsail.util.functions.y_direction(player:get_look_vertical(), 20)
			local px, pz = solarsail.util.functions.yaw_to_vec(player:get_look_horizontal(), 20, false)
			local pv = vector.add(raybegin, {x=px, y=yp, z=pz})
			local pr = vector.add(pv, raymod)


			-- Replace with entity
			minetest.add_particle({
				pos = vector.add(raygunbegin, vector.multiply(player:get_look_dir(), 1)),
				velocity = vector.add(vector.multiply(vector.direction(pv, pr), 90), vector.new(0, 0.44, 0)),
				expirationtime = 10,
				collisiondetection = true,
				collision_removal = true,
				texture = "tracer.png",
				size = 2,
				glow = 12
			})
		end

		if pointed == nil then
			if weapon._type == "block" then
				weapons.player_list[pname].blocks =
					weapons.player_list[pname].blocks + 1
			end
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

			if weapon._type == "tool" then
				minetest.after(dist/weapon._speed, wait, pointed, player,
					weapon, target_pos, dist)
			elseif weapon._type == "tool_alt" or weapon._type == "flag" then
				minetest.after(dist/weapon._speed, wait, pointed, player,
					weapon, target_pos, dist)
			elseif dist > 1 then -- Prevent damage close to you
				if weapon._type == "gun" then
					minetest.after(dist/weapon._speed, wait, pointed, player,
						weapon, target_pos, dist)
				elseif pointed.type ~= "object" then
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
	end

end

minetest.register_on_joinplayer(function(player)
	player_timers[player:get_player_name()] = {}
	player_timers[player:get_player_name()].fire = 0
	player_timers[player:get_player_name()].reload = 0
	is_reloading[player:get_player_name()] = false
	player_fov[player:get_player_name()] = 120
	player:hud_set_flags({
		hotbar = true,
		healthbar = false,
		crosshair = false,
		wielditem = true,
		breathbar = false,
		minimap = false,
		minimap_radar = false
	})
	player_huds[player:get_player_name()] = {}
	player_huds[player:get_player_name()].crosshair = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[player:get_player_name()].hp_1 = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.425, y=0.75},
		offset = {x=-100, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[player:get_player_name()].hp_2 = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.425, y=0.75},
		offset = {x=-50, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[player:get_player_name()].hp_3 = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.425, y=0.75},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[player:get_player_name()].ammo_1 = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.575, y=0.75},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[player:get_player_name()].ammo_2 = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.575, y=0.75},
		offset = {x=50, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[player:get_player_name()].ammo_s = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.575, y=0.75},
		offset = {x=100, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[player:get_player_name()].ammo_m1 = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.575, y=0.75},
		offset = {x=150, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
	player_huds[player:get_player_name()].ammo_m2 = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.575, y=0.75},
		offset = {x=200, y=0},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[player:get_player_name()].reloading = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.6},
		scale = {x=1, y=1},
		text = "transparent.png"
	})

	player_huds[player:get_player_name()].hitmarker = player:hud_add({
		hud_elem_type = "image",
		position = {x=0.5, y=0.5},
		scale = {x=1, y=1},
		text = "transparent.png"
	})
end)

function weapons.player.cancel_reload(player)
	local pname = player:get_player_name()
	is_reloading[pname] = false
	player:hud_change(player_huds[pname].reloading,
		"text", "transparent.png")
end

local function finish_reload(player, weapon, new_wep)
	local pname = player:get_player_name()

	if is_reloading[pname] then
		is_reloading[player:get_player_name()] = false
		if weapons.player_list[player:get_player_name()] == nil then
			return
		end
		weapons.player_list[player:get_player_name()].primary =
			weapons.player_list[player:get_player_name()].primary_max
		local p_inv = player:get_inventory()
		p_inv:set_stack("main", 1, ItemStack(new_wep._reset_node.." 1"))
		player:hud_change(player_huds[player:get_player_name()].reloading,
			"text", "transparent.png")
	end
end

local function reload_controls()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()

		if solarsail.controls.player[player:get_player_name()] == nil then
		elseif solarsail.controls.player[player:get_player_name()].sneak then
			if solarsail.controls.player[player:get_player_name()].RMB then
				local wield = player:get_wielded_item():get_name()
				local weapon = minetest.registered_nodes[wield]
				if weapon == nil then
				elseif weapon._type == "gun" then
					if not is_reloading[player:get_player_name()] then
						if weapons.player_list[pname].primary ~=
								weapons.player_list[pname].primary_max then
							minetest.after(weapon._reload, finish_reload, player, weapon,
								minetest.registered_nodes[weapon._reload_node])
							is_reloading[player:get_player_name()] = true
							minetest.sound_play({name=weapon._reload_sound},
								{object=player, max_hear_distance=8, gain=0.15})
							local p_inv = player:get_inventory()
							p_inv:set_stack("main", 1, ItemStack(weapon._reload_node.." 1"))
							player:hud_change(player_huds[player:get_player_name()].reloading, 
								"text", "reloading.png")
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
		elseif player_timers[player:get_player_name()].fire > 60 / weapon._rpm  then
			if solarsail.controls.player[player:get_player_name()].LMB then
				player_timers[player:get_player_name()].fire = 0
				if weapon._type == "gun" or weapon._type == "rocket" then
					if weapons.player_list[player:get_player_name()].primary > 0 then
						if not is_reloading[player:get_player_name()] then
							shoot(player, weapon)
							minetest.sound_play({name=weapon._firing_sound}, 
								{pos=player:get_pos(), max_hear_distance=128, gain=1.75})
							weapons.player_list[player:get_player_name()].primary = 
								weapons.player_list[player:get_player_name()].primary - 1
							if weapons.player_list[player:get_player_name()].primary == 0 then
								is_reloading[player:get_player_name()] = true
								local p_inv = player:get_inventory()
								player:hud_change(player_huds[player:get_player_name()].reloading, 
									"text", "reloading.png")
								minetest.sound_play({name=weapon._reload_sound},
									{object=player, max_hear_distance=8, gain=0.15})
								p_inv:set_stack("main", 1, ItemStack(weapon._reload_node.." 1"))
								minetest.after(weapon._reload, finish_reload, player, weapon,
									minetest.registered_nodes[weapon._reload_node])
							end
						end
					end
				elseif weapon._type == "block" then
					if weapons.player_list[player:get_player_name()].blocks > 0 then
						shoot(player, weapon)
						weapons.player_list[player:get_player_name()].blocks = 
							weapons.player_list[player:get_player_name()].blocks - 1
					end
				elseif weapon._type == "tool" then
					shoot(player, weapon)
				elseif weapon._type == "tool_alt" then
					shoot(player, weapon)
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
				weapon = minetest.registered_items[wield]
				if weapon == nil then
					weapon = minetest.registered_tools[wield]
					if weapon == nil then
						weapon = minetest.registered_craftitems[wield]
					end
				end
			end
			
			if weapon == nil then
			elseif weapon._type == nil then
			elseif weapon._type == "gun" then
				if weapons.player_list[player:get_player_name()].primary > 9 then
					local a1 = tostring(weapons.player_list[player:get_player_name()].primary):sub(1,1)
					local a2 = tostring(weapons.player_list[player:get_player_name()].primary):sub(2,2)

					if a1 ~= weapons.player_list[pname].a1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_1, "text",
							a1..".png")
						weapons.player_list[pname].a1 = a1
					end

					if a2 ~= weapons.player_list[pname].a2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_2, "text",
							a2..".png")
						weapons.player_list[pname].a2 = a2
					end
				else
					local a1 = "0"
					local a2 = tostring(weapons.player_list[player:get_player_name()].primary):sub(1,1)
					
					if a1 ~= weapons.player_list[pname].a1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_1, "text", "0.png")
						weapons.player_list[pname].a1 = "0"
					end

					if a2 ~= weapons.player_list[pname].a2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_2, "text",
							a2..".png")
						weapons.player_list[pname].a2 = a2
					end
				end
				if weapons.player_list[player:get_player_name()].primary_max > 9 then
					local m1 = tostring(weapons.player_list[player:get_player_name()].primary_max):sub(1,1)
					local m2 = tostring(weapons.player_list[player:get_player_name()].primary_max):sub(2,2)

					if m1 ~= weapons.player_list[pname].m1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_m1, "text",
							m1..".png")
						weapons.player_list[pname].m1 = m1
					end

					if m2 ~= weapons.player_list[pname].m2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_m2, "text",
							m2..".png")
						weapons.player_list[pname].m2 = m2
					end
				else
					local m1 = "0"
					local m2 = tostring(weapons.player_list[player:get_player_name()].primary_max):sub(1,1)
					
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
			elseif weapon._type == "block" then
				if weapons.player_list[player:get_player_name()].blocks > 9 then
					local a1 = tostring(weapons.player_list[player:get_player_name()].blocks):sub(1,1)
					local a2 = tostring(weapons.player_list[player:get_player_name()].blocks):sub(2,2)

					if a1 ~= weapons.player_list[pname].a1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_1, "text",
							a1..".png")
						weapons.player_list[pname].a1 = a1
					end

					if a2 ~= weapons.player_list[pname].a2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_2, "text",
							a2..".png")
						weapons.player_list[pname].a2 = a2
					end
				else
					local m1 = "0"
					local m2 = tostring(weapons.player_list[player:get_player_name()].blocks):sub(1,1)

					if m1 ~= weapons.player_list[pname].m1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_1, "text", "0.png")
						weapons.player_list[pname].m1 = m1
					end

					if m2 ~= weapons.player_list[pname].m2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_2, "text",
							m2..".png")
						weapons.player_list[pname].m2 = m2
					end
				end

				if weapons.player_list[player:get_player_name()].blocks_max > 9 then
					local m1 = tostring(weapons.player_list[player:get_player_name()].blocks_max):sub(1,1)
					local m2 = tostring(weapons.player_list[player:get_player_name()].blocks_max):sub(2,2)

					if m1 ~= weapons.player_list[pname].m1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_m1, "text",
							m1..".png")
						weapons.player_list[pname].m1 = m1
					end

					if m2 ~= weapons.player_list[pname].m2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_m2, "text",
							m2..".png")
						weapons.player_list[pname].m2 = m2
					end
				else
					local m1 = "0"
					local m2 = tostring(weapons.player_list[player:get_player_name()].blocks_max):sub(1,1)

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
			elseif weapon._type == "tool" then
				if weapons.player_list[player:get_player_name()].blocks > 9 then
					local a1 = tostring(weapons.player_list[player:get_player_name()].blocks):sub(1,1)
					local a2 = tostring(weapons.player_list[player:get_player_name()].blocks):sub(2,2)

					if a1 ~= weapons.player_list[pname].a1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_1, "text",
							a1..".png")
						weapons.player_list[pname].a1 = a1
					end

					if a2 ~= weapons.player_list[pname].a2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_2, "text",
							a2..".png")
						weapons.player_list[pname].a2 = a2
					end
				else
					local m1 = "0"
					local m2 = tostring(weapons.player_list[player:get_player_name()].blocks):sub(1,1)

					if m1 ~= weapons.player_list[pname].m1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_1, "text", "0.png")
						weapons.player_list[pname].m1 = m1
					end

					if m2 ~= weapons.player_list[pname].m2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_2, "text",
							m2..".png")
						weapons.player_list[pname].m2 = m2
					end
				end

				if weapons.player_list[player:get_player_name()].blocks_max > 9 then
					local m1 = tostring(weapons.player_list[player:get_player_name()].blocks_max):sub(1,1)
					local m2 = tostring(weapons.player_list[player:get_player_name()].blocks_max):sub(2,2)

					if m1 ~= weapons.player_list[pname].m1 then
						player:hud_change(player_huds[player:get_player_name()].ammo_m1, "text",
							m1..".png")
						weapons.player_list[pname].m1 = m1
					end

					if m2 ~= weapons.player_list[pname].m2 then
						player:hud_change(player_huds[player:get_player_name()].ammo_m2, "text",
							m2..".png")
						weapons.player_list[pname].m2 = m2
					end
				else
					local m1 = "0"
					local m2 = tostring(weapons.player_list[player:get_player_name()].blocks_max):sub(1,1)

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
				player:hud_change(player_huds[player:get_player_name()].ammo_1, "text", "transparent.png")
				player:hud_change(player_huds[player:get_player_name()].ammo_m1, "text", "transparent.png")
				player:hud_change(player_huds[player:get_player_name()].ammo_2, "text", "transparent.png")
				player:hud_change(player_huds[player:get_player_name()].ammo_m2, "text", "transparent.png")
				player:hud_change(player_huds[player:get_player_name()].ammo_s, "text", "transparent.png")
			end
			
			if weapon == nil then
				if weapons.player_list[pname].cross ~= "transparent" then
					weapons.player_list[pname].cross = "transparent"
					player:hud_change(player_huds[player:get_player_name()].crosshair, "text", "transparent.png")
				end
			elseif weapon._crosshair == nil then
				if weapons.player_list[pname].cross ~= "transparent" then
					weapons.player_list[pname].cross = "transparent"
					player:hud_change(player_huds[player:get_player_name()].crosshair, "text", "transparent.png")
				end
			else
				if weapons.player_list[pname].cross ~= weapon._crosshair then
					player:hud_change(player_huds[player:get_player_name()].crosshair,
						"text", weapon._crosshair)
					weapons.player_list[pname].cross = weapon._crosshair
				end
			end
		end
	end
	minetest.after(0.01, render_hud)
end

local function alternate_mode()
	for _, player in ipairs(minetest.get_connected_players()) do
		if solarsail.controls.player[player:get_player_name()] == nil then
		elseif solarsail.controls.player[player:get_player_name()].RMB then
			if not solarsail.controls.player[player:get_player_name()].sneak then
				local wield = player:get_wielded_item():get_name()
				local weapon = minetest.registered_nodes[wield]
				if weapon == nil then
				elseif weapon._alt_mode == nil then
				else
					print(wield, weapon._alt_mode)
					player:set_wielded_item(ItemStack(weapon._alt_mode .. " 1"))
				end
			end
		end
	end
	minetest.after(0.15, alternate_mode)
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
		local wield = player:get_wielded_item()
		local weapon = minetest.registered_nodes[wield]
		local pname = player:get_player_name()
		
		if weapons.player_list[pname].class == nil then
		elseif weapon == nil then
			player:set_physics_override(
				weapons[weapons.player_list[pname].class].physics
			)
		elseif weapon._phys_alt == nil then
			player:set_physics_override(
				weapons[weapons.player_list[pname].class].physics
			)
		elseif weapon._phys_alt == 1 then
			player:set_physics_override(
				weapons[weapons.player_list[pname].class].physics
			)
		else
			local new_phys = table.copy(weapons[weapons.player_list[pname].class].physics)
			new_phys.speed = new_phys.speed * weapon._phys_alt
			new_phys.jump = new_phys.jump * weapon._phys_alt
			new_phys.sneak_glitch = false
			new_phys.sneak = false
			player:set_physics_override(
				weapons[weapons.player_list[pname].class].physics
			)
		end
	end
	minetest.after(0.03, handle_alt_physics)
end
--minetest.after(1, handle_alt_physics)

function core.spawn_item(pos, item)
	return
end

-- We now have access to other functions defined here:

dofile(minetest.get_modpath("weapons").."/worldedit.lua")
dofile(minetest.get_modpath("weapons").."/skybox.lua")
dofile(minetest.get_modpath("weapons").."/blocks.lua")
dofile(minetest.get_modpath("weapons").."/weapons.lua")
dofile(minetest.get_modpath("weapons").."/player.lua")
dofile(minetest.get_modpath("weapons").."/game.lua")
dofile(minetest.get_modpath("weapons").."/mapgen.lua")
dofile(minetest.get_modpath("weapons").."/rocketry.lua")

minetest.register_on_player_receive_fields(function(player, 
	formname, fields)
	if formname == "class_select" then
		if fields.lefty then
			local pname = player:get_player_name()
			player:set_eye_offset({x=0,y=0,z=0}, {x=-15,y=-1,z=20})
			minetest.chat_send_player(pname, "Third person camera and crosshair set to over the left shoulder.")
			minetest.after(0.1, minetest.show_formspec,
				player:get_player_name(), "class_select",
				weapons.class_formspec)
		elseif fields.righty then
			local pname = player:get_player_name()
			player:set_eye_offset({x=0,y=0,z=0}, {x=15,y=-1,z=20})
			minetest.chat_send_player(pname, "Third person camera and crosshair set to over the right shoulder.")
			minetest.after(0.1, minetest.show_formspec,
				player:get_player_name(), "class_select",
				weapons.class_formspec)
		end
	end
end)