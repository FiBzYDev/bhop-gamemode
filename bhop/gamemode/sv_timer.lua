local PLAYER, CT, CAPVEL, strafeavg, nPage = FindMetaTable("Player"), SysTime, 280, 0, nil
Timer = {
    Multiplier = 1,
    BonusMultiplier = 1,
    Options = 0
}

require "reqwest"
local reqwest = reqwest
local DISCORD_WR_WEBHOOK = file.Read("bhop-wr-webhook.txt", "DATA")

local function ValidTimer(ply, bBonus)
    -- Check if the player is a bot
    if ply:IsBot() then
        return false
    end
    
    -- Check if the player is in practice mode
    if ply:GetNWInt("inPractice", false) then
        return false
    end

    -- Check if the timer is for bonus style (if specified)
    if bBonus then
        return ply.Style == _C.Style.Bonus
    else
        return ply.Style ~= _C.Style.Bonus
    end
end

-- Function to convert tick-based input to formatted time with rounded milliseconds
function Timer:Convert(input)
    -- Calculate time components
	input = input * engine.TickInterval() / .01
    local seconds = math.floor(input)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)

    -- Calculate remaining seconds and milliseconds
    local remainingSeconds = seconds % 60
    local milliseconds = math.floor((input - seconds) * 1000 + 0.5) -- Round milliseconds

    -- Adjust seconds if milliseconds overflowed
    if milliseconds >= 1000 then
        remainingSeconds = remainingSeconds + 1
        milliseconds = 0
    end

    -- Format components with leading zeros if necessary
    local formattedSeconds = string.format("%02d", remainingSeconds)
    local formattedMinutes = string.format("%02d", minutes % 60)
    local formattedMilliseconds = string.format("%03d", milliseconds)

    -- Construct the formatted time string
    local formattedTime = formattedMinutes .. ":" .. formattedSeconds .. "." .. formattedMilliseconds

    -- Include hours if the input is greater than an hour
    if hours > 0 then
        formattedTime = string.format("%02d", hours) .. ":" .. formattedTime
    end

    return formattedTime
end

function Timer:Convert2(input,_)
	input = input * engine.TickInterval() / .01
	if not input then input = 0 end
	local h = math.floor(input / 3600)
	local m = math.floor((input / 60) % 60)
	local ms = ( input - math.floor( input ) ) * 1000
	local s = math.floor(input % 60)
	if input > 3600 then
		return string.format("%02i:%02i:%02i.%03i",h,m,s,ms)
	else
		return string.format("%02i:%02i.%03i",m,s,ms)
	end
end

function Timer:GetDate()
	return os.date( "%Y-%m-%d %H:%M:%S", os.time() )
end

function PLAYER:StartTimer(savetime)
    if not ValidTimer(self) then return end

    local vel2d = self:GetVelocity():Length2D()
    if vel2d > CAPVEL and not (bit.band(Timer.Options, Zones.Options.NoStartLimit) > 0) then
        self:SetLocalVelocity(Vector(0, 0, 0))
        Player:SpawnChecks(self)
        return Core:Send(self, "Print", {"Timer", Lang:Get("ZoneSpeed")})
    end

    if not savetime then
        self.Tn = SysTime() + engine.TickInterval() / 0.1 -- Use SysTime for internal precision timing
        self.displayTn = CurTime() -- Use CurTime for display purposes
        self.lastGroundTouch = SysTime() -- Initialize the last ground touch time
    end

    -- Start the tick-based timer
    local timerName = "PlayerTimer_" .. self:SteamID()
    local tickDuration = 0.1  -- Adjust this value as needed
    local elapsedTicks = 0

    timer.Create(timerName, tickDuration, 0, function()
        -- Increment elapsed ticks
        elapsedTicks = elapsedTicks + 1

        -- Perform actions on each tick here
        -- For example, calculate elapsed time since start tick
        local elapsedTime = elapsedTicks * tickDuration

        -- Check if the player has touched the ground recently
        if self:IsOnGround() then
            self.lastGroundTouch = SysTime()
        end

        -- Check if the player has been on the ground for half a second or more
        if SysTime() - self.lastGroundTouch >= 0.00000001 then
            if not self.hasBeenOnGround then
                self.hasBeenOnGround = true
                -- Add your custom actions here
            end
        else
            -- Reset the flag if the player leaves the ground
            self.hasBeenOnGround = false
        end

        -- Check if you need to stop the timer
        if elapsedTime >= 100000 then
            timer.Remove(timerName)
            -- print("Timer stopped after reaching max time")
        end
    end)

    -- Send timer start event to the player/entity
    local elapsedTime = SysTime() - self.Tn
    Core:Send(self, "Timer", {"Start", self.displayTn}) -- Use displayTn for displaying the timer

    if self.Style == _C.Style.Legit and self.LegitTopSpeed and self.LegitTopSpeed ~= 480 then
        self:SetLegitSpeed(480)
    end

    Bot:TrimRecording(self)
    Spectator:PlayerRestart(self)
    SMgrAPI:ResetStatistics(self)

    Core:Send(player.GetAll(), "Scoreboard", {"normal", self, self.displayTn}) -- Use displayTn for the scoreboard
