-- Create local variables for repeated values
Client = {}
allPlayers = player.GetAll()
gameMap = game.GetMap()

local lp = LocalPlayer

-- Client-side Network Optimization Script for GMod
-- Adjust interpolation and network settings for smoother player movement

-- Command to manually adjust network settings for player movement
concommand.Add("optimize_movement", function(ply, cmd, args)
    local setting = args[1]

    if setting == "high" then
        -- High precision settings for low latency environments
        ply:ConCommand("cl_interp 0")
        ply:ConCommand("cl_interp_ratio 1")
        ply:ConCommand("cl_updaterate 66")
        ply:ConCommand("cl_cmdrate 66")
        ply:ConCommand("rate 196608")
        ply:PrintMessage(HUD_PRINTCONSOLE, "Network settings adjusted for high precision.")
    elseif setting == "medium" then
        -- Medium settings for average latency
        ply:ConCommand("cl_interp 0.01")
        ply:ConCommand("cl_interp_ratio 2")
        ply:ConCommand("cl_updaterate 33")
        ply:ConCommand("cl_cmdrate 33")
        ply:ConCommand("rate 131072")
        ply:PrintMessage(HUD_PRINTCONSOLE, "Network settings adjusted for medium precision.")
    elseif setting == "low" then
        -- Lower settings for high latency environments
        ply:ConCommand("cl_interp 0.1")
        ply:ConCommand("cl_interp_ratio 2")
        ply:ConCommand("cl_updaterate 20")
        ply:ConCommand("cl_cmdrate 20")
        ply:ConCommand("rate 65536")
        ply:PrintMessage(HUD_PRINTCONSOLE, "Network settings adjusted for lower precision.")
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid setting. Use 'high', 'medium', or 'low'.")
    end
end)

-- Hook to automatically adjust settings on game start
hook.Add("Initialize", "AutoOptimizeNetworkSettings", function()
    if LocalPlayer():IsValid() then
        LocalPlayer():ConCommand("optimize_movement high")
    end
end)


-- Timer for cl_interp
timer.Create("interp", 2, 1, function()
    for _, ply in ipairs(allPlayers) do
        ply:ConCommand("cl_interp 100000")
    end
end)

-- Timer for r_drawparticles
timer.Create("gunlag", 2, 1, function()
    for _, ply in ipairs(allPlayers) do
        ply:ConCommand("r_drawparticles 0")
    end
end)

-- Timer for r_decals based on HIDEPAINTER
hidePainterEnabled = CreateClientConVar("kawaii_hidepainter", "0", true, false, "Enables hide painter"):GetBool()
timer.Create("painter2", 2, 1, function()
    for _, ply in ipairs(allPlayers) do
        command = hidePainterEnabled and "r_decals 0" or "r_decals 1000"
        ply:ConCommand(command)
    end
end)

-- Timer for kawaii_map_brightness based on game map
mapBrightness = {
    ["bhop_nervosity2"] = .8,
    ["bhop_dice"] = 1.16,
}
timer.Create("mapBrightnessTimer", 2, 1, function()
    brightness = mapBrightness[gameMap]
    if brightness then
        for _, ply in ipairs(allPlayers) do
            ply:ConCommand("kawaii_map_brightness " .. brightness)
        end
    end
end)

-- Timer for r_skybox based on game map
timer.Create("skyboxTimer", 2, 1, function()
    if gameMap == "bhop_z" then
        for _, ply in ipairs(allPlayers) do
            ply:ConCommand("r_skybox 0")
        end
    end
end)

-- Timer for showclips based on KAWAIISCMAPCHANGE
kawaiiSCMapChangeEnabled = CreateClientConVar("kawaii_mapchangesclips", "0", true, false, "Enables map change show clips"):GetBool()
timer.Create("showClipsTimer", 1, 1, function()
    if kawaiiSCMapChangeEnabled then
        for _, ply in ipairs(allPlayers) do
            ply:ConCommand("showclips 1")
        end
    end
end)

