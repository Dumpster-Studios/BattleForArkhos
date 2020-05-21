-- SolarSail Engine
-- Author: Jordach
-- License: Reserved

-- Primary Namespaces:

solarsail = {}

solarsail.skybox = {}
solarsail.camera = {}
solarsail.controls = {}
solarsail.player = {}
solarsail.npc = {}
solarsail.battle = {}
solarsail.hud = {}
solarsail.cosmetic = {}
solarsail.color = {}
solarsail.util = {}
solarsail.util.clipboard = {}
solarsail.util.functions = {}

-- Handle flat mapgen, for building a world

minetest.register_node("solarsail:wireframe", {
	description = "Wireframe, prototyping node",
	tiles = {"solarsail_wireframe.png"},
	groups = {debug=1}
})

--minetest.register_alias("mapgen_stone", "solarsail:wireframe")
--minetest.register_alias("mapgen_grass", "solarsail:wireframe")
--minetest.register_alias("mapgen_water_source", "solarsail:wireframe")
--minetest.register_alias("mapgen_river_water_source", "solarsail:wireframe")

-- Sava data handling (per-player):

dofile(minetest.get_modpath("solarsail").."/save.lua")

-- HSVA->RGBA->HSVA handling:

dofile(minetest.get_modpath("solarsail").."/colour.lua")

-- HUD rendering and formspec handling:

dofile(minetest.get_modpath("solarsail").."/hud.lua")

-- Cameras used in dialog, cutscenes or when controlled by the player:

--dofile(minetest.get_modpath("solarsail").."/camera.lua")

-- Start skybox engine:

--dofile(minetest.get_modpath("solarsail").."/skybox.lua")

-- Control handling for HUDs, player entity, etc:

dofile(minetest.get_modpath("solarsail").."/control.lua")

-- Third person player camera handling + third person model:

dofile(minetest.get_modpath("solarsail").."/player.lua")

-- Basic, advanced NPC AI;

--dofile(minetest.get_modpath("solarsail").."/npc.lua")

-- Player menus:

--dofile(minetest.get_modpath("solarsail").."/menu.lua")