end

function PLAYER:ResetTimer(saveway)
    Core:Send(self, "Timer", { "Restart" })
    self:SetNWInt("inPractice", false)

    if not ValidTimer(self) then
        return
    end

    if not self.Tn then
        return
    end

    local tickInterval = engine.TickInterval() / 0.1 -- Get the tick interval

    if saveway and self.Tn ~= nil and self.TnF ~= nil then
        local timeRemaining = self.TnF - self.Tn  -- Calculate remaining time
        self.Tn = CT() + timeRemaining / tickInterval  -- Adjust the time based on tickInterval
        self.TnF = nil
    else
        self.Tn = nil
        self.TnF = nil
    end

    local observers = { self }
    for k, v in pairs(player.GetHumans()) do
        if IsValid(v:GetObserverTarget()) and v:GetObserverTarget() == self then
            table.insert(observers, v)
        end
    end

    PlayerJumps[self] = 0
    Core:Send(observers, "jump_update", { self, 0 })

    Bot:StartRecording(self)

    Spectator:PlayerRestart(self)
    SMgrAPI:ResetStatistics(self)

    Core:Send(self, "Timer", { "Start", self.Tn })  -- Adjust timer based on tickInterval
    Core:Send(player.GetAll(), "Scoreboard", { "normal", self, self.Tn })
end

function PLAYER:StopTimer()
    if not ValidTimer(self) then
        return
    end

    local tickInterval = engine.TickInterval() / 0.01  -- Get the tick interval

    self.TnF = CT() * tickInterval  -- Calculate TnF in ticks

    Bot:StopRecording(self, self.TnF - self.Tn, self.Record)  -- Calculate tick difference
    Core:Send(self, "Timer", {"Finish", self.TnF})
    Timer:Finish(self, (self.TnF - self.Tn) * tickInterval)  -- Adjust the time based on tickInterval
    Core:Send(player.GetAll(), "Scoreboard", {"normal", self, self.Tn, self.TnF})
end

local tickInterval = engine.TickInterval() / 0.01 -- Get the tick interval

function PLAYER:BonusStart()
    if not ValidTimer(self, true) then
        return
    end

    local vel2d = self:GetVelocity():Length2D()
    if vel2d > CAPVEL then
        self:SetLocalVelocity(Vector(0, 0, 0))
        Player:SpawnChecks(self)
        return Core:Send(self, "Print", {"Timer", Lang:Get("ZoneSpeed")})
    end

    self.Tb = CT() * tickInterval
    self.TbF = nil

    Core.Util:SetPlayerJumps(self, 0)
    Core:Send(self, "Timer", {"Start", self.Tb * tickInterval})  -- Adjust the time based on tickInterval

    Bot:TrimRecording(self)
    Spectator:PlayerRestart(self)
    SMgrAPI:ResetStatistics(self)
    Core:Send(player.GetAll(), "Scoreboard", {"bonus", self, self.Tb * tickInterval})
end

-- Define the BonusReset function for the PLAYER class
function PLAYER:BonusReset()
    -- Check if the player has a valid timer and the necessary variables
    if not ValidTimer(self, true) then
        return
    end

    -- Reset the bonus timer variables
    self.Tb = nil
    self.TbF = nil

    -- Perform any additional reset logic here

    -- Send messages or update UI as needed
    Core:Send(self, "Timer", {"Start", self.Tb})
    Core:Send(player.GetAll(), "Scoreboard", {"bonus", self, self.Tb})
