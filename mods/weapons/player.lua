-- Weapons for Super CTF:
-- Author: Jordach
-- License: Reserved

local assault = {}
assault.stats = {
	hp = 200,
	blocks = 50,
}
assault.items = {
	"weapons:assault_rifle",
	"weapons:rocket_launcher",
	"weapons:pickaxe",
	"core:team_neutral",
}
assault.physics = {
	speed = 1.15,
	jump = 1,
	gravity = 1,
	sneak = true,
	sneak_glitch = true,
	new_move = false
}

local marksman = {}
marksman.stats = {
	hp = 125,
	blocks = 75,
}
marksman.items = {
	"weapons:railgun",
	--"weapons:pistol",
	"weapons:pickaxe",
	"core:team_neutral",
}
marksman.physics = {
	speed = 0.95,
	jump = 1.5,
	gravity = 1,
	sneak = true,
	sneak_glitch = true,
	new_move = false
}

local medic = {}
medic.stats = {
	hp = 125,
	blocks = 35,
}
medic.items = {
	"weapons:smg",
	"weapons:pickaxe",
	--"weapons:injector",
	--"weapons:resurrector",
	"core:team_neutral",
}
medic.physics = {
	speed = 1.4,
	jump = 1.25,
	gravity = 1,
	sneak = true,
	sneak_glitch = true,
	new_move = false
}
local scout = {}
scout.stats = {
	hp = 75,
	blocks = 25,
}
scout.items = {
	"weapons:shotgun",
	"weapons:frag_grenade",
	"weapons:pickaxe",
	"core:team_neutral",
}
scout.physics = {
	speed = 1.55,
	jump = 2,
	gravity = 1,
	sneak = true,
	sneak_glitch = true,
	new_move = false
}

local red_flag = {
	items = {
		"weapons:flag_red"
	}
}

local blue_flag = {
	items = {
		"weapons:flag_blue"
	}
}

weapons.assault = assault
weapons.marksman = marksman
weapons.medic = medic
weapons.scout = scout
weapons.red_flag = red_flag
weapons.blue_flag = blue_flag

weapons.class_formspec =
	"size[8,8]"..
	"button[0,7;2,1;assault;Assault]"..
	"button[2,7;2,1;marksman;Marksman]"..
	"button[4,7;2,1;medic;Medic]"..
	"button[6,7;2,1;scout;Scout]"..
	"button[0,0;4,1;lefty;Left Shoulder View]"..
	"button[4,0;4,1;righty;Right Shoulder View]"

local function clear_inv(player)
	local p_inv = player:get_inventory()
	p_inv:set_list("main", {})
	p_inv:set_list("craft", {})
end

weapons.clear_inv = clear_inv

