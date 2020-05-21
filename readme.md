# SolarSail
### A framework for making RPG games, ~~but also other games.~~

## Introduction:
SolarSail is an engine for writing RPG games, in the style of Dragon Quest, Final Fantasy, and EarthBound / ~~Mother~~ series. Inspired by the 1990s RPGs with of content. SolarSail aims to expedite the game construction process.

## What It Does:
In other words, SolarSail is a form of middleware for the Minetest engine that simplifies and abstracts some of the more complex abilities of the Minetest API, while retaining it's full functionality, as SolarSail's built in functionality can be enabled and disabled.

## Documentation, ~~What's that?~~
Check the Lua source code under `mods/solarsail/`, wherein you'll find all functions documented.

## Why As A Game For Minetest, Not A Mod?
As an **engine** that powers games, it should be classed a a game. More importantly, it doesn't contain anything but a single node for prototyping things with.

Instead, a mod should provide assets, such as: nodes, models, entities, logic and code. Which can be enabled per world, and that means you can use ***more than one*** game using the SolarSail engine, all while only needing to download a world and enable the required mod. This also means updates for the SolarSail engine can be done via Content Distribution Services, reducing the input needed to update the engine.

## Why Isn't This Open Source?
This is a preview of what's to come, and can be downloaded, installed and fiddled with, and forked for *personal use only.*

Because it's nowhere near completion and I'm not in the mood to deal with potentially bad code. Or indentation that is all spaces.

Once the heavy work is done it'll likely be licensed AGPL.