end

function PLAYER:StopAnyTimer()
	if self:IsBot() then return false end
	if self:GetNWInt("inPractice", false) then return false end

	self.Tn = nil
	self.TnF = nil
	self.Tb = nil
	self.TbF = nil

	Bot:StartRecording( self )

	Core:Send( self, "Timer", { "Start" } )
	Core:Send(player.GetAll(), "Scoreboard", {"stopanytimer", self})
	return true
end

function PLAYER:BonusStop()
    if not ValidTimer(self, true) then
        return
    end
    self.TbF = CT()

    Bot:StopRecording(self, (self.TbF - self.Tb) * tickInterval, self.Record)  -- Adjust the time based on tickInterval
    Core:Send(self, "Timer", {"Finish", self.TbF * tickInterval})  -- Adjust the time based on tickInterval
    Timer:Finish(self, (self.TbF - self.Tb) * tickInterval)  -- Adjust the time based on tickInterval
    Core:Send(player.GetAll(), "Scoreboard", {"bonus", self, self.Tb * tickInterval, self.TbF * tickInterval})
end

function PLAYER:StartFreestyle()
	if not ValidTimer( self ) then return end

	if self.Style >= _C.Style.SW and self.Style <= _C.Style["A-Only"] then
		self.Freestyle = true
		Core:Send( self, "Timer", { "Freestyle", self.Freestyle } )
		Core:Send( self, "Print", { "Timer", Lang:Get( "StyleFreestyle", { "entered a", " All key combinations are now possible." } ) } )
	end
end

function PLAYER:StopFreestyle()
	if not ValidTimer( self ) then return end

	if self.Style >= _C.Style.SW and self.Style <= _C.Style["A-Only"] then
		self.Freestyle = nil
		Core:Send( self, "Timer", { "Freestyle", self.Freestyle } )
		Core:Send( self, "Print", { "Timer", Lang:Get( "StyleFreestyle", { "left the", "" } ) } )
	end
end

function PLAYER:SetLegitSpeed( nTop )
	if not ValidTimer( self ) then return end
	if self.Style != _C.Style.Legit then return end

	if not self.LegitTopSpeed or (self.LegitTopSpeed and self.LegitTopSpeed != nTop) then
		self.LegitTopSpeed = nTop

		Core.Util:SetPlayerLegit( self, nTop )
		Core:Send( self, "Timer", { "Legit", nTop } )
	end
end

function Timer:Finish( ply, nTime )
	local szMessage = ply.Style == _C.Style.Bonus and "StyleBonusFinish" or "TimerFinish"
	local nDifference = ply.Record > 0 and nTime - ply.Record or nil
	local szSlower = nDifference and ("(" .. (nDifference < 0 and "-" or "+") .. Timer:Convert( math.abs( nDifference ) ) .. ")") or ""
	local varSync, szSync = SMgrAPI:GetFinishingSync( ply ), ""
	if varSync then szSync = " (With " .. varSync .. "% Sync)" ply.LastSync = varSync end

	Core:Send( ply, "Print", { "Timer", Lang:Get( szMessage, { Timer:Convert( nTime ), szSlower } ) } )

	local OldRecord = ply.Record or 0
	if ply.Record != 0 and nTime >= ply.Record then return end

	ply.Record = nTime
	ply.SpeedRequest = ply.Style
	ply:SetNWFloat( "Record", ply.Record )

	Timer:AddRecord( ply, nTime, OldRecord )
end

local RC = {}
local TC = {}
local IR = {}

local function InitializeStyleStats()
    for styleName, styleValue in pairs(_C.Style) do
        RC[styleValue] = { Total = 0, Count = 0, Average = 0 }
        TC[styleValue] = {}
    end
end

InitializeStyleStats()

local function GetAverage(nStyle)
    return RC[nStyle].Average
end

local function CalcAverage(nStyle)
    if RC[nStyle].Count > 0 then
        RC[nStyle].Average = RC[nStyle].Total / RC[nStyle].Count
    else
        RC[nStyle].Average = 0
    end
end

local function PushTime(nStyle, nTime, nOld, bAvg)
    if nOld then
        RC[nStyle].Total = RC[nStyle].Total + (nTime - nOld)
    else
        RC[nStyle].Total = RC[nStyle].Total + nTime
        RC[nStyle].Count = RC[nStyle].Count + 1
    end

    if bAvg then
        CalcAverage(nStyle)
    end
