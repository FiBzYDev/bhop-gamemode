local mc, mp = math.Clamp, math.pow
local bn, ba, bo = bit.bnot, bit.band, bit.bor
local sl, ls = string.lower, {}
local lp, ft, ct, gf = LocalPlayer, FrameTime, CurTime, {}
local mabs, matan, mdeg, NormalizeAngle = math.abs, math.atan, math.deg, math.NormalizeAngle
local groundTicks, longGround, storedVelocity = {}, {}, {}

PlayerJumps = {}

local function ChangePlayerAngle(ply, cmd)
    if ply.Style == _C.Style.Backwards and not ply:IsOnGround() then
        local d = math.AngleDifference(cmd:GetViewAngles().y, ply:GetVelocity():Angle().y)
        if d > -100 and d < 100 then
            cmd:SetForwardMove(0)
            cmd:SetSideMove(0)
        end
    end
end
hook.Add("StartCommand", "ChangeAngles", ChangePlayerAngle)

if CLIENT then
    local function AutoStrafe(cmd)
        local ply = LocalPlayer()
        local client = ply:EntIndex()

        if not ply:Alive() or ply:IsBot() then return end
        if LocalPlayer().Style == _C.Style.AutoStrafe and cmd:KeyDown(IN_JUMP) then

        local hMoveType = ply:GetMoveType()
        if hMoveType == MOVETYPE_NOCLIP or hMoveType == MOVETYPE_LADDER then return end

        if not (ply:GetMoveType() == MOVETYPE_WALK) and not ply:IsOnGround() and mv:KeyDown(IN_JUMP) then return end

        local mouseX = cmd:GetMouseX()
        local vel = ply:GetVelocity()

        if mouseX > 0 then
            vel.y = 8000000000000000000
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_MOVERIGHT))
        elseif mouseX < 0 then
            vel.y = -8000000000000000000
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_MOVELEFT))
        end

        ply:SetVelocity(vel)
    end
end
    hook.Add("CreateMove", "AutoStrafeHook", function(cmd)
        AutoStrafe(cmd)
    end)
end

hook.Add("Move", "SetMaxSpeed", function(ply, mv)
    mv:SetMaxSpeed(math.huge)
    mv:SetFinalStepHeight(18)
end)

local crouchTimes = {}

hook.Add("SetupMove", "MaxMoveSpeed", function(ply, mv, data)
    if not (ply:GetMoveType() == MOVETYPE_WALK) and not ply:IsOnGround() and mv:KeyDown(IN_JUMP) then
        mv:SetMaxClientSpeed(math.huge)
    else
        local onGround = ply:IsOnGround()
        local crouching = mv:KeyDown(IN_DUCK)

        if onGround and crouching then
            if not crouchTimes[ply] then
                crouchTimes[ply] = CurTime()
            elseif CurTime() - crouchTimes[ply] >= 0.4 then
                mv:SetMaxClientSpeed(150)
                return
            end
        else
            crouchTimes[ply] = nil
        end

        mv:SetMaxClientSpeed(250)
    end
end)

local function MovementCMD(cmd)
    local ply = LocalPlayer()
    if IsValid(ply) and ply:GetMoveType() ~= MOVETYPE_NOCLIP and ply:GetMoveType() ~= MOVETYPE_OBSERVER then
        local fmove = cmd:KeyDown(IN_FORWARD) and 8000000000000000000 or cmd:KeyDown(IN_BACK) and -8000000000000000000 or 0
        local smove = cmd:KeyDown(IN_MOVERIGHT) and 8000000000000000000 or cmd:KeyDown(IN_MOVELEFT) and -8000000000000000000 or 0
        cmd:SetForwardMove(fmove)
        cmd:SetSideMove(smove)
    end
end
hook.Add("CreateMove", "MovementCMD", MovementCMD)

local function SetSideSpeed(moveData, speed)
    if not moveData then
        print("Error: moveData is nil")
        return
    end

    moveData:SetMaxClientSpeed(speed)
    moveData:SetMaxSpeed(speed)
    local vel = moveData:GetVelocity()
    
    if moveData:KeyDown(IN_MOVELEFT) then
        vel.y = -speed
    elseif moveData:KeyDown(IN_MOVERIGHT) then
        vel.y = speed
    else
        vel.y = 0
    end

    moveData:SetVelocity(vel)
