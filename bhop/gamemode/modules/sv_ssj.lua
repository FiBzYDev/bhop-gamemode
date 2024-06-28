-- Show Jump Status --
-- Edited: fibzy

local SSJ = {}
util.AddNetworkString "kawaii.secret"

util.AddNetworkString "train_update"
local movementSpeed = 32.8
local interval = (1 / engine.TickInterval()) / 10 
local deg, atan = math.deg, math.atan
local active = {}

local p = FindMetaTable "Player"
function p:InitStrafeTrainer(client)
    local data = self:GetPData("strafetrainer", 0)
    if tobool(data) then 
        self:SetNWBool("strafetrainer", true)
    end
end

function StrafeTrainer_CMD(client)
    local curr = tobool(client:GetPData("strafetrainer", 0))
    client:SetPData("strafetrainer", curr and 0 or 1)
    client:SetNWBool("strafetrainer", not curr)
end

local function NormalizeAngle(x)
    if x > 180 then 
        x = x - 360
    elseif x <= -180 then 
        x = x + 360
    end 
    return x
end

local function GetPerfectAngle(vel)
    return deg(atan(movementSpeed / vel))
end

local function NetworkList(ply)
    local watchers = {}

    for _, p in pairs(player.GetHumans()) do
        if not p.Spectating then continue end

        local ob = p:GetObserverTarget()

        if IsValid(ob) and ob == ply then
            watchers[#watchers + 1] = p
        end
    end
    watchers[#watchers + 1] = ply 
    return watchers
end

local last = {}
local tick = {}
local percentages = {}
local value = {}

local function SetupMove(client, data, cmd)
    if not client:Alive() then return end
    if client:GetMoveType() == MOVETYPE_NOCLIP then return end 

    if not percentages[client] then 
        percentages[client] = {}
        last[client] = 0
        tick[client] = 0
        value[client] = 0
    end
    local diff = NormalizeAngle(last[client] - data:GetAngles().y)
    local perfect = GetPerfectAngle(client:GetVelocity():Length2D())
    local perc = math.abs(diff) / perfect 
    local t = tick[client]
    if (t > interval) then 
        local avg = 0 
        for x = 0, interval do 
            avg = avg + percentages[client][x]
            percentages[client][x] = 0
        end
        avg = avg / interval 
        value[client] = avg 
        tick[client] = 0 
        net.Start "train_update"
            net.WriteFloat(avg)
        net.Send(NetworkList(client))
    else
        percentages[client][t] = perc 
        tick[client] = t + 1
    end
    last[client] = data:GetAngles().y
end
hook.Add("SetupMove", "sm_strafetrainer", SetupMove)

util.AddNetworkString "JHUD1_Notify"
util.AddNetworkString "JHUD1_Toggle"
util.AddNetworkString "JHUD1_IResponse"

local function initTables(ply)
    local jhud = JHUD1 or {}
    ply.JHUD1 = ply.JHUD1 or {}
    ply.JHUD1.Gains = ply.JHUD1.Gains or {}
    ply.JHUD1.Settings = {enabled = true, sync = true, gain = true}
    ply.JHUD1.LastTickVel = ply.JHUD1.LastTickVel or 0
    ply.JHUD1.LastUpdate = ply.JHUD1.LastUpdate or CurTime()
    ply.JHUD1.Jumps = ply.JHUD1.Jumps or {}
    ply.jsync = 0
    ply.jsyncalignA = 0
    ply.JHUD1.Strafes = 0
    ply.JHUD1.trajectory = 0
    ply.JHUD1.distance = Vector()
end

local function ResetData(ply)
    table.Empty(ply.JHUD1.Gains)
    ply.JHUD1.LastTickVel = 0
    ply.JHUD1.LastUpdate = CurTime()
    ply.JHUD1.HoldingSpace = false
    ply.JHUD1.Jumps = {}
    ply.jsync = 0
    ply.jsyncalignA = 0
    ply.JHUD1.trajectory = 0
    ply.JHUD1.distance = Vector()
end

local function ResetDataForJump(ply)
    table.Empty(ply.JHUD1.Gains)
    ply.JHUD1.LastTickVel = 0
    ply.JHUD1.LastUpdate = CurTime()
    ply.jsync = 0
    ply.jsyncalignA = 0
    ply.JHUD1.trajectory = 0
    ply.JHUD1.distance = Vector()
end
  
local function OnPlySpwn(ply)
    if ply.JHUD1 then
        ResetData(ply)
    end
end
hook.Add("PlayerSpawn", "JHUD1:PlayerSpawn", OnPlySpwn)

local function GetJump(ply)
    local vel = ply:GetVelocity():Length2D()
    return {vel}
end

local function TableAverage(tab)
    local final = 0
    if #tab == 0 then return 0 end
    for k, v in pairs(tab) do
        final = final + v
    end
    return final / #tab
end

local function norm(i) 
    if i > 180 then 
        i = i - 360 
    elseif i < -180 then 
        i = i + 360
    end 
    return i 
end

local fb = bit.band
local MonAngle = {}

local function GetStrafes(ply, key)
    if not ply:Alive() then return end
    if not ply.JHUD1 then return end
    --local buttons = data:GetButtons()
    if (key == IN_MOVELEFT) or (key == IN_MOVERIGHT) then
        --SPJ Debug print("KEYPRESS")
        ply.JHUD1.Strafes = ply.JHUD1.Strafes + 1
    end 
end

local function NotifyJHUD1(ply, msg, isprestrafe)
    net.Start "JHUD1_Notify"
    net.WriteTable(msg)
    net.WriteFloat(math.Round(math.Clamp(TableAverage(ply.JHUD1.Gains), 0, 100), 2))
    net.WriteBool(isprestrafe and isprestrafe or false)
    net.Send(ply)
end

local function MonitorSync(ply, data)
    if not ply:Alive() then return end
    if not ply.JHUD1 then return end
    local buttons = data:GetButtons()
    local ang = data:GetAngles().y

    if not ply:IsFlagSet(FL_ONGROUND + FL_INWATER) and ply:GetMoveType() != MOVETYPE_LADDER then
        if MonAngle[ply] == nil then return end

        local difference = norm(ang - MonAngle[ply])

        if difference > 0 then
            if ply.jsync ~= nil then
                ply.jsync = ply.jsync + 1
            end
            if (fb(buttons, IN_MOVELEFT) > 0) and not (fb(buttons, IN_MOVERIGHT) > 0) then
                ply.jsyncalignA = ply.jsyncalignA + 1
            end
        elseif difference < 0 then
            if ply.jsync ~= nil then
                ply.jsync = ply.jsync + 1
            end
            if (fb(buttons, IN_MOVERIGHT) > 0) and not (fb(buttons, IN_MOVELEFT) > 0) then
                ply.jsyncalignA = ply.jsyncalignA + 1
            end
        end
    end
    MonAngle[ply] = ang
end

local function getEfficiency(ply, data)
    if not ply.JHUD1 or not ply.JHUD1.HoldingSpace then return end
    local dist = ply:GetAbsVelocity() * engine.TickInterval() * ply:GetLaggedMovementValue()
    ply.JHUD1.trajectory = (ply.JHUD1.trajectory or 0) + dist:Length2D()
    ply.JHUD1.distance = ply.JHUD1.distance or Vector()
    ply.JHUD1.distance:Add(dist)
end

hook.Add("Move", "JHUD:GetEfficiency", getEfficiency)

local function CalculateEfficiency(ply)
    local distance = ply.JHUD1.distance and ply.JHUD1.distance:Length2D() or 0
    local trajectory = ply.JHUD1.trajectory or 0
    local efficiency = 0
    if distance > trajectory then
        distance = trajectory
    end
    if trajectory > 0 then
        efficiency = (distance / trajectory) * 100
    end
    return string.format("%.2f%%", efficiency)
end

local function DisplayJHUD1(ply)
    if not ply.JHUD1 then return end
    if not ply.JHUD1.HoldingSpace then return end
    if #ply.JHUD1.Jumps > 1 and ply.IsInside then return end 
    if ply:IsBot() then return end

    local currentJump = ply.JHUD1.Jumps[#ply.JHUD1.Jumps]
    local currentGain = math.Round(math.Clamp(TableAverage(ply.JHUD1.Gains), 0, 100), 2)
    local currentVel = currentJump[1]
    local difference
    local sync = math.Round((ply.jsyncalignA / ply.jsync) * 100, 2)
    if ply.jsync == 0 then
        sync = 0
    end
    local tStr = {math.Round(currentJump[1]), " | ",""}
    local str = table.Copy(tStr)
    if #ply.JHUD1.Jumps > 1 then
        local oldData = ply.JHUD1.Jumps[#ply.JHUD1.Jumps - 1]
        if (not oldData) then return end

        local oldVelocity = oldData[1]
        difference = math.Round(currentVel - oldVelocity)
    end

    if not ply.JHUD1.Settings["enabled"] then return end
    if #ply.JHUD1.Jumps > 1 then
        table.insert(str, "")
        if difference < 0 then
            table.insert(str, tostring(difference))
        elseif difference > 0 then
            table.insert(str, "+"..tostring(difference))
        elseif difference == 0 then
            table.insert(str, "0")
        end
        table.insert(str, ")")
    end

    if (#ply.JHUD1.Jumps > 1) then
        table.insert(str, " | ")
        table.insert(str, "(")
        table.insert(str, tostring(sync))
        table.insert(str, "%")
    end
    if (#ply.JHUD1.Jumps > 1) then
        table.insert(str, " | ")
        table.insert(str, "")
        table.insert(str, tostring(ply.JHUD1.Strafes))
    end

    if #ply.JHUD1.Jumps > 1 and ply.JHUD1.Settings["gain"] then
        table.insert(str, " | ")
        table.insert(str, "")
        table.insert(str, tostring(currentGain) .. "%")
    end

    if ply.JHUD1.Settings[9] then
        -- Insert EFF information into the display string
        table.insert(str, " | Eff: ")
        table.insert(str, CalculateEfficiency(ply))  -- EFF value formatted as a string
    end

    NotifyJHUD1(ply, str)
end

local function OnPlyHitGround(ply, bWater)
    if ply and ply != ply then return end
    if not ply.JHUD1 then initTables(ply) end
    if ply.JHUD1.LastUpdate + 0.2 < CurTime() and ply.JHUD1.HoldingSpace then
        table.insert(ply.JHUD1.Jumps, GetJump(ply))
        DisplayJHUD1(ply)

        ResetDataForJump(ply)
    end
    if not ply.JHUD1.HoldingSpace then
        DisplayJHUD1(ply)
        ResetData(ply)
    end
end

local function PlayerKeyPress(ply, key)
    if ply:IsBot() or ply:GetObserverMode() > 0 then return end
    if not ply.JHUD1 then initTables(ply) end

    if key == IN_JUMP and ply:Alive() then
        ply.JHUD1.HoldingSpace = true

        ply.JHUD1.Jumps[1] = GetJump(ply)
        if #ply.JHUD1.Jumps == 1 then
            local str = {")", tostring(math.Round(ply.JHUD1.Jumps[1][1]))}
            NotifyJHUD1(ply, str, true)
        end
    end
end

local function KeyRelease(ply, key)
    if key == IN_JUMP then
        ply.JHUD1.HoldingSpace = false
    end
end

local function ToggleJHUD1(ply, update)
    if not update then
        net.Start "JHUD1_Toggle"
        net.WriteTable(ply.JHUD1.Settings)
        net.Send(ply)
        return
    end

    net.Start "JHUD1_Toggle"
    net.WriteTable(ply.JHUD1.Settings)
    net.WriteBool(update and update or false)
    net.Send(ply)
end

util.AddNetworkString "JHUD1_RetrieveSettings"
local function JHUD1_RetrieveSettings(ply, openMenu)
    net.Start "JHUD1_RetrieveSettings"
    net.WriteBool(openMenu)
    net.WriteBool(tobool(ply:GetPData("jhudh_enabled")))
    net.Send(ply)
end

local function JHUD1_PlayerInit(ply)
    JHUD1_RetrieveSettings(ply, false)
end
net.Receive("JHUD1_IResponse", JHUD1_IResponse)

hook.Add("KeyPress", "JHUD1:KeyPress", PlayerKeyPress)
hook.Add("KeyRelease", "JHUD1:KeyRelease", KeyRelease)
hook.Add("OnPlayerHitGround", "JHUD1:HitGround", OnPlyHitGround)
hook.Add("SetupMove", "JHUD1:Sync", MonitorSync)
hook.Add("PlayerInitialSpawn", "JHUD1:Init", initTables)
hook.Add("OnPlayerHitGround", "JHUD1:HitGround", OnPlyHitGround)
hook.Add("PlayerInitialSpawn", "JHUD1:PlayerInit", JHUD1_PlayerInit)

util.AddNetworkString "JHUD12_Notify"
util.AddNetworkString "JHUD12_Toggle"
util.AddNetworkString "JHUD12_IResponse"

local function initTables(ply)
    local JHUD12 = JHUD12 or {}
    ply.JHUD12 = ply.JHUD12 or {}
    ply.JHUD12.Gains = ply.JHUD12.Gains or {}
    ply.JHUD12.Settings = {enabled = true, sync = true, gain = true}
    ply.JHUD12.LastTickVel = ply.JHUD12.LastTickVel or 0
    ply.JHUD12.LastUpdate = ply.JHUD12.LastUpdate or CurTime()
    ply.JHUD12.Jumps = ply.JHUD12.Jumps or {}
    ply.jsync2 = 0
    ply.jsyncalignA2 = 0
end

util.AddNetworkString "JHUD12_RetrieveSettings"
local function ResetData(ply)
    table.Empty(ply.JHUD12.Gains)
    ply.JHUD12.LastTickVel = 0
    ply.JHUD12.LastUpdate = CurTime()
    ply.JHUD12.HoldingSpace = false
    ply.JHUD12.Jumps = {}
    ply.jsync2 = 0
    ply.jsyncalignA2 = 0
end

local function ResetDataForJump(ply)
    table.Empty(ply.JHUD12.Gains)
    ply.JHUD12.LastTickVel = 0
    ply.JHUD12.LastUpdate = CurTime()
    ply.jsync2 = 0
    ply.jsyncalignA2 = 0
end

local function OnPlySpwn(ply)
    if ply.JHUD12 then
        ResetData(ply)
    end
end
hook.Add("PlayerSpawn", "JHUD12:PlayerSpawn", OnPlySpwn)

local function GetJump(ply)
    local vel = ply:GetVelocity():Length2D()
    return {vel}
end

local function TableAverage(tab)
    local final = 0

    if #tab == 0 then return 0 end
    for k, v in pairs(tab) do
        final = final + v
    end
    return final / #tab
end

local function NotifyJHUD12(ply, msg, isprestrafe)
    net.Start "JHUD12_Notify"
    net.WriteTable(msg)
    net.WriteFloat(math.Round(math.Clamp(TableAverage(ply.JHUD12.Gains), 0, 100), 2))
    net.WriteBool(isprestrafe and isprestrafe or false)
    net.Send(ply)
end

local function norm(i)
    if i > 180 then
        i = i - 360
    elseif i < -180 then
        i = i + 360
    end
    return i
end

local fb = bit.band
local MonAngle = {}

local function MonitorSync2(ply, data)
    if not ply:Alive() then
        return
    end

    local vel = data:GetVelocity()
    local ang = math.deg(math.atan2(vel.y, vel.x)) -- Calculate movement angle based on velocity

    if not ply:IsFlagSet(FL_ONGROUND + FL_INWATER) and ply:GetMoveType() ~= MOVETYPE_LADDER then
        if MonAngle[ply] == nil then
            return
        end

        local difference = norm(ang - MonAngle[ply])

        if difference > 0 then
            if ply.jsync2 ~= nil then
                ply.jsync2 = ply.jsync2 + 1
            end
            if (fb(data:GetButtons(), IN_MOVELEFT) > 0) and not (fb(data:GetButtons(), IN_MOVERIGHT) > 0) then
                ply.jsyncalignA2 = ply.jsyncalignA2 + 1
            end
        elseif difference < 0 then
            if ply.jsync2 ~= nil then
                ply.jsync2 = ply.jsync2 + 1
            end
            if (fb(data:GetButtons(), IN_MOVERIGHT) > 0) and not (fb(data:GetButtons(), IN_MOVELEFT) > 0) then
                ply.jsyncalignA2 = ply.jsyncalignA2 + 1
            end
        end
    end
    MonAngle[ply] = ang
end

local function DisplayJHUD12(ply)
    if not ply.JHUD12 then return end
    if not ply.JHUD12.HoldingSpace then return end
    if ply:IsBot() then return end

    local currentJump = ply.JHUD12.Jumps[#ply.JHUD12.Jumps]
    local currentGain = math.Round(math.Clamp(TableAverage(ply.JHUD12.Gains), 0, 100), 2)
    local currentVel = currentJump[1]
    local difference
    local sync2 = math.Round((ply.jsyncalignA2 / ply.jsync2) * 100, 2)
    if ply.jsync2 == 0 then
        sync2 = 0
    end
    local tStr = {"J: ", tostring(#ply.JHUD12.Jumps), " | ",""}
    local str = table.Copy(tStr)
    
    if #ply.JHUD12.Jumps > 1 then
        local oldData = ply.JHUD12.Jumps[#ply.JHUD12.Jumps - 1]
        if not oldData then return end

        local oldVelocity = oldData[1]

        difference = math.Round(currentVel - oldVelocity) - 0.5
    end

    if not ply.JHUD12.Settings["enabled"] then return end
    
    if #ply.JHUD12.Jumps > 1 then
        if difference < 0 then
            table.insert(str, math.Round(currentVel - tostring(difference)))
        elseif difference > 0 then
            table.insert(str, math.Round(currentVel - tostring(difference)))
        elseif difference == 0 then
            table.insert(str, "0")
        end
    end

    if #ply.JHUD12.Jumps >= 1 and ply.JHUD12.Settings["gain"] then
        table.insert(str, " | ")
        table.insert(str, "")
        table.insert(str, tostring(currentGain) .. "%")
    end

    if (#ply.JHUD12.Jumps > 1) then
        table.insert(str, " | ")
        table.insert(str, "")
        table.insert(str, tostring(sync2))
        table.insert(str, "")
    end

    NotifyJHUD12(ply, str)
end

local function OnPlyHitGround(ply, bWater)
    if LocalPlayer and ply != LocalPlayer() then return end
    if not ply.JHUD12 then initTables(ply) end
    if ply.JHUD12.LastUpdate + 0.2 < CurTime() and ply.JHUD12.HoldingSpace then
        table.insert(ply.JHUD12.Jumps, GetJump(ply))
        DisplayJHUD12(ply)

        ResetDataForJump(ply)
    end
    if not ply.JHUD12.HoldingSpace then
        DisplayJHUD12(ply)
        ResetData(ply)
    end
end

local function PlayerKeyPress(ply, key)
    if ply:IsBot() or ply:GetObserverMode() > 0 then return end
    if not ply.JHUD12 then initTables(ply) end

    if key == IN_JUMP and ply:Alive() then
        ply.JHUD12.HoldingSpace = true

        ply.JHUD12.Jumps[1] = GetJump(ply)
        if #ply.JHUD12.Jumps == 1 then
            local str = {"", tostring(math.Round(ply.JHUD12.Jumps[1][1]))}
            NotifyJHUD12(ply, str, true)
        end
    end
end

local function KeyRelease(ply, key)
    if key == IN_JUMP then
        ply.JHUD12.HoldingSpace = false
    end
end

local function ToggleJHUD12(ply, update)
    if not update then
        net.Start "JHUD12_Toggle"
        net.WriteTable(ply.JHUD12.Settings)
        net.Send(ply)
        return
    end

    net.Start "JHUD12_Toggle"
    net.WriteTable(ply.JHUD12.Settings)
    net.WriteBool(update and update or false)
    net.Send(ply)
end

util.AddNetworkString "JHUD12_RetrieveSettings"
local function JHUD12_RetrieveSettings(ply, openMenu)
    net.Start "JHUD12_RetrieveSettings"
    net.WriteBool(openMenu)
    net.WriteBool(tobool(ply:GetPData("JHUD12h_enabled")))
    net.WriteBool(tobool(ply:GetPData("JHUD12h_simple")))
    net.WriteBool(tobool(ply:GetPData("JHUD12h_gain")))
    net.WriteBool(tobool(ply:GetPData("jhudh_strafes")))
    net.Send(ply)
end

local function JHUD12_PlayerInit(ply)
    JHUD12_RetrieveSettings(ply, false)
end
net.Receive("JHUD12_IResponse", JHUD12_IResponse)

hook.Add("KeyPress", "JHUD12:KeyPress", PlayerKeyPress)
hook.Add("KeyRelease", "JHUD12:KeyRelease", KeyRelease)
hook.Add("SetupMove", "JHUD12:Sync", MonitorSync2)
hook.Add("Move", "JHUD1:Strafes", GetStrafes)
hook.Add("OnPlayerHitGround", "JHUD12:HitGround", OnPlyHitGround)
hook.Add("PlayerInitialSpawn", "JHUD12:Init", initTables)
hook.Add("OnPlayerHitGround", "JHUD12:HitGround", OnPlyHitGround)
hook.Add("PlayerInitialSpawn", "JHUD12:PlayerInit", JHUD12_PlayerInit)

local function LoadPlayer(pl)
    timer.Simple(1, function()
        local ssj = pl:GetPData("SSJ_Settings", false)
        pl.SSJ = {}
        pl.SSJ["Jumps"] = {}
        pl.SSJ["Settings"] = ssj and util.JSONToTable(ssj) or {false, true, false, false, true, false}
        pl.rawgain = 0
        pl.tick = 0
        pl.totalNormalYaw = 0
        pl.totalPerfectYaw = 0
        pl.lastJSSYaw = 0
    end)
end
hook.Add("PlayerInitialSpawn", "SSJ.LoadPlayer", LoadPlayer)

local function AddCommand()
    Command:Register({"ssj", "sj", "ssjmenu"}, function(pl)
        SSJ:OpenMenuForPlayer(pl, pl.SSJ["Settings"])
    end)
end
hook.Add("Initialize", "SSJ.AddCommand", AddCommand)

local function OnPlayerHitGround(pl)
    if pl.SSJ then
        if not pl.SSJ["Jumps"][1] then
            pl.SSJ["Jumps"][1] = {0, 0}
        end
        table.insert(pl.SSJ["Jumps"], SSJ:RetrieveData(pl))
        SSJ:Display(pl)
        pl.rawgain = 0
        pl.tick = 0
        pl.totalNormalYaw = 0
        pl.totalPerfectYaw = 0
        pl.SSJ.trajectory = 0
        pl.SSJ.distance = Vector()
        pl.SSJ.efficiency = 0
    end
end

local function KeyPress(pl, key)
    if key == IN_JUMP then
        pl.SSJ["InSpace"] = true
    end
    if key == IN_JUMP and pl:Alive() then
        pl.tick = 0
        pl.rawgain = 0
        pl.maxgain = 0
        pl.totalNormalYaw = 0
        pl.totalPerfectYaw = 0
        pl.SSJ["Jumps"] = {}
        pl.SSJ["Jumps"][1] = SSJ:RetrieveData(pl)

        if PlayerJumps and PlayerJumps[pl] and PlayerJumps[pl] <= 1 then
            local observers = {pl}

            for k, v in pairs(player.GetHumans()) do
                if IsValid(v:GetObserverTarget()) and v:GetObserverTarget() == pl then
                    table.insert(observers, v)
                end
            end
            Core:Send(observers, "jump_update", {pl, 0})
            PlayerJumps[pl] = 0
        end
        SSJ:Display(pl)
    end
end

local function KeyRelease(pl, key)
    if key == IN_JUMP and pl.SSJ["InSpace"] then
        pl.SSJ["InSpace"] = false
    end
end

hook.Add("KeyPress", "SSJ.KeyPress", KeyPress)
hook.Add("KeyRelease", "SSJ.KeyRelease", KeyRelease)

-- Modified OnPlayerHitGround to use IsOnGround from CMoveData structure
local function OnPlayerHitGround(pl, mv)
    if pl.SSJ and pl:IsOnGround() then
        if not pl.SSJ["Jumps"][1] then
            pl.SSJ["Jumps"][1] = {0, 0}
        end
        table.insert(pl.SSJ["Jumps"], SSJ:RetrieveData(pl))
        SSJ:Display(pl)
        pl.rawgain = 0
        pl.tick = 0
        pl.totalNormalYaw = 0
        pl.totalPerfectYaw = 0
        pl.SSJ.trajectory = 0
        pl.SSJ.distance = Vector()
        pl.SSJ.efficiency = 0
    end
end
hook.Add("Move", "SSJ.OnPlayerHitGround", OnPlayerHitGround)

function SSJ:OpenMenuForPlayer(pl, data)
    UI:SendToClient(pl, "ssj", data)
end

function SSJ:RetrieveData(pl)
    local velocity = math.Round(pl:GetVelocity():Length2D())
    local pos = pl:GetPos().z
    return {velocity, pos}
end

local function InterfaceResponse(pl, data)
    local k = data[1]

    pl.SSJ["Settings"][k] = (not pl.SSJ["Settings"][k])
    pl:SetPData("SSJ_Settings", util.TableToJSON(pl.SSJ["Settings"]))

    SSJ:OpenMenuForPlayer(pl, k)
end
UI:AddListener("ssj", InterfaceResponse)

local fade = 0

local function GetJSSSuffix(jss)
    return jss >= 101 and "✓" or (jss <= 99 and "▲" or "▲")
end
local ftj = 0
local ftjStart = 0
local distance = Vector()
local trajectory = 0
local efficiency = 0

-- Function to format efficiency for display
local function FormatEfficiency()
    if efficiency >= 1.0 then
        return "0%"
    else
        return string.format("%.2f%%", efficiency * 100)
    end
end

function SSJ:Display(pl)
    if not pl.SSJ then return end
    if not pl.SSJ["InSpace"] then return end
    if #pl.SSJ["Jumps"] > 1 and pl.IsInside then return end
    if pl:IsBot() then return end 

    -- Calculate distance and trajectory for each jump
    local currentJump = pl.SSJ["Jumps"][#pl.SSJ["Jumps"]]
    local currentVel = currentJump[1]
    local currentHeight = currentJump[2]
    local dStr = {_C["Prefixes"].Timer, color_white}
    local difference, height

    local gain = pl.rawgain / pl.tick * 100
    gain = math.floor(gain * 100 + 0.5) / 100

    local jss = 0
    if pl.totalPerfectYaw ~= 0 then
        jss = (pl.totalNormalYaw / pl.totalPerfectYaw) * 100
    end

    if gain > 0 then
        if gain >= 80 then
            color = _C["Prefixes"].Timer
        elseif gain > 70 and gain <= 80 then
            color = Color(39, 255, 0, 255)
        elseif gain > 60 and gain <= 70 then
            color = Color(255, 191, 0, 255)
        else
            color = Color(255, 0, 0, 255)
        end 
    end

    if gain == math.huge or gain ~= gain then
        gain = 0
    end

    if gain > pl.maxgain or 0 then 
        pl.maxgain = gain
    end

    -- Check if player has left the zone and update ftj
    local isInZone = Zones:IsInside(pl, (pl.Style == _C.Style.Bonus) and 2 or 0)
    if isInZone then
        ftjStart = 0  -- Reset ftjStart if player is inside the zone
    else
        if ftjStart == 0 then
            ftjStart = CurTime()  -- Set ftjStart to the current time when leaving zone
        end
        ftj = CurTime() - ftjStart  -- Calculate ftj (ticks spent outside the zone)
    end

    local oldData
    if (#pl.SSJ["Jumps"] ~= 1) then
        oldData = pl.SSJ["Jumps"][#pl.SSJ["Jumps"] - 2]
        if (not oldData) then return end
        local oldVelocity = oldData[1]
        local oldHeight = oldData[2]
        difference = math.Round(currentVel - oldVelocity)
        height = math.Round(currentHeight - oldHeight)
    end
    if (#pl.SSJ["Jumps"] == 6) then 
        JAC:ReportStat(pl, "gain", pl.maxgain)
        pl.maxgain = 0
    end

    local clients = {pl}
    for k, v in pairs(player.GetAll()) do
        if not v.Spectating or not v.SSJ["Settings"][5] then continue end 
        local target = v:GetObserverTarget()
        if target:IsValid() and target == pl then 
            table.insert(clients, v)
        end
    end

    for k, v in pairs(clients) do
        local str = table.Copy(dStr)
        local str2 = table.Copy(dStr2)
        net.Start "kawaii.secret"
            net.WriteInt(#pl.SSJ["Jumps"], 16)
            net.WriteFloat(gain)
            net.WriteInt(currentVel, 18)
        net.Send(v)

        if not v.SSJ["Settings"][1] then continue end
        if not v.SSJ["Settings"][2] and #pl.SSJ["Jumps"] ~= 7 then continue end

        -- Adjust the jump count to start from 1
        local displayJumpCount = #pl.SSJ["Jumps"] - 1

        if #pl.SSJ["Jumps"] == 1 then
            table.insert(str, "Prestrafe: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(math.Round(currentVel - 0.5)) )
            table.insert(str, color_white)
        end

        if displayJumpCount > 0 then
            table.insert(str, "J: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(displayJumpCount))
            table.insert(str, color_white)
        end

        if displayJumpCount > 0 then
            table.insert(str, " | S: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(math.Round(currentVel - 0.5)))
            table.insert(str, color_white)
        end

        if displayJumpCount > 0 and v.SSJ["Settings"][4] then
            table.insert(str, " | H ∆: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(height))
            table.insert(str, color_white)
        end
        if displayJumpCount > 0 and v.SSJ["Settings"][3] then
            table.insert(str, " | S ∆: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(difference))
            table.insert(str, color_white)
        end
        if displayJumpCount > 0 and v.SSJ["Settings"][6] then
            table.insert(str, " | G: ")
            table.insert(str, color)
            table.insert(str, tostring(gain) .. "%")
            table.insert(str, color_white)
        end

        if displayJumpCount > 0 and v.SSJ["Settings"][7] then
            table.insert(str, " | SPJ: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(pl.JHUD.Strafes))
            table.insert(str, color_white)
        end

        if displayJumpCount > 0 and v.SSJ["Settings"][8] then
            if jss >= 101 then
                table.insert(str, " | JSS: ")
                table.insert(str, _C["Prefixes"].Timer)  -- Blue color for JSS value
                table.insert(str, tostring(math.Round(jss, 0)))
                table.insert(str, "")
                table.insert(str, Color(39, 255, 0, 255))  -- Green color for "✓"
                table.insert(str, "✓")
            else
                -- Insert "▲" symbol with red color for jssSuffix
                local jssSuffix = (jss <= 70 and "▼" or "▲")
                table.insert(str, " | JSS: ")
                table.insert(str, _C["Prefixes"].Timer)  -- Blue color for JSS value
                table.insert(str, tostring(math.Round(jss, 0)))
                table.insert(str, Color(255, 0, 0, 255))  -- Red color for "▲" or "▲"
                table.insert(str, jssSuffix)
            end
        end

        if displayJumpCount > 0 and v.SSJ["Settings"][9] then
            -- Insert EFF information into the display string
            table.insert(str, " | Eff: ")
            table.insert(str, CalculateEfficiency(pl))  -- EFF value formatted as a string
        end

        -- Check if player has landed
        local hasLanded = pl:OnGround()

        -- Initialize jump start time if it's not already set
        if hasLanded and not pl.jumpStartTime then
            pl.jumpStartTime = CurTime()
        elseif not hasLanded then
            pl.jumpStartTime = nil  -- Reset jump start time if the player is not on the ground
        end

        -- Reset jump start time if it's set and it's time to reset
        if pl.jumpStartTime and CurTime() - pl.jumpStartTime > 0.8 then
            pl.jumpStartTime = nil
        end

        -- Calculate jump time if the player has a jump start time
        local jumpTimeFormatted = nil  -- Default value for jump time
        if pl.jumpStartTime then
            local jumpTime = CurTime() - pl.jumpStartTime
            if jumpTime > 0.01 then -- Ensure jump time is displayed if it's more than 0.01 seconds
                jumpTimeFormatted = string.format("%.2f", jumpTime) .. "s"
            else
                jumpTimeFormatted = "0.72s" -- Default value if jump time is less than 0.01 seconds
            end
        end

        -- Add jump time to the display string if the condition is met
        if displayJumpCount > 0 and v.SSJ["Settings"][10] then
            table.insert(str, color_white)
            table.insert(str, " | Time: ")
            table.insert(str, _C["Prefixes"].Timer)
            if jumpTimeFormatted then
                table.insert(str, jumpTimeFormatted)
            else
                table.insert(str, "0.72s")
            end
            table.insert(str, color_white)
        end

        Core:Send(v, "Print", {"Timer", str})
    end
end