end

local function GetRecordCount(nStyle)
    return TC[nStyle] and #TC[nStyle] or 0
end

local function UpdateRecords(ply, nPos, nNew, nOld, data)
    local tab = {
        ply:SteamID(),
        data[1]["szPlayer"],
        nNew,
        Core:Null(data[1]["szDate"]),
        nil
    }
    ply.SpeedPos = nPos

    if nOld == 0 then
        table.insert(TC[ply.Style], nPos, tab)
    else
        local nID = -1
        for id, sub in pairs(TC[ply.Style]) do
            if sub[1] == tab[1] then
                nID = id
                break
            end
        end

        if nID >= 0 then
            table.remove(TC[ply.Style], nID)
            table.insert(TC[ply.Style], nPos, tab)
        else
        end
    end
end

function Timer:LoadRecords()
    local queriesCompleted = 0
    local totalQueries = 2 + #TC

    -- Load statistics for each style from the database
    for id, _ in pairs(RC) do
        MySQL:Start("SELECT SUM(nTime) AS nSum, COUNT(nTime) AS nCount, AVG(nTime) AS nAverage FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. id, function(Query)
            if Query and #Query > 0 then
                RC[id].Total = tonumber(Query[1]["nSum"]) or 0
                RC[id].Count = tonumber(Query[1]["nCount"]) or 0
                RC[id].Average = tonumber(Query[1]["nAverage"]) or 0
            else
                RC[id].Total = 0
                RC[id].Count = 0
                RC[id].Average = 0
            end
            queriesCompleted = queriesCompleted + 1
            if queriesCompleted == totalQueries then
                -- All queries completed, perform any post-query operations herez
            end
        end)
    end

    -- Load map-specific settings from the database
    MySQL:Start("SELECT nMultiplier, nBonusMultiplier, nOptions FROM game_map WHERE szMap = '" .. game.GetMap() .. "'", function(Map)
        if Map and #Map > 0 then
            Timer.Multiplier = tonumber(Core:Null(Map[1]["nMultiplier"], 1))
            Timer.BonusMultiplier = tonumber(Core:Null(Map[1]["nBonusMultiplier"], 1))
            Timer.Options = tonumber(Core:Null(Map[1]["nOptions"], 0))
        else
            -- Handle database query error or empty result
            Timer.Multiplier = 1
            Timer.BonusMultiplier = 1
            Timer.Options = 0
        end
        queriesCompleted = queriesCompleted + 1
        if queriesCompleted == totalQueries then
            -- All queries completed, perform any post-query operations here
        end
    end)

    -- Load individual records for each style from the database
    for id, _ in pairs(TC) do
        MySQL:Start("SELECT * FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. id .. " ORDER BY nTime ASC", function(Rec)
            TC[id] = {}
            if Rec and #Rec > 0 then
                for _, data in pairs(Rec) do
                    table.insert(TC[id], { data["szUID"], data["szPlayer"], tonumber(data["nTime"]), Core:Null(data["szDate"]), Core:Null(data["vData"]) })
                end
            end
            queriesCompleted = queriesCompleted + 1
            if queriesCompleted == totalQueries then
                -- All queries completed, perform any post-query operations here
            end
        end)
    end

    for _, id in pairs(_C.Style) do
        if TC[id] and TC[id][1] and TC[id][1][3] then
            IR[id] = tonumber(TC[id][1][3])
        end
    end
end