end

-- Example usage within a hypothetical game loop or event handler
hook.Add("PlayerMove", "CustomSideSpeed", function(player, moveData)
    local sideSpeed = 8000000000000000000  -- Example speed value
    SetSideSpeed(moveData, sideSpeed)
end)

local function FixCrouchLoss(ply, data)
    if not IsValid(ply) or ply:IsBot() or not ply:IsOnGround() then
        groundTicks[ply], storedVelocity[ply], longGround[ply] = 0, nil, false
        return
    end

    local moveType = ply:GetMoveType()
    local onGround = ply:IsOnGround()
    local keyDownJump = data:KeyDown(IN_JUMP)
    local keyReleasedDuck = data:KeyReleased(IN_DUCK)
    local keyDownDuck = data:KeyDown(IN_DUCK)
    local currentVelocity = data:GetVelocity()

    groundTicks[ply] = groundTicks[ply] or 0

    if moveType ~= MOVETYPE_NOCLIP and keyDownJump then
        local jumpForce = 289
        ply.pFix = ply.pFix or {}

        if ply.pFix.DoubleJumpCooldown and ply.pFix.DoubleJumpCooldown > CurTime() + 10 then
            ply.pFix.DoubleJumped = false
        end

        if onGround and keyReleasedDuck then
            currentVelocity.z = jumpForce - (ply:GetGravity() * 800 * FrameTime() * 0.5)
            data:SetVelocity(currentVelocity)
            ply.pFix.DoubleJumped = true
            ply.pFix.DoubleJumpCooldown = CurTime() + 0.6
        else
            ply.pFix.DoubleJumped = false
        end
    end

    if groundTicks[ply] == 1 then
        storedVelocity[ply] = currentVelocity
    elseif groundTicks[ply] > 1 and keyDownDuck and not onGround then
        data:SetVelocity(storedVelocity[ply] or currentVelocity)
    end

    if groundTicks[ply] > 1 then
        longGround[ply] = true
    end
end
hook.Add("SetupMove", "FixCrouchLoss", FixCrouchLoss)

local function norm(angle)
    return (angle + 180) % 360 - 180
end

local function GetPerfectYaw(mv, speed)
    return speed == 0 and 0 or mabs(mdeg(matan(mv / speed)))
end

local function CalculateGainCoefficient(wishspeed, current)
    if current ~= 0 and current < 32.8 then
        return (wishspeed - mabs(current)) / wishspeed
    end
    return 0
end

local memoizedResults = {}
local function expensiveFunction(input)
    if memoizedResults[input] then return memoizedResults[input] end
    local result = input ^ 2
    memoizedResults[input] = result
    return result
end

