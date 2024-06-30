Client = {}

include("shared.lua")
include("essential/sh_movement.lua")

-- UI
local ui_files = {
    "cl_receive.lua", "cl_settings.lua", "cl_themes.lua", "cl_ui.lua", "cl_hud.lua",
    "menu/cl_menu.lua", "menu/cl_interface.lua", "menu/cl_display.lua",
    "menu/cl_other.lua", "menu/cl_beta.lua"
}

for _, file in ipairs(ui_files) do
    include("userinterface/" .. file)
end

include("modules/fpsfixes/cl_buffthefps.lua")
include("modules/fpsfixes/sh_disablehooks.lua")
include("modules/fpsfixes/cl_disablehooks.lua")
include("essential/timer/cl_timer.lua")
include("modules/fpsfixes/cl_nixthelag.lua")
include("modules/fpsfixes/sh_serialization.lua")
include("userinterface/cl_gui.lua")
include("modules/admin/cl_admin.lua")
include("modules/cl_strafe.lua")
include("modules/cl_commands.lua")
include("userinterface/scoreboards/cl_default.lua")

local function createClientConVars()
    CreateClientConVar("sl_showothers", "1", true, false)
    CreateClientConVar("sl_steamgroup", "1", true, false)
    CreateClientConVar("sl_crosshair", "1", true, false)
    CreateClientConVar("sl_targetids", "0", true, false)
    CreateClientConVar("bhop_anticheats", "0", true, false)
    CreateClientConVar("bhop_gunsounds", "1", true, false)
    CreateClientConVar("kawaii_mousesource", "1", true, false, "Enable mouse source smoothing.")
    CreateClientConVar("kawaii_fov", GetConVarNumber("fov_desired"))
    CreateClientConVar("kawaii_view_angle", 2)
    CreateClientConVar("kawaii_suppress_viewpunch", "0", true, false, "Suppress viewpunch.")
    CreateClientConVar("kawaii_suppress_viewpunch_wep", "0", true, false, "Suppress viewpunch for weapons.")
    CreateClientConVar("kawaii_steady_view", "0", true, false, "Steady weapon view.")
    CreateClientConVar("kawaii_triggers", "0", true, false)
    CreateClientConVar("bhop_showplayers", 1, true, false, "Shows bhop players", 0, 1)
    CreateClientConVar("bhop_flipweapons", 0, true, false, "Flips weapon view models.", 0, 1)
    CreateClientConVar("bhop_weaponsway", 1, true, false, "Controls how weapon view models move.", 0, 1)
end

createClientConVars()

local function SetHullAndViewOffset()
    local ply = LocalPlayer()
    if IsValid(ply) and ply.SetHull and ply.SetHullDuck then
        if ply.SetViewOffset and ply.SetViewOffsetDucked and not viewset then
            viewset = true
            ply:SetViewOffset( _C["Player"].ViewStand )
            ply:SetViewOffsetDucked( _C["Player"].ViewDuck )
        end
        ply:SetHull(_C["Player"].HullMin, _C["Player"].HullStand)
        ply:SetHullDuck(_C["Player"].HullMin, _C["Player"].HullDuck)
    end
end

local function InitializeClient()
    timer.Create("SetHullAndView", 0.01, 0, SetHullAndViewOffset)
end
hook.Add("Initialize", "CInitialize", InitializeClient)

local function toggleCrosshair(tabData)
    if tabData then
        for cmd, target in pairs(tabData) do
            RunConsoleCommand(cmd, tostring(target))
        end
        Link:Print("General", "Your crosshair options have been changed!")
    else
        HUDItems["CHudCrosshair"] = not HUDItems["CHudCrosshair"]
        RunConsoleCommand("sl_crosshair", HUDItems["CHudCrosshair"] and 1 or 0)
        Link:Print("General", "Crosshair visibility has been toggled")
    end
end

