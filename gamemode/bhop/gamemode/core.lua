--[[
	Bunny Hop
	a gamemode by FiBzY
]]--

GM.Name = "Bunny Hop"
GM.DisplayName = "Bunny Hop"
GM.Author = "FiBzY"
GM.Email = "jwolf2110"
GM.Website = "www.steamcommunity.com/id/fibzysending"
GM.TeamBased = false

DeriveGamemode "base"
DEFINE_BASECLASS "gamemode_base"

_C = _C or {}
_C["Version"] = 1.35
_C["PageSize" ] = 7
_C["GameType"] = "bhop"
_C["ServerName"] = "your server name"
_C["Identifier"] = "jcs-" .. _C.GameType
_C["SteamGroup"] = ""
_C["MaterialID"] = "kawaii"

_C["Team"] = { Players = 1, Spectator = TEAM_SPECTATOR }
_C["Style"] = {
    Normal = 1,
    SW = 2,
    HSW = 3,
    ["W-Only"] = 4,
    ["A-Only"] = 5,
    ["D-Only"] = 6,
    SHSW = 7,
    Legit = 8,
    ["Easy Scroll"] = 9,
    Unreal = 10,
    Swift = 11,
    Bonus = 12,
    WTF = 13,
    Segment = 14,
    AutoStrafe = 15,
    ["Low Gravity"] = 16,
    ["Moon Man"] = 17,
    Stamina = 18,
    Backwards = 19
}

_C["Player"] = {
	DefaultModel = "models/player/group01/male_01.mdl",
	DefaultWeapon = "weapon_glock",
	JumpPower = 290,
	ScrollPower = 268.4,
	HullMin = Vector( -16, -16, 0 ),
	HullDuck = Vector( 16, 16, 45- 2 ),
	HullStand = Vector( 16, 16, 62- 2 ),
	ViewDuck = Vector( 0, 0, 47- 2 ),
	ViewStand = Vector( 0, 0, 64 - 2 )
}

_C["Prefixes"] = {
	["Timer"] = Color(0, 132, 255),
	["General"] = Color( 52, 152, 219 ),
	["Admin"] = Color(244, 66, 66),
	["Notification"] = Color( 231, 76, 60 ),
	[_C["ServerName"]] = Color( 46, 204, 113 ),
	["Radio"] = Color( 230, 126, 34 ),
	["VIP"] = Color( 174, 0, 255 )
}

_C["Ranks"] = {
    {"Unranked", Color(255, 255, 255)},
    {"Starter", Color(255, 255, 255)},
    {"Beginner", Color(166, 166, 166)},
    {"Just Bad", Color(175, 238, 238)},
    {"Noob", Color(75, 0, 130)},
    {"Learning", Color(107, 142, 35)},
    {"Novice", Color(65, 105, 225)},
    {"Casual", Color(128, 128, 0)},
    {"Competent", Color(154, 205, 50)},
    {"Expert", Color(240, 230, 140)},
    {"Gamer", Color(0, 255, 255)},
    {"Professional", Color(244, 164, 96)},
    {"Cracked", Color(255, 255, 0)},
    {"Elite", Color(255, 165, 0)},
    {"Intelligent", Color(0, 255, 0)},
    {"Famous", Color(0, 139, 139)},
    {"Jumplet", Color(127, 255, 212)},
    {"Executor", Color(128, 0, 0)},
    {"Incredible", Color(0, 0, 255)},
    {"King", Color(218, 165, 32)},
    {"Mentally Ill", Color(240, 128, 128)},
    {"Egomaniac", Color(255, 0, 255)},
    {"Legendary", Color(255, 105, 180)},
    {"Immortal", Color(255, 69, 0)},
    {"Demoniac", Color(255, 0, 0)},
    {"God", Color(0, 206, 209)}
}

if game.GetMap() == "bhop_aux_a9" then
	_C.Player.JumpPower = math.sqrt( 2 * 800 * 57.0 )
end

include("sh_playerclass.lua" )
include("sh_disablehooks.lua")
include("cl_disablehooks.lua")

local mc, mp = math.Clamp, math.pow
local bn, ba, bo = bit.bnot, bit.band, bit.bor
local sl, ls = string.lower, {}
local lp, ft, ct, gf = LocalPlayer, FrameTime, CurTime, {}

