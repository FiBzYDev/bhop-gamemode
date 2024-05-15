SQL = {}
SQL.Use = true
MySQL = MySQL or {}
MySQL.queries = {}
UI, DATA = {}, {}
local db = db or false

util.AddNetworkString "userinterface.network"

require "mysqloo"

Core = Core or {}
Core.Protocol = "SecureTransfer"
Core.Protocol2 = "BinaryTransfer"
Core.Try = 0

util.AddNetworkString( Core.Protocol )
util.AddNetworkString( Core.Protocol2 )

function Core:Boot()
	Command:Init()
	RTV:Init()

	Core:LoadZones()
	Timer:LoadRecords()
	Player:LoadRanks()
	Player:LoadTop()

	Timer:AddPlays()
end

function Core:Unload( bForce )
	Bot:Save( bForce )
end

function Core:LoadZones()
	local zones = sql.Query( "SELECT nType, vPos1, vPos2 FROM game_zones WHERE szMap = '" .. game.GetMap() .. "'" )
	if not zones then return end

	Zones.Cache = {}
	for _,data in pairs( zones ) do
		table.insert( Zones.Cache, {
			Type = tonumber( data[ "nType" ] ),
			P1 = util.StringToType( tostring( data[ "vPos1" ] ), "Vector" ),
			P2 = util.StringToType( tostring( data[ "vPos2" ] ), "Vector" )
		} )
	end
end

function Core:AwaitLoad( bRetry )
	if not bRetry then
		Zones:SetupMap()
		Bot:Setup()
		Core:Optimize()

		if SQL.Use then
			if timer.Exists( "SQLCheck" ) then
				timer.Destroy( "SQLCheck" )
			end

			timer.Simple( 0, function() Core:StartSQL() end )
			timer.Create( "SQLCheck", 10, 0, Core.SQLCheck )
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
			
			timer.Simple( 60, function() Core:AwaitLoad( true ) end )
		end
	end
end

function Core:StartSQL()
	if not SQL.Use then return end

	local function OnComplete()
		Admin:LoadAdmins()
		Admin:LoadNotifications()

		Core.SQLChecking = nil
	end
	
	SQL:CreateObject( OnComplete )
	timer.Simple( 60, function()
		Core.SQLChecking = nil
	end )
end

function Core.SQLCheck()
	if not SQL.Use then return end

	if (not Admin.Loaded or SQL.Error) and not Core.SQLChecking then
		SQL.Error = nil
		Core.SQLChecking = true
		Core:StartSQL()
	end
end

function Core:Assert( varType, szType )
	if varType and type( varType ) == "table" and varType[ 1 ] and type( varType[ 1 ] ) == "table" and varType[ 1 ][ szType ] then
		return true
	end

	return false
end

function Core:Null( varInput, varAlternate )
	if varInput and type( varInput ) == "string" and varInput != "NULL" then
		return varInput
	end

	return varAlternate or nil
end

function Core:Print( szPrefix, szText )
	print( "[" .. (szPrefix or "Core") .. "]", szText )
end

function Core:Send( ply, szAction, varArgs )
	net.Start( Core.Protocol )
	net.WriteString( szAction )

	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
		net.WriteUInt(32, 16)
	else
		net.WriteBit( false )
	end

	net.Send( ply )
end

function Core:Broadcast( szAction, varArgs, varExclude )
	net.Start( Core.Protocol )
	net.WriteString( szAction )

	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end

	if varExclude and (type( varExlude ) == "table" or (IsValid( varExclude ) and varExclude:IsPlayer())) then
		net.SendOmit( varExclude )
	else
		net.Broadcast()
	end
end