local pool = {}
local function getTable() return table.remove(pool) or {} end
local function releaseTable(t) table.clear(t) pool[#pool + 1] = t end

local eventListeners = {}
local function addEventListener(event, listener)
    if not eventListeners[event] then eventListeners[event] = {} end
    eventListeners[event][listener] = true
end

local function removeEventListener(event, listener)
    if eventListeners[event] then eventListeners[event][listener] = nil end
end

local function dispatchEvent(event, ...)
    for listener in pairs(eventListeners[event] or {}) do
        listener(...)
    end
end

function CalculatePlayerGainCoefficient(ply, wishspeed, current)
    if SERVER and not ply:IsBot() then
        local wishspd = math.min(wishspeed, 32.8)
        ply.tick = (ply.tick or 0) + 1
        ply.rawgain = (ply.rawgain or 0) + CalculateGainCoefficient(wishspd, current)
    end
end

local function DisplayStats(ply, data)
    local aim = data:GetMoveAngles()
    local forward, right = aim:Forward(), aim:Right()
    forward.z, right.z = 0, 0
    forward:Normalize()
    right:Normalize()

    local fmove = data:GetForwardSpeed()
    local smove = data:GetSideSpeed()
    local wishvel = forward * fmove + right * smove
    wishvel.z = 0

    local wishspeed = wishvel:Length()
    local maxSpeed = data:GetMaxSpeed()
    if wishspeed > maxSpeed then
        wishvel = wishvel * (maxSpeed / wishspeed)
        wishspeed = maxSpeed
    end

    local vel = ply:GetAbsVelocity()
    if SERVER and ply.totalNormalYaw then
        ply.totalNormalYaw = ply.totalNormalYaw + mabs(NormalizeAngle(aim.yaw - (ply.lastJSSYaw or 0)))
        ply.totalPerfectYaw = ply.totalPerfectYaw + GetPerfectYaw(32.8, ply:GetAbsVelocity():Length2D())
        ply.lastJSSYaw = aim.yaw
    end

    local distance = Vector()
    local dist = vel * engine.TickInterval() * ply:GetLaggedMovementValue()
    distance:Add(dist)
    local trajectory = distance:Length2D()
    local efficiency = distance:Length2D() / trajectory

   CalculatePlayerGainCoefficient(ply, wishspeed, vel:Dot(wishvel:GetNormal()))

    if not (st == 10 or st == 12 or st == 13) then
        local SPEED_CAP = 32.8
        local current = vel:Dot(wishvel:GetNormal())
        if current < SPEED_CAP then
            local gaincoeff = (wishspeed - mabs(current)) / wishspeed
        end
    end
end
hook.Add("SetupMove", "DisplayStats", DisplayStats)

local function VectorNormalize(v)
    local length = v:Length()
    if length ~= 0 then v:Normalize() end
    return length
end

local function VectorCopy(vec) return Vector(vec.x, vec.y, vec.z) end

local function CustomDotProduct(vec1, vec2)
    return vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z
end

local function AngleVectors(angles, forward, right, up)
    local angle, sr, sp, sy, cr, cp, cy

    angle = angles.y * (math.pi * 2 / 360)
    sy = math.sin(angle)
    cy = math.cos(angle)

    angle = angles.p * (math.pi * 2 / 360)
    sp = math.sin(angle)
    cp = math.cos(angle)

    angle = angles.r * (math.pi * 2 / 360)
    sr = math.sin(angle)
    cr = math.cos(angle)

    if forward then
        forward.x, forward.y, forward.z = cp * cy, cp * sy, -sp
    end

    if right then
        right.x, right.y, right.z = (-1 * sr * sp * cy) + (-1 * cr * -sy), (-1 * sr * sp * sy) + (-1 * cr * cy), -1 * sr * cp
    end

    if up then
        up.x, up.y, up.z = (cr * sp * cy) + (-sr * -sy), (cr * sp * sy) + (-sr * cy), cr * cp
    end
end

local function SV_AirAccelerate(velocity, wishvel)
    local wishspd = VectorNormalize(wishvel)
    if wishspd > 30 then wishspd = 32.8 end

    local currentspeed = CustomDotProduct(velocity, wishvel)
    local addspeed = wishspd - currentspeed
    if addspeed <= 0 then return end

    local accelspeed = addspeed
    if accelspeed > addspeed then accelspeed = addspeed end

    for i = 1, 2 do 
        velocity[i] = velocity[i] + accelspeed * wishvel[i] 
    end
end

local function SV_AirMove(ply, mv, cmd)
    local velocity = mv:GetVelocity()
    local fmove, smove = cmd:GetForwardMove(), cmd:GetSideMove()
    local forward, right, up = Vector(), Vector(), Vector()
    local ang = mv:GetAngles()

    if ply:GetMoveType() == MOVETYPE_WALK and ply:IsOnGround() and not mv:KeyDown(IN_JUMP) then
        return false
    end

    AngleVectors(ang, forward, right, up)

    if mv:KeyDown(IN_MOVERIGHT) then smove = smove + 80000000000000000 end
    if mv:KeyDown(IN_MOVELEFT) then smove = smove - 80000000000000000 end

    cmd:SetForwardMove(fmove)
    cmd:SetSideMove(smove)

    local wishvel = forward * fmove + right * smove
    if ply:GetMoveType() ~= MOVETYPE_WALK then wishvel.z = cmd:GetUpMove() end

    local wishdir = VectorCopy(wishvel)
    local wishspeed = VectorNormalize(wishdir)
    local sv_maxspeed = GetConVar("sv_maxspeed"):GetFloat()
    local vel = ply:GetAbsVelocity()

    CalculatePlayerGainCoefficient(ply, wishspeed, vel:Dot(wishvel:GetNormal()))
   --[[] if wishspeed > sv_maxspeed then
        wishvel = wishvel * (sv_maxspeed / wishspeed)
        wishspeed = sv_maxspeed
    end--]]

    SV_AirAccelerate(velocity, wishvel)
    mv:SetVelocity(velocity)
