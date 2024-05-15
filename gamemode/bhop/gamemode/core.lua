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
        HullMin = Vector(-16, -16, 0),
        HullDuck = Vector(16, 16, 43),
        HullStand = Vector(16, 16, 60),
        ViewDuck = Vector(0, 0, 45),
        ViewStand = Vector(0, 0, 62)
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

include("sh_playerclass.lua")
include("sh_disablehooks.lua")
include("cl_disablehooks.lua")

local mc, mp = math.Clamp, math.pow
local bn, ba, bo = bit.bnot, bit.band, bit.bor
local sl, ls = string.lower, {}
local lp, ft, ct, gf = LocalPlayer, FrameTime, CurTime, {}

-- Initialize groundTicks and longGround tables
local groundTicks, longGround, storedVelocity = {}, {}, {}

function GM:PlayerNoClip(ply)
    if ply.Style == 14 and CurTime() > 6 then
        chat.AddText(Color(0, 255, 0), "Timer", color_white, " | Noclip has been ", Color(255, 0, 0), "disabled", color_white, ".")
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

local function AutoStrafe(cmd)
    if LocalPlayer().Style == _C.Style.AutoStrafe and cmd:KeyDown(IN_JUMP) then
        cmd:SetSideMove(cmd:GetMouseX() < -1 and -10000 or 10000)
    end
end
hook.Add("CreateMove", "ChangeAngAutoStrafeles", AutoStrafe)

hook.Add("Move", "SetMaxSpeed", function(ply, mv)
    mv:SetMaxSpeed(10000)
    mv:SetFinalStepHeight(18)
end)

hook.Add("SetupMove", "MySpeed", function(ply, mv, data)
    if not ply:IsOnGround() then
        mv:SetMaxClientSpeed(10000)
    else
        mv:SetMaxClientSpeed(250)
    end
end)

local function MovementCMD(cmd)
    local ply = LocalPlayer()
    if IsValid(ply) and ply:GetMoveType() ~= MOVETYPE_NOCLIP and ply:GetMoveType() ~= MOVETYPE_OBSERVER then
        local fmove = cmd:KeyDown(IN_FORWARD) and 10000 or cmd:KeyDown(IN_BACK) and -10000 or 0
        local smove = cmd:KeyDown(IN_MOVERIGHT) and 10000 or cmd:KeyDown(IN_MOVELEFT) and -10000 or 0
        cmd:SetForwardMove(fmove)
        cmd:SetSideMove(smove)
    end
end
hook.Add("CreateMove", "MovementCMD", MovementCMD)

local function FixCrouchLoss(ply, data)
    if not IsValid(ply) or ply:IsBot() or not ply:IsOnGround() then
        groundTicks[ply], storedVelocity[ply], longGround[ply] = 0, nil, false
        return
    end

    groundTicks[ply] = groundTicks[ply] or 0
    if ply:GetMoveType() ~= MOVETYPE_NOCLIP and data:KeyDown(IN_JUMP) then
        local jumpForce = 284
        if not ply.pFix then ply.pFix = {} end
        if ply.pFix.DoubleJumpCooldown and ply.pFix.DoubleJumpCooldown > CurTime() + 10 then
            ply.pFix.DoubleJumped = false
        end
        if ply:IsOnGround() and data:KeyReleased(IN_DUCK) then
            local vel = data:GetVelocity()
            vel.z = jumpForce - (ply:GetGravity() * 800 * FrameTime() * 0.5)
            data:SetVelocity(vel)
            ply.pFix.DoubleJumped = true
            ply.pFix.DoubleJumpCooldown = CurTime() + 0.6
        else
            ply.pFix.DoubleJumped = false
        end
    end

    if groundTicks[ply] == 1 then
        storedVelocity[ply] = data:GetVelocity()
    elseif groundTicks[ply] > 1 and data:KeyDown(IN_DUCK) and not ply:IsOnGround() then
        local vel = storedVelocity[ply] or data:GetVelocity()
        data:SetVelocity(vel)
    end

    if groundTicks[ply] > 1 then
        longGround[ply] = true
    end
end
hook.Add("SetupMove", "FixCrouchLoss", FixCrouchLoss)

local mabs, matan, mdeg, NormalizeAngle = math.abs, math.atan, math.deg, math.NormalizeAngle

local function norm(i)
    if i > 180 then
        i = i - 360
    elseif i < -180 then
        i = i + 360
    end
    return i
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

