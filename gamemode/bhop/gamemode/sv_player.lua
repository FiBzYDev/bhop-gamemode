-- Player Configuration
Player = {
    MultiplierNormal = 1,
    MultiplierAngled = 1,
    LadderScalar = 1.40,
    NormalScalar = 0.0001,
    AngledScalar = 0.0001
}

if CLIENT then
    local cooldown = 0

    local function requestFullPlayerUpdate()
        if cooldown > CurTime() then return end
        net.Start("RequestFullPlayerUpdate")
        net.SendToServer()
        cooldown = CurTime() + 10
    end

    hook.Add("InitPostEntity", "RequestFullPlayerUpdate", function()
        requestFullPlayerUpdate()
        timer.Create("RepeatedFullPlayerUpdate", 10, 0, requestFullPlayerUpdate)
    end)
end

-- PVS Functions
local function player_FindInPVS(viewPoint)
    local plys = {}
    for _, ent in ipairs(ents.FindInPVS(viewPoint)) do
        if ent:IsPlayer() then
            table.insert(plys, ent)
        end
    end
    return plys
end

local function player_FindOutsidePVS(viewPoint)
    local plys = {}
    local pvs_plys = player_FindInPVS(viewPoint)
    for _, ply in ipairs(player.GetAll()) do
        if not pvs_plys[ply] then
            table.insert(plys, ply)
        end
    end
    return plys
end

local query = {}
local query_size = 0

local function RemovePlayer(query, id, ply)
    query[id] = nil
    if #query == 0 then
        query[ply] = nil
        query_size = query_size - 1
        if query_size == 0 then
            hook.Remove("SetupPlayerVisibility", "Player_Query")
        end
    end
end

local function SetupPlayerVisibility(ply)
    local left_plys = query[ply]
    if not left_plys or next(left_plys) == nil then return end

    local pvs_plys = {}
    for _, pvs_ply in ipairs(player_FindInPVS(ply)) do
        pvs_plys[pvs_ply] = true
    end

    for k, v in pairs(left_plys) do
        if pvs_plys[v] then
            RemovePlayer(left_plys, k, ply)
        else
            AddOriginToPVS(v:GetPos())
        end
    end
end

util.AddNetworkString("RequestFullPlayerUpdate")
net.Receive("RequestFullPlayerUpdate", function(_, ply)
    query[ply] = player_FindOutsidePVS(ply)
    if query_size == 0 then
        hook.Add("SetupPlayerVisibility", "Player_Query", SetupPlayerVisibility)
    end
    query_size = query_size + 1
end)

local PLAYER_HULL_MIN = Vector(-16.0, -16.0, 0.0)
local PLAYER_HULL_STAND = Vector(16.0, 16.0, 62.0)
local PLAYER_HULL_DUCK = Vector(16.0, 16.0, 45.0)

function Player:Spawn(ply)
    if not IsValid(ply) then return end

    if not ply:IsBot() then
        ply:SetModel(_C.Player.DefaultModel)
    else
        ply:SetPos(Vector(0, 0, 0))
    end

    ply:SetNoCollideWithTeammates(true)
    ply:SetAvoidPlayers(false)
    ply:SetJumpPower(_C.Player.JumpPower)
    ply:SetHull(_C.Player.HullMin, _C.Player.HullStand)
    ply:SetHullDuck(_C.Player.HullMin, _C.Player.HullDuck)

    if ply:Crouching() then
        ply:SetCollisionBounds(PLAYER_HULL_MIN, PLAYER_HULL_DUCK)
    else
        ply:SetCollisionBounds(PLAYER_HULL_MIN, PLAYER_HULL_STAND)
    end

    if not ply:IsBot() then
        Stats:InitializePlayer(ply)
        if ply.Style == _C.Style.Bonus then
            ply:BonusReset()
        else
            ply:ResetTimer()
        end
        Player:SpawnChecks(ply)
    else
        if Zones.BotPoint then
            ply:SetPos(Zones.BotPoint)
        end
    end
end

