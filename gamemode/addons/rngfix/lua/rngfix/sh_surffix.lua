if CLIENT then 
	CreateClientConVar("kawaii_debug_pebbles", 0, false, false, "Debug pebble analysis to console", 0, 1)
	
	local function PebbleDebugEnabled()
		return GetConVar("kawaii_debug_pebbles"):GetBool()
	end
	
	local function PebbleDebugOutput(strOutput)
		LocalPlayer():ChatPrint(strOutput)
	end
	
	local function ResetPlayerData(objPlayer)
		objPlayer.lastLength = 0
		objPlayer.lastVelocity = Vector(0, 0, 0)
		objPlayer.lastMoveAngles = Angle(0, 0, 0)
		objPlayer.lastPct = 0
		objPlayer.traceData = {}
	end
	
	local function DetectPebble(objPlayer, mvData, cmd)
		if not IsValid(objPlayer) then return end
	
		if not objPlayer.lastLength then
			ResetPlayerData(objPlayer)
		end
	
		if mvData:KeyDown(IN_BACK) or math.Round(mvData:GetVelocity():LengthSqr(), 2) == 0.25 then
			ResetPlayerData(objPlayer)
			return
		end
	
		if objPlayer:OnGround() or objPlayer:WaterLevel() > 0 then 
			ResetPlayerData(objPlayer)
			return 
		end
	
		if not objPlayer.shouldPebbleBust then
			ResetPlayerData(objPlayer)
			return 
		end
	
		if objPlayer.lastLength > mvData:GetVelocity():LengthSqr() then
			local raw = objPlayer.lastLength - mvData:GetVelocity():LengthSqr()
			local pct = (raw / objPlayer.lastLength) * 100
	
			if pct == 100 then -- This doesn't seem to be a natural pebble, or a pebble at all
				ResetPlayerData(objPlayer)
				return 
			end
	
			if pct > 96 and pct ~= objPlayer.lastPct then
				objPlayer.traceData = util.TraceLine(
					{
						start = objPlayer:GetPos(),
						endpos = objPlayer:GetPos() + Vector(0, 0, 100),
						filter = objPlayer,
						mask = CONTENTS_PLAYERCLIP + MASK_SOLID_BRUSHONLY
					}
				)
	
				if objPlayer.traceData.HitWorld then
					ResetPlayerData(objPlayer)
					return
				end
	
				if mvData:GetVelocity():LengthSqr() == 20.25 and objPlayer.lastLength ~= mvData:GetVelocity():LengthSqr() then
					mvData:SetOrigin(mvData:GetOrigin() + Vector(0, 0, 2))
					mvData:SetMoveAngles(objPlayer.lastMoveAngles)
					mvData:SetVelocity(objPlayer.lastVelocity)
					objPlayer.lastLength = 20.25
					objPlayer.lastPct = 1
					if PebbleDebugEnabled() then
						PebbleDebugOutput(Format("%s (CLIENT) Quick Pebble detected! %% Speed loss: %f. New Speed would have been: %f", os.date(), pct, objPlayer.lastLength))
					end
					return
				end	
	
				objPlayer.traceData = util.TraceHull(
					{
						start = objPlayer:GetPos(),
						endpos = objPlayer:GetPos() + (objPlayer:GetForward() * 60),
						mins = objPlayer:OBBMins(),
						maxs = objPlayer:OBBMaxs(),
						filter = objPlayer,
						mask = CONTENTS_PLAYERCLIP + MASK_SOLID_BRUSHONLY
					}
				)
	
				if objPlayer.traceData.HitWorld then
					ResetPlayerData(objPlayer)
					return
				end
	
				objPlayer.traceData = util.TraceHull(
					{
						start = objPlayer:GetPos(),
						endpos = objPlayer:GetPos(),
						mins = objPlayer:OBBMins() + Vector(-10, -10, -10),
						maxs = objPlayer:OBBMaxs() + Vector(10, 10, 10),
						filter = objPlayer,
						mask = CONTENTS_PLAYERCLIP
					}
				)
	
				if objPlayer.traceData.HitWorld then
					ResetPlayerData(objPlayer)
					return
				end
	
				objPlayer.traceData = {}
	
				if PebbleDebugEnabled() then
					PebbleDebugOutput(Format("%s (CLIENT) Pebble detected! %% Speed loss: %f. New Speed would have been: %f", os.date(), pct, mvData:GetVelocity():LengthSqr()))
				end
				if objPlayer.lastLength < 40 then 
					if PebbleDebugEnabled() then 
						PebbleDebugOutput("(CLIENT) Last speed too low, not correcting") 
					end 
					return 
				end
				if PebbleDebugEnabled() then
					PebbleDebugOutput(Format("%s (CLIENT) Applying last speed: %f (PEBBLE).", os.date(), objPlayer.lastLength))
				end
				mvData:SetOrigin(mvData:GetOrigin() + Vector(0, 0, 2))
				mvData:SetMoveAngles(objPlayer.lastMoveAngles)
				mvData:SetVelocity(objPlayer.lastVelocity)
				objPlayer.lastPct = pct
				return
			end
		end
	
		objPlayer.lastLength = mvData:GetVelocity():LengthSqr()
		objPlayer.lastVelocity = mvData:GetVelocity()
		objPlayer.lastMoveAngles = mvData:GetMoveAngles()
	end
	
	hook.Add("SetupMove", "DetectPebble", DetectPebble)
