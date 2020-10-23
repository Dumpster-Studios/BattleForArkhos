-- Entity Arms for Super CTF:
-- Author: Jordach
-- License: Reserved

-- FoV change in 12 frames (0.2s):

local ent = {
	visual = "mesh",
	mesh = "assault_arms.x",
	textures = {"transparent.png", "assault_rifle.png"},
	physical = false,
	backface_culling = false,
	collide_with_objects = false,
	visual_size = {x=1.05, y=1.05},
	pointable = false,
	_texture = "assault_rifle.png",
}

minetest.register_entity("weapons:assault_arms", ent)