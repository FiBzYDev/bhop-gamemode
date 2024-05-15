Client = {}

include( "core.lua" )

-- UI
include( "userinterface/cl_settings.lua" )
include( "userinterface/cl_themes.lua" )
include( "userinterface/cl_ui.lua" )
include( "userinterface/cl_hud.lua" )

include( "userinterface/menu/cl_menu.lua")
include( "userinterface/menu/cl_interface.lua")
include( "userinterface/menu/cl_display.lua")
include( "userinterface/menu/cl_other.lua")
include( "userinterface/menu/cl_beta.lua")

include("sh_disablehooks.lua")
include( "cl_disablehooks.lua")

include( "cl_timer.lua" )
include( "cl_receive.lua" )
include( "cl_gui.lua" )

include( "modules/cl_admin.lua" )
include( "modules/cl_strafe.lua" )
include( "modules/cl_commands.lua" )

include( "userinterface/scoreboards/cl_default.lua" )

local CPlayers = CreateClientConVar( "sl_showothers", "1", true, false )
local CSteam = CreateClientConVar( "sl_steamgroup", "1", true, false )
local CCrosshair = CreateClientConVar( "sl_crosshair", "1", true, false )
local CTargetID = CreateClientConVar( "sl_targetids", "0", true, false )
local HUDItems = { "CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo", "CHudSuitPower" }

local setting_anticheats = CreateClientConVar("bhop_anticheats", "0", true, false)
local setting_gunsounds = CreateClientConVar("bhop_gunsounds", "1", true, false)

local mousesmoothing = {}
mousesmoothing.Enabled = CreateClientConVar("kawaii_mousesource", "1", true, false, "Enable mouse source smoothing.")

-- View-related ConVars
local ubasefov = GetConVarNumber("fov_desired")
CreateClientConVar("kawaii_fov", ubasefov)
CreateClientConVar("kawaii_view_angle", 2)

-- Miscellaneous ConVars
CreateClientConVar("kawaii_suppress_viewpunch", "0", true, false, "Suppress viewpunch.")
CreateClientConVar("kawaii_suppress_viewpunch_wep", "0", true, false, "Suppress viewpunch for weapons.")
CreateClientConVar("kawaii_steady_view", "0", true, false, "Steady weapon view.")

local HUDItems = { "CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo", "CHudSuitPower" }
local ubasefov = GetConVarNumber "fov_desired"
CreateClientConVar("kawaii_fov", ubasefov)
local newfov = GetConVarNumber "kawaii_fov"
CreateClientConVar("kawaii_view_angle", 2)
local _angle = GetConVarNumber "kawaii_view_angle"
suppress_viewpunch = {}
suppress_viewpunch.Enabled = CreateClientConVar( "kawaii_suppress_viewpunch", "0", true, false, "Suppress viewpunch" )
suppress_viewpunch_wep = {}
suppress_viewpunch_wep.Enabled = CreateClientConVar( "kawaii_suppress_viewpunch_wep", "0", true, false, "Suppress viewpunch for weapon" )
steady_view = {}
steady_view.Enabled = CreateClientConVar( "kawaii_steady_view", "0", true, false, "Steady weapon view not moving" )


-- Edited: justa
-- convars
local setting_triggers = CreateClientConVar("kawaii_triggers", "0", true, false)
local setting_anticheats = CreateClientConVar("kawaii_anticheats", "0", true, false)
local setting_gunsounds = CreateClientConVar("kawaii_gunsounds", "1", true, false)
local setting_hints = CreateClientConVar("kawaii_hints", "180", true, false)

-- Hints
local function AddMessage(message)
	chat.AddText(color_white, "[", Color(0, 200, 200), "Hint", color_white, "] ", message)
end

local hints = {
	"You can toggle anti-cheat visibility with !anticheats",
	"You can edit the style of your HUD with !theme",
	"You can edit the delay between these hints with \"kawaii_hints <delay>\" in your console. 0 will stop hints completely."
}