function GM:PlayerNoClip(ply)
	if ply.Style == 14 and CurTime() > 6 then
		chat.AddText( Color(0,255,0), "Timer", color_white, " | Noclip has been ", Color( 255, 0, 0 ),"disabled", color_white, "." )
	end
	if ply.Style == 14 then return end

	local practice = ply:GetNWInt("inPractice", false)
	if not practice then 
		if SERVER then 
			ply:SetNWInt("inPractice", true)
			Core:Send( ply, "Print", { "Timer", Lang:Get( "NoClip" ) } )

				ply:StopAnyTimer()
			return true
		end
	end

	return practice
end

function GM:PlayerUse( ply )
	if not ply:Alive() then return false end
	if ply:Team() == TEAM_SPECTATOR then return false end
	if ply:GetMoveType() != MOVETYPE_WALK then return false end
	
	return true
end

function GM:CreateTeams()
	team.SetUp( _C.Team.Players, "Players", Color( 255, 50, 50, 255 ), false )
	team.SetUp( _C.Team.Spectator, "Spectators", Color( 50, 255, 50, 255 ), true )
	team.SetSpawnPoint( _C.Team.Players, { "info_player_terrorist", "info_player_counterterrorist" } )
end

PlayerJumps = {}

local function ChangePlayerAngle( ply, cmd )
	if ply.Style == _C.Style.Backwards and not ply:IsOnGround() then
        local d = math.AngleDifference(cmd:GetViewAngles().y, ply:GetVelocity():Angle().y)
		if d > -100 and d < 100 then
			cmd:SetForwardMove(0)
			cmd:SetSideMove(0)
		end
	end
end
hook.Add( "StartCommand", "ChangeAngles", ChangePlayerAngle )

local function AutoStrafe( cmd )
	if LocalPlayer().Style == _C.Style.AutoStrafe then
		if cmd:KeyDown( IN_JUMP ) then
			if cmd:GetMouseX() < -1 then
				cmd:SetSideMove(-999999999999999999999)
			elseif cmd:GetMouseX() > -1 then
				cmd:SetSideMove(999999999999999999999)
			end
		end
	end
end
hook.Add( "CreateMove", "ChangeAngAutoStrafeles", AutoStrafe )

local groundTicks = {}
local storedVelocity = {}
local longGround = {}

hook.Add( "Move", "SetMaxSpeed", function( ply, mv )
	mv:SetMaxSpeed(8000000000000000000000)
	mv:SetFinalStepHeight(18)
end )

local lastground = {}
hook.Add("Move","DumbGMOD",function(ply, data)
	if LocalPlayer and ply != LocalPlayer() then return end

	if(ply:IsFlagSet(FL_ONGROUND) && !data:KeyDown(IN_JUMP)) then
		if(!lastground[ply]) then
			data:SetMaxSpeed(0.00000000000000000000000000000000000000000000000000000000000000000000000001)
		end
		lastground[ply] = true
	else
        data:SetMaxSpeed(8000000000000000000000)
		lastground[ply] = false
	end
end)

hook.Add("SetupMove","MySpeed", function( ply, mv, data )
	if ( not ply:IsOnGround() ) then mv:SetMaxClientSpeed( 8000000000000000000000 ) end
	if ( ply:IsOnGround() ) then mv:SetMaxClientSpeed( 250 ) end
end )

local function MovementCMD( cmd )
	local ply = LocalPlayer()
	if( IsValid( ply ) ) then
		if( ply:GetMoveType() != MOVETYPE_NOCLIP ) && ( ply:GetMoveType() != MOVETYPE_OBSERVER ) then
			local up = 0
			local right = 0
			local fw = 0
			local maxspeed = 1000000000
			if( cmd:KeyDown( IN_FORWARD ) ) then
				fw = fw + maxspeed
			end
			if( cmd:KeyDown( IN_BACK ) ) then
				fw = fw - maxspeed
			end
			if( cmd:KeyDown( IN_MOVERIGHT ) ) then
				right = right + maxspeed
			end
			if( cmd:KeyDown( IN_MOVELEFT ) ) then
				right = right - maxspeed
			end

			cmd:SetUpMove( up )
			cmd:SetForwardMove( fw )
			cmd:SetSideMove( right )
		end
	end
end
hook.Add( "CreateMove", "MovementCMD", MovementCMD )