end

hook.Add("Move", "HandleAirStrafing", function(ply, mv)
    if ply:GetMoveType() == MOVETYPE_WALK and ply:IsOnGround() and not mv:KeyDown(IN_JUMP) then
        return false
    end

    local controlDir = Vector(0, 0, 0)
    local moveAngles = mv:GetAngles() -- Get the movement angles from the move data

    if mv:KeyDown(IN_FORWARD) then controlDir = controlDir + moveAngles:Forward() end
    if mv:KeyDown(IN_BACK) then controlDir = controlDir - moveAngles:Forward() end
    if mv:KeyDown(IN_MOVELEFT) then controlDir = controlDir - moveAngles:Right() end
    if mv:KeyDown(IN_MOVERIGHT) then controlDir = controlDir + moveAngles:Right() end
    controlDir:Normalize()

    if controlDir ~= Vector(0, 0, 0) then
        local currentVelocity = mv:GetVelocity()
        local dotProduct = currentVelocity:Dot(controlDir)
        local maxVelocity = 32.8 -- Set your desired max air speed here

        if dotProduct < maxVelocity then
            local newVelocity = currentVelocity + controlDir * (maxVelocity - dotProduct)
            mv:SetVelocity(newVelocity)
        end
    end
end)

--[[hook.Add("Move", "HandleAirStrafing", function(ply, mv)
    if not IsValid(ply) or not ply:Alive() or ply:IsOnGround() then return end

    local controlDir = Vector(0, 0, 0)
    local eyeAngles = mv:GetAngles() -- Get the movement angles from the move data

    if mv:KeyDown(IN_FORWARD) then controlDir = controlDir + Vector(1, 0, 0) end
    if mv:KeyDown(IN_BACK) then controlDir = controlDir - Vector(1, 0, 0) end
    if mv:KeyDown(IN_MOVELEFT) then controlDir = controlDir - Vector(0, -1, 0) end
    if mv:KeyDown(IN_MOVERIGHT) then controlDir = controlDir + Vector(0, -1, 0) end
    controlDir:Normalize()

    if controlDir ~= Vector(0, 0, 0) then
        -- Apply camera rotation to control direction
        controlDir:Rotate(Angle(0, eyeAngles.y, 0))

        local currentVelocity = mv:GetVelocity()
        local dotProduct = currentVelocity:Dot(controlDir)
        local maxVelocity = 32.8 -- Adjust your desired max air speed here

        if dotProduct < maxVelocity then
            local newVelocity = currentVelocity + controlDir * (maxVelocity - dotProduct)
            mv:SetVelocity(newVelocity)
        end
    end
end)--]]

function GM:Move(client, data)
    if not IsValid(client) or (lp and client ~= lp()) or not client:Alive() then return end

    local velocity = data:GetVelocity()
    local velocity2d = velocity:Length2D()
    local style = client.Style
    local onGround = client:IsOnGround()

    if client.InStartZone and not client:GetNWInt('inPractice', false) and style ~= 11 then 
        local speedcap = 280
        if style == 3 or style == 4 or style == 5 then speedcap = 450 end

        if velocity2d > speedcap and not client.Teleporting then 
            local diff = velocity2d - speedcap
            velocity:Sub(Vector(velocity.x > 0 and diff or -diff, velocity.y > 0 and diff or -diff, 0))
            data:SetVelocity(velocity)
            return false
        end
    end

    local function setDuckSpeed(client, speed)
        client:SetDuckSpeed(speed)
        client:SetUnDuckSpeed(speed * 0.5)
    end

    if client:GetMoveType() == MOVETYPE_WALK then
         if not data:KeyDown(IN_JUMP) then
            setDuckSpeed(client, 0.4)
        else
            setDuckSpeed(client, -1)
         end
     else
        setDuckSpeed(client, -1)
    end

    local aim = data:GetMoveAngles()
    local forward, right = aim:Forward(), aim:Right()
    forward.z, right.z = 0, 0
    forward:Normalize()
    right:Normalize()

    local wish = forward * data:GetForwardSpeed() + right * data:GetSideSpeed()
    wish.z = 0

    local wishspeed = (wish:Length() > 30) and 49.2 or wish:Length()
    local current = client:GetAbsVelocity():Dot(wish:GetNormalized())

    client.ctick = (client.ctick or 0) + 1
    if (client.ctick % 100) == 1 then 
        client.current = velocity2d
    end

    return false
