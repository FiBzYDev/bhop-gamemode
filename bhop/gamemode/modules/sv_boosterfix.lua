-- Booster fix 

local function HandleBaseVelocity(self, data, caller)
    local var1, var2, var3 = string.match(data, "basevelocity (%d+) (%d+) (%d+)")
    if not var1 or not var2 or not var3 then return end

    local vel = self:GetVelocity()
    local pos = self:GetPos()
    local callerPos = caller:GetPos()
    local height = select(2, caller:GetCollisionBounds())

    self:SetPos(Vector(pos.x, pos.y, callerPos.z + height))
    self:SetVelocity(Vector(0, 0, var3 - vel.z + 278))
end

local function HandleGravity(self, data, caller)
    local grav = string.match(data, "gravity (%-?%d+)")
    if not grav or tonumber(grav) >= 0 then return end

    local callerPos = caller:GetPos()
    local pos = self:GetPos()
    local vel = self:GetVelocity()
    local height = select(2, caller:GetCollisionBounds())

    if math.abs(height) > 3 then
        callerPos.z = pos.z + (pos.z - callerPos.z)
    else
        callerPos.z = callerPos.z + height
    end

    self:SetPos(Vector(pos.x, pos.y, callerPos.z))
    self:SetVelocity(Vector(0, 0, -vel.z + 270))
end

local function AcceptInput(self, input, activator, caller, data)
    if not data or not self.boosterfix then return end

    if string.match(data, "basevelocity") then
        HandleBaseVelocity(self, data, caller)
        return true
    elseif string.match(data, "gravity") then
        HandleGravity(self, data, caller)
        return true
    end
end
hook.Add("AcceptInput", "boosterfix.acceptinput", AcceptInput)

local function ToggleBoosterFixCommand(ply)
    ply.boosterfix = not ply.boosterfix
    local status = ply.boosterfix and "enabled" or "disabled"
    Core:Send(ply, "Print", {"Timer", "Booster modifications have now been " .. status .. "."})
end

local function AddCommand()
    Command:Register({"boosterfix", "fixboosters", "booster"}, function(ply, arguments)
        ToggleBoosterFixCommand(ply)
    end)
end
hook.Add("Initialize", "boosterfix.addcommand", AddCommand)