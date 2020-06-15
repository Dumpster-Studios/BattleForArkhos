-- Grenades for Super CTF:
-- Author: Jordach
-- License: Reserved

local bounce_factor = 0.44

local function register_grenade(name, effect)
	local ent_table = {
		visual = "mesh",
		mesh = "grenade_" .. name .. ".obj",
		textures = {"grenade.png"},
		physical = true,
		collide_with_objects = true,
		pointable = false,
		visual_size = {x=6, y=6},
		collisionbox = {-0.15, -0.15, -0.15, 0.15, 0.15, 0.15},
		_type = name,
		_fuse_started = false,
		_fuse = 20,
		_timer = 0
	}

	function ent_table:smoke_grenade(self)

	end

	function ent_table:heal_grenade(self)
	
	end

	function ent_table:frag_grenade(self)
		minetest.chat_send_all("this is a frag grenade")
		self.object:remove()
	end

	function ent_table:on_step(dtime, moveresult)
		local rot = self.object:get_rotation()
		local velocity = {x=0, y=0, z=0}
		if moveresult.collides then
			local old_vel 
			-- Check for velocities:
			if moveresult.collisions[1] == nil then
				old_vel = self.object:get_velocity()
			else
				old_vel = table.copy(moveresult.collisions[1].old_velocity)
			end

			-- Handle air resistance, friction:
			if moveresult.touching_ground then
				old_vel.x = old_vel.x * 0.6
				old_vel.z = old_vel.z * 0.6
			else
				old_vel.x = old_vel.x * 0.975
				old_vel.z = old_vel.z * 0.975
			end

			if moveresult.collisions[1] == nil then
				if not moveresult.touching_ground then
					velocity.x = old_vel.x
					velocity.z = old_vel.z
				end
				velocity.y = old_vel.y
			elseif moveresult.collisions[1].axis == "x" then
				velocity.x = -(old_vel.x * bounce_factor)
				velocity.y = old_vel.y
				velocity.z = old_vel.z
			elseif moveresult.collisions[1].axis == "y" then
				velocity.x = old_vel.x
				velocity.y = -(old_vel.y * bounce_factor)
				velocity.z = old_vel.z
			elseif moveresult.collisions[1].axis == "z" then
				velocity.x = old_vel.x
				velocity.y = old_vel.y
				velocity.z = -(old_vel.z * bounce_factor)
			end

			-- Rotate object for rolling and shit:
			local xz, y = solarsail.util.functions.get_3d_angles(
				vector.new(0, 0, 0), velocity
			)
			rot.y = xz + math.rad(0)

			self.object:set_velocity(velocity)
			if not self._fuse_started then
				self._fuse_started = true
			end
		end

		
		local norm = vector.normalize(self.object:get_velocity())
		rot.x = rot.x + ((norm.x + norm.z) / 3)
		self.object:set_rotation(rot)

		if self._fuse_started then
			self._timer = self._timer + dtime
			if self._timer > self._fuse then
				if self._type == "smoke" then
					self:smoke_grenade(self)
				elseif self._type == "frag" then
					self:frag_grenade(self)
				elseif self._type == "heal" then
					self:heal_grenade(self)
				end
			end
		end
	end
	
	minetest.register_entity("weapons:".. name .."_grenade_ent", ent_table)
end

register_grenade("frag")

minetest.register_node("weapons:frag_grenade_red", {
	drawtype = "mesh",
	mesh = "frag_grenade.b3d",
	tiles = {"grenade.png", "scout_class_red.png"},
	range = 1,
	node_placement_prediction = "",

	_grenade_type = "frag",
	_ammo_bg = "grenade_bg",
	_reload_node = "weapons:frag_grenade_reload_red",
	_kf_name = "Frag Grenade",
	_fov_mult = 0,
	_crosshair = "railgun_crosshair.png",
	_type = "grenade",
	_grenade_ent = "weapons:frag_grenade_ent",
	_ammo_type = "grenade",
	_name = "frag_grenade",
	_pellets = 1,
	_mag = 3,
	_rpm = 150,
	_reload = 15,
	_no_reload_hud = true,
	_damage = 35,
	_recoil = 0,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})

minetest.register_node("weapons:frag_grenade_reload_red", {
	drawtype = "mesh",
	mesh = "grenade_reload.b3d",
	tiles = {"scout_class_red.png"},
	range = 1,
	node_placement_prediction = "",

	_reset_node = "weapons:frag_grenade_red",
	_ammo_bg = "grenade",
	_kf_name = "Frag Grenade",
	_fov_mult = 0,
	_crosshair = "railgun_crosshair.png",
	_type = "grenade",
	_ammo_type = "grenade",
	_phys_alt = 1,
	_no_reload_hud = true
})

minetest.register_node("weapons:frag_grenade_blue", {
	drawtype = "mesh",
	mesh = "frag_grenade.b3d",
	tiles = {"grenade.png", "scout_class_blue.png"},
	range = 1,

	_grenade_type = "frag",
	_ammo_bg = "grenade_bg",
	_reload_node = "weapons:frag_grenade_reload_blue",
	_kf_name = "Frag Grenade",
	_fov_mult = 0,
	_crosshair = "railgun_crosshair.png",
	_type = "grenade",
	_grenade_ent = "weapons:frag_grenade_ent",
	_ammo_type = "grenade",
	_name = "frag_grenade",
	_pellets = 1,
	_mag = 3,
	_rpm = 150,
	_reload = 15,
	_no_reload_hud = true,
	_damage = 35,
	_recoil = 0,

	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
	on_drop = function(itemstack, dropper, pointed_thing)
		return itemstack
	end
})

minetest.register_node("weapons:frag_grenade_reload_blue", {
	drawtype = "mesh",
	mesh = "grenade_reload.b3d",
	tiles = {"scout_class_blue.png"},
	range = 1,
	node_placement_prediction = "",

	_reset_node = "weapons:frag_grenade_blue",
	_ammo_bg = "grenade",
	_kf_name = "Frag Grenade",
	_fov_mult = 0,
	_crosshair = "railgun_crosshair.png",
	_type = "grenade",
	_ammo_type = "grenade",
	_phys_alt = 1,
	_no_reload_hud = true
})