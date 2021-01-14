-- Grenades for Super CTF:
-- Author: Jordach
-- License: Reserved

local bounce_factor = 0.55

local smoke_ent = {
	visual = "sprite",
	physical = false,
	collide_with_objects = false,
	textures = {
		"transparent.png"
	}
}

minetest.register_entity("weapons:smoke_ent", smoke_ent)

local function explosion_tracers(pos)
	for i=16,  math.random(30) do
		local vector_mod = vector.new(
								math.random(-100, 100)/100,
								math.random(-100, 100)/100,
								math.random(-100, 100)/100
		)
		if moveresult == nil then
		elseif moveresult.touching_ground then
			vector_mod.y = math.random(1, 100)/100
		end			
							
		local rayend = vector.add(pos, vector_mod)
		-- Tracers; performance heavy?
		local tracer_vel = vector.multiply(vector.direction(pos, rayend), 45)
		local xz, y = solarsail.util.functions.get_3d_angles(pos, rayend)
		local ent = minetest.add_entity(vector.add(pos, vector.new(0, 0.16, 0)),
			"weapons:tracer_shotgun")

		ent:set_velocity(tracer_vel)
		ent:set_rotation(vector.new(y, xz, 0))
		ent:set_properties({collide_with_objects = false})
	end
end

local function instant_smoke(pos)
	for i=1, 3 do
		minetest.add_particlespawner({
			amount = math.random(6, 12),
			time = 0.03,
			texture = "rocket_smoke_" .. i .. ".png",
			collisiondetection = false,
			collision_removal = false,
			object_collision = false,
			vertical = false,
			minpos = vector.new(pos.x,pos.y+0.05,pos.z),
			maxpos = vector.new(pos.x,pos.y+0.05,pos.z),
			minvel = vector.new(-2, 0.1, -2),
			maxvel = vector.new(2, 1, 2),
			minacc = vector.new(0,0,0),
			maxacc = vector.new(0,0,0),
			minsize = 20,
			maxsize = 40,
			minexptime = 2,
			maxexptime = 4
		})
	end
end

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
		_fuse = stats._fuse,
		_timer = 0,
		_player_ref = nil,
		_delay_timer = 0,
		_delay_fuse = stats._delay,
		_invis_ent = nil,
	}

	function ent_table:smoke_grenade(self)
		local pos = self.object:get_pos()
		local pmin = vector.new(-0.05, -0.05, -0.05)
		local pmax = vector.new(0.05, 0.05, 0.05)
		local ent = minetest.add_entity(pos, "weapons:smoke_ent")
		self._invis_ent = ent
		for i=1, 3 do
			minetest.add_particlespawner({
				attached = self._invis_ent,
				amount = 25,
				time = 0,
				texture = "rocket_smoke_" .. i .. ".png",
				collisiondetection = false,
				collision_removal = false,
				object_collision = false,
				vertical = false,
				minpos = pmin,
				maxpos = pmax,
				minvel = vector.new(-0.25, 0.25, -0.25),
				maxvel = vector.new(0.25, 0.5, 0.25),
				minacc = vector.new(0,0,0),
				maxacc = vector.new(0,0,0),
				minsize = 20,
				maxsize = 32,
				minexptime = 2,
				maxexptime = 8
			})
		end
		local vec = vector.new(0,0,0)
	end

	function ent_table:heal_grenade(self)
		self.object:remove()
	end

	function ent_table:frag_grenade(self, moveresult)
		local pos = self.object:get_pos()
		local grenade = minetest.registered_nodes["weapons:frag_grenade_red"]
		
		minetest.after(0.03, explosion_tracers, pos)
		minetest.after(0.03, instant_smoke, pos)

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
				old_vel.x = old_vel.x * 0.75
				old_vel.z = old_vel.z * 0.75
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
			if self._fuse_started == nil then
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
					self._delay_started = true
				elseif self._type == "frag" then
					self:frag_grenade(self, moveresult)
				elseif self._type == "heal" then
					self:heal_grenade(self)
				end
			end
		end

		if self._delay_started then
			self._fuse_started = false
			self._delay_timer = self._delay_timer + dtime
			
			if self._type == "smoke" then
				local ent_pos = vector.add(self.object:get_pos(), vector.new(0,0.1,0))
				self._invis_ent:set_pos(ent_pos)
			end
			if self._delay_timer > self._delay_fuse then
				if self._type == "smoke" then
					self._invis_ent:remove()
				end
				self.object:remove()
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
		_radius = copy_stats._radius,
		_name = name .. "_grenade",
		_break_hits = 1,

		drawtype = "mesh",
		mesh = name .. "_grenade_fp.b3d",
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

	-- Healing Grenade only.
	if copy_stats.heals == nil then
	else
		grenade_node._heals = copy_stats._heals
	end

	local grenade_reload = {
		_reset_node = "weapons:"..name.."_grenade_red",
		_kf_name = killfeed_name .. " Grenade",
		
		drawtype = "mesh",
		mesh = "grenade_reload_fp.b3d",
		tiles = {class.."_class_red.png"},
		range = 1,
		node_placement_prediction = "",

		_ammo_bg = "grenade",
		_fov_mult = 0,
		_crosshair = "railgun_crosshair.png",
		_ammo_bg = "grenade_bg",
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
			vector.add(player:get_pos(), vector.new(0, weapons.default_eye_height, 0)), 
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

register_grenade("frag", "scout", "Frag", {_reload = 60, _mag = 3, _damage=35, _fuse=4, _radius=2.5})
register_grenade("smoke", "sniper", "Smoke", {_reload = 60, _mag = 1, _damage=10, _fuse=1, _radius=1, _delay=12})
register_grenade("heal", "medic", "Heal", {_reload = 60, _mag=2, _damage = 2, _fuse = 2, _radius=4, _heals=45})