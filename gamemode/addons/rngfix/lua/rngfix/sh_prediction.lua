local GravityPredictionNetwork = "sm_gravity_prediction"

if SERVER then
    util.AddNetworkString(GravityPredictionNetwork)

    local g_CVar_sv_gravity = 800
    local g_flClientGravity = {}
    local g_flClientActualGravity = {}
    local g_bLadder = {}

    local function OnGameFrame()
        local flSVGravity = 800

        for _, ply in ipairs(player.GetHumans()) do
            if not IsValid(ply) or not ply:Alive() then
                g_flClientGravity[ply] = 1
                g_bLadder[ply] = false
            elseif ply:GetMoveType() == MOVETYPE_LADDER and not g_bLadder[ply] then
                g_bLadder[ply] = true
            elseif not g_bLadder[ply] then
                local flClientGravity = ply:GetGravity()
                if flClientGravity ~= 0 then
                    g_flClientGravity[ply] = flClientGravity

                    local flClientActualGravity = flClientGravity * flSVGravity

                    if flClientActualGravity ~= g_flClientActualGravity[ply] then
                        g_flClientActualGravity[ply] = flClientActualGravity
                    end
                end
            end
        end
    end
    hook.Add("Think", "sm_gravpredfix_OnGameFrame", OnGameFrame)
	if CLIENT then
    local gravityMultiplier = 1

    local function GravityController(ply, move)
        if not IsValid(ply) then return end
        move:SetGravity(gravityMultiplier)
    end
    hook.Add("SetupMove", "sm_gravpredfix_GravityController", GravityController)

    local function ReceiveGrav()
        gravityMultiplier = net.ReadFloat()
    end
    net.Receive(GravityPredictionNetwork, ReceiveGrav)
end

local function OnPostGameFrame(ply)
	if ply:IsBot() then return end

	if IsValid(ply) and g_bLadder[ply] then
		RestoreGravity(ply)
	end
end
hook.Add("PlayerPostThink", "sm_gravpredfix_OnPostGameFrame", OnPostGameFrame)
elseif CLIENT then
	local gravityMultiplier = 1

local function GravityController(ply)
		if !IsValid(pl) then return end
		if pl != ply then return end

		ply:SetGravity(gravityMultiplier)
	end
hook.Add("SetupMove", "sm_gravpredfix_GravityController", GravityController)

local function ReceiveGrav()
		gravityMultiplier = net.ReadFloat()
	end
	net.Receive(GravityPredictionNetwork, ReceiveGrav)
end

local function HandleJumpEdgeCollision(ply, mv)
    -- Check if the player is jumping and colliding with an edge
    if not ply:IsOnGround() and mv:KeyPressed(IN_JUMP) then
        -- Get the player's eye position and forward direction
        local eyePos = ply:EyePos()
        local forwardDir = ply:EyeAngles():Forward()

        -- Perform a trace to check for collisions in front of the player
        local trace = util.TraceLine({
            start = eyePos,
            endpos = eyePos + forwardDir * 30,
            filter = ply
        })

        -- Check if the trace hit an edge or obstacle
        if trace.Hit then
            -- Modify the movement velocity to prevent stopping
            mv:SetVelocity(mv:GetVelocity() + forwardDir * ply:GetMaxSpeed())
        end
    end
end

hook.Add("Move", "HandleJumpEdgeCollisionHook", function(ply, mv)
    HandleJumpEdgeCollision(ply, mv)
end)

local lastGroundEnt = {}
local lastTickPredicted = {}
local lastBase = {}
local tick = {}
local btns = {}
local obtns = {}
local vels  = {}
local lastTeleport = {}
local teleportedSeq = {}
local lastCollision = {}
local lastLand = {}

NON_JUMP_VELOCITY = 140
MIN_STANDABLE_ZNRM = 0.7	
LAND_HEIGHT = 2.0 

local unducked = Vector(16, 16, 62)
local ducked = Vector(16, 16, 45)
local duckdelta = (unducked.z / ducked.z) / 2

