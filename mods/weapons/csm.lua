-- CSM handler
-- Author: Jordach
-- License: Reserved

--[[
Modchannels:

A modchannel data is sent as 

0: Indicates that weapon data is being sent
1: Indicates that player data is being sent
2: Indicates that settings data is being sent
3: Indicates that Lua code is being sent over the network
4:
5:
6:
7:
8:
9: Indicates that the client is echoing back a hello message.

]]--

local function compress_and_send(input, player, mode)
	local pname = player:get_player_name()
	local data = minetest.compress(input, "deflate", 9)
	data = mode .. data
end

minetest.register_on_modchannel_message(function(channel_name, sender, message)
	if channel_name == weapons.default_modchannel .. string.lower(sender) then
		if message == "9hello" then
			print("BFA CSM successfully registered.")
			
		else
			minetest.kick_player(sender, "Server disallows other CSMs on this server other than the official Battle for Arkhos one.")
		end
	elseif sender == "" then
	else
		minetest.kick_player(sender, "Server disallows other CSMs on this server other than the official Battle for Arkhos one.")
	end
end)