-- SolarSail Engine HSVA -> RGBA -> HSVA handling:
-- Author: Jordach
-- License: Reserved

function solarsail.util.functions.hex_is_valid(color)
	local patterns = {"%x%x%x%x%x%x", "%x%x%x", "%x%x%x%x%x%x%x%x"} -- Standard, shortened, alpha
	for _, pat in pairs(patterns) do
		if color:find("^#"..pat.."$") then
			return true
		end
	end
	return false
end

-- Convert between 1000 units and 1.0
function solarsail.util.functions.from_slider_hsv(value)
	value = tonumber(value)
	return value/1000
end
-- ...and back
function solarsail.util.functions.to_slider_hsv(value)
	return value*1000
end

-- HSV -> RGBA and RGBA -> HSV conversions
-- taken from: https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
-- License info for hsv_rgba and rgba_hsv and rgb_hsl: CC-BY 3.0

--[[
	* Converts an HSV color value to RGB. Conversion formula
	* adapted from http://en.wikipedia.org/wiki/HSV_color_space.
	* Assumes h, s, and v are contained in the set [0, 1] and
	* returns r, g, and b in the set [0, 255].
	*
	* @param   Number  h       The hue
	* @param   Number  s       The saturation
	* @param   Number  v       The value
 	* @return  Array           The RGB representation
]]--

function solarsail.util.functions.hsv_rgba(h, s, v, a)
	local r, g, b

	local i = math.floor(h * 6);
	local f = h * 6 - i;
	local p = v * (1 - s);
	local q = v * (1 - f * s);
	local t = v * (1 - (1 - f) * s);
  
	i = i % 6
  
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end
  
	return r * 255, g * 255, b * 255, a * 255
  end
  
--[[
	* Converts an RGB color value to HSV. Conversion formula
	* adapted from http://en.wikipedia.org/wiki/HSV_color_space.
	* Assumes r, g, and b are contained in the set [0, 255] and
	* returns h, s, and v in the set [0, 1].
	*
	* @param   Number  r       The red color value
	* @param   Number  g       The green color value
	* @param   Number  b       The blue color value
	* @return  Array           The HSV representation
]]--

function solarsail.util.functions.rgba_hsv(r, g, b, a)
	r, g, b, a = r / 255, g / 255, b / 255, a / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max
  
	local d = max - min
	if max == 0 then s = 0 else s = d / max end
  
	if max == min then
	  h = 0 -- achromatic
	else
	  if max == r then
	  h = (g - b) / d
	  if g < b then h = h + 6 end
	  elseif max == g then h = (b - r) / d + 2
	  elseif max == b then h = (r - g) / d + 4
	  end
	  h = h / 6
	end
  
	return h, s, v, a
end

local hud_ref = {}
hud_ref.hue = {}
hud_ref.sat = {}
hud_ref.val = {}
hud_ref.alpha = {}

--[[ solarsail.color.rgba
	Read only; to be used as temporary memory for storing custom colours in.
]]
solarsail.color.rgba = {}