function Timer:AddRecord(ply, nTime, nOld)
    local nAverage = GetAverage(ply.Style)

    MySQL:Start(
        "SELECT nTime FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND szUID = '" .. ply:SteamID() .. "' AND nStyle = " .. ply.Style,
        function(OldEntry)
            if Core:Assert(OldEntry, "nTime") then
                PushTime(ply.Style, nTime, nOld, true)
                MySQL:Start(
                    "UPDATE game_times SET szPlayer = " .. sql.SQLStr(ply:Name()) .. ", nTime = " .. nTime .. ", szDate = '" .. Timer:GetDate() .. "' WHERE szMap = '" .. game.GetMap() .. "' AND szUID = '" .. ply:SteamID() .. "' AND nStyle = " .. ply.Style
                )
            else
                PushTime(ply.Style, nTime, nil, true)
                MySQL:Start(
                    "INSERT INTO game_times VALUES ('" .. ply:SteamID() .. "', " .. sql.SQLStr(ply:Name()) .. ", '" .. game.GetMap() .. "', " .. ply.Style .. ", " .. nTime .. ", 0, NULL, '" .. Timer:GetDate() .. "')"
                )
            end
        end
    )

    timer.Simple(
        0.25,
        function()
            Timer:RecalculatePoints(ply.Style)
            Player:UpdateRank(ply)

            local nID = 1
            MySQL:Start(
                "SELECT t1.*, (SELECT COUNT(*) + 1 FROM game_times AS t2 WHERE szMap = '" .. game.GetMap() .. "' AND t2.nTime < t1.nTime AND nStyle = " .. ply.Style .. ") AS nRank FROM game_times AS t1 WHERE t1.szUID = '" .. ply:SteamID() .. "' AND t1.szMap = '" .. game.GetMap() .. "' AND t1.nStyle = " .. ply.Style,
                function(Rank)
                    if Rank and Rank[1] and Rank[1]["nRank"] then
                        nID = tonumber(Rank[1]["nRank"])
                    end
                    UpdateRecords(ply, nID, nTime, nOld, Rank)

                    Core:Send(ply, "Timer", {"Record", nTime, nil, true})
                    Player:ReloadSubRanks(ply, nAverage)

                    local Data = {Core:StyleName(ply.Style) .. " | ", "You"}
                    local nRec = GetRecordCount(ply.Style)

                    local szID, descCount = "", 4
                    if nID <= 10 then
                        szID = "TimerWRFirst"
                        if nOld ~= 0 then
                            szID = "TimerWRNext"
                            descCount = 5
                        end
                        Data[3] = "#" .. nID
                        Data[descCount] = Timer:Convert(nTime)
                        Data[descCount + 1] = nID .. " / " .. nRec
                        Timer:UpdateWRs(player.GetHumans())
                        Player:SetRankMedal(ply, nID)
                    else
                        szID = "TimerPBFirst"
                        if nOld ~= 0 then
                            szID = "TimerPBNext"
                            descCount = 5
                        end
                        Data[3] = Timer:Convert(nTime)
                        Data[descCount] = nID .. " / " .. nRec
                    end

                    if nID == 1 then
                        Timer:RecalculateInitial(ply.Style)
                    end

                    if
                        nID == 1 and
                            (ply.Style == _C.Style.Normal or ply.Style == _C.Style.Bonus or ply.Style == _C.Style.Segment) and
                            DISCORD_WR_WEBHOOK
                     then
                        local playerName = ply:Nick()
                        local playerSteam = ply:SteamID()
                        local playerSteam64 = ply:SteamID64()
                        local time = Timer:Convert(nTime)
                        local sync = (ply.LastSync or 0) .. "%"
                        local jumps = Core.Util:GetPlayerJumps(ply)
                        local embedColor =
                            (ply.Style == _C.Style.Normal and Color(0, 165, 255) or Color(255, 255, 0)) -- Blue for Normal, Yellow for Bonus and Segment
                        local title = "New " .. Core:StyleName(ply.Style) .. " Record | " .. game.GetMap()
                        local description =
                            string.format(
                            "[%s](https://steamcommunity.com/profiles/%s) (%s) has the #1 record!\nTime: %s\nSync: %s\nJumps: %d",
                            playerName,
                            playerSteam64,
                            playerSteam,
                            time,
                            sync,
                            jumps
                        )
                        local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                        local compiled = {
                            content = nil,
                            embeds = {
                                {
                                    title = title,
                                    description = description,
                                    color =
                                        embedColor.r * 65536 + embedColor.g * 256 + embedColor.b, -- Convert Color to integer for Discord color representation
                                    timestamp = timestamp
                                }
                            },
                            attachments = {}
                        }

                        reqwest(
                            {
                                method = "POST",
                                url = DISCORD_WR_WEBHOOK,
                                body = util.TableToJSON(compiled, false),
                                headers = {
                                    ["content-type"] = "application/json",
                                    ["user-agent"] = "insomnia/2021.6.0"
                                },
                                timeout = 5,
                                success = function(status, body, headers)
                                    -- Handle success if needed
                                end,
                                failed = function(err, errExt)
                                    -- Handle failure if needed
                                end
                            }
                        )
                    end

                    local p = Bot.PerStyle[ply.Style] or 0
                    if p > 0 and nID <= p then
                        Bot:SetWRPosition(ply.Style)
                    end
                    Core:Send(ply, "Print", {"Timer", Lang:Get(szID, Data)})

                    Data[2] = ply:Name()
                    Core:Broadcast("Print", {"Timer", Lang:Get(szID, Data)}, ply)
                end
            )
        end
    )
