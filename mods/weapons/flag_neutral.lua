local entity_flag_blue = {
	visual = "mesh",
	textures = {
		"flag_blue.png"
	},
	mesh = "flag.obj",
	physical = true,
	collide_with_objects = false,
	pointable = false,
	collisionbox = {-0.3, 0, -0.3, 0.3, 2, 0.3},

	_set_waypoint = false,
	_timer = -1,
	_carried_by = nil,
	_is_held = false,
	_updated_waypoint = false,
	_team = "blue",
	_booted = true,
	_x = 0,
	_y = 0,
	_z = 0
}

function entity_flag_blue:alert_team()
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if self._team == weapons.player_list[pname].team then
			minetest.chat_send_player(pname,
				self._carried_by:get_player_name() .. " has picked up your flag.")
		end
	end
end

function entity_flag_blue:attach_to_player(player)
	remove_global_waypoint("blue_flag")
	self.object:set_attach(player, "", {x=0,y=0,z=0},{x=0,y=0,z=0})
	self._carried_by = player
	self._is_held = true
	local pname = player:get_player_name()
	if weapons.player_list[pname].team ~= self._team then
		self:alert_team()
	end
	self._set_waypoint = false
	self._x = 0
	self._z = 0
	weapons.clear_inv(player)
	weapons.add_class_items(player, "blue_flag")
	weapons.player.cancel_reload(player)
end

function entity_flag_blue:yeet_flag(velocityy)
	self.object:set_detach()
	local yaw_rad = self._carried_by:get_look_horizontal()
	local pitch_rad = self._carried_by:get_look_vertical()
	self._x, self._z = 
			solarsail.util.functions.yaw_to_vec(yaw_rad, 8, false)
	self._y = (solarsail.util.functions.y_direction(pitch_rad, 10) * -1)
	local pitch_mult = solarsail.util.functions.xz_amount(pitch_rad)
	self._x = self._x * (pitch_mult * 1.55)
	self._z = self._z * (pitch_mult * 1.55)
	velocityy.y = velocityy.y + self._y
	self._timer = 1
	weapons.clear_inv(self._carried_by)
	weapons.add_class_items(self._carried_by, weapons.player_list[self._carried_by:get_player_name()].class)
	self._carried_by = nil
end

function entity_flag_blue:flag_captured(velocityy)
	local blu = 147
	local blu2 = 192-42
	local y = minetest.get_spawn_level(-blu2, -blu2)
	self.object:set_detach()
	self.object:set_pos({x=-blu, y=y+1, z=-blu})
	--self._is_held = false
	velocityy.y = velocityy.y + 1
	weapons.clear_inv(self._carried_by)
	weapons.add_class_items(self._carried_by, weapons.player_list[self._carried_by:get_player_name()].class)
	self._carried_by = nil
	self._timer = 5
end

function entity_flag_blue:drop_flag()
	self.object:set_detach()
	weapons.clear_inv(self._carried_by)
	weapons.add_class_items(self._carried_by, weapons.player_list[self._carried_by:get_player_name()].class)
	self._carried_by = nil
	--self._is_held = false
	velocityy.y = velocityy.y + 2 
	self._timer = 2
end

function entity_flag_blue:on_step(dtime)
	-- apply physics
	local velocityy = self.object:get_velocity()
	local accel = self.object:get_acceleration()
	
	if velocityy.y == 0 then
		-- Handle friction
		self._x = self._x * 0.75
		self._z = self._z * 0.75
	else
		self._x = self._x * 0.99
		self._z = self._z * 0.99
	end

	-- Round down numbers when percentages exponentialise movement:		
	if math.abs(self._x) < 0.01 then self._x = 0 end
	if math.abs(self._z) < 0.01 then self._z = 0 end

	if not self._is_held then
		if self._timer < 0.01 then -- fuck the flag being instantly recaptured
			-- waiting for player to move flag
			for _, player in ipairs(minetest.get_connected_players()) do
				local dist = solarsail.util.functions.pos_to_dist(
					self.object:get_pos(), player:get_pos())
				if weapons.player_list[player:get_player_name()].team == nil then return end
				if weapons.player_list[player:get_player_name()].hp == nil then -- Ignore invalid players
				elseif weapons.player_list[player:get_player_name()].hp < 1 then -- Ignore dead players
				elseif dist < 0.76 then
					self:attach_to_player(player)
					return
				end
			end
		end
	else
		if self._carried_by ~= nil then
			local red = 207-39
			local red2 = 207-42
			local y = minetest.get_spawn_level(red2, red2)
			local dist_to_cap =
				solarsail.util.functions.pos_to_dist(self.object:get_pos(), 
					{x=red, y=y-1, z=red})
			if dist_to_cap < 1 then
				self:flag_captured(velocityy)
				minetest.chat_send_all("Blue Flag Captured")
				return
			end
			local pname = self._carried_by:get_player_name()
			if solarsail.controls.player[pname].RMB == nil then
			elseif solarsail.controls.player[pname].RMB then
				if solarsail.controls.player[pname].sneak == nil then
				elseif solarsail.controls.player[pname].sneak then
					self:yeet_flag(velocityy)
				end
			elseif weapons.player_list[pname].hp < 1 then
				self:drop_flag()
			end
		end

		if self._timer > 0 then
			self._timer = self._timer - 0.01
			if self._timer < 0.01 then
				if self._is_held then
					self._is_held = false
					self._carried_by = nil
				end
			end
		end
	end

	self.object:set_velocity({x=self._x, y=velocityy.y, z=self._z})
	self.object:set_acceleration({x=0, y=-9.80, z=0})

	if velocityy.x == 0 then
		if velocityy.z == 0 then
			if velocityy.y == 0 then
				if not self._is_held then
					if not self._set_waypoint then
						remove_global_waypoint("blue_flag")
						local flag_pos = self.object:get_pos()
						flag_pos.y = flag_pos.y + 2.5
						add_global_waypoint(flag_pos, "blue_flag",
							"Blue Flag", weapons.teams.blue_colour)
						self._set_waypoint = true
					end
				end
			else
				if not self._is_held then
					remove_global_waypoint("blue_flag")
					self._set_waypoint = false
				end
			end
		end
	end
end

minetest.register_entity("weapons:flag_blue", entity_flag_blue)