-- Weapons for Super CTF:
-- Author: Jordach
-- License: Reserved

-- Create a class configuration:
weapons.creator = {}
weapons.creator.base_points = 50

weapons.creator.hp_cost = 5
weapons.creator.hp_base = 100
weapons.creator.hp_gain = 15

weapons.creator.speed_cost = 10
weapons.creator.speed_base = 1
weapons.creator.speed_gain = 0.2

weapons.creator.jump_cost = 10
weapons.creator.jump_base = 1
weapons.creator.jump_gain = 0.2

weapons.creator.blocks_cost = 1
weapons.creator.blocks_base = 20
weapons.creator.blocks_gain = 5

local base_class = {}
base_class.stats = {
	hp = weapons.creator.hp_base,
	blocks = weapons.creator.blocks_base
}

base_class.physics = {
	speed = weapons.creator.speed_base,
	jump = weapons.creator.jump_base,
	-- Legacy
	sneak = true,
	sneak_glitch = true,
	new_move = false
}


base_class.items = {}

-- base_class.items = {
-- 	"weapons:assault_rifle",
-- 	"weapons:burst_rifle",
-- 	"weapons:sniper_rifle",
-- 	"weapons:veteran_rifle",
-- 	"weapons:pump_shotgun",
-- 	"weapons:light_machine_gun",
-- 	"weapons:plasma_autorifle",
-- 	"weapons:minigun",
-- 	"weapons:pickaxe",
-- 	"core:team_neutral",
-- 	"weapons:fists",
-- 	"weapons:boring_pistol"
-- }

local always_given_items = {
	"weapons:pickaxe",
	"core:team_neutral",
	"weapons:fists"
}

---------------------------------
---------------------------------
-- Create a class testing zone --
---------------------------------
---------------------------------

local create_a_class =
	"formspec_version[4]"..
	"size[24,12]"..
	"image[12,0.5;0.01,9;creator_divider.png]"..
	"button[11,10;2,0.5;respawn;Respawn]"..
	"button[11,11;2,0.5;refresh;Refresh]"..
	"label[0.5,11.5;Note: Exiting this menu will save changes and take effect on next respawn.]"

weapons.creator.weapons = {}
weapons.creator.weapons.primary = {}
weapons.creator.weapons.secondary = {}
weapons.creator.weapons.grenades = {}

-- use this for unsuccessful actions
function weapons.creator.play_error_sound(player, pname)

end

-- use this for successful actions
function weapons.creator.play_ui_beep(player, pname)

end