end

local function norm(angle)
    angle = angle % 360
    if angle > 180 then angle = angle - 360
    elseif angle < -180 then angle = angle + 360
    end
    return angle
end

TIMER = {
    SyncMonitored = {},
    SyncAngles = {},
    SyncB = {},
    SyncA = {},
    SyncTick = {}
}

function TIMER:GetSync(client)
    if not self.SyncMonitored[client] then
        return 0
    end

    if SERVER then
        local x = math.Round((((self.SyncB[client] / self.SyncTick[client]) * 100) + ((self.SyncA[client] / self.SyncTick[client]) * 100)) / 2, 2)
        if x ~= x then
            return 0 
        else
            return x 
        end
    else
        return client.sync
    end
end

function GM:SetupMove(client, data)
    if not IsValid(client) or client:IsBot() then return end 

    local buttons = data:GetOldButtons()

    if client.Style ~= 6 and client.Style ~= 7 then 
        if ba(buttons, IN_JUMP) > 0 then
            if client:WaterLevel() < 2 and client:GetMoveType() ~= MOVETYPE_LADDER and client:IsOnGround() then
                data:SetOldButtons(ba(buttons, bn(IN_JUMP)))
            end
        end
    end

    if client:GetMoveType() ~= MOVETYPE_NOCLIP then 
        if client:OnGround() then 
            if client.Style == 6 then 
                local vel = data:GetVelocity()
                local ts = ls[client] or 700

                if vel:Length2D() > ts then
                    local diff = vel:Length2D() - ts
                    vel:Sub(Vector(vel.x > 0 and diff or -diff, vel.y > 0 and diff or -diff, 0))
                end
                
                data:SetVelocity(vel)
            end
        else
            if client.Style == 2 or client.Style == 4 then 
                data:SetSideSpeed(0)

                if client.Style == 4 and data:GetForwardSpeed() < 0 then 
                    data:SetForwardSpeed(0)
                end 

            elseif client.Style == 5 then 
                data:SetForwardSpeed(0)
                    
                if data:GetSideSpeed() > 0 then
                    data:SetSideSpeed(0)
                end

            elseif client.Style == 3 and (data:GetForwardSpeed() == 0 or data:GetSideSpeed() == 0) then
                data:SetForwardSpeed(0)
                data:SetSideSpeed(0)
            end
        end
    end

    if not TIMER.SyncAngles[client] then
        TIMER.SyncAngles[client] = client:EyeAngles()
    end

    if SERVER and not client:IsFlagSet(FL_ONGROUND + FL_INWATER) and client:GetMoveType() ~= MOVETYPE_LADDER and TIMER.SyncMonitored[client] and TIMER.SyncAngles[client] then
        local diff = norm(data:GetAngles().y - TIMER.SyncAngles[client].y)
        local lastkey = client.lastkey or 6969 

        if diff > 0 then 
            TIMER.SyncTick[client] = (TIMER.SyncTick[client] or 0) + 1

            if ba(buttons, IN_MOVELEFT) > 0 and not ba(buttons, IN_MOVERIGHT) > 0 then 
                TIMER.SyncA[client] = (TIMER.SyncA[client] or 0) + 1 
            end 

            if data:GetSideSpeed() < 0 then 
                TIMER.SyncB[client] = (TIMER.SyncB[client] or 0) + 1
            end

            if lastkey ~= 1 then 
                client.strafes = (client.strafes or 0) + 1 
                client.strafesjump = (client.strafesjump or 0) + 1
                client.lastkey = 1 
            end
        elseif diff < 0 then 
            TIMER.SyncTick[client] = (TIMER.SyncTick[client] or 0) + 1

            if ba(buttons, IN_MOVERIGHT) > 0 and not ba(buttons, IN_MOVELEFT) > 0 then 
                TIMER.SyncA[client] = (TIMER.SyncA[client] or 0) + 1 
            end 

            if data:GetSideSpeed() > 0 then 
                TIMER.SyncB[client] = (TIMER.SyncB[client] or 0) + 1
            end

            if lastkey ~= 0 then 
                client.strafes = (client.strafes or 0) + 1 
                client.strafesjump = (client.strafesjump or 0) + 1
                client.lastkey = 0
            end
        end

        local currentAngles = data:GetAngles()
        local newAngles = Angle(currentAngles.p, TIMER.SyncAngles[client].y + diff, currentAngles.r)
        data:SetAngles(newAngles)

        TIMER.SyncAngles[client] = data:GetAngles()
    end