--[[function ClipVelocity(vel, nrm, out)
    -- Ensure that out is initialized
    out = out or Vector()
    
    -- Calculate backoff using dot product
    local backoff = vel:Dot(nrm)
    
    -- Loop through each component of the vectors
    for i = 1, 3 do
        -- Calculate change for each component
        local change = nrm[i] * backoff
        
        -- Calculate the clipped velocity for each component
        out[i] = vel[i] - change
    end
    
    return out -- The adjust step only matters with overbounce which doesn't apply to walkable surfaces.
end--]]

--[[function ClipVelocity(vel, nrm, out)
    out = out or Vector()
    local backoff = vel:Dot(nrm)
    local blocked = 0
    
    if nrm.z > 0 then
        blocked = blocked or 0x01
    elseif nrm.z == 0 then
        blocked = blocked or 0x02
    end
    
    for i = 1, 3 do
        local change = nrm[i] * backoff
        out[i] = vel[i] - change
    end
    
    local adjust = out:Dot(nrm)
    if adjust < 0.0 then
        out = out - (nrm * adjust)
    end
    
    return out
end--]]

STOP_EPSILON = 0.1

local function ClipVelocity(vel, nrm, out)
    out = out or Vector() -- Initialize out as a Vector if it's nil
    local backoff = vel:Dot(nrm) * 1
    local blocked = 0
    
    if nrm.z > 0 then
        blocked = blocked or 1 -- floor
    elseif nrm.z == 0 then
        blocked = blocked or 2 -- step
    end
    
    for i = 1, 3 do
        local change = nrm[i] * backoff
        out[i] = vel[i] - change
        if out[i] > -STOP_EPSILON and out[i] < STOP_EPSILON then
            out[i] = 0
        end
    end
    
    return out, blocked
end

local function PreventCollision(ply, origin, collision, veltick, mv)
	local no = collision - veltick 
	no.z = no.z + 0.1 

	lastTickPredicted[ply] = 0
	mv:SetOrigin(no)
end

local function CanJump(ply)
    -- Check if the player is crouching
    local isCrouching = ply:Crouching()

    -- Check if the player is on the ground
    local onGround = ply:IsOnGround()

    -- Check if the IN_JUMP key is pressed
    local jumpPressed = ply:KeyDown(IN_JUMP)
    
    -- Return false if the player is crouching and on the ground but jump key is not pressed
    if not isCrouching and onGround and not jumpPressed then
        return false
    end

    return true
end

local function Duck(ply, origin, mins, max)
	local ducking = ply:Crouching()
	local nextducking = ducking 

	if not ducking and bit.band(btns[ply], IN_DUCK) != 0 then 
		origin.z = origin.z + duckdelta 
		nextducking = true 
	elseif bit.band(btns[ply], IN_DUCK) == 0 and ducking then 
		origin.z = origin.z - duckdelta 

		local tr = util.TraceHull{
			start = origin,
			endpos = origin,
			mins = Vector(-16.0, -16.0, 0.0),
			maxs = unducked,
			mask = MASK_PLAYERSOLID_BRUSHONLY,
			filter = ply
		}

		if tr.Hit then 
			origin.z = origin.z + duckdelta 
		else 
			nextducking = false 
		end 
	end 

	mins = Vector(-16.0, -16.0, 0.0) 
	max = nextducking and ducked or unducked 
	return origin, mins, max 
end 

local function StartGravity(ply, velocity)
	local localGravity = ply:GetGravity()
	if localGravity == 0.0 then localGravity = 1.0 end

	local baseVelocity = ply:GetBaseVelocity()
    velocity.z = velocity.z + (baseVelocity.z - localGravity * 600 * 0.5) * engine.TickInterval() / 0.1

	return velocity
end

local function FinishGravity(ply, velocity)
	local localGravity = ply:GetGravity()
	if localGravity == 0.0 then localGravity = 1.0 end

	velocity.z = velocity.z - localGravity * 600 * 0.5 * FrameTime() * engine.TickInterval() / 0.1

	return velocity