local function SV_AirAccelerate(velocity, wishvel, frametime, sv_accelerate)
    local wishspd = VectorNormalize(wishvel)
    if wishspd > 32.8 then wishspd = 32.8 end

    local currentspeed = CustomDotProduct(velocity, wishvel)
    local addspeed = wishspd - currentspeed
    if addspeed <= 0 then return end

    local accelspeed = sv_accelerate * wishspd * frametime
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

    AngleVectors(ang, forward, right, up)

    if mv:KeyDown(IN_MOVERIGHT) then smove = smove + 500 end
    if mv:KeyDown(IN_MOVELEFT) then smove = smove - 500 end

    cmd:SetForwardMove(fmove)
    cmd:SetSideMove(smove)

    local wishvel = forward * fmove + right * smove
    if ply:GetMoveType() ~= MOVETYPE_WALK then wishvel.z = cmd:GetUpMove() end

    local wishdir = VectorCopy(wishvel)
    local wishspeed = VectorNormalize(wishdir)
    local sv_maxspeed = GetConVar("sv_maxspeed"):GetFloat()

    if wishspeed > sv_maxspeed then
        wishvel = wishvel * (sv_maxspeed / wishspeed)
        wishspeed = sv_maxspeed
    end

    SV_AirAccelerate(velocity, wishvel, 0.10, 500)
    mv:SetVelocity(velocity)
end

hook.Add("SetupMove", "CustomPlayerAirMove", function(ply, mv, cmd)
    if ply:IsValid() and ply:Alive() then SV_AirMove(ply, mv, cmd) end
end)

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

    local function setDuckSpeed(speed)
        client:SetDuckSpeed(speed)
        client:SetUnDuckSpeed(speed * 0.5)
    end

    if onGround then
        gf[client] = (gf[client] or 0) + 1
        if gf[client] > 12 and gf[client] < 15 then setDuckSpeed(0.4) end
    else
        gf[client] = 0
        setDuckSpeed(0)
    end

    local aim = data:GetMoveAngles()
    local forward, right = aim:Forward(), aim:Right()
    forward.z, right.z = 0, 0
    forward:Normalize()
    right:Normalize()

    local wish = forward * data:GetForwardSpeed() + right * data:GetSideSpeed()
    wish.z = 0

    local wishspd = data:GetMaxSpeed() / data:GetMaxSpeed()
    local maxspeed = data:GetMaxSpeed() / data:GetMaxSpeed()
    if wishspd > maxspeed then
        wish = wish * (maxspeed / wishspd)
        wishspd = maxspeed / maxspeed
    end

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

AutoPred = {
    Enabled = CreateClientConVar("kawaii_autopred", "1", true, false, "Enables Auto Hop Prediction, Rejoin to take effect")
}
local AutoPred = AutoPred.Enabled:GetBool()
SH = GetConVarNumber("kawaii_autopred")

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

    TIMER.SyncAngles[client] = client:EyeAngles()

    if SERVER and not client:IsFlagSet(FL_ONGROUND + FL_INWATER) and client:GetMoveType() ~= MOVETYPE_LADDER and TIMER.SyncMonitored[client] and TIMER.SyncAngles[client] then
        local diff = norm(data:GetAngles().y - TIMER.SyncAngles[client])
        local lastkey = client.lastkey or 6969 

        if diff > 0 then 
            TIMER.SyncTick[client] = TIMER.SyncTick[client] + 1

            if ba(buttons, IN_MOVELEFT) > 0 and not ba(buttons, IN_MOVERIGHT) > 0 then 
                TIMER.SyncA[client] = TIMER.SyncA[client] + 1 
            end 

            if data:GetSideSpeed() < 0 then 
                TIMER.SyncB[client] = TIMER.SyncB[client] + 1
            end

            if lastkey ~= 1 then 
                client.strafes = client.strafes + 1 
                client.strafesjump = client.strafesjump + 1
                client.lastkey = 1 
            end
        elseif diff < 0 then 
            TIMER.SyncTick[client] = TIMER.SyncTick[client] + 1

            if ba(buttons, IN_MOVERIGHT) > 0 and not ba(buttons, IN_MOVELEFT) > 0 then 
                TIMER.SyncA[client] = TIMER.SyncA[client] + 1 
            end 

            if data:GetSideSpeed() > 0 then 
                TIMER.SyncB[client] = TIMER.SyncB[client] + 1
            end

            if lastkey ~= 0 then 
                client.strafes = client.strafes + 1 
                client.strafesjump = client.strafesjump + 1
                client.lastkey = 0
            end
        end

        TIMER.SyncAngles[client] = data:GetAngles().y
    end
end