local function FixCrouchLoss(ply, data)
    if not IsValid(ply) or ply:IsBot() then return end

    -- Reset if not on ground or bot
    if not ply:IsOnGround() then
        groundTicks[ply] = 0
        storedVelocity[ply] = nil
        longGround[ply] = false
        return
    end

    groundTicks[ply] = groundTicks[ply] or 0

    -- Handle crouch jump logic only if not in noclip and pressing jump key
    if ply:GetMoveType() ~= MOVETYPE_NOCLIP and data:KeyDown(IN_JUMP) then
        -- Check for double jump
        local pFix = {}
        local jumpForce = 284

        if pFix.DoubleJumpCooldown and pFix.DoubleJumpCooldown > CurTime() + 10 then
            pFix.DoubleJumped = false
        end

        if ply:IsOnGround() and data:KeyReleased(IN_DUCK) then
            local vel = data:GetVelocity()
            vel.z = jumpForce

            -- Apply gravity
            vel.z = vel.z - (ply:GetGravity() * 800 * FrameTime() * 0.5)
            data:SetVelocity(vel)  -- Apply modified velocity with gravity

            pFix.DoubleJumped = true
            pFix.DoubleJumpCooldown = CurTime() + 0.6
        else
            pFix.DoubleJumped = false
        end
    end

    -- Handle ground ticks and stored velocity
    if groundTicks[ply] == 1 then
        storedVelocity[ply] = data:GetVelocity()
    elseif groundTicks[ply] > 1 and data:KeyDown(IN_DUCK) and st ~= _C.Style.Legit and st ~= _C.Style["Easy Scroll"] then
        if ic and groundTicks[ply] < 4 then return end
        local vel = storedVelocity[ply] or data:GetVelocity()
        data:SetVelocity(vel)
    end

    -- Detect long ground time
    if groundTicks[ply] > 1 then
        longGround[ply] = true
    end
end
hook.Add("SetupMove", "FixCrouchLoss", FixCrouchLoss)

local function VectorNormalize(v)
    local length = v:Length()
    if length ~= 0 then
        v:Normalize()
    end
    return length
end

local function VectorCopy(vec)
    return Vector(vec.x, vec.y, vec.z)
end

local function VectorScale(vec, scale)
    return vec * scale
end

local function CustomDotProduct(vec1, vec2)
    return vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z
end

local function AngleVectors(angles, forward, right, up)
    local angle
    local sr, sp, sy, cr, cp, cy

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
        forward.x = cp * cy
        forward.y = cp * sy
        forward.z = -sp
    end

    if right then
        right.x = (-1 * sr * sp * cy) + (-1 * cr * -sy)
        right.y = (-1 * sr * sp * sy) + (-1 * cr * cy)
        right.z = -1 * sr * cp
    end

    if up then
        up.x = (cr * sp * cy) + (-sr * -sy)
        up.y = (cr * sp * sy) + (-sr * cy)
        up.z = cr * cp
    end
end

local function SV_AirAccelerate(velocity, wishveloc, frametime, sv_accelerate)
    local wishspd = VectorNormalize(wishveloc)
    if wishspd > 32.8 then
        wishspd = 32.8
    end

    local currentspeed = CustomDotProduct(velocity, wishveloc)
    local addspeed = wishspd - currentspeed

    if addspeed <= 0 then
        return
    end

    local accelspeed = sv_accelerate * wishspd * frametime
    if accelspeed > addspeed then
        accelspeed = addspeed
    end

	for i = 1, 2 do 
		velocity[i] = velocity[i] + accelspeed * wishveloc[i] 
	end
end

local function SV_AirMove(ply, mv, cmd)
    local velocity = mv:GetVelocity()
    local fmove = mv:GetForwardSpeed()
    local smove = cmd:GetSideMove()
	local onGround = ply:IsOnGround()

	local forward, right, up = Vector(), Vector(), Vector()
    local ang = mv:GetAngles()

    AngleVectors(ang, forward, right, up)

    if mv:KeyDown(IN_MOVERIGHT) then
        smove = smove + 500 
    elseif mv:KeyDown(IN_MOVELEFT) then
        smove = smove - 500
    end

	cmd:SetForwardMove(fmove)
    cmd:SetSideMove(smove)

	local wishvel = Vector(0, 0, 0)
    for i = 1, 3 do
        wishvel[i] = forward[i] * fmove + right[i] * smove
    end

    if ply:GetMoveType() ~= MOVETYPE_WALK then
        wishvel.z = cmd:GetUpMove()
    end

	local wishdir = VectorCopy(wishvel, wishdir)
    local wishspeed = VectorNormalize(wishdir)
    local sv_maxspeed = GetConVar("sv_maxspeed"):GetFloat()

	if wishspeed > sv_maxspeed and wishspeed > 0 then
		wishvel = wishvel * (sv_maxspeed / wishspeed)
		wishspeed = sv_maxspeed
	end	

    SV_AirAccelerate(velocity, wishvel, 0.10, 500)

    mv:SetVelocity(velocity)