local lasthint = CurTime() + setting_hints:GetInt()
local hintindex = 1
hook.Add("Think", "Hints", function()
	if (setting_hints:GetInt() == 0) then return end

	if (lasthint < CurTime()) then
		AddMessage(hints[hintindex])

		lasthint = CurTime() + setting_hints:GetInt()
		hintindex = (hintindex == #hints) and 1 or (hintindex + 1)
	end
end)

function GM:HUDShouldDraw( szApp )
	return not HUDItems[ szApp ]
end

function Client:ToggleCrosshair( tabData )
	if tabData then
		for cmd,target in pairs( tabData ) do
			RunConsoleCommand( cmd, tostring( target ) )
		end
		Link:Print( "General", "Your crosshair options have been changed!" )
	else
		HUDItems[ "CHudCrosshair" ] = not HUDItems[ "CHudCrosshair" ]
		RunConsoleCommand( "sl_crosshair", HUDItems[ "CHudCrosshair" ] and 1 or 0 )
		Link:Print( "General", "Crosshair visibility has been toggled" )
	end
end

function Client:ToggleTargetIDs()
	local nNew = 1 - CTargetID:GetInt()
	RunConsoleCommand( "sl_targetids", nNew )
	Link:Print( "General", "You have " .. (nNew == 0 and "disabled" or "enabled") .. " player labels" )
end

function Client:PlayerVisibility( nTarget )
	local nNew = -1
	if CPlayers:GetInt() == nTarget then
		RunConsoleCommand( "sl_showothers", 1 - nTarget )
		timer.Simple( 1, function() RunConsoleCommand( "sl_showothers", nTarget ) end )
		nNew = nTarget
	elseif nTarget < 0 then
		nNew = 1 - CPlayers:GetInt()
		RunConsoleCommand( "sl_showothers", nNew )
	else
		nNew = nTarget
		RunConsoleCommand( "sl_showothers", nNew )
	end

	if nNew >= 0 then
		Link:Print( "General", "You have set player visibility to " .. (nNew == 0 and "invisible" or "visible") )
	end
end

function Client:ShowHelp( tab )
	print( "\n\nBelow is a list of all available commands and their aliases:\n\n" )

	table.sort( tab, function( a, b )
		if not a or not b or not a[ 2 ] or not a[ 2 ][ 1 ] then return false end
		return a[ 2 ][ 1 ] < b[ 2 ][ 1 ]
	end )

	for _,data in pairs( tab ) do
		local desc, alias = data[ 1 ], data[ 2 ]
		local main = table.remove( alias, 1 )

		MsgC( Color( 212, 215, 134 ), "\tCommand: " ) MsgC( Color( 255, 255, 255 ), main .. "\n" )
		MsgC( Color( 212, 215, 134 ), "\t\tAliases: " ) MsgC( Color( 255, 255, 255 ), (#alias > 0 and string.Implode( ", ", alias ) or "None") .. "\n" )
		MsgC( Color( 212, 215, 134 ), "\t\tDescription: " ) MsgC( Color( 255, 255, 255 ), desc .. "\n\n" )
	end

	Link:Print( "General", "A list of commands and their descriptions has been printed in your console! Press ~ to open." )
end

function Client:ShowEmote( data )
	local ply
	for _,p in pairs( player.GetHumans() ) do
		if tostring( p:SteamID() ) == data[ 1 ] then
			ply = p
			break
		end
	end
	if not IsValid( ply ) then return end

	if ply:GetNWInt( "AccessIcon", 0 ) > 0 then
		local tab = {}
		local VIPNameColor = ply:GetNWVector( "VIPNameColor", Vector( -1, 0, 0 ) )
		if VIPNameColor.x >= 0 then
			local VIPName = ply:GetNWString( "VIPName", "" )
			if VIPName == "" then
				VIPName = ply:Name()
			end

			if VIPNameColor.x == 256 then
				tab = Client:GenerateName( tab, VIPName .. " " )
			elseif VIPNameColor.x == 257 then
				tab = Client:GenerateName( tab, VIPName .. " ", ply )
			else
				table.insert( tab, Core.Util:VectorToColor( VIPNameColor ) )
				table.insert( tab, VIPName .. " " )
			end

			if Client.VIPReveal and VIPName != ply:Name() then
				table.insert( tab, GUIColor.White )
				table.insert( tab, "(" .. ply:Name() .. ") " )
			end
		else
			table.insert( tab, Color( 98, 176, 255 ) )
			table.insert( tab, ply:Name() .. " " )
		end

		table.insert( tab, GUIColor.White )
		table.insert( tab, tostring( data[ 2 ] ) )

		chat.AddText( unpack( tab ) )
	end
end

function Client:VerifyList()
	if file.Exists( Cache.M_Name, "DATA" ) then
		Cache:M_Load()
	end
end

function Client:Mute( bMute )
	for _,p in pairs( player.GetHumans() ) do
		if LocalPlayer() and p != LocalPlayer() then
			if bMute and not p:IsMuted() then
				p:SetMuted( true )
			elseif not bMute and p:IsMuted() then
				p:SetMuted( false )
			end
		end
	end

	Link:Print( "General", "All players have been " .. (bMute and "muted" or "unmuted") .. "." )
end

function Client:DoChatMute( szID, bMute )
	for _,p in pairs( player.GetHumans() ) do
		if tostring( p:SteamID() ) == szID then
			p.ChatMuted = bMute
			Link:Print( "General", p:Name() .. " has been " .. (bMute and "chat muted" or "unmuted") .. "!" )
		end
	end
end

function Client:DoVoiceGag( szID, bGag )
	for _,p in pairs( player.GetHumans() ) do
		if tostring( p:SteamID() ) == szID then
			p:SetMuted( bGag )
			Link:Print( "General", p:Name() .. " has been " .. (bGag and "voice gagged" or "ungagged") .. "!" )
		end
	end
end

function Client:GenerateName( tab, szName, gradient )
	szName = szName:gsub('[^%w ]', '')
	local count = #szName
	local start, stop = Core.Util:RandomColor(), Core.Util:RandomColor()
	if gradient then
		local gs = gradient:GetNWVector( "VIPGradientS", Vector( -1, 0, 0 ) )
		local ge = gradient:GetNWVector( "VIPGradientE", Vector( -1, 0, 0 ) )

		if gs.x >= 0 then start = Core.Util:VectorToColor( gs ) end
		if ge.x >= 0 then stop = Core.Util:VectorToColor( ge ) end
	end

	for i = 1, count do
		local percent = i / count
		table.insert( tab, Color( start.r + percent * (stop.r - start.r), start.g + percent * (stop.g - start.g), start.b + percent * (stop.b - start.b) ) )
		table.insert( tab, szName[ i ] )
	end

	return tab
end

function Client:ToggleChat()
	local nTime = GetConVar( "hud_saytext_time" ):GetInt()
	if nTime > 0 then
		Link:Print( "General", "The chat has been hidden." )
		RunConsoleCommand( "hud_saytext_time", 0 )
	else
		Link:Print( "General", "The chat has been restored." )
		RunConsoleCommand( "hud_saytext_time", 12 )
	end
end

function Client:SpecVisibility( arg )
	local nNew = nil
	if not arg then
		nNew = 1 - Timer:GetSpecSetting()
	else
		nNew = tonumber( arg ) or 1
	end

	if nNew then
		RunConsoleCommand( "sl_showspec", nNew )
		Link:Print( "General", "You have set spectator list visibility to " .. (nNew == 0 and "invisible" or "visible") )
	end
end

function Client:ChangeWater()
	local a = GetConVar( "r_waterdrawrefraction" ):GetInt()
	local b = GetConVar( "r_waterdrawreflection" ):GetInt()
	local c = 1 - a

	RunConsoleCommand( "r_waterdrawrefraction", c )
	RunConsoleCommand( "r_waterdrawreflection", c )
	Link:Print( "General", "Water reflection and refraction have been " .. (c == 0 and "disabled" or "re-enabled") .. "!" )
end

function Client:ClearDecals()
	RunConsoleCommand( "r_cleardecals" )
	Link:Print( "General", "All players decals have been cleared from your screen." )
end

function Client:ToggleReveal()
	Client.VIPReveal = not Client.VIPReveal
	Link:Print( "General", "True VIP names will now " .. (Client.VIPReveal and "" or "no longer ") .. "be shown" )
end

function Client:DoFlipWeapons()
	local n = 0
	for _,wep in pairs( LocalPlayer():GetWeapons() ) do
		if wep.ViewModelFlip != Client.FlipStyle then
			wep.ViewModelFlip = Client.FlipStyle
		end

		n = n + 1
	end
	return n
end

function Client:FlipWeapons( bRestart )
	if IsValid( LocalPlayer() ) then
		if not bRestart then
			Client.Flip = not Client.Flip
			Client.FlipStyle = not Client.Flip

			local n = Client:DoFlipWeapons()
			if n > 0 then
				Link:Print( "General", "Your weapons have been flipped!" )
			else
				Link:Print( "General", "You had no weapons to flip. Flip again to revert back." )
			end
		elseif Client.Flip then
			timer.Simple( 0.1, function()
				Client:DoFlipWeapons()
			end )
		end
	end
end

function Client:ToggleSpace( bStart )
	if bStart then
		Client.SpaceToggle = not Client.SpaceToggle
	else
		if not IsValid( LocalPlayer() ) then return end
		if not Client.SpaceEnabled then
			Client.SpaceEnabled = true
			LocalPlayer():ConCommand( "+jump" )
		else
			LocalPlayer():ConCommand( "-jump" )
			Client.SpaceEnabled = nil
		end
	end
end

function Client:ServerSwitch( data )
	Link:Print( "General", "Now connecting to: " .. data[ 2 ] )
	Derma_Query( 'Are you sure you want to connect to ' .. data[ 2 ] .. '?', 'Connecting to different server', 'Yes', function() LocalPlayer():ConCommand( "connect " .. data[ 1 ] ) end, 'No', function() end)
end

-- Define the function to set hull and view offset
local function SetHullAndViewOffset()
    local ply = LocalPlayer()

    -- Check if the player is valid and has the required functions
    if IsValid(ply) and ply.SetHull and ply.SetHullDuck then
        -- Check and set view offsets only once
        if ply.SetViewOffset and ply.SetViewOffsetDucked and not viewset then
            viewset = true
            -- Set your desired view offset here if needed
            ply:SetViewOffset(Vector(0, 0, 62))
            ply:SetViewOffsetDucked(Vector(0, 0, 45))
        end

        -- Set hull sizes
        ply:SetHull(_C["Player"].HullMin, _C["Player"].HullStand)
        ply:SetHullDuck(_C["Player"].HullMin, _C["Player"].HullDuck)
    end
end

-- Initialize the function using a timer
local function InitializeClient()
    timer.Create("SetHullAndView", 0.01, 0, SetHullAndViewOffset)
end
hook.Add("Initialize", "CInitialize", InitializeClient)

local function ClientTick()
	if not IsValid( pl ) then timer.Simple( 1, ClientTick ) return end
	timer.Simple( 1, ClientTick )
end

local function ChatEdit( nIndex, szName, szText, szID )
	if szID == "joinleave" then
		return true
	end
end
hook.Add( "ChatText", "SuppressMessages", ChatEdit )

local function ChatTag( ply, szText, bTeam, bDead )
	if ply.ChatMuted then
		print( "[CHAT MUTE] " .. ply:Name() .. ": " .. szText )
		return true
	end

	local tab = {}
	if bTeam then
		table.insert( tab, Color( 30, 160, 40 ) )
		table.insert( tab, "(TEAM) " )
	end

	if ply:GetNWInt( "Spectating", 0 ) == 1 then
		table.insert( tab, Color( 189, 195, 199 ) )
		table.insert( tab, "*SPEC* " )
	end

	local nAccess = 0
	if IsValid( ply ) and ply:IsPlayer() then
		nAccess = ply:GetNWInt( "AccessIcon", 0 )
		local ID = ply:GetNWInt( "Rank", 1 )
		table.insert( tab, GUIColor.White )

		-- Edited by Niflheimrx
		-- Support custom titles with viptags
		-- Minor updates to rank colors

		local VIPTag, VIPTagColor = ply:GetNWString( "VIPTag", "" ), ply:GetNWVector( "VIPTagColor", Vector( -1, 0, 0 ) )
		if nAccess > 0 and VIPTag != "" and VIPTagColor.x >= 0 then
			table.insert( tab, Core.Util:VectorToColor( VIPTagColor ) )
			table.insert( tab, "[" )
			table.insert( tab, VIPTag )
			table.insert( tab, "] " )
			table.insert( tab, GUIColor.White )
		else
			table.insert( tab, _C.Ranks[ ID ][ 2 ] )
			table.insert( tab, "[" )
			table.insert( tab, _C.Ranks[ ID ][ 1 ] )
			table.insert( tab, "] " )
			table.insert( tab, GUIColor.White )
		end

		if nAccess > 0 then
			local VIPNameColor = ply:GetNWVector( "VIPNameColor", Vector( -1, 0, 0 ) )
			if VIPNameColor.x >= 0 then
				local VIPName = ply:GetNWString( "VIPName", "" )
				if VIPName == "" then
					VIPName = ply:Name()
				end

				if VIPNameColor.x == 256 then
					tab = Client:GenerateName( tab, VIPName )
				elseif VIPNameColor.x == 257 then
					tab = Client:GenerateName( tab, VIPName, ply )
				else
					table.insert( tab, Core.Util:VectorToColor( VIPNameColor ) )
					table.insert( tab, VIPName )
				end

				if Client.VIPReveal and VIPName != ply:Name() then
					table.insert( tab, GUIColor.White )
					table.insert( tab, " (" .. ply:Name() .. ")" )
				end
			else
				table.insert( tab, Color( 98, 176, 255 ) )
				table.insert( tab, ply:Name() )
			end
		else
			table.insert( tab, Color( 98, 176, 255 ) )
			table.insert( tab, ply:Name() )
		end
	else
		table.insert( tab, "Console" )
	end

	table.insert( tab, GUIColor.White )
	table.insert( tab, ": " )

	if nAccess > 0 then
		local VIPChat = ply:GetNWVector( "VIPChat", Vector( -1, 0, 0 ) )
		if VIPChat.x >= 0 then
			table.insert( tab, Core.Util:VectorToColor( VIPChat ) )
		end
	end

	table.insert( tab, szText )

	chat.AddText( unpack( tab ) )
	return true
end
hook.Add( "OnPlayerChat", "TaggedChat", ChatTag )

local function EntityCheckPost( ply )
	RunConsoleCommand( "sl_targetids", 0 )
	hook.Remove( "PostDrawOpaqueRenderables", "PlayerMarkers" )
	hook.Remove( "PostDrawOpaqueRenderables", "PlayerMarkers" )
	hook.Remove( "PlayerTick", "PlayerTick" )
	hook.Remove( "SetupMove", "SetupMove" )
	hook.Remove( "Move", "Move" )
	hook.Remove( "StartMove", "StartMove" )
	hook.Remove( "FinishMove", "FinishMove" )
	hook.Remove( "CreateMove", "CreateMove" )
	hook.Remove( "Tick", "Tick" )
	hook.Remove( "Think", "Think" )
	hook.Remove("StartCommand", "StartCommand")
	hook.Remove("Think", "Think")
	hook.Remove("PlayerTick", "PlayerTick")
	hook.Remove("PostZombieKilledHuman", "PostZombieKilledHuman")
	hook.Remove("PrePlayerRedeemed", "PrePlayerRedeemed")
	hook.Remove("AcceptStream", "AcceptStream")
	hook.Remove("AllowPlayerPickup", "AllowPlayerPickup")
	hook.Remove("CanExitVehicle", "CanExitVehicle")
	hook.Remove("CanPlayerSuicide", "CanPlayerSuicide")
	hook.Remove("CanPlayerUnfreeze", "CanPlayerUnfreeze")
	hook.Remove("CreateEntityRagdoll", "CreateEntityRagdoll")
	hook.Remove("DoPlayerDeath", "DoPlayerDeath")
	hook.Remove("EntityTakeDamage", "EntityTakeDamage")
	hook.Remove("GetFallDamage", "GetFallDamage")
	hook.Remove("GetGameDescription", "GetGameDescription")
	hook.Remove("GravGunOnDropped", "GravGunOnDropped")
	hook.Remove("GravGunPickupAllowed", "GravGunPickupAllowed")
	hook.Remove("IsSpawnpointSuitable", "IsSpawnpointSuitable")
	hook.Remove("NetworkIDValidated", "NetworkIDValidated")
	hook.Remove("OnDamagedByExplosion", "OnDamagedByExplosion")
	hook.Remove("OnNPCKilled", "OnNPCKilled")
	hook.Remove("OnPhysgunFreeze", "OnPhysgunFreeze")
	hook.Remove("OnPhysgunReload", "OnPhysgunReload")
	hook.Remove("OnPlayerChangedTeam", "OnPlayerChangedTeam")
	hook.Remove("PlayerCanJoinTeam", "PlayerCanJoinTeam")
	hook.Remove("PlayerCanPickupItem", "PlayerCanPickupItem")
	hook.Remove("PlayerCanPickupWeapon", "PlayerCanPickupWeapon")
	hook.Remove("PlayerDeath", "PlayerDeath")
	hook.Remove("PlayerDeathSound", "PlayerDeathSound")
	hook.Remove("PlayerDeathThink", "PlayerDeathThink")
	hook.Remove("PlayerDisconnected", "PlayerDisconnected")
	hook.Remove("PlayerHurt", "PlayerHurt")
	hook.Remove("PlayerInitialSpawn", "PlayerInitialSpawn")
	hook.Remove("PlayerJoinTeam", "PlayerJoinTeam")
	hook.Remove("PlayerLeaveVehicle", "PlayerLeaveVehicle")
	hook.Remove("PlayerLoadout", "PlayerLoadout")
	hook.Remove("PlayerRequestTeam", "PlayerRequestTeam")
	hook.Remove("PlayerSelectSpawn", "PlayerSelectSpawn")
	hook.Remove("PlayerSelectTeamSpawn", "PlayerSelectTeamSpawn")
	hook.Remove("PlayerSetModel", "PlayerSetModel")
	hook.Remove("PlayerShouldAct", "PlayerShouldAct")
	hook.Remove("PlayerShouldTakeDamage", "PlayerShouldTakeDamage")
	hook.Remove("PlayerSilentDeath", "PlayerSilentDeath")
	hook.Remove("PlayerSpawn", "PlayerSpawn")
	hook.Remove("PlayerSpawnAsSpectator", "PlayerSpawnAsSpectator")
	hook.Remove("PlayerSpray", "PlayerSpray")
	hook.Remove("PlayerSwitchFlashlight", "PlayerSwitchFlashlight")
	hook.Remove("PlayerUse", "PlayerUse")
	hook.Remove("ScaleNPCDamage", "ScaleNPCDamage")
	hook.Remove("SetPlayerSpeed", "SetPlayerSpeed")
	hook.Remove("SetupPlayerVisibility", "SetupPlayerVisibility")
	hook.Remove("WeaponEquip", "WeaponEquip")
	hook.Remove("CalcMainActivity", "CalcMainActivity")
	hook.Remove("CanPlayerEnterVehicle", "CanPlayerEnterVehicle")
	hook.Remove("CompletedIncomingStream", "CompletedIncomingStream")
	hook.Remove("ContextScreenClick", "ContextScreenClick")
	hook.Remove("CreateTeams", "CreateTeams")
	hook.Remove("DoAnimationEvent", "DoAnimationEvent")
	hook.Remove("EntityKeyValue", "EntityKeyValue")
	hook.Remove("EntityRemoved", "EntityRemoved")
	hook.Remove("FinishMove", "FinishMove")
	hook.Remove("GravGunPunt", "GravGunPunt")
	hook.Remove("HandlePlayerDriving", "HandlePlayerDriving")
	hook.Remove("HandlePlayerJumping", "HandlePlayerJumping")
	hook.Remove("Initialize", "Initialize")
	hook.Remove("InitPostEntity", "InitPostEntity")
	hook.Remove("KeyPress", "KeyPress")
	hook.Remove("KeyRelease", "KeyRelease")
	hook.Remove("Move", "Move")
	hook.Remove("OnEntityCreated", "OnEntityCreated")
	hook.Remove("OnPlayerHitGround", "OnPlayerHitGround")
	hook.Remove("PhysgunDrop", "PhysgunDrop")
	hook.Remove("PlayerAuthed", "PlayerAuthed")
	hook.Remove("PlayerConnect", "PlayerConnect")
	hook.Remove("PlayerEnteredVehicle", "PlayerEnteredVehicle")
	hook.Remove("PlayerNoClip", "PlayerNoClip")
	hook.Remove("PlayerFootstep", "PlayerFootstep")
	hook.Remove("PlayerStepSoundTime", "PlayerStepSoundTime")
	hook.Remove("PlayerTraceAttack", "PlayerTraceAttack")
	hook.Remove("PostGamemodeLoaded", "PostGamemodeLoaded")
	hook.Remove("PropBreak", "PropBreak")
	hook.Remove("Restored", "Restored")
	hook.Remove("Saved", "Saved")
	hook.Remove("SetupMove", "SetupMove")
	hook.Remove("ShouldCollide", "ShouldCollide")
	hook.Remove("ShutDown", "ShutDown")
	hook.Remove("Think", "Think")
	hook.Remove("Tick", "Tick")
	hook.Remove("TranslateActivity", "TranslateActivity")
	hook.Remove("UpdateAnimation", "UpdateAnimation")
	hook.Remove("CanTool", "CanTool")
	hook.Remove("PlayerGiveSWEP", "PlayerGiveSWEP")
	hook.Remove("PlayerSpawnedEffect", "PlayerSpawnedEffect")
	hook.Remove("PlayerSpawnedNPC", "PlayerSpawnedNPC")
	hook.Remove("PlayerSpawnedProp", "PlayerSpawnedProp")
	hook.Remove("PlayerSpawnedRagdoll", "PlayerSpawnedRagdoll")
	hook.Remove("PlayerSpawnedSENT", "PlayerSpawnedSENT")
	hook.Remove("PlayerSpawnedVehicle", "PlayerSpawnedVehicle")
	hook.Remove("PlayerSpawnEffect", "PlayerSpawnEffect")
	hook.Remove("PlayerSpawnNPC", "PlayerSpawnNPC")
	hook.Remove("PlayerSpawnObject", "PlayerSpawnObject")
	hook.Remove("PlayerSpawnProp", "PlayerSpawnProp")
	hook.Remove("PlayerSpawnRagdoll", "PlayerSpawnRagdoll")
	hook.Remove("PlayerSpawnSENT", "PlayerSpawnSENT")
	hook.Remove("PlayerSpawnSWEP", "PlayerSpawnSWEP")
	hook.Remove("PlayerSpawnVehicle", "PlayerSpawnVehicle")
	hook.Remove("AddHint", "AddHint")
	hook.Remove("AddNotify", "AddNotify")
	hook.Remove("GetSENTMenu", "GetSENTMenu")
	hook.Remove("GetSWEPMenu", "GetSWEPMenu")
	hook.Remove("PaintNotes", "PaintNotes")
	hook.Remove("PopulateSTOOLMenu", "PopulateSTOOLMenu")
	hook.Remove("SpawnMenuEnabled", "SpawnMenuEnabled")
	hook.Remove("StartCommand", "StartCommand")
	hook.Remove("Think", "Think")
	hook.Remove("PlayerTick", "PlayerTick")
	hook.Remove("PostZombieKilledHuman", "PostZombieKilledHuman")
	hook.Remove("PrePlayerRedeemed", "PrePlayerRedeemed")
	hook.Remove("Move", "Move")
	hook.Remove("CreateMove", "CreateMove")
	hook.Remove("FinishMove", "FinishMove")
	hook.Remove("StartMove", "StartMove")
	hook.Remove("OnUndo", "OnUndo")
    hook.Remove("SetupPlayerVisibility", "mySetupVis")
end
hook.Add( "InitPostEntity", "StartEntityCheck", EntityCheckPost )

local function VisibilityCallback( CVar, Previous, New )
	if tonumber( New ) == 1 then
		for _,ent in pairs( ents.FindByClass("env_spritetrail") ) do
			ent:SetNoDraw( false )
		end
		for _,ent in pairs( ents.FindByClass("beam") ) do
			ent:SetNoDraw( false )
		end
	else
		for _,ent in pairs( ents.FindByClass("env_spritetrail") ) do
			ent:SetNoDraw( true )
		end
		for _,ent in pairs( ents.FindByClass("beam") ) do
			ent:SetNoDraw( true )
		end
	end
end
cvars.AddChangeCallback( "bhop_showplayers", VisibilityCallback )

CreateClientConVar("bhop_showplayers", 1, true, false, "Shows bhop players", 0, 1)
concommand.Add("bhop_showplayers_toggle", function(client)
	LocalPlayer():ConCommand("bhop_showplayers "..(GetConVar("bhop_showplayers"):GetInt() == 0 and 1 or 0))
end)

local function PlayerVisiblityCheck( ply )
	if (GetConVar("bhop_showplayers"):GetInt() == 0) then 
		return true
	end 
end
hook.Add( "PrePlayerDraw", "PlayerVisiblityCheck", PlayerVisiblityCheck )

local function Initialize()
	timer.Simple( 5, ClientTick )
	timer.Simple( 5, function() Core:Optimize() end )
end
hook.Add( "Initialize", "ClientBoot", Initialize )

concommand.Add("_toggleanticheats", function(client, command, args)
	local acs = GetConVar("bhop_anticheats")
	acs:SetInt(acs:GetInt() == 1 and 0 or 1)
end)

concommand.Add("_togglegunsounds", function()
	local gunshots = GetConVar("bhop_gunsounds")
	gunshots:SetInt(gunshots:GetInt() == 1 and 0 or 1)
end)

concommand.Add("_imvalid", function(ply, cmd, args)
    if IsValid(ply) then
        hook.Remove("Think", "Validation")
        print("Validation hook has been removed by", ply:GetName())
    end
end)

hook.Add("Think", "Validation", function()
	if IsValid(LocalPlayer()) then 
		RunConsoleCommand("_imvalid")
		hook.Remove("Think", "Validation")
	end
end)

local fp = CreateClientConVar("bhop_flipweapons", 0, true, false, "Flips weapon view models.", 0, 1)
cvars.AddChangeCallback("bhop_flipweapons", function(cvar, prev, new)
	local bool = (new == "1")

	if IsValid(LocalPlayer()) then 
		for k, v in pairs(LocalPlayer():GetWeapons()) do 
			v.ViewModelFlip = !bool 
		end 
	end 
end)

hook.Add("HUDWeaponPickedUp", "flipweps", function(wep)
	wep.ViewModelFlip = (not fp:GetBool())
end)

local swayvar = CreateClientConVar("bhop_weaponsway", 1, true, false, "Controls how weapon view models move.", 0, 1)
local sway = swayvar:GetBool()
cvars.AddChangeCallback("bhop_weaponsway", function(cvar, prev, new)
	sway = (new == "1") 
end)

--[[function GM:CalcViewModelView( we, vm, op, oa, p, a )
	if (not sway) then 
		return op, oa
	end 
end --]]
local _angle = GetConVarNumber "kawaii_view_angle"

function GM:CalcViewModelView(we, vm, op, oa, p, a)
    if not sway then
        return op - a:Forward() * _angle, oa
    end

    return op - a:Forward() * _angle, oa
end

local util = util

local function fov(ply, ori, ang, fov, nz, fz)

    local suppress_viewpunch = suppress_viewpunch.Enabled:GetBool()

    if suppress_viewpunch then
        ang.r = 0
    end

    local forwardOffset = ang:Forward() * - _angle  -- Adjust the offset based on your needs
    local view = {
        origin = ori + forwardOffset,
        angles = ang,
        fov = newfov
    }

    return view
end

hook.Remove("CalcView", "fov")
timer.Simple(1, function()
if GetConVarNumber "kawaii_fov" != 0 then
	hook.Add("CalcView", "fov", fov)
end
end)

cvars.AddChangeCallback("kawaii_fov", function() 
	newfov = GetConVarNumber "kawaii_fov"
	if newfov != 0 then
		hook.Add("CalcView", "fov", fov)
	else
		hook.Remove("CalcView", "fov")
	end
end)