function Client:ToggleTargetIDs()
    local nNew = 1 - GetConVar("sl_targetids"):GetInt()
    RunConsoleCommand("sl_targetids", nNew)
    Link:Print("General", "You have " .. (nNew == 0 and "disabled" or "enabled") .. " player labels")
end

function Client:PlayerVisibility(nTarget)
    local nNew = -1
    if GetConVar("sl_showothers"):GetInt() == nTarget then
        RunConsoleCommand("sl_showothers", 1 - nTarget)
        timer.Simple(1, function() RunConsoleCommand("sl_showothers", nTarget) end)
        nNew = nTarget
    elseif nTarget < 0 then
        nNew = 1 - GetConVar("sl_showothers"):GetInt()
        RunConsoleCommand("sl_showothers", nNew)
    else
        nNew = nTarget
        RunConsoleCommand("sl_showothers", nNew)
    end

    if nNew >= 0 then
        Link:Print("General", "You have set player visibility to " .. (nNew == 0 and "invisible" or "visible"))
    end
end

function Client:ShowHelp(tab)
    print("\n\nBelow is a list of all available commands and their aliases:\n\n")

    table.sort(tab, function(a, b)
        if not a or not b or not a[2] or not a[2][1] then return false end
        return a[2][1] < b[2][1]
    end)

    for _, data in pairs(tab) do
        local desc, alias = data[1], data[2]
        local main = table.remove(alias, 1)

        MsgC(Color(212, 215, 134), "\tCommand: ") MsgC(Color(255, 255, 255), main .. "\n")
        MsgC(Color(212, 215, 134), "\t\tAliases: ") MsgC(Color(255, 255, 255), (#alias > 0 and table.concat(alias, ", ") or "None") .. "\n")
        MsgC(Color(212, 215, 134), "\t\tDescription: ") MsgC(Color(255, 255, 255), desc .. "\n\n")
    end

    Link:Print("General", "A list of commands and their descriptions has been printed in your console! Press ~ to open.")
end

function Client:ShowEmote(data)
    local ply
    for _, p in pairs(player.GetHumans()) do
        if tostring(p:SteamID()) == data[1] then
            ply = p
            break
        end
    end
    if not IsValid(ply) then return end

    if ply:GetNWInt("AccessIcon", 0) > 0 then
        local tab = {}
        local VIPNameColor = ply:GetNWVector("VIPNameColor", Vector(-1, 0, 0))
        if VIPNameColor.x >= 0 then
            local VIPName = ply:GetNWString("VIPName", "")
            if VIPName == "" then
                VIPName = ply:Name()
            end

            if VIPNameColor.x == 256 then
                tab = Client:GenerateName(tab, VIPName .. " ")
            elseif VIPNameColor.x == 257 then
                tab = Client:GenerateName(tab, VIPName .. " ", ply)
            else
                table.insert(tab, Core.Util:VectorToColor(VIPNameColor))
                table.insert(tab, VIPName .. " ")
            end

            if Client.VIPReveal and VIPName ~= ply:Name() then
                table.insert(tab, GUIColor.White)
                table.insert(tab, "(" .. ply:Name() .. ") ")
            end
        else
            table.insert(tab, Color(98, 176, 255))
            table.insert(tab, ply:Name() .. " ")
        end

        table.insert(tab, GUIColor.White)
        table.insert(tab, tostring(data[2]))

        chat.AddText(unpack(tab))
    end
end

function Client:VerifyList()
    if file.Exists(Cache.M_Name, "DATA") then
        Cache:M_Load()
    end
end

function Client:Mute(bMute)
    for _, p in pairs(player.GetHumans()) do
        if LocalPlayer() and p ~= LocalPlayer() then
            p:SetMuted(bMute)
        end
    end

    Link:Print("General", "All players have been " .. (bMute and "muted" or "unmuted") .. ".")
end

function Client:DoChatMute(szID, bMute)
    for _, p in pairs(player.GetHumans()) do
        if tostring(p:SteamID()) == szID then
            p.ChatMuted = bMute
            Link:Print("General", p:Name() .. " has been " .. (bMute and "chat muted" or "unmuted") .. "!")
        end
    end
end

function Client:DoVoiceGag(szID, bGag)
    for _, p in pairs(player.GetHumans()) do
        if tostring(p:SteamID()) == szID then
            p:SetMuted(bGag)
            Link:Print("General", p:Name() .. " has been " .. (bGag and "voice gagged" or "ungagged") .. "!")
        end
    end
end

function Client:GenerateName(tab, szName, gradient)
    szName = szName:gsub('[^%w ]', '')
    local count = #szName
    local start, stop = Core.Util:RandomColor(), Core.Util:RandomColor()
    if gradient then
        local gs = gradient:GetNWVector("VIPGradientS", Vector(-1, 0, 0))
        local ge = gradient:GetNWVector("VIPGradientE", Vector(-1, 0, 0))

        if gs.x >= 0 then start = Core.Util:VectorToColor(gs) end
        if ge.x >= 0 then stop = Core.Util:VectorToColor(ge) end
    end

    for i = 1, count do
        local percent = i / count
        table.insert(tab, Color(start.r + percent * (stop.r - start.r), start.g + percent * (stop.g - start.g), start.b + percent * (stop.b - start.b)))
        table.insert(tab, szName[i])
    end

    return tab
end

function Client:ToggleChat()
    local nTime = GetConVar("hud_saytext_time"):GetInt()
    if nTime > 0 then
        Link:Print("General", "The chat has been hidden.")
        RunConsoleCommand("hud_saytext_time", 0)
    else
        Link:Print("General", "The chat has been restored.")
        RunConsoleCommand("hud_saytext_time", 12)
    end
end

function Client:SpecVisibility(arg)
    local nNew = arg and tonumber(arg) or 1 - Timer:GetSpecSetting()
    RunConsoleCommand("sl_showspec", nNew)
    Link:Print("General", "You have set spectator list visibility to " .. (nNew == 0 and "invisible" or "visible"))
end

function Client:ChangeWater()
    local a, b, c = GetConVar("r_waterdrawrefraction"):GetInt(), GetConVar("r_waterdrawreflection"):GetInt(), 1 - GetConVar("r_waterdrawrefraction"):GetInt()
    RunConsoleCommand("r_waterdrawrefraction", c)
    RunConsoleCommand("r_waterdrawreflection", c)
    Link:Print("General", "Water reflection and refraction have been " .. (c == 0 and "disabled" or "re-enabled") .. "!")
end

function Client:ClearDecals()
    RunConsoleCommand("r_cleardecals")
    Link:Print("General", "All players decals have been cleared from your screen.")
end

function Client:ToggleReveal()
    Client.VIPReveal = not Client.VIPReveal
    Link:Print("General", "True VIP names will now " .. (Client.VIPReveal and "" or "no longer ") .. "be shown")
end

function Client:DoFlipWeapons()
    local n = 0
    for _, wep in pairs(LocalPlayer():GetWeapons()) do
        if wep.ViewModelFlip ~= Client.FlipStyle then
            wep.ViewModelFlip = Client.FlipStyle
        end
        n = n + 1
    end
    return n
end

function Client:FlipWeapons(bRestart)
    if IsValid(LocalPlayer()) then
        if not bRestart then
            Client.Flip = not Client.Flip
            Client.FlipStyle = not Client.Flip
            local n = Client:DoFlipWeapons()
            Link:Print("General", n > 0 and "Your weapons have been flipped!" or "You had no weapons to flip. Flip again to revert back.")
        elseif Client.Flip then
            timer.Simple(0.1, function() Client:DoFlipWeapons() end)
        end
    end
end

function Client:ToggleSpace(bStart)
    if bStart then
        Client.SpaceToggle = not Client.SpaceToggle
    else
        if not IsValid(LocalPlayer()) then return end
        if not Client.SpaceEnabled then
            Client.SpaceEnabled = true
            LocalPlayer():ConCommand("+jump")
        else
            LocalPlayer():ConCommand("-jump")
            Client.SpaceEnabled = nil
        end
    end
end

local function ChatEdit(nIndex, szName, szText, szID)
    if szID == "joinleave" then
        return true
    end
end
hook.Add("ChatText", "SuppressMessages", ChatEdit)

local function ChatTag(ply, szText, bTeam, bDead)
    if ply.ChatMuted then
        print("[CHAT MUTE] " .. ply:Name() .. ": " .. szText)
        return true
    end

    local tab = {}
    if bTeam then
        table.insert(tab, Color(30, 160, 40))
        table.insert(tab, "(TEAM) ")
    end

    if ply:GetNWInt("Spectating", 0) == 1 then
        table.insert(tab, Color(189, 195, 199))
        table.insert(tab, "*SPEC* ")
    end

    local nAccess = ply:GetNWInt("AccessIcon", 0)
    local ID = ply:GetNWInt("Rank", 1)
    table.insert(tab, GUIColor.White)

    local VIPTag, VIPTagColor = ply:GetNWString("VIPTag", ""), ply:GetNWVector("VIPTagColor", Vector(-1, 0, 0))
    if nAccess > 0 and VIPTag ~= "" and VIPTagColor.x >= 0 then
        table.insert(tab, Core.Util:VectorToColor(VIPTagColor))
        table.insert(tab, "[" .. VIPTag .. "] ")
        table.insert(tab, GUIColor.White)
    else
        table.insert(tab, _C.Ranks[ID][2])
        table.insert(tab, "[" .. _C.Ranks[ID][1] .. "] ")
        table.insert(tab, GUIColor.White)
    end

    if nAccess > 0 then
        local VIPNameColor = ply:GetNWVector("VIPNameColor", Vector(-1, 0, 0))
        if VIPNameColor.x >= 0 then
            local VIPName = ply:GetNWString("VIPName", "")
            if VIPName == "" then
                VIPName = ply:Name()
            end

            if VIPNameColor.x == 256 then
                tab = Client:GenerateName(tab, VIPName)
            elseif VIPNameColor.x == 257 then
                tab = Client:GenerateName(tab, VIPName, ply)
            else
                table.insert(tab, Core.Util:VectorToColor(VIPNameColor))
                table.insert(tab, VIPName)
            end

            if Client.VIPReveal and VIPName ~= ply:Name() then
                table.insert(tab, GUIColor.White)
                table.insert(tab, " (" .. ply:Name() .. ")")
            end
        else
            table.insert(tab, Color(98, 176, 255))
            table.insert(tab, ply:Name())
        end
    else
        table.insert(tab, Color(98, 176, 255))
        table.insert(tab, ply:Name())
    end

    table.insert(tab, GUIColor.White)
    table.insert(tab, ": ")

    if nAccess > 0 then
        local VIPChat = ply:GetNWVector("VIPChat", Vector(-1, 0, 0))
        if VIPChat.x >= 0 then
            table.insert(tab, Core.Util:VectorToColor(VIPChat))
        end
    end

    table.insert(tab, szText)

    chat.AddText(unpack(tab))
    return true
end
hook.Add("OnPlayerChat", "TaggedChat", ChatTag)

local function EntityCheckPost()
    RunConsoleCommand("sl_targetids", 0)

    local hooksToRemove = {
        ["PostDrawOpaqueRenderables"] = { "PlayerMarkers" },
        ["PlayerTick"] = { "TickWidgets" },
        ["SetupMove"] = { "SetupMove" },
        ["Move"] = { "Move" },
        ["StartMove"] = { "StartMove" },
        ["FinishMove"] = { "FinishMove" },
        ["CreateMove"] = { "CreateMove" },
        ["Tick"] = { "Tick" },
        ["Think"] = { "Think" },
        ["StartCommand"] = { "StartCommand" },
        ["PostZombieKilledHuman"] = { "PostZombieKilledHuman" },
        ["PrePlayerRedeemed"] = { "PrePlayerRedeemed" },
        ["AcceptStream"] = { "AcceptStream" },
        ["AllowPlayerPickup"] = { "AllowPlayerPickup" },
        ["CanExitVehicle"] = { "CanExitVehicle" },
        ["CanPlayerSuicide"] = { "CanPlayerSuicide" },
        ["CanPlayerUnfreeze"] = { "CanPlayerUnfreeze" },
        ["CreateEntityRagdoll"] = { "CreateEntityRagdoll" },
        ["DoPlayerDeath"] = { "DoPlayerDeath" },
        ["EntityTakeDamage"] = { "EntityTakeDamage" },
        ["GetFallDamage"] = { "GetFallDamage" },
        ["GetGameDescription"] = { "GetGameDescription" },
        ["GravGunOnDropped"] = { "GravGunOnDropped" },
        ["GravGunPickupAllowed"] = { "GravGunPickupAllowed" },
        ["IsSpawnpointSuitable"] = { "IsSpawnpointSuitable" },
        ["NetworkIDValidated"] = { "NetworkIDValidated" },
        ["OnDamagedByExplosion"] = { "OnDamagedByExplosion" },
        ["OnNPCKilled"] = { "OnNPCKilled" },
        ["OnPhysgunFreeze"] = { "OnPhysgunFreeze" },
        ["OnPhysgunReload"] = { "OnPhysgunReload" },
        ["OnPlayerChangedTeam"] = { "OnPlayerChangedTeam" },
        ["PlayerCanJoinTeam"] = { "PlayerCanJoinTeam" },
        ["PlayerCanPickupItem"] = { "PlayerCanPickupItem" },
        ["PlayerCanPickupWeapon"] = { "PlayerCanPickupWeapon" },
        ["PlayerDeath"] = { "PlayerDeath" },
        ["PlayerDeathSound"] = { "PlayerDeathSound" },
        ["PlayerDeathThink"] = { "PlayerDeathThink" },
        ["PlayerDisconnected"] = { "PlayerDisconnected" },
        ["PlayerHurt"] = { "PlayerHurt" },
        ["PlayerInitialSpawn"] = { "PlayerInitialSpawn" },
        ["PlayerJoinTeam"] = { "PlayerJoinTeam" },
        ["PlayerLeaveVehicle"] = { "PlayerLeaveVehicle" },
        ["PlayerLoadout"] = { "PlayerLoadout" },
        ["PlayerRequestTeam"] = { "PlayerRequestTeam" },
        ["PlayerSelectSpawn"] = { "PlayerSelectSpawn" },
        ["PlayerSelectTeamSpawn"] = { "PlayerSelectTeamSpawn" },
        ["PlayerSetModel"] = { "PlayerSetModel" },
        ["PlayerShouldAct"] = { "PlayerShouldAct" },
        ["PlayerShouldTakeDamage"] = { "PlayerShouldTakeDamage" },
        ["PlayerSilentDeath"] = { "PlayerSilentDeath" },
        ["PlayerSpawn"] = { "PlayerSpawn" },
        ["PlayerSpawnAsSpectator"] = { "PlayerSpawnAsSpectator" },
        ["PlayerSpray"] = { "PlayerSpray" },
        ["PlayerSwitchFlashlight"] = { "PlayerSwitchFlashlight" },
        ["PlayerUse"] = { "PlayerUse" },
        ["ScaleNPCDamage"] = { "ScaleNPCDamage" },
        ["SetPlayerSpeed"] = { "SetPlayerSpeed" },
        ["SetupPlayerVisibility"] = { "SetupPlayerVisibility", "mySetupVis" },
        ["WeaponEquip"] = { "WeaponEquip" },
        ["CalcMainActivity"] = { "CalcMainActivity" },
        ["CanPlayerEnterVehicle"] = { "CanPlayerEnterVehicle" },
        ["CompletedIncomingStream"] = { "CompletedIncomingStream" },
        ["ContextScreenClick"] = { "ContextScreenClick" },
        ["CreateTeams"] = { "CreateTeams" },
        ["DoAnimationEvent"] = { "DoAnimationEvent" },
        ["EntityKeyValue"] = { "EntityKeyValue" },
        ["EntityRemoved"] = { "EntityRemoved" },
        ["GravGunPunt"] = { "GravGunPunt" },
        ["HandlePlayerDriving"] = { "HandlePlayerDriving" },
        ["HandlePlayerJumping"] = { "HandlePlayerJumping" },
        ["Initialize"] = { "Initialize" },
        ["InitPostEntity"] = { "InitPostEntity", "StartEntityCheck" },
        ["KeyPress"] = { "KeyPress" },
        ["KeyRelease"] = { "KeyRelease" },
        ["OnEntityCreated"] = { "OnEntityCreated" },
        ["OnPlayerHitGround"] = { "OnPlayerHitGround" },
        ["PhysgunDrop"] = { "PhysgunDrop" },
        ["PlayerAuthed"] = { "PlayerAuthed" },
        ["PlayerConnect"] = { "PlayerConnect" },
        ["PlayerEnteredVehicle"] = { "PlayerEnteredVehicle" },
        ["PlayerNoClip"] = { "PlayerNoClip" },
        ["PlayerFootstep"] = { "PlayerFootstep" },
        ["PlayerStepSoundTime"] = { "PlayerStepSoundTime" },
        ["PlayerTraceAttack"] = { "PlayerTraceAttack" },
        ["PostGamemodeLoaded"] = { "PostGamemodeLoaded" },
        ["PropBreak"] = { "PropBreak" },
        ["Restored"] = { "Restored" },
        ["Saved"] = { "Saved" },
        ["ShouldCollide"] = { "ShouldCollide" },
        ["ShutDown"] = { "ShutDown" },
        ["TranslateActivity"] = { "TranslateActivity" },
        ["UpdateAnimation"] = { "UpdateAnimation" },
        ["CanTool"] = { "CanTool" },
        ["PlayerGiveSWEP"] = { "PlayerGiveSWEP" },
        ["PlayerSpawnedEffect"] = { "PlayerSpawnedEffect" },
        ["PlayerSpawnedNPC"] = { "PlayerSpawnedNPC" },
        ["PlayerSpawnedProp"] = { "PlayerSpawnedProp" },
        ["PlayerSpawnedRagdoll"] = { "PlayerSpawnedRagdoll" },
        ["PlayerSpawnedSENT"] = { "PlayerSpawnedSENT" },
        ["PlayerSpawnedVehicle"] = { "PlayerSpawnedVehicle" },
        ["PlayerSpawnEffect"] = { "PlayerSpawnEffect" },
        ["PlayerSpawnNPC"] = { "PlayerSpawnNPC" },
        ["PlayerSpawnObject"] = { "PlayerSpawnObject" },
        ["PlayerSpawnProp"] = { "PlayerSpawnProp" },
        ["PlayerSpawnRagdoll"] = { "PlayerSpawnRagdoll" },
        ["PlayerSpawnSENT"] = { "PlayerSpawnSENT" },
        ["PlayerSpawnSWEP"] = { "PlayerSpawnSWEP" },
        ["PlayerSpawnVehicle"] = { "PlayerSpawnVehicle" },
        ["AddHint"] = { "AddHint" },
        ["AddNotify"] = { "AddNotify" },
        ["GetSENTMenu"] = { "GetSENTMenu" },
        ["GetSWEPMenu"] = { "GetSWEPMenu" },
        ["PaintNotes"] = { "PaintNotes" },
        ["PopulateSTOOLMenu"] = { "PopulateSTOOLMenu" },
        ["SpawnMenuEnabled"] = { "SpawnMenuEnabled" },
        ["OnUndo"] = { "OnUndo" }
    }

    for hookType, hookNames in pairs(hooksToRemove) do
        for _, hookName in ipairs(hookNames) do
            if hook.GetTable()[hookType] and hook.GetTable()[hookType][hookName] then
                hook.Remove(hookType, hookName)
            else
                --print("Hook not found or already removed:", hookType, hookName)
            end
        end
    end
end
hook.Add("InitPostEntity", "StartEntityCheck", EntityCheckPost)

local function VisibilityCallback(CVar, Previous, New)
    local show = tonumber(New) == 1
    for _, ent in pairs(ents.FindByClass("env_spritetrail")) do
        ent:SetNoDraw(not show)
    end
    for _, ent in pairs(ents.FindByClass("beam")) do
        ent:SetNoDraw(not show)
    end
end
cvars.AddChangeCallback("bhop_showplayers", VisibilityCallback)

concommand.Add("bhop_showplayers_toggle", function(client)
    LocalPlayer():ConCommand("bhop_showplayers " .. (GetConVar("bhop_showplayers"):GetInt() == 0 and 1 or 0))
end)

local function PlayerVisibilityCheck(ply)
    if GetConVar("bhop_showplayers"):GetInt() == 0 then
        return true
    end
end
hook.Add("PrePlayerDraw", "PlayerVisibilityCheck", PlayerVisibilityCheck)

local function Initialize()
    timer.Simple(5, ClientTick)
    timer.Simple(5, function() Core:Optimize() end)
end
hook.Add("Initialize", "ClientBoot", Initialize)

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
    end
end)

hook.Add("Think", "Validation", function()
    if IsValid(LocalPlayer()) then
        RunConsoleCommand("_imvalid")
        hook.Remove("Think", "Validation")
    end
end)

local function applyFlipWeapons(bool)
    for _, wep in pairs(LocalPlayer():GetWeapons()) do
        wep.ViewModelFlip = not bool
    end
end

cvars.AddChangeCallback("bhop_flipweapons", function(cvar, prev, new)
    local bool = (new == "1")
    if IsValid(LocalPlayer()) then
        applyFlipWeapons(bool)
    end
end)

hook.Add("HUDWeaponPickedUp", "flipweps", function(wep)
    wep.ViewModelFlip = (not GetConVar("bhop_flipweapons"):GetBool())
end)

local sway = GetConVar("bhop_weaponsway"):GetBool()
cvars.AddChangeCallback("bhop_weaponsway", function(cvar, prev, new)
    sway = (new == "1")
end)

local _angle = GetConVar("kawaii_view_angle"):GetInt()

function GM:CalcViewModelView(we, vm, op, oa, p, a)
    return sway and { op - a:Forward() * _angle, oa } or { op, oa }
end

local function fov(ply, ori, ang, fov, nz, fz)
    local suppress_viewpunch = GetConVar("kawaii_suppress_viewpunch"):GetBool()

    if suppress_viewpunch then
        ang.r = 0
    end

    local forwardOffset = ang:Forward() * -_angle
    return {
        origin = ori + forwardOffset,
        angles = ang,
        fov = GetConVar("kawaii_fov"):GetInt()
    }
end

hook.Remove("CalcView", "fov")
timer.Simple(1, function()
    if GetConVar("kawaii_fov"):GetInt() ~= 0 then
        hook.Add("CalcView", "fov", fov)
    end
end)

cvars.AddChangeCallback("kawaii_fov", function()
    local newfov = GetConVar("kawaii_fov"):GetInt()
    if newfov ~= 0 then
        hook.Add("CalcView", "fov", fov)
    else
        hook.Remove("CalcView", "fov")
    end
end)
