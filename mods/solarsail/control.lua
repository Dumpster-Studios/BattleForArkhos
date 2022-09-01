-- SolarSail Engine Control Handler:
-- Author: Jordach
-- License: Reserved

--[[ solarsail.controls.focus[player_name]
	Valid values, should be read only (but set by a authoritive script):

	"talk" all controls are used to handle talking to NPCs, ie dialog options
	"world" all controls are used to control the player when in the world
	"menu" all controls are used to change the cursor in a menu
	"battle" all controls are used to handle battle, behaves like "menu"
	"cutscene" all controls aren't used, but pressing jump can skip things

--]]
solarsail.controls.focus = {}

--[[ solarsail.controls.player[player_name]
	Read only:
	Gets the player:get_player_control() result for [player_name]
]]--
solarsail.controls.player = {}
solarsail.controls.player_last = {}
solarsail.controls.template = {
	up = false,
	down = false,
	left = false,
	right = false,
	jump = false,
	aux1 = false,
	sneak = false,
	dig = false,
	place = false,
	LMB = false,
	RMB = false,
	zoom = false
}

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		-- This runs the risk of walking into a boolean key
		-- but since strings are not booleans this should
		-- be fine under "normal" circumstances.
		if solarsail.controls.player[pname] == nil then
			solarsail.controls.player_last[pname] = table.copy(solarsail.controls.template)
		else
			solarsail.controls.player_last[pname] = table.copy(solarsail.controls.player[pname])
		end
		solarsail.controls.player[pname] = player:get_player_control()
	end
end)

minetest.register_on_joinplayer(function(player)
	solarsail.controls.focus[player:get_player_name()] = "world"
end)