-- Timer for showtriggers_enabled based on KAWAIISTMAPCHANGE
kawaiiSTMapChangeEnabled = CreateClientConVar("kawaii_mapchangestriggers", "1", true, false, "Enables map change show triggers"):GetBool()
timer.Create("showTriggersTimer", 1, 1, function()
    if kawaiiSTMapChangeEnabled then
        for _, ply in ipairs(allPlayers) do
            ply:ConCommand("showtriggers_enabled 1")
        end
    end
end)

-- Timer for kawaii_map_color based on game map
mapColor = {
    ["bhop_bloodflow"] = 1.8,
    ["bhop_calming"] = 1.3,
    ["bhop_overline"] = 2,
    -- Add more mappings as needed
}
timer.Create("mapColorTimer", 2, 1, function()
    color = mapColor[gameMap]
    if color then
        for _, ply in ipairs(allPlayers) do
            ply:ConCommand("kawaii_map_color " .. color)
        end
    end
end)

-- Timer for kawaii_map_brightness on specific map
timer.Create("mapBrightnessSpecificTimer", 2, 1, function()
    if gameMap == "bhop_0000" then
        for _, ply in ipairs(allPlayers) do
            ply:ConCommand("kawaii_map_brightness 3")
        end
    end
end)

-- Timer for mat_bloomscale based on game map
matBloomScale = {
    ["bhop_overline"] = 0,
    ["bhop_overline_sof"] = 0,
    ["bhop_alt_univaje"] = 1,
}
timer.Create("matBloomScaleTimer", 2, 1, function()
    bloomScale = matBloomScale[gameMap]
    if bloomScale then
        for _, ply in ipairs(allPlayers) do
            ply:ConCommand("mat_bloomscale " .. bloomScale)
        end
    end
end)

-- Movement-related ConVars
local maxspeed = CreateClientConVar("sv_maxspeed_gmod", 250, true, "Sets the maximum movement speed.")
local backspeed = CreateClientConVar("sv_backspeed_gmod", 0.6, true, "Sets the backward movement speed.")
local sv_stepsize = CreateClientConVar("sv_stepsize_gmod", 18, true, "Sets the step size for movement.")
local sv_waterdist = CreateClientConVar("sv_waterdist_gmod", 12, true, "Sets the water dist for movement.")

-- Miscellaneous ConVars
local sm_fakedownloadurl = CreateClientConVar("sm_fakedownloadurl", "fibzy's cool server", true, "Fake download URL.")
local cl_bob = CreateClientConVar("cl_bob", 0.002, true, "View bobbing amount.")
local cl_bobcycle = CreateClientConVar("cl_bobcycle", 0.8, true, "View bobbing cycle.")
local cl_bobup = CreateClientConVar("cl_bobup", 0.5, true, "View bobbing up amount.")
local sv_bounce = CreateClientConVar("sv_bounce", 0, true, "Bounce setting.")
local hudhint_sound = CreateClientConVar("sv_hudhint_sound", 0, true, "HUD hint sound setting.")
local mpbhops_enable = CreateClientConVar("mpbhops_enable", 1, false, "Enable MPB hops.")
local sm_nextmap = CreateClientConVar("sm_nextmap", 0, false, "Next map setting.")
local sw_gamedesc_override = CreateClientConVar("sw_gamedesc_override", "Bunny Hop", false, "Game description override.")
local CSteam = CreateClientConVar("fcs_steamgroup", 0, false, "Steam group setting.")