local function CoreHandle( ply, szAction, varArgs )
	if szAction == "Admin" then
		Admin:HandleClient( ply, varArgs )
	elseif szAction == "Speed" then
		Timer:AddSpeedData( ply, varArgs )
	elseif szAction == "WRList" then
		Timer:SendWRList( ply, varArgs[ 1 ], varArgs[ 2 ], varArgs[ 3 ] )
	elseif szAction == "MapList" then
		RTV:GetMapList( ply, varArgs[ 1 ] )
	elseif szAction == "Vote" then
		RTV:ReceiveVote( ply, varArgs[ 1 ], varArgs[ 2 ] )
	elseif szAction == "TopList" then
		Player:SendTopList( ply, varArgs[ 1 ], varArgs[ 2 ] )
	elseif szAction == "Checkpoints" then
		Timer:CPHandleCallback( ply, varArgs[ 1 ], varArgs[ 2 ], varArgs[ 3 ] )
	elseif szAction == 'abc' then 
		JAC:RegisterDetection(ply, 'no_startcommand')
	end
end

local function CoreReceive( _, ply )
	local szAction = net.ReadString()
	local bTable = net.ReadBit() == 1
	local varArgs = {}

	if bTable then
		varArgs = net.ReadTable()
	end

	if IsValid( ply ) and ply:IsPlayer() then
		CoreHandle( ply, szAction, varArgs )
	end
end
net.Receive( Core.Protocol, CoreReceive )

local function BinaryReceive( l, ply )
	local length = net.ReadUInt( 32 )
	local data = net.ReadData( length )

	if IsValid( ply ) then
		local target = Admin.Screenshot[ ply ]
		if IsValid( target ) then
			net.Start( Core.Protocol2 )
			net.WriteString( "Data" )
			net.WriteUInt( length, 32 )
			net.WriteData( data, length )
			net.Send( target )
			
			Admin.Screenshot[ ply ] = nil
		end
	end
end
net.Receive( Core.Protocol2, BinaryReceive )

SQL.Available = true
local SQLObject
local SQLDetails = {
    Host = "yourwebhere",
    Port = 3306,
    User = "root",
    Pass = "",
    Database = "kawaii"
}

local function SQL_Print( szMsg, varArg )
	print( szMsg, varArg or "" )
end

local function SQL_ConnectSuccess( fCallback )
	SQL.Available = true
	SQL.Busy = false

	fCallback()
end

local function SQL_ConnectFailure( obj, szError )
	SQL.Available = false
	SQL.Busy = false
end

local function SQL_Query( szQuery, fCallback, varArgs )
	if not SQLObject or not SQL.Available then
		return SQL_Print( "No valid SQLObject to execute query: ", szQuery )
	elseif not szQuery or szQuery == "" then
		return SQL_Print( "No valid SQLQuery to execute" )
	end

	local query = SQLObject:query( szQuery )
	local function fSuccess( obj, varData )
		if fCallback then
			fCallback( varData, varArgs )
		end
	end
	
	local function fError( obj, szError, szSQL )
		if fCallback then
			fCallback( nil, nil, szError or "" )
		end

		if string.find( string.lower( szError ), "lost connection", 1, true ) or string.find( string.lower( szError ), "gone away", 1, true ) then
			SQL.Error = true
			return false
		end
	end

	query.onSuccess = fSuccess
	query.onError = fError
	query:start()
end

local function SQL_Execute( szQuery, fCallback, varArg )
	SQL_Query( szQuery, function( varData, varArgs, szError )
		fCallback( varData, varArgs, szError )
	end, varArg )
end

function SQL:CreateObject( SQL_ConnectCallback )
	local function SQL_SelectCallback()
		SQL_ConnectSuccess( SQL_ConnectCallback )
	end

	SQL.Busy = true

	SQLObject = mysqloo.connect( SQLDetails.Host, SQLDetails.User, SQLDetails.Pass, SQLDetails.Database, SQLDetails.Port )
	SQLObject.onConnected = SQL_SelectCallback
	SQLObject.onConnectionFailed = SQL_ConnectFailure
	SQLObject:connect()
end	