end

function Timer:AddSpeedData(ply, tab)
    if ply.Record and ply.Record > 0 and ply.SpeedRequest then
        local szData = Core.Util:TabToString({math.floor(tab[1]), math.floor(tab[2]), Core.Util:GetPlayerJumps(ply), ply.LastSync or 0})
        timer.Simple(
            0.25,
            function()
                MySQL:Start("UPDATE game_times SET vData = '" .. szData .. "' WHERE szUID = '" .. ply:SteamID() .. "' AND szMap = '" .. game.GetMap() .. "' AND nStyle = " .. ply.SpeedRequest)
            end
        )

        if ply.SpeedPos and ply.SpeedPos > 0 and TC[ply.Style] and TC[ply.Style][ply.SpeedPos] and TC[ply.Style][ply.SpeedPos][1] == ply:SteamID() then
            TC[ply.Style][ply.SpeedPos][5] = Core:Null(szData)
        end
    end
end

function Timer:AddPlays()
    Timer.PlayCount = 1

    local Check = sql.Query("SELECT szMap, nPlays FROM game_map WHERE szMap = '" .. game.GetMap() .. "'")
    if Core:Assert(Check, "szMap") then
        Timer.PlayCount = tonumber(Check[1]["nPlays"]) + 1
        sql.Query("UPDATE game_map SET nPlays = nPlays + 1 WHERE szMap = '" .. game.GetMap() .. "'")
    end
end

