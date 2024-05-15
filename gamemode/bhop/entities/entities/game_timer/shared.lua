ENT.Type = "anim"
ENT.Base = "base_anim"
AccessorFunc(ENT, "p_Size", "Size")

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "ID")
    self:NetworkVar("Int", 1, "Style")
    self:NetworkVar("Int", 2, "Vel")
    self:NetworkVar("Int", 3, "ZoneType") -- Changed the index from 0 to 3
    for i = 1, 9 do
        self:NetworkVar("Vector", i - 1, "Neighbor" .. i)
    end
end

if SERVER then
    include "server.lua"
elseif CLIENT then
    include "client.lua"
end