function Player:SpawnChecks(ply)
    Core.Util:SetPlayerJumps(ply, 0)

    local stepSize = Zones.DefaultStepSize
    if ply.Style == _C.Style.Bonus then
        stepSize = Zones.BonusStepSize or stepSize
    elseif Zones.StepSize then
        stepSize = Zones.StepSize
    end
    ply:SetStepSize(18)

    if ply.Style == _C.Style.Legit and ply.LegitTopSpeed and ply.LegitTopSpeed ~= 480 then
        ply:SetLegitSpeed(480)
    end

    local spawnPoint = Zones:GetSpawnPoint(Zones.StartPoint)
    if ply.Style == _C.Style.Bonus and Zones.BonusPoint then
        spawnPoint = Zones:GetSpawnPoint(Zones.BonusPoint)
    end

    local steamID = ply:SteamID()
    local index = Setspawn.Points and Setspawn.Points[steamID] and Setspawn.Points[steamID][(ply.Style == _C.Style.Bonus) and 2 or 0]
    if index then
        ply:SetPos(index[1])
        ply:SetEyeAngles(index[2])
    else
        ply:SetPos(spawnPoint)
    end

    if not ply:IsBot() and ply:GetMoveType() ~= MOVETYPE_WALK then
        ply:SetMoveType(MOVETYPE_WALK)
    end
end

function Player:Load(ply)
    Stats:EnablePlayer(ply)
    ply:SetTeam(_C.Team.Players)
    ply.Style = _C.Style.Normal
    ply.Record = 0
    ply.Rank = -1
    ply:InitStrafeTrainer()

    if Zones.StyleForce then
        ply.Style = Zones.StyleForce
    end

    ply:SetNWInt("Style", ply.Style)
    ply:SetNWFloat("Record", ply.Record)
    JAC:Init(ply)

    if not ply:IsBot() then
        Player:LoadBest(ply)
        Player:LoadRank(ply)
        Timer:SendInitialRecords(ply)
        Admin:CheckPlayerStatus(ply)
        Bot:StartRecording(ply)
        SMgrAPI:Monitor(ply, true)

        ply.SyncDisplay = ""
        ply.ConnectedAt = CurTime()

        Timer:UpdateWRs(ply)
    else
        ply.Temporary = true
        ply.Rank = -2
        ply:SetNWInt("Rank", ply.Rank)
    end
end

function Player:LoadStyle(ply, nStyle)
    if not IsValidStyle(nStyle) then return end
    ply.Style = nStyle
    ply.Record = 0

    Command:RemoveLimit(ply)
    Command.Restart(ply)
    Player:LoadBest(ply)
    Player:LoadRank(ply, true)

    ply:SetNWInt("Style", ply.Style)
    ply:SetNWFloat("Record", ply.Record)

    Core:Send(ply, "Print", {"Timer", Lang:Get("StyleChange", {Core:StyleName(ply.Style)})})
end

local PlayerPoints = {}

function Player:LoadRanks()
    local Data = sql.Query("SELECT SUM(nMultiplier) AS nSum, SUM(nBonusMultiplier) AS nBonus FROM game_map")
    if Core:Assert(Data, "nSum") then
        local Normal, Bonus = tonumber(Data[1]["nSum"]) or 1, tonumber(Data[1]["nBonus"]) or 1
        Player.MultiplierNormal = Normal + Bonus
        Player.MultiplierAngled = Normal * 0.5
    end

    local OutNormal = Player:FindScalar(Player.MultiplierNormal)
    local OutAngled = Player:FindScalar(Player.MultiplierAngled)

    if OutNormal + OutAngled > 0 then
        Player.NormalScalar = OutNormal
        Player.AngledScalar = OutAngled
    else
        Core:Lock("Couldn't calculate ranking scalar. Make sure you have at least ONE entry in your game_map!")
    end

    for n, data in pairs(_C.Ranks) do
        if n < 0 then continue end
        _C.Ranks[n][3] = Core:Exp(Player.NormalScalar, n)
        _C.Ranks[n][4] = Core:Exp(Player.AngledScalar, n)
    end
end

function Player:LoadRank(ply, bUpdate)
    self:CachePointSum(ply.Style, ply:SteamID())
    timer.Simple(0.25, function()
        local nSum = self:GetPointSum(ply.Style, ply:SteamID())
        local nRank = self:GetRank(nSum, self:GetRankType(ply.Style, true))
        ply.RankSum = nSum

        if nRank ~= ply.Rank then
            ply.Rank = nRank
            ply:SetNWInt("Rank", ply.Rank)
        end

        self:SetSubRank(ply, nRank, nSum)

        if not bUpdate then
            Core:Send(ply, "Timer", {"Ranks", self.NormalScalar, self.AngledScalar})
        end
    end)