function Timer:RecalculatePoints(nStyle)
    local nMult = Timer:GetMultiplier(nStyle)
    MySQL:Start("UPDATE game_times SET nPoints = " .. nMult .. " * (" .. GetAverage(nStyle) .. " / nTime) WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle)

    local nFourth, nDouble = nMult / 4, nMult * 2
    MySQL:Start("UPDATE game_times SET nPoints = " .. nDouble .. " WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle .. " AND nPoints > " .. nDouble)
    MySQL:Start("UPDATE game_times SET nPoints = " .. nFourth .. " WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. nStyle .. " AND nPoints < " .. nFourth)
end

function Timer:RecalculateInitial( id )
	if TC[ id ] and TC[ id ][ 1 ] and TC[ id ][ 1 ][ 3 ] then
		IR[ id ] = tonumber( TC[ id ][ 1 ][ 3 ] )
	end

	Core:Broadcast( "Timer", { "Initial", IR } )
	WRSFX_Broadcast()
end

function Timer:RecalculateInitial(id)
    if TC[id] and TC[id][1] and TC[id][1][3] then
        IR[id] = tonumber(TC[id][1][3])
    end
    Core:Broadcast("Timer", {"Initial", IR})
    WRSFX_Broadcast()
end

function Timer:SendInitialRecords(ply)
    Core:Send(ply, "Timer", {"Initial", IR})
end

function Timer:GetRecordID(nTime, nStyle)
    if TC and TC[nStyle] then
        for pos, data in ipairs(TC[nStyle]) do
            if nTime <= data[3] then
                return pos
            end
        end
        return #TC[nStyle] + 1
    else
        return 0
    end
end

function Timer:GetRecordList(nStyle, nPage)
    if not nPage or type(nPage) ~= "number" then
        nPage = 1
    end

    local tab = {}
    local a = 7 * nPage - 7

    for i = 1, 7 do
        local index = i + a
        if TC[nStyle] and TC[nStyle][index] then
            tab[index] = TC[nStyle][index]
        end
    end

    return tab
end

function Timer:GetRecordCount(nStyle)
    return RC[nStyle].Count or 0
end

function Timer:GetAverage(nStyle)
    return GetAverage(nStyle)
end

function Timer:GetMultiplier(nStyle)
    return nStyle == _C.Style.Bonus and Timer.BonusMultiplier or Timer.Multiplier
end

function Timer:GetPointsForMap(nTime, nStyle)
    if nTime == 0 then return 0 end

    local m = Timer:GetMultiplier(nStyle)
    local p = m * (GetAverage(nStyle) / nTime)

    if p > m * 2 then
        p = m * 2
    elseif p < m / 4 then
        p = m / 4
    end

    return p
end

function Timer:SendWRList(ply, nPage, nStyle, szMap)
    if szMap then
        Player:SendRemoteWRList(ply, szMap, nStyle, nPage, true)
    else
        UI:SendToClient(ply, "wr", Timer:GetRecordList(nStyle, nPage), szMap, nStyle, nPage, true)
    end
end

function Timer:GetWR(nStyle)
    if TC[nStyle] and TC[nStyle][1] then
        local wr = TC[nStyle][1]
        return {wr[2], wr[3]}
    else
        return {}
    end
end

function Timer:UpdateWRs(ply)
    local wrs = {}
    for k, v in pairs(_C.Style) do
        wrs[v] = self:GetWR(v)
    end
    Core:Send(ply, "update_wr", wrs)
end

--[[util.AddNetworkString "SyncMeter"

local Sync = {}
Sync.SyncMeter = true

function Sync.SetupMove(p, mv, cmd)
    if not p.lastang then
        p.lastang = p:EyeAngles()
        p.lastkey = 0
        p.lastdir = 0
        p.strafes = 0
        p.strafeavg = 0
        p.gstrafes = 0
        return
    end

    if not p:OnGround() and p:GetMoveType() ~= MOVETYPE_LADDER and p:GetMoveType() ~= MOVETYPE_NOCLIP and p:WaterLevel() < 1 then
        local ang = p:EyeAngles()
        local dir = (ang.y > p.lastang.y and -1) or (ang.y < p.lastang.y and 1) or 0
        local key = (cmd:GetSideMove() > 0 and 1) or (cmd:GetSideMove() < 0 and -1) or 0

        if dir ~= 0 then
            p.strafes = p.strafes + 1
            if dir == key then
                p.gstrafes = p.gstrafes + 1
            end
            p.strafeavg = p.gstrafes / p.strafes
        end

        p.lastdir = dir
        p.lastang = ang
        p.lastkey = key
    end
end

function Sync.ResetSync(p)
	p.lastang = p:EyeAngles()
	p.lastkey = 0
	p.lastdir = 0
	p.strafes = 0
	p.strafeavg = 0
	p.gstrafes = 0
end

if Sync.SyncMeter then
	hook.Add("SetupMove","Strafe_Meter",Sync.SetupMove)
	hook.Add("PlayerSpawn","ResetSync",Sync.ResetSync)
end

function Sync.SendSync()
    for _, p in pairs(player.GetAll()) do
        if p.strafeavg and p.strafeavg ~= p.oldstrafeavg then
            net.Start("SyncMeter")
                net.WriteEntity(p)
                net.WriteDouble(p.strafeavg)
            net.Broadcast()
            p.oldstrafeavg = p.strafeavg -- Store the last sent strafe average to avoid resending the same value
        end
    end
end

if Sync.SyncMeter then
	timer.Create("SendSync",2,0,Sync.SendSync)
end

function Sync.ResetSync(p)
	p.lastang = p:EyeAngles()
	p.lastkey = 0
	p.lastdir = 0
	p.strafes = 0
	p.strafeavg = 0
	p.gstrafes = 0
end

local function SendSyncPeriodically()
    Sync.SendSync()
    -- Adjust the delay based on your desired tick interval
    local tickInterval = engine.TickInterval() / 0.01
    local delay = 10 * tickInterval
    timer.Simple(delay, SendSyncPeriodically)
end

-- Call the function to start the periodic syncing
SendSyncPeriodically()--]]

local function FixRNG(ply, data, cmd)
    local vel = data:GetVelocity()

    -- Check if the player is moving only vertically (on a ladder)
    if vel:Length2D() == 0 and math.abs(vel.z - ply:GetJumpPower()) == 258 then
        vel.z = ply:GetJumpPower() -- Reset vertical velocity to jump power
        data:SetVelocity(vel) -- Update the velocity in the move data
    end
end
hook.Add("SetupMove", "FixRNG", FixRNG)