end

hook.Add("SetupMove", "CustomPlayerAirMove", function(ply, mv, cmd)
    if not ply:IsValid() or not ply:Alive() then return end
    SV_AirMove(ply, mv, cmd)
end)

function GM:Move(client, data)
	-- Is the client valid?
	if not IsValid(client) then return end 

	-- If this is a local file, and the player isn't themselves don't run this function.
	if lp and (client ~= lp()) then return end 

	-- They're not alive?
	if (not client:Alive()) then return end 

	-- Some values we're going to need to play with 
	local velocity = data:GetVelocity()
	--local velocity = ply:GetInternalVariable("m_vecVelocity") --ply:GetAbsVelocity()
	local velocity2d = velocity:Length2D()
	local style = client.Style
	local mode = client.Style
	local onGround = client:IsOnGround()

	-- Facilitate Start Zone speed cap 
	if client.InStartZone and (not client:GetNWInt('inPractice', false)) and style != 11 then 
		-- Check if they're in a style that has an adjusted speedcap 
		local speedcap = 280
		if (style == 3) or (style == 4) or (style == 5) then 
			speedcap = 450 
		end 

		-- If they're over this speed then make sure their speed is altered 
		if (velocity2d > speedcap) and (not client.Teleporting) then 
			local diff = velocity2d - speedcap
			velocity:Sub(Vector(velocity.x > 0 and diff or -diff, velocity.y > 0 and diff or -diff, 0))
			data:SetVelocity(velocity)
			return false
		end
	end

	-- Stamina (Credits: Gravious)
	local function setDuckSpeed(speed)
		client:SetDuckSpeed(speed)
		client:SetUnDuckSpeed(speed * 0.5)
	end

    -- Adjustments based on specific conditions
    if onGround then
        gf[client] = (gf[client] or 0) + 1
        if gf[client] > 12 and gf[client] < 15 then
            setDuckSpeed(0.4)
        end
    else
        gf[client] = 0
        setDuckSpeed(0)
    end

    local aim = data:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
    local vel, absVel, ang = Vector(data:GetForwardSpeed(), data:GetSideSpeed(), 0), client:GetAbsVelocity(), aim
	local fore, side = ang:Forward(), ang:Right()
    local fmove, smove = data:GetForwardSpeed(), data:GetSideSpeed()

	forward.z, right.z = 0,0
	forward:Normalize()
	right:Normalize()

	local wish = Vector()
	wish.x = fore.x * vel.x + side.x * vel.y
	wish.y = fore.y * vel.x + side.y * vel.y

	local style = client.Style
	if (style == 1) or (style == 8) or (style == 9) or (style == 10) or (style == 11) then 
		smove = data:KeyDown(IN_MOVERIGHT) and smove + 18 or smove
		smove = data:KeyDown(IN_MOVELEFT) and smove - 18 or smove
	elseif (style == 2) then  
		fmove = data:KeyDown(IN_FORWARD) and fmove + 18 or fmove 
		fmove = data:KeyDown(IN_BACK) and fmove - 18 or fmove
	end

	if style == 1 then
		if data:KeyDown( IN_MOVERIGHT ) then
			smove = (smove* 10) + 18
		elseif data:KeyDown( IN_MOVELEFT ) then
			smove = (smove* 10) - 18
		end
	end

	if (smove != 0) then
		if data:KeyDown(IN_MOVERIGHT) then smove = smove + 18 end
		if data:KeyDown(IN_MOVELEFT) then smove = smove - 18 end
	end

	if (fmove != 0) then
		if data:KeyDown(IN_FORWARD) then fmove = fmove + 18 end
		if data:KeyDown(IN_BACK) then fmove = fmove - 18 end
	end

	local style = client.Style
	if style == 10 or style == 11 or style == 13 then
		gain = 49.2
	end

	local wishspd = data:GetMaxSpeed() / data:GetMaxSpeed()
	local maxspeed = data:GetMaxSpeed() / data:GetMaxSpeed()
	if wishspd > maxspeed then
		wish = wish * (maxspeed / maxspeed)
		wishspd = maxspeed / maxspeed
	end

	local wishspd = wish:Length()
	local wishspeed = (wishspd > 30) and gain or wishspd
	
	local wishdir = wish:GetNormalized()
	local current = client:GetAbsVelocity():Dot(wishdir)
	local addspeed = wishspeed - current

	client.ctick = (client.ctick or 0) + 1
	if (client.ctick % 100) == 1 then 
		client.current = velocity2d
	end

	return false
