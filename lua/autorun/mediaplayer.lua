local basepath = "mediaplayer/"

local function IncludeMP( filepath )
	include( basepath .. filepath )
end

local function LoadMediaPlayer()
	print( "Loading 'mediaplayer' addon..." )

	-- Check if MediaPlayer has already been loaded
	if MediaPlayer then
		MediaPlayer.__refresh = true

		-- HACK: Lua refresh fix; access local variable of baseclass lib
		local _, BaseClassTable = debug.getupvalue(baseclass.Get, 1)
		for classname, _ in pairs(BaseClassTable) do
			if classname:find("mp_") then
				BaseClassTable[classname] = nil
			end
		end
	end

	-- shared includes
	IncludeCS "includes/extensions/sh_url.lua"
	IncludeCS "includes/modules/EventEmitter.lua"

	if SERVER then
		-- download clientside includes
		AddCSLuaFile "includes/modules/browserpool.lua"
		AddCSLuaFile "includes/modules/control.lua"
		AddCSLuaFile "includes/modules/htmlmaterial.lua"
		AddCSLuaFile "includes/modules/spritesheet.lua"

		-- initialize serverside mediaplayer
		IncludeMP "init.lua"
	else
		-- clientside includes
		include "includes/modules/browserpool.lua"
		include "includes/modules/control.lua"
		include "includes/modules/htmlmaterial.lua"
		include "includes/modules/spritesheet.lua"

		-- initialize clientside mediaplayer
		IncludeMP "cl_init.lua"
	end

	-- Sandbox includes; these must always be included as the gamemode is still
	-- set as 'base' when the addon is loading. Can't check if gamemode derives
	-- Sandbox.
	IncludeCS "menubar/mp_options.lua"
	include "properties/mediaplayer.lua"

	--
	-- Media Player menu includes; remove these if you would rather not include
	-- the sidebar menu.
	--
	if SERVER then
		AddCSLuaFile "mp_menu/cl_init.lua"
		include "mp_menu/init.lua"
	else
		include "mp_menu/cl_init.lua"
	end


	if SERVER then
		-- Reinstall media players on Lua refresh
		for _, mp in pairs(MediaPlayer.GetAll()) do

			if mp:GetType() == 'entity' and IsValid(mp) then
				local ent = mp:GetEntity()
				local listeners = table.Copy(mp:GetListeners())

				-- remove media player
				mp:Remove()

				-- install new media player
				ent:InstallMediaPlayer()

				-- reinitialize settings
				mp = ent._mp

				-- TODO: implement memento pattern for reloading MP state.

				-- reapply listeners
				mp:SetListeners( listeners )
				mp:BroadcastUpdate()
			end

		end
	end
end

-- First time load
LoadMediaPlayer()
