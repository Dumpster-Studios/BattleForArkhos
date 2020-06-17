-- Rocket Science for Super CTF:
-- Author: Jordach
-- License: Reserved

function weapons.calc_block_damage(nodedef, weapon, target_pos, pointed)
	if nodedef == nil then
	elseif nodedef.name == "air" then
		return 0, "air"
	elseif nodedef.name == "ignore" then
		return 0, "air"
	elseif nodedef._health == nil then
		weapons.spray_particles(pointed, nodedef, target_pos)
		return 0, "air"
	elseif not nodedef._takes_damage then
		weapons.spray_particles(pointed, nodedef, target_pos)
		return 0, nodedef.name
	else
		local nodedamage = nodedef._health - weapon._break_hits
		if nodedamage < 1 then
			weapons.spray_particles(pointed, nodedef, target_pos)
			return 0, "air"
		else
			weapons.spray_particles(pointed, nodedef, target_pos)
			return nodedamage, nodedef._name.."_"..nodedamage
		end
	end
end

local function rocket_explode_damage_blocks(pos)
	local bpos = table.copy(pos)
	local weapon = table.copy(minetest.registered_nodes["weapons:rocket_launcher_red"])
	for x=-1, 1 do
		for y=-1, 1 do
			for z=-1, 1 do
				local npos = {x=bpos.x+x, y=bpos.y+y, z=bpos.z+z}
				local nodedef = minetest.registered_nodes[minetest.get_node(npos).name]
				if nodedef == nil then
				elseif nodedef._takes_damage == nil then
					weapon._break_hits = math.random(1, 4)
					local damage, node = weapons.calc_block_damage(nodedef, weapon, npos)
					minetest.set_node(npos, {name=node})
				end
			end
		end
	end
end

local rocket_ent = {
	visual = "mesh",
	mesh = "rocket_ent.obj",
	textures = {
		"rocket_ent.png",
	},
	physical = true,
	collide_with_objects = true,
	pointable = false,
	collision_box = {-0.15, -0.15, -0.15, 0.15, 0.15, 0.15},
	visual_size = {x=5, y=5},
	_player_ref = nil,
	_loop_sound_ref = nil,
	_timer = 0
}

function rocket_ent:explode(self, moveresult)
	local pos = self.object:get_pos()
	local pos_block
	if moveresult.collisions[1] == nil then
		pos_block = table.copy(self.object:get_pos())
		pos_block.x = math.floor(pos_block.x)
		pos_block.y = math.floor(pos_block.y)
		pos_block.z = math.floor(pos_block.z)
	elseif moveresult.collisions[1].type == "object" then
		if moveresult.collisions[1].object:get_pos() ~= nil then
			pos_block = table.copy(moveresult.collisions[1].object:get_pos())
			pos_block.x = math.floor(pos_block.x)
			pos_block.y = math.floor(pos_block.y)
			pos_block.z = math.floor(pos_block.z)
		else
			pos_block = table.copy(pos)
			pos_block.x = math.floor(pos_block.x)
			pos_block.y = math.floor(pos_block.y)
			pos_block.z = math.floor(pos_block.z)
		end
	elseif moveresult.collisions[1].type == "node" then
		pos_block = table.copy(moveresult.collisions[1].node_pos)
	else
		pos_block = table.copy(pos)
		pos_block.x = math.floor(pos_block.x)
		pos_block.y = math.floor(pos_block.y)
		pos_block.z = math.floor(pos_block.z)
	end

	local node = minetest.registered_nodes[minetest.get_node(pos).name]
	local rocket = minetest.registered_nodes["weapons:rocket_launcher_red"]
	local rocket_damage = table.copy(rocket)
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local dist = solarsail.util.functions.pos_to_dist(pos, ppos)
		if dist < 4.01 then
			if player == self._player_ref then
				rocket_damage._damage = rocket._damage/2.5
				weapons.handle_damage(rocket_damage, self._player_ref, player, dist)
			else
				dist = solarsail.util.functions.pos_to_dist(self._player_ref:get_pos(), ppos)
				weapons.handle_damage(rocket_damage, self._player_ref, player, dist)
			end
			-- Add player knockback:
			solarsail.util.functions.apply_explosion_recoil(player, 25, pos)
		end
	end

	
	rocket_explode_damage_blocks(pos_block)
	for i=1, 25 do
		minetest.add_particle({
			pos = pos,
			velocity = {x=math.random()*2.5, y=math.random()*2.5, z=math.random()*2.5},
			expirationtime = 4,
			collisiondetection = true,
			collision_removal = false,
			texture = "rocket_smoke_"..math.random(1,3)..".png",
			size = math.random(5, 12)
		})
	end
	minetest.sound_play({name="rocket_explode"}, 
		{pos=pos_block, max_hear_distance=64, gain=7}, true)
	if self._loop_sound_ref ~= nil then
		minetest.sound_stop(self._loop_sound_ref)
	end
	self.object:remove()