-- Bhop-related ConVars
local ShowZones = CreateClientConVar("sl_showzones", "1", true, false, "Toggles visibility of server zones.")
local Comparison = CreateClientConVar("sl_comparison_type", "1", true, true, "Toggles prestrafe view in timer.")
local Blur = CreateClientConVar("sl_blur", "1", true, false, "Toggles visibility of blur menus.")
local Decimals = CreateClientConVar("sl_enumerator", "2", true, false, "Changes decimal places in timer.")
local PrintPref = CreateClientConVar("sl_printchat", "1", true, false, "Decides where messages are printed.")
local TotalTime = CreateClientConVar("sl_totaltime", "1", true, true, "Toggles total time display.")
local Footsteps = CreateClientConVar("sl_footsteps", "1", true, true, "Toggles footstep sounds.")
local ChatTick = CreateClientConVar("sl_chattick", "default", true, true, "Changes chat ticker sound.")
local MenuClicker = CreateClientConVar("sl_clicker", "1", true, false, "Enables menu clicker sound.")
local ForceBloom = CreateClientConVar("sl_forcebloom", "0", true, false, "Forces bloom rendering.")
local ForceMotion = CreateClientConVar("sl_forcemotion", "0", true, false, "Forces motion blur rendering.")
local ForceFocus = CreateClientConVar("sl_forcefocus", "0", true, false, "Forces focus loosen.")
local GlobalCheckpoints = CreateClientConVar("sl_globalcheckpoints", "0", true, true, "Enables global checkpoints.")
local SpeedStats = CreateClientConVar("sl_speedstats", "0", true, true, "Displays Velocity stats.")
local ShowSpecialRanks = CreateClientConVar("sl_special_ranks", "1", true, true, "Shows special ranks.")
local CustomChat = CreateClientConVar("sl_customchat", "0", true, false, "Enables custom chatbox.")
local CustomSurfTimer = CreateClientConVar("sl_customsurftimer", "0", true, false, "Allows custom surf timer colors.")
local CustomChatColors = CreateClientConVar("sl_chattheme", "0", true, false, "Changes chat message colors.")
local SmoothNoclipping = CreateClientConVar("sl_smoothnoclip", "0", true, true, "Enables smooth noclip.")
local UltrawideCenter = CreateClientConVar("sl_ultracenter", "0", true, false, "Allows HUD elements in ultrawide.")

local CPlayers = CreateClientConVar( "sl_showothers", "1", true, false )
local CSteam = CreateClientConVar( "sl_steamgroup", "1", true, false )
local CCrosshair = CreateClientConVar( "sl_crosshair", "1", true, false )
local CTargetID = CreateClientConVar( "sl_targetids", "0", true, false )
local Connection = CreateClientConVar( "sl_connection", "1", true, false )

-- Other ConVars
CreateClientConVar("fov_desired_cs", 90)
CreateClientConVar("sm_connection", 1, true, false)
CreateClientConVar("sv_bounce_gmod", 0, true, false)
CreateClientConVar("sv_stepsize_gmod", 18, true, false)
CreateClientConVar("sv_maxspeed_gmod", 250, true)
CreateClientConVar("sv_backspeed_gmod", 0.6, true)
CreateClientConVar("sm_fakedownloadurl", "fibzy's cool server", true)
CreateClientConVar("sv_downloadurl", "fibzy's cool server", true)

-- View-related ConVars
local ubasefov = GetConVarNumber("fov_desired")
CreateClientConVar("kawaii_fov", ubasefov)
CreateClientConVar("kawaii_view_angle", 2)

-- Miscellaneous ConVars
CreateClientConVar("kawaii_suppress_viewpunch", "0", true, false, "Suppress viewpunch.")
CreateClientConVar("kawaii_suppress_viewpunch_wep", "0", true, false, "Suppress viewpunch for weapons.")
CreateClientConVar("kawaii_steady_view", "0", true, false, "Steady weapon view.")

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

-- Boolean to track if the sound stopper is enabled
local soundStopperEnabled = false
local timerName = "SoundStopperTimer"

-- Function to toggle the sound stopper
local function ToggleSoundStopper()
    if soundStopperEnabled then
        RunConsoleCommand("stopsound")
        print("Sound stopped.")
        soundStopperEnabled = false
        timer.Remove(timerName)  -- Remove the timer when sound stopper is disabled
    else
        print("Sound stopper is now enabled.")
        soundStopperEnabled = true
        -- Start a timer to disable the sound stopper after 30 seconds (adjust as needed)
        timer.Create(timerName, 30, 1, function()
            ToggleSoundStopper()  -- Automatically disable sound stopper after timer expires
        end)
    end
end

-- Add a console command to toggle the sound stopper
concommand.Add("togglesoundstopper", function()
    ToggleSoundStopper()
end)

function GM:PlayerFootstep( ply )
	local wantsFootsteps = Footsteps:GetInt()
	local alwaysOff, settingLocal = wantsFootsteps == 0, wantsFootsteps == 2

	if alwaysOff then return true end
	if settingLocal then
		local isLocal = ply == lp()
		if !isLocal then return true end
	end

	return false
