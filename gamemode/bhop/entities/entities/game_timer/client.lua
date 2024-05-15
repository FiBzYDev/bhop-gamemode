local Zone = {MStart = 0, MEnd = 1, BStart = 2, BEnd = 3, FS = 5, AC = 4, BAC = 7, NAC = 6, HELPER = 130}
local DrawArea = {
    [Zone.MStart] = Settings:GetValue("StartZone"),
    [Zone.MEnd] = Settings:GetValue("EndZone"),
    [Zone.BStart] = Settings:GetValue("BonusStart"),
    [Zone.BEnd] = Settings:GetValue("BonusEnd"),
    [Zone.FS] = Color(0, 80, 255),
    [Zone.AC] = Color(153, 0, 153, 100),
    [Zone.BAC] = Color(0, 0, 153, 100),
    [Zone.NAC] = Color(140, 140, 140, 100),
    [Zone.HELPER] = Color(255, 255, 0, 100)
}

local DrawMaterial = Material("sprites/jscfixtimer")

function ENT:Initialize()
end

function ENT:Think()
    local Min, Max = self:GetCollisionBounds()
    self:SetRenderBounds(Min, Max)
end

ZONES = {}
ZONES.Enabled = CreateClientConVar("kawaii_showzones", "1", true, false, "Show Timer Zones")

FLATZONE = {}
FLATZONE.Enabled = CreateClientConVar("kawaii_showflatzones", "0", true, false, "Show Timer Flat Zones")

COOLZONES = {}
COOLZONES.Enabled = CreateClientConVar("kawaii_rainbowzones", "0", true, false, "Show Rainbow Zones")

THICKZONES = {}
THICKZONES.Enabled = CreateClientConVar("kawaii_thickzones", "0", true, false, "Show Thick Zones")

function ENT:Draw()
    local showZones = ZONES.Enabled:GetBool()
    if not showZones then return end

    DrawArea[Zone.MStart] = Settings:GetValue("StartZone")
    DrawArea[Zone.MEnd] = Settings:GetValue("EndZone")
    DrawArea[Zone.BStart] = Settings:GetValue("BonusStart")
    DrawArea[Zone.BEnd] = Settings:GetValue("BonusEnd")

    local zoneType = self:GetZoneType()
    if not DrawArea[zoneType] then return end

    local rm, rma = self:GetCollisionBounds()
    local Min = self:GetPos() + rm
    local Max = self:GetPos() + rma
    local Col, Width = DrawArea[zoneType], 1
    local C1, C2, C3, C4, C5, C6, C7, C8 = Vector(Min.x, Min.y, Min.z), Vector(Min.x, Max.y, Min.z),
                                           Vector(Max.x, Max.y, Min.z), Vector(Max.x, Min.y, Min.z),
                                           Vector(Min.x, Min.y, Max.z), Vector(Min.x, Max.y, Max.z),
                                           Vector(Max.x, Max.y, Max.z), Vector(Max.x, Min.y, Max.z)

    if table.HasValue({Zone.AC, Zone.BAC, Zone.NAC}, zoneType) and GetConVar("kawaii_anticheats"):GetInt() == 0 then
        return
    end

    local w = (Max.y - Min.y) / 1
    local l = (Max.x - Min.x) / 1
    local h = (Max.z - Min.z) / 1
    local zw = 1

    render.SetMaterial(DrawMaterial)
    render.DrawBeam(C1, C2, zw, 0, 1 * w, Col)
    render.DrawBeam(C2, C3, zw, 0, 1 * l, Col)
    render.DrawBeam(C3, C4, zw, 0, 1 * w, Col)
    render.DrawBeam(C4, C1, zw, 0, 1 * l, Col)

    if FLATZONE.Enabled:GetBool() == 1 then
        return
    end

    render.DrawBeam(C5, C6, zw, 0, 1 * w, Col)
    render.DrawBeam(C6, C7, zw, 0, 1 * l, Col)
    render.DrawBeam(C7, C8, zw, 0, 1 * w, Col)
    render.DrawBeam(C8, C5, zw, 0, 1 * l, Col)
    render.DrawBeam(C1, C5, zw, 0, 1 * h, Col)
    render.DrawBeam(C2, C6, zw, 0, 1 * h, Col)
    render.DrawBeam(C3, C7, zw, 0, 1 * h, Col)
    render.DrawBeam(C4, C8, zw, 0, 1 * h, Col)

    if COOLZONES.Enabled:GetBool() == 1 then
        render.DrawBeam(C1, C2, zw, 0, 1 * w, Col2)
        render.DrawBeam(C2, C3, zw, 0, 1 * l, Col2)
        render.DrawBeam(C3, C4, zw, 0, 1 * w, Col2)
        render.DrawBeam(C4, C1, zw, 0, 1 * l, Col2)

        if FLATZONE.Enabled:GetBool() == 1 then
            return
        end

        render.DrawBeam(C5, C6, zw, 0, 1 * w, Col2)
        render.DrawBeam(C6, C7, zw, 0, 1 * l, Col2)
        render.DrawBeam(C7, C8, zw, 0, 1 * w, Col2)
        render.DrawBeam(C8, C5, zw, 0, 1 * l, Col2)
        render.DrawBeam(C1, C5, zw, 0, 1 * h, Col2)
        render.DrawBeam(C2, C6, zw, 0, 1 * h, Col2)
        render.DrawBeam(C3, C7, zw, 0, 1 * h, Col2)
        render.DrawBeam(C4, C8, zw, 0, 1 * h, Col2)
    end
end
