-- Weapons for Super CTF:
-- Author: Jordach
-- License: Reserved

-- Create a class configuration:
weapons.creator = {}
weapons.creator.base_points = 30

weapons.creator.hp_cost = 3
weapons.creator.hp_base = 100
weapons.creator.hp_gain = 5

weapons.creator.speed_cost = 3
weapons.creator.speed_base = 1
weapons.creator.speed_gain = 0.2

weapons.creator.jump_cost = 3
weapons.creator.jump_base = 1
weapons.creator.jump_gain = 0.15

weapons.creator.weight_cost = 2
weapons.creator.weight_base = 1
weapons.creator.weight_loss = 0.05

weapons.creator.blocks_cost = 1
weapons.creator.blocks_base = 20
weapons.creator.blocks_gain = 3

weapons.creator.perk_cost = 5

local base_class = {}
base_class.stats = {
	hp = weapons.creator.hp_base,
	blocks = weapons.creator.blocks_base
}
base_class.physics = {
	speed = weapons.creator.speed_base,
	jump = weapons.creator.jump_base,
	gravity = weapons.creator.weight_base,
	-- Legacy
	sneak = true,
	sneak_glitch = true,
	new_move = false
}

local assault = {}
assault.stats = {
	hp = 100,
	blocks = 20,
}
assault.items = {
	"weapons:assault_rifle",
	--"weapons:rocket_launcher",
	"weapons:pickaxe",
	"core:team_neutral",
}
assault.physics = {
	speed = 1,
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
	"weapons:smoke_grenade",
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
	"weapons:heal_grenade",
	--"weapons:injector",
	"weapons:pickaxe",
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
	speed = 1.8,
	jump = 1.65,
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
	--"button[2,7;2,1;marksman;Marksman]"..
	--"button[4,7;2,1;medic;Medic]"..
	--"button[6,7;2,1;scout;Scout]"..
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
			istack = ItemStack(stack .. " 1")
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
		local weapon = minetest.registered_nodes[stack]

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
	weapons.update_health(player)
	weapons.fix_hp_bg(player)
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
		--minetest.kick_player(pname, "Hello ".. pname .. ", please upgrade your client to Minetest 5.4.0 or greater!")
	end
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

	-- Create a class things
	weapons.player_list[pname].creator = {}
	weapons.player_list[pname].creator.points = weapons.creator.base_points
	weapons.player_list[pname].creator.spent = 0
	weapons.player_list[pname].creator.hp_base = weapons.creator.hp_base
	weapons.player_list[pname].creator.speed_base = weapons.creator.speed_base
	weapons.player_list[pname].creator.jump_base = weapons.creator.jump_base
	weapons.player_list[pname].creator.weight_base = weapons.creator.weight_base
	weapons.player_list[pname].creator.blocks = weapons.creator.blocks_base
	weapons.player_list[pname].creator.perk_one = 1
	weapons.player_list[pname].creator.perk_two = 1
	weapons.player_list[pname].creator.weapon_pri = 1
	weapons.player_list[pname].creator.weapon_sec = 1
	weapons.player_list[pname].creator.weapon_gre = 1

	weapons.assign_team(player, nil)
	minetest.after(2, weapons.player.set_class, player, "assault")
	player:set_nametag_attributes({
		color = "#00000000"
	})

	-- Red Base waypoint
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

	-- Blue Base waypoint
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

	weapons.update_blue_flag = true
	weapons.update_red_flag = true
end)

-- cache bone positions for speed
local head_rot  = -90
local head_body = vector.new(0,-4.5,-12.5)
local body_pos  = vector.new(0,4.5,-4.25)
local body_rot  = vector.new(0,0,0)
local legs_pos  = vector.new(0,6,-4.25)
local legs_rot  = vector.new(180,0,0)
local arms_pos  = vector.new(0,9,-4.25)
local arms_rot  = vector.new(0,0,0)
local nulvec    = vector.new(0,0,0)

