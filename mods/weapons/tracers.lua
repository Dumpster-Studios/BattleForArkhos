-- Tracers for Super CTF:
-- Author: Jordach
-- License: Reserved

local function register_tracer(name)
	local ent_table = {
		visual = "mesh",
		mesh = "tracer_" .. name .. ".obj",
		textures = {"tracer.png"},
		glow = -1,
		physical = true,
		collide_with_objects = false,
		pointable = false,
		collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		visual_scale = {x=1, y=1},
	}

	function ent_table:on_step(dtime, moveresult)
		if moveresult.collides then
			self.object:remove()
		end
	end

	minetest.register_entity("weapons:tracer_" .. name, ent_table)
end

register_tracer("ar")
register_tracer("railgun")
register_tracer("shotgun")
register_tracer("smg")
register_tracer("smg_alt")