end

local AA = 500
local MV = 32.8
local function PredictVelocity(ply, mv, p)
	local a = mv:GetMoveAngles()
	local fw, r = a:Forward(), a:Right()
	local fmove, smove = mv:GetForwardSpeed(), mv:GetSideSpeed()
	local velocity =  mv:GetVelocity()

	fw.z, r.z = 0,0
	fw:Normalize()
	r:Normalize()

	local wish = fw * fmove + r * smove 
	wish.z = 0 

	local wishspd = wish:Length()
	local maxspeed = mv:GetMaxSpeed()
	if wishspd > maxspeed then
		wish = wish * (maxspeed / wishspd)
		wishspd = maxspeed
	end

    local wishspeed = math.Clamp(wishspd, 0, MV) * engine.TickInterval() / 0.1
	local wishdir = wish:GetNormal()
	local current = velocity:Dot( wishdir )
	local addspeed = wishspeed - current

	if addspeed <= 0 then 
		return velocity 
	end 

	local acc = AA * FrameTime() * wishspd 
	if acc > addspeed then 
		acc = addspeed 
	end 

	return velocity + (wishdir * acc)
end 

math_floor = math.floor
util_TraceHull = util.TraceHull

local function DoPreTickChecks(ply, mv, cmd)
    if not (ply:Alive() and ply:GetMoveType() == MOVETYPE_WALK and ply:WaterLevel() == 0) then
        return false
    end

    lastGroundEnt[ply] = ply:GetGroundEntity()

    if not CanJump(ply) and lastGroundEnt[ply] ~= NULL then
        return false
    end

    btns[ply] = mv:GetButtons()
    obtns[ply] = mv:GetOldButtons()
    lastTickPredicted[ply] = tick[ply]

    local vel = PredictVelocity(ply, mv, false)
    vel = StartGravity(ply, vel)

    local base = bit.band(ply:GetFlags(), FL_BASEVELOCITY) ~= 0 and ply:GetBaseVelocity() or Vector(0, 0, 0)
    vel:Add(base)

    lastBase[ply] = base
    vels[ply] = vel

    local shouldDoDownhillFixInstead = false -- Initialize the variable

    local origin = mv:GetOrigin()
    local vMins = ply:OBBMins()
    local vMaxs = ply:OBBMaxs()
    local vEndPos = origin * 1
    vEndPos, vMins, vMaxs = Duck(ply, vEndPos, vMins, vMaxs)
    vEndPos = vEndPos + (vel * FrameTime())

    local tr = util_TraceHull{
        start = origin,
        endpos = vEndPos,
        mins = vMins,
        maxs = vMaxs,
        mask = MASK_PLAYERSOLID_BRUSHONLY,
        filter = ply
    }

    local nrm = tr.HitNormal 

    if tr.Hit and not tr.HitNonWorld then
        lastCollision[ply] = tick[ply]
        if ply:IsOnGround() then return false end 

        if nrm.z < MIN_STANDABLE_ZNRM then return end
        if vel.z > NON_JUMP_VELOCITY then return end 

        local collision = tr.HitPos
        local veltick = vel * FrameTime()

        if (nrm.z < 1.0 and nrm.x * vel.x + nrm.y * vel.y < 0.0) then 
            local newvel = ClipVelocity(vel, nrm, out)

            if (newvel.x * newvel.x + newvel.y * newvel.y > vel.x * vel.x + vel.y * vel.y) then 
                shouldDoDownhillFixInstead = true;
            end 

            if not shouldDoDownhillFixInstead then 
                PreventCollision(ply, origin, collision, veltick, mv)
                return
            end
        end 

        local edgebug = true 

        if edgebug then 
            local fraction_left = 1 - tr.Fraction 
            local tickEnd = Vector()

            if nrm.z == 1 then 
                tickEnd.x = collision.x + veltick.x * fraction_left
                tickEnd.y = collision.y + veltick.y * fraction_left
                tickEnd.z = collision.z
            else 
                local velocity2 = ClipVelocity(vel, nrm, out)

                if velocity2.z > NON_JUMP_VELOCITY then 
                    return 
                else 
                    velocity2 = velocity2 * FrameTime() * fraction_left
                    tickEnd = collision + velocity2
                end 
            end

            local tickEndBelow = Vector()
            tickEndBelow.x = tickEnd.x
            tickEndBelow.y = tickEnd.y
            tickEndBelow.z = tickEnd.z - LAND_HEIGHT

            local tr_edge = util_TraceHull{
                start = tickEnd,
                endpos = tickEndBelow,
                mins = vMins,
                maxs = vMaxs,
                mask = MASK_PLAYERSOLID,
                filter = ply
            }

            if tr_edge.Hit then
                if tr_edge.HitNormal.z >= MIN_STANDABLE_ZNRM then return end
                if TracePlayerBBoxForGround(tickEnd, tickEndBelow, vMins, vMaxs, ply) then return end
            end

            PreventCollision(ply, origin, collision, veltick, mv)
        end
    end
