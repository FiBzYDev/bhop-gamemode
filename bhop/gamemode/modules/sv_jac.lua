-- Module init
JAC = {}

-- Kick message
local kick_msg = "You have been banned permanently for cheating.\nDetails of your detections will not be released."

-- Statistical Scores
local stats = {
    ["gain"] = {{85, 87, 90}, {false, false, false}, "Warning! Client 1 has 2 gains (Level: 3)"},
    ["angle"] = {{40, 60, 80}, {false, false, true}, "Warning! Client 1 had an illegal angle snap of 2 degrees (Level: 3)"}
}

-- Colors
local CW = color_white
local CJ = Color(186, 85, 211)

-- Print function
function JAC:Print(client, ...)
    Core:Send(client, "Print", {"jAntiCheat", {CW, ...}})
end

-- Compile string for messages
local function CompileString(str, client, stat, level)
    local replacements = {
        ["1"] = {color = CJ, text = client:Nick()},
        ["2"] = {color = CJ, text = stat == "gain" and tostring(stat) .. "%" or tostring(stat)},
        ["3"] = {color = level[1], text = level[2]}
    }

    local result = {CW}
    for i = 1, #str do
        local c = str:sub(i, i)
        if replacements[c] then
            table.insert(result, replacements[c].color)
            table.insert(result, replacements[c].text)
            table.insert(result, CW)
        else
            table.insert(result, c)
        end
    end

    return result
end

-- Determine threat level and corresponding color
local function GetThreatLevel(var, thresholds)
    if var >= thresholds[3] then
        return 3, {Color(186, 82, 73), "High [No Kick]"}
    elseif var >= thresholds[2] then
        return 2, {Color(255, 140, 0), "Medium"}
    elseif var >= thresholds[1] then
        return 1, {Color(0, 100, 0), "Low"}
    end
    return 0, nil
end

-- Report stat
function JAC:ReportStat(client, stat, var)
    local thresholds = stats[stat][1]
    local threat, level = GetThreatLevel(var, thresholds)

    if threat == 0 then return end

    local str = CompileString(stats[stat][3], client, stat, level)
    self:InitWarn(unpack(str))
end

-- Initialize warning
function JAC:InitWarn(...)
    for _, admin in pairs(player.GetHumans()) do
        if admin:GetNWInt("AccessIcon", 0) >= 3 then
            self:Print(admin, ...)
        end
    end
end

-- Initialize ban
function JAC:InitBan(client)
    local name = client:Name()
    Admin:AddBan(client:SteamID(), name, 0, kick_msg, "CONSOLE", "CONSOLE")
    client:Kick(kick_msg)
    self:Print(player.GetHumans(), "Player ", CJ, name, CW, " has been banned permanently for cheating.")
end

-- Detection limits
local DetectionLimit = {
    ["consistant_strafe"] = 3,
    ["perfect_strafe"] = 3,
    ["no_startcommand"] = 1
}

local Detections = {}

-- Database initialization
MySQL:Start('create table if not exists jac_log(id int AUTO_INCREMENT, steamid varchar(255), name text, ip text, detectionid text, data text, PRIMARY KEY(id))')

-- Register detection
function JAC:RegisterDetection(client, id, ...)
    local data = {...}
    Detections[client] = Detections[client] or {}
    Detections[client][id] = Detections[client][id] or {}

    table.insert(Detections[client][id], data)
    MySQL:Start("insert into jac_log(steamid, name, ip, detectionid, data) VALUES('" .. client:SteamID() .. "', '" .. client:Nick() .. "', '" .. client:IPAddress() .. "', '" .. id .. "', '" .. table.concat(data, ' ') .. "')")

    if #Detections[client][id] > DetectionLimit[id] then
        self:InitBan(client)
    end
end

-- Strafe data handling
local StrafeData = {
    TotalRight = {}, PerfectRight = {}, LastRight = {}, CRight = {},
    TotalLeft = {}, PerfectLeft = {}, LastLeft = {}, CLeft = {}
}

function JAC:Init(client)
    self:Refresh(client)
end

function JAC:Refresh(client)
    for k, v in pairs(StrafeData) do
        v[client] = 0
    end
end