function SQL:Prepare( szQuery, varArgs, bNoQuote )
	if not SQL.Use then
		return SQL:LocalPrepare( szQuery, varArgs, bNoQuote )
	end

	if not SQLObject or not SQL.Available then
		return { Execute = function() end }
	end

	if varArgs and #varArgs > 0 then
		for i = 1, #varArgs do
			local sort = type( varArgs[ i ] )
			local num = tonumber( varArgs[ i ] )
			local arg = ""

			if sort == "string" and not num then
				arg = SQLObject:escape( varArgs[ i ] )
				if not bNoQuote then
					arg = "'" .. arg .. "'"
				end
			elseif (sort == "string" and num) or (sort == "number") then
				arg = varArgs[ i ]
			else
				arg = tostring( varArgs[ i ] ) or ""
			end
			
			szQuery = string.gsub( szQuery, "{" .. i - 1 .. "}", arg )
		end
	end
	
	return { Query = szQuery, Execute = function( self, fCallback, varArg ) SQL_Execute( self.Query, fCallback, varArg ) end }
end

function SQL:LocalPrepare( szQuery, varArgs, bNoQuote )
	if not SQL.LoadedSQLite then
		return { Execute = function() end }
	end

	if varArgs and #varArgs > 0 then
		for i = 1, #varArgs do
			local sort = type( varArgs[ i ] )
			local num = tonumber( varArgs[ i ] )
			local arg = ""

			if sort == "string" and not num then
				arg = sql.SQLStr( varArgs[ i ] )
				if bNoQuote then
					arg = string.sub( arg, 2, string.len( arg ) - 1 )
				end
			elseif (sort == "string" and num) or (sort == "number") then
				arg = varArgs[ i ]
			else
				arg = tostring( varArgs[ i ] ) or ""
			end

			szQuery = string.gsub( szQuery, "{" .. i - 1 .. "}", arg )
		end
	end

	local varData, szError
	local data = sql.Query( szQuery )

	if data then
		for id,item in pairs( data ) do
			for key,value in pairs( item ) do
				if tonumber( value ) then
					data[ id ][ key ] = tonumber( value )
				end
			end
		end

		varData = data
	else
		local statement = string.sub( szQuery, 1, 6 )
		if statement == "SELECT" then
			szError = sql.LastError() or "Unknown error"
		else
			varData = true
		end
	end

	return { Query = szQuery, Execute = function( self, fCallback, varArg ) fCallback( varData, varArg, szError ) end }
end

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

net.Receive("userinterface.network", function(len, cl)
    local network_id = net.ReadString()
    local network_data = net.ReadTable()

    local listenerFunc = DATA[network_id]
    if listenerFunc then
        listenerFunc(cl, network_data)
    else
        print("Error: No listener found for UI ID", network_id)
    end
end)

function Connect()
    if db and db:status() == mysqloo.DATABASE_CONNECTED then
        return
    end

    db = mysqloo.connect(SQLDetails.Host, SQLDetails.User, SQLDetails.Pass, SQLDetails.Database, SQLDetails.Port)

    function db:onConnected()
        --print("Database connected successfully!")
        MySQL:StartUp()
        MySQL:ProcessQueuedQueries()
    end

    function db:onConnectionFailed(err)
        print("Database connection failed:", err)
        timer.Simple(20, Connect)
    end

    db:connect()
end

function MySQL:StartUp()
    -- Add any initialization code for MySQL
end

function MySQL:ProcessQueuedQueries()
    if not self.queuedQueries then
        self.queuedQueries = {}  -- Initialize queuedQueries as an empty table if it's nil
    end

    for _, queryData in ipairs(self.queuedQueries) do
        MySQL:Start(queryData.query, queryData.callback)
    end

    self.queuedQueries = {}  -- Clear the queued queries
end

function MySQL:Start(query, callback)
    if not db or db:status() ~= mysqloo.DATABASE_CONNECTED then
        print("Error: Database connection not established.")
        return
    end

    local q = db:query(query)

    function q:onSuccess(data)
        --print("Query successful")
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

Connect()