function solarsail.util.functions.get_hsva_formspec(player, pos)
	local name = player:get_player_name()
	local rgba = table.copy(solarsail.color.rgba[name])

	local h, s, v, a = solarsail.util.functions.rgba_hsv(rgba.r, rgba.g, rgba.b, rgba.a)
	local curr_rgb = minetest.rgba(rgba.r, rgba.g, rgba.b)

	local min_sat = minetest.rgba(solarsail.util.functions.hsv_rgba(h, 0, v, a))
	local max_sat = minetest.rgba(solarsail.util.functions.hsv_rgba(h, 1, v, a))

	local min_val = minetest.rgba(solarsail.util.functions.hsv_rgba(h, s, 0, a))
	local max_val = minetest.rgba(solarsail.util.functions.hsv_rgba(h, s, 1, a))
	
	local smin = minetest.formspec_escape("(solarsail_ui_gradient.png^[multiply:"..min_sat..")^")
	local smax = minetest.formspec_escape("(solarsail_ui_gradient_flip.png^[multiply:"..max_sat..")")

	local vmin = minetest.formspec_escape("(solarsail_ui_gradient.png^[multiply:"..min_val..")^")
	local vmax = minetest.formspec_escape("(solarsail_ui_gradient_flip.png^[multiply:"..max_val..")")

	local alp = minetest.formspec_escape("solarsail_ui_gradient_flip.png^[multiply:"..curr_rgb)
	local formspec = "container["..pos.x..","..pos.y.."]"..
		-- HSV sliders
		"label[0.28,0;Hue: "..string.format("%.2f", tostring(h)).."]"..
		"background9[0.28, 0.25;4.44, 0.8;solarsail_hsv_spectrum.png;false;1,1]".. -- +0.25 from label, +0.5 from label
		"scrollbar[0,0.5;5,0.3;horizontal;h;"..tostring(solarsail.util.functions.to_slider_hsv(h))..";false]"..

		"label[0.28,1.3;Saturation: "..string.format("%.2f", tostring(s)).."]".. -- +0.5 from scrollbar
		"background9[0.28,1.55;4.44,0.8;".. smin .. smax ..";false;1,1]" ..
		"scrollbar[0,1.8;5,0.3;horizontal;s;"..tostring(solarsail.util.functions.to_slider_hsv(s)).."]"..

		"label[0.28,2.6;Value: "..string.format("%.2f", tostring(v)).."]"..
		"background9[0.28,2.85;4.44,0.8;".. vmin .. vmax .. ";false;1,1]"..
		"scrollbar[0,3.1;5,0.3;horizontal;v;"..tostring(solarsail.util.functions.to_slider_hsv(v)).."]"..

		"label[0.28,3.9;Alpha: "..string.format("%.2f", tostring(a)).."]"..
		"background9[0.28,4.15;4.44,0.8;"..alp..";false;1,1]"..
		"scrollbar[0,4.4;5,0.3;horizontal;a;"..tostring(solarsail.util.functions.to_slider_hsv(a)).."]"..
		"container_end[]"
	return formspec
end

minetest.register_chatcommand("colortag", {
	params = "demo",
	description = "demo",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local formspec = "formspec_version[1]"..
						"size[20, 10;false]"..
						"position[0.5, 0.5]"..
						"bgcolor[#00000000;neither]"..
						"real_coordinates[true]"..
						"background9[19.5,6.5;6,6.05;solarsail_nineslice_1.png;false;2,2]"

		formspec = formspec .. solarsail.util.functions.get_hsva_formspec(player, {x=20, y=7})
		minetest.show_formspec(player:get_player_name(), "colortag", formspec)
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "colortag" then
		if fields.h or fields.s or fields.v or fields.a then
			local function sval(value)
				return solarsail.util.functions.from_slider_hsv(value:gsub(".*:", ""))
			end
			local h, s, v, a =
				sval(fields.h),
				sval(fields.s), 
				sval(fields.v),
				sval(fields.a)
			
			local r, g, b, a = solarsail.util.functions.hsv_rgba(h, s, v, a)

			-- Use temporary/clipboard memory
			solarsail.color.rgba[player:get_player_name()] = {r=r, g=g, b=b, a=a}
			
			local formspec = "formspec_version[1]"..
							"size[20, 10;false]"..
							"position[0.5, 0.5]"..
							"bgcolor[#00000000;neither]"..
							"real_coordinates[true]" ..
							"background9[9.5,4.5;6,6.05;solarsail_nineslice_1.png;false;2,2]"
			formspec = formspec .. solarsail.util.functions.get_hsva_formspec(player, {x=20, y=7})
			minetest.show_formspec(player:get_player_name(), "colortag", formspec)

		end
	end
end)

-- Set default color to white:
minetest.register_on_joinplayer(function(player)
	solarsail.color.rgba[player:get_player_name()] = {r=255, g=0, b=0, a=255}
end)