function weapons.creator.register_weapon(localisation, slot)
	weapons.creator.weapons[slot][#weapons.creator.weapons[slot]+1] = localisation
end

function weapons.creator.generate_weapons_list(player)
	local pname = player:get_player_name()
	local pri_list, pri_tooltip, sec_list, sec_tooltip, gre_list, gre_tooltip = "", "", "", "", "", ""
	local pri_index, sec_index, gre_index = 1,1,1

	-- Construct primary weapons dropdown and tooltip:
	for index, localisation in pairs(weapons.creator.weapons.primary) do
		if index ~= #weapons.creator.weapons.primary then
			pri_list = pri_list .. localisation.name .. ","
		else
			pri_list = pri_list .. localisation.name .. ";"
		end
		
		if index == weapons.player_list[pname].creator.weapon_pri then
			pri_tooltip = "tooltip[0.5,0.5;4,1;"..localisation.tooltip.."]"
			pri_index = index
		end
	end

	-- Invalidate weapons that used to exist but no longer exist in updates,
	-- ideally this should never happen but just in case classes are remembered between restarts
	if #weapons.creator.weapons.primary < weapons.player_list[pname].creator.weapon_pri then
		pri_tooltip = "tooltip[0.5,0.5;4,1;"..weapons.creator.weapons.primary[1].tooltip.."]"
		print("[WARNING]: Weapon index is invalid. Potentially a missing weapon?")
	end

	for index, localisation in pairs(weapons.creator.weapons.secondary) do
		if index ~= #weapons.creator.weapons.secondary then
			sec_list = sec_list .. localisation.name .. ","
		else
			sec_list = sec_list .. localisation.name .. ";"
		end

		if index == weapons.player_list[pname].creator.weapon_sec then
			sec_tooltip = "tooltip[0.5,3;4,1;"..localisation.tooltip.."]"
			sec_index = index
		end
	end

	-- Invalidate weapons that used to exist but no longer exist in updates,
	-- ideally this should never happen but just in case classes are remembered between restarts
	if #weapons.creator.weapons.secondary < weapons.player_list[pname].creator.weapon_sec then
		sec_tooltip = "tooltip[0.5,3;5,1;"..weapons.creator.weapons.secondary[1].tooltip.."]"
		print("[WARNING]: Weapon index is invalid. Potentially a missing weapon?")
	end

	local dropdown_pri = "dropdown[0.5,0.5;4;weapon_pri;"..pri_list..pri_index..";true]"
	local dropdown_sec = "dropdown[0.5,3.5;4;weapon_sec;"..sec_list..sec_index..";true]"

	return dropdown_pri..pri_tooltip..dropdown_sec..sec_tooltip
end

function weapons.creator.form_to_creator(fields, player, pname)
	if fields == nil then
	elseif fields.weapon_pri ~= nil then
		weapons.player_list[pname].creator.weapon_pri = tonumber(fields.weapon_pri)
	end

	if fields == nil then
	elseif fields.weapon_sec ~= nil then
		weapons.player_list[pname].creator.weapon_sec = tonumber(fields.weapon_sec)
	end

	if fields == nil then
	elseif fields.dec_hp == "-" then
		if weapons.player_list[pname].creator.hp <= weapons.creator.hp_base then
		else
			weapons.player_list[pname].creator.hp = weapons.player_list[pname].creator.hp - weapons.creator.hp_gain
			weapons.player_list[pname].creator.points = weapons.player_list[pname].creator.points + weapons.creator.hp_cost
		end
	elseif fields.inc_hp == "+" then
		if weapons.player_list[pname].creator.points >= weapons.creator.hp_cost then
			weapons.player_list[pname].creator.hp = weapons.player_list[pname].creator.hp + weapons.creator.hp_gain
			weapons.player_list[pname].creator.points = weapons.player_list[pname].creator.points - weapons.creator.hp_cost
		end
	end

	if fields == nil then
	elseif fields.dec_blk == "-" then
		if weapons.player_list[pname].creator.blocks <= weapons.creator.blocks_base then
		else
			weapons.player_list[pname].creator.blocks = weapons.player_list[pname].creator.blocks - weapons.creator.blocks_gain
			weapons.player_list[pname].creator.points = weapons.player_list[pname].creator.points + weapons.creator.blocks_cost
		end
	elseif fields.inc_blk == "+" then
		if weapons.player_list[pname].creator.points >= weapons.creator.blocks_cost then
			weapons.player_list[pname].creator.blocks = weapons.player_list[pname].creator.blocks + weapons.creator.blocks_gain
			weapons.player_list[pname].creator.points = weapons.player_list[pname].creator.points - weapons.creator.blocks_cost
		end
	end

	if fields == nil then
	elseif fields.dec_spd == "-" then
		if weapons.player_list[pname].creator.speed <= weapons.creator.speed_base then
		else
			weapons.player_list[pname].creator.speed = weapons.player_list[pname].creator.speed - weapons.creator.speed_gain
			weapons.player_list[pname].creator.points = weapons.player_list[pname].creator.points + weapons.creator.speed_cost
		end
	elseif fields.inc_spd == "+" then
		if weapons.player_list[pname].creator.points >= weapons.creator.speed_cost then
			weapons.player_list[pname].creator.speed = weapons.player_list[pname].creator.speed + weapons.creator.speed_gain
			weapons.player_list[pname].creator.points = weapons.player_list[pname].creator.points - weapons.creator.speed_cost
		end
	end

	if fields == nil then
	elseif fields.dec_jump == "-" then
		if weapons.player_list[pname].creator.jump <= weapons.creator.jump_base then
		else
			weapons.player_list[pname].creator.jump = weapons.player_list[pname].creator.jump - weapons.creator.jump_gain
			weapons.player_list[pname].creator.points = weapons.player_list[pname].creator.points + weapons.creator.jump_cost
		end
	elseif fields.inc_jump == "+" then
		if weapons.player_list[pname].creator.points >= weapons.creator.jump_cost then
			weapons.player_list[pname].creator.jump = weapons.player_list[pname].creator.jump + weapons.creator.jump_gain
			weapons.player_list[pname].creator.points = weapons.player_list[pname].creator.points - weapons.creator.jump_cost
		end
	end
end

function weapons.creator.creator_to_class(player, pname)
	local wep_pri, wep_sec = weapons.creator.weapons.primary[weapons.player_list[pname].creator.weapon_pri].itemstring, weapons.creator.weapons.secondary[weapons.player_list[pname].creator.weapon_sec].itemstring
	local items = {}
	items[1] = wep_pri
	items[2] = wep_sec

	for k, item in pairs(always_given_items) do
		items[#items+1] = item
	end

	weapons.player.set_class(player, items)
end

function weapons.creator.player_preview(player, pname)
	local player_texture = minetest.formspec_escape(weapons.get_player_texture(player))
	local arms_mat = player_texture .. ",rubber.png,steel_dark.png,steel_grey.png,sight_green.png"
	local primary_weapon_index = weapons.player_list[pname].creator.weapon_pri
	local primary_weapon = minetest.registered_nodes[weapons.creator.weapons.primary[primary_weapon_index].itemstring]
	local primary_preview, primary_materials = "", ""
	if primary_weapon._localisation.preview == nil then
		-- Fallback or use an invisible model /shrug
		primary_preview = "preview_shotgun.obj;"
	else
		primary_preview = primary_weapon._localisation.preview .. ";"
	end

	for k, v in pairs(primary_weapon._arms.textures) do
		if primary_weapon._arms.skin_pos == k then
		else
			if #primary_weapon._arms.textures == k then
				primary_materials = primary_materials .. primary_weapon._arms.textures[k] .. ";"
			else
				primary_materials = primary_materials .. primary_weapon._arms.textures[k] .. ","
			end
		end
	end
	
	local secondary_weapon_index = weapons.player_list[pname].creator.weapon_sec
	local secondary_weapon = minetest.registered_nodes[weapons.creator.weapons.secondary[secondary_weapon_index].itemstring]
	local secondary_preview, secondary_materials = "", ""

	if secondary_weapon._localisation.preview == nil then
		secondary_preview = "preview_boringpistol.obj;"
	else
		secondary_preview = secondary_weapon._localisation.preview .. ";"
	end

	for k, v in pairs (secondary_weapon._arms.textures) do
		if secondary_weapon._arms.skin_pos == k then
		else
			if #secondary_weapon._arms.textures == k then
				secondary_materials = secondary_materials .. secondary_weapon._arms.textures[k] .. ";"
			else
				secondary_materials = secondary_materials .. secondary_weapon._arms.textures[k] .. ","
			end
		end
	end

	local primary_model = "model[5,-0.5;8,3;preview_primary;"..primary_preview..primary_materials.."0,-90]"
	local secondary_model = "model[5,2.5;8,3;preview_secondary;"..secondary_preview..secondary_materials.."0,-90]"
	return primary_model .. secondary_model
end

function weapons.creator.player_stats(player, pname)
	local points_label = "label[14, 0.5;"
	local p_lbl_text = ""
	if weapons.player_list[pname].creator.points <= 0 then
		p_lbl_text = "No points available to spend, unallocate some spent points!"
		points_label = "label[13.5, 0.5;"
	elseif weapons.player_list[pname].creator.points > 0 then
		p_lbl_text = weapons.player_list[pname].creator.points .. " available points to spend, allocate some points!"
	end

	points_label = points_label .. p_lbl_text .. "]"
	
	local dec_hp   = "button[12.5,1.5;0.5,0.5;dec_hp;-]"
	local inc_hp   = "button[14.5,1.5;0.5,0.5;inc_hp;+]"
	
	local dec_blk  = "button[12.5,2.5;0.5,0.5;dec_blk;-]"
	local inc_blk  = "button[14.5,2.5;0.5,0.5;inc_blk;+]"
	
	local dec_spd  = "button[12.5,3.5;0.5,0.5;dec_spd;-]"
	local inc_spd  = "button[14.5,3.5;0.5,0.5;inc_spd;+]"

	local dec_jump = "button[12.5,4.5;0.5,0.5;dec_jump;-]"
	local inc_jump = "button[14.5,4.5;0.5,0.5;inc_jump;+]"
	
	local lbl_hp   = "label[13.2,1.65;Health: "..weapons.player_list[pname].creator.hp.."]"
	local lbl_blk  = "label[13.225,2.65;Blocks: "..weapons.player_list[pname].creator.blocks.."]"
	local lbl_spd  = "label[13.25,3.65;Speed: "..weapons.player_list[pname].creator.speed.."x]"
	local lbl_jump = "label[13.3,4.65;Jump: "..weapons.player_list[pname].creator.jump.."x]"
	
	local cost_hp   = "label[13.3,1.85;Cost: "..weapons.creator.hp_cost.."]"
	local cost_blk  = "label[13.3,2.85;Cost: "..weapons.creator.blocks_cost.."]"
	local cost_spd  = "label[13.3,3.85;Cost: "..weapons.creator.speed_cost.."]"
	local cost_jump = "label[13.3,4.85;Cost: "..weapons.creator.jump_cost.."]"

	local player_preview = "image[20.5,0.5;3,6;creator_skin_placeholder.png]"
	local helmet_index = 1
	local armour_index = 1
	local undersuit_index = 1
	local helmet_dropdown = "dropdown[20.5,6.5;3;armour_chooser;Default Helmet,Unlockable Helmet,Placeholder Hemlet;"..helmet_index..";true]"
	local armour_dropdown = "dropdown[20.5,7.5;3;armour_chooser;Default Armour,Unlockable Armour,Placeholder Armour;"..armour_index..";true]"
	local undersuit_dropdown = "dropdown[20.5,8.5;3;undersuit_chooser;Default Undersuit,Unlockable Undersuit,Placeholder Undersuit;"..undersuit_index..";true]"


	return 
		points_label..
		lbl_hp..
		cost_hp..
		dec_hp..
		inc_hp..
		
		lbl_jump..
		cost_jump..
		dec_jump..
		inc_jump..
		
		lbl_spd..
		cost_spd..
		dec_spd..
		inc_spd..
		
		lbl_blk..
		cost_blk..
		dec_blk..
		inc_blk..

		player_preview..
		undersuit_dropdown..
		armour_dropdown..
		helmet_dropdown

end

function weapons.creator.display_formspec(pname, player, fields)
	weapons.creator.form_to_creator(fields, player, pname)
	local weapon_lists = weapons.creator.generate_weapons_list(player)
	local preview = weapons.creator.player_preview(player, pname)
	local player_stats = weapons.creator.player_stats(player, pname)
	minetest.show_formspec(pname, "create_a_class", create_a_class..weapon_lists..preview..player_stats)
end

minetest.register_chatcommand("creator", {

	description = "create a class, will respawn you.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name
	)
		local weapon_lists = weapons.creator.generate_weapons_list(minetest.get_player_by_name(name))
		local preview = weapons.creator.player_preview(player, name)
		local player_stats = weapons.creator.player_stats(player, name)
		minetest.show_formspec(name, "create_a_class", create_a_class..weapon_lists..preview..player_stats)
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pname = player:get_player_name()
	--print(dump(fields))
	if formname == "create_a_class" then
		if fields.respawn == "Respawn" then
			weapons.creator.form_to_creator(fields, player, pname)
			if weapons.player_list[pname].texture == nil then
				minetest.close_formspec(pname, "create_a_class")
			else
				weapons.kill_player(player, player, {_localisation={name="Suicide Pill"}}, 0, false)
			end
			weapons.creator.creator_to_class(player, pname)
		elseif fields.quit == "true" then
			if weapons.player_list[pname].texture == nil then
				minetest.after(0.06, weapons.creator.display_formspec, pname, player, fields)
			else
				minetest.close_formspec(pname, "create_a_class")
			end
		else -- Formspec updates
			weapons.creator.display_formspec(pname, player, fields)
		end
	end
end)

local function clear_inv(player)
	local p_inv = player:get_inventory()
	p_inv:set_list("main", {})
	p_inv:set_list("craft", {})
end

weapons.clear_inv = clear_inv


local function add_class_items(player, class_items)
	local items = class_items or base_class.items
	local p_inv = player:get_inventory()
	local pname = player:get_player_name()
	for k, stack in pairs(class_items) do
		local istack = ItemStack(stack .. " 1")
		p_inv:add_item("main", istack)
		-- Hacky bullshit part 69
		-- This doesn't cancel reloading at all, it just for some reason doesn't
		-- properly *apply* it.
		weapons.is_reloading[pname][stack] = false
	end
	player:hud_set_hotbar_itemcount(#class_items)
end

weapons.add_class_items = add_class_items

local function set_player_physics(player, class_stats)
	local pname = player:get_player_name()
	local cstat = {
		speed = weapons.player_list[pname].creator.speed,
		jump = weapons.player_list[pname].creator.jump,
		sneak_glitch = true,
		new_move = false
	}
	player:set_physics_override(cstat)
end

local function set_ammo(player, class_items)
	local pname = player:get_player_name()

	local items, stats
	if class_items == nil then
		items = base_class.items
	else
		items = class_items
	end
	
	for _, stack in pairs(items) do
		-- Big hax btw, teams can have differing magazine sizes
		local weapon = minetest.registered_nodes[stack]

		-- Avoid invalid weapons being checked against
		if weapon == nil then
		-- Also avoid invalid ammo types
		elseif weapon._ammo_type == nil then
		else
			-- Allow certain magazine sizes to be class defined:
			if weapon._mag == nil then
			else
				if weapon._is_energy == nil then
					weapons.player_list[pname][weapon._ammo_type] = weapon._mag
					weapons.player_list[pname][weapon._ammo_type .. "_max"] = weapon._mag
					weapons.player_list[pname][weapon._ammo_type .. "_energy"] = false
				elseif weapon._is_energy then
					weapons.player_list[pname][weapon._ammo_type] = 0
					weapons.player_list[pname][weapon._ammo_type .. "_max"] = 100
					weapons.player_list[pname][weapon._ammo_type .. "_energy"] = true
				else
					weapons.player_list[pname][weapon._ammo_type] = weapon._mag
					weapons.player_list[pname][weapon._ammo_type .. "_max"] = weapon._mag
					weapons.player_list[pname][weapon._ammo_type .. "_energy"] = false
				end
			end
		end
	end
	weapons.player_list[pname].blocks = weapons.player_list[pname].creator.blocks
	weapons.player_list[pname].blocks_max = weapons.player_list[pname].creator.blocks
	weapons.player_list[pname].fatigue = 0
	weapons.player_list[pname].fatigue_max = 100
end


function weapons.get_tex_size(file) -- ported from a fork
	local file = io.open(file)
	if file then
	
		file:seek("set", 16)
		local widthstr, heightstr = file:read(4), file:read(4)
		local width=widthstr:sub(1,1):byte()*16777216+widthstr:sub(2,2):byte()*65536+widthstr:sub(3,3):byte()*256+widthstr:sub(4,4):byte()
		local height=heightstr:sub(1,1):byte()*16777216+heightstr:sub(2,2):byte()*65536+heightstr:sub(3,3):byte()*256+heightstr:sub(4,4):byte()
		file:close()
		return width, height
	else
		return nil, nil
	end
end

function weapons.get_player_skin(player)
	local pname = player:get_player_name()
	local team = weapons.player.get_team(player)
	local skin = 1
	if team == nil then
		return nil
	else
		return "skin_"..skin.."_" .. team .. ".png"
	end
end

function weapons.get_player_texture(player)
	local path = minetest.get_modpath("weapons").."/textures/heads/"
	local pname = player:get_player_name()
	local x64_template = "([combine:64x64:0,0="
	local x16_chop = "([combine:64x16:0,0="
	local result
	local player_head = "player_"..pname..".png"
	local width, height = weapons.get_tex_size(path..player_head)
	local skin_overlay = weapons.get_player_skin(player)

	if skin_overlay == nil then
		return nil
	elseif width == nil then
		local nhead = x16_chop .. "default_player.png" .. ")"
		return x64_template .. ")^" .. nhead .. "^" .. skin_overlay
	elseif height == 64 or height == 32 then
		local nhead = x16_chop .. player_head .. ")"
		result = x64_template .. ")^" .. nhead .. "^" .. skin_overlay
	else
		local nhead = x16_chop .. "default_player.png" .. ")"
		return x64_template .. ")^" .. nhead .. "^" .. skin_overlay
	end
	return result
end

function weapons.set_player_texture(player)
	local pname = player:get_player_name()
	local ptex = weapons.get_player_texture(player)
	if ptex == nil then
		minetest.after(1, weapons.set_player_texture, player)
		return
	end
	weapons.player_list[pname].texture = ptex
end

weapons.set_ammo = set_ammo

local function set_health(player, class)
	local pname = player:get_player_name()
	weapons.player_list[pname].hp = base_class.stats.hp
	weapons.player_list[pname].hp_max = base_class.stats.hp
	weapons.hud.force_hp_refresh(player)
end

weapons.force_anim_group = {}
weapons.force_anim_set = {}

local anim_lock = {}
local anim_frame = {}

-- Arm animations
local arm_frame = {} -- frame offset
local arm_anim = {} -- x and y frame range
local arm_type = {} -- animation group
local arm_after = {} -- minetest.after storage
local last_arm = {} -- last wield item

local look_pitch = {}
local last_anim = {}
weapons.player_arms = {}
weapons.player_body = {}

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if minetest.get_player_information(pname).formspec_version < 4 then
		minetest.kick_player(pname, "Hello ".. pname .. ", please upgrade your client to Minetest 5.4.0 or greater!")
	end

	player:set_nametag_attributes({
		color = "#00000000"
	})
	
	player:set_properties({
		textures = {"transparent.png", "transparent.png"}
	})
	
	weapons.update_blue_flag = true
	weapons.update_red_flag = true

	-- Animation things
	anim_lock[pname] = false
	anim_frame[pname] = -1
	-- Arm anim things
	arm_frame[pname] = -1
	arm_anim[pname] = {x=-1, y=-1}
	arm_type[pname] = "idle"
	arm_after[pname] = ""
	last_arm[pname] = "!literally:invalid"

	look_pitch[pname] = -1000
	last_anim[pname] = {x=-1, y=-1}

	player:set_eye_offset(weapons.default_first_person_eyes, {x=0,y=-1,z=-3})

	-- Clear old invs first:
	clear_inv(player)
	weapons.player_list[pname] = {}
	-- Fix aim not working
	weapons.player_list[pname].aim_mode = false
	weapons.player_list[pname].anim_mode = false -- true == alternate animation, false == regular

	-- Create a class things
	-- I'm only doing this to enable me to fold this up.
	if true then
		weapons.player_list[pname].creator = {}
		weapons.player_list[pname].creator.points = weapons.creator.base_points
		weapons.player_list[pname].creator.hp = weapons.creator.hp_base
		weapons.player_list[pname].creator.speed = weapons.creator.speed_base
		weapons.player_list[pname].creator.jump = weapons.creator.jump_base
		weapons.player_list[pname].creator.blocks = weapons.creator.blocks_base

		weapons.player_list[pname].creator.weapon_pri = 1
		weapons.player_list[pname].creator.weapon_sec = 1
		weapons.player_list[pname].creator.weapon_gre = 1
	end


	weapons.assign_team(player, nil)
	weapons.creator.display_formspec(pname, player, {})
end)

-- cache bone positions for speed
local head_rot  = vector.new(-90,0,180)
local head_pos  = vector.new(0,0,-5)
local body_pos  = vector.new(0,0,-4.5)
local body_rot  = vector.new(-90,0,180)
local legs_pos  = vector.new(0,0,-6)
local legs_rot  = vector.new(90,0,180)
local arms_pos  = vector.new(0,10,0)
local arms_rot  = vector.new(0,0,0)
local nulvec    = vector.new(0,0,0)

function weapons.player.set_class(player, class_items)
	local pname = player:get_player_name()

	-- Clear inv:
	clear_inv(player)
	set_health(player)
	set_player_physics(player)
	set_ammo(player, class_items)
	add_class_items(player, class_items)

	weapons.set_player_texture(player)
	
	local ppos = player:get_pos()
	-- Add player body
	if weapons.player_body[pname] == nil then
		weapons.player_body[pname] = minetest.add_entity(ppos, "weapons:player_body")
		local plb_lae = weapons.player_body[pname]:get_luaentity()
		plb_lae._player_ref = player
		weapons.player_body[pname]:set_properties({textures = {weapons.player_list[pname].texture}})
		weapons.player_body[pname]:set_attach(player, "",  nulvec, nulvec, true)
		weapons.player_body[pname]:set_bone_position("Armature_Root", body_pos, body_rot)
		weapons.player_body[pname]:set_bone_position("Armature_Legs", legs_pos, legs_rot)
	end

	if weapons.player_arms[pname] == nil then
		-- Add wield arms
		weapons.player_arms[pname] = minetest.add_entity(ppos, "weapons:player_arms")
		local pla_lae = weapons.player_arms[pname]:get_luaentity()
		pla_lae._player_ref = player
		--weapons.player_arms[pname]:set_properties({textures = {"assault_class_" .. weapons.player_list[pname].team .. ".png", pla_lae._texture}})
		weapons.player_arms[pname]:set_attach(player, "", nulvec, nulvec, true)
		weapons.player_arms[pname]:set_bone_position("Armature_Root", arms_pos, arms_rot)
	end

	player:set_properties({
		visual = "mesh",
		mesh = "player_head.x",
		textures = {
			weapons.player_list[pname].texture,
		},
		visual_size = {x=1.05, y=1.05},
		collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.77, 0.3},
		nametag = "",
		--stepheight = 1.1,
		eye_height = weapons.default_eye_height,
	})	
	player:set_bone_position("Armature_Root", head_pos, head_rot)
end

minetest.register_on_leaveplayer(function(player, timed_out)
	-- Remove old attachments
	local pname = player:get_player_name()
	if weapons.player_arms[pname] ~= nil then
		weapons.player_arms[pname]:remove()
		weapons.player_arms[pname] = nil
	end
	if weapons.player_body[pname] ~= nil then
		weapons.player_body[pname]:remove()
		weapons.player_body[pname] = nil
	end
end)

minetest.register_chatcommand("respawn", {
	description = "Respawn back to base if stuck.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		weapons.kill_player(player, player, {_localisation = {name="Suicide Pill"}}, 0, false)
	end,
})

local function unlock_anim(pname)
	anim_lock[pname] = false
	anim_frame[pname] = -1
end

local function unlock_arms(pname)
	arm_frame[pname] = -1
	arm_type[pname] = "idle"

	--if solarsail.controls.player[pname].LMB then
		local curr_anim, spd, bl, loop = weapons.player_arms[pname]:get_animation()
		curr_anim.x = curr_anim.y
		weapons.player_arms[pname]:set_animation(curr_anim, 60, 0.15, false)
	--end
end

local function reset_arm_pos(pname, weapon)
	if weapon == nil then
		weapons.player_arms[pname]:set_bone_position("Armature_Root", arms_pos, arms_rot)
	else
		if weapon._arms.pos == nil then
			weapons.player_arms[pname]:set_bone_position("Armature_Root", arms_pos, arms_rot)
		else
			weapons.player_arms[pname]:set_bone_position("Armature_Root", weapon._arms.pos, arms_rot)
		end
	end
end

local animation_table = {}

animation_table.body = {}
animation_table.body.idle = {x=0, y=159}
animation_table.body.up = {x=170, y=249}
animation_table.body.left = {x=260, y=339}
animation_table.body.right = {x=350, y=430}
animation_table.body.down = {x=440, y=519}

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local wield = player:get_wielded_item():get_name()
		local weapon = minetest.registered_nodes[wield]
		if true then -- Legs/Body, Head anim foldable for your viewing pleasure
			local ppitch = -math.deg(player:get_look_vertical())
			local frame_offset = 0
			local anim_group
			if look_pitch[pname] ~= ppitch then
				player:set_animation({x=ppitch+90, y=ppitch+90}, 1, 0.03, false)
				local pidiv2 = 1.5707963268
				
				look_pitch[pname] = ppitch+0 -- Do not alias
				if weapon == nil then
				elseif weapon._min_arm_angle == nil then
				elseif weapon._max_arm_angle == nil then
				else
					if weapons.player_arms[pname] ~= nil then
						if ppitch > weapon._max_arm_angle then
							ppitch = weapon._max_arm_angle
						elseif ppitch < weapon._min_arm_angle then
							ppitch = weapon._min_arm_angle
						end
						--Manually control arms bone here
						local bpos = arms_pos
						if weapon._arms.pos ~= nil then
							bpos = weapon._arms.pos
						end
						weapons.player_arms[pname]:set_bone_position(
							"Armature_Root",
							bpos,
							{x=ppitch+arms_rot.x, y=arms_rot.y, z=arms_rot.z}
						)
					end
				end
			end

			if anim_frame ~= nil then
				if anim_frame[pname] ~= nil then
					if anim_frame[pname] ~= -1 then
						anim_frame[pname] = anim_frame[pname] + dtime
						frame_offset = math.floor(anim_frame[pname] * 60)
					end
				end
			end
			if solarsail.controls.player[pname] == nil then
			elseif solarsail.controls.player[pname].left then
				if solarsail.controls.player[pname].down then
					anim_group = "left"
				else
					anim_group = "right"
				end
			elseif solarsail.controls.player[pname].right then
				if solarsail.controls.player[pname].down then
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

			-- Only do animations when we have a valid animation 
			if anim_group == nil then
			else
				-- Avoid aliasing the original animation table and screwing it up for everyone.
				local result_frames = table.copy(animation_table.body[anim_group])

				-- Only increment the animation start frames when we have an uncancelable animation
				if frame_offset ~= 0 then
					result_frames.x = result_frames.x + frame_offset
					-- Prevent animation leaking into other keyframes
					if frame_offset.x > frame_offset.y then
						frame_offset.x = frame_offset.y
					end
				end

				-- Prevent re-sending packets to clients with the exact frames again.
				if last_anim[pname].x ~= result_frames.x then
					if weapons.player_body[pname] ~= nil then
						weapons.player_body[pname]:set_animation(result_frames, 60, 0.1, true)
					end
					-- Once again, avoid aliasing and getting a potentially GC'd frame range
					last_anim[pname] = table.copy(result_frames)
				end
			end
		end
		if true then -- Arms animation utilities, are locked frame wise; if weapon doesn't match prior, it's canceled.
			if wield ~= last_arm[pname] then
				-- Unlock if there's an active minetest.after registered
				-- and if the wield is swapped
				if arm_after[pname] ~= "" then
					arm_after[pname]:cancel()
					unlock_arms(pname)
					arm_after[pname] = ""
				end

				-- Update arms visuals
				if weapon == nil then
				elseif weapon._arms == nil then -- Prevent nil crashing
				else
					reset_arm_pos(pname, weapon)
					unlock_arms(pname)
					local materials = weapon._arms.textures
					materials[weapon._arms.skin_pos] = weapons.player_list[pname].texture
					weapons.player_arms[pname]:set_properties({
						mesh = weapon._arms.mesh,
						textures = materials
					})
				end
				last_arm[pname] = wield
			end

			if weapon == nil then
			else
				local ammo = weapon._ammo_type
				if weapon._anim == nil then
				elseif arm_frame[pname] == -1 then
					if weapons.is_reloading[pname][wield] == nil then
					elseif weapons.is_reloading[pname][wield] then
						if not weapons.player_list[pname].anim_mode then
							arm_frame[pname] = 0
							arm_type[pname] = "reload"
							arm_after[pname] = minetest.after(weapon._reload, unlock_arms, pname)
							if weapons.player_arms[pname] ~= nil then
								weapons.player_arms[pname]:set_animation(weapon._anim.reload, 60, 0.15, true)
							end
						else
							arm_frame[pname] = 0
							arm_type[pname] = "reload_alt"
							arm_after[pname] = minetest.after((weapon._reload*0.9), unlock_arms, pname)
							if weapons.player_arms[pname] ~= nil then
								weapons.player_arms[pname]:set_animation(weapon._anim.reload_alt, 60, 0.15, true)
							end
						end
					elseif solarsail.controls.player[pname].RMB then -- Handle aiming
						if solarsail.controls.player[pname].LMB then
							if weapons.player_list[pname][ammo] > 0 or ammo == "blocks" then
								arm_frame[pname] = 0
								arm_type[pname] = "aim_fire"
								arm_after[pname] = minetest.after((60 / weapon._rpm), unlock_arms, pname)
								if weapons.player_arms[pname] ~= nil then
									weapons.player_arms[pname]:set_animation(weapon._anim.aim_fire, 60, 0.15, true)
								end
							end
						else
							--arm_frame[pname] = -1
							arm_type[pname] = "aim"
							if weapons.player_arms[pname] ~= nil then
								weapons.player_arms[pname]:set_animation(weapon._anim.aim, 60, 0.15, true)
							end
						end
					else
						if solarsail.controls.player[pname].LMB then
							if weapons.player_list[pname][ammo] > 0 or ammo == "blocks" then
								arm_frame[pname] = 0
								arm_type[pname] = "idle_fire"
								arm_after[pname] = minetest.after((60 / weapon._rpm), unlock_arms, pname)
								if weapons.player_arms[pname] ~= nil then
									weapons.player_arms[pname]:set_animation(weapon._anim.idle_fire, 60, 0.15, true)
								end
							end
						else
							--arm_frame[pname] = -1
							arm_type[pname] = "idle"
							if weapons.player_arms[pname] ~= nil then
								weapons.player_arms[pname]:set_animation(weapon._anim.idle, 60, 0.15, true)
							end
						end
					end
				end
			end
		end
	end
end)