end

local function OnPlayerHitGround(ply, inWater, float, speed)
    -- Check if the player is in water or floating
    if inWater or float then
        return
    end

    -- Check if the player's velocity is below a certain threshold
    local minVelocityThreshold = 10 -- Adjust this value as needed
    if ply:GetVelocity():Length() < minVelocityThreshold then
        return
    end

    -- Record the last ground hit for the player
    lastLand[ply] = tick[ply]
end
hook.Add("Move", "RNGFIXGround", OnPlayerHitGround)

local function DoInclineCollisonFixes(ply, mv, nrm)
    if not ply:IsOnGround() or not CanJump(ply) or not vels[ply] or tick[ply] ~= lastTickPredicted[ply] then
        return
    end

    local velocity = vels[ply]
    local dot = nrm.x * velocity.x + nrm.x * velocity.z
    local newVelocity = ClipVelocity(velocity, nrm, out)
    local downhill = newVelocity:Length2DSqr() > velocity:Length2DSqr()

    if downhill then
        newVelocity.z = 0
        mv:SetVelocity(newVelocity)
    end
end

local function OnPlayerTeleported(activator)
    local velsActivator = vels[activator]
    if not IsValid(activator) or not IsValid(velsActivator) then
        -- Handle invalid activator or vels[activator]
        return
    end

    local activatorVel2D = activator:GetVelocity():Length2D()
    local velsActivatorLen2D = velsActivator:Length2D()
    
    if velsActivatorLen2D == 0 then
        -- Handle division by zero
        return
    end

    local isWorthIt = (activatorVel2D / velsActivatorLen2D) < 0.4
    if not isWorthIt then
        return
    end

    if lastTeleport[activator] == tick[activator] - 1 then
        teleportedSeq[activator] = true
    end

    lastTeleport[activator] = tick[activator]
end

local function CheckBoundingBoxIntersection(box1, box2)
    return box1.mins.x <= box2.maxs.x and
           box1.maxs.x >= box2.mins.x and
           box1.mins.y <= box2.maxs.y and
           box1.maxs.y >= box2.mins.y and
           box1.mins.z <= box2.maxs.z and
           box1.maxs.z >= box2.mins.z
end

local function CheckTouchingTrigger(ply)
    -- Get the player's position and bounding box dimensions
    local pos = ply:GetPos()
    local mins, maxs = ply:GetCollisionBounds()

    -- Create a box around the player's position to represent the player's collision bounds
    local box = {
        mins = pos + mins,
        maxs = pos + maxs
    }

    -- Iterate through all entities in the game
    for _, ent in pairs(ents.FindInBox(box.mins, box.maxs)) do
        -- Check if the entity is a trigger based on its class or name
        if IsValid(ent) and (ent:GetClass() == "trigger_multiple") then
            -- Check if the player's bounding box is intersecting with the trigger's bounding box
            local entMins, entMaxs = ent:GetCollisionBounds()
            local entBox = {
                mins = ent:GetPos() + entMins,
                maxs = ent:GetPos() + entMaxs
            }
            if CheckBoundingBoxIntersection(box, entBox) then
                return true  -- Player is touching the trigger
            end
        end
    end

    return false