end

--local function norm(i) if i > 180 then i = i - 360 elseif i < -180 then i = i + 360 end return i end 
local mabs, matan, mdeg, NormalizeAngle = math.abs, math.atan, math.deg, math.NormalizeAngle

local function GetPerfectYaw(mv, speed)
	return speed == 0 and 0 or mabs(mdeg(matan(mv / speed)))
end

-- Calculate gain coefficient based on wishspeed and current velocity
local function CalculateGainCoefficient(wishspeed, current)
    if current ~= 0 and current < 32.8 then
        return (wishspeed - math.abs(current)) / wishspeed
    end
    return 0
end

-- Calculate gain coefficient for player
function CalculatePlayerGainCoefficient(ply, wishspeed, current)
    if SERVER and (not ply:IsBot()) then
        local wishspd = (wishspeed > 32.8) and 32.8 or wishspeed
        local gaincoeff = 0.0

        ply.tick = (ply.tick or 0) + 1
        ply.rawgain = ply.rawgain or 0 -- Initialize rawgain if it's nil

        gaincoeff = CalculateGainCoefficient(wishspd, current)
        ply.rawgain = ply.rawgain + gaincoeff
    end
end

local function DisplayStats( ply, data )
	local aa, mv = 120, 32.8
	local aim = data:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()

	local vel, absVel, ang = Vector(data:GetForwardSpeed(), data:GetSideSpeed(), 0), ply:GetAbsVelocity(), aim
	local fore, side = ang:Forward(), ang:Right()

    forward.z, right.z = 0, 0
    forward:Normalize()
    right:Normalize()

    -- Calculate wish velocity based on input directly from the command
    local fmove = data:GetForwardSpeed()
    local smove = data:GetSideSpeed()

    -- Calculate wish velocity components
    local wishvel = forward * fmove + right * smove
    wishvel.z = 0  -- Zero out z part of velocity

	local wishspeed = wishvel:Length()
	if wishspeed > data:GetMaxSpeed() then
		wishvel = wishvel * (data:GetMaxSpeed() / wishspeed)
		wishspeed = data:GetMaxSpeed()
	end

	local vel = ply:GetAbsVelocity()

	if SERVER and ply.totalNormalYaw then
		ply.totalNormalYaw = ply.totalNormalYaw + mabs(NormalizeAngle(aim.yaw - (ply.lastJSSYaw or 0)))
		ply.totalPerfectYaw = ply.totalPerfectYaw + GetPerfectYaw(mv, ply:GetAbsVelocity():Length2D())
		ply.lastJSSYaw = aim.yaw
	end

	-- each tick do this
	distance = Vector()
	trajectory = 0
	local dist = ply:GetAbsVelocity() * engine.TickInterval() * ply:GetLaggedMovementValue()
	distance:Add(dist)
	trajectory = trajectory + dist:Length2D()

	-- each jump
	local efficiency = distance:Length2D() / trajectory

	local vel = ply:GetAbsVelocity()
	local wishspd = wishspeed

    if wishspd > 32.8 then
        wishspd = 32.8
    end

	local wishdir = wishvel:GetNormal()
	local current = vel:Dot(wishdir)
    CalculatePlayerGainCoefficient(ply, wishspeed, vel:Dot(wishvel:GetNormal()))

	if not st == 10 or not st == 12 or not st == 13 then
		local SPEED_CAP = 32.8
		local current = vel:Dot(wishdir)
		local wishspd = (wishspeed > SPEED_CAP) and SPEED_CAP or wishspeed
		if current < SPEED_CAP then
			gaincoeff = (wishspd - math.abs(current)) / wishspd
		end
	end
end
hook.Add("SetupMove","DisplayStats",DisplayStats)

