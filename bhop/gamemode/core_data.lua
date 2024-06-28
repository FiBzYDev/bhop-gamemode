SQL = {}
SQL.Use = true
MySQL = MySQL or {}
MySQL.queries = {}
UI, DATA = {}, {}
local db = db or false

util.AddNetworkString("userinterface.network")
require("mysqloo")

Core = Core or {}
Core.Protocol = "SecureTransfer"
Core.Protocol2 = "BinaryTransfer"
Core.Try = 0

util.AddNetworkString(Core.Protocol)
util.AddNetworkString(Core.Protocol2)

-- Core Functions
function Core:Boot()
    Command:Init()
    RTV:Init()
    Core:LoadZones()
    Timer:LoadRecords()
    Player:LoadRanks()
    Player:LoadTop()
    Timer:AddPlays()
end

function Core:Unload(force)
    Bot:Save(force)
end

function Core:LoadZones()
    local zones = sql.Query("SELECT nType, vPos1, vPos2 FROM game_zones WHERE szMap = '" .. game.GetMap() .. "'")
    if not zones then return end

    Zones.Cache = {}
    for _, data in ipairs(zones) do
        table.insert(Zones.Cache, {
            Type = tonumber(data["nType"]),
            P1 = util.StringToType(tostring(data["vPos1"]), "Vector"),
            P2 = util.StringToType(tostring(data["vPos2"]), "Vector")
        })
    end
end

function Core:AwaitLoad(retry)
    if not retry then
        Zones:SetupMap()
        Bot:Setup()
        Core:Optimize()

        if SQL.Use then
            if timer.Exists("SQLCheck") then
                timer.Remove("SQLCheck")
            end

            timer.Simple(0, function() Core:StartSQL() end)
            timer.Create("SQLCheck", 10, 0, Core.SQLCheck)
        else
            SQL:LoadNoMySQL()
        end
    end

    if #Zones.Cache > 0 then
        Zones:Setup()
        Core.Try = 0
    else
        if Core.Try < 100 then
            Core.Try = Core.Try + 1
            Core:LoadZones()
            timer.Simple(60, function() Core:AwaitLoad(true) end)
        end
    end
end

function Core:StartSQL()
    if not SQL.Use then return end

    local function onComplete()
        Admin:LoadAdmins()
        Admin:LoadNotifications()
        Core.SQLChecking = nil
    end

    SQL:CreateObject(onComplete)
    timer.Simple(60, function() Core.SQLChecking = nil end)
end

function Core.SQLCheck()
    if not SQL.Use then return end

    if (not Admin.Loaded or SQL.Error) and not Core.SQLChecking then
        SQL.Error = nil
        Core.SQLChecking = true
        Core:StartSQL()
    end
end

function Core:Assert(varType, szType)
    return varType and type(varType) == "table" and varType[1] and type(varType[1]) == "table" and varType[1][szType] or false
end

function Core:Null(varInput, varAlternate)
    return varInput and type(varInput) == "string" and varInput ~= "NULL" and varInput or varAlternate
end

function Core:Print(szPrefix, szText)
    print("[" .. (szPrefix or "Core") .. "]", szText)
end

function Core:Send(ply, szAction, varArgs)
    net.Start(Core.Protocol)
    net.WriteString(szAction)

    if varArgs and type(varArgs) == "table" then
        net.WriteBool(true)
        net.WriteTable(varArgs)
    else
        net.WriteBool(false)
    end

    net.Send(ply)
end

function Core:Broadcast(szAction, varArgs, varExclude)
    net.Start(Core.Protocol)
    net.WriteString(szAction)

    if varArgs and type(varArgs) == "table" then
        net.WriteBool(true)
        net.WriteTable(varArgs)
    else
        net.WriteBool(false)
    end

    if varExclude and (type(varExclude) == "table" or (IsValid(varExclude) and varExclude:IsPlayer())) then
        net.SendOmit(varExclude)
    else
        net.Broadcast()
    end
