local SSJ = {}
util.AddNetworkString "kawaii.secret"
util.AddNetworkString "train_update"

local movementSpeed = 32.8
local interval = (1 / engine.TickInterval()) / 10
local deg, atan = math.deg, math.atan
local active = {}

local p = FindMetaTable "Player"
function p:InitStrafeTrainer(client)
    local data = self:GetPData("strafetrainer", 0)
    if tobool(data) then
        self:SetNWBool("strafetrainer", true)
    end
end

function StrafeTrainer_CMD(client)
    local curr = tobool(client:GetPData("strafetrainer", 0))
    client:SetPData("strafetrainer", curr and 0 or 1)
    client:SetNWBool("strafetrainer", not curr)
end

local function NormalizeAngle(x)
    if x > 180 then
        x = x - 360
    elseif x <= -180 then
        x = x + 360
    end
    return x
end

local function GetPerfectAngle(vel)
    return deg(atan(movementSpeed / vel))
end

local function NetworkList(ply)
    local watchers = {}

    for _, p in pairs(player.GetHumans()) do
        if not p.Spectating then continue end

        local ob = p:GetObserverTarget()

        if IsValid(ob) and ob == ply then
            watchers[#watchers + 1] = p
        end
    end
    watchers[#watchers + 1] = ply
    return watchers
end

local last = {}
local tick = {}
local percentages = {}
local value = {}

local function SetupMove(client, data, cmd)
    if not client:Alive() then return end
    if client:GetMoveType() == MOVETYPE_NOCLIP then return end

    if not percentages[client] then
        percentages[client] = {}
        last[client] = 0
        tick[client] = 0
        value[client] = 0
    end
    local diff = NormalizeAngle(last[client] - data:GetAngles().y)
    local perfect = GetPerfectAngle(client:GetVelocity():Length2D())
    local perc = math.abs(diff) / perfect
    local t = tick[client]
    if (t > interval) then
        local avg = 0
        for x = 0, interval do
            avg = avg + percentages[client][x]
            percentages[client][x] = 0
        end
        avg = avg / interval
        value[client] = avg
        tick[client] = 0
        net.Start "train_update"
            net.WriteFloat(avg)
        net.Send(NetworkList(client))
    else
        percentages[client][t] = perc
        tick[client] = t + 1
    end
    last[client] = data:GetAngles().y
end
hook.Add("SetupMove", "sm_strafetrainer", SetupMove)

local function LoadPlayer(pl)
    timer.Simple(1, function()
        if not IsValid(pl) then return end
        local ssj = pl:GetPData("SSJ_Settings", false)
        pl.SSJ = {}
        pl.SSJ["Jumps"] = {}
        pl.SSJ["Settings"] = ssj and util.JSONToTable(ssj) or {false, true, false, false, true, false}
        pl.rawgain = 0
        pl.tick = 0
        pl.totalNormalYaw = 0
        pl.totalPerfectYaw = 0
        pl.lastJSSYaw = 0
        pl.lastSpeed = 0
    end)
end
hook.Add("PlayerInitialSpawn", "SSJ.LoadPlayer", LoadPlayer)

local function AddCommand()
    Command:Register({"ssj", "sj", "ssjmenu"}, function(pl)
        SSJ:OpenMenuForPlayer(pl, pl.SSJ["Settings"])
    end)
end
hook.Add("Initialize", "SSJ.AddCommand", AddCommand)

local function OnPlayerHitGround(pl)
    if pl.SSJ then
        if not pl.SSJ["Jumps"][1] then
            pl.SSJ["Jumps"][1] = {0, 0, 0}
        end
        table.insert(pl.SSJ["Jumps"], SSJ:RetrieveData(pl))
        SSJ:Display(pl)
        pl.rawgain = 0
        pl.tick = 0
        pl.totalNormalYaw = 0
        pl.totalPerfectYaw = 0
        pl.SSJ.trajectory = 0
        pl.SSJ.distance = Vector()
        pl.SSJ.efficiency = 0
    end
end

local function KeyPress(pl, key)
    if key == IN_JUMP then
        if not pl.SSJ then
            print("Warning: pl.SSJ is nil")
        end
        pl.SSJ["InSpace"] = true
    end
    if key == IN_JUMP and pl:Alive() then
        pl.tick = 0
        pl.rawgain = 0
        pl.maxgain = 0
        pl.totalNormalYaw = 0
        pl.totalPerfectYaw = 0
        pl.SSJ["Jumps"] = {}
        pl.SSJ["Jumps"][1] = SSJ:RetrieveData(pl)

        if PlayerJumps and PlayerJumps[pl] and PlayerJumps[pl] <= 1 then
            local observers = {pl}

            for k, v in pairs(player.GetHumans()) do
                if IsValid(v:GetObserverTarget()) and v:GetObserverTarget() == pl then
                    table.insert(observers, v)
                end
            end
            Core:Send(observers, "jump_update", {pl, 0})
            PlayerJumps[pl] = 0
        end
        SSJ:Display(pl)
    end
end
hook.Add("KeyPress", "SSJ.KeyPress", KeyPress)

local function KeyRelease(pl, key)
    if key == IN_JUMP and pl.SSJ["InSpace"] then
        pl.SSJ["InSpace"] = false
    end
end
hook.Add("KeyRelease", "SSJ.KeyRelease", KeyRelease)

local function OnPlayerHitGround(pl, mv)
    if pl.SSJ and pl:IsOnGround() then
        if not pl.SSJ["Jumps"][1] then
            pl.SSJ["Jumps"][1] = {0, 0, 0}
        end
        table.insert(pl.SSJ["Jumps"], SSJ:RetrieveData(pl))
        SSJ:Display(pl)
        pl.rawgain = 0
        pl.tick = 0
        pl.totalNormalYaw = 0
        pl.totalPerfectYaw = 0
        pl.SSJ.trajectory = 0
        pl.SSJ.distance = Vector()
        pl.SSJ.efficiency = 0
    end
end
hook.Add("Move", "SSJ.OnPlayerHitGround", OnPlayerHitGround)

function SSJ:OpenMenuForPlayer(pl, data)
    UI:SendToClient(pl, "ssj", data)
end

function SSJ:RetrieveData(pl)
    local velocity = math.Round(pl:GetVelocity():Length2D())
    local pos = pl:GetPos().z
    local lastSpeed = pl.lastSpeed or 0
    pl.lastSpeed = velocity
    return {velocity, pos, lastSpeed}
end

local function InterfaceResponse(pl, data)
    local k = data[1]
    pl.SSJ["Settings"][k] = not pl.SSJ["Settings"][k]
    pl:SetPData("SSJ_Settings", util.TableToJSON(pl.SSJ["Settings"]))
    SSJ:OpenMenuForPlayer(pl, k)
end
UI:AddListener("ssj", InterfaceResponse)

local function GetJSSSuffix(jss)
    return jss >= 101 and "✓" or (jss <= 99 and "▲" or "▲")
end

function SSJ:Display(pl)
    if not pl.SSJ then return end
    if not pl.SSJ["InSpace"] then return end
    if pl:IsBot() then return end

    local currentJump = pl.SSJ["Jumps"][#pl.SSJ["Jumps"]]
    local currentVel = currentJump[1]
    local currentHeight = currentJump[2]
    local lastSpeed = currentJump[3]

    local gain = pl.rawgain / pl.tick * 100
    gain = math.floor(gain * 100 + 0.5) / 100

    local jss = 0
    if pl.totalPerfectYaw ~= 0 then
        jss = (pl.totalNormalYaw / pl.totalPerfectYaw) * 100
    end

    local color = Color(255, 0, 0, 255)
    if gain > 0 then
        if gain >= 80 then
            color = _C["Prefixes"].Timer
        elseif gain > 70 and gain <= 80 then
            color = Color(39, 255, 0, 255)
        elseif gain > 60 and gain <= 70 then
            color = Color(255, 191, 0, 255)
        end
    end

    if gain == math.huge or gain ~= gain then
        gain = 0
    end

    if gain > (pl.maxgain or 0) then
        pl.maxgain = gain
    end

    local clients = {pl}
    for k, v in pairs(player.GetAll()) do
        if not v.Spectating or not v.SSJ["Settings"][5] then continue end
        local target = v:GetObserverTarget()
        if IsValid(target) and target == pl then
            table.insert(clients, v)
        end
    end

    for k, v in pairs(clients) do
        net.Start("kawaii.secret")
            net.WriteInt(#pl.SSJ["Jumps"], 16)
            net.WriteFloat(gain)
            net.WriteInt(currentVel, 18)
            net.WriteFloat(jss)
            net.WriteInt(lastSpeed, 18)
        net.Send(v)

        if not v.SSJ["Settings"][1] then continue end
        if not v.SSJ["Settings"][2] and #pl.SSJ["Jumps"] ~= 7 then continue end

        local displayJumpCount = #pl.SSJ["Jumps"] - 1
        if displayJumpCount <= 0 then continue end

        local str = {_C["Prefixes"].Timer, color_white}

        if displayJumpCount == 1 then
            table.insert(str, "PreSpeed: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(math.Round(currentVel - 0.5)))
        else
            table.insert(str, "J: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(displayJumpCount))
            table.insert(str, color_white)

            table.insert(str, " | S: ")
            table.insert(str, _C["Prefixes"].Timer)
            table.insert(str, tostring(math.Round(currentVel - 0.5)))
            table.insert(str, color_white)

            local oldData = pl.SSJ["Jumps"][#pl.SSJ["Jumps"] - 1]
            if oldData then
                local oldVelocity = oldData[1]
                local oldHeight = oldData[2]
                local difference = math.Round(currentVel - oldVelocity)
                local height = math.Round(currentHeight - oldHeight)

                if v.SSJ["Settings"][4] then
                    table.insert(str, " | H ∆: ")
                    table.insert(str, _C["Prefixes"].Timer)
                    table.insert(str, tostring(height))
                    table.insert(str, color_white)
                end
                if v.SSJ["Settings"][3] then
                    table.insert(str, " | S ∆: ")
                    table.insert(str, _C["Prefixes"].Timer)
                    table.insert(str, tostring(difference))
                    table.insert(str, color_white)
                end
            end

            if v.SSJ["Settings"][6] then
                table.insert(str, " | G: ")
                table.insert(str, color)
                table.insert(str, tostring(gain) .. "%")
                table.insert(str, color_white)
            end

            if v.SSJ["Settings"][7] then
                table.insert(str, " | SPJ: ")
                table.insert(str, _C["Prefixes"].Timer)
                table.insert(str, tostring(pl.JHUD.Strafes))
                table.insert(str, color_white)
            end

            if v.SSJ["Settings"][8] then
                if jss >= 101 then
                    table.insert(str, " | JSS: ")
                    table.insert(str, _C["Prefixes"].Timer)
                    table.insert(str, tostring(math.Round(jss, 0)))
                    table.insert(str, "")
                    table.insert(str, Color(39, 255, 0, 255))
                    table.insert(str, "✓")
                else
                    local jssSuffix = (jss <= 70 and "▼" or "▲")
                    table.insert(str, " | JSS: ")
                    table.insert(str, _C["Prefixes"].Timer)
                    table.insert(str, tostring(math.Round(jss, 0)))
                    table.insert(str, Color(255, 0, 0, 255))
                    table.insert(str, jssSuffix)
                end
            end

            if v.SSJ["Settings"][9] then
                table.insert(str, " | Eff: ")
                table.insert(str, _C["Prefixes"].Timer)
                table.insert(str, FormatEfficiency(pl))
                table.insert(str, color_white)
            end

            if v.SSJ["Settings"][10] then
                table.insert(str, " | Time: ")
                table.insert(str, _C["Prefixes"].Timer)
                table.insert(str, CalculateJumpTime(pl))
                table.insert(str, color_white)
            end
        end

        Core:Send(v, "Print", {"Timer", str})
    end
end

local function FormatEfficiency(pl)
    local efficiency = 0
    if pl.totalPerfectYaw ~= 0 then
        efficiency = (pl.totalNormalYaw / pl.totalPerfectYaw)
    end
    return efficiency >= 1.0 and "0%" or string.format("%.2f%%", efficiency * 100)
end

local function CalculateJumpTime(pl)
    local jumpTimeFormatted = nil
    if pl.jumpStartTime then
        local jumpTime = CurTime() - pl.jumpStartTime
        if jumpTime > 0.01 then
            jumpTimeFormatted = string.format("%.2f", jumpTime) .. "s"
        else
            jumpTimeFormatted = "0.72s"
        end
    end
    return jumpTimeFormatted or "0.72s"
end
