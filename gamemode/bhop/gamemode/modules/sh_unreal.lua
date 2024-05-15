
local BoostTimer = {} -- Ensure BoostTimer is defined and accessible

IN_ATTACK2 = IN_ATTACK2 -- Define IN_ATTACK2 locally
Styles = { Unreal = 10, Style10 = 13 }

-- Define your BoostCooldown and BoostMultiplier tables
BoostCooldown = { 4, 5, 4.5, 8 }
BoostMultiplier = { 1.8, 2.4, 3.0, 3.0 }

function DoUnrealBoost(ply, nForce)
    -- Check if the player is not in practice mode and boost timer is expired
    if not ply.Practice and ply.BoostTimer and SysTime() < ply.BoostTimer then return end
    
    -- Check if the player has TAS and trigger UnrealBoost
    if ply.TAS and ply.TAS.UnrealBoost(ply) then return end

    -- Set the base cooldown to be non-existent
    local nCooldown, nMultiplier, nType = 0, 0, 1
    local vel = ply:GetVelocity()

    -- Check which boost type we need
    if ply:KeyDown(IN_FORWARD) and not ply:KeyDown(IN_BACK) and not ply:KeyDown(IN_MOVELEFT) and not ply:KeyDown(IN_MOVERIGHT) then
        nType = 2
    elseif ply:KeyDown(IN_JUMP) and not ply:KeyDown(IN_FORWARD) and not ply:KeyDown(IN_BACK) and not ply:KeyDown(IN_MOVELEFT) and not ply:KeyDown(IN_MOVERIGHT) then
        nType = 3
    elseif ply:KeyDown(IN_BACK) and not ply:KeyDown(IN_FORWARD) and not ply:KeyDown(IN_MOVELEFT) and not ply:KeyDown(IN_MOVERIGHT) then
        nType = 4
    else
        nType = 1
    end

    -- See if we're forcing
    if nForce then
        nType = nForce
    end

    -- By default, for all different key combinations, we will simply amplify velocity
    if nType == 1 then
        nCooldown = BoostCooldown[1]
        nMultiplier = BoostMultiplier[1]

        ply:SetVelocity(vel * Vector(nMultiplier, nMultiplier, nMultiplier * 1.5) - vel)
    elseif nType == 2 then
        nCooldown = BoostCooldown[2]
        nMultiplier = BoostMultiplier[2]

        ply:SetVelocity(vel * Vector(nMultiplier, nMultiplier, 1) - vel)
    elseif nType == 3 then
        nCooldown = BoostCooldown[3]
        nMultiplier = BoostMultiplier[3]

        if vel.z < 0 then
            nMultiplier = -0.5 * nMultiplier
        end

        ply:SetVelocity(vel * Vector(1, 1, nMultiplier) - vel)
    elseif nType == 4 then
        nCooldown = BoostCooldown[4]
        nMultiplier = BoostMultiplier[4]

        if vel.z > 0 then
            nMultiplier = -nMultiplier
        end

        ply:SetVelocity(vel * Vector(1, 1, nMultiplier) - vel)
    end

    if nCooldown ~= 0 then
        ply.BoostTimer = SysTime() + nCooldown -- Set the boost timer
        if ply.TAS then ply.TAS.UnrealBoost(ply, nCooldown) end
    end
end

-- Function to handle key press for Unreal Boost
function UnrealBoostKey(ply, key)
    if key == IN_ATTACK2 and ply.Style == Styles.Unreal then
        DoUnrealBoost(ply)
    end
end

-- Hook key press event
hook.Add("KeyPress", "UnrealKeyPress", UnrealBoostKey)

-- Add boost functionality for Style 10 (WTF)
function BoostStyle10(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end -- Check if ply is a valid player entity
    if ply:KeyDown(IN_ATTACK2) and ply.Style == Styles.Style10 then
        if CurTime() - (ply.lastUnrealBoost or 0) > 0.1 then
            local mult = 2.2
            ply:SetVelocity(ply:GetVelocity() * Vector(mult, mult, mult * 50))
            ply.lastUnrealBoost = CurTime()
        end
    end
end

-- Hook this function to be called every tick
hook.Add("Think", "BoostStyle10", function()
    for _, ply in ipairs(player.GetAll()) do -- Loop through all players
        BoostStyle10(ply) -- Call BoostStyle10 function for each player
    end
end)