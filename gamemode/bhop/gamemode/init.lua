include "core.lua"
include "core_lang.lua"
include "core_data.lua"
include "sv_player.lua"
include "sv_command.lua"
include "sv_disablehooks.lua"
include "sv_timer.lua"
include "sv_zones.lua"
include "modules/sv_rtv.lua"
include "modules/sv_admin.lua"
include "modules/sv_bot.lua"
include "modules/sv_spectator.lua"
include "modules/sv_smgr.lua"
include "modules/sv_stats.lua"
include "modules/sv_ssj.lua"
include "modules/sv_jac.lua"
include "modules/sv_boosterfix.lua"

-- Checkpoints
include "modules/sv_checkpoint.lua"
include "modules/sv_setspawn.lua"
include "modules/sv_segment.lua"
include "modules/sv_wrsfx.lua"

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

-- Table to manage the status of lag-inducing features
local lagControl = {
    propsPhysics = true,
    particleEffects = true,
    expensiveThinkHooks = true
}

-- Function to update the status of lag-inducing features
local function updateLagInducingFeatures(feature, status)
    if feature == "propsPhysics" then
        if status == "disable" then
            RunConsoleCommand("sbox_noclip", "0") -- Disabling noclip can reduce unintended physics interactions
            RunConsoleCommand("sbox_godmode", "0") -- Disable godmode to prevent abuse with props
            game.ConsoleCommand("phys_timescale 0.1\n") -- Slows down physics calculations
        else
            game.ConsoleCommand("phys_timescale 1\n") -- Reset physics calculations to normal
        end
    elseif feature == "particleEffects" then
        if status == "disable" then
            RunConsoleCommand("r_drawparticles", "0") -- Disable particle effects
        else
            RunConsoleCommand("r_drawparticles", "1") -- Enable particle effects
        end
    elseif feature == "expensiveThinkHooks" then
        -- Example: Disabling complex AI or custom scripts
        if status == "disable" then
            hook.Remove("Think", "ExpensiveCustomAI")
        else
            hook.Add("Think", "ExpensiveCustomAI", function() -- Re-enable or define expensive hooks
                -- Custom AI logic here
            end)
        end
    end
end

-- Admin command to control laggy functions
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

-- A fictional game mode script with performance optimizations

-- Globals for caching and resource management
local loadedResources = {}
local lastSentPositions = {}

-- Function to load a resource on-demand
local function LoadResource(id)
    -- Placeholder for resource loading logic
    return "Resource_" .. id
end

-- Function to get a resource with caching
local function GetResource(id)
    if not loadedResources[id] then
        loadedResources[id] = LoadResource(id)
    end
    return loadedResources[id]
end

-- Function to process players efficiently
local function ProcessPlayers()
    for _, player in ipairs(player.GetAll()) do
        if not IsValid(player) then continue end  -- Skip invalid players
        local playerID = player:GetID()

        -- Check and update position with network optimization
        local currentPosition = player:GetPosition()
        if lastSentPositions[playerID] ~= currentPosition then
            UpdateClientPosition(player, currentPosition)
            lastSentPositions[playerID] = currentPosition
        end
    end
end

-- Function to cleanup old data periodically
local function CleanupOldData(dataStore)
    for key, data in pairs(dataStore) do
        if not data:IsNeeded() then
            dataStore[key] = nil -- Allow garbage collection
        end
    end
end

-- Coroutine function for processing data in chunks
local function processInChunks(data)
    for i = 1, #data do
        coroutine.yield(processDataPiece(data[i]))
    end
end

-- Example of starting a coroutine for heavy computations
local function StartCoroutineProcessing(data)
    local co = coroutine.create(processInChunks)
    coroutine.resume(co, data)
end

-- Main function to initialize game mode optimizations
local function InitializeGameMode()
    -- Setup resource and player processing
    ProcessPlayers()
    StartCoroutineProcessing(player.GetAll())

    -- Setup periodic cleanup
    timer.Create("CleanupTimer", 2, 0, function()  -- Cleanup every 60 seconds
        CleanupOldData(loadedResources)
        CleanupOldData(lastSentPositions)
    end)
end

-- Calling the initialization function to start the game mode
InitializeGameMode()

-- server_optimizations.lua
util.AddNetworkString("UpdatePosition")

local lastUpdateTimes = {}