-- Handle right strafe
function JAC:HandleRightStrafe(client, gain)
    if gain > 0.9 then
        StrafeData.PerfectRight[client] = StrafeData.PerfectRight[client] + 1
    end
    if gain > 0.1 then
        StrafeData.TotalRight[client] = StrafeData.TotalRight[client] + 1
        if (StrafeData.LastRight[client] < (gain + 0.01) and StrafeData.LastRight[client] > (gain - 0.01)) and (gain > 0.3) then
            StrafeData.CRight[client] = StrafeData.CRight[client] + 1
        end
        StrafeData.LastRight[client] = gain
    end
end

-- Handle left strafe
function JAC:HandleLeftStrafe(client, gain)
    if gain > 0.9 then
        StrafeData.PerfectLeft[client] = StrafeData.PerfectLeft[client] + 1
    end
    if gain > 0.1 then
        StrafeData.TotalLeft[client] = StrafeData.TotalLeft[client] + 1
        if (StrafeData.LastLeft[client] < (gain + 0.01) and StrafeData.LastLeft[client] > (gain - 0.01)) and (gain > 0.3) then
            StrafeData.CLeft[client] = StrafeData.CLeft[client] + 1
        end
        StrafeData.LastLeft[client] = gain
    end
end

function JAC:CheckFrame(client, gain, smove)
    if smove > 0 then
        self:HandleRightStrafe(client, gain)
    elseif smove < 0 then
        self:HandleLeftStrafe(client, gain)
    end
end

JAC.Debug = true

function JAC:StartCheck(client)
    local perfectRightPer = StrafeData.PerfectRight[client] / StrafeData.TotalRight[client]
    local perfectLeftPer = StrafeData.PerfectLeft[client] / StrafeData.TotalLeft[client]
    local consistantRightPer = StrafeData.CRight[client] / StrafeData.TotalRight[client]
    local consistantLeftPer = StrafeData.CLeft[client] / StrafeData.TotalLeft[client]

    if StrafeData.TotalRight[client] + StrafeData.TotalLeft[client] < 15 then
        self:Refresh(client)
        return
    end

    local consistantBan = (StrafeData.TotalRight[client] > 10) and (StrafeData.TotalLeft[client] > 10) and ((consistantRightPer > 0.9) or (consistantLeftPer > 0.9))
    local perfectBan = ((perfectRightPer + perfectLeftPer) / 2) > 0.95

    if consistantBan then
        self:RegisterDetection(client, "consistant_strafe", StrafeData.TotalRight[client], StrafeData.TotalLeft[client], StrafeData.CRight[client], StrafeData.CLeft[client], consistantRightPer, consistantLeftPer)
    elseif perfectBan then
        self:RegisterDetection(client, "perfect_strafe", StrafeData.TotalRight[client], StrafeData.TotalLeft[client], StrafeData.PerfectRight[client], StrafeData.PerfectLeft[client], perfectRightPer, perfectLeftPer)
    end

    if self.Debug then
        local c = string.format("-----------------------------[ Client: %s ]-----------------------------", client:Nick())
        print("\n" .. c .. "\n")
        print(string.format("\tTotal Strafes: %d [Right: %d] [Left: %d]", StrafeData.TotalLeft[client] + StrafeData.TotalRight[client], StrafeData.TotalRight[client], StrafeData.TotalLeft[client]))
        print(string.format("\tPerfect Strafes: %d [Right: %d (%.2f%%)] [Left: %d (%.2f%%)]", StrafeData.PerfectLeft[client] + StrafeData.PerfectRight[client], StrafeData.PerfectRight[client], perfectRightPer * 100, StrafeData.PerfectLeft[client], perfectLeftPer * 100))
        print(string.format("\tConsistant Strafes: %d [Right: %d (%.2f%%)] [Left: %d (%.2f%%)]", StrafeData.CLeft[client] + StrafeData.CRight[client], StrafeData.CRight[client], consistantRightPer * 100, StrafeData.CLeft[client], consistantLeftPer * 100))
        print(string.format("\tSuspected Cheat: %s", (consistantBan or perfectBan) and "Yes" or "No"))
        print("\n" .. string.rep("-", #c))
    end

    self:Refresh(client)
end

function JAC:ReportIllegalMovement(client, aDiff, pDiff)
    if aDiff > 10 then
        -- print(string.format("Client %s [%s, %s] Angle Snap: %.2f°", client:Name(), client:SteamID(), client:IPAddress(), aDiff))
    end
    if client.stopillegal or aDiff < 49.99 then return end
    -- self:ReportStat(client, "angle", math.Round(aDiff, 2))
end