function weapons.player.set_class(player, class)
	local pname = player:get_player_name()

	-- Clear inv:
	clear_inv(player)
	set_player_physics(player, class)
	set_health(player, class)
	weapons.player_list[pname].class = class
	set_ammo(player, class)
	add_class_items(player, class)
	weapons.update_health(player)

	-- Add player body
	local ppos = player:get_pos()
	weapons.player_body[pname] = minetest.add_entity(ppos, "weapons:player_body")
	local plb_lae = weapons.player_body[pname]:get_luaentity()
	plb_lae._player_ref = player
	weapons.player_body[pname]:set_properties({textures = {"assault_class_" .. weapons.player_list[pname].team .. ".png"}})
	weapons.player_body[pname]:set_attach(player, "Armature_Root",  nul_vec, nul_vec, true)
	weapons.player_body[pname]:set_bone_position("Armature_Root", body_pos, body_rot)
	weapons.player_body[pname]:set_bone_position("Armature_Legs", legs_pos, legs_rot)

	-- Add wield arms
	weapons.player_arms[pname] = minetest.add_entity(ppos, "weapons:assault_arms")
	local pla_lae = weapons.player_arms[pname]:get_luaentity()
	pla_lae._player_ref = player
	weapons.player_arms[pname]:set_properties({textures = {"assault_class_" .. weapons.player_list[pname].team .. ".png", pla_lae._texture}})
	weapons.player_arms[pname]:set_attach(player, "Armature_Root", nulvec, nulvec, true)
	weapons.player_arms[pname]:set_bone_position("Armature_Root", arms_pos, arms_rot)

	weapons.respawn_player(player, false)
	player:set_properties({
		visual = "mesh",
		mesh = "player_head.x",
		textures = {
			"assault_class_"..weapons.player_list[player:get_player_name()].team..".png",
		},
		visual_size = {x=1.05, y=1.05},
		collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.77, 0.3},
		nametag = "",
		stepheight = 0.6,
		eye_height = 1.64,
	})	
end

minetest.register_on_leaveplayer(function(player, timed_out)
	-- Remove old attachments
	local pname = player:get_player_name()
	if weapons.player_arms[pname] ~= nil then
		weapons.player_arms[pname]:remove()
		weapons.player_arms[pname] = nil
	end
	if weapon.player_body[pname] ~= nil then
		weapons.player_body[pname]:remove()
		weapons.player_body[pname] = nil
	end
end)

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
		minetest.show_formspec(name, "class_select", weapons.class_formspec)
	end,
})

minetest.register_chatcommand("respawn", {
	description = "Respawn back to base if stuck.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		weapons.kill_player(player, player, {_localisation ={name="Suicide Pill"}}, 0)
	end,
})

local function unlock_anim(pname)
	anim_lock[pname] = false
	anim_frame[pname] = -1
end