end

local Boosters = {}

RNGFix = {
    UpdateMessage = "SurfFix has been updated 2024",
    Hooks = {
        SetupData = "PlayerSpawn",
        CheckOnGround = "SetupMove",
        Move = "Move",
        SurfFix = "FinishMove",
        TelehopFix = "FinishMove",
        PredictVelocityClip = "Move",
        CheckNoClip = "PlayerNoClip",
        AnalyseBoosters = "EntityKeyValue",
        PrepareBoosters = "InitPostEntity",
        DisableBoosters = "AcceptInput",
        PrepareTPs = "InitPostEntity",
        PlayerTeleported = "AcceptInput",
    },
    TickRate = 1 / engine.TickInterval(),
    Boosters = {},
}

function RNGFix:Initialize()
    local Hooks = self.Hooks
    setmetatable(self, {__index = _G})
    for name, func in pairs(self) do
        if type(func) == "function" and Hooks[name] then
            hook.Add(Hooks[name], "RNGFix_" .. name, function(...) return func(self, ...) end)
        end
    end
    
    local Player = FindMetaTable("Player")
    PrepareBoosters()
    PrepareTPs()
    function Player:UseRNGFix()
        return self.RNGFix and self.RNGFix.Enabled and (not self.Spectating) and (not self.RNGFix.NoClip) and (not self:IsBot())
    end

    for _, ply in pairs(player.GetAll()) do
        self:SetupData(ply)
    end

    if SERVER then
        concommand.Add("update_rngfix", function(ply)
            if not IsValid(ply) then
                include("autorun/server/sh_surffix.lua")
            end
        end)
    end
end

function RNGFix:SetupData(ply)
    if not IsValid(ply) then return end
    
    local enabled = ply.RNGFix and ply.RNGFix.Enabled
    ply.RNGFix = {
        Enabled = enabled == nil or enabled,
        PreviousVL = {Vector()},
        PredictedVL = false,
        PreviousPos = Vector(),
        WasOnGround = true,
        Landing = false,
        Landed = false,
        Jumped = false,
        GroundTrace = {},
        InBooster = false,
        OnRamp = false,
        WasOnRamp = false,
        LastOnRamp = 0,
        NoClip = false,
        Teleported = false,
        NextGravity = false,
        NextVelocity = false,
    }
end

function RNGFix:CheckNoClip(ply, noclip)
    if ply and ply:IsValid() and ply.Practice then
        ply.RNGFix.NoClip = noclip
    end
end

function RNGFix:CheckOnGround(ply, mv, cmd)
    local pFix = ply.RNGFix or {}
    local vl = mv:GetVelocity()
    pFix.Landed = ply:IsOnGround() and not pFix.WasOnGround
    pFix.Jumped = pFix.WasOnGround and not ply:IsOnGround()
    pFix.WasOnGround = ply:IsOnGround()
    pFix.WasOnRamp = pFix.OnRamp

    if pFix.Landed then
        local endpos = mv:GetOrigin() - Vector(0, 0, 100)
        pFix.GroundTrace = util.TraceHull {
            start = mv:GetOrigin(),
            endpos = endpos,
            mins = ply:OBBMins(),
            maxs = ply:OBBMaxs(),
            mask = MASK_PLAYERSOLID_BRUSHONLY,
        }
        pFix.Landing = false
        if pFix.OnRamp then pFix.OnRamp = false end
    elseif pFix.Landing then
        pFix.Landed = true
        pFix.Landing = false
    else
        local endpos = mv:GetOrigin() - Vector(0, 0, 100)
        local ground = util.TraceHull {
            start = mv:GetOrigin(),
            endpos = endpos,
            mins = ply:OBBMins(),
            maxs = ply:OBBMaxs(),
            mask = MASK_PLAYERSOLID_BRUSHONLY,
        }
        if (vl.z < 0) and ground.Hit and (ground.HitNormal.z >= 0.7) then
        elseif ground.Hit and (ground.HitNormal.z < 0.7) then
            pFix.OnRamp = true
            pFix.GroundTrace = ground
        elseif not ground.Hit then
            pFix.OnRamp = false
        end
    end

    self:PredictVelocityClip(ply, mv, cmd)
