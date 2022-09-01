-- Particulate
-- A mod to create cubic or other worldly shaped particles in the same vein as the Irrlicht ones.
-- License: MIT
-- Author: Jordach

particulate = {}
particulate.known_particles = {}

function particulate.register_cubic_particle(name, definition, physics, factor, sound_name, sound_def, register)
	local reg_ent
	if register == nil then
		reg_end = false
	else
		reg_end = register
	end

	local def = table.copy(definition)
	def.visual = "mesh"
	def.mesh = "particulate_cubic.obj"
	local onstep = particulate["prefab_"..physics.."_particle"](factor) 
	def.on_step = onstep
	def._physics = physics
	def._factor = factor
	def._sound_name = sound_name
	def._sound_def = table.copy(sound_def)
	def._timer = 0
	def.collisionbox = {-0.05, -0.05, -0.05, 0.05, 0.05, 0.05}
	def.visual_size = {x=1, y=1}
	def.use_texture_alpha = true
	def.physical = true
	def.collide_with_objects = false
	def.pointable = false
	particulate.known_particles = table.copy(def)
	minetest.register_entity(":"..name, table.copy(def))
end

function particulate.calc_collisionbox_size(scale)
	local size = 0.05 * scale
	return {-size, -size, -size, size, size, size}, size
end

--[[
	pos, size_min, size_max, vel_min, vel_max, del_min, del_max	

	Pointed Velocity Logic:

	North Facing: intersection_normal.z == -1; vdepth <= 0; x + y
	South Facing: intersection_normal.z == 1; vdepth >= 0; x + y

	East Facing: intersection_normal.x == -1; vdepth <= 0; z + y
	West Facing: intersection_normal.x == 1; vdepth >= 0; z + y

	Bot Facing: intersection_normal.y == -1; vdepth <= 0; x + z
	Top Facing: intersection_normal.y == 1; vdepth >= 0; x + z

]]--

function particulate.spawn_particles(name, number, spawn_props, pointed, textures, destroyed)
	for i=1, number do
		local px, py, pz = 0, 0, 0
		local vx, vy, vz = 0, 0, 0
		local vel = vector.new(0, 0, 0)
		local vdepth, vsides, vhight = 0, 0, 0
		local scale = math.random(spawn_props.size_min*100, spawn_props.size_max*100) / 100
		local coll_box, doffset = particulate.calc_collisionbox_size(scale)
		local rot = vector.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
		doffset = doffset + 0.01
		if pointed == nil then
			vdepth = math.random(spawn_props.vel_min*100, spawn_props.vel_max*100) / 100
			vhight = math.random(spawn_props.vel_min*100, spawn_props.vel_max*100) / 100
			vsides = math.random(spawn_props.vel_min*100, spawn_props.vel_max*100) / 100
			if destroyed then
				px = spawn_props.pos.x + 0.5
				py = spawn_props.pos.y + 0.5
				pz = spawn_props.pos.z + 0.5
				vhight = math.random(spawn_props.del_min*100, spawn_props.del_max*100) / 100
				rot = vector.new(90 * math.random(0, 3), 0, 0)
			else
				px = spawn_props.pos.x + (math.random(-105, 105) / 100)
				py = spawn_props.pos.y + (math.random(-105, 105) / 100)
				pz = spawn_props.pos.z + (math.random(-105, 105) / 100)
			end

			vel = vector.new(vsides, vhight, vdepth)
		else
			local pos_floor = table.copy(pointed.under)
			px = spawn_props.pos.x + (math.random(-5, 5) / 100)
			py = spawn_props.pos.y + (math.random(-5, 5) / 100)
			pz = spawn_props.pos.z + (math.random(-5, 5) / 100)

			vdepth = math.random(spawn_props.del_min*100, spawn_props.del_max*100) / 100
			vsides = math.random(spawn_props.vel_min*100, spawn_props.vel_max*100) / 100
			vhight = math.random(spawn_props.vel_min*100, spawn_props.vel_max*100) / 100

			if pointed.intersection_normal.x == -1 then
				vel = vector.new(-vdepth, vsides, vhight)
				px = spawn_props.pos.x - doffset
			elseif pointed.intersection_normal.x == 1 then
				vel = vector.new(vdepth, vsides, vhight)
				px = spawn_props.pos.x + doffset
			elseif pointed.intersection_normal.y == -1 then
				vel = vector.new(vsides, -vdepth, vhight)
				py = spawn_props.pos.y - doffset
			elseif pointed.intersection_normal.y == 1 then
				vel = vector.new(vsides, vdepth, vhight)
				py = spawn_props.pos.y + doffset
			elseif pointed.intersection_normal.z == -1 then
				vel = vector.new(vsides, vhight, -vdepth)
				pz = spawn_props.pos.z - doffset
			elseif pointed.intersection_normal.z == 1 then
				vel = vector.new(vsides, vhight, vdepth)
				pz = spawn_props.pos.z + doffset
			end
		end

		local pos = vector.new(px, py, pz)
		local ent = minetest.add_entity(pos, name)
		ent:set_acceleration({x=0, y=-9.80, z=0})
		ent:set_rotation(rot)
		ent:set_velocity(vel)
		ent:set_properties(
			{
				visual_size = {x=scale, y=scale},
				collisionbox = coll_box,
				textures = textures
			}
		)
	end
