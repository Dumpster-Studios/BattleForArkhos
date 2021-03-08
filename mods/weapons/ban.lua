-- Ban module for Battle for Arkhos.
-- License: RESERVED
-- Author: Jordach

-- Layout = {"1.2.3.4" = true or nil}
local ip_bans = {}

-- Layout = {"1.2.3.4" = 0-<ban threshold>}
local attempts = {}

-- Layout = {"Player_Name" = true or false, otherwise nil}
local warn_user = {}

local function remove_ip_ban(ip)
	if ip_bans[ip] then
		ip_bans[ip] = false
	end
end

minetest.register_on_authplayer(function(name, ip, is_success)
	if not is_success then
		if attempts[name] == nil then
			attempts[name] = 1
		else
			attempts[name] = attempts[name] + 1
			-- Ban IP from connecting
			if attempts[name] > 5 then
				minetest.log("warning", ip .. " attempting to brute force username " .. name .. ". Please alert user.")
				ip_bans[ip] = true
				minetest.after(60*10, remove_ip_ban, ip)
				warn_user[name] = true
			end
		end
	end
end)

minetest.register_on_prejoinplayer(function(name, ip)
	for key, value in pairs(ip_bans) do
		if ip == key then 
			if key then
				return "Too many failed login attempts from this IP. You can try again after 10 minutes."
			end
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if warn_user[pname] == nil then
	elseif warn_user[pname] then
		local msg = minetest.colorize("#ff0000", "Caution, failed logins occurred for this username. Change of password recommended")
		minetest.after(2, minetest.chat_send_player, pname, msg)
		minetest.after(4, minetest.chat_send_player, pname, msg)
		warn_user[pname] = false
	end
end)