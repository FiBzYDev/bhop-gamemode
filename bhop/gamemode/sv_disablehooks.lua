function table.HasValue(tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function isNonEssentialGlobal(key)
    local essentialGlobals = {
        -- Lua base functions and libraries
        ["_G"] = true, ["pairs"] = true, ["ipairs"] = true, ["print"] = true, ["tonumber"] = true,
        ["tostring"] = true, ["next"] = true, ["pcall"] = true, ["xpcall"] = true, ["table"] = true,
        ["math"] = true, ["string"] = true, ["coroutine"] = true, ["os"] = true, ["io"] = true,
        ["debug"] = true, ["package"] = true,

        -- Any other global variables or modules your application needs
    }

    -- Use a set for non-essential globals for quick lookup
    local nonEssentialGlobals = {
        ["DMG_FALL"] = true, ["ParticleEffect"] = true, ["predictionFactor"] = true, ["BOUNDS_COLLISION"] = true,
        ["CreatePhysCollidesFromModel"] = true, ["CreatePhysCollideBox"] = true, ["SND_DELAY"] = true,
        ["MAT_FOLIAGE"] = true, ["RENDERMODE_GLOW"] = true, ["SetGlobal2Var"] = true, ["GetGlobal2Entity"] = true,
        ["HTTP"] = true, ["ParticleEffectAttach"] = true, ["PrecacheParticleSystem"] = true, ["FL_FROZEN"] = true,
        ["MASK_BLOCKLOS_AND_NPCS"] = true, ["RENDERMODE_NONE"] = true, ["kRenderFxPulseSlow"] = true,
        ["RENDERGROUP_OPAQUE_BRUSH"] = true, ["RENDERMODE_WORLDGLOW"] = true, ["FSASYNC_ERR_READING"] = true,
        ["TRANSMIT_ALWAYS"] = true, ["PrecacheSentenceGroup"] = true, ["PrecacheSentenceFile"] = true,
        ["PrecacheScene"] = true, ["ACT_MP_DOUBLEJUMP"] = true, ["GetPredictionPlayer"] = true, ["SuppressHostEvents"] = true
    }

    return not essentialGlobals[key] and nonEssentialGlobals[key] == true
end

local function ClearSpecificEntries(targetTable, isNonEssentialGlobal)
    local keysToClear = {}
    -- First, collect all keys that need to be cleared
    for key, _ in pairs(targetTable) do
        if isNonEssentialGlobal(key) then
            table.insert(keysToClear, key)  -- Store keys to be cleared
        end
    end

    -- Now, safely clear the collected keys
    for _, key in pairs(keysToClear) do
        print("Clearing:", key)  -- Log the key before clearing it
        targetTable[key] = nil  -- Actually perform the clearing
    end
end

-- Apply the function to the global environment table _G with the new safety checks
ClearSpecificEntries(_G, isNonEssentialGlobal)

table.Empty( debug.getregistry() )

-- Safety check: Ensure that we are running in a secure environment (e.g., server-side)
if SERVER then
    -- Check if the debug library is available and if we have permission to access it
    if debug and debug.getregistry then
        -- Clear the debug registry to remove any potential Lua objects
        table.Empty(debug.getregistry())
        print("Debug registry cleared successfully.")
    else
        print("Error: Unable to access debug registry.")
    end
else
    print("Warning: This code should be executed on the server side.")
end

local Table = {"String Value", "Another value", Var = "Non-integer key"}
table.Empty(Table)

table.Empty(_MODULES)

function GM:OnPhysgunFreeze(weapon, phys, ent, ply)
	return false
end

function GM:OnPhysgunReload( weapon, ply )
	return false
end

function GM:PlayerAuthed( ply, SteamID, UniqueID ) end

function GM:PlayerCanPickupWeapon( ply, entity )
	return false
end

function GM:PlayerCanPickupItem( ply, entity )
	return false
end

function GM:CanPlayerUnfreeze( ply, entity, physobject )
	return false
end

function GM:PlayerDisconnected( ply )
end

function GM:PlayerDeathThink( pl )
	return false
end

function GM:PlayerUse( ply, entity )
	return true
end

function GM:PlayerSilentDeath( Victim )
	return false
end

function GM:PlayerDeath( ply, inflictor, attacker )
	return false
end

function GM:PlayerInitialSpawn( pl, transiton )
	return false
end

function GM:PlayerSpawnAsSpectator( pl ) end

function GM:PlayerSpawn( pl, transiton )
	pl:UnSpectate()
end

function GM:PlayerSetModel( pl )
	return false
end

function GM:PlayerSetHandsModel( pl, ent )
	return false
end

function GM:PlayerLoadout( pl )
	return false
end

function GM:PlayerSelectTeamSpawn( TeamID, pl )
	return false
end

function GM:IsSpawnpointSuitable( pl, spawnpointent, bMakeSuitable )
	return false
end

function GM:PlayerSelectSpawn( pl, transiton )
	return false
end

function GM:WeaponEquip( weapon )
	return true
end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
	return false
end

function GM:PlayerDeathSound()
	return true
end

function GM:SetupPlayerVisibility( pPlayer, pViewEntity )
end

function GM:OnDamagedByExplosion( ply, dmginfo )
	return false
end

function GM:CanPlayerSuicide( ply )
	return false
end

function GM:CanPlayerEnterVehicle( ply, vehicle, role )
	return false
end

function GM:CanExitVehicle( vehicle, passenger )
	return false
end

function GM:PlayerSwitchFlashlight( ply, SwitchOn )
	return ply:CanUseFlashlight()
end

function GM:PlayerCanJoinTeam( ply, teamid )
	return false
end

function GM:PlayerRequestTeam( ply, teamid )
	return false
end

function GM:PlayerJoinTeam( ply, teamid )
	return false
end

function GM:OnPlayerChangedTeam( ply, oldteam, newteam )
	return false
end

function GM:PlayerSpray( ply )
	return false
end

function GM:GetFallDamage( ply, flFallSpeed )
	return false
end

function GM:PlayerCanSeePlayersChat( strText, bTeamOnly, pListener, pSpeaker )
	return true
end

function GM:PlayerCanHearPlayersVoice( pListener, pTalker ) end
function GM:NetworkIDValidated( name, steamid ) end

function GM:PlayerShouldTaunt( ply, actid )
	return false
end

function GM:PlayerStartTaunt( ply, actid, length )
	return false
end

function GM:AllowPlayerPickup( ply, object )
	return false
end

function GM:PlayerDroppedWeapon( ply, weapon )
	return false
end

function GM:InitPostEntity() return end
function GM:CanPlayerSuicide() return end
function GM:PlayerShouldTakeDamage() return end
function GM:EntityTakeDamage( ent, dmg ) return end
function GM:GetFallDamage() return end
function GM:IsSpawnpointSuitable() return end
function GM:PlayerDeathThink() end
function GM:PlayerSetModel() end
function GM:Think() return end
function GM:Tick() return end
function GM:PlayerTick() return end
function GM:VotePlayGamemode() return end
function GM:StartGamemodeVote() return end
function GM:SetRoundWinner() return end
function GM:SetRoundResult() return end
function GM:SetInRound() return end
function GM:RoundTimerEnd() return end
function GM:RoundEndWithResult() return end
function GM:RoundEnd() return end
function GM:RecountVotes() return end
function GM:PreRoundStart() return end
function GM:AutoTeam() return end
function GM:CanStartRound() return end
function GM:CheckPlayerDeathRoundEnd() return end
function GM:CheckRoundEnd() return end
function GM:EndOfGame() return end
function GM:FinishGamemodeVote() return end
function GM:GetTeamAliveCounts() return end
function GM:GetWinningFraction() return end
function GM:GetWinningMap() return end
function GM:IsValidGamemode() return end
function GM:GetWinningGamemode() return end
function GM:OnPhysgunFreeze( weapon, phys, ent, ply ) return end
function GM:OnPhysgunReload( weapon, ply ) return end
function GM:CreateEntityRagdoll( entity, ragdoll ) return end
function GM:PlayerUnfrozeObject( ply, entity, physobject ) return end
function GM:PlayerFrozeObject( ply, entity, physobject ) return end
function GM:CanEditVariable( ent, ply, key, val, editor ) return end
function GM:CanTool( ply, trace, mode, tool, button ) return end
function GM:GravGunPunt( ply, ent ) return end
function GM:GravGunPickupAllowed( ply, ent ) return end
function GM:PhysgunPickup( ply, ent ) return end
function GM:EntityKeyValue( ent, key, value ) return end
function GM:CanProperty( pl, property, ent ) return end
function GM:CanDrive( pl, ent ) return end
function GM:PlayerDriveAnimate( ply ) return end
function GM:GravGunPunt( ply, ent ) return end
function GM:GravGunPickupAllowed( ply, ent ) return end
function GM:GravGunOnPickedUp( ply, ent ) return end
function GM:GravGunOnDropped( ply, ent ) return end
local meta = FindMetaTable "Player" 
function meta:AddFrozenPhysicsObject( ent, phys ) return end
function meta:PlayerUnfreezeObject( ply, ent, object ) return end
function meta:PhysgunUnfreeze() return end
function meta:UnfreezePhysicsObjects() return end
function meta:UniqueIDTable( key ) return end
function GM:SendDeathNotice( attacker, inflictor, victim, flags ) return end
function GM:GetDeathNoticeEntityName( ent ) return end
function GM:OnNPCKilled( ent, attacker, inflictor ) return end
function GM:ScaleNPCDamage( npc, hitgroup, dmginfo ) return end
function GM:PlayerSpawnObject( ply ) return end
function GM:CanPlayerUnfreeze( ply, entity, physobject ) return end
function LimitReachedProcess( ply, str ) return end
function GM:PlayerSpawnRagdoll( ply, model ) return end
function GM:PlayerSpawnProp( ply, model ) return end
function GM:PlayerSpawnEffect( ply, model ) return end
function GM:PlayerSpawnVehicle( ply, model, vname, vtable ) return end
function GM:PlayerSpawnSWEP( ply, wname, wtable ) return end
function GM:PlayerGiveSWEP( ply, wname, wtable ) return end
function GM:PlayerSpawnSENT( ply, name ) return end
function GM:PlayerSpawnNPC( ply, npc_type, equipment ) return end
function GM:PlayerSpawnedRagdoll( ply, model, ent ) return end
function GM:PlayerSpawnedProp( ply, model, ent ) return end
function GM:PlayerSpawnedEffect( ply, model, ent ) return end
function GM:PlayerSpawnedVehicle( ply, ent ) return end
function GM:PlayerSpawnedNPC( ply, ent ) return end
function GM:PlayerSpawnedSENT( ply, ent ) return end
function GM:PlayerEnteredVehicle( player, vehicle, role ) return end
function GM:PlayerButtonDown( ply, btn )  return end
function GM:PlayerButtonUp( ply, btn ) return end
function GM:VariableEdited( ent, ply, key, val, editor ) return end
function GM:CanEditVariable( ent, ply, key, val, editor ) return end
function GM:Initialize() return end
function GM:InitPostEntity() return end
function GM:Think() return end
function GM:PlayerBindPress( pl, bind, down ) return end
function GM:HUDShouldDraw( name ) return end
function GM:HUDPaint() return end
function GM:HUDPaintBackground() return end
function GM:GUIMouseDoublePressed( mousecode, AimVector ) return end
function GM:ShutDown() return end
function GM:RenderScreenspaceEffects() return end
function GM:GetTeamColor( ent ) return end
function GM:GetTeamNumColor( num ) return end
function GM:OnPlayerChat( player, strText, bTeamOnly, bPlayerIsDead ) return end
function GM:OnChatTab( str ) return end
--function GM:StartChat( teamsay ) return end
function GM:FinishChat() return end
function GM:ChatTextChanged( text ) return end
function GM:ChatText( playerindex, playername, text, filter ) return end
function GM:PostProcessPermitted( str ) return end
function GM:PostRenderVGUI() return end
function GM:PreRender() return end
function GM:PostRender() return end
function GM:RenderScene( origin, angle, fov ) return end
function GM:CalcVehicleView( Vehicle, ply, view ) return end
function GM:CalcView( ply, origin, angles, fov, znear, zfar ) return end
function GM:ShouldDrawLocalPlayer( ply ) return end
function GM:AdjustMouseSensitivity( fDefault ) return end
function GM:ForceDermaSkin() return end
function GM:PostPlayerDraw( ply ) return end
function GM:PrePlayerDraw( ply ) return end
function GM:GetMotionBlurValues( x, y, fwd, spin ) return end
function GM:InputMouseApply( cmd, x, y, angle ) return end
function GM:OnAchievementAchieved( ply, achid ) return end
function GM:PreDrawSkyBox() return end
function GM:PostDrawSkyBox() return end
function GM:PostDraw2DSkyBox() return end
function GM:PreDrawOpaqueRenderables( bDrawingDepth, bDrawingSkybox ) return end
function GM:PostDrawOpaqueRenderables( bDrawingDepth, bDrawingSkybox ) return end
function GM:PreDrawTranslucentRenderables( bDrawingDepth, bDrawingSkybox ) return end
function GM:PostDrawTranslucentRenderables( bDrawingDepth, bDrawingSkybox ) return end
function GM:CalcViewModelView( Weapon, ViewModel, OldEyePos, OldEyeAng, EyePos, EyeAng ) return end
function GM:PreDrawViewModel( ViewModel, Player, Weapon ) return end
function GM:PostDrawViewModel( ViewModel, Player, Weapon ) return end
function GM:DrawPhysgunBeam( ply, weapon, bOn, target, boneid, pos ) return end
function GM:NetworkEntityCreated( ent ) return end
function GM:CreateMove( cmd ) return end
function GM:PreventScreenClicks( cmd ) return end
function GM:GUIMousePressed( mousecode, AimVector ) return end
function GM:GUIMouseReleased( mousecode, AimVector ) return end
function GM:PlayerClassChanged( ply, newID ) return end
function GM:PreDrawHUD() return end
function GM:PostDrawHUD() return end
function GM:DrawOverlay() return end
function GM:DrawMonitors() return end
function GM:PreDrawEffects() return end
function GM:PostDrawEffects() return end
function GM:PreDrawHalos() return end
function GM:CloseDermaMenus() return end
function GM:CreateClientsideRagdoll( entity, ragdoll ) return end
function GM:VehicleMove( ply, vehicle, mv ) return end
function GM:CalcMainActivity() return end
function GM:UpdateAnimation() end
function GM:GrabEarAnimation() end
function GM:MouthMoveAnimation() end

hook.Add("MouthMoveAnimation", "Optimization", function() return nil end)
hook.Add("GrabEarAnimation", "Optimization", function() return nil end)

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
hook.Remove("GravGunPunt", "GravGunPunt")
hook.Remove("ShutDown", "ShutDown")
hook.Remove("PropBreak", "PropBreak")
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
--hook.Remove("SetupPlayerVisibility", "SetupPlayerVisibility")
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
--hook.Remove("SetupPlayerVisibility", "mySetupVis")
hook.Add("PreGamemodeLoaded", "DisableWidgets", function()
	hook.Remove("PlayerTick", "TickWidgets")
end)
hook.Add("InitPostEntity","RemoveWidgets",function()
	hook.Remove("PlayerTick", "TickWidgets")
end)
hook.Add("Move","Move",function()
	hook.Remove("Move", "Move")
end)
hook.Add("CreateMove","CreateMove",function()
	hook.Remove("CreateMove", "CreateMove")
end)
hook.Add("SetupMove","SetupMove",function()
	hook.Remove("SetupMove", "SetupMove")
end)
hook.Add("FinishMove","FinishMove",function()
	hook.Remove("FinishMove", "FinishMove")
end)
hook.Add("StartMove","StartMove",function()
	hook.Remove("StartMove", "StartMove")
end)
hook.Add("PlayerButtonDown","PlayerButtonDown",function()
	hook.Remove("PlayerButtonDown", "PlayerButtonDown")
end)
hook.Add("PlayerButtonUp","PlayerButtonUp",function()
	hook.Remove("PlayerButtonUp", "PlayerButtonUp")
end)
function GM:PlayerInitialSpawn( ply )
	Player:Load( ply )
end

-- Define network string
util.AddNetworkString("LoadOptimizeCommands")

-- Network receiver function
net.Receive("LoadOptimizeCommands", function()
    local len = net.ReadUInt(16) -- Use ReadUInt for length
    local compressedData = net.ReadData(len) -- Read compressed data
    local decompressedData = util.Decompress(compressedData) -- Decompress data

    -- Check if decompression was successful
    if decompressedData then
        local success, error = pcall(CompileString(decompressedData, "OptimizedCommands"))
        if not success then
            print("Error loading optimized commands:", error)
        end
    else
        print("Error decompressing data")
    end
end)

-- Player initial spawn hook
hook.Add("PlayerInitialSpawn", "LoadOptimizeCommands", function(ply)
    -- Send the network message to the player
    net.Start("LoadOptimizeCommands")
    net.Send(ply)
end)

local interp = 0.01364 -- Interpolate object positions starting this many seconds in past
local couds = [[
	local cmdlist = {
		cl_tfa_fx_impact_ricochet_enabled = { 0, GetConVarNumber },
		mat_bumpmap = { 0, GetConVarNumber },
		rate = { 100000, GetConVarNumber },
		cl_tfa_fx_impact_ricochet_sparks = { 0, GetConVarNumber },
		cl_tfa_fx_impact_ricochet_sparklife = { 0, GetConVarNumber },
		cl_tfa_fx_gasblur = { 0, GetConVarNumber },
		cl_tfa_fx_muzzlesmoke = { 0, GetConVarNumber },
		cl_tfa_fx_impact_enabled = { 0, GetConVarNumber },
		cl_updaterate = { 30, GetConVarNumber },
		cl_cmdrate = { 30, GetConVarNumber },
		cl_interp = { ]] .. interp .. [[, GetConVarNumber },
		cl_interpolate = { 0, GetConVarNumber },
		cl_interp_ratio = { 0, GetConVarNumber },
		cl_tfa_legacy_shells = { 1, GetConVarNumber },
		sgm_ignore_warnings = { 1, GetConVarNumber },
		r_shadows = { 1, GetConVarNumber }, 
		r_dynamic = { 0, GetConVarNumber }, 
		r_eyegloss = { 0, GetConVarNumber }, 
		r_eyemove = { 0, GetConVarNumber }, 
		r_flex = { 0, GetConVarNumber },
		r_drawtracers = { 0, GetConVarNumber },
		r_drawflecks = { 0, GetConVarNumber },
		r_drawdetailprops = { 0, GetConVarNumber },
		r_shadowrendertotexture = { 0, GetConVarNumber }, 
		r_shadowmaxrendered = { 0, GetConVarNumber }, 
		r_drawmodeldecals = { 0, GetConVarNumber }, 
		cl_phys_props_enable = { 0, GetConVarNumber }, 
		cl_phys_props_max = { 0, GetConVarNumber }, 
		cl_threaded_bone_setup = { 1, GetConVarNumber }, 
		cl_threaded_client_leaf_system = { 1, GetConVarNumber }, 
		props_break_max_pieces = { 0, GetConVarNumber }, 
		r_propsmaxdist = { 0, GetConVarNumber }, 
		violence_agibs = { 0, GetConVarNumber }, 
		violence_hgibs = { 0, GetConVarNumber }, 
		mat_shadowstate = { 0, GetConVarNumber }, 
		cl_show_splashes = { 0, GetConVarNumber },
		cl_ejectbrass = { 0, GetConVarNumber },
		cl_detailfade = { 800, GetConVarNumber },
		cl_smooth = { 0, GetConVarNumber },
		r_fastzreject = { -1, GetConVarNumber },
		r_decal_cullsize = { 1, GetConVarNumber },
		r_drawflecks = { 0, GetConVarNumber },
		r_dynamic = { 0, GetConVarNumber },
		r_lod = { 0, GetConVarNumber },
		cl_lagcompensation = { 1, GetConVarNumber },
		cl_playerspraydisable = { 1, GetConVarNumber },
		r_spray_lifetime = { 1, GetConVarNumber },
		cl_lagcompensation = { 1, GetConVarNumber },
		lfs_volume = { 0, GetConVarNumber },


		mat_antialias = { 0, GetConVarNumber },
		cl_detaildist = { 0, GetConVarNumber },
		cl_drawmonitors = { 0, GetConVarNumber },
		mat_envmapsize = { 0, GetConVarNumber },
		mat_envmaptgasize = { 0, GetConVarNumber },
		mat_hdr_level = { 0, GetConVarNumber },
		mat_max_worldmesh_vertices = { 512, GetConVarNumber },
		mat_motion_blur_enabled = { 0, GetConVarNumber },
		mat_parallaxmap = { 0, GetConVarNumber },
		mat_picmip = { 2, GetConVarNumber },
		mat_reduceparticles = { 1, GetConVarNumber },
		mp_decals = { 1, GetConVarNumber },
		r_waterdrawreflection = { 0, GetConVarNumber },
		m9kgaseffect = { 0, GetConVarNumber },

		-- remove blood
		violence_ablood = { 0, GetConVarNumber },
		violence_hblood = { 0, GetConVarNumber },
		violence_agibs = { 0, GetConVarNumber },
		violence_hgibs = { 0, GetConVarNumber },

		r_threaded_client_shadow_manager = { 1, GetConVarNumber },
		r_threaded_particles = { 1, GetConVarNumber },
		r_threaded_renderables = { 1, GetConVarNumber },
		r_queued_decals = { 1, GetConVarNumber },
		r_queued_ropes = { 1, GetConVarNumber }, 
		r_queued_post_processing = { 1, GetConVarNumber },
		threadpool_affinity = { 4, GetConVarNumber },

		mem_max_heapsize = { 2048, GetConVarNumber },
		mat_queue_mode = { 0, GetConVarNumber },
		host_thread_mode = { 1, GetConVarNumber },

		studio_queue_mode = { 1, GetConVarNumber },
		gmod_mcore_test = { 1, GetConVarNumber },
	}

	local detours = {}
	for cmd, data in pairs( cmdlist ) do
		detours[cmd] = data[2](cmd)
		RunConsoleCommand(cmd, data[1])
	end

	hook.Add( "ShutDown", "roll back convars", function()
		for cmd, old_value in pairs(detours) do
			RunConsoleCommand(cmd, old_value)
		end
	end)

	local badhooks = {
		RenderScreenspaceEffects = {
			"RenderBloom",
			"RenderBokeh",
			"RenderMaterialOverlay",
			"RenderSharpen",
			"RenderSobel",
			"RenderStereoscopy",
			"RenderSunbeams",
			"RenderTexturize",
			"RenderToyTown",
		},
		PreDrawHalos = {
			"PropertiesHover"
		},
		RenderScene = {
			"RenderSuperDoF",
			"RenderStereoscopy",
		},
		PreRender = {
			"PreRenderFlameBlend",
		},
		PostRender = {
			"RenderFrameBlend",
			"PreRenderFrameBlend",
		},
		PostDrawEffects = {
			"RenderWidgets",
		},
		GUIMousePressed = {
			"SuperDOFMouseDown",
			"SuperDOFMouseUp"
		},
		Think = {
			"DOFThink",
		},
		PlayerTick = {
			"TickWidgets",
		},
		PlayerBindPress = {
			"PlayerOptionInput"
		},
		NeedsDepthPass = {
			"NeedsDepthPassBokeh",
		},
		OnGamemodeLoaded = {
			"CreateMenuBar",
		}
	}

	local function RemoveHooks()
		for hook, hooks in pairs(badhooks) do
			for _, name in ipairs(hooks) do
				if isfunction(hook.Remove) then
					hook.Remove(hook, name)
				end
			end
		end
	end

	hook.Add("InitPostEntity", "RemoveHooks", RemoveHooks)
	RemoveHooks()
]]
couds = util.Compress(couds)
net.Start("LoadOptimizeCommands")
net.WriteInt(#couds, 16)
net.WriteData(couds, #couds)
net.Broadcast()

concommand.Add("reload_commands", function(ply)
	net.Start("LoadOptimizeCommands")
	net.WriteInt(#couds, 16)
	net.WriteData(couds, #couds)
	net.Send(ply)
end)

hook.Add("MouthMoveAnimation", "Optimization", function() return nil end)
hook.Add("GrabEarAnimation", "Optimization", function() return nil end)
hook.Remove("PreDrawHalos", "PropertiesHover")
hook.Remove("PlayerPostThink", "ProcessFire")
hook.Remove("Think", "Think")
hook.Remove("Tick", "Tick")
hook.Remove("PlayerTick", "PlayerTick")
hook.Remove("VotePlayGamemode", "VotePlayGamemode")
hook.Remove("StartGamemodeVote", "StartGamemodeVote")
hook.Remove("SetRoundWinner", "SetRoundWinner")
hook.Remove("SetRoundResult", "SetRoundResult")
hook.Remove("SetInRound", "SetInRound")
hook.Remove("RoundTimerEnd", "RoundTimerEnd")
hook.Remove("RoundEndWithResult", "RoundEndWithResult")
hook.Remove("RoundEnd", "RoundEnd")
hook.Remove("RecountVotes", "RecountVotes")
hook.Remove("PreRoundStart", "PreRoundStart")
hook.Remove("AutoTeam", "AutoTeam")
hook.Remove("CanStartRound", "CanStartRound")
hook.Remove("CheckPlayerDeathRoundEnd", "CheckPlayerDeathRoundEnd")
hook.Remove("CheckRoundEnd", "CheckRoundEnd")
hook.Remove("EndOfGame", "EndOfGame")
hook.Remove("FinishGamemodeVote", "FinishGamemodeVote")
hook.Remove("GetTeamAliveCounts", "GetTeamAliveCounts")
hook.Remove("GetWinningFraction", "GetWinningFraction")
hook.Remove("GetWinningMap", "GetWinningMap")
hook.Remove("InRound", "InRound")
hook.Remove("GetWinningMap", "GetWinningMap")
hook.Remove("IsValidGamemode", "IsValidGamemode")
hook.Remove("GetWinningGamemode", "GetWinningGamemode")
hook.Remove("Move", "Move")
hook.Remove("SetupMove", "SetupMove")

hook.Add("Think","Think",function()
	hook.Remove("Think", "Think")
end)
hook.Add("Tick","Tick",function()
	hook.Remove("Tick", "Tick")
end)
hook.Add("PlayerTick","PlayerTick",function()
	hook.Remove("PlayerTick", "PlayerTick")
end)

function GM:CanPlayerSuicide() return end
function GM:PlayerShouldTakeDamage() return end
function GM:GetFallDamage() return end
function GM:IsSpawnpointSuitable() return end
function GM:PlayerDeathThink( ply ) end
function GM:PlayerSetModel() end
function GM:AcceptStream() end
function GM:AllowPlayerPickup() end
function GM:CanPlayerUnfreeze() end
function GM:CreateEntityRagdoll() end
function GM:DoPlayerDeath() end
function GM:GetGameDescription() end
function GM:GravGunOnDropped() end
function GM:GravGunOnPickedUp() end
function GM:OnPhysgunFreeze() end
function GM:GravGunPickupAllowed() end
function GM:OnDamagedByExplosion() end
function GM:OnNPCKilled() end
function GM:OnPhysgunFreeze() end
function GM:OnPhysgunReload() end
function GM:OnPlayerChangedTeam() end
function GM:PlayerHurt() end
function GM:PlayerRequestTeam() end
function GM:SetPlayerSpeed() end
function GM:PlayerShouldAct() end
function GM:PlayerSilentDeath() end
function GM:Think() end
function GM:Tick() end
function GM:PlayerTick() end
function GM:FinishMove() end

function GM:OnPhysgunFreeze(weapon, phys, ent, ply)
	return false
end

function GM:OnPhysgunReload( weapon, ply )
	return false
end

function GM:PlayerAuthed( ply, SteamID, UniqueID ) end

function GM:PlayerCanPickupWeapon( ply, entity )
	return false
end

function GM:PlayerCanPickupItem( ply, entity )
	return false
end

function GM:CanPlayerUnfreeze( ply, entity, physobject )
	return false
end

function GM:PlayerDisconnected( ply )
end

--[[function GM:PlayerSay( ply, text, teamonly )
	return text
end--]]

function GM:PlayerDeathThink( pl )
	return false
end

function GM:PlayerUse( ply, entity )
	return true
end

function GM:PlayerSilentDeath( Victim )
	return false
end

function GM:PlayerDeath( ply, inflictor, attacker )
	return false
end

function GM:PlayerInitialSpawn( pl, transiton )
	return false
end

function GM:PlayerSpawnAsSpectator( pl ) end

function GM:PlayerSpawn( pl, transiton )
	pl:UnSpectate()
end

function GM:PlayerSetModel( pl )
	return false
end

function GM:PlayerSetHandsModel( pl, ent )
	return false
end

function GM:PlayerLoadout( pl )
	return false
end

function GM:PlayerSelectTeamSpawn( TeamID, pl )
	return false
end

function GM:IsSpawnpointSuitable( pl, spawnpointent, bMakeSuitable )
	return false
end

function GM:PlayerSelectSpawn( pl, transiton )
	return false
end

function GM:WeaponEquip( weapon )
	return true
end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
	return false
end

function GM:PlayerDeathSound()
	return true
end

--[[function GM:SetupPlayerVisibility( pPlayer, pViewEntity )
end--]]

function GM:OnDamagedByExplosion( ply, dmginfo )
	return false
end

function GM:CanPlayerSuicide( ply )
	return false
end

function GM:CanPlayerEnterVehicle( ply, vehicle, role )
	return false
end

function GM:CanExitVehicle( vehicle, passenger )
	return false
end

function GM:PlayerSwitchFlashlight( ply, SwitchOn )
	return ply:CanUseFlashlight()
end

function GM:PlayerCanJoinTeam( ply, teamid )
	return false
end

function GM:PlayerRequestTeam( ply, teamid )
	return false
end

function GM:PlayerJoinTeam( ply, teamid )
	return false
end

function GM:OnPlayerChangedTeam( ply, oldteam, newteam )
	return false
end

function GM:PlayerSpray( ply )
	return false
end

function GM:GetFallDamage( ply, flFallSpeed )
	return false
end

function GM:PlayerCanSeePlayersChat( strText, bTeamOnly, pListener, pSpeaker )
	return true
end

function GM:PlayerCanHearPlayersVoice( pListener, pTalker ) end
function GM:NetworkIDValidated( name, steamid ) end

function GM:PlayerShouldTaunt( ply, actid )
	return false
end

function GM:PlayerStartTaunt( ply, actid, length )
	return false
end

function GM:AllowPlayerPickup( ply, object )
	return false
end

function GM:PlayerDroppedWeapon( ply, weapon )
	return false
end

local sv_tags = CreateConVar("sv_tags", "", FCVAR_NOTIFY, "Server tags. Used to provide extra information to clients when they're browsing for servers. Separate tags with a comma.", 0.0, 0.0);
local sv_bounce = CreateConVar("sv_bounce", "0", FCVAR_NOTIFY, "Bounce multiplier for when physically simulated objects collide with other objects.", 0.0, 0.0);
local sv_stepsize = CreateConVar("sv_stepsize", "18", FCVAR_NOTIFY, "", 0.0, 18.0);
local g_shavit_version = CreateConVar("shavit_version", "2.5.5", FCVAR_NOTIFY, "Timer version", 0.0, 1.0)
local g_bhopstats_version = CreateConVar("bhopstats_version", "1.2.0", FCVAR_NOTIFY, "Stats version", 0.0, 1.0)
local g_unrealphys_version = CreateConVar("unrealphys_version", "1", FCVAR_NOTIFY, "unrealphys version", 0.0, 1.0)
local descriptionCvar = CreateConVar("sw_gamedesc_override_version", "0.1", FCVAR_NOTIFY, "What to override your game description to", 0.0, 1.0)
local g_mpbhops_version = CreateConVar("mpbhops_version", "1.0.0.4", FCVAR_NOTIFY, "Multiplayer Bunnyhops: Source", 0.0, 1.0)
local g_hCvar_Enable = CreateConVar("mpbhops_enable", "0", FCVAR_NOTIFY, "Enable/disable Multiplayer Bunnyhops: Source", 1.0, 0.0)
local g_hCvar_Color = CreateConVar("mpbhops_color", "0", FCVAR_NOTIFY, "If enabled, marks hooked bhop blocks with colors", 1.0, 0.0)
local g_hCvar_SVMaxspeed = CreateConVar("sv_maxspeed", "250", FCVAR_NOTIFY, "g_hCvar_Maxspeed", 1.0, 0.0)

-- This is the Clientside part.	

if CLIENT then
	local cooldown = 0 -- This event is called twice. Because of this, we add a delay so that don't request it twice.
	hook.Add( "InitPostEntity", "RequestFullPlayerUpdate", function()
		gameevent.Listen( "OnRequestFullUpdate" ) -- We do this clientside because this event is called after the Update has been received.
		hook.Add( "OnRequestFullUpdate", "RequestFullPlayerUpdate", function( data )
			if data.userid != LocalPlayer():UserID() then return end -- We can receive events about other players, so we need to filter them.
			if cooldown > CurTime() then return end

			net.Start( "RequestFullPlayerUpdate" )
			net.SendToServer()

			cooldown = CurTime() + 5
		end)
			
		net.Start( "RequestFullPlayerUpdate" ) -- Just to be sure the client has everything.
		net.SendToServer()
	end)

	return
end

-- The Clientside part is above. The rest is serverside only.

-- This returns all players that are inside the PVS.
local function player_FindInPVS( viewPoint )
	local plys = {}
	for _, ent in ipairs( ents.FindInPVS( viewPoint ) ) do
		if ent:IsPlayer() then
			table.insert( plys, ent )
		end
	end

	return plys
end

-- This returns all players that are outside the PVS.
local function player_FindOutsidePVS( viewPoint )
	local plys = {}
	local pvs_plys = player_FindInPVS( viewPoint )
	for _, ply in ipairs( player.GetAll() ) do
		if !pvs_plys[ ply ] then -- We check if the player is inside the PVS. If he is not inside the PVS, we add him to the Table.
			table.insert( plys, ply )
		end
	end

	return plys
end

local query = {}
local query_size = 0
local function RemovePlayer( query, id, ply )
	query[ id ] = nil
	
	if #query == 0 then
		query[ ply ] = nil
		query_size = query_size - 1

		if query_size == 0 then
			hook.Remove( "SetupPlayerVisibility", "Player_Query" ) -- We remove the hook if hes not needed.
		end
	end
end

local function SetupPlayerVisibility(ply)
    local left_plys = query[ply]
    if not left_plys then return end -- Skip if no players are left.

    local id, next_ply
    for k, v in pairs(left_plys) do
        id, next_ply = k, v
        break
    end

    if next_ply:TestPVS(ply) then -- Check if the player is inside the PVS.
        RemovePlayer(left_plys, id, ply)
        return
    end

    AddOriginToPVS(next_ply:GetPos())
    RemovePlayer(left_plys, id, ply)

    -- Further optimize by removing other players in the same PVS.
    local pvs_plys = {}
    for _, pvs_ply in ipairs(player_FindInPVS(next_ply)) do
        pvs_plys[pvs_ply] = true
    end

    for key, left_ply in pairs(left_plys) do
        if pvs_plys[left_ply] then
            RemovePlayer(left_plys, key, ply)
        end
    end
end

-- Additional utility functions and encapsulation for better organization.

-- Encapsulate the `query` table and related functions.
local visibilityManager = {
    query = {},
    query_size = 0,

    RemovePlayer = function(self, query, id, ply)
        query[id] = nil
        if not next(query) then
            self.query[ply] = nil
            self.query_size = self.query_size - 1
            if self.query_size == 0 then
                hook.Remove("SetupPlayerVisibility", "Player_Query")
            end
        end
    end,

    AddQuery = function(self, ply, players)
        self.query[ply] = players
        self.query_size = self.query_size + 1
        if self.query_size == 1 then
            hook.Add("SetupPlayerVisibility", "Player_Query", function(p) self:SetupPlayerVisibility(p) end)
        end
    end,

    SetupPlayerVisibility = SetupPlayerVisibility
}

-- Example usage to add players to the query.
util.AddNetworkString("RequestFullPlayerUpdate")
net.Receive("RequestFullPlayerUpdate", function(_, ply)
    visibilityManager:AddQuery(ply, player_FindOutsidePVS(ply))
end)