end

local function coreHandle(ply, szAction, varArgs)
    if szAction == "Admin" then
        Admin:HandleClient(ply, varArgs)
    elseif szAction == "Speed" then
        Timer:AddSpeedData(ply, varArgs)
    elseif szAction == "WRList" then
        Timer:SendWRList(ply, varArgs[1], varArgs[2], varArgs[3])
    elseif szAction == "MapList" then
        RTV:GetMapList(ply, varArgs[1])
    elseif szAction == "Vote" then
        RTV:ReceiveVote(ply, varArgs[1], varArgs[2])
    elseif szAction == "TopList" then
        Player:SendTopList(ply, varArgs[1], varArgs[2])
    elseif szAction == "Checkpoints" then
        Timer:CPHandleCallback(ply, varArgs[1], varArgs[2], varArgs[3])
    elseif szAction == 'abc' then
        JAC:RegisterDetection(ply, 'no_startcommand')
    end
end

local function coreReceive(_, ply)
    local szAction = net.ReadString()
    local bTable = net.ReadBool()
    local varArgs = bTable and net.ReadTable() or {}

    if IsValid(ply) and ply:IsPlayer() then
        coreHandle(ply, szAction, varArgs)
    end
end
net.Receive(Core.Protocol, coreReceive)

local function binaryReceive(_, ply)
    local length = net.ReadUInt(32)
    local data = net.ReadData(length)

    if IsValid(ply) then
        local target = Admin.Screenshot[ply]
        if IsValid(target) then
            net.Start(Core.Protocol2)
            net.WriteString("Data")
            net.WriteUInt(length, 32)
            net.WriteData(data, length)
            net.Send(target)
            Admin.Screenshot[ply] = nil
        end
    end
end
net.Receive(Core.Protocol2, binaryReceive)

-- SQL Functions
SQL.Available = true
local SQLObject
local SQLDetails = {
    Host = "176.9.2.59",
    Port = 3306,
    User = "u177_sYbfn4GCtV",
    Pass = "^6^qU4lCxT2r^Kh3v@=@i18T",
    Database = "s177_kawaii"
}

local function sqlPrint(msg, arg)
    print(msg, arg or "")
end

local function sqlConnectSuccess(callback)
    SQL.Available = true
    SQL.Busy = false
    callback()
end

local function sqlConnectFailure(_, err)
    SQL.Available = false
    SQL.Busy = false
    print("SQL connection failed:", err)
end

local function sqlQuery(query, callback, args)
    if not SQLObject or not SQL.Available then
        return sqlPrint("No valid SQLObject to execute query: ", query)
    elseif not query or query == "" then
        return sqlPrint("No valid SQLQuery to execute")
    end

    local q = SQLObject:query(query)
    
    function q:onSuccess(data)
        if callback then
            callback(data, args)
        end
    end
    
    function q:onError(err)
        if callback then
            callback(nil, args, err)
        end

        if string.find(string.lower(err), "lost connection", 1, true) or string.find(string.lower(err), "gone away", 1, true) then
            SQL.Error = true
            return false
        end
    end

    q:start()
end

local function sqlExecute(query, callback, args)
    sqlQuery(query, function(data, varArgs, err)
        callback(data, varArgs, err)
    end, args)
end

function SQL:CreateObject(callback)
    local function selectCallback()
        sqlConnectSuccess(callback)
    end

    SQL.Busy = true

    SQLObject = mysqloo.connect(SQLDetails.Host, SQLDetails.User, SQLDetails.Pass, SQLDetails.Database, SQLDetails.Port)
    SQLObject.onConnected = selectCallback
    SQLObject.onConnectionFailed = sqlConnectFailure
    SQLObject:connect()
end

