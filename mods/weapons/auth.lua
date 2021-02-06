-- Authentication module for Battle for Arkhos
-- License RESERVED
-- Author Jordach

weapons.auth = nil
local sudo_invoked = false

local function rst_sudo()
	sudo_invoked = false
end

local function grant_sudo_privs(name)
	-- Grants admins all privs for temporary reasons; these are not permanent.
	if name == minetest.settings:get("name") then
		local privs = {}
		for priv, def in pairs(core.registered_privileges) do
			privs[priv] = true
		end
		sudo_invoked = true
		minetest.set_player_privs(name, privs)
		minetest.after(0.2, rst_sudo)
		return true
	end
	return false
end

if true then
	local loaded, wad, file_created = persistence.load_data("weapons_player_auth", true)
	weapons.auth = table.copy(wad)
	wad = nil
end

weapons.auth_handler = {
	get_auth = function(name)
		-- I really doubt this as it's loaded from a persistence db; as it creates an empty table.
		if weapons.auth == nil then
			return nil
		elseif weapons.auth[name] == nil then
			return nil
		else
			return weapons.auth[name]
		end
	end,
	
	create_auth = function(name, password)
		weapons.auth[name] = {}
		weapons.auth[name].password = password
		weapons.auth[name].privileges = {}
		weapons.auth[name].privileges.shout = true
		weapons.auth[name].privileges.interact = true
		weapons.auth[name].last_login = tonumber(os.time())
		persistence.save_data("weapons_player_auth", weapons.auth)
	end,

	delete_auth = function(name)
		weapons.auth[name] = {}
		persistence.save_data("weapons_player_auth", weapons.auth)
		return true
	end,

	set_password = function(name, password)
		weapons.auth[name].password = password
		persistence.save_data("weapons_player_auth", weapons.auth)
		return true
	end,

	set_privileges = function(name, privileges)
		weapons.auth[name].privileges = privileges
		
		if not sudo_invoked then
			persistence.save_data("weapons_player_auth", weapons.auth)
		end
		return true
	end,

	reload = function()
		return true
	end,

	record_login = function(name)
		weapons.auth[name].last_login = tonumber(os.time())
		persistence.save_data("weapons_player_auth", weapons.auth)
		return true
	end,

	iterate = function()
		return pairs(weapons.auth)
	end
}

minetest.register_authentication_handler(weapons.auth_handler)
minetest.log("action", "[Weapons] weapons/auth.lua registered and loaded authentication for world-persistent logins.")

minetest.register_chatcommand("sudo", {
	--params = "N/A",
	description = "Grants the username as defined in minetest.conf temporary admin privs.",
	func = function(name)
		if grant_sudo_privs(name) then
			minetest.log("warning", name .. " has been granted temporary privs.")
			return true, "Temporary admin and server privs granted. With great power, comes great responsibility."
		else
			minetest.log("warning", name .. " is not in the minetest.conf. This incident will be reported.")
			return false, weapons.get_nick(minetest.get_player_by_name(name)) .. " is not in the minetest.conf. This incident will be reported."
		end
	end,
})