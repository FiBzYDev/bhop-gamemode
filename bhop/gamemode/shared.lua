GM.Name = "Bunny Hop"
GM.Author = "FiBzY"
GM.Email = "jwolf2110"
GM.Website = "www.steamcommunity.com/id/fibzysending"
GM.TeamBased = false

DeriveGamemode("base")
DEFINE_BASECLASS("gamemode_base")

_C = _C or {
    Version = 1.35,
    PageSize = 7,
    GameType = "bhop",
    ServerName = "justa's cool server",
    Identifier = "jcs-bhop",
    SteamGroup = "",
    MaterialID = "kawaii",
    Team = { Players = 1, Spectator = TEAM_SPECTATOR },
    Style = {
        Normal = 1, SW = 2, HSW = 3, ["W-Only"] = 4, ["A-Only"] = 5, ["D-Only"] = 6,
        SHSW = 7, Legit = 8, ["Easy Scroll"] = 9, Unreal = 10, Swift = 11, Bonus = 12,
        WTF = 13, Segment = 14, AutoStrafe = 15, ["Low Gravity"] = 16, ["Moon Man"] = 17,
        Stamina = 18, Backwards = 19
    },
    Player = {
        DefaultModel = "models/player/group01/male_01.mdl",
        DefaultWeapon = "weapon_glock",
        JumpPower = 290,
        ScrollPower = 268.4,
        HullMin = Vector( -16, -16, 0 ),
        HullDuck = Vector( 16, 16, 45 ),
        HullStand = Vector( 16, 16, 62 ),
        ViewDuck = Vector( 0, 0, 47 ),
        ViewStand = Vector( 0, 0, 64 )
    },
    Prefixes = {
        Timer = Color(0, 132, 255),
        General = Color(52, 152, 219),
        Admin = Color(244, 66, 66),
        Notification = Color(231, 76, 60),
        ["justa's cool server"] = Color(46, 204, 113),
        Radio = Color(230, 126, 34),
        VIP = Color(174, 0, 255)
    },
    Ranks = {
        {"Unranked", Color(255, 255, 255)}, {"Starter", Color(255, 255, 255)},
        {"Beginner", Color(166, 166, 166)}, {"Just Bad", Color(175, 238, 238)},
        {"Noob", Color(75, 0, 130)}, {"Learning", Color(107, 142, 35)},
        {"Novice", Color(65, 105, 225)}, {"Casual", Color(128, 128, 0)},
        {"Competent", Color(154, 205, 50)}, {"Expert", Color(240, 230, 140)},
        {"Gamer", Color(0, 255, 255)}, {"Professional", Color(244, 164, 96)},
        {"Cracked", Color(255, 255, 0)}, {"Elite", Color(255, 165, 0)},
        {"Intelligent", Color(0, 255, 0)}, {"Famous", Color(0, 139, 139)},
        {"Jumplet", Color(127, 255, 212)}, {"Executor", Color(128, 0, 0)},
        {"Incredible", Color(0, 0, 255)}, {"King", Color(218, 165, 32)},
        {"Mentally Ill", Color(240, 128, 128)}, {"Egomaniac", Color(255, 0, 255)},
        {"Legendary", Color(255, 105, 180)}, {"Immortal", Color(255, 69, 0)},
        {"Demoniac", Color(255, 0, 0)}, {"God", Color(0, 206, 209)}
    }
}

if game.GetMap() == "bhop_aux_a9" then
    _C.Player.JumpPower = math.sqrt(2 * 800 * 57.0)
end

include("modules/fpsfixes/cl_nixthelag.lua")
include("modules/fpsfixes/cl_buffthefps.lua")
include("modules/fpsfixes/sh_serialization.lua")
include("sh_playerclass.lua")
include("modules/fpsfixes/sh_disablehooks.lua")
include("modules/fpsfixes/cl_disablehooks.lua")
include("essential/sh_movement.lua")

function GM:PlayerNoClip(ply)
    if ply.Style == 14 and CurTime() > 6 then
        if SERVER then 
        Core:Send(ply, "Print", { "Timer", Lang:Get("NoClipSegment") })
        end
    end
    if ply.Style == 14 then return end

    local practice = ply:GetNWInt("inPractice", false)
    if not practice then 
        if SERVER then 
            ply:SetNWInt("inPractice", true)
            Core:Send(ply, "Print", { "Timer", Lang:Get("NoClip") })
            ply:StopAnyTimer()
            return true
        end
    end

    return practice
