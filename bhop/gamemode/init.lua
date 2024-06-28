-- Core Includes
include "core.lua"
include "nixthelag.lua"
include "core_lang.lua"
include "core_data.lua"

-- Server Includes
include "sv_player.lua"
include "sv_command.lua"
include "sv_disablehooks.lua"
include "sv_timer.lua"
include "sv_zones.lua"

-- Module Includes
local modules = {
    "sv_rtv.lua",
    "sv_admin.lua",
    "sv_bot.lua",
    "sv_spectator.lua",
    "sv_smgr.lua",
    "sv_stats.lua",
    "sv_ssj.lua",
    "sv_jac.lua",
    "sv_json.lua",
    "sv_boosterfix.lua",
    "sv_checkpoint.lua",
    "sv_setspawn.lua",
    "sv_segment.lua",
    "sv_wrsfx.lua",
    "sv_trailing.lua",
    "sh_paint.lua",
    "sh_unreal.lua"
}

for _, module in ipairs(modules) do
    include("modules/" .. module)
end

--remove/set some entities for fps boost

hook.Add("InitPostEntity", "fpsbooster", function()
	local sc = ents.FindByClass("shadow_control") or {}
	if #sc >= 1 then
		for k, v in pairs(sc) do
			v:SetKeyValue("disableallshadows", "1")
			print("modified shadow controller successfully")
		end
	else
		local shadow = ents.Create("shadow_control")
		if shadow:IsValid() then
			shadow:SetKeyValue("disableallshadows", "1")
			print("No shadow controller on map, created default one")
		else
			print("No shadow controller on map, and created one failed")
		end
	end
	
	local precip = ents.FindByClass("func_precipitation") or {}
	if #precip >= 1 then
		for k, v in pairs(precip) do
			local entval = v:GetKeyValues()
			if entval["preciptype"] == 0 then
				v:Remove()
			end
		end
	end
end)

-- Function to hide bot player models
local function HideBotModels()
    -- Iterate over all players
    for _, ply in pairs(player.GetAll()) do
        -- Check if the player is a bot
        if ply:IsBot() then
            -- Hide the player model
            ply:SetNoDraw(true)
        else
            -- Show the player model if it's not a bot
            ply:SetNoDraw(false)
        end
    end
end

-- Hook the function to the player spawn event
hook.Add("PlayerSpawn", "HideBotModelsOnSpawn", function(ply)
    -- Hide bot models when they spawn
    timer.Simple(0.1, function()
        if IsValid(ply) then
            HideBotModels()
        end
    end)
end)

-- Hook the function to the think event to constantly check and hide bot models
hook.Add("Think", "HideBotModelsOnThink", function()
    HideBotModels()
end)

-- Event Listener System
local listeners = {}
local function addEventListener(event, callback)
    if not listeners[event] then
        listeners[event] = {}
    end
    table.insert(listeners[event], callback)
end

local function removeEventListener(event, callback)
    for i, listener in ipairs(listeners[event] or {}) do
        if listener == callback then
            table.remove(listeners[event], i)
            break
        end
    end
end

local function dispatchEvent(event, ...)
    for _, callback in ipairs(listeners[event] or {}) do
        callback(...)
    end
end

-- Lag Control System
local lagControl = {
    propsPhysics = true,
    particleEffects = true,
    expensiveThinkHooks = true
}

local function updateLagInducingFeatures(feature, status)
    if feature == "propsPhysics" then
        if status == "disable" then
            RunConsoleCommand("sbox_noclip", "0")
            RunConsoleCommand("sbox_godmode", "0")
            game.ConsoleCommand("phys_timescale 0.1\n")
        else
            game.ConsoleCommand("phys_timescale 1\n")
        end
    elseif feature == "particleEffects" then
        RunConsoleCommand("r_drawparticles", status == "disable" and "0" or "1")
    elseif feature == "expensiveThinkHooks" then
        if status == "disable" then
            hook.Remove("Think", "ExpensiveCustomAI")
        else
            hook.Add("Think", "ExpensiveCustomAI", function()
                -- Custom AI logic here
            end)
        end
    end
end

concommand.Add("toggle_lag_feature", function(ply, cmd, args)
    if not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "You must be an admin to use this command.")
        return
    end

    local feature = args[1]
    local action = args[2]

    if lagControl[feature] and (action == "disable" or action == "enable") then
        updateLagInducingFeatures(feature, action)
        lagControl[feature] = (action == "enable")
        ply:PrintMessage(HUD_PRINTCONSOLE, feature .. " has been " .. action .. "d.")
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid feature or action. Use 'propsPhysics', 'particleEffects', 'expensiveThinkHooks' and 'disable' or 'enable'.")
    end
end)

-- Server Optimizations
local loadedResources = {}
local lastSentPositions = {}

local function LoadResource(id)
    return "Resource_" .. id
end