function SQL:Prepare(query, args, noQuote)
    if not SQL.Use then
        return SQL:LocalPrepare(query, args, noQuote)
    end

    if not SQLObject or not SQL.Available then
        return { Execute = function() end }
    end

    if args and #args > 0 then
        for i = 1, #args do
            local argType = type(args[i])
            local arg = ""

            if argType == "string" and not tonumber(args[i]) then
                arg = SQLObject:escape(args[i])
                if not noQuote then
                    arg = "'" .. arg .. "'"
                end
            elseif argType == "number" or (argType == "string" and tonumber(args[i])) then
                arg = args[i]
            else
                arg = tostring(args[i]) or ""
            end
            
            query = string.gsub(query, "{" .. i - 1 .. "}", arg)
        end
    end
    
    return { Query = query, Execute = function(self, callback, varArg) sqlExecute(self.Query, callback, varArg) end }
end

function SQL:LocalPrepare(query, args, noQuote)
    if not SQL.LoadedSQLite then
        return { Execute = function() end }
    end

    if args and #args > 0 then
        for i = 1, #args do
            local argType = type(args[i])
            local arg = ""

            if argType == "string" and not tonumber(args[i]) then
                arg = sql.SQLStr(args[i])
                if noQuote then
                    arg = string.sub(arg, 2, string.len(arg) - 1)
                end
            elseif argType == "number" or (argType == "string" and tonumber(args[i])) then
                arg = args[i]
            else
                arg = tostring(args[i]) or ""
            end

            query = string.gsub(query, "{" .. i - 1 .. "}", arg)
        end
    end

    local data, err
    local result = sql.Query(query)

    if result then
        for id, item in ipairs(result) do
            for key, value in pairs(item) do
                if tonumber(value) then
                    result[id][key] = tonumber(value)
                end
            end
        end
        data = result
    else
        local statement = string.sub(query, 1, 6)
        if statement == "SELECT" then
            err = sql.LastError() or "Unknown error"
        else
            data = true
        end
    end

    return { Query = query, Execute = function(self, callback, varArg) callback(data, varArg, err) end }
end

-- UI Functions
function UI:SendToClient(client, uiId, ...)
    local net_contents = {...}

    net.Start("userinterface.network")
    net.WriteString(uiId)
    net.WriteTable(net_contents)

    if not client then
        net.Broadcast()
    else
        net.Send(client)
    end
end

function UI:AddListener(id, func)
    DATA[id] = func
end

net.Receive("userinterface.network", function(_, cl)
    local network_id = net.ReadString()
    local network_data = net.ReadTable()

    local listenerFunc = DATA[network_id]
    if listenerFunc then
        listenerFunc(cl, network_data)
    else
        print("Error: No listener found for UI ID", network_id)
    end
end)

-- MySQL Functions
local function connect()
    if db and db:status() == mysqloo.DATABASE_CONNECTED then
        return
    end

    db = mysqloo.connect(SQLDetails.Host, SQLDetails.User, SQLDetails.Pass, SQLDetails.Database, SQLDetails.Port)

    function db:onConnected()
        print("Database connected successfully!")
        MySQL:StartUp()
        MySQL:ProcessQueuedQueries()
    end

    function db:onConnectionFailed(err)
        print("Database connection failed:", err)
        timer.Simple(20, connect)
    end

    db:connect()
end

function MySQL:StartUp()
    -- Add any initialization code for MySQL
end

function MySQL:ProcessQueuedQueries()
    self.queuedQueries = self.queuedQueries or {}

    for _, queryData in ipairs(self.queuedQueries) do
        MySQL:Start(queryData.query, queryData.callback)
    end

    self.queuedQueries = {}
end

function MySQL:Start(query, callback)
    if not db or db:status() ~= mysqloo.DATABASE_CONNECTED then
        print("Error: Database connection not established.")
        return
    end

    local q = db:query(query)

    function q:onSuccess(data)
        if callback then
            callback(data)
        end
    end

    function q:onError(err)
        print("Query error:", err)
    end

    q:start()
end

function MySQL:Escape(str)
    return sql.SQLStr(str)
end

connect()