end

function Player:LoadBest(ply)
    if ply.Style == _C.Style.Practice then
        ply:SetNWFloat("Record", ply.Record)
        ply.SpecialRank = 0
        ply:SetNWInt("SpecialRank", ply.SpecialRank)
        return Core:Send(ply, "Timer", {"Record", ply.Record, ply.Style})
    end

    MySQL:Start("SELECT t1.nTime, (SELECT COUNT(*) + 1 FROM game_times AS t2 WHERE szMap = '" .. game.GetMap() .. "' AND t2.nTime < t1.nTime AND nStyle = " .. ply.Style .. ") AS nRank FROM game_times AS t1 WHERE t1.szUID = '" .. ply:SteamID() .. "' AND t1.nStyle = " .. ply.Style .. " AND t1.szMap = '" .. game.GetMap() .. "'", function(Fetch)
        if Core:Assert(Fetch, "nTime") then
            ply.Record = tonumber(Fetch[1]["nTime"])
            ply:SetNWFloat("Record", ply.Record)
            Core:Send(ply, "Timer", {"Record", ply.Record, ply.Style})
            self:SetRankMedal(ply, tonumber(Fetch[1]["nRank"]))
        else
            ply:SetNWFloat("Record", ply.Record)
            Core:Send(ply, "Timer", {"Record", ply.Record, ply.Style})
            ply.SpecialRank = 0
            ply:SetNWInt("SpecialRank", ply.SpecialRank)
        end
    end)
end

function Player:CachePointSum(nStyle, szUID)
    MySQL:Start("SELECT SUM(nPoints) AS nSum FROM game_times WHERE szUID = '" .. szUID .. "' AND (" .. self:GetMatchingStyles(nStyle) .. ")", function(data)
        if Core:Assert(data, "nSum") then
            PlayerPoints[szUID] = PlayerPoints[szUID] or {}
            PlayerPoints[szUID][nStyle] = tonumber(data[1]["nSum"]) or 0
        end
    end)
end

function Player:GetPointSum(nStyle, szUID)
    return PlayerPoints[szUID] and PlayerPoints[szUID][nStyle] or 0
end

function Player:GetRank(nPoints, nType)
    local Rank = 1
    for RankID, Data in pairs(_C.Ranks) do
        if RankID > Rank and nPoints >= Data[nType] then
            Rank = RankID
        end
    end
    return Rank
end

function Player:SetSubRank(ply, nRank, nPoints)
    local function calculateSubRank(nRank, nPoints)
        if nRank >= #_C.Ranks then
            return 10
        else
            local nDifference = _C.Ranks[nRank + 1][3] - _C.Ranks[nRank][3]
            local nStepSize = nDifference / 10
            local nOut = 1
            for i = _C.Ranks[nRank][3], _C.Ranks[nRank + 1][3], nStepSize do
                if nPoints >= i then
                    nOut = math.ceil((i - _C.Ranks[nRank][3]) / nStepSize) + 1
                end
            end
            return nOut
        end
    end

    local nSubRank = calculateSubRank(nRank, nPoints)

    if not ply.SubRank or ply.SubRank ~= nSubRank then
        ply.SubRank = nSubRank
        ply:SetNWInt("SubRank", ply.SubRank)
    end
end

function Player:ReloadSubRanks(sender, nOld)
    local nMultiplier = Timer:GetMultiplier(sender.Style)
    if not nMultiplier or nMultiplier == 0 then
        return
    end

    local nAverage = Timer:GetAverage(sender.Style)
    if not nAverage or not nOld then
        return
    end

    for _, p in pairs(player.GetHumans()) do
        if p == sender or not p.RankSum or not p.Rank or not p.Record or p.Record == 0 or p.Style ~= sender.Style then
            continue
        end

        local nCurrent = nMultiplier * (nOld / p.Record)
        local nNew = nMultiplier * (nAverage / p.Record)
        local nPoints = p.RankSum - nCurrent + nNew

        local nRank = self:GetRank(nPoints, self:GetRankType(p.Style, true))
        if nRank ~= p.Rank then
            p.Rank = nRank
            p:SetNWInt("Rank", p.Rank)
        end
        p.RankSum = nPoints
        self:SetSubRank(p, p.Rank, p.RankSum)
    end