end

local function DoTelehopFix(ply, mv)
    -- Check if player is touching a trigger
    local touchingTrigger = CheckTouchingTrigger(ply)
    if touchingTrigger then
        OnPlayerTeleported(ply)
    end

	if not ply:Alive() then return false end
	if not ply:GetMoveType() == MOVETYPE_WALK then return false end
	if not ply:WaterLevel() == 0 then return false end

	if (tick[ply] != lastTickPredicted[ply]) then return end
	if lastTeleport[ply] ~= tick[ply] then return end
	if teleportedSeq[ply] then return end
	if not (lastCollision[ply] == tick[ply] or lastLand[ply] == tick[ply]) then return end
	local vel = vels[ply]
	if vel then
		if (ply:IsOnGround()) then 
			vel.z = 0
		end
		mv:SetVelocity(vel)
	end 
end 

local function CheckTick(e)
	return tick[e]
end 

hook.Add("SetupMove", "RNGFix", function(ply, mv, cmd)
	if not tick[ply] then 
		tick[ply] = 0
	end 

	DoTelehopFix(ply,mv)

	tick[ply] = tick[ply] + 1
	teleportedSeq[ply] = false 

	DoPreTickChecks(ply, mv, cmd)
end )

local function PlayerPostThink(ply, mv)
    if not ply:Alive() or ply:GetMoveType() ~= MOVETYPE_WALK or ply:WaterLevel() ~= 0 then
        return
    end

    local origin = mv:GetOrigin()
    local vMins, vMaxs = ply:OBBMins(), ply:OBBMaxs()
    local vEndPos = origin - Vector(0, 0, vMaxs.z)

    local traceData = {
        start = origin,
        endpos = vEndPos,
        mins = vMins,
        maxs = vMaxs,
        mask = MASK_PLAYERSOLID,
        filter = ply
    }

    local tr = util.TraceHull(traceData)

    if tr.Hit and tr.HitNormal.z > MIN_STANDABLE_ZNRM and tr.HitNormal.z < 1 then
        DoInclineCollisonFixes(ply, mv, tr.HitNormal)
    end

    if SERVER then
        DoTelehopFix(ply, mv)
    end
end
hook.Add("FinishMove", "RNGFixPost", PlayerPostThink)

function TracePlayerBBoxForGround(origin, originBelow, mins, maxs, ply)
    local traceData = {
        start = origin,
        endpos = originBelow,
        mask = MASK_PLAYERSOLID_BRUSHONLY
    }

    local function traceWithBounds(mins, maxs)
        traceData.mins, traceData.maxs = mins, maxs
        local tr = util.TraceHull(traceData)
        return tr.Hit and tr.HitNormal.z >= MIN_STANDABLE_ZNRM
    end

    local origMins, origMaxs = Vector(mins), Vector(maxs)

    -- Test with bottom left back corner clipped
    if traceWithBounds(origMins, Vector(math.min(origMaxs.x, 0.0), math.min(origMaxs.y, 0.0), origMaxs.z)) then
        return true
    end

    -- Test with top right front corner clipped
    if traceWithBounds(Vector(math.max(origMins.x, 0.0), math.max(origMins.y, 0.0), origMins.z), origMaxs) then
        return true
    end

    -- Test with bottom right back corner clipped
    if traceWithBounds(Vector(origMins.x, math.max(origMins.y, 0.0), origMins.z), Vector(math.min(origMaxs.x, 0.0), origMaxs.y, origMaxs.z)) then
        return true
    end

    -- Test with top left front corner clipped
    if traceWithBounds(Vector(math.max(origMins.x, 0.0), origMins.y, origMins.z), Vector(origMaxs.x, math.min(origMaxs.y, 0.0), origMaxs.z)) then
        return true
    end

    return false
end