-- Function to update player position with network throttling
local function UpdatePlayerPosition(player)
    local curTime = CurTime()
    if not lastUpdateTimes[player] or curTime - lastUpdateTimes[player] > 0.001 then  -- 100ms between updates
        net.Start("UpdatePosition")
        net.WriteEntity(player)
        net.WriteVector(player:GetPos())
        net.Send(player)
        lastUpdateTimes[player] = curTime
    end
end

-- Function to cleanup server memory
local function cleanupMemory()
    collectgarbage("collect")  -- Force a garbage collection pass
end
timer.Create("MemoryCleanupTimer", 2, 0, cleanupMemory)  -- Run every 60 seconds

-- Function to optimize server-side loops and condition statements
hook.Add("Think", "ServerThinkOptimizations", function()
    for _, player in ipairs(player.GetAll()) do
        if IsValid(player) and player:Alive() then
            -- Only process valid and alive players
            UpdatePlayerPosition(player)
        end
    end
end)

local function Startup()
	Core:Boot()
end
hook.Add( "Initialize", "Startup", Startup )

local function LoadEntities()
	Core:AwaitLoad()
end
hook.Add( "InitPostEntity", "LoadEntities", LoadEntities )

function GM:PlayerSpawn( ply )
	player_manager.SetPlayerClass( ply, "player_bhop" )
	self.BaseClass:PlayerSpawn( ply )
	
	Player:Spawn( ply )
end

function GM:PlayerInitialSpawn( ply )
	Player:Load( ply )
end

function GM:CanPlayerSuicide() return false end
function GM:PlayerShouldTakeDamage() return false end
function GM:GetFallDamage() return false end
function GM:PlayerCanHearPlayersVoice() return true end
function GM:IsSpawnpointSuitable() return true end
function GM:PlayerDeathThink( ply ) end
function GM:PlayerSetModel() end

-- Check if the player can pick up a weapon
function GM:PlayerCanPickupWeapon(ply, weapon)
    if ply.WeaponStripped or ply:HasWeapon(weapon:GetClass()) or ply:IsBot() then
        return false
    end

    -- Delayed ammo setting to ensure the weapon is fully spawned
    timer.Simple(0, function()
        if IsValid(ply) and IsValid(weapon) then
            ply:SetAmmo(999, weapon:GetPrimaryAmmoType())
        end
    end)

    return true
end

-- Hook to manage unlimited ammo
hook.Add("WeaponEquip", "UnlimitedAmmo", function(wep, ply)
    if not IsValid(wep) or not IsValid(ply) or not ply:IsPlayer() then return end

    local maxClip = wep:GetMaxClip1()
    if maxClip > 0 then
        wep:SetClip1(maxClip)
    end
end)

local function RemoveAllEntities()
    for _, ent in pairs(ents.FindByClass("prop_physics")) do
        if IsValid(ent) then
            ent:Remove()
        end
    end
    for _, ent in pairs(ents.FindByClass("prop_static")) do
        if IsValid(ent) then
            ent:Remove()
        end
    end
    for _, ent in pairs(ents.FindByClass("prop_dynamic")) do
        if IsValid(ent) then
            ent:Remove()
        end
    end
end

local mapName = game.GetMap()

if mapName == "bhop_alt_terassi" and mapName == "bhop_tumi" and mapName == "bhop_boredom" and mapName == "bhop_ambience" and mapName == "bhop_tehoputki" then
    hook.Add("InitPostEntity", "RemoveAllEntitiesOnMap", function()
        timer.Simple(1, RemoveAllEntities)  -- Add a slight delay before executing
    end)
end

hook.Add("ShouldCollide", "DisableBulletsOnSpecificMaps", function(ent1, ent2)
    -- Check if either of the entities is a bullet
    local isBullet1 = ent1:GetClass() == "bb_pistol_bullet"  -- Replace "entity_class_of_bullet" with the actual class name of bullets
    local isBullet2 = ent2:GetClass() == "entity_class_of_bullet"

    if isBullet1 or isBullet2 then
        local mapName = game.GetMap()  -- Get the current map's name
        local disabledMaps = {
            "bhop_sandtrap",
            "bhop_sandtrap2",
            "bhop_sandtrap3",
            "bhop_classicrainbowaux_fix",
            "kz_bhop_yonkoma"
        }

        -- Check if the map is in the list of disabled maps
        if table.HasValue(disabledMaps, mapName) then
            -- Prevent bullet collisions
            return false
        end
    end

    -- Allow all other collisions
    return true
end)