local function unlock_arms(pname)
	arm_frame[pname] = -1
	arm_type[pname] = "idle"
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
				player:set_bone_position("Armature_Head", head_body, {x = ppitch + head_rot, y = 0, z = 0})
				look_pitch[pname] = ppitch
				if weapon == nil then
				elseif weapon._max_arm_angle == nil then
				else
					if weapons.player_arms[pname] ~= nil then
						if ppitch > weapon._max_arm_angle then
							ppitch = weapon._max_arm_angle
						elseif ppitch < weapon._min_arm_angle then
							ppitch = weapon._min_arm_angle
						end
						--Manually control arms bone here
						weapons.player_arms[pname]:set_bone_position("Armature_Root", arms_pos, {x=ppitch+arms_rot.x, y=arms_rot.y, z=arms_rot.z})
					end
				end
			end

			if anim_frame ~= nil then
				if anim_frame[pname] ~= -1 then
					anim_frame[pname] = anim_frame[pname] + dtime
					frame_offset = math.floor(anim_frame[pname] * 60)
				end
			end
			if solarsail.controls.player[pname] == nil then
			elseif solarsail.controls.player[pname].left then
				if solarsail.controls.player[pname].down then
					anim_group = "right"
				else
					anim_group = "left"
				end
			elseif solarsail.controls.player[pname].right then
				if solarsail.controls.player[pname].down then
					anim_group = "left"
				else
					anim_group = "right"
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
					player:set_animation(result_frames, 60, 0.1, true)
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
				if arm_after[pname] ~= "" then
					arm_after[pname]:cancel()
					unlock_arms(pname)
					arm_after[pname] = ""
				end
			end

			if weapon == nil then
			else
				if weapon._anim == nil then
				elseif arm_frame[pname] == -1 then
					local result_frames
					if weapons.is_reloading[pname][wield] then
						arm_frame[pname] = 0
						arm_type[pname] = "reload"
						arm_after[pname] = minetest.after(weapon._reload + 0.03, unlock_arms, pname)
						if weapons.player_arms[pname] ~= nil then
							weapons.player_arms[pname]:set_animation(weapon._anim.reload, 60, 0.015, false)
						end
					elseif solarsail.controls.player[pname].RMB then -- Handle aiming
						if solarsail.controls.player[pname].LMB then
							arm_frame[pname] = 0
							arm_type[pname] = "aim_fire"
							arm_after[pname] = minetest.after(60 / weapon._rpm + 0.03, unlock_arms, pname)
							if weapons.player_arms[pname] ~= nil then
								weapons.player_arms[pname]:set_animation(weapon._anim.aim_fire, 60, 0.015, false)
							end
						else
							if weapons.player_arms[pname] ~= nil then
								arm_frame[pname] = -1
								arm_type[pname] = "aim"
								weapons.player_arms[pname]:set_animation(weapon._anim.aim, 60, 0.1, false)
							end
						end
					else
						if solarsail.controls.player[pname].LMB then
							arm_frame[pname] = 0
							arm_type[pname] = "idle_fire"
							arm_after[pname] = minetest.after(60 / weapon._rpm + 0.03, unlock_arms, pname)
							if weapons.player_arms[pname] ~= nil then
								weapons.player_arms[pname]:set_animation(weapon._anim.idle_fire, 60, 0.015, false)
							end
						else
							if weapons.player_arms[pname] ~= nil then
								arm_frame[pname] = -1
								arm_type[pname] = "idle"
								if weapons.player_arms[pname] then
									weapons.player_arms[pname]:set_animation(weapon._anim.idle, 60, 0.1, false)
								end
							end
						end
					end
				end
			end
			if last_arm[pname] ~= wield then
				last_arm[pname] = wield
			end
		end
	end
end)

---------------------------------
---------------------------------
-- Create a class testing zone --
---------------------------------
---------------------------------

weapons.creator.weapons = {}
weapons.creator.weapons.primary = {}
weapons.creator.weapons.secondary = {}
weapons.creator.weapons.grenades = {}
weapons.creator.perks = {}

