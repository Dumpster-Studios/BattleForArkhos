-- Player Body for Super CTF:
-- Author: Jordach
-- License: Reserved

local ent = {
	visual = "mesh",
	mesh = "player_body.x",
	textures = {"transparent.png"},
	physical = false,
	backface_culling = false,
	collide_with_objects = false,
	visual_size = {x=1.05, y=1.05},
	pointable = false,
}

minetest.register_entity("weapons:player_body", ent)