local s1, s2 = _C.Style["Easy Scroll"], _C.Style.Legit
local function AutoHop( ply, data )
	if lp and ply != lp() then return end
	if not ply.Style then ply.Style = Timer.Style end
	
	if ply.Style != s1 and ply.Style != s2 then
		local ButtonData = data:GetButtons()
		if ba( ButtonData, IN_JUMP ) > 0 then
			if ply:WaterLevel() < 2 and ply:GetMoveType() != MOVETYPE_LADDER and not ply:IsOnGround() then
				data:SetButtons( ba( ButtonData, bn( IN_JUMP ) ) )
			end
		end
	end
end
hook.Add( "SetupMove", "AutoHop", AutoHop )

PlayerJumps = {}
local P1, P2 = _C.Player.ScrollPower, _C.Player.JumpPower

local function PlayerGround( ply, bWater )
	if lp and ply != lp() then return end
	if not ply.Style then ply.Style = Timer.Style or 1 end
	
	if ply.Style == s1 or ply.Style == s2 then
		ply:SetJumpPower( P1 or _C.Player.ScrollPower )
		timer.Simple( 0.3, function() if not IsValid( ply ) or not ply.SetJumpPower or not _C.Player.JumpPower then return end ply:SetJumpPower( P2 or _C.Player.JumpPower ) end )
	end
	
	if PlayerJumps[ ply ] then
		PlayerJumps[ ply ] = PlayerJumps[ ply ] + 1
			JAC:StartCheck(ply)
	end

	if (SERVER) then 
		local observers = {ply}

		for k, v in pairs(player.GetHumans()) do 
			if IsValid(v:GetObserverTarget()) and (v:GetObserverTarget() == ply) then 
				table.insert(observers, v)
			end
		end

		Core:Send(observers, "jump_update", {ply, PlayerJumps[ply]})
	end
end
hook.Add( "OnPlayerHitGround", "HitGround", PlayerGround )

local function StripMovements( ply, data )
	if lp and ply != lp() then return end
	
	local st = ply.Style
	if not ply.Freestyle and st and st > 1 and st < 7 and ply:GetMoveType() != MOVETYPE_NOCLIP then
		if ply:OnGround() then
			if st == 6 then
				local vel = data:GetVelocity()
				local ts = ls[ ply ] or 700
				if vel:Length2D() > ts then
					local diff = vel:Length2D() - ts
					vel:Sub( Vector( vel.x > 0 and diff or -diff, vel.y > 0 and diff or -diff, 0 ) )
				end
				
				data:SetVelocity( vel )
				return false
			end
			
			return
		end
		
		if st == 2 or st == 4 then
			data:SetSideSpeed( 0 )
				
			if st == 4 and data:GetForwardSpeed() < 0 then
				data:SetForwardSpeed( 0 )
			end
		elseif st == 5 then
			data:SetForwardSpeed( 0 )
				
			if data:GetSideSpeed() > 0 then
				data:SetSideSpeed( 0 )
			end
		elseif st == 3 and (data:GetForwardSpeed() == 0 or data:GetSideSpeed() == 0) then
			data:SetForwardSpeed( 0 )
			data:SetSideSpeed( 0 )
		end
	end
end
hook.Add( "SetupMove", "StripIllegal", StripMovements )

local function norm(angle)
    angle = angle % 360
    if angle > 180 then
        angle = angle - 360
    elseif angle < -180 then
        angle = angle + 360
    end
    return angle
end

TIMER = {}
TIMER.SyncMonitored = {}
TIMER.SyncAngles = {}
TIMER.SyncB = {}
TIMER.SyncA = {}
TIMER.SyncTick = {}

AutoPred = {}
AutoPred.Enabled = CreateClientConVar( "kawaii_autopred", "1", true, false, "Enables Auto Hop Prediction, Rejoin to take effect" )
local AutoPred = AutoPred.Enabled:GetBool()
SH = GetConVarNumber "kawaii_autopred"