end

function rocket_ent:on_step(dtime, moveresult)
	if moveresult.collides then
		rocket_ent:explode(self, moveresult)
	elseif self._timer > 15 then
		rocket_ent:explode(self, moveresult)
	end
	self._timer = self._timer + dtime
end

minetest.register_entity("weapons:rocket_ent", rocket_ent)

local launcher_def_red = {
	tiles = {"rocket_launcher.png", {name="assault_class_red.png", 
										backface_culling=true}},
	drawtype = "mesh",
	mesh = "rocket_launcher_fp.b3d",
	use_texture_alpha = true,
	range = 1,
	node_placement_prediction = "",

	_no_reload_hud = true,
	_reload_node = "weapons:rocket_launcher_reload_red",
	_ammo_bg = "rocket_bg",
	_kf_name = "Rocket Launcher",
	_fov_mult = 0.95,
	_crosshair = "railgun_crosshair.png",
	_type = "rocket",
	_ammo_type = "rocket",
	_firing_sound = "rocket_launch",
	_name = "rocket_launcher",
	_mag = 1,
	_rpm = 80,
	_reload = 3,
	_damage = 65,
	_recoil = 0,
	_phys_alt = 1,
	_break_hits = 2,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
}
minetest.register_node("weapons:rocket_launcher_red", launcher_def_red)

local launcher_def_blue = table.copy(launcher_def_red)
launcher_def_blue.tiles = {"rocket_launcher.png", {name="assault_class_blue.png",
													backface_culling=true}}
launcher_def_blue._reload_node = "weapons:rocket_launcher_reload_blue"

minetest.register_node("weapons:rocket_launcher_blue", launcher_def_blue)

local launcher_reload_red = {
	drawtype = "mesh",
	mesh = "rocket_launcher_reload_fp.b3d",
	use_texture_alpha = true,
	range = 1,
	node_placement_prediction = "",
	tiles = {"rocket_launcher.png", "rocket_ent.png",
				{name="assault_class_red.png", backface_culling=true}},

	_no_reload_hud = true,
	_reset_node = "weapons:rocket_launcher_red",
	_ammo_bg = "rocket_bg",
	_kf_name = "Rocket Launcher",
	_damage = 0,
	_mag = 1,
	_fov_mult = 0.95,
	_type = "rocket",
	_ammo_type = "rocket",
	_phys_alt = 0.75,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
}

minetest.register_node("weapons:rocket_launcher_reload_red", launcher_reload_red)

local launcher_reload_blue = table.copy(launcher_reload_red)
launcher_reload_blue.tiles = {"rocket_launcher.png", "rocket_ent.png",
								{name="assault_class_blue.png", backface_culling=true}}
launcher_reload_blue._reset_node = "weapons:rocket_launcher_blue"

minetest.register_node("weapons:rocket_launcher_reload_blue", launcher_reload_blue)