end

function Player:SetRankMedal(ply, nPos)
    local map = game.GetMap()
    local style = ply.Style
    local query = "SELECT t1.szUID, (SELECT COUNT(*) + 1 FROM game_times AS t2 WHERE szMap = '" .. map .. "' AND t2.nTime < t1.nTime AND nStyle = " .. style .. ") AS nRank FROM game_times AS t1 WHERE t1.szMap = '" .. map .. "' AND t1.nStyle = " .. style .. " ORDER BY nRank ASC LIMIT 3"

    MySQL:Start(query, function(Query)
        if Core:Assert(Query, "szUID") then
            for _, p in pairs(player.GetHumans()) do
                if p.Style ~= style then continue end

                local bSet = false
                for _, d in pairs(Query) do
                    if p:SteamID() == d["szUID"] then
                        bSet = true
                        if tonumber(d["nRank"]) > 40 then
                            p.SpecialRank = p.SpecialRank or 0
                            if p.SpecialRank ~= 0 then
                                p.SpecialRank = 0
                                p:SetNWInt("SpecialRank", p.SpecialRank)
                            end
                        else
                            p.SpecialRank = tonumber(d["nRank"])
                            p:SetNWInt("SpecialRank", p.SpecialRank)
                        end
                    end
                end
                if not bSet and p.SpecialRank then
                    p.SpecialRank = 0
                    p:SetNWInt("SpecialRank", p.SpecialRank)
                end
            end
        end
    end)
end

function Player:UpdateRank(ply)
    self:LoadRank(ply, true)
end

function Player:GetMatchingStyles(nStyle)
    local tab = {_C.Style.Normal, _C.Style["Easy Scroll"], _C.Style.Legit, _C.Style.Bonus}
    if nStyle >= _C.Style.SW and nStyle <= _C.Style["A-Only"] then
        tab = {_C.Style.SW, _C.Style.HSW, _C.Style["W-Only"], _C.Style["A-Only"]}
    end

    local t = {}
    for _, s in ipairs(tab) do
        table.insert(t, "nStyle = " .. s)
    end
    return table.concat(t, " OR ")
end

function Player:FindScalar(nMultiplier)
    local Count, Sum, Out = #_C.Ranks, nMultiplier * Player.LadderScalar, 0
    for i = 0, 50, 0.00001 do
        if Core:Exp(i, Count) > Sum then
            Out = i
            break
        end
    end
    return Out
end

function Player:GetRankType(nStyle, bNumber)
    if nStyle >= _C.Style.SW and nStyle <= _C.Style["A-Only"] then
        return bNumber and 4 or true
    else
        return bNumber and 3 or false
    end
end

function Player:GetOnlineVIPs()
    local tabVIP = {}
    for _, p in ipairs(player.GetHumans()) do
        if p.IsVIP then
            table.insert(tabVIP, p)
        end
    end
    return tabVIP
end

local TopCache = {}
local TopLimit = 15 * _C.PageSize

function Player:LoadTop()
    local topStyles = {
        [_C.Style.Normal] = {"szPlayer", "SUM(nPoints) as nSum", "nSum"},
        [_C.Style.Bonus] = {"szPlayer", "SUM(nPoints) as nSum", "nSum"},
        [_C.Style.SW] = {"szPlayer", "SUM(nPoints) as nSum", "nSum"},
        [_C.Style.HSW] = {"szPlayer", "SUM(nPoints) as nSum", "nSum"}
    }

    for style, columns in pairs(topStyles) do
        TopCache[style] = {}
        MySQL:Start("SELECT " .. columns[1] .. ", " .. columns[2] .. " FROM game_times WHERE (nStyle = " .. style .. " OR nStyle = " .. (_C.Style.Bonus) .. ") GROUP BY szUID ORDER BY " .. columns[3] .. " DESC LIMIT " .. TopLimit, function(data)
            if Core:Assert(data, columns[3]) then
                for i, d in pairs(data) do
                    TopCache[style][i] = {string.sub(d["szPlayer"], 1, 20), math.floor(tonumber(d["nSum"]))}
                end
            end
        end)
    end