local function add_class_items(player, class)
	local p_inv = player:get_inventory()
	local pname = player:get_player_name()
	for k, stack in pairs(weapons[class].items) do
		local istack = ItemStack(stack .. " 1")
		local node = minetest.registered_nodes[stack .. "_" ..
			weapons.player_list[pname].team]
		if node == nil then
		elseif node._type == nil then
		else
			istack = ItemStack(stack .. "_" .. 
				weapons.player_list[pname].team ..
				" 1")
		end
		p_inv:add_item("main", istack)
		-- Hacky bullshit part 69
		-- This doesn't cancel reloading at all, it just for some reason doesn't
		-- properly *apply* it.
		weapons.is_reloading[pname][stack .."_"..weapons.player_list[pname].team] = false
	end
	player:hud_set_hotbar_itemcount(#weapons[class].items)
end

weapons.add_class_items = add_class_items

local function set_player_physics(player, class)
	if class == "assault" then
		player:set_physics_override(assault.physics)
	elseif class == "marksman" then
		player:set_physics_override(marksman.physics)
	elseif class == "medic" then
		player:set_physics_override(medic.physics)
	elseif class == "scout" then
		player:set_physics_override(scout.physics)
	end
end

local function set_ammo(player, class)
	local pname = player:get_player_name()
	for _, stack in pairs(weapons[class].items) do
		-- Big hax btw, teams can have differing magazine sizes
		local weapon = minetest.registered_nodes[stack .. "_" ..
			weapons.player_list[pname].team]

		-- Avoid invalid weapons being checked against
		if weapon == nil then
		-- Also avoid invalid ammo types
		elseif weapon._ammo_type == nil then
		else
			-- Allow certain magazine sizes to be class defined:
			if weapon._mag == nil then
			else
				weapons.player_list[pname][weapon._ammo_type] =
					weapon._mag
				weapons.player_list[pname][weapon._ammo_type .. "_max"] =
					weapon._mag
			end
		end
	end
	weapons.player_list[pname].blocks = weapons[class].stats.blocks
	weapons.player_list[pname].blocks_max = weapons[class].stats.blocks
end

weapons.set_ammo = set_ammo

local function set_health(player, class)
	weapons.player_list[player:get_player_name()].hp = weapons[class].stats.hp
	weapons.player_list[player:get_player_name()].hp_max = weapons[class].stats.hp
end

weapons.set_health = set_health

local function set_skin(player, class)
	if class == "assault" then
		if weapons.player_list[player:get_player_name()].team == "red" then
			player:set_properties({
				visual = "mesh",
				mesh = "player_assault.x",
				textures = {
					"assault_rifle.png",
					"pickaxe.png",
					"assault_class_red.png",
				},
				visual_size = {x=1.05, y=1.05},
				nametag = ""
			})		
		elseif weapons.player_list[player:get_player_name()].team == "blue" then
			player:set_properties({
				visual = "mesh",
				mesh = "player_assault.x",
				textures = {
					"assault_rifle.png",
					"pickaxe.png",
					"assault_class_blue.png",
				},
				visual_size = {x=1.05, y=1.05},
				nametag = ""
			})	
		end
	elseif class == "marksman" then
		if weapons.player_list[player:get_player_name()].team == "red" then
			player:set_properties({
				visual = "mesh",
				mesh = "player_assault.x",
				textures = {
					"assault_rifle.png",
					"pickaxe.png",
					"assault_class_red.png",
				},
				visual_size = {x=1.05, y=1.05},
				nametag = ""
			})		
		elseif weapons.player_list[player:get_player_name()].team == "blue" then
			player:set_properties({
				visual = "mesh",
				mesh = "player_assault.x",
				textures = {
					"assault_rifle.png",
					"pickaxe.png",
					"assault_class_blue.png",
				},
				visual_size = {x=1.05, y=1.05},
				nametag = ""
			})	
		end
	elseif class == "medic" then
		if weapons.player_list[player:get_player_name()].team == "red" then
			player:set_properties({
				visual = "mesh",
				mesh = "player_assault.x",
				textures = {
					"assault_rifle.png",
					"pickaxe.png",
					"assault_class_red.png",
				},
				visual_size = {x=1.05, y=1.05},
				nametag = ""
			})		
		elseif weapons.player_list[player:get_player_name()].team == "blue" then
			player:set_properties({
				visual = "mesh",
				mesh = "player_assault.x",
				textures = {
					"assault_rifle.png",
					"pickaxe.png",
					"assault_class_blue.png",
				},
				visual_size = {x=1.05, y=1.05},
				nametag = ""
			})	
		end
	elseif class == "scout" then
		if weapons.player_list[player:get_player_name()].team == "red" then
			player:set_properties({
				visual = "mesh",
				mesh = "player_assault.x",
				textures = {
					"assault_rifle.png",
					"pickaxe.png",
					"assault_class_red.png",
				},
				visual_size = {x=1.05, y=1.05},
				nametag = ""
			})		
		elseif weapons.player_list[player:get_player_name()].team == "blue" then
			player:set_properties({
				visual = "mesh",
				mesh = "player_assault.x",
				textures = {
					"assault_rifle.png",
					"pickaxe.png",
					"assault_class_blue.png",
				},
				visual_size = {x=1.05, y=1.05},
				nametag = ""
			})	
		end
	end
	player:set_animation({x=0, y=159}, 60, 0.1, true)
end

weapons.force_anim_group = {}
weapons.force_anim_set = {}

local anim_lock = {}
local anim_frame = {}
local anim_press = {}
local look_pitch = {}
local last_anim = {}

minetest.register_on_joinplayer(function(player)
	-- Clear old invs first:
	clear_inv(player)
	local pname = player:get_player_name()
	weapons.player_list[pname] = {}
	minetest.show_formspec(pname, "class_select", weapons.class_formspec)
	weapons.assign_team(player, nil)
	player:set_nametag_attributes({
		color = "#00000000"
	})

	local red = 207-35
	local red2 = 207-42
	local y = weapons.red_base_y
	player:hud_add({
		hud_elem_type = "waypoint",
		name = "Red Base",
		text = "m",
		number = weapons.teams.red_colour,
		world_pos = {x=red, y=y, z=red}
	})

	local blu = 147-4
	local blu2 = 192-42
	y = weapons.blu_base_y
	player:hud_add({
		hud_elem_type = "waypoint",
		name = "Blue Base",
		text = "m",
		number = weapons.teams.blue_colour,
		world_pos = {x=-blu, y=y, z=-blu}
	})	
	weapons.respawn_player(player, false)
	weapons.update_blue_flag = true
	weapons.update_red_flag = true
	player:set_eye_offset({x=0,y=0,z=0}, {x=15,y=-1,z=20})
	player:set_properties({
		textures = {"transparent.png", "transparent.png"},
		collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3}
	})
	anim_lock[pname] = false
	anim_frame[pname] = -1
	anim_press[pname] = "none"
	look_pitch[pname] = -1000
	last_anim[pname] = {x=-1, y=-1}
end)

