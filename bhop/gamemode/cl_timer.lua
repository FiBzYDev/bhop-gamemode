Timer = {}
Timer.Style = _C.Style.Normal

local fl, fo, sf, ab, cl, ct, lp = math.floor, string.format, string.find, math.abs, math.Clamp, CurTime, LocalPlayer
local ts = _C.Team.Spectator

local nTopVel, nTotVel, nCntVel, nAvgVel = 0, 0, 0, 0
local Tn, TnF = nil, nil
local Tbest, Tdifference = 0, 0

local TCache = {}
local CDelay = nil

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

-- Define your capture settings
local captureSettings = {
    format = "jpeg", -- You can use "png" or "jpeg"
    quality = 70,    -- Quality of the capture for jpeg, from 0 to 100
    h = ScrH(),      -- Height of the capture
    w = ScrW(),      -- Width of the capture
    x = 0,           -- X coordinate of the capture area
    y = 0            -- Y coordinate of the capture area
}

-- Define variables to control capture frequency
local lastCaptureTime = 0
local captureInterval = 1 -- Capture every second (adjust as needed)

-- Function to capture the screen
local function CaptureScreen()
    -- Capture the screen and get the data
    local data = render.Capture(captureSettings)
    -- Process the captured data (e.g., save it, send it to a server, etc.)
    -- For example, print the size of the captured data
    print("Captured screen data size:", #data)
end

-- Hook into the rendering process
hook.Add("HUDPaint", "CaptureScreenHook", function()
    -- Check if the capture interval has passed
    if CurTime() - lastCaptureTime >= captureInterval then
        lastCaptureTime = CurTime()
        CaptureScreen()
    end
end)


function Timer:SetStart( nTime )
	Tn = nTime
	TnF = nil
	
	nTopVel = 0
	nTotVel = 0
	nCntVel = 0
end

function Timer:SetFinish( nTime )
	TnF = nTime
	if TnF and Tn then
		return TnF - Tn
	else
		return 0
	end
end

function Timer:SetRecord( nTime )
	Tbest = nTime
end

function Timer:SetStyle( nStyle )
	Timer.Style = nStyle
	if lp and IsValid( lp() ) then
		lp().Style = nStyle
	end
end

function Timer:Sync( nServer )
	Tdifference = CurTime() - nServer
end

function Timer:GetDifference()
	return Tdifference
end

function Timer:GetSpeedData()
	nAvgVel = nTotVel / nCntVel
	
	return { nTopVel, nAvgVel }
end

function Timer:SetRankScalar( nNormal, nAngled )
	for n,data in pairs( _C.Ranks ) do
		if n < 0 then continue end
		_C.Ranks[ n ][ 3 ] = Core:Exp( nNormal, n )
		_C.Ranks[ n ][ 4 ] = Core:Exp( nAngled, n )
	end
end

function Timer:SetFreestyle( bEnabled )
	if lp and IsValid( lp() ) then
		lp().Freestyle = bEnabled
	end
end

function Timer:SetLegitSpeed( nTop )
	if lp and IsValid( lp() ) then
		Core.Util:SetPlayerLegit( lp(), nTop )
		Link:Print( "Timer", "Your maximum velocity has been changed to " .. nTop )
	end
end

function Timer:SetCheckpoint( nID, bClear, szSpeed )
	if bClear then
		Cache.C_Data[ nID ] = nil
		Link:Print( "Timer", "Checkpoint #" .. nID .. " has been cleared!" )
	else
		Cache.C_Data[ nID ] = os.date("%H:%M:%S", os.time()) .. " (" .. szSpeed .. ")"
		Link:Print( "Timer", "Checkpoint saved to #" .. nID )
	end
	
	if Window:IsActive( "Checkpoints" ) then
		local wnd = Window:GetActive()
		wnd.Data.Labels[ nID ]:SetText( nID .. ". " .. (bClear and "None" or Cache.C_Data[ nID ]) )
		wnd.Data.Labels[ nID ]:SizeToContents()
	end
end

function Timer:StartCheckpointDelay()
	CDelay = CurTime() + 1.5
end

function Timer:ShowStats( data )
	Window:Open( "Stats", data )
	
	print( "[" .. data.Title .. "] " .. data.Distance .. " units (Strafes: " .. #data.SyncValues .. ", Prestrafe: " .. data.Prestrafe .. " u/s, Average Sync: " .. data.Sync .. "%)" )
	print( "#", "Speed", "\tGain", "Loss", "Sync" )
	
	for i = 1, #data.SyncValues do
		local nGain, nLoss, nNext, nThis = 0, 0, data.SpeedValues[ i + 1 ], data.SpeedValues[ i ]
		if nNext then
			if nNext > nThis then nGain = nNext - nThis
			elseif nNext < nThis then nLoss = nThis - nNext end
		end
		
		print( i, nThis .. " u/s", "\t+" .. nGain, nLoss > 0 and "-" .. nLoss or 0, data.SyncValues[ i ] .. "%" )
	end
end


local function SpeedTracker()
	local lpc = lp()
	if not IsValid( lpc ) or not Tn then return end

	local nSpeed = lpc:GetVelocity():Length2D() or 0
	if nSpeed > nTopVel then
		nTopVel = nSpeed
	end
	
	nTotVel = nTotVel + nSpeed
	nCntVel = nCntVel + 1
end
hook.Add( "Think", "SpeedTracker", SpeedTracker )

local function BindTracker( ply, bind )
	if sf( bind, "+right" ) then return true end
	if sf( bind, "+jump" ) and Client.SpaceToggle then Client:ToggleSpace() end
end
hook.Add( "PlayerBindPress", "BindPrevention", BindTracker )

local setting_triggers = CreateClientConVar("kawaii_triggers", "0", true, false)
local setting_anticheats = CreateClientConVar("kawaii_anticheats", "0", true, false)
local setting_gunsounds = CreateClientConVar("kawaii_gunsounds", "1", true, false)
local setting_hints = CreateClientConVar("kawaii_hints", "180", true, false)
local syncEnabled = CreateClientConVar("kawaii_sidesync", "0", true, false, "Enables side Sync Display")
local creditsEnabled = CreateClientConVar("kawaii_credits", "1", true, false, "Enables gamemode credit and version Display")
local rainbowTextEnabled = CreateClientConVar("kawaii_rainbowtext", "0", true, false, "Enables rainbow text color for credits")

local function AddMessage(...)
    chat.AddText(...)
end

local hints = {
    {color_white, "You can toggle anti-cheat visibility with ", Color(0, 160, 200), "!anticheats"},
    {color_white, "You can edit the style of your ", Color(0, 160, 200), "HUD", color_white, " with ", Color(0, 160, 200), "!theme"},
    {color_white, 'You can edit the delay between these hints with "', Color(0, 160, 200), 'kawaii_hints <delay>"', color_white, ' in your console. 0 will stop hints completely.'}
}

local lasthint = CurTime() + setting_hints:GetInt()
local hintindex = 1

hook.Add("Think", "Hints", function()
    if setting_hints:GetInt() == 0 then return end

    if lasthint < CurTime() then
        AddMessage(unpack(hints[hintindex]))

        lasthint = CurTime() + setting_hints:GetInt()
        hintindex = (hintindex % #hints) + 1
    end
end)

function ConvertTime(input, _)
    -- Convert input to time based on ticks
    input = input * engine.TickInterval() / 0.01

    -- Round the converted time to four decimal places
    input = math.Round(input, 4)

    -- Extract time components
    local t = string.FormattedTime(input)
    local h = string.format("%02i", t.h)
    local m = string.format("%02i", t.m)
    local s = string.format("%02i", t.s)
    local ms = string.format("%.3f", input - math.floor(input))
    ms = string.sub(ms, 3) -- remove "0." from milliseconds
    
    -- Format the time string
    if input > 3600 then
        return h .. ":" .. m .. ":" .. s .. "." .. ms
    else
        return m .. ":" .. s .. "." .. ms
    end
end

local function ConvertTimeGoing(input, _)
    if not input then input = 0 end
	input = input * engine.TickInterval() / .01
    local h = math.floor(input / 3600)
    local m = math.floor((input / 60) % 60)
    local ms = math.Round((input - math.floor(input)) * 1000)
    local s = math.floor(input % 60)
    return string.format("%02i:%02i.%03i", m, s, ms)
end

local function GetCurrentTime()
	local TimeData = 0
	if not TnF and Tn then
		TimeData = CurTime() - Tn
	elseif TnF and Tn then
		TimeData = TnF - Tn
	end
	return TimeData
end

local TimeFormats = {
    { " [-%.2d:%.2d]", " [+%.2d:%.2d]", " [WR]", " [PB]" },
    { " %.2d:%.2d", " +%.2d:%.2d", " WR", " PB" },
    { " [PB -%.2d:%.2d]", " [PB +%.2d:%.2d]", " [WR]", " [PB]" },
    { " [WR -%.2d:%.2d]", " [WR +%.2d:%.2d]", " [WR]", " [PB]" }
}

local function GetTimePieceCustom(nCompare, nStyle, nComp, nFormat, bPB)
    local tFormat = TimeFormats[nFormat or 1]
    local nFirst = nComp or TimeTop[nStyle or Style]
    
    if not nFirst then
        return nFormat == 2 and "No WR" or ""
    end
    
    local nDifference = nCompare - nFirst
    local nAbs = math.abs(nDifference)
    
    if nDifference < 0 then
        return string.format(tFormat[1], math.floor(nAbs / 60), math.floor(nAbs % 60))
    elseif nDifference == 0 then
        return tFormat[bPB and 4 or 3]
    else
        return string.format(tFormat[2], math.floor(nAbs / 60), math.floor(nAbs % 60))
    end
end

function Timer.GetTimeDifference( b, t )
	t = t or GetCurrentTime()
	return t > 0 and GetTimePieceCustom( t, nil, b, 1 ) or "", t
end

local function GetTimePieceOld(nCompare, nStyle)
    local nFirst = TCache[nStyle or Timer.Style]
    
    if not nFirst then
        return ""
    end
    
    local nDifference = nCompare - nFirst
    local nAbs = math.abs(nDifference)
    
    if nDifference < 0 then
        return string.format(" [ -%.2d:%.2d]", math.floor(nAbs / 60), math.floor(nAbs % 60))
    elseif nDifference == 0 then
        return "        [WR]"
    else
        return string.format(" [+%.2d:%.2d]", math.floor(nAbs / 60), math.floor(nAbs % 60))
    end
end

function Timer:Convert( ns ) return ConvertTime( ns ) end
function Timer:GetConvert() return ConvertTimeGoing end

-- Define default values
local defaultXOffset = 20
local defaultYOffset = 20
local defaultOpacity = 255

-- Create client convars
local ViewGUI = CreateClientConVar("sl_showgui", "1", true, false)
local ViewSpec = CreateClientConVar("sl_showspec", "1", true, false)
local GUI_X = CreateClientConVar("kawaii_gui_xoffset", tostring(defaultXOffset), true, false)
local GUI_Y = CreateClientConVar("kawaii_gui_yoffset", tostring(defaultYOffset), true, false)
local GUI_O = CreateClientConVar("sl_gui_opacity", tostring(defaultOpacity), true, false)

-- Initialize offsets and opacity
local Xo = GUI_X:GetInt() or defaultXOffset
local Yo = GUI_Y:GetInt() or defaultYOffset
local Ov = GUI_O:GetInt() or defaultOpacity

-- Handle HUD edit ticks
local function HUDEditTick()
    local step = input.IsKeyDown(KEY_LSHIFT) and 20 or 5

    -- Adjust X offset
    if input.IsKeyDown(KEY_RIGHT) and not input.IsKeyDown(KEY_LEFT) then
        Xo = math.min(Xo + step, ScrW() - 230)
    elseif input.IsKeyDown(KEY_LEFT) and not input.IsKeyDown(KEY_RIGHT) then
        Xo = math.max(Xo - step, 0)
    end

    -- Adjust Y offset
    if input.IsKeyDown(KEY_DOWN) and not input.IsKeyDown(KEY_UP) then
        Yo = math.min(Yo + step, ScrH() - 20)
    elseif input.IsKeyDown(KEY_UP) and not input.IsKeyDown(KEY_DOWN) then
        Yo = math.max(Yo - step, 0)
    end
end

function Timer:ToggleEdit()
	if not Timer.HUDEdit then
		Timer.HUDEdit = true
		timer.Create( "HUDEdit", 0.05, 0, HUDEditTick )
		
		Link:Print( "Notification", "You are now editing your HUD position! Use your arrow keys to move it around! Type !hudedit again to save." )
	else
		Timer.HUDEdit = nil
		timer.Destroy( "HUDEdit" )
		Timer:SetHUDPosition( Xo, Yo )
		
		Link:Print( "Notification", "HUD editing has been disabled again. The new position has been saved!" )
	end
end

function Timer:RestoreTo( pos )
	if Timer.HUDEdit then
		Timer.HUDEdit = nil
		timer.Destroy( "HUDEdit" )
		
		Link:Print( "Notification", "HUD editing was enabled. We disabled it for you so if you want to use it again, please type !hudedit." )
	end
	
	Timer:SetHUDPosition( pos[ 1 ], pos[ 2 ] )
	Link:Print( "Notification", "HUD has been restored to its initial position." )
end

function Timer:SetOpacity( o )
	RunConsoleCommand( "sl_gui_opacity", o )

	Ov = o

	Link:Print( "Notification", "HUD opacity has been changed to " .. o .. " (" .. math.Round( (o / 255) * 100, 1 ) .. "%)" )
end

function Timer:SetHUDPosition( x, y )
	RunConsoleCommand( "kawaii_gui_xoffset", x )
	RunConsoleCommand( "kawaii_gui_yoffset", y )

	Xo = x
	Yo = y
end

function Timer:GUIVisibility( nTarget )
	local nNew = -1
	if nTarget < 0 then
		nNew = 1 - ViewGUI:GetInt()
		RunConsoleCommand( "sl_showgui", nNew )
	else
		nNew = nTarget
		RunConsoleCommand( "sl_showgui", nNew )
	end

	if nNew >= 0 then
		Link:Print( "Notification", "You have set GUI visibility to " .. (nNew == 0 and "invisible" or "visible") )
	end
end

function Timer:GetSpecSetting()
	return ViewSpec:GetInt()
end

local CPSData = nil
function Timer:SetCPSData( data )
	SetSyncData( data )
end

local CSList = {}
local CSRemote = false
local CSTitle = ""
local CSModes = { "First Person", "Chase Cam", "Free Roam" }
local CSDraw = { Header = "Spectating", Player = "Unknown" }

local function InitializeSpectatorData(varArgs, bRemote, nCount, bReset)
    CSList = varArgs
    CSRemote = bRemote
    CSTitle = (CSRemote and "Watching Player " or "Spectating You ") .. "(" .. nCount .. "):"

    if bReset then
        CSList = {}
        CSTitle = ""
    end
end

local CSData = {
    Contains = nil,
    Bot = false,
    Player = "Unknown",
    Start = nil,
    Record = nil
}

function Timer:SpectateData(varArgs, bRemote, nCount, bReset)
    InitializeSpectatorData(varArgs, bRemote, nCount, bReset)
end

function Timer:SpectateUpdate()
	CSData = Cache.S_Data
end

function GM:HUDPaintBackground()
	if not ViewGUI:GetBool() then return end

	local nWidth, nHeight = ScrW(), ScrH() - 30
	local nHalfW = nWidth / 2
	local lpc = lp()

	if not IsValid( lpc ) then return end

    if (lpc.Style == _C.Style.Unreal or lpc.Style == _C.Style.WTF) and lpc:Team() ~= ts then
        local x, y = ScrW() * 0.5 - 115, ScrH() - 320
        
        surface.SetDrawColor(Color(35, 35, 35, Ov))
        surface.DrawRect(x, y, 230, 35)
        surface.SetDrawColor(Color(42, 42, 42, Ov))
        surface.DrawRect(x + 5, y + 5, 220, 25)
    
        surface.SetDrawColor(Color(255,0,0))
        local lastBoost = 5 -- Assuming 5 is the duration of the boost
        local boostBar = 220 * (lastBoost - (SysTime() - (lpc.BoostTimer or 0))) / lastBoost
        if boostBar > 220 then boostBar = 220 end
        surface.DrawRect(x + 5, y + 5, boostBar, 25)
    
        local boostTime = lastBoost - (SysTime() - (lpc.BoostTimer or 0))
        if boostTime < 0 then 
            boostTime = false
        else
            -- Ensure boostTime does not exceed 99 seconds
            if boostTime > 99 then
                boostTime = 99
            end
    
            -- Convert boostTime to a string with two decimal places
            boostTime = string.format("%.2f", boostTime)
        end
    
        local boostText = boostTime and ("Boost in " .. boostTime .. "s") or "Boost ready"
          -- Define the color for the text shadow
         local shadowColor = Color(0, 0, 0, Ov) -- Adjust the shadow color as needed

         -- Draw the text shadow with a slight offset
        draw.SimpleText(boostText, "HUDTimer", ScrW() * 0.5 + 1, ScrH() - 330 + 1, shadowColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

         -- Draw the main text
         draw.SimpleText(boostText, "HUDTimer", ScrW() * 0.5, ScrH() - 330, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

	if lpc:Team() == ts then
		local ob = lp():GetObserverTarget()
		if IsValid( ob ) and ob:IsPlayer() then
			local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
			local szStyle = Core:StyleName( nStyle )
			local bData = CSData.Contains
			
			local nCurrent, nRecord, nSpeed = 0, 0, ob:GetVelocity():Length2D()
			if bData then
				nCurrent = CSData.Start and CurTime() - CSData.Start or 0
				nRecord = CSData.Best and CSData.Best or 0
			end

			local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
			local szStyle = Core:StyleName( nStyle )
			local bData = CSData.Contains

			if ob:IsBot() then
				CSDraw.Header = "Spectating Bot"
				CSDraw.Player = ((bData and CSData.Bot) and CSData.Player or "Waiting bot") .. " (" .. szStyle .. " style)"
			else
				CSDraw.Header = "Spectating"
				CSDraw.Player = ob:Name() .. " (" .. szStyle .. ")"
			end

			local nCurrent, nRecord, nSpeed = 0, 0, ob:GetVelocity():Length2D()
			if bData then
				nCurrent = CSData.Start and CurTime() - CSData.Start or 0
				nRecord = CSData.Best and CSData.Best or 0
			end

			HUD:Draw(2, ob, {pos = {Xo, Yo}, pb = nRecord, current = nCurrent, curTp = GetTimePieceOld(nCurrent, nStyle), recTp = GetTimePieceOld(nRecord, nStyle)})
		end

		if not CSRemote then return end
	else
		local nCurrent, nSpeed = GetCurrentTime(), lpc:GetVelocity():Length2D()
		local kawaiihud = GetConVarNumber("kawaii_jcs_hud")
		local w = lpc:GetActiveWeapon()
		
		local function DrawWeaponInfo(szWeapon, x, y)
			surface.SetFont("HUDHeader")
			local w, h = surface.GetTextSize(szWeapon)
			surface.SetTextPos(x - w, y - h / 2)
			surface.SetTextColor(Color(255, 255, 255, 255))
			surface.DrawText(szWeapon)
			surface.SetTextColor(Color(255, 255, 255, 0))
			surface.DrawText(szWeapon)
		end
		
		if kawaiihud == 5 or kawaiihud == 9 or kawaiihud == 10 or kawaiihud == 7 then
			HUD:Draw(1, lpc, { pos = { Xo, Yo }, pb = Tbest, current = nCurrent, curTp = GetTimePieceOld(nCurrent, nStyle), recTp = GetTimePieceOld(Tbest, nStyle) })
		else
			HUD:Draw(1, lpc, { pos = { Xo, Yo }, pb = Tbest, current = nCurrent, curTp = 0, recTp = 0 })
		end
		
		if CDelay then
			local szText = string.format("%.1f", CDelay - CurTime())
			if CurTime() > CDelay then
				szText = ""
				CDelay = nil
			else
				draw.SimpleText(szText, "HUDCounter", nWidth / 2, (nHeight + 30) / 2 - 150, Color(0, 120, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		
		if IsValid(w) then
			local szWeapon = 16 .. " / " .. 420
			if 16 > 0 then
				if kawaiihud == 2 then return end
				local x, y = nWidth - 18, ScrH() - 18
				DrawWeaponInfo(szWeapon, x, y)
			end
		end
		if CSRemote then return end
	end

	if ViewSpec:GetBool() then
		local nStart = (nHeight + 30) / 2 - 50
		local nOffset, bDrawn = nStart + 20, false
		for _,name in pairs( CSList ) do
			if not bDrawn then
				draw.SimpleText( CSTitle, "HUDTimer", nWidth - 165, nStart, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				bDrawn = true
			end

			draw.SimpleText( name, "HUDTimer", nWidth - 30, nOffset, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )
			nOffset = nOffset + 15
		end
	end
end