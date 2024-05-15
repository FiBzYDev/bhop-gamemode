local Cache = {
    T_Data = {
		[_C.Style.Normal] = {},
		[_C.Style.SW] = {},
		[_C.Style.HSW] = {},
		[_C.Style["W-Only"]] = {},
		[_C.Style["A-Only"]] = {},
		[_C.Style["Easy Scroll"]] = {},
		[_C.Style.Legit] = {},
		[_C.Style.Bonus] = {}
    },
    T_Mode = _C.Style.Normal,
    M_Data = {},
    M_Version = 0,
    M_Name = _C.GameType .. "-bhop.txt",
    S_Data = { Contains = nil, Bot = false, Player = "Unknown", Start = nil, Record = nil },
    V_Data = {},
    R_Data = {},
    L_Data = {},
    C_Data = {},
    H_Data = {}
}

local CS_LocalList = {}
local CS_RemoteList = {}
local CS_Type = 3

local function CS_Clear()
	CS_LocalList = {}
	CS_RemoteList = {}
	Cache.S_Data = { Contains = nil, Bot = false, Player = "Unknown", Start = nil, Record = nil }
	CS_Type = 3
	Timer:SpectateUpdate()
	Timer:SpectateData( {}, true, 0, true )
end

local function CS_Mode( nMode )
	CS_Type = nMode
	if CS_Type == 3 then
		CS_Clear()
	end
end