end

function GM:PlayerUse(ply)
    if not ply:Alive() or ply:Team() == TEAM_SPECTATOR or ply:GetMoveType() ~= MOVETYPE_WALK then 
        return false 
    end
    return true
end

function GM:CreateTeams()
    team.SetUp(_C.Team.Players, "Players", Color(255, 50, 50, 255), false)
    team.SetUp(_C.Team.Spectator, "Spectators", Color(50, 255, 50, 255), true)
    team.SetSpawnPoint(_C.Team.Players, { "info_player_terrorist", "info_player_counterterrorist" })
end

Core = {}

local StyleNames = {}
for name, id in pairs(_C.Style) do
    StyleNames[id] = name
end

function Core:StyleName(nID)
    return StyleNames[nID] or "Unknown"
end

function Core:IsValidStyle(nStyle)
    return not not StyleNames[nStyle]
end

function Core:GetStyleID(szStyle)
    for s, id in pairs(_C.Style) do
        if sl(s) == sl(szStyle) then
            return id
        end
    end
    return 0
end

function Core:Exp(c, n)
    return c * mp(n, 2.9)
end

local hooksToRemove = {
    OnEntityCreated = {
        "seats_network_optimizer", "player/ents.Iterator"
    },
    SpawniconGenerated = {
        "SpawniconGenerated"
    },
    EntityRemoved = {
        "DoDieFunction", "player/ents.Iterator"
    },
    VGUIMousePressAllowed = {
        "WorldPickerMouseDisable"
    },
    GUIMouseReleased = {
        "HandleMouseMovement"
    },
    PreDrawHUD = {
        "sm_fullbright_hudfix"
    },
   --[[ PreGamemodeLoaded = {
        "DisableWidgets"
    },--]]
    PostDrawOpaqueRenderables = {
        --"PreviewArea"
    },
   --[[ HUDShouldDraw = {
        "HUD_Hide", "hidechat"
    },--]]
    CreateMove = {
        "ClickableScoreBoard",
        "Random Patches v5.17.5::Focus Attack Fix", --"ChangeAngAutoStrafeles"
    },
    PreDrawOpaqueRenderables = {
        "sm_fullbright_opaquefix"
    },
    PostDrawEffects = {
        "sm_fullbright_effectfix"
    },
    OnViewModelChanged = {
        "Entity [74][gmod_hands]", "[NULL Entity]", "Entity [82][gmod_hands]"
    },
    PostRender = {
        "bhop_GrabScreenshot", --"sm_fullbright"
    },
    EntityFireBullets = {
        "Random Patches v5.17.5::Player Shoot Position Fix"
    },
    PlayerSpawn = {
        "RNGFix_SetupData"
    },
    PreventScreenClicks = {
        "PropertiesPreventClicks"
    },
    ShutDown = {
        "SaveCookiesOnShutdown", "roll back convars"
    },
    MouthMoveAnimation = {
       -- "Optimization"
    },
    GrabEarAnimation = {
      --  "Optimization"
    },
    NetworkEntityCreated = {
        "ShowHidden.HandleCreatedTrigger"
    },
    InitPostEntity = {
        "bash2_gmod", "CreateVoiceVGUI",
        "DisablePhysicsSettings",
        --"map_color_fixes", "RNGFix_PrepareTPs"
    },
    RenderScreenspaceEffects = {
        "StunEffect", "MapBrightness"
    },
    NotifyShouldTransmit = {
        "ShowHidden.HandleCreatedTrigger"
    },
    ChatText = {
        "SuppressMessages"
    },
    PreDrawEffects = {
        "sm_fullbright_effectfix", "PropertiesUpdateEyePos"
    },
    AcceptInput = {
        "RNGFix_PlayerTeleported"
    },
    PlayerFootstep = {
        "Random Patches v5.17.5::Player Footstep Fix"
    },
    DrawOverlay = {
        "DragNDropPaint", "DrawNumberScratch", "VGUIShowLayoutPaint"
    },
    KeyPress = {
       -- "StrafeKeys"
    },
    PreRender = {
        "sm_fullbright"
    },
    Think = {
        "RealFrameTime", "Hints", "NotificationThink", "JHUD1_Notify", 
        "WRDisplay", "JHUD12_Notify", "BHOPCSSReloader", 
        "Random Patches v5.17.5::False Screen Capture Fix", 
        "seats_network_optimizer", "SpeedTracker", "DragNDropThink"
    },
    SetupWorldFog = {
        "sm_cheat_fog", "sm_fullbright_forcebrightworld"
    },
    EntityNetworkedVarChanged = {
        "NetworkedVars"
    },
    PlayerLeaveVehicle = {
        --"seats_network_optimizer"
    },
    PrePlayerDraw = {
        "PlayerVisibilityCheck"
    },
    PostReloadToolsMenu = {
        "BuildUndoUI", "BuildCleanupUI"
    },
    PlayerBindPress = {
        "bash2_gmod", "BindPrevention", "PlayerOptionInput", 
        "sm_fullbright_flashlight", --"ChatboxCommand"
    },
    PostDrawTranslucentRenderables = {
        "sm_fullbright_transluscentfix"
    },
    PlayerPostThink = {
        "ProcessFire"
    },
    PlayerButtonDown = {
        "claz_sm_menu"
    },
    EntityRemove = {
        --"Random Patches v5.17.5::Entity.GetTable"
    },
    NeedsDepthPass = {
        "RemoveRenderDepth"
    },
    server_cvar = {
        "cvars.OnConVarChanged"
    },
    PopulateMenuBar = {
        "DisplayOptions_MenuBar", "NPCOptions_MenuBar", "MenuBar_ServerOptions"
    },
    PostGamemodeLoaded = {
        "bash2_gmod", --"OptimizeHooks"
    },
    AddToolMenuCategories = {
        "CreateUtilitiesCategories"
    },
    HUDPaint = {
        --"PaintB", "bhop.ShowKeys", "DarkClient", 
        "CaptureScreenHook", 
        "FlashEffect", "PlayerOptionDraw"
    },
    Tick = {
        "ShowTriggers.OverrideServer", --"SendQueuedConsoleCommands"
    },
    GetMotionBlurValues = {
        "gMotionBlur.Render"
    },
    PostDraw2DSkyBox = {
        "DrawRainbowSkybox"
    },
    PopulateToolMenu = {
        "PopulateUtilityMenus"
    },
    Initialize = {
        "InfogHook", "CSSTest", 
       -- "RemoveOtherHooks", "AutoOptimizeNetworkSettings", 
        "ClientBoot"
    },
   PlayerEnteredVehicle = {
        "seats_network_optimizer"
    },
    VGUIMousePressed = {
        "TextEntryLoseFocus", "DermaDetectMenuFocus"
    },
    player_hurt = {
        "Random Patches v5.17.5::Player Decals Fix"
    },
    StartChat = {
        "Random Patches v5.17.5::cl_drawhud fix"
    },
    GUIMousePressed = {
        "PropertiesClick"
    },
    OnGamemodeLoaded = {
        "CreateMenuBar"
    }
}