end

function GM:RenderScreenspaceEffects()
    -- Check if ForceBloom is enabled
    if ForceBloom:GetBool() then
        RunConsoleCommand("pp_bloom", 1)
        DrawBloom(0.65, 3, 9, 9, 1, 1, 1, 1, 1)
    else
        RunConsoleCommand("pp_bloom", 0)
    end

    -- Check if ForceMotion is enabled
    if ForceMotion:GetBool() then
        DrawMotionBlur(0.4, 0.4, 0.01)
    end

    -- Check if ForceFocus is enabled
    if ForceFocus:GetBool() then
        DrawToyTown(2, ScrH() / 2)
    end
end

-- Create the client ConVar
CreateClientConVar("kawaii_css_reloading", 1, true, false)

-- Function to handle BHOP CSS reloader
local function BHOPCSSReloader()
	-- Check if the ConVar is enabled (1 means enabled, 0 means disabled)
	if GetConVar("kawaii_css_reloading"):GetBool() then
		-- Check if right mouse button is pressed
		if input.IsMouseDown(MOUSE_RIGHT) then
			-- Check if the player is on the ground to prevent spamming
			if lp():IsOnGround() then
				-- Start attacking with secondary fire
				RunConsoleCommand("+attack2")

				-- Create a one-time timer to release the attack command
				timer.Simple(0, function()
					RunConsoleCommand("-attack2")
				end)
			end
		end
	end
end
hook.Add("Think", "BHOPCSSReloader", BHOPCSSReloader)

-- Define the key you want to use for displaying the world record
local WRKey = KEY_F4

-- Function to check and execute the world record display command
local function WRDisplay()
    -- Check if the F4 key is pressed and the chat is not active
    if input.IsKeyDown(WRKey) then
        -- Send the chat command to display the world record
        RunConsoleCommand("say", "!wr")
    end
end
hook.Add("Think", "WRDisplay", WRDisplay)

local WRSOUND = {}
WRSOUND.Enabled = CreateClientConVar("kawaii_recordsound", "1", true, false, "Enables WR Sounds")

-- Rainbow color function
local function RainbowColor(index, frequency)
    local r = math.sin(frequency * index + 0) * 127 + 128
    local g = math.sin(frequency * index + 2) * 127 + 128
    local b = math.sin(frequency * index + 4) * 127 + 128
    return Color(r, g, b)
end

Darker = {}
Darker.Enabled = CreateClientConVar( "kawaii_dark", "0", true, false, "Enables Darker Screen" )

hook.Add( "HUDPaint", "DarkClient", function()
	local Darker = Darker.Enabled:GetBool()
	if !Darker then return end
	local width = 100000
	local height = 100000
	local xPos = ScrW() / 2 - width / 2
	local yPos = ScrH() - height
	draw.RoundedBox(0, xPos, yPos, width, height, Color(0,0,0,50))
end )

hook.Add("GUIMouseReleased", "HandleMouseMovement", function(code, x, y)
    hook.Remove("GUIMouseMoved", "HandleMouseMovement")
end)


if SERVER then
    local mapBrightness = "1"

    local function updateMapBrightness(mult)
        local brightness = mult or mapBrightness
        for _, ply in pairs(player.GetHumans()) do
            if not ply:IsBot() then
                ply:ConCommand("kawaii_map_brightness " .. brightness)
            end
        end
        sql.Query("UPDATE game_map SET nBrightness = " .. brightness .. " WHERE szMap = '" .. game.GetMap() .. "'")
    end

    local function setMapBrightness(value)
        if value then
            updateMapBrightness(value)
        else
            local data = sql.Query("SELECT nBrightness FROM game_map WHERE szMap = '" .. game.GetMap() .. "'")
            if Core:Assert(data, "nBrightness") then
                mapBrightness = tostring(data[1]["nBrightness"])
                updateMapBrightness()
            end
        end
    end

    hook.Add("PlayerInitialSpawn", "SetMapBrightness", setMapBrightness)