-- Setup move for mainly alternative move methods
function GM:SetupMove(client, data)
	-- Not valid?
	if not IsValid(client) or (client:IsBot()) then return end 

	local buttons = data:GetOldButtons()

	-- Auto Hop
	local style = client.Style
	if (style ~= 6) and (style ~= 7) then 
		if ba(buttons, IN_JUMP) > 0 then
			if client:WaterLevel() < 2 and client:GetMoveType() ~= MOVETYPE_LADDER and client:IsOnGround() then
				data:SetOldButtons(ba(buttons, bn(IN_JUMP)))
			end
		end
	end

	-- Stripping movements that a player shouldn't be able to do with their current style
	if (client:GetMoveType() ~= MOVETYPE_NOCLIP) then 
		-- It's different if we're on the ground, we're not CSS!
		if client:OnGround() then 
			-- Speed cap for legit
			if (style == 6) then 
				local vel = data:GetVelocity()
				local ts = ls[client] or 700

				-- Oh dear
				if vel:Length2D() > ts then
					local diff = vel:Length2D() - ts
					vel:Sub(Vector(vel.x > 0 and diff or -diff, vel.y > 0 and diff or -diff, 0))
				end
				
				data:SetVelocity( vel )
			end
		else
			if (style == 2) or (style == 4) then 
				data:SetSideSpeed(0)

				-- W-Only?
				if (style == 4) and (data:GetForwardSpeed() < 0) then 
					data:SetForwardSpeed(0)
				end 

			-- A-Only 
			elseif (style == 5) then 
				data:SetForwardSpeed(0)
					
				if data:GetSideSpeed() > 0 then
					data:SetSideSpeed(0)
				end

			-- HSW
			elseif style == 3 and (data:GetForwardSpeed() == 0 or data:GetSideSpeed() == 0) then
				data:SetForwardSpeed(0)
				data:SetSideSpeed(0)
			end
		end
	end

	TIMER.SyncAngles[client] = client:EyeAngles()

	-- Sync!!
	if SERVER and not client:IsFlagSet( FL_ONGROUND + FL_INWATER ) and client:GetMoveType() != MOVETYPE_LADDER and TIMER.SyncMonitored[client] and TIMER.SyncAngles[client] then
		-- Normalizes it so we don't have some CRAZY angles lol
		local diff = norm(data:GetAngles().y - TIMER.SyncAngles[client])
		local lastkey = client.lastkey or 6969 

		-- If their camera is angled left / right	
		if (diff > 0) then 
			TIMER.SyncTick[client] = TIMER.SyncTick[client] + 1

			if (ba(buttons, IN_MOVELEFT) > 0) and not (ba(buttons, IN_MOVERIGHT) > 0) then 
				TIMER.SyncA[client] = TIMER.SyncA[client] + 1 
			end 

			if (data:GetSideSpeed() < 0) then 
				TIMER.SyncB[client] = TIMER.SyncB[client] + 1
			end

			if lastkey != 1 then 
				client.strafes = client.strafes + 1 
				client.strafesjump = client.strafesjump + 1
				client.lastkey = 1 
			end
		elseif (diff < 0) then 
			TIMER.SyncTick[client] = TIMER.SyncTick[client] + 1

			if (ba(buttons, IN_MOVERIGHT) > 0) and not (ba(buttons, IN_MOVELEFT) > 0) then 
				TIMER.SyncA[client] = TIMER.SyncA[client] + 1 
			end 

			if (data:GetSideSpeed() > 0) then 
				TIMER.SyncB[client] = TIMER.SyncB[client] + 1
			end

			if lastkey != 0 then 
				client.strafes = client.strafes + 1 
				client.strafesjump = client.strafesjump + 1
				client.lastkey = 0
			end
		end

		-- Update Sync Angles
		TIMER.SyncAngles[client] = data:GetAngles().y
	end
end

-- Whenever a player hits the ground 
local scrollpow, normpow = 268.4, 290
function GM:OnPlayerHitGround(client, isWater)
	local style = client.Style

	-- Jump power stuff, i honestly dk 
	if (style == 6) or (style == 7) then 
		client:SetJumpPower(scrollpow)
		timer.Simple(0.3, function() if not IsValid(client) or not client.SetJumpPower or not normpow then return end client:SetJumpPower(normpow) end)
	end

	if PlayerJumps[client] then
		PlayerJumps[client] = PlayerJumps[client] + 1
			JAC:StartCheck(client)
	end
end

local function GravityStyles(client, data)
	if not IsValid(client) or client:IsBot() then return end 

	local style = client.Style

	local DEFAULT_GRAVITY = 1

	if style == _C.Style["Moon Man"] then
		client:SetGravity(0.1)
	elseif style == _C.Style["Low Gravity"] then
		client:SetGravity(0.6)
	else
		--client:SetGravity(DEFAULT_GRAVITY)
	end
end
hook.Add("SetupMove", "GravityStyles", GravityStyles)

-- View
local ut, mm = util.TraceLine, math.min
local HullDuck = _C["Player"].HullDuck
local HullStand = _C["Player"].HullStand
local ViewDuck = _C["Player"].ViewDuck
local ViewStand = _C["Player"].ViewStand