function Core:Optimize()
    for event, hooks in pairs(hooksToRemove) do
        for _, id in ipairs(hooks) do
            if hook.GetTable()[event] and hook.GetTable()[event][id] then
                hook.Remove(event, id)
            end
        end
    end
end

hook.Add("PostGamemodeLoaded", "OptimizeHooks", function()
    Core:Optimize()
end)

Core.Util = {
    GetPlayerJumps = function(self, ply) 
        return PlayerJumps[ply] 
    end,

    SetPlayerJumps = function(self, ply, nValue) 
        PlayerJumps[ply] = nValue 
    end,

    SetPlayerLegit = function(self, ply, nValue) 
        ls[ply] = nValue 
    end,

    StringToTab = function(self, szInput)
        if type(szInput) ~= "string" then
            print("Error: StringToTab expected a string but got:", type(szInput))
            return {}
        end

        local tab = string.Explode(" ", szInput)
        for k, v in pairs(tab) do
            if tonumber(v) then tab[k] = tonumber(v) end
        end
        return tab
    end,

    TabToString = function(self, tab)
        local size = #tab
        for i = 1, size do
            if not tab[i] then
                tab[i] = 0
            end
        end
        return string.Implode(" ", tab)
    end,

    RandomColor = function(self)
        local r = math.random
        return Color(r(0, 255), r(0, 255), r(0, 255))
    end,

    VectorToColor = function(self, v) 
        return Color(v.x, v.y, v.z) 
    end,

    ColorToVector = function(self, c) 
        return Vector(c.r, c.g, c.b) 
    end,

    NoEmpty = function(self, tab)
        local cleanedTab = {}
        for k, v in pairs(tab) do
            if v and v ~= "" then
                table.insert(cleanedTab, v)
            end
        end
        return cleanedTab
    end
}