end

local function ba(buttons, key)
    return bit.band(buttons, key)
end

-- Function to calculate and get synchronization data
function TIMER:GetSync(client)
    if not self.SyncMonitored[client] then
        return 0
    end

    if SERVER then
        local x = math.Round((((self.SyncB[client] / self.SyncTick[client]) * 100) + ((self.SyncA[client] / self.SyncTick[client]) * 100)) / 2, 2)
        if x ~= x then
            return 0
        else
            return x
        end
    else
        return client.sync
    end
end

-- Hook to handle player movement
hook.Add("SetupMove", "OnPlayerSetupMove", function(client, mv, cmd)
    if not client:Alive() or client:IsBot() then return end

    local hMoveType = client:GetMoveType()
    if hMoveType == MOVETYPE_NOCLIP or hMoveType == MOVETYPE_LADDER then return end

    if client:OnGround() then return end

    if not TIMER.SyncAngles[client] then
        TIMER.SyncAngles[client] = client:EyeAngles()
    end

    if SERVER and not client:IsFlagSet(FL_ONGROUND + FL_INWATER) and client:GetMoveType() ~= MOVETYPE_LADDER and TIMER.SyncMonitored[client] and TIMER.SyncAngles[client] then
        local diff = norm(mv:GetAngles().y - TIMER.SyncAngles[client].y)
        local lastkey = client.lastkey or 6969
        local buttons = mv:GetButtons()

        if diff > 0 then
            TIMER.SyncTick[client] = (TIMER.SyncTick[client] or 0) + 1

            if ba(buttons, IN_MOVELEFT) > 0 and not (ba(buttons, IN_MOVERIGHT) > 0) then
                TIMER.SyncA[client] = (TIMER.SyncA[client] or 0) + 1
            end            

            if mv:GetSideSpeed() < 0 then
                TIMER.SyncB[client] = (TIMER.SyncB[client] or 0) + 1
            end

            if lastkey ~= 1 then
                client.strafes = (client.strafes or 0) + 1
                client.strafesjump = (client.strafesjump or 0) + 1
                client.lastkey = 1
            end
        elseif diff < 0 then
            TIMER.SyncTick[client] = (TIMER.SyncTick[client] or 0) + 1

            if (ba(buttons, IN_MOVERIGHT) > 0) and not (ba(buttons, IN_MOVELEFT) > 0) then 
                TIMER.SyncA[client] = (TIMER.SyncA[client] or 0) + 1 
            end

            if mv:GetSideSpeed() > 0 then
                TIMER.SyncB[client] = (TIMER.SyncB[client] or 0) + 1
            end

            if lastkey ~= 0 then
                client.strafes = (client.strafes or 0) + 1
                client.strafesjump = (client.strafesjump or 0) + 1
                client.lastkey = 0
            end
        end

        local currentAngles = mv:GetAngles()
        local newAngles = Angle(currentAngles.p, TIMER.SyncAngles[client].y + diff, currentAngles.r)
        mv:SetAngles(newAngles)

        TIMER.SyncAngles[client] = mv:GetAngles()
    end
end)

if CLIENT then
    -- Initialize the synchronization monitoring for clients
    hook.Add("InitPostEntity", "InitSyncMonitoring", function()
        net.Start("RequestSyncData")
        net.SendToServer()
    end)
    
    net.Receive("SyncData", function()
        local client = LocalPlayer()
        TIMER.SyncAngles[client] = client:EyeAngles()
        TIMER.SyncMonitored[client] = true
        TIMER.SyncTick[client] = 0
        TIMER.SyncA[client] = 0
        TIMER.SyncB[client] = 0
    end)
