-- SolarSail Engine Sava Data Handling:
-- Author: Jordach
-- License: Reserved

solarsail.save_data = minetest.get_mod_storage()
solarsail.game = {}

--[[ solarsail.game.save()

Saves all game data to disk, includes other players connected to the server.
]]

--[[ solarsail.game.set_spawn(player, pos)

Set's a players world location. Used on connection
in multiplayer mode and when loading a save in singleplayer.

If pos is set to nil it will use player:get_pos(). However,
if a pos table is supplied in {x=0 , y=0, z=0} format,
it will use that instead of the player's current position.s
]]