local function CS_Remote( varList )
	CS_RemoteList = varList
	Timer:SpectateData( varList, true, #varList )
end

local function CS_Viewer( bLeave, szName, szUID )
	if not bLeave then
		if not CS_LocalList[ szUID ] or CS_LocalList[ szUID ] != szName then
			CS_LocalList[ szUID ] = szName
		end
	else
		if CS_LocalList[ szUID ] then
			CS_LocalList[ szUID ] = nil
		end
	end

	local nCount = 0
	for _,s in pairs( CS_LocalList ) do
		nCount = nCount + 1
	end

	Timer:SpectateData( CS_LocalList, false, nCount )
end

local function CS_Player( nTimer, nRecord, nServer, varList )
	if nServer then Timer:Sync( nServer ) end
	if varList then if type( varList ) == "table" and #varList > 0 then CS_Remote( varList ) end else CS_Remote( {} ) end
	Cache.S_Data.Bot = false
	Cache.S_Data.Start = nTimer and nTimer + Timer:GetDifference() or nil
	Cache.S_Data.Best = nRecord or 0
	Cache.S_Data.Contains = true
	Timer:SpectateUpdate()
end

local function CS_Bot( nTimer, szName, nRecord, nServer, varList )
	if nServer then Timer:Sync( nServer ) end
	if varList then if type( varList ) == "table" and #varList > 0 then CS_Remote( varList ) end else CS_Remote( {} ) end
	Cache.S_Data.Bot = true
	Cache.S_Data.Player = szName or "Bot"
	Cache.S_Data.Start = nTimer and nTimer + Timer:GetDifference() or nil
	Cache.S_Data.Best = nRecord or 0
	Cache.S_Data.Contains = true
	Timer:SpectateUpdate()
end


function Cache:S_GetType()
	return CS_Type
end

function Cache:M_Load()
	local data = file.Read( Cache.M_Name, "DATA" )
	local version = tonumber( string.sub( data, 1, 5 ) )
	if not version then return end
	local remain = util.Decompress( string.sub( data, 6 ) )
	if not remain then return end
	local tab = util.JSONToTable( remain )

	if #tab > 0 then
		Cache.M_Version = version
		Cache.M_Data = tab
		Cache:M_Update()
	end
end

function Cache:M_Save( varList, nVersion, bOpen )
	Cache.M_Data = varList or {}
	Cache.M_Version = nVersion
	Cache:M_Update()

	if #Cache.M_Data > 0 then
		local data = util.Compress( util.TableToJSON( Cache.M_Data ) )
		if not data then return end
		
		file.Write( Cache.M_Name, string.format( "%.5d", nVersion ) .. data )
		if bOpen then
			Window:Open( "Nominate", { nVersion } )
		end
	else
		Window:Close()
	end
end

function Cache:M_Update()
	for i,d in pairs( Cache.M_Data ) do
		Cache.M_Data[ i ][ 2 ] = tonumber( d[ 2 ] )
	end
end

function Cache:V_Update( varList )
	if Window:IsActive( "Vote" ) then
		local wnd = Window:GetActive()
		wnd.Data.Votes = varList
		wnd.Data.Update = true
	end
end

function Cache:V_InstantVote( nID )
	if Window:IsActive( "Vote" ) then
		local wnd = Window:GetActive()
		wnd.Data.InstantVote = nID
	end
end

function Cache:V_VIPExtend()
	if Window:IsActive( "Vote" ) then
		local wnd = Window:GetActive()
		wnd.Data.EnableExtend = true
	end
end

function Cache:L_Check( szMap )
	if not Cache.L_Data or #Cache.L_Data == 0 then return false end
	
	for _,data in pairs( Cache.L_Data ) do
		if data[ 1 ] == szMap then
			return true
		end
	end
	
	return false
end

Link = {}
Link.Protocol = "SecureTransfer"
Link.Protocol2 = "BinaryTransfer"

function Link:Print(szPrefix, varText)
    if not varText then return end
    if type(varText) ~= "table" then
        varText = { varText }
    end

    local currentTime = CurTime()
    local hueOffset = 30  -- Offset to adjust rainbow colors for each letter

    -- Rainbow effect for szPrefix
    local rainbowPrefix = {}  -- Table to store rainbow-colored characters
    for i = 1, #szPrefix do
        local hue = (currentTime * 120 + i * hueOffset) % 360
        local color = HSVToColor(hue, 1, 1)
        table.insert(rainbowPrefix, color)
        table.insert(rainbowPrefix, szPrefix:sub(i, i))  -- Insert each character with its corresponding color
    end

    -- Add separator (" | ") with white color
    table.insert(rainbowPrefix, Color(255, 255, 255))  -- White color
    table.insert(rainbowPrefix, " | ")

    -- Add varText to rainbowPrefix
    for _, text in ipairs(varText) do
        table.insert(rainbowPrefix, text)
    end

    -- Print the combined rainbow-colored text with separator
    chat.AddText(unpack(rainbowPrefix))
end

function Link:Send( szAction, varArgs )
	net.Start( Link.Protocol )
	net.WriteString( szAction )
	
	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
		local tableSize = table.Count(varArgs)
		net.WriteUInt(tableSize, 16)
	else
		net.WriteBit( false )
	end

	net.SendToServer()
end

local function HandleGUIOpen(varArgs)
    Window:Open(tostring(varArgs[1]), varArgs[2])
end

local function HandleUpdateWR(varArgs)
    WorldRecords = varArgs
end

local function HandleJumpUpdate(varArgs)
    varArgs[1].player_jumps = varArgs[2]
end

local function HandleGUIUpdate(varArgs)
    Window:Update(tostring(varArgs[1]), varArgs[2])
end

local function HandlePrint(varArgs)
    Link:Print(tostring(varArgs[1]), varArgs[2])
end

local function HandleMainMenu(varArgs)
    local isLegacy = varArgs[1]
    if isLegacy then
        BHopTimerLegacy()
        BHopTimer:Open()
    else
        BHopTimer:Open()
    end
end

local function HandleHelpMenu(szAction, varArgs)
    if szAction == "Help" then
        Help:OpenRules()
    elseif szAction == "Rules" then
        Help:OpenRulesC()
    elseif szAction == "SettingsMenu" then
        Help:OpenSettings()
    elseif szAction == "CommandsMenu" then
        Help:OpenCommands()
    end
end

local function HandleTimerActions(szType, varArgs)
    if szType == "Start" then
        Timer:SetStart(tonumber(varArgs[2]))
    elseif szType == "Restart" then
        if imstnit then imstnit(1) end
        if ResetStrafes then ResetStrafes() end
    elseif szType == "Finish" then
        local t = Timer:SetFinish(tonumber(varArgs[2]))
        if imstnit then imstnit(2, math.ceil(t)) end
    elseif szType == "Record" then
        Timer:SetRecord(tonumber(varArgs[2]))
        if varArgs[3] then Timer:SetStyle(tonumber(varArgs[3])) end
        if varArgs[4] then Link:Send("Speed", Timer:GetSpeedData()) end
    elseif szType == "Ranks" then
        Timer:SetRankScalar(varArgs[2], varArgs[3])
    elseif szType == "Freestyle" then
        Timer:SetFreestyle(varArgs[2])
    elseif szType == "Legit" then
        Timer:SetLegitSpeed(varArgs[2])
    elseif szType == "Stats" then
        Timer:ShowStats(varArgs[2])
    end
end

local function HandleClientActions(szType, varArgs)
    if szType == "HUDEditToggle" then
        Timer:ToggleEdit()
    elseif szType == "HUDEditRestore" then
        Timer:RestoreTo(varArgs[2])
    elseif szType == "HUDOpacity" then
        Timer:SetOpacity(varArgs[2])
    elseif szType == "Crosshair" then
        Client:ToggleCrosshair(varArgs[2])
    elseif szType == "TargetIDs" then
        Client:ToggleTargetIDs()
    elseif szType == "PlayerVisibility" then
        Client:PlayerVisibility(tonumber(varArgs[2]))
    elseif szType == "Chat" then
        Client:ToggleChat()
    elseif szType == "Mute" then
        Client:Mute(varArgs[2])
    elseif szType == "SpecVisibility" then
        Client:SpecVisibility(varArgs[2])
    elseif szType == "GUIVisibility" then
        Timer:GUIVisibility(tonumber(varArgs[2]))
    elseif szType == "Water" then
        Client:ChangeWater()
    elseif szType == "Sky" then
        Client:Sky()
    elseif szType == "Fog" then
        Client:Fog()
    elseif szType == "Simple" then
        Client:Simple()
    elseif szType == "Decals" then
        Client:ClearDecals()
    elseif szType == "Reveal" then
        Client:ToggleReveal()
    elseif szType == "Tutorial" then
        gui.OpenURL(varArgs[2])
    elseif szType == "Display" then
        Timer:SetCPSData(varArgs[2])
    elseif szType == "WeaponFlip" then
        Client:FlipWeapons(varArgs[2])
    elseif szType == "Space" then
        Client:ToggleSpace(varArgs[2])
    elseif szType == "Server" then
        Client:ServerSwitch(varArgs[2])
    elseif szType == "Emote" then
        Client:ShowEmote(varArgs[2])
    end
end

local function TransferHandle(szAction, varArgs)
    if szAction == "GUI_Open" then
        HandleGUIOpen(varArgs)
    elseif szAction == "update_wr" then
        HandleUpdateWR(varArgs)
    elseif szAction == "jump_update" then
        HandleJumpUpdate(varArgs)
    elseif szAction == "GUI_Update" then
        HandleGUIUpdate(varArgs)
    elseif szAction == "Print" then
        HandlePrint(varArgs)
    elseif szAction == "MainMenu" then
        HandleMainMenu(varArgs)
    elseif szAction == "Help" or szAction == "Rules" or szAction == "SettingsMenu" or szAction == "CommandsMenu" then
        HandleHelpMenu(szAction, varArgs)
    elseif szAction == "Timer" then
        local szType = tostring(varArgs[1])
        HandleTimerActions(szType, varArgs)
    elseif szAction == "Client" then
        local szType = tostring(varArgs[1])
        HandleClientActions(szType, varArgs)
	elseif szAction == "Spectate" then
		local szType = tostring( varArgs[ 1 ] )
		if szType == "Clear" then
			CS_Clear()
		elseif szType == "Mode" then
			CS_Mode( tonumber( varArgs[ 2 ] ) )
		elseif szType == "Viewer" then
			CS_Viewer( varArgs[ 2 ], varArgs[ 3 ], varArgs[ 4 ] )
		elseif szType == "Timer" then
			if varArgs[ 2 ] then
				CS_Bot( varArgs[ 3 ], varArgs[ 4 ], varArgs[ 5 ], varArgs[ 6 ], varArgs[ 7 ] )
			else
				CS_Player( varArgs[ 3 ], varArgs[ 4 ], varArgs[ 5 ], varArgs[ 6 ] )
			end
		end
	elseif szAction == "RTV" then
		local szType = tostring( varArgs[ 1 ] )
		szType = ""
		if szType == "GetList" then
			Cache.V_Data = varArgs[ 2 ] or {}
			Window:Open( "Vote" )
		elseif szType == "VoteList" then
			Cache:V_Update( varArgs[ 2 ] )
		elseif szType == "InstantVote" then
			Cache:V_InstantVote( varArgs[ 2 ] )
		elseif szType == "VIPExtend" then
			Cache:V_VIPExtend()
		end
	elseif szAction == "Manage" then
		local szType = tostring( varArgs[ 1 ] )
		if szType == "Mute" then
			Client:DoChatMute( varArgs[ 2 ], varArgs[ 3 ] )
		elseif szType == "Gag" then
			Client:DoVoiceGag( varArgs[ 2 ], varArgs[ 3 ] )
		end
	elseif szAction == "Checkpoints" then
		local szType = tostring( varArgs[ 1 ] )
		if szType == "Open" then
			Window:Open( "Checkpoints" )
		elseif szType == "Update" then
			Timer:SetCheckpoint( varArgs[ 2 ], varArgs[ 3 ], varArgs[ 4 ] )
		elseif szType == "Delay" then
			Timer:StartCheckpointDelay()
		end
	elseif szAction == "Admin" then
		Admin:Receive( varArgs )
	elseif szAction == "Scoreboard" then
		local mode = varArgs[1]
		local client = varArgs[2]
		local timeStarted = varArgs[3] and varArgs[3] or nil
		local finishedTime = varArgs[4] and varArgs[4] or nil 
		if (mode == "normal") then
			client.Tn = timeStarted 
			client.TnF = finishedTime
		elseif (mode == "bonus") then 
			client.Tb = timeStarted 
			client.TbF = finishedTime 
		else 
			client.Tn = 0
			client.Tb = 0
			client.TnF = nil 
			client.TbF = nil
		end
	end
end

local function TransferReceive()
	local szAction = net.ReadString()
	local bTable = net.ReadBit() == 1
	local varArgs = {}
	if bTable then
		varArgs = net.ReadTable()
		net.ReadUInt(6)  -- Read 6 bits
	end
	TransferHandle( szAction, varArgs )
end
net.Receive( Link.Protocol, TransferReceive )