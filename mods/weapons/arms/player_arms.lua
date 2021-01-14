-- Entity Arms for Super CTF:
-- Author: Jordach
-- License: Reserved

-- FoV change in 12 frames (0.2s):

local ent = {
	visual = "mesh",
	mesh = "assault_arms.x", -- I'd leave this blank but fucking minetest is too smooth brain for that
	textures = {"transparent.png"}, -- so the bigger hack is to fucking use an invisible texture lmao.
	physical = false,
	backface_culling = false,
	collide_with_objects = false,
	visual_size = {x=1.05, y=1.05},
	pointable = false,
}

minetest.register_entity("weapons:player_arms", ent)