end

if SERVER then
    util.AddNetworkString("RequestSyncData")
    util.AddNetworkString("SyncData")

    net.Receive("RequestSyncData", function(len, client)
        net.Start("SyncData")
        net.Send(client)
    end)

    hook.Add("PlayerInitialSpawn", "InitSyncMonitoring", function(client)
        TIMER.SyncAngles[client] = client:EyeAngles()
        TIMER.SyncMonitored[client] = true
        TIMER.SyncTick[client] = 0
        TIMER.SyncA[client] = 0
        TIMER.SyncB[client] = 0
    end)

    hook.Add("PlayerDisconnected", "CleanupSyncMonitoring", function(client)
        TIMER.SyncAngles[client] = nil
        TIMER.SyncMonitored[client] = nil
        TIMER.SyncTick[client] = nil
        TIMER.SyncA[client] = nil
        TIMER.SyncB[client] = nil
    end)
end

-- Function to normalize angles
local function normalizeAngle(angle)
    return ((angle + 180) % 360) - 180
end

local function IncrementJumpCounter(ply)
    if not PlayerJumps[ply] then
        PlayerJumps[ply] = 0
    end
    PlayerJumps[ply] = PlayerJumps[ply] + 1

    if SERVER then
        JAC:StartCheck(ply)
        
        local observers = {ply}
        for _, v in pairs(player.GetHumans()) do
            if IsValid(v:GetObserverTarget()) and v:GetObserverTarget() == ply then
                table.insert(observers, v)
            end
        end

        Core:Send(observers, "jump_update", {ply, PlayerJumps[ply]})
    end
end

hook.Add("Move", "PlayerJumpCounter", function(ply, mv)
    if ply:IsOnGround() and mv:KeyDown(IN_JUMP) and not ply.JumpedThisFrame then
        ply.JumpedThisFrame = true
        IncrementJumpCounter(ply)
    elseif not ply:IsOnGround() then
        ply.JumpedThisFrame = false
    end
end)

hook.Add("PlayerSpawn", "ResetJumpCounter", function(ply)
    PlayerJumps[ply] = 0
end)

hook.Add("PlayerDisconnected", "CleanupJumpCounter", function(ply)
    PlayerJumps[ply] = nil
end)

function GM:OnPlayerHitGround(client, isWater)
    if client.Style == 6 or client.Style == 7 then 
        client:SetJumpPower(268.4)
        timer.Simple(0.3, function() 
            if IsValid(client) then 
                client:SetJumpPower(290) 
            end 
        end)
    end
end

local function GravityStyles(client, data)
    if IsValid(client) and not client:IsBot() then 
        if client.Style == _C.Style["Moon Man"] then
            client:SetGravity(0.1)
        elseif client.Style == _C.Style["Low Gravity"] then
            client:SetGravity(0.6)
        else
            --client:SetGravity(1)
        end
    end
end
hook.Add("SetupMove", "GravityStyles", GravityStyles)

local function installView(ply)
    if not IsValid(ply) then return end

    local maxs = ply:Crouching() and _C.Player.HullDuck or _C.Player.HullStand
    local viewOffset = ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset()
    local traceStart = ply:GetPos() + maxs + Vector(0, 0, 1)
    local traceEnd = traceStart + Vector(0, 0, 12 - maxs.z + viewOffset.z)
    local trace = util.TraceLine({start = traceStart, endpos = traceEnd, filter = ply, mask = MASK_PLAYERSOLID})

    if trace.Fraction < 1 then
        local estimatedHeight = traceStart.z + trace.Fraction * (traceEnd.z - traceStart.z) - ply:GetPos().z - 12
        if ply:Crouching() then
            viewOffset.z = math.min(viewOffset.z, estimatedHeight)
            ply:SetViewOffsetDucked(viewOffset)
        else
            viewOffset.z = estimatedHeight
            ply:SetViewOffset(viewOffset)
        end
    else
        ply:SetViewOffset(_C.Player.ViewStand)
        ply:SetViewOffsetDucked(_C.Player.ViewDuck)
    end
end
hook.Add("Move", "InstallView", installView)