local function InstallView( ply )
	if not IsValid( ply ) then return end
	local maxs = ply:Crouching() and HullDuck or HullStand
	local v = ply:Crouching() and ViewDuck or ViewStand
	local offset = ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset()

	local fudge = Vector(1, 1, 0)
    maxs = maxs + fudge

	local tracedata = {}
	local s = ply:GetPos()
	s.z = s.z + maxs.z
	tracedata.start = s
	
	local e = Vector( s.x, s.y, s.z )
	e.z = e.z + (12 - maxs.z)
	e.z = e.z + v.z
	tracedata.endpos = e
	tracedata.filter = ply
	tracedata.mask = MASK_PLAYERSOLID
	
	local trace = ut( tracedata )
	if trace.Fraction < 1 then
		local est = s.z + trace.Fraction * (e.z - s.z) - ply:GetPos().z - 12
		if not ply:Crouching() then
			offset.z = est
			ply:SetViewOffset( offset )
		else
			offset.z = mm( offset.z, est )
			ply:SetViewOffsetDucked( offset )
		end
	else
		ply:SetViewOffset( ViewStand )
		ply:SetViewOffsetDucked( ViewDuck )
	end
end
hook.Add( "Move", "InstallView", InstallView )

-- Core

Core = {}

local StyleNames = {}
for name,id in pairs( _C.Style ) do
	StyleNames[ id ] = name
end

function Core:StyleName( nID )
	return StyleNames[ nID ] or "Unknown"
end

function Core:IsValidStyle( nStyle )
	return not not StyleNames[ nStyle ]
end

function Core:GetStyleID( szStyle )
	for s,id in pairs( _C.Style ) do
		if sl( s ) == sl( szStyle ) then
			return id
		end
	end
	
	return 0
end

function Core:Exp( c, n )
	return c * mp( n, 2.9 )
end

function Core:Optimize()
	hook.Remove( "PlayerTick", "TickWidgets" )
	hook.Remove( "PreDrawHalos", "PropertiesHover" )
	hook.Remove("Tick", "Tick" )
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


Core.Util = {}
function Core.Util:GetPlayerJumps( ply )
	return PlayerJumps[ ply ]
end

function Core.Util:SetPlayerJumps( ply, nValue )
	PlayerJumps[ ply ] = nValue
end

function Core.Util:SetPlayerLegit( ply, nValue )
	ls[ ply ] = nValue
end

function Core.Util:StringToTab( szInput )
	local tab = string.Explode( " ", szInput )
	for k,v in pairs( tab ) do
		if tonumber( v ) then
			tab[ k ] = tonumber( v )
		end
	end
	return tab
end

function Core.Util:TabToString( tab )
	for i = 1, #tab do
		if not tab[ i ] then
			tab[ i ] = 0
		end
	end
	return string.Implode( " ", tab )
end

function Core.Util:RandomColor()
	local r = math.random
	return Color( r( 0, 255 ), r( 0, 255 ), r( 0, 255 ) )
end

function Core.Util:VectorToColor( v )
	return Color( v.x, v.y, v.z )
end

function Core.Util:ColorToVector( c )
	return Color( c.r, c.g, c.b )
end

function Core.Util:NoEmpty( tab )
	for k,v in pairs( tab ) do
		if not v or v == "" then
			table.remove( tab, k )
		end
	end
	
	return tab
end

local memoizedResults = {}

local function expensiveFunction(input)
    if memoizedResults[input] then
        return memoizedResults[input]
    end

    -- Simulate an expensive computation
    local result = input ^ 2
    memoizedResults[input] = result
    return result
end

local pool = {}

local function getTable()
    return table.remove(pool) or {}
end

local function releaseTable(t)
    table.clear(t)  -- Requires Lua 5.4 or a compatibility function
    pool[#pool + 1] = t
end

local eventListeners = {}

local function addEventListener(event, listener)
    if not eventListeners[event] then
        eventListeners[event] = {}
    end
    eventListeners[event][listener] = true  -- Use listener as key for quick access
end

local function removeEventListener(event, listener)
    if eventListeners[event] then
        eventListeners[event][listener] = nil  -- Remove directly without iteration
    end
end

local function dispatchEvent(event, ...)
    for _, listener in ipairs(eventListeners[event] or {}) do
        listener(...)
    end
end