function weapons.player.set_class(player, class)
	-- Clear inv:
	clear_inv(player)
	set_player_physics(player, class)
	set_health(player, class)
	weapons.player_list[player:get_player_name()].class = class
	set_skin(player, class)
	set_ammo(player, class)
	add_class_items(player, class)
	weapons.update_health(player)
end

minetest.register_chatcommand("class", {
	description = "Choose a class.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
		local pos2
		if weapons.player_list[player:get_player_name()].team == "red" then
			pos2 = {x=207-35, y=weapons.red_base_y, z=207-35}
		else
			pos2 = {x=-143, y=weapons.blu_base_y, z=-143}
		end
		
		--if result < 5.5 then
			minetest.show_formspec(name, "class_select", weapons.class_formspec)
		--else
			--minetest.chat_send_player(name, "You can only change class at your team's base!")
		--end
	end,
})

minetest.register_chatcommand("respawn", {
	description = "Respawn back to base if stuck.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		weapons.respawn_player(player, false)
	end,
})

minetest.register_on_player_receive_fields(function(player, 
		formname, fields)
	local pname = player:get_player_name()
	if formname == "class_select" then
		local pos = player:get_pos()
		local pos2
		if weapons.player_list[pname].team == "red" then
			pos2 = {x=207-35, y=weapons.red_base_y, z=207-35}
		else
			pos2 = {x=-143, y=weapons.blu_base_y, z=-143}
		end
		local result = solarsail.util.functions.pos_to_dist(pos, pos2)
		local dist = 6
		if fields.assault then
			if result < dist then
				weapons.player.set_class(player, "assault")
				weapons.player.cancel_reload(player)
			elseif weapons.player_list[player:get_player_name()].class == nil then
				weapons.player.set_class(player, "assault")
				weapons.player.cancel_reload(player)
			else
				minetest.chat_send_player(pname, 
					"You can only change class at your team's base!")
			end
		elseif fields.marksman then
			if result < dist then
				weapons.player.set_class(player, "marksman")
				weapons.player.cancel_reload(player)
			elseif weapons.player_list[player:get_player_name()].class == nil then
				weapons.player.set_class(player, "marksman")
				weapons.player.cancel_reload(player)
			else
				minetest.chat_send_player(pname, 
					"You can only change class at your team's base!")
			end
		elseif fields.medic then
			if result < dist then
				weapons.player.set_class(player, "medic")
				weapons.player.cancel_reload(player)
			elseif weapons.player_list[player:get_player_name()].class == nil then
				weapons.player.set_class(player, "medic")
				weapons.player.cancel_reload(player)
			else
				minetest.chat_send_player(pname, 
					"You can only change class at your team's base!")
			end
		elseif fields.scout then
			if result < dist then
				weapons.player.set_class(player, "scout")
				weapons.player.cancel_reload(player)
			elseif weapons.player_list[player:get_player_name()].class == nil then
				weapons.player.set_class(player, "scout")
				weapons.player.cancel_reload(player)
			else
				minetest.chat_send_player(pname, 
					"You can only change class at your team's base!")
			end
		elseif fields.quit then
			minetest.after(0.1, minetest.show_formspec,
				player:get_player_name(), "class_select",
				weapons.class_formspec)
			return
		end
		player:set_bone_position("Armature_Legs", {x=0, y=6, z=0}, {x=180, y=0, z=0})
		player:set_bone_position("Armature_Root", {x = 0, y = 4.5, z = 0}, {x = 0, y = 0, z = 0})
		minetest.close_formspec(player:get_player_name(), "class_select")
	end
end)