else
    local ppColors = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 1.2,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }

    concommand.Add("kawaii_map_brightness", function(ply, cmd, args)
        ppColors["$pp_colour_contrast"] = tonumber(args[1]) or 1
    end)

    hook.Add("RenderScreenspaceEffects", "MapBrightness", function()
        if ppColors["$pp_colour_contrast"] == 1 then return end
        DrawColorModify(ppColors)
    end)

    function GM:PostProcessPermitted()
        return true
    end
end

hook.Add("InitPostEntity", "map_color_fixes", function()
    local mapName = game.GetMap()

    if mapName == "bhop_overline" then
        local mat = Material("base0/blackblue")
        if mat ~= nil then
            mat:SetVector("$color", Vector(0.3, 0.3, 0.3))
        end
    elseif mapName == "bhop_lunti" then
        local mat = Material("ryan_dev/85")
        if mat ~= nil then
            mat:SetVector("$color", Vector(0.6, 0.6, 0.6))
        end
    elseif mapName == "bhop_dom" then
        local mat1 = Material("base_floor/clang_floor")
        local mat2 = Material("cncr04sp2/metal/yelhaz2dif")
        if mat1 ~= nil then
            mat1:SetVector("$color", Vector(0.3, 0.3, 0.3))
        end
        if mat2 ~= nil then
            mat2:SetVector("$color", Vector(0.4, 0.3, 0.3))
        end
    elseif mapName == "bhop_kasvihuone" then
        local mat = Material("neon/green")
        if mat ~= nil then
            mat:SetVector("$color", Vector(1, 0.3, 0.3))
        end
    elseif mapName == "bhop_alt_univaje" then
        local mat = Material("neon/green")
        if mat ~= nil then
            mat:SetVector("$color", Vector(1, 0, 0))
        end
    elseif mapName == "bhop_ares" then
        local mat = Material("dev/dev_measuregeneric43")
        if mat ~= nil then
            mat:SetVector("$color", Vector(0, 1, 0.3))  -- Adjusted values to be within range
        end
    end
end)

local MotionBlur = {}
MotionBlur.Enabled = CreateClientConVar("kawaii_css_motionblur", "0", true, false, "Enable CS:S Motion Blur.")

if CLIENT then
    local function CalculateBlurFactor(velocity)
        local maxVelocity = 1200  -- Adjust this based on your desired max velocity
        local maxBlurFactor = 0.1  -- Adjust this based on your desired max blur factor
        local minBlurFactor = 0.01 -- Adjust this based on your desired min blur factor

        local normalizedVelocity = math.min(velocity / maxVelocity, 1)
        return minBlurFactor + (maxBlurFactor - minBlurFactor) * normalizedVelocity
    end

    hook.Add("GetMotionBlurValues", "gMotionBlur.Render", function(h, v, f, r)
        local isEnabled = MotionBlur.Enabled:GetBool()
        if isEnabled then
            local velocity = lp():GetVelocity():Length()
            local blurFactor = CalculateBlurFactor(velocity)

            f = math.Clamp(f + blurFactor, 0, 1)
        end
        return h, v, f, r
    end)
end

SkyJSC = {}
SkyJSC.Enabled = CreateClientConVar("kawaii_skybox", "0", true, false, "Rainbow skybox :)")

local function DrawRainbowSkybox()
    if not SkyJSC.Enabled:GetBool() then return end

    local skybox_speed = GetConVarNumber("kawaii_skybox_speed") or 40
    local col = HSVToColor(RealTime() * skybox_speed % 360, 1, 1)
    
    render.Clear(col.r / 1.3, col.g / 1.3, col.b / 1.3, 255)
end

hook.Add("PostDraw2DSkyBox", "DrawRainbowSkybox", DrawRainbowSkybox)

Cheats = {}
Cheats.Fullbright = false

function Cheats.ToggleFullbright(supress)
	Cheats.Fullbright = !Cheats.Fullbright
	if !supress then
		Chat.Print("Fullbright: ", CL.Y, Cheats.Fullbright and "ON" or "OFF")
	end
end

hook.Add("PreRender", "sm_fullbright", function()
	if !Cheats.Fullbright then
		render.SetLightingMode(0)
	return end
	render.SetLightingMode(1)
	render.SuppressEngineLighting(false)
end)

hook.Add("PostRender", "sm_fullbright", function()
	render.SetLightingMode(0)
	render.SuppressEngineLighting(false)
end)

