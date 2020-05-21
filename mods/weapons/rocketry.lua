-- Rocket Science for Super CTF:
-- Author: Jordach
-- License: Reserved

local rocket_ent = {
	visual = "mesh",
	mesh = "rocket_ent.obj",
	textures = {
		"core_cobble.png",
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
	local rocket = minetest.registered_nodes["weapons:assault_rifle_alt_red"]
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

	
	worldedit.sphere(pos_block, 1, "air", false)
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