function GM:OnPlayerHitGround(client, isWater)
    if client.Style == 6 or client.Style == 7 then 
        client:SetJumpPower(268.4)
        timer.Simple(0.3, function() if IsValid(client) then client:SetJumpPower(290) end end)
    end

    if PlayerJumps[client] then
        PlayerJumps[client] = PlayerJumps[client] + 1
        JAC:StartCheck(client)
    end
end

local function GravityStyles(client, data)
    if IsValid(client) and not client:IsBot() then 
        if client.Style == _C.Style["Moon Man"] then
            client:SetGravity(0.1)
        elseif client.Style == _C.Style["Low Gravity"] then
            client:SetGravity(0.6)
        else
            client:SetGravity(1)
        end
    end
end
hook.Add("SetupMove", "GravityStyles", GravityStyles)

local ut, mm = util.TraceLine, math.min
local HullDuck, HullStand = _C.Player.HullDuck, _C.Player.HullStand
local ViewDuck, ViewStand = _C.Player.ViewDuck, _C.Player.ViewStand

local function InstallView(ply)
    if not IsValid(ply) then return end

    local maxs = ply:Crouching() and HullDuck or HullStand
    local v = ply:Crouching() and ViewDuck or ViewStand
    local offset = ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset()

    local fudge = Vector(1, 1, 0)
    maxs = maxs + fudge

    local tracedata = {}
    local s = ply:GetPos()
    s.z = s.z + maxs.z
    tracedata.start = s

    local e = Vector(s.x, s.y, s.z)
    e.z = e.z + (12 - maxs.z) + v.z
    tracedata.endpos = e
    tracedata.filter = ply
    tracedata.mask = MASK_PLAYERSOLID

    local trace = ut(tracedata)
    if trace.Fraction < 1 then
        local est = s.z + trace.Fraction * (e.z - s.z) - ply:GetPos().z - 12
        if not ply:Crouching() then
            offset.z = est
            ply:SetViewOffset(offset)
        else
            offset.z = mm(offset.z, est)
            ply:SetViewOffsetDucked(offset)
        end
    else
        ply:SetViewOffset(ViewStand)
        ply:SetViewOffsetDucked(ViewDuck)
    end
end
hook.Add("Move", "InstallView", InstallView)

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

function Core:Optimize()
    hook.Remove("PlayerTick", "TickWidgets")
    hook.Remove("PreDrawHalos", "PropertiesHover")
    hook.Remove("Tick", "Tick")
    hook.Remove("Move", "Move")
    hook.Remove("CreateMove", "CreateMove")
    hook.Remove("SetupMove", "SetupMove")
    hook.Remove("FinishMove", "FinishMove")
    hook.Remove("StartMove", "StartMove")
    hook.Remove("PlayerButtonDown", "PlayerButtonDown")
    hook.Remove("PlayerButtonUp", "PlayerButtonUp")
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
end

Core.Util = {
    GetPlayerJumps = function(ply) return PlayerJumps[ply] end,
    SetPlayerJumps = function(ply, nValue) PlayerJumps[ply] = nValue end,
    SetPlayerLegit = function(ply, nValue) ls[ply] = nValue end,
    StringToTab = function(szInput)
        local tab = string.Explode(" ", szInput)
        for k, v in pairs(tab) do
            if tonumber(v) then tab[k] = tonumber(v) end
        end
        return tab
    end,
    TabToString = function(tab)
        for i = 1, #tab do
            if not tab[i] then tab[i] = 0 end
        end
        return string.Implode(" ", tab)
    end,
    RandomColor = function()
        local r = math.random
        return Color(r(0, 255), r(0, 255), r(0, 255))
    end,
    VectorToColor = function(v) return Color(v.x, v.y, v.z) end,
    ColorToVector = function(c) return Color(c.r, c.g, c.b) end,
    NoEmpty = function(tab)
        for k, v in pairs(tab) do
            if not v or v == "" then table.remove(tab, k) end
        end
        return tab
    end
}

local memoizedResults = {}

local function expensiveFunction(input)
    if memoizedResults[input] then return memoizedResults[input] end
    local result = input ^ 2
    memoizedResults[input] = result
    return result
end

local pool = {}

local function getTable() return table.remove(pool) or {} end

local function releaseTable(t)
    table.clear(t)
    pool[#pool + 1] = t
end

local eventListeners = {}

local function addEventListener(event, listener)
    if not eventListeners[event] then eventListeners[event] = {} end
    eventListeners[event][listener] = true
end

local function removeEventListener(event, listener)
    if eventListeners[event] then eventListeners[event][listener] = nil end
end

local function dispatchEvent(event, ...)
    for _, listener in ipairs(eventListeners[event] or {}) do
        listener(...)
    end
end