local function unlock_anim(pname)
	anim_lock[pname] = false
	anim_frame[pname] = -1
	anim_press[pname] = "none"
end

local animation_table = {}

animation_table.gun = {}
animation_table.gun.idle = {x=0, y=159}
animation_table.gun.up = {x=170, y=249}
animation_table.gun.left = {x=260, y=339}
animation_table.gun.right = {x=350, y=430}
animation_table.gun.down = {x=440, y=519}

animation_table.pickaxe = {}
animation_table.pickaxe.idle = {x=530, y=689}
animation_table.pickaxe.up = {x=700, y=779}
animation_table.pickaxe.left = {x=790, y=869}
animation_table.pickaxe.right = {x=880, y=959}
animation_table.pickaxe.down = {x=970, y=1049}

animation_table.pickaxe_swing = {}
animation_table.pickaxe_swing.idle = {x=1060, y=1219}
animation_table.pickaxe_swing.up = {x=1230, y=1309}
animation_table.pickaxe_swing.left = {x=1320, y=1399}
animation_table.pickaxe_swing.right = {x=1410, y=1489}
animation_table.pickaxe_swing.down = {x=1500, y=1579}

animation_table.pickaxe_alt = {}
animation_table.pickaxe_alt_swing = {}
animation_table.block = {}
animation_table.block_place = {}

minetest.register_globalstep(function(dtime)
	--print("server step: " .. dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local wield = player:get_wielded_item():get_name()
		local weapon = minetest.registered_nodes[wield]
		local ppitch = -math.deg(player:get_look_vertical())
		local frame_offset = 0
		local anim_group, anim_set

		if look_pitch[pname] ~= ppitch then
			player:set_bone_position("Armature_Upper_Body", {x = 0, y = 4, z = 0}, {x = ppitch * 0.6, y = 0, z = 0})
			player:set_bone_position("Armature_Head", {x = 0, y = 3, z = 0}, {x = ppitch * 0.25, y = 0, z = 0})
			look_pitch[pname] = ppitch
		end

		if anim_frame[pname] ~= -1 then
			anim_frame[pname] = anim_frame[pname] + dtime
			frame_offset = math.floor(anim_frame[pname] * 60)
		end
		if solarsail.controls.player[pname] == nil then
		elseif solarsail.controls.player[pname].left then
			if solarsail.controls.player[pname].up then
				anim_group = "left"
			else
				anim_group = "right"
			end
		elseif solarsail.controls.player[pname].right then
			if solarsail.controls.player[pname].up then
				anim_group = "right"
			else
				anim_group = "left"
			end
		elseif solarsail.controls.player[pname].up then
			anim_group = "up"
		elseif solarsail.controls.player[pname].down then
			anim_group = "down"
		else
			anim_group = "idle"
		end

		if weapon == nil then
		elseif weapon._type == nil then
		elseif weapon._type == "gun" or weapon._type == "rocket" then
			anim_set = "gun"
		elseif weapon._type == "tool" then
			if solarsail.controls.player[pname].LMB or anim_lock[pname] then
				anim_set = "pickaxe_swing"
				if not anim_lock[pname] then
					anim_lock[pname] = true
					anim_frame[pname] = 0
					minetest.after(1.33, unlock_anim, pname)
				end
			else
				anim_set = "pickaxe"
			end
		elseif weapon._type == "tool_alt" then
		elseif weapon._type == "block" then
		elseif weapon._type == "flag" then
		end

		-- Only do animations when we have a valid animation 
		if anim_set == nil then
		elseif anim_group == nil then
		else
			-- Avoid aliasing the original animation table and screwing it up for everyone.
			local result_frames = table.copy(animation_table[anim_set][anim_group])

			-- Only increment the animation start frames when we have an uncancelable animation
			if frame_offset ~= 0 then
				result_frames.x = result_frames.x + frame_offset
			end

			-- Prevent re-sending packets to clients with the exact frames again.
			if last_anim[pname].x ~= result_frames.x then
				player:set_animation(result_frames, 60, 0.1, true)
				-- Once again, avoid aliasing and getting a potentially GC'd frame range
				last_anim[pname] = table.copy(result_frames)
			end
		end
	end
end)