end

function particulate.prefab_bouncing_particle(factor)
	local function onstep(self, dtime, moveresult)
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
				velocity.x = -(old_vel.x * factor)
				velocity.y = old_vel.y
				velocity.z = old_vel.z
				minetest.sound_play({name = self._sound_name}, 
					{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
			elseif moveresult.collisions[1].axis == "y" then
				velocity.x = old_vel.x
				velocity.y = -(old_vel.y * factor)
				velocity.z = old_vel.z
				if math.abs(old_vel.y) > 0.38 then
					minetest.sound_play({name = self._sound_name}, 
						{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
				end
			elseif moveresult.collisions[1].axis == "z" then
				velocity.x = old_vel.x
				velocity.y = old_vel.y
				velocity.z = -(old_vel.z * factor)
				minetest.sound_play({name = self._sound_name}, 
					{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
			end
			self.object:set_velocity(velocity)
		end
	
		-- local norm = self.object:get_velocity()
		-- norm.x = norm.x * 0.66
		-- norm.y = norm.y * 0.66
		-- norm.z = norm.z * 0.66
		-- rot.z = rot.z + ((norm.x + norm.z) / 3)
		--self.object:set_rotation(rot)

		if self._timer > self._ttl then
			if math.random(1, 10) == 1 then
				self.object:remove()
			end
		end

		if self._timer > self._ttl_max then
			self.object:remove()
		end
		self._timer = self._timer + dtime
	end

	return onstep
end

function particulate.prefab_bouncing_alt_particle(factor)
	local function onstep(self, dtime, moveresult)
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
				velocity.x = -(old_vel.x * factor)
				velocity.y = old_vel.y
				velocity.z = old_vel.z
				minetest.sound_play({name = self._sound_name}, 
					{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
			elseif moveresult.collisions[1].axis == "y" then
				velocity.x = old_vel.x
				velocity.y = -(old_vel.y * factor)
				velocity.z = old_vel.z
				if math.abs(old_vel.y) > 0.38 then
					minetest.sound_play({name = self._sound_name}, 
						{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
				end
			elseif moveresult.collisions[1].axis == "z" then
				velocity.x = old_vel.x
				velocity.y = old_vel.y
				velocity.z = -(old_vel.z * factor)
				minetest.sound_play({name = self._sound_name}, 
					{object=self.object, max_hear_distance=self._sound_def.dist, gain=self._sound_def.gain}, true)
			end
			self.object:set_velocity(velocity)
		end
	
		-- local norm = self.object:get_velocity()
		-- norm.x = norm.x * 0.66
		-- norm.y = norm.y * 0.66
		-- norm.z = norm.z * 0.66
		-- rot.z = rot.z + ((norm.x + norm.z) / 3)
		--self.object:set_rotation(rot)
	
		-- if self._timer > self._effect_timer then
		-- 	local props = self.object:get_properties()
		-- 	if props == nil then
		-- 		return
		-- 	elseif props.visual_size == nil then
		-- 		return
		-- 	end
			
		-- 	props.visual_size.x = props.visual_size.x * 0.985
		-- 	props.visual_size.y = props.visual_size.y * 0.985
		-- 	props.visual_size.z = props.visual_size.z * 0.985
			
		-- 	props.collisionbox = particulate.calc_collisionbox_size(props.visual_size.x)
		-- 	--self.object:set_properties(props)
		-- end

		if self._timer > self._ttl then
			if math.random(1, 10) == 1 then
				self.object:remove()
			end
		end

		if self._timer > self._ttl_max then
			self.object:remove()
		end
		self._timer = self._timer + dtime
	end

	return onstep
end

function particulate.prefab_smoke_particle(factor)
	local function onstep(self, dtime, moveresult)
		--local rot = self.object:get_rotation()
		--local norm = self.object:get_velocity()
		--norm.x = norm.x * 0.66
		--norm.y = norm.y * 0.66
		--norm.z = norm.z * 0.66
		--rot.z = rot.z + ((norm.x + norm.z + norm.y) / 15)
		--self.object:set_rotation(rot)
	
		--local props = self.object:get_properties()
		--if props == nil then
		--	return
		--elseif props.visual_size == nil then
		--	return
		--end
		
		-- props.visual_size.x = props.visual_size.x * 1.007
		-- props.visual_size.y = props.visual_size.y * 1.007
		-- props.visual_size.z = props.visual_size.z * 1.007
		--self.object:set_properties(props)
	
		if self._timer > self._ttl then
			if math.random(1, 10) == 1 then
				self.object:remove()
			end
		end

		if self._timer > self._ttl_max then
			self.object:remove()
		end
		self._timer = self._timer + dtime
	end
	return onstep
end

--[[

	Spawn Props:

	vel.x/y/z initial and only velocity
	pos.x/y/z position to be created at
	offset_min, offset_max the random value that affects the spawn position by
	vel_min, vel_max the random value that affects the given initial velocity
	size_min, size_max the random values that affects the given size and collision box
]]--

function particulate.spawn_gas_particles(name, number, spawn_props, textures)
	for i=1, number do
		local npos = table.copy(spawn_props.pos)
		npos.x = npos.x + math.random(spawn_props.offset_min*100, spawn_props.offset_max*100) / 100
		npos.y = npos.y + math.random(spawn_props.offset_min*100, spawn_props.offset_max*100) / 100
		npos.z = npos.z + math.random(spawn_props.offset_min*100, spawn_props.offset_max*100) / 100

		local nvel = table.copy(spawn_props.vel)
		nvel.x = nvel.x + math.random(spawn_props.vel_min*100, spawn_props.vel_max*100) / 100
		nvel.y = nvel.y + math.random(spawn_props.vel_min*100, spawn_props.vel_max*100) / 100
		nvel.z = nvel.z + math.random(spawn_props.vel_min*100, spawn_props.vel_max*100) / 100

		local nrot = vector.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))

		local scale = math.random(spawn_props.size_min*100, spawn_props.size_max*100) / 100
		local coll_box, doffset = particulate.calc_collisionbox_size(scale)
		local ent = minetest.add_entity(npos, name)
		ent:set_velocity(nvel)
		ent:set_rotation(nrot)
		ent:set_properties({
			visual_size = {x=scale, y=scale},
			collisionbox = coll_box,
			textures = textures
		})
	end
end