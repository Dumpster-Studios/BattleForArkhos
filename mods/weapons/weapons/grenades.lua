-- Grenades for Super CTF:
-- Author: Jordach
-- License: Reserved

local bounce_factor = 0.44

local function register_grenade(name, class, killfeed_name, stats)
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
		_timer = 0,
		_player_ref = nil,
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

	local copy_stats = table.copy(stats)

	local grenade_node = {
		_grenade_type = name,
		_reload_node = "weapons:"..name.."_grenade_reload_red",
		_kf_name = killfeed_name .. " Grenade",
		_grenade_ent = "weapons:"..name.."_grenade_ent",
		_mag = copy_stats._mag,
		_reload = copy_stats._reload,
		_damage = copy_stats._damage,
		_name = name .. "_grenade",

		drawtype = "mesh",
		mesh = name .. "_grenade.b3d",
		tiles = {"grenade.png", class.."_class_red.png"},
		range = 1,
		node_placement_prediction = "",

		_crosshair = "railgun_crosshair.png",
		_type = "grenade",
		_ammo_type = "grenade",
		_ammo_bg = "grenade_bg",
		_fov_mult = 0,
		_rpm = 200,
		_pellets = 1,
		_recoil = 0,
		_no_reload_hud = true,
		_phys_alt = 1,

		on_place = function(itemstack, placer, pointed_thing)
			return itemstack
		end,
		on_drop = function(itemstack, dropper, pointed_thing)
			return itemstack
		end
	}

	local grenade_reload = {
		_reset_node = "weapons:"..name.."_grenade_red",
		_kf_name = killfeed_name .. " Grenade",
		
		drawtype = "mesh",
		mesh = "grenade_reload.b3d",
		tiles = {class.."_class_red.png"},
		range = 1,
		node_placement_prediction = "",

		_ammo_bg = "grenade",
		_fov_mult = 0,
		_crosshair = "railgun_crosshair.png",
		_type = "grenade",
		_ammo_type = "grenade",
		_phys_alt = 1,
		_no_reload_hud = true,

		on_place = function(itemstack, placer, pointed_thing)
			return itemstack
		end,
		on_drop = function(itemstack, dropper, pointed_thing)
			return itemstack
		end
	}

	function grenade_node.on_fire(player, weapon)
		local gren_pos = vector.add(
			vector.add(player:get_pos(), vector.new(0, 1.64, 0)), 
				vector.multiply(player:get_look_dir(), 1)
		)

		local gren_vel = vector.add(
				vector.multiply(player:get_look_dir(), 12), vector.new(0, 0, 0)
			)
		local ent = minetest.add_entity(gren_pos, weapon._grenade_ent)
		local luaent = ent:get_luaentity()
		luaent._player_ref = player
		
		ent:set_velocity(gren_vel)
		local look_vertical = player:get_look_vertical()
		local look_horizontal = player:get_look_horizontal()
		ent:set_rotation(vector.new(-look_vertical, look_horizontal, 0))
		ent:set_acceleration({x=0, y=-9.80, z=0})
		if weapon._grenade_type == "frag" then
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
					minvel = vector.new(-1, 0.1, -1),
					maxvel = vector.new(1, 0.75, 1),
					minacc = vector.new(0,0,0),
					maxacc = vector.new(0,0,0),
					minsize = 7,
					maxsize = 12,
					minexptime = 2,
					maxexptime = 6
				})
			end
		end
	end

	local gren_blue = table.copy(grenade_node)
	local gren_blue_rel = table.copy(grenade_reload)

	minetest.register_node("weapons:"..name.."_grenade_red", grenade_node)
	minetest.register_node("weapons:"..name.."_grenade_reload_red", grenade_reload)

	gren_blue._reload_node = "weapons:"..name.."_grenade_reload_blue"
	gren_blue.tiles = {"grenade.png", class.."_class_blue.png"}

	gren_blue_rel._reset_node = "weapons:"..name.."_grenade_blue"
	gren_blue_rel.tiles = {class.."_class_blue.png"}
	minetest.register_node("weapons:"..name.."_grenade_blue", gren_blue)
	minetest.register_node("weapons:"..name.."_grenade_reload_blue", gren_blue_rel)
end

register_grenade("frag", "scout", "Frag", {_reload = 15, _mag = 3, _damage=35, _fuse=4})