hook.Add("PreDrawHUD", "sm_fullbright_hudfix", function()
	render.SetLightingMode(0)
end)

hook.Add("PreDrawEffects", "sm_fullbright_effectfix", function()
	if !Cheats.Fullbright then return end
	render.SetLightingMode(0)
end)

hook.Add("PostDrawEffects", "sm_fullbright_effectfix", function()
	if !Cheats.Fullbright then return end
	render.SetLightingMode(0)
end)

hook.Add("PreDrawOpaqueRenderables", "sm_fullbright_opaquefix", function()
	if !Cheats.Fullbright then return end
	render.SetLightingMode(0)
end)

hook.Add("PostDrawTranslucentRenderables", "sm_fullbright_transluscentfix", function()
	if !Cheats.Fullbright then return end
	render.SetLightingMode(0)
end)

hook.Add("SetupWorldFog", "sm_fullbright_forcebrightworld", function()
	if !Cheats.Fullbright then return end
	render.SuppressEngineLighting(true)
	render.SetLightingMode(1)
	render.SuppressEngineLighting(false)
end)

hook.Add("PlayerBindPress", "sm_fullbright_flashlight", function( _, bind)
	local isValidBind = string.StartWith(bind, "impulse 100")
	if isValidBind then
		local bindingKey = input.LookupBinding(bind, true)
		local keyCode = input.GetKeyCode(bindingKey)
		local justReleased = input.WasKeyReleased(keyCode)
		if (isValidBind and !justReleased) then
			Cheats.ToggleFullbright(true)
		return true end
	end
end)

local Cheats = {}
Cheats.Fog = true

-- Create the console variable for Fog cheat
Cheats.CVarFog = CreateClientConVar("cheats_fog", "1", true, false, "Toggle fog cheat (0 = OFF, 1 = ON)")

-- Function to toggle Fog cheat
function Cheats.ToggleFog(suppressMessage)
    Cheats.Fog = not Cheats.Fog
    Cheats.CVarFog:SetBool(Cheats.Fog)  -- Update the cvar value
    
    -- Optionally print a message if suppressMessage is not true
    if not suppressMessage then
        chat.AddText("Fog: ", Cheats.Fog and Color(255, 0, 0) or Color(0, 255, 0), Cheats.Fog and "ON" or "OFF")
    end
end

-- Hook into a command to toggle Fog cheat
concommand.Add("toggle_fog", function()
    Cheats.ToggleFog(false)
end)

-- Function to render fogs based on the cheat status
local function RenderFogs()
    if not Cheats.Fog then
        render.FogMode(MATERIAL_FOG_NONE)  -- Disable fog rendering
        return true  -- Return true to override the fog
    end
end

-- Hook into SetupWorldFog to control fog rendering
hook.Add("SetupWorldFog", "sm_cheat_fog", RenderFogs)

local trailConfig = {
	["blue"] = CreateClientConVar("kawaii_trail_blue", "0", true, false, "When replay trailing, set the trail color to blue when you are faster than the trail speed.", 0, 1),
	["range"] = CreateClientConVar("kawaii_trail_range_fpsfix", "10000000", true, false, "On the trailing replay, increase the visibility of the trails", 0, 1),
	["ground"] = CreateClientConVar("kawaii_trail_ground", "0", true, false, "On the trailing replay, show trails only when the trail is on the ground", 0, 1),
	["vague"] = CreateClientConVar("kawaii_trail_vague", "0", true, false, "On the trailing replay, show trails transparent", 0, 1),
	["label"] = CreateClientConVar("kawaii_trail_label", "0", true, false, "On the trailing replay, hide trail markers", 0, 1),
	["hud"] = CreateClientConVar("kawaii_trail_hud", "0", true, false, "On the trailing replay, hide the trail hud", 0, 1),
}

local function UpdateSettings()
	for _,ent in ipairs(ents.FindByClass "game_point") do
		ent:LoadConfig()
	end
end

for _,cvar in pairs(trailConfig) do
	cvars.AddChangeCallback(cvar:GetName(), function()
		UpdateSettings()
	end)
end

function Client:GetTrailConfig(name)
	return trailConfig[name]:GetBool()
end