function weapons.creator.register_weapon(localisation, slot)
	weapons.creator.weapons[slot][#weapons.creator.weapons[slot]+1] = localisation
end

function weapons.creator.generate_weapons_list(player)
	local pname = player:get_player_name()
	local pri_list, pri_tooltip, sec_list, sec_tooltip, gre_list, gre_tooltip = ""
	local pri_index, sec_index, gre_index

	-- Construct primary weapons dropdown and tooltip:
	for index, localisation in pairs(weapons.creator.weapons.primary) do
		if index ~= #weapons.creator.weapons.primary then
			pri_list = pri_list .. localisation.name .. ","
		else
			pri_list = pri_list .. localisation.name .. ";"
		end
		
		if index == weapons.player_list[pname].creator.weapon_pri then
			pri_tooltip = "tooltip[0,0;5,1;"..localisation.tooltip.."]"
			pri_index = index
		end
	end

	-- Invalidate weapons that used to exist but no longer exist in updates,
	-- ideally this should never happen but just in case classes are remembered between restarts
	if #weapons.creator.weapons.primary < weapons.player_list[pname].creator.weapon_pri then
		pri_tooltip = "tooltip[0,0;5,1;"..weapon.creator.weapons.primary[1].tooltip.."]"
		print("[Weapons WARNING]: Weapon index is invalid. Potentially a missing weapon?")
	end

	local dropdown_pri = "dropdown[0,0;4;weapon_pri;"..pri_list..pri_index..";true]"

	return dropdown_pri..pri_tooltip
end

function weapons.creator.register_perk(localisation)
	weapons.creator.perks[#weapons.creator.perks+1] = localisation
end

function weapons.creator.generate_perk_list(player)
	local pname = player:get_player_name()
	local perk_list, tooltip_pri, tooltip_sec = ""
	local index_pri, index_sec

	for index, localisation in pairs(weapons.creator.perks) do
		if index ~= #weapons.creator.perks then
			perk_list = perk_list .. localisation.name .. ","
		else
			perk_list = perk_list .. localisation.name .. ";"
		end

		if index == weapons.player_list[pname].creator.perk_one then
			tooltip_pri = "tooltip[0,3;5,1;"..localisation.tooltip.."]"
			index_pri = index
		end

		if index == weapons.player_list[pname].creator.perk_two then
			tooltip_sec = "tooltip[0,4;5,1;"..localisation.tooltip.."]"
			index_sec = index
		end

	end

	-- Disallow invalid perks that don't exist
	if #weapons.creator.perks < weapons.player_list[pname].creator.perk_one then
		tooltip_pri = "tooltip[0,3;5,1;"..weapons.creator.perks[1].tooltip.."]"
		index_pri = 1
		print("[Weapons WARNING]: Perk index is invalid. Potentially a missing perk?")
	end

	if #weapons.creator.perks < weapons.player_list[pname].creator.perk_two then
		tooltip_sec = "tooltip[0,4;5,1;"..weapons.creator.perks[1].tooltip.."]"
		index_sec = 1
		print("[Weapons WARNING]: Perk index is invalid. Potentially a missing perk?")
	end

	local perks_pri = "dropdown[0,3;4;perk_pri;"..perk_list..index_pri..";true]"
	local perks_sec = "dropdown[0,4;4;perk_sec;"..perk_list..index_sec..";true]"

	return perks_pri..perks_sec..tooltip_pri..tooltip_sec
end

weapons.creator.register_perk({name="No Perk",tooltip="No perk equipped, costs 0 points. All perks cost 5 points.",var="no_perk"})
weapons.creator.register_perk({name="Automated Reload Link",tooltip="Partially reloads magazine on kills for a minimum of one projectile.\nHeadshot kills reload the entire magazine.",var="auto_reload"})
weapons.creator.register_perk({name="Block Fabricator",tooltip="Automaically generates 1 block ammo every 5 seconds.",var="block_fab"})
weapons.creator.register_perk({name="Intergrated Medical Unit",tooltip="Regenerates 25 health every 20 seconds, and resets the cooldown when taking damage.",var="med_unit"})
weapons.creator.register_perk({name="Tough Nut",tooltip="All damage is reduced by 10.",var="tough_nut"})
weapons.creator.register_perk({name="Tungsten Boots",tooltip="Disables weapon knockback and explosive knockback.",var="tungsten_boot"})
weapons.creator.register_perk({name="Smaller Frame",tooltip="10% smaller in size and hitbox.\nAll damage is increased by 20% more damage.\nYou'll also deal 20% less melee damage.",var="smol_frame"})
weapons.creator.register_perk({name="Muscular Frame",tooltip="10% bigger in size and hitbox.\nYour accuracy spread is decreased by 1 node, and 20% better melee damage.",var="muscular"})
weapons.creator.register_perk({name="Gambler",tooltip="5% chance not to take damage.\n5% chance to heal from damage.\n10% chance to take twice the damage after perk calculations.",var="gambler"})
weapons.creator.register_perk({name="Dead Eye",tooltip="Pistols have their reload speeds halved, and have accuracy spread reduced by 1 node.",var="dead_eye"})
weapons.creator.register_perk({name="Demolitionist",tooltip="Explosives have an increased blast radius of 3 nodes.\nExplosives also take an extra 25% longer to reload.",var="demoman"})
weapons.creator.register_perk({name="Accelerationism",tooltip="SMG class weapons gain 250 RPM and have their accuracy spread increased by 1 node.",var="accelerator"})
weapons.creator.register_perk({name="One Shot Wonder",tooltip="Sniper rifles and precision weapons deal 3x headshot damage.",var="one_shot"})
weapons.creator.register_perk({name="Tungsten Rounds",tooltip="Assault and Burst Rifles can penetrate upto three nodes and or players.\nDoes not penetrate invulnerable nodes.",var="tungsten_shot"})
weapons.creator.register_perk({name="Ordinance Defusal Plating",tooltip="All explosive damage is reduced by 75%.",var="eod"})

local primary_weapons =
	-- Rifles
	"Assault Rifle,"..
	"Burst Rifle,"..
	"Marksman Rifle,"..
	"Sniper Rifle,"..
	-- SMGs
	"PDW,"..
	"Dual SMGs,"..
	"Dual Micro SMGs,"..
	-- Shotguns
	"Super Shotgun,"..
	"Semi Auto Shotgun,"..
	"Precision Slug Shotgun,"..
	-- Heavy Weapons (Restricts secondary and grenades)
	"Minigun,"..
	"Anti Materiel Rifle,"..
	"HE Semi Auto Shotgun,"..
	-- Explosives
	"Rocket Launcher,"..
	"Grenade Launcher,"..
	-- Misc
	"Medical Regenerator;"

local secondary_weapons = 
	-- Pistols
	"Semi Auto Pistol,"..
	"Auto Pistol,"..
	"Heavy Pistol,"..
	"Revolver,"..
	"Dual Revolvers,"..
	"Silenced Pistol,"..
	--SMGs
	"Micro SMG,"..
	"SMG,"..
	-- Misc
	"Sawn Off Shotgun,"..
	"Medical Injector;"

local grenades =
	"Frag Grenade,"..
	"Sticky Grenade,"..
	"Smoke Grenade,"..
	"Disorientation Grenade,"..
	"Expanding Grenade,"..
	"Repair Grenade,"..
	"Medical Grenade,"..
	"Inferno Grenade,"..
	"Cryo Grenade;"

--local pri_drop = "dropdown[0,0;4;weapon_pri;"..primary_weapons
local sec_drop = "dropdown[0,1;4;weapon_sec;"..secondary_weapons
local gre_drop = "dropdown[0,2;4;weapon_gre;"..grenades

local create_a_class = 
	"size[12,8]"
	--"dropdown[0,0;4;weapon_pri;"..primary_weapons.."1;true]"..
	--"dropdown[0,1;4;weapon_sec;"..secondary_weapons.."1;true]"..
	--"dropdown[0,2;4;weapon_gre;"..grenades.."1;true]"

minetest.register_chatcommand("creator", {
	description = "create a class, will respawn you.",
	func = function(name, param)
		local weapon_lists = weapons.creator.generate_weapons_list(minetest.get_player_by_name(name))
		local player_perks = weapons.creator.generate_perk_list(minetest.get_player_by_name(name))
		minetest.show_formspec(name, "create_a_class", create_a_class..weapon_lists..player_perks)
		--local player = minetest.get_player_by_name(name)
		--weapons.kill_player(player, player, {_localisation={name="Suicide Pill"}}, 0)
	end,
})

minetest.register_on_player_receive_fields(function(player, 
	formname, fields)
	local pname = player:get_player_name()
	if formname == "create_a_class" then
		if fields.save_changes then
			local player = minetest.get_player_by_name(name)
			weapons.kill_player(player, player, {_localisation={name="Suicide Pill"}}, 0)
		end
	end
end)