end

function Player:GetTopPage(nPage, nStyle)
    local tab = {}
    local startIndex = _C.PageSize * nPage - _C.PageSize
    local topData = TopCache[nStyle]

    for i = 1, _C.PageSize do
        local dataIndex = i + startIndex
        if topData[dataIndex] then
            tab[dataIndex] = topData[dataIndex]
        end
    end

    return tab
end

function Player:GetTopCount(nStyle)
    return #TopCache[nStyle]
end

function Player:SendTopList(ply, nPage, nType)
    local nStyle = nType == 4 and _C.Style.Backwards or _C.Style.Normal
    Core:Send(ply, "GUI_Update", {"Top", {4, Player:GetTopPage(nPage, nStyle), nPage, Player:GetTopCount(nStyle), nType}})
end

function Player:GetMapsBeat(ply, yeahwhatuwant)
    MySQL:Start("SELECT szMap, nTime, nPoints FROM game_times WHERE szUID = '" .. ply:SteamID() .. "' AND nStyle = " .. ply.Style .. " ORDER BY nPoints ASC", function(List)
        local tab = {}
        if Core:Assert(List, "szMap") then
            for _, d in pairs(List) do
                table.insert(tab, {d["szMap"], tonumber(d["nTime"]), tonumber(d["nPoints"])})
            end
        end
        Core:Send(ply, "GUI_Open", {"Maps", {yeahwhatuwant, tab}})
    end)
end

function Player:SendRemoteWRList(ply, szMap, nStyle, nPage, bUpdate)
    if not szMap or type(szMap) ~= "string" then
        return
    end

    local function SendWRData(data, count, map)
        if bUpdate then
            UI:SendToClient(ply, "wr", data, nStyle, nPage, count)
        else
            UI:SendToClient(ply, "wr", data, nStyle, nPage, count, map)
        end
    end

    if szMap == game.GetMap() then
        local recordList = Timer:GetRecordList(nStyle, nPage)
        local recordCount = Timer:GetRecordCount(nStyle)
        return SendWRData(recordList, recordCount)
    end

    local SendData = {}
    local SendCount = 0
    local RWRC = RemoteWRCache[szMap]

    if not RWRC or (type(RWRC) == "table" and not RWRC[nStyle]) then
        if RTV:MapExists(szMap) then
            MySQL:Start("SELECT * FROM game_times WHERE szMap = '" .. szMap .. "' AND nStyle = " .. nStyle .. " ORDER BY nTime ASC", function(List)
                if not RWRC then
                    RemoteWRCache[szMap] = {}
                end
                RemoteWRCache[szMap][nStyle] = {}
                if Core:Assert(List, "szUID") then
                    for _, data in pairs(List) do
                        table.insert(RemoteWRCache[szMap][nStyle], {data["szUID"], data["szPlayer"], tonumber(data["nTime"]), Core:Null(data["szDate"]), Core:Null(data["vData"])})
                    end
                end
                local startIndex = nPage * _C.PageSize - _C.PageSize + 1
                for i = startIndex, startIndex + _C.PageSize - 1 do
                    if RemoteWRCache[szMap][nStyle][i] then
                        SendData[i] = RemoteWRCache[szMap][nStyle][i]
                    end
                end
                SendCount = #RemoteWRCache[szMap][nStyle]
                SendWRData(SendData, SendCount)
            end)
            timer.Simple(0.2, function()
                self:SendRemoteWRList(ply, szMap, nStyle, nPage, bUpdate)
            end)
            return
        else
            return Core:Send(ply, "Print", {"General", Lang:Get("MapInavailable", {szMap})})
        end
    else
        local startIndex = nPage * _C.PageSize - _C.PageSize + 1
        for i = startIndex, startIndex + _C.PageSize - 1 do
            if RemoteWRCache[szMap][nStyle][i] then
                SendData[i] = RemoteWRCache[szMap][nStyle][i]
            end
        end
        SendCount = #RemoteWRCache[szMap][nStyle]
        SendWRData(SendData, SendCount)
    end

    if SendCount == 0 then
        if not bUpdate then
            Core:Send(ply, "Print", {"Timer", "No WR data found for " .. szMap .. " on style " .. Core:StyleName(nStyle)})
        end
    end
end