local function GetResource(id)
    if not loadedResources[id] then
        loadedResources[id] = LoadResource(id)
    end
    return loadedResources[id]
end

local function ProcessPlayers()
    for _, player in ipairs(player.GetAll()) do
        if not IsValid(player) then continue end
        local playerID = player:GetID()
        local currentPosition = player:GetPosition()

        if lastSentPositions[playerID] ~= currentPosition then
            UpdateClientPosition(player, currentPosition)
            lastSentPositions[playerID] = currentPosition
        end
    end
end

local function CleanupOldData(dataStore)
    for key, data in pairs(dataStore) do
        if not data:IsNeeded() then
            dataStore[key] = nil
        end
    end
end

local function processInChunks(data)
    for i = 1, #data do
        coroutine.yield(processDataPiece(data[i]))
    end
end

local function StartCoroutineProcessing(data)
    local co = coroutine.create(processInChunks)
    coroutine.resume(co, data)
end

local function InitializeGameMode()
    ProcessPlayers()
    StartCoroutineProcessing(player.GetAll())

    timer.Create("CleanupTimer", 80, 0, function()
        CleanupOldData(loadedResources)
        CleanupOldData(lastSentPositions)
    end)
end

InitializeGameMode()

util.AddNetworkString("UpdatePosition")

local lastUpdateTimes = {}

local function UpdatePlayerPosition(player)
    local curTime = CurTime()
    if not lastUpdateTimes[player] or curTime - lastUpdateTimes[player] > 0.1 then
        net.Start("UpdatePosition")
        net.WriteEntity(player)
        net.WriteVector(player:GetPos())
        net.Send(player)
        lastUpdateTimes[player] = curTime
    end
end

local function cleanupMemory()
    collectgarbage("collect")
end
timer.Create("MemoryCleanupTimer", 80, 0, cleanupMemory)

hook.Add("Think", "ServerThinkOptimizations", function()
    for _, player in ipairs(player.GetAll()) do
        if IsValid(player) and player:Alive() then
            UpdatePlayerPosition(player)
        end
    end
end)

local function Startup()
    Core:Boot()
end
hook.Add("Initialize", "Startup", Startup)

local function LoadEntities()
    Core:AwaitLoad()
end
hook.Add("InitPostEntity", "LoadEntities", LoadEntities)

function GM:PlayerSpawn(ply)
    player_manager.SetPlayerClass(ply, "player_bhop")
    self.BaseClass:PlayerSpawn(ply)
    Player:Spawn(ply)
end

function GM:PlayerInitialSpawn(ply)
    Player:Load(ply)
end

function GM:CanPlayerSuicide() return false end
function GM:PlayerShouldTakeDamage() return false end
function GM:GetFallDamage() return false end
function GM:PlayerCanHearPlayersVoice() return true end
function GM:IsSpawnpointSuitable() return true end
function GM:PlayerDeathThink(ply) end
function GM:PlayerSetModel() end

function GM:PlayerCanPickupWeapon(ply, weapon)
    if ply.WeaponStripped or ply:HasWeapon(weapon:GetClass()) or ply:IsBot() then
        return false
    end

    timer.Simple(0, function()
        if IsValid(ply) and IsValid(weapon) then
            ply:SetAmmo(999, weapon:GetPrimaryAmmoType())
        end
    end)

    return true
end

hook.Add("WeaponEquip", "UnlimitedAmmo", function(wep, ply)
    if not IsValid(wep) or not IsValid(ply) or not ply:IsPlayer() then return end
    local maxClip = wep:GetMaxClip1()
    if maxClip > 0 then
        wep:SetClip1(maxClip)
    end
end)

local function RemoveAllEntities()
    local entityClasses = {"prop_physics", "prop_static", "prop_dynamic"}
    for _, class in ipairs(entityClasses) do
        for _, ent in pairs(ents.FindByClass(class)) do
            if IsValid(ent) then
                ent:Remove()
            end
        end
    end
end

local mapsToClean = {
    "bhop_alt_terassi", "bhop_tumi", "bhop_boredom", "bhop_ambience", "bhop_tehoputki"
}

if table.HasValue(mapsToClean, game.GetMap()) then
    hook.Add("InitPostEntity", "RemoveAllEntitiesOnMap", function()
        timer.Simple(1, RemoveAllEntities)
    end)
end

hook.Add("ShouldCollide", "DisableBulletsOnSpecificMaps", function(ent1, ent2)
    local isBullet1 = ent1:GetClass() == "bb_pistol_bullet"
    local isBullet2 = ent2:GetClass() == "bb_pistol_bullet"

    if isBullet1 or isBullet2 then
        local mapName = game.GetMap()
        local disabledMaps = {
            "bhop_sandtrap", "bhop_sandtrap2", "bhop_sandtrap3",
            "bhop_classicrainbowaux_fix", "kz_bhop_yonkoma"
        }

        if table.HasValue(disabledMaps, mapName) then
            return false
        end
    end
    return true
end)