end

function RNGFix:PredictVelocityClip(ply, mv, cmd) 
    if not ply:UseRNGFix() then return end
    local pFix = ply.RNGFix
    if not pFix.OnRamp then return end

    local a = mv:GetMoveAngles()
    local fw, r = a:Forward(), a:Right()
    local fmove, smove = mv:GetForwardSpeed(), mv:GetSideSpeed()
    local velocity =  mv:GetVelocity()

    fw.z, r.z = 0, 0
    fw:Normalize()
    r:Normalize()

    local wish = fw * fmove + r * smove 
    wish.z = 0 

    local wishspd = wish:Length()
    local wishspeed = 32.8
    local wishdir = wish:GetNormal()
    local current = velocity:Dot(wishdir)
    local addspeed = wishspeed - current

    if addspeed <= 0 then 
        return velocity 
    end 

    local acc = 500 * FrameTime() * wishspd * 1
    if acc > addspeed then 
        acc = addspeed 
    end 
    local vel = velocity + (wishdir * acc)

    local hitNormal = pFix.GroundTrace.HitNormal
    vel = Vector(vel.x, vel.y, vel.z)
    vel.z = vel.z - (ply:GetGravity() * 800 * FrameTime() * 0.5)

    local slowDown = vel:Dot(hitNormal)
    vel.x = vel.x - hitNormal.x * slowDown
    vel.y = vel.y - hitNormal.y * slowDown
    vel.z = vel.z - hitNormal.z * slowDown

    local adjust = vel:Dot(hitNormal)
    if adjust < 0 then
        vel = vel - (hitNormal * adjust)
    end

    pFix.PredictedVL = vel
end

function RNGFix:Move(ply, mv)
    if not ply:UseRNGFix() then return end
    local pFix = ply.RNGFix or {}
    self:BoosterFix(ply, mv)

    pFix.PreviousVL = {mv:GetVelocity()}
end

function RNGFix:SurfFix(ply, mv)
    if game.GetMap() == "bhop_timecrunch" then return end
    if not ply:UseRNGFix() then return end
    local pFix = ply.RNGFix or {}
    if not pFix.PredictedVL then return end

    local vel = mv:GetVelocity()
    local pVel = pFix.PredictedVL

    local loss = pVel:Length() - vel:Length()
    loss = math.floor(loss)

    pFix.PredictedVL = false
    if loss < 100 then return end

    local pos = mv:GetOrigin() + (pVel * FrameTime())
    local tr = util.TraceHull {
        start = pos,
        endpos = pos,
        mins = ply:OBBMins(),
        maxs = ply:OBBMaxs(),
        mask = MASK_ALL,
        filter = player.GetAll(),
        ignoreworld = true,
    }

    if not tr.Hit then
        mv:SetOrigin(pos)
        mv:SetVelocity(pVel)
    end
end

function RNGFix:TelehopFix(ply, mv)
    if mv:GetVelocity():Length2D() >= 300 then
        if not ply:GetMoveType() == MOVETYPE_WALK or ply:IsOnGround() then return end
    end

    local pFix = ply.RNGFix or {}

    if not pFix.Teleported then return end

    local pVL = pFix.PreviousVL[10]
    local cVL = mv:GetVelocity()
    if mv:GetVelocity():Length2D() >= 300 then
        if pVL and (pVL:Length2DSqr() > cVL:Length2DSqr()) then
            mv:SetVelocity(pVL)
        end
    end

    local pVL = pFix.PreviousVL[10]
    local cVL = mv:GetVelocity()
    if game.GetMap() == "bhop_growfonder" then
        if pVL and (pVL:Length2DSqr() > cVL:Length2DSqr()) then
            mv:SetVelocity(pVL)
        end
    end

    pFix.Teleported = false
end