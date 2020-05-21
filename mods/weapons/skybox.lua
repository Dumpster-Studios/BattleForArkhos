-- Skybox for Super CTF:
-- Author: Jordach
-- License: Reserved

local day_sky = "#c5b7ea"
local day_horizon = "#f0ecff"
local dawn_sky = "#bf9bb4"
local dawn_horizon = "#dec6d7"
local night_sky = "#5400ff"
local night_horizon = "#4f2a9b"
local sun_tint = "#dbbae7"
local moon_tint = "#d37dff"

local cloud_color = "#f3eaf8e7"
local star_color = "#c0c7ffaa"

minetest.register_on_joinplayer(function(player)
	player:set_sky({
		type = "regular",
		clouds = true,
		sky_color = {
			day_sky = day_sky,
			day_horizon = day_horizon,
			dawn_sky = dawn_sky,
			dawn_horizon = dawn_horizon,
			night_sky = night_sky,
			night_horizon = night_horizon,
			fog_sun_tint = sun_tint,
			fog_moon_tint = moon_tint,
			fog_tint_type = "custom"
		}
	})

	player:set_clouds({
		color = cloud_color
	})

	player:set_stars({
		count = 2000,
		star_color = star_color,
		scale = 0.65
	})
end)