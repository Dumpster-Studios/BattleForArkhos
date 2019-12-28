-- SolarSail Engine HUD/UI Renderer:
-- Author: Jordach
-- License: Reserved

solarsail.hud.formspec = {}
solarsail.hud.theme = {}
solarsail.hud.active_chat = {}
solarsail.hud.active_chat.theme = {}
solarsail.hud.active_chat.message = {}
solarsail.hud.active_chat.name = {}
solarsail.hud.active_chat.portrait = {}
solarsail.hud.active_chat.formname = {}

--[[ solarsail.hud.render_chat(player_ref, state, hud_theme, portrait, name, message, formname):

API Spec for defining screen sized text boxes:

SolarSail uses a keyframe or timeline based theming system; in which it allows
multiple messages, characters and text box themes. In which it's designed so
that mods can just re-use solarsail.hud.render_chat() to update what's on
screen at any time, or when a formspec is received.

Use the whole arguments to set up a long conversation chain with if statements or loops.
Use solarsail.hud.render_chat(player_ref, state) to change the 

state = 0 - 65535, controls what is displayed in the text box and portrait.

Textures and settings to define the appearance of the chat box and theming:
	hud_theme.text_box[6] = "texture.png"
	hud_theme.name_box[475] = "texture.png"
	hud_theme.portrait_box[14] = "texture.png"
	hud_theme.portrait_type[141] = (See below)
		"retro", Behaves as a small square portrait at the right edge of the chat box.
		"modern", Makes the portrait cover almost the entire screen, unstretched (not flipped)
		"indie_left" Makes the portrait the same size as the text box, and sits on the left.
		"indie_right" Does the above, but sits on the right edge.

portrait:
	portrait[1] = "texture.png"
	portrait[26] = "bacon.png"

name:
	name[1] = "Some name"
	name[76] = "someone""

message, see https://github.com/minetest/minetest/blob/master/doc/lua_api.txt#L2585 :
	message[1] = "this is a single line message!"
	message[26] = "multi\n line messages are also supported!"
	message[38] = "test"

formname:
	formname[4] = "mod_yourformname", used by minetest.register_on_player_receive_fields()
	formname[7] = "mod_yourresponse", used by minetest.register_on_player_receive_fields()

--]]
function solarsail.hud.render_chat(player_ref, state, hud_theme, portrait, name, message, formname)
	-- Keep a copy of last used in case of nil arguments
	if hud_theme ~= nil then solarsail.hud.active_chat.theme[player_ref:get_player_name()] = hud_theme end
	if message ~= nil then solarsail.hud.active_chat.message[player_ref:get_player_name()] = message end
	if name ~= nil then solarsail.hud.active_chat.name[player_ref:get_player_name()] = name end
	if portrait ~= nil then solarsail.hud.active_chat.portrait[player_ref:get_player_name()] = portrait end
	if formname ~= nil then solarsail.hud.active_chat.formname[player_ref:get_player_name()] = formname end
	-- Build initial formspec:
	local formspec = "formspec_version[1]"..
					"size[8, 2;false]".. 
					"position[0.5, 0.8]"..
					"container[1.25,0]" ..
					"bgcolor[#00000000;neither]"..
					"real_coordinates[true]"
	
	-- Decode theming:
	if solarsail.hud.active_chat.theme[player_ref:get_player_name()] ~= nil then
		if solarsail.hud.active_chat.theme[player_ref:get_player_name()].text_box[state] ~= nil then
			formspec = formspec .. "background9[0, 1;8, 2;" ..
				solarsail.hud.active_chat.theme[player_ref:get_player_name()].text_box[state] .. ";false;2,2]"
		end

		if solarsail.hud.active_chat.name[player_ref:get_player_name()][state] ~= nil then
			if solarsail.hud.active_chat.theme[player_ref:get_player_name()].name_box[state] ~= nil then
				formspec = formspec .. "background9[0.2, 0.4;2, 0.75;" .. 
					solarsail.hud.active_chat.theme[player_ref:get_player_name()].name_box[state] .. ";false;2,2]"
				
				formspec = formspec .. "hypertext[0.2, 0.5;2, 1;solarsail_name;<global halign=justify valign=center><center><big>" .. 
					solarsail.hud.active_chat.name[player_ref:get_player_name()][state] .. "</big></center>]"
			end
		end
		
		if solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_type[state] == "retro" then
			if solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_box[state] ~= nil then
				formspec = formspec .. "background9[7.1, 0.4;0.75, 0.75;"..
					solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_box[state] ..";false;2,2]"
				formspec = formspec .. "image[7.1, 0.4;0.75, 0.75;"..
					solarsail.hud.active_chat.portrait[player_ref:get_player_name()][state] .."]"
			end
		elseif solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_type[state] == "indie_left" then
			if solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_box[state] then
				formspec = formspec .. "background9[-1.95, 1;2, 2;" ..
					solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_box[state] .. ";false;2,2]"
				formspec = formspec .. "image[-1.95, 1;2, 2;" ..
					solarsail.hud.active_chat.portrait[player_ref:get_player_name()][state] .. "]"
			end
		elseif solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_type[state] == "indie_right" then
			if solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_box[state] ~= nil then
				formspec = formspec .. "background9[7.95, 1;2, 2;" ..
					solarsail.hud.active_chat.theme[player_ref:get_player_name()].portrait_box[state] .. ";false;2,2]"
				formspec = formspec .. "image[7.95, 1;2, 2;" .. 
					solarsail.hud.active_chat.portrait[player_ref:get_player_name()][state] .. "]"
			end
		end
	end

	-- Render hypertext chat to the main formspec
	formspec = formspec .. "hypertext[0.15, 1.35;8, 2;solarsail_chat;" .. 
		minetest.formspec_escape(solarsail.hud.active_chat.message[player_ref:get_player_name()][state]) .."]"
	
	minetest.show_formspec(
		player_ref:get_player_name(),
		solarsail.hud.active_chat.formname[player_ref:get_player_name()][state],
		formspec .. "container_end[]"
	)
end