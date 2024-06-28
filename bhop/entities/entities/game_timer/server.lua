-- Define zone types with numeric values for better detection
local Zone = {
    MStart = 0,
    MEnd = 1,
    BStart = 2,
    BEnd = 3,
    AC = 4,
    FS = 5,
    NAC = 6,
    BAC = 7,
    LS = 100,
    SOILDAC = 120,
    SURFGRAVTY = 122,
    STEPSIZE = 123,
}

-- Map zone types to corresponding actions
local ZoneActions = {
    [Zone.MEnd] = function(ent) if ent.Tn and not ent.TnF then ent:StopTimer() end end,
    [Zone.BEnd] = function(ent) if ent.Tb and not ent.TbF then ent:BonusStop() end end,
    [Zone.AC] = function(ent) ent:StopAnyTimer() end,
    [Zone.BAC] = function(ent) ent:BonusReset() end,
    [Zone.NAC] = function(ent) ent:ResetTimer() end,
    [Zone.SURFGRAVTY] = function(ent) ent:SetGravity(0.9) end,
    [Zone.STEPSIZE] = function(ent) ent:SetStepSize(6) end,
    [Zone.LS] = function(ent) ent:SetLegitSpeed(self.speed) end,
    [Zone.SOILDAC] = function(ent) ent:SetNotSolid(false) end,
}

function ENT:Initialize()
    -- Calculate the bounding box size
    local boundingBox = (self.max - self.min) * 2
    self.pos = (self.min + self.max) / 2

    -- Set up collision properties
    self:SetSolid(SOLID_BBOX)
    self:PhysicsInitBox(-boundingBox, boundingBox)
    self:SetCollisionBoundsWS(self.min, self.max)
    self:SetTrigger(true)

    -- Set up visibility properties
    self:DrawShadow(false)
    self:SetNotSolid(true)
    self:SetNoDraw(false)

    -- Set up physics properties
    self.Phys = self:GetPhysicsObject()
    if IsValid(self.Phys) then
        self.Phys:Sleep()
        self.Phys:EnableCollisions(false)
    else
        -- Handle case where physics object is not valid
        print("Warning: Physics object is not valid for entity " .. tostring(self))
    end

    -- Set the zone type
    self:SetZoneType(self.zonetype)
end

function ENT:StartTouch(ent)
    if not IsValid(ent) or not ent:IsPlayer() or ent:Team() == TEAM_SPECTATOR then
        return
    end

    local zone = self:GetZoneType()
    local action = ZoneActions[zone]
    if action then action(ent) end

    -- Handle special conditions for MStart and BStart zones
    if zone == Zone.MStart or zone == Zone.BStart then
        if not ent:IsOnGround() and ent:GetVelocity():Length2D() >= 100000 then
            local exemptMaps = {"bhop_ext_kool_06", "bhop_coast"}
            if table.HasValue(exemptMaps, game.GetMap()) then
                return
            end
            ent:SetMoveType(MOVETYPE_WALK)
            ent:SetLocalVelocity(Vector(0, 100, 0))
            ent:SetNWInt("inPractice", false)
            return true
        end
        if ent.Tn and not ent:KeyDown(IN_JUMP) and ent:IsOnGround() then
            ent:ResetTimer()
        end
    end
end

function ENT:Touch(ent)
    if not IsValid(ent) or not ent:IsPlayer() or ent:Team() == TEAM_SPECTATOR then
        return
    end

    local zone = self:GetZoneType()

    -- Handle MStart and BStart zones differently during Touch
    if zone == Zone.MStart then
        if ent.Tn and not ent:KeyDown(IN_JUMP) and ent:IsOnGround() then
            ent:ResetTimer()
        elseif not ent.Tn and ent:KeyDown(IN_JUMP) then
            ent:StartTimer()
        end
    elseif zone == Zone.BStart then
        if ent.Tb and not ent:KeyDown(IN_JUMP) and ent:IsOnGround() then
            ent:BonusReset()
        elseif not ent.Tb and ent:KeyDown(IN_JUMP) then
            ent:BonusStart()
        end
    end
end

function ENT:EndTouch(ent)
    if not IsValid(ent) or not ent:IsPlayer() or ent:Team() == TEAM_SPECTATOR then
        return
    end

    ent:SetGravity(1)
    local zone = self:GetZoneType()

    -- Handle specific actions when leaving zones
    if zone == Zone.FS then
        ent:StopFreestyle()
    elseif zone == Zone.MStart and not ent.Tn then
        ent:StartTimer()
        if game.GetMap() ~= "bhop_alt_paskin" then
            ent:SetStepSize(6)
        end
    elseif zone == Zone.BStart and not ent.Tb then
        ent:BonusStart()
    elseif zone == Zone.STEPSIZE then
        ent:SetStepSize(6)
    end
end