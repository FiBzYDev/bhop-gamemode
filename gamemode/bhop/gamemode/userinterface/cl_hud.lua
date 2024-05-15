-- HUD
-- by Justa

local surface = surface
local draw = draw
local Color = Color
local selected_hud = CreateClientConVar("kawaii_jcs_hud", 4, true, false)
local kawaiius = CreateClientConVar("kawaii_us_center", 0, true, false)
local wantraindow = CreateClientConVar("kawaii_flow_rainbow", 0, true, false)
JHDULAST = {}
JHDULAST.Enabled = CreateClientConVar( "kawaii_lastspeed", "0", true, false, "JHud show last speed" )

CreateConVar("hud_rainbow_text", "1", FCVAR_ARCHIVE, "Enable rainbow text for HUD")

-- Retrieve the ConVar value
local rainbowTextEnabled = GetConVar("hud_rainbow_text"):GetBool()

strafetrainer = CreateClientConVar("bhop_strafetrainer", 0, true, false, "Controls strafe trainer", 0, 1)
local strafetrainer_interval = CreateClientConVar("bhop_strafetrainer_interval", 10, true, false, "Controls strafe trainer update rate in ticks", 1, 100)
local strafetrainer_ground = CreateClientConVar("bhop_strafetrainer_ground", 0, true, false, "Should it update on ground", 0, 1)
local roundedBoxEnabled = CreateConVar("kawaii_momu_rounded_box", "1", {FCVAR_ARCHIVE}, "Enable rounded box drawing")
local syncbackgroundEnabled = CreateConVar("kawaii_momu_syncbackground", "0", {FCVAR_ARCHIVE}, "Enable sync background bar")

local interval = (1 / engine.TickInterval())*(strafetrainer_interval:GetInt()/100)
local ground = strafetrainer_ground:GetBool()

local mapDatabase = {
    ["bhop_overline"] = "00:23:049 - bozya",
    ["bhop_stref_amazon"] = "00:19:140 - astra",
    ["bhop_asko"] = "02:02:320 - bozya",
    ["bhop_anotherbhopmap"] = "01:10.829 - Cat",
    ["bhop_lubluebatsjavanal"] = "00:34.309 - bozya",
    ["bhop_effigy"] = "00:12.480 - Vehnex",
    ["bhop_horseshit_4"] = "00:16.199 - Justa",
    ["bhop_terry"] = "01:00.999 - Vehnex",
    ["bhop_kotodama"] = "00:41.029 - zzz",
    ["bhop_kotodama2"] = "00:45.679 - justa",
    ["bhop_bloodflow"] = "00:41.410 - Vehnex",
    ["bhop_speedrun_valley"] = "00:18.529 - Vehnex",
    ["bhop_p08"] = "00:36.850 - Greatchar",
    ["bhop_3dm"] = "00:31.439 - justa",
    ["bhop_newdun"] = "00:21.670 - Vehnex",
    ["bhop_filter_fix"] = "00:17.119 - Justa",
    ["bhop_nosotros"] = "00:26.378 - Justa",
    ["bhop_kiwi_cwfx"] = "00:21.739 - zzz",
    ["bhop_linear_gif2"] = "00:39.938 - Lemin",
    ["bhop_bfur"] = "00:09.531 - Sashbern",
    ["bhop_sandtrap3"] = "00:49.948 - Lemin",
    ["bhop_nervosity2"] = "00:39.740 - Cat",
    ["bhop_coast"] = "00:33.569 - Greatchar",
    ["bhop_stref_lively"] = "00:18.489 - LokL",
    ["bhop_hexag0n_cool"] = "00:25.499 - Cat",
    ["bhop_blossom"] = "00:37.729 - bozya",
    ["bhop_futile"] = "00:51.489 - Lemin",
    ["bhop_bloc"] = "00:54.091 - Cat",
    ["bhop_bon_fix"] = "00:20.117 - justa",
    ["bhop_rikudo"] = "00:25.540 - justa",
    ["bhop_akame"] = "00:21.678 - justa",
    ["bhop_lined"] = "00:27.329 - LokL",
    ["bhop_autobadges"] = "00:17.819 - antacid",
    ["bhop_ragepoop_rev"] = "00:17.040 - boyza",
    ["bhop_probeginners"] = "00:18.190 - m1ners",
    ["bhop_chaser"] = "00:19.369 - Vehnex",
    ["bhop_jegg"] = "00:07.399 - Vehnex",
    ["bhop_blue_aux"] = "00:18.279 - Greatchar",
    ["bhop_zhopavqaqe"] = "00:07.709 - Cat",
    ["bhop_z"] = "00:59.738 - justa",
    ["bhop_dimensional"] = "01:13.690 - Trickster",
    ["bhop_zeus"] = "00:58.209 - Lemin",
    ["bhop_saffron_css"] = "00:18.708 - LokL",
    ["bhop_grassyass"] = "00:14.309 - astra",
    ["bhop_ambience"] = "00:17.919 - LokL",
    ["bhop_cobblestone"] = "00:26.880 - dora",
    ["bhop_bhop"] = "00:29.519 - Syn",
    ["bhop_bhop3"] = "00:31.910 - Sashbern",
    ["bhop_topgay"] = "00:26.060 - Sashbern",
    ["bhop_alt_saimaa"] = "00:19.977 - Cat",
    ["bhop_alt_univaje"] = "00:21.430 - Zqk",
    ["bhop_kasvihuone"] = "00:37.929 - sadrainbow",
    ["bhop_stref_siberia"] = "00:27.910 - Zqk",
    ["bhop_horseshit_1"] = "00:25.299 - Sashbern",
}

function getGlobalWRForCurrentMap()
    local currentMap = game.GetMap()
    return mapDatabase[currentMap] or "N/A"
end

cvars.AddChangeCallback("bhop_strafetrainer_interval", function(cvar, old, new)
	interval= (1 / engine.TickInterval()) * (new/100)
end)

cvars.AddChangeCallback("bhop_strafetrainer_ground", function(cvar, old, new)
	ground = (new == "1" and true or false)
end)

local movementSpeed = 32.8
local deg, atan = math.deg, math.atan

local function NormalizeAngle(x)
	if (x > 180) then 
		x = x - 360
	elseif (x <= -180) then 
		x = x + 360
	end 

	return x
end

local function GetPerfectAngle(vel)
	return deg(atan(movementSpeed / vel))
end

local last = 0
local tick = 0
local percentages = {}
CurrentTrainValue = 0
local function StartCommand(client, cmd)
	if (client:IsOnGround() and !ground) then return end
	if cmd:TickCount() == 0 then return end 
    if client:GetMoveType() == MOVETYPE_NOCLIP then return end 

	local vel = client:GetVelocity():Length2D()
	local ang = client:GetAngles().y
	local diff = NormalizeAngle(last - ang)
	local perfect = GetPerfectAngle(vel)
	local perc = math.abs(diff) / perfect 

	if (tick > interval) then 
		local avg = 0 

		for x = 0, interval do 
			avg = avg + percentages[x]
			percentages[x] = 0
		end

		CurrentTrainValue = avg / interval 
		tick = 0 
	else
		percentages[tick] = perc 
		tick = tick + 1
	end

	last = ang
end
hook.Add("StartCommand", "BHOP_strafetrainer", StartCommand)

local fb, lp = bit.band, LocalPlayer
local isPressing = function( ent, bit ) return ent:KeyDown( bit ) end
local syncData, syncAxis, syncStill = "", 0, 0
local spectatorBits = 0
local isSpecPressing = function( bit ) return fb( spectatorBits, bit ) > 0 end
local jumpTime = 0
local jumpDisplay = 0.25
local function norm( i ) if i > 180 then i = i - 360 elseif i < -180 then i = i + 360 end return i end
ShowKeys = {}
ShowKeys.Enabled = CreateClientConVar( "kawaii_showkeys", "1", true, false, "Displays the movement keys that are being pressed by the player." )
ShowKeys.Position = CreateClientConVar( "kawaii_showkeys_pos", "1", true, false, "Changes the position of the showkeys module, default is 0 (center)." )
ShowKeys2 = {}
ShowKeys2.Enabled2 = CreateClientConVar( "kawaii_showkeys_flow2", "0", true, false, "Displays the movement keys that are being pressed by the player." )
ShowKeys2.Position2 = CreateClientConVar( "kawaii_showkeys_pos_flow2", "0", true, false, "Changes the position of the showkeys module, default is 0 (center)." )
ShowKeys.Color = color_white
local keyStrings = {
  [512] = input.LookupBinding( "+moveleft" ) or "A",
  [1024] = input.LookupBinding( "+moveright" ) or "D",
  [8] = input.LookupBinding( "+forward" ) or "W",
  [16] = input.LookupBinding( "+back" ) or "S",
  [4] = "+ DUCK",
  [2] = "+ JUMP",
  [128] = "",
  [256] = "",
}

local keyPositions = {
  [0] = {
    [512] = { ScrW() / 2 - 30, ScrH() / 2 },
    [1024] = { ScrW() / 2 + 30, ScrH() / 2 },
    [8] = { ScrW() / 2, ScrH() / 2 - 30 },
    [16] = { ScrW() / 2, ScrH() / 2 + 30 },
    [4] = { ScrW() / 2 - 60, ScrH() / 2 + 30 },
    [2] = { ScrW() / 2 + 60, ScrH() / 2 + 30 },
    [128] = { ScrW() / 2 - 60, ScrH() / 2 },
    [256] = { ScrW() / 2 + 60, ScrH() / 2 }
  },
  [1] = {
    [512] = { ScrW() - 120 - 30, ScrH() - 120 },
    [1024] = { ScrW() - 120 + 30, ScrH() - 120 },
    [8] = { ScrW() - 120, ScrH() - 120 - 30 },
    [16] = { ScrW() - 120, ScrH() - 120 + 30 },
    [4] = { ScrW() - 120 - 60, ScrH() - 120 + 30 },
    [2] = { ScrW() - 120 + 60, ScrH() - 120 + 30 },
    [128] = { ScrW() - 120 - 60, ScrH() - 120 },
    [256] = { ScrW() - 120 + 60, ScrH() - 120 }
  }
}

local function DisplayKeys()
  local wantsKeys = ShowKeys.Enabled:GetBool()
  if !wantsKeys then return end
  kawaiihud = GetConVarNumber "kawaii_jcs_hud"
  local lpc = lp()
  if !IsValid( lpc ) then return end
  local currentPos = ShowKeys.Position:GetInt()
  local isSpectating = lpc:Team() == ts
  local testSubject = lpc:GetObserverTarget()
  local isValidSpectator = isSpectating and IsValid( testSubject ) and testSubject:IsPlayer()

	if lp():IsOnGround() and (CurTime() < (CurTime() + 0.060)) then
 	 	ShowKeys.Color = HSVToColor( RealTime() * 40 % 360, 1, 1 )
	else
		ShowKeys.Color = color_white
	end

  if isValidSpectator then
    for key, text in pairs( keyStrings ) do
      local willDisplay = isSpecPressing(key)
      if key == 2 and jumpTime > RealTime() then
        local pos = keyPositions[currentPos][key]
        draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        continue
      end
      if !willDisplay then continue end
      local pos = keyPositions[currentPos][key]
      text = string.upper( text )
      if key == 2 then
        jumpTime = RealTime() + jumpDisplay
      end
	  kawaiihud = GetConVarNumber "kawaii_jcs_hud"
	  if kawaiihud == 5 or kawaiihud == 9 or kawaiihud == 8 or kawaiihud == 7 then return end
      draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end
	
    local currentAngle = testSubject:EyeAngles().y
    local diff = norm( currentAngle - syncAxis )
    if diff > 0 then
      syncStill = 0
	  kawaiihud = GetConVarNumber "kawaii_jcs_hud"
	  if kawaiihud == 5 or kawaiihud == 9 or kawaiihud == 8 or kawaiihud == 7 then return end
      local pos = keyPositions[currentPos][128]
      draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    elseif diff < 0 then
      syncStill = 0
	  kawaiihud = GetConVarNumber "kawaii_jcs_hud"
	  if kawaiihud == 5 or kawaiihud == 9 or kawaiihud == 8 or kawaiihud == 7 then return end
      local pos = keyPositions[currentPos][256]
      draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    else
      syncStill = syncStill + 1
    end
    syncAxis = currentAngle
  else
    for key, text in pairs( keyStrings ) do
      local willDisplay = isPressing(lpc, key)
      if !willDisplay then continue end
      local pos = keyPositions[currentPos][key]
      text = string.upper( text )
	  kawaiihud = GetConVarNumber "kawaii_jcs_hud"
	  if kawaiihud == 5 or kawaiihud == 9 or kawaiihud == 8 or kawaiihud == 7 then return end
      draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end
    local currentAngle = lpc:EyeAngles().y
    local diff = norm( currentAngle - syncAxis )
    if diff > 0 then
      syncStill = 0
	  kawaiihud = GetConVarNumber "kawaii_jcs_hud"
	  if kawaiihud == 5 or kawaiihud == 9 or kawaiihud == 8 or kawaiihud == 7 then return end
      local pos = keyPositions[currentPos][128]
      draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    elseif diff < 0 then
      syncStill = 0
	  kawaiihud = GetConVarNumber "kawaii_jcs_hud"
	  if kawaiihud == 5 or kawaiihud == 9 or kawaiihud == 8 or kawaiihud == 7 then return end
      local pos = keyPositions[currentPos][256]
      draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    else
      syncStill = syncStill + 1
    end
    syncAxis = currentAngle
    local pos = { ScrW() - 15, ScrH() - 15 }
  end
end
hook.Add( "HUDPaint", "bhop.ShowKeys", DisplayKeys )

local function ReceiveSpecByte()
  spectatorBits = net.ReadUInt( 11 )
end
net.Receive( "bhop_ShowKeys", ReceiveSpecByte )

-- Font
surface.CreateFont( "HUDTimerBig", { size = 28, weight = 400, font = "Trebuchet24" } )

-- Converting a time

local function ConvertTime(input, _)
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
	input = input * engine.TickInterval() / .01
    local h = math.floor(input / 3600)
    local m = math.floor((input / 60) % 60)
    local ms = math.Round((input - math.floor(input)) * 1000)
    local s = math.floor(input % 60)
    return string.format("%02i:%02i.%03i", m, s, ms)
end

local fl, fo = math.floor, string.format

local function cCTime(ns)
	ns = ns * engine.TickInterval() / .01
    if not ns then ns = 0 end
    if ns > 3600 then
        return fo("%i:%.02i:%.02i.%.03i", fl(ns / 3600), fl(ns / 60 % 60), fl(ns % 60), (ns - math.floor(ns)) * 1000)
    elseif ns > 60 then
        return fo("%.01i:%.02i.%.03i", fl(ns / 60 % 60), fl(ns % 60), (ns - math.floor(ns)) * 1000)
    else
        return fo("%.01i.%.03i", fl(ns % 60), (ns - math.floor(ns)) * 1000)
    end
end

local function cTime(input, _)
    if type(input) == 'boolean' then input = 0 end
    input = input * engine.TickInterval() / .01
    if not input then input = 0 end
    local h = math.floor(input / 3600)
    local m = math.floor((input / 60) % 60)
    local ms = (input - math.floor(input)) * 1000
    local s = math.floor(input % 60)
    if input > 3600 then
        return string.format("%i:%.02i:%.02i.%.01i", fl(input / 3600), fl(input / 60 % 60), fl(input % 60), (input - math.floor(input)) * 10)
    elseif input > 60 then
        return string.format("%.01i:%.02i.%.01i", fl(input / 60 % 60), fl(input % 60), (input - math.floor(input)) * 10)
    else
        return string.format("%.01i.%.01i", fl(input % 60), (input - math.floor(input)) * 10)
    end
end

local function pGOldTime(input)
	if type(input) ~= 'number' or input < 0 then input = 0 end
    
    -- Calculate minutes, seconds, and tenths of a second (first digit of milliseconds)
    local m = math.floor(input / 60)
    local s = math.floor(input % 60)
    local t = math.floor((input * 10) % 10)  -- This gets the first decimal place

    -- Format the string as "MIN:SEC.T" where T is tenths of a second
    local timeString = string.format("%i:%02i.%i", m, s, t)

    return timeString
end

local function ConvertTimeSM(ns)
	ns = ns * engine.TickInterval() / .01
    if not ns then ns = 0 end
    local dec = 3
    local frm = 10 ^ dec
    local decimalFormat = string.format(".%%.%ii", dec)
    if dec == 0 then
        decimalFormat = ""
        frm = 1
    end
    if ns > 3600 then
        return string.format("%i:%.02i:%.02i" .. decimalFormat, fl(ns / 3600), fl(ns / 60 % 60), fl(ns % 60), (ns - math.floor(ns)) * frm)
    else
        return string.format("%.02i:%.02i" .. decimalFormat, fl(ns / 60 % 60), fl(ns % 60), (ns - math.floor(ns)) * frm)
    end
end

-- Neat :)
HUD = {}
HUD.Ids = {
    "Counter Strike: Source",
    "Counter Strike: Source Shavit",
    "Simple",
    "Momentum",
    "Flow Network"
}

-- Themes
local sync = "Sync: N/A%"

HUD.Themes = {
	function(pl, data)
		local base = Color(20, 20, 20, 150)
		local text = color_white

		if (data.strafe) then 
			sync = data.sync or sync
			return
		end

		-- Current Vel
		local velocity = math.floor(pl:GetVelocity():Length2D())

		-- Strings
		local time = "Time: "
		local pb = "PB: "
		local style = pl:GetNWInt("Style", 1)
		local stylename = Core:StyleName(style or 1) .. (pl:IsBot() and " Bot" or "")

		-- Personal best
		local personal = ConvertTime(data.pb or 0)

		-- Current Time
		local current = data.current < 0 and 0 or data.current
		local currentf = cTime(current)

		-- Jumps
		jumps = pl.player_jumps or 0

		-- Activity 
		local activity = current > 0 and 1 or 2
		activity = (pl:GetNWInt("inPractice", false) or (pl.TnF or pl.TbF)) and 3 or activity
		activity = (activity == 1 and (pl:IsBot() and 4 or 1) or activity)

		-- Outer box
		local width = 130
		local height = {124, 64, 44, 84}
		height = height[activity]
		local xPos = (ScrW() / 2) - (width / 2)
		local yPos = ScrH() - height - 60 - (LocalPlayer():Team() == TEAM_SPECTATOR and 50 or 0)

		draw.RoundedBox(16, xPos, yPos, width, height, base)

		-- HUD on the bottom
		if (activity == 1) then 
			draw.SimpleText(stylename, "HUDTimer", ScrW() / 2, yPos + 20, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)		
			draw.SimpleText(time .. currentf, "HUDTimer", ScrW() / 2, yPos + 40, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Jumps: " .. jumps or 0, "HUDTimer", ScrW() / 2, yPos + 60, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Sync: " .. sync .. "%", "HUDTimer", ScrW() / 2, yPos + 80, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)	
			draw.SimpleText("Speed: " .. velocity, "HUDTimer", ScrW() / 2, yPos + 100, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)			
		elseif (activity == 2) then
			draw.SimpleText("In Start Zone", "HUDTimer", ScrW() / 2, yPos + 20, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Speed: " .. velocity, "HUDTimer", ScrW() / 2, yPos + 40, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)			
		elseif (activity == 3) then
			draw.SimpleText("Speed: " .. velocity, "HUDTimer", ScrW() / 2, yPos + 20, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)			
		elseif (activity == 4) then 
			draw.SimpleText(stylename, "HUDTimer", ScrW() / 2, yPos + 20, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)		
			draw.SimpleText(time .. currentf, "HUDTimer", ScrW() / 2, yPos + 40, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Speed: " .. velocity, "HUDTimer", ScrW() / 2, yPos + 60, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)		
		end

		local wr, wrn
		if (not WorldRecords) or (not WorldRecords[style]) or (#WorldRecords[style] == 0) then 
			wr = "No time recorded"
			wrn = ""
		else 
			wr = ConvertTime(WorldRecords[pl:GetNWInt("Style", 1)][2])
			wrn = "(" .. WorldRecords[pl:GetNWInt("Style", 1)][1] .. ")"
		end

		-- Top 
		draw.SimpleText("WR: " .. wr .. " " .. wrn, "HUDTimerBig", 10, 6, text)
		draw.SimpleText(pb .. personal, "HUDTimerBig", 10, 34, text)	

		-- Spec 
		if (LocalPlayer():Team() == TEAM_SPECTATOR) then 
			-- Draw big box
			surface.SetDrawColor(base)
			surface.DrawRect(0, ScrH() - 80, ScrW(), ScrH())

			-- Name
			local name = pl:Name()

			-- Bot?
			if (pl:IsBot()) then 
				name = Core:StyleName(style or 1) .. " Replay (" .. pl:GetNWString("BotName", "Loading...") .. ")"
			end

			draw.SimpleText(name, "HUDTimer", ScrW() / 2, ScrH() - 40, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)		
		end	
	end,

	-- CS:S Shavit --
	function(pl, data)
		local ScrWidth, ScrHeight = ScrW, ScrH
		local w, h = ScrWidth(), ScrHeight()
	
			if data.strafe then sync = data.sync or sync return end

				local ply = LocalPlayer()
				kawaiihud = GetConVarNumber "kawaii_jcs_hud"
				if ply:GetActiveWeapon().Primary then
					if ammo_clip != -1 then
			
					surface.SetFont( "CSS_FONT" )
			
					local csstext = Color(255, 176, 0, 120)
					draw.RoundedBox( 8, ScrW() - 352, ScrH() - 76, 318, 56, Color(0, 0, 0, 90))
					draw.SimpleText( 16, "CSS_FONT", ScrW() - 270, ScrH() - 90 + 9, color_white, TEXT_ALIGN_CENTER )
					draw.SimpleText( "M", "CSS_ICONS", ScrW() - 75, ScrH() -75, color_white, TEXT_ALIGN_CENTER ) 
					draw.SimpleText( 420, "CSS_FONT", ScrW() - 120, ScrH() - 90 + 9, color_white, TEXT_ALIGN_RIGHT ) 
					draw.RoundedBox( 0, ScrW() - 230, ScrH() - 70, 3, 42, color_white )
					end
				end

			local velocity = math.Round(pl:GetVelocity():Length2D())
			local time = "Time: "
			local pb = "Best: "
			local style = pl:GetNWInt("Style", 1)
			local stylename = Core:StyleName(style or 1) .. (pl:IsBot() and " Replay" or "")
			local personal = cCTime(data.pb or 0)
			local current = data.current < 0 and 0 or data.current
			local currentf = cTime(current)

			jumps = pl.player_jumps or 0
			local base = Color(0, 0, 0, 70)
			local activity = current > 0 and 1 or 2
			activity = (pl:GetNWInt("inPractice", false) or (pl.TnF or pl.TbF)) and 3 or activity
			activity = activity == 1 and (pl:IsBot() and 4 or 1) or activity

			local box_y_css = -4
			local box_y_css2 = -8
			local text_y_css = 5
			local text_y_css2 = -22
			local text_y_css4 = 2
			local width = {162, 164, 125, 165}
			local width2 = {162, 164, 38, 165}
			width = width[activity]
			width2 = width2[activity]

			local height = {136, 95, 56, 90}
			height = height[activity]
			local activity_y = {175, 175, 175, 175}
			activity_y = activity_y[activity]

			local xPos = (ScrW()/2) - (width/2)
			local xPos2 = (ScrW()/2) - (width2/2)
			local yPos = ScrH() - height - activity_y
			local CSRound2 = 8

			local wrtext = "WR: "

			local wr, wrn
			if not WorldRecords or not WorldRecords[style] or #WorldRecords[style] == 0 then 
				wr = "No Record"
				wrn = ""
			else 
				wr = cCTime(WorldRecords[pl:GetNWInt("Style", 1)][2])
				wrn = "(" .. WorldRecords[pl:GetNWInt("Style", 1)][1] .. ")"
			end

			local pbtext
			if (data.pb) == 0 then 
				pbtext = "No Time"
			else 
				pbtext = cCTime(data.pb or 0)
			end

			draw.SimpleText("WR: " .. wr .. " " .. wrn, "HUDcsstop2", 19, 10, color_white, text, TEXT_ALIGN_LEFT)
			draw.SimpleText(pb .. pbtext, "HUDcsstop2", 19, 50, color_white, text, TEXT_ALIGN_LEFT)	

			local me = LocalPlayer()
			local ot = LocalPlayer()
			local t = nil
			if ot == me or not ot then
				t = me
			else
				t = ot
			end
				if activity == 1 then
					draw.SimpleText("Sync: " .. sync .. "%","HUDcssBottom",ScrW() / 2.002, text_y_css + yPos + 79,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				end

			if activity == 1 then
				local TimeText = "Time: " .. currentf
				local Vel = "Speed: " .. velocity
				local Scaling = TimeText
				local place = "1"
				draw.SimpleText(stylename, "HUDcss4", ScrW() / 2.002, text_y_css + yPos + 19, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)		
				draw.SimpleText(Scaling .. " (#" .. place .. ")", "HUDcssBottomTimer", ScrW() / 2, text_y_css + yPos + 39, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Jumps: " .. jumps, "HUDcssBottom", ScrW() / 2, text_y_css + yPos + 59, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(Vel, "HUDcssBottom", ScrW() / 2.002, text_y_css + yPos + 99, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				local Scaling = surface.GetTextSize(Scaling)
				draw.RoundedBox(CSRound2, ScrW() / 2 - Scaling / 2 - 35 - 15 + 7, yPos + box_y_css, Scaling + 98 - 11, height, base)
			elseif activity == 2 then
				draw.SimpleText("In Start Zone", "HUDcss", ScrW() / 2.002, text_y_css2 + yPos + 44, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(velocity, "HUDcss", ScrW() / 2.007, text_y_css2 + yPos + 84, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css2, width, height, base)
			elseif activity == 3 then
				local Vel2 = velocity
				draw.SimpleText(Vel2, "HUDcss", ScrW() / 2, text_y_css4 + yPos + 22, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				local Vel2 = surface.GetTextSize(Vel2)
				draw.RoundedBox(CSRound2, xPos2 - (Vel2/2), yPos + box_y_css, width2 + Vel2, height, base)
			elseif activity == 4 then
				draw.SimpleText(stylename, "HUDcss", ScrW() / 2, text_y_css2 + yPos + 20 + 22, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Time: " .. currentf, "HUDcss", ScrW() / 2, text_y_css2 + yPos + 40 + 22, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Speed: " .. velocity, "HUDcss", ScrW() / 2, text_y_css2 + yPos + 60 + 22, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css, width, height, base)
			end

			if lp():Team() == TEAM_SPECTATOR then 
				surface.SetDrawColor(Color(0,0,0,190))
				surface.DrawRect(0, ScrH() - 116.70, ScrW(), ScrH())

				draw.SimpleText(pl:Name() .. " (100)", "HUDTimer", ScrW() / 2, ScrH() - 60, Color(239, 74, 74), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)	

				surface.SetDrawColor(Color(0,0,0,190))
				surface.DrawRect(0, 0, ScrW(), ScrH()/2 * 0.218)
	
				draw.SimpleText("Counter-Terrorists :   0", "HUDSpecHud", ScrW() - 484, (ScrH() / 35) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
				draw.SimpleText("Map: " .. game.GetMap(), "HUDSpecHud", ScrW() - 220, (ScrH() / 35) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
				draw.SimpleText("Terrorists :   0", "HUDSpecHud", ScrW() - 400, (ScrH() / 18) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
				draw.SimpleText("e", "CounterStrike", ScrW() - 220, (ScrH() / 21) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
				draw.SimpleText("00:00", "HUDSpecHud", ScrW() - 184, (ScrH() / 17) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
			end
	end,

	-- Simple --
	function(pl, data)
		local base = Color(20, 20, 20, 150)
		local text = color_white
		local width = 200
		local height = 100
		local xPos = ScrW() / 2 - width / 2
		local yPos = ScrH() - 90 - height

		if data.strafe then sync = data.sync or sync return end

		local theme = Momentum
		local box = Color(0, 0, 0, 100)
		local tc = color_white
		local tc2 = Color(0, 160, 200)
		local su = Color(0, 160, 200)
		local sd = Color(200, 0, 0)
		local start = false
		local current = data.current < 0 and 0 or data.current
		local time = ConvertTimeGoing(current)

		local personal = data.pb 
		local personalf = ConvertTime(personal) .. data.recTp
		local status = "No Timer"
		local velocity = math.Round(pl:GetVelocity():Length2D())
		jumps = pl.player_jumps or 0
	
		local style = pl:GetNWInt("Style", 1)
		local stylename = Core:StyleName(style or 1) .. (pl:IsBot() and " Replay" or "")
		local personal = ConvertTime(data.pb or 0)
		local current = data.current < 0 and 0 or data.current
		local currentf = ConvertTimeGoing(current)

		jumps = pl.player_jumps or 0

		local current = data.current < 0 and 0 or data.current
		local time = ConvertTimeGoing(current)
		local szStyle = Core:StyleName(pl:GetNWInt("Style", _C.Style.Normal))
		local personal = data.pb 
		local personalf = ConvertTime(personal) .. data.recTp
		local status = "Disabled"

		if current > 0.01 then
			status = time
		end

		if pl.TnF or pl.TbF then 
			status = ConvertTime(current)
			if not pl:GetNWInt("inPractice", true) and pl.TnF or pl.TbF then 
				draw.SimpleText("Map Completed", "Simplefont", ScrW() / 2, yPos + 24, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end 
		end

		draw.SimpleText("Time: " .. status, "Simplefont", ScrW() / 2, yPos + 60, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local me = LocalPlayer()
		local ot = LocalPlayer()
		local t = nil
		if ot == me or not ot then
			t = me
		else
			t = ot
		end
			if activity == 1 then
				draw.SimpleText("Sync: " .. sync .. "%","HUDTimSimplefonter2", 1755, 1000, tc)
			end

		if current < 0.01 and not pl:GetNWInt("inPractice", true) and pl:GetMoveType() != MOVETYPE_NOCLIP then 
			draw.SimpleText("Start Zone", "Simplefont", ScrW() / 2, yPos + 92, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			--draw.SimpleText(_C.Ranks[pl:GetNWInt("Rank", -1)][1], "Simplefont", ScrW() / 2, yPos + 123, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(velocity .. " u/s", "Simplefont", ScrW() / 2, yPos - 520, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText(szStyle, "Simplefont", ScrW() / 2, yPos + 92, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(velocity .. " u/s", "Simplefont", ScrW() / 2, yPos - 520, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Sync: " .. sync .. "%", "Simplefont", 1755, 1000, tc)
			draw.SimpleText("Jumps: " .. jumps or 0, "Simplefont", 100, 1000, tc)
		end

		if not pl:IsBot() and pl:GetNWInt("inPractice", true) then 
			draw.SimpleText("Practicing", "Simplefont", ScrW() / 2, yPos + 24, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local wr, wrn
		if not WorldRecords or not WorldRecords[style] or #WorldRecords[style] == 0 then 
			wr = "No time recorded"
			wrn = ""
		else 
			wr = ConvertTime(WorldRecords[pl:GetNWInt("Style", 1)][2])
			wrn = "(" .. WorldRecords[pl:GetNWInt("Style", 1)][1] .. ")"
		end

		local pbtext
		if data.pb == 0 then 
			pbtext = "No time recorded"
		else 
			pbtext = ConvertTime(data.pb or 0)
		end

		draw.SimpleText("Map: " .. game.GetMap(), "Simplefont", 10, 8, tc, TEXT_ALIGN_LEFT)
		draw.SimpleText("World Record: " .. wr .. " " .. wrn, "Simplefont", 9, 28, tc)
		draw.SimpleText("Personal Best: " .. pbtext, "Simplefont", 10, 48, tc)	

		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )
				local header, pla
				if ob:IsBot() then
					header = "Spectating"
					pla =  szStyle .. " Replay " .. "(" .. ob:GetNWString("BotName", "Loading...") .. ")"
				else
					header = "Spectating"
					pla = szStyle .. " (" .. ob:Name() .. ")"
				end
       			 if last < velocity then
       			     coll = Color(0, 160, 200)
      			  end
       			 if last > velocity then
        		    coll = Color(255,0,0)
      			  end
       			 if last == velocity then
         		   if CurTime() > (lastUp + 0.5) then
          		      coll = color_white
         		       lastUp = CurTime()
         		   end
       			 end

				local width = 200
				local height = 100
				local xPos = (ScrW() / 2) - (width / 2)
				local yPos = ScrH() - height - 60 - (lp():Team() == TEAM_SPECTATOR and 50 or 0)
      			last = current
       			draw.SimpleText(string.Split(velocity, ".")[1], "HUDTimerKindaUltraBig", ScrW() / 2, yPos - 110 + 50, coll, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, 15, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, 15, Color(0, 160, 200, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, 56, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, 56, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
			end
		end
	end,

	-- Momentum --
	function(pl, data)
		local base = Color(20, 20, 20, 150)
		local text = color_white
		local width = 200
		local height = 100
		local xPos = (ScrW() / 2) - (width / 2)
		local yPos = ScrH() - 90 - height

		if data.strafe then sync = data.sync or sync return end

		local theme = Momentum
		local box = Color(0, 0, 0, 100)
		local tc = color_white
		local tc2 = Color(0, 160, 200)
		local su = Color(0, 160, 200)
		local sd = Color(200, 0, 0)
		local start = false

		local current = data.current < 0 and 0 or data.current
		local time = cTime(current)
		local personal = data.pb 
		local personalf = ConvertTime(personal) .. data.recTp
		local status = "No Timer"
			
		if not (lp():Team() == TEAM_SPECTATOR) then 
			if type(sync) == 'number' then 
				local col = sync > 93 + 2 and su or tc
				col = sync < 90 + 2 and sd or col
				col = sync == 0 and color_white or col
				local sync2 = sync
				if sync ~= 0 then
					draw.SimpleText("Sync", "HUDTimerMedThick", ScrW() / 2, yPos + height + 10, tc, TEXT_ALIGN_CENTER)
					col = sync < 90 and sd or col
					col = sync == 0 and color_white or col
					draw.SimpleText(sync, "HUDTimerKindaUltraBig", ScrW() / 2, yPos + height + 34, col, TEXT_ALIGN_CENTER)
				end
		
				wantraindow = GetConVarNumber "kawaii_flow_rainbow"
		
				if wantraindow == 1 then
					surface.SetDrawColor(HSVToColor( RealTime() * 40 % 360, 1, 1 ))
				else
					surface.SetDrawColor(col)
				end
		
				local strafeavg = 0
				local FGG = sync
				local barWidth = FGG / 100 * (width + 10)
	
				if syncbackgroundEnabled:GetBool() then
					draw.RoundedBox(8, xPos - 10, ScrH() - 24, 215, 16, color_white)
				end

				if roundedBoxEnabled:GetBool() then
					draw.RoundedBox(8, xPos - 10, ScrH() - 24, barWidth, 16, col)  -- Rounded box option
				else
					surface.SetDrawColor(Color(200, 0, 0))  -- Set the draw color to red if rounded boxes are disabled
					surface.DrawRect(xPos - 10, ScrH() - 24, barWidth, 16)  -- Draw the rectangle as before
				end
			end
			surface.SetDrawColor(Color(200, 0, 0))  -- Set the draw color for other elements
		end

		local velocity = math.Round(pl:GetVelocity():Length2D())
		local style = pl:GetNWInt("Style", 1)
		local stylename = Core:StyleName(style or 1) .. (pl:IsBot() and " Replay" or "")
		local personal = ConvertTime(data.pb or 0)
		local current = data.current < 0 and 0 or data.current
		local currentf = cTime(current)

		jumps = pl.player_jumps or 0
		local speed = lp():GetVelocity():Length2D()
		pl.speedcol = pl.speedcol or tc
		pl.current = pl.current or 0 
		local speed = lp():GetVelocity():Length2D()
		local diff = speed - pl.current
		
		if pl.current == speed or speed == 0 then 
			pl.speedcol = tc
		elseif diff > -2 then 
			pl.speedcol = su
		elseif diff < -2 then
			pl.speedcol = sd
		end
		
		-- Slope detection
		local plyPos = lp():GetPos()
		local start = plyPos + Vector(0, 0, 3)  -- Start slightly above player's feet
		local endpos = plyPos - Vector(0, 0, 7) -- End below the player's feet (adjust as needed)
		
		local tr = util.TraceLine({
			start = start,
			endpos = endpos,
			mask = MASK_PLAYERSOLID_BRUSHONLY  -- Adjust the mask based on your collision setup
		})
		
		if tr.Hit and tr.HitNormal.z < 0.97 then
			pl.speedcol = Color(255, 0, 255)  -- Change to purple color when on a slope
		end

		if not (lp():Team() == TEAM_SPECTATOR) then 
			draw.SimpleText(math.Round(speed), "HUDTimerKindaUltraBig", ScrW() / 2, yPos - 80, (pl:GetMoveType() == MOVETYPE_NOCLIP) and tc or pl.speedcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local width = 200
		local height = 100
		local xPos = (ScrW() / 2) - (width / 2)
		local yPos = ScrH() - height - 60

		local activity = current > 0 and 1 or 2
		activity = (pl:GetNWInt("inPractice", false) or (pl.TnF or pl.TbF)) and 3 or activity
		activity = activity == 1 and (pl:IsBot() and 4 or 1) or activity

		surface.SetDrawColor(Color(200, 0, 0))
		surface.SetDrawColor(box)

		if roundedBoxEnabled:GetBool() then
			draw.RoundedBox(8, xPos, yPos - 30, width, height, box)
		else
			surface.SetDrawColor(box)
			surface.DrawRect(xPos, yPos - 30, width, height)
		end

		local current = data.current < 0 and 0 or data.current
		local time = cTime(current)
		local time_prog = ConvertTime(current)
		local personal = data.pb 
		local personalf = ConvertTime(personal) .. data.recTp
		local status = "No Timer"

		if current > 0.01 then
			status = time
		end

		if not pl:GetNWInt("inPractice", true) and pl.TnF or pl.TbF then 
			status = cTime(current)
			if not pl:GetNWInt("inPractice", true) and pl.TnF or pl.TbF then 
				draw.SimpleText("Map Completed", "HUDTimer", ScrW() / 2, yPos - 40, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end 
		end

		local style = pl:GetNWInt("Style", 1)
		local worldRecord = WorldRecords[style]
		
		local worldRecordTime
		if worldRecord and worldRecord[2] then
			worldRecordTime = ConvertTime(worldRecord[2])
		end
		
		if worldRecordTime and time_prog > worldRecordTime then
			wrc = Color(255, 0, 0)
		else
			wrc = color_white
		end

		draw.SimpleText(status or 0, "HUDTimerKindaUltraBig", ScrW() / 2, yPos - 10, wrc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if current < 0.01 and not pl:GetNWInt("inPractice", true) and pl:GetMoveType() != MOVETYPE_NOCLIP then 
			draw.SimpleText("Start Zone", "HUDTimer", ScrW() / 2, yPos - 40, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		if not pl:IsBot() and pl:GetNWInt("inPractice", true) then 
			draw.SimpleText("Practicing", "HUDTimer", ScrW() / 2, yPos - 40, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local wr, wrn
		if (not WorldRecords) or (not WorldRecords[style]) or (#WorldRecords[style] == 0) then
			wr = "No time recorded"
			wrn = ""
		else 
			wr = ConvertTime(WorldRecords[pl:GetNWInt("Style", 1)][2])
			wrn = "(" .. WorldRecords[pl:GetNWInt("Style", 1)][1] .. ")"
		end

		local pbtext
		if data.pb == 0 then
			pbtext = "No time recorded"
		else
			pbtext = ConvertTime(data.pb or 0)
		end

		local mapText = "Map: " .. game.GetMap()
		local mapX = 10
		local mapY = 8
		local shadowColor = Color(0, 0, 0, 150)  -- Shadow color (semi-transparent black)
		local textColor = color_white  -- Text color
		draw.SimpleText(mapText, "HUDTimer", mapX + 1, mapY + 1, shadowColor, TEXT_ALIGN_LEFT)
		draw.SimpleText(mapText, "HUDTimer", mapX, mapY, textColor, TEXT_ALIGN_LEFT)
	
		-- Calculate rainbow color based on time
		local rainbowColor = HSVToColor(RealTime() * 40 % 360, 1, 1)
		
		-- Define text properties
		local textOffsetX = 9
		local textOffsetY = 28
		local textSpacing = 0
	
		-- Draw "World Record:" text with rainbow effect and shadow
		local wrText = "World Record: " .. wr .. " " .. wrn
		for i = 1, #wrText do
			local char = wrText:sub(i, i)
			local charColor = rainbowTextEnabled and HSVToColor((i * 30 + RealTime() * 50) % 360, 1, 1) or color_white
			draw.SimpleText(char, "HUDTimer", textOffsetX + 1, textOffsetY + 1, shadowColor)
			draw.SimpleText(char, "HUDTimer", textOffsetX, textOffsetY, charColor)
			textOffsetX = textOffsetX + surface.GetTextSize(char) + textSpacing
		end
	
		-- Reset text properties for the next text element
		textOffsetX = 10
		textOffsetY = 48

		local globalWR = getGlobalWRForCurrentMap()
		draw.SimpleText("Global WR: " .. globalWR, "HUDTimer", 11, 69, Color(0, 0, 0, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("Global WR: " .. globalWR, "HUDTimer", 10, 68, tc)

		-- Draw "Personal Best:" text with rainbow effect and shadow
		local pbText = "Personal Best: " .. pbtext
		for i = 1, #pbText do
			local char = pbText:sub(i, i)
			local charColor = rainbowTextEnabled and HSVToColor((i * 30 + RealTime() * 50) % 360, 1, 1) or color_white
			draw.SimpleText(char, "HUDTimer", textOffsetX + 1, textOffsetY + 1, shadowColor)
			draw.SimpleText(char, "HUDTimer", textOffsetX, textOffsetY, charColor)
			textOffsetX = textOffsetX + surface.GetTextSize(char) + textSpacing
		end
		local current = math.Round(lp():GetVelocity():Length2D())
		if not (lp():Team() == TEAM_SPECTATOR) then 
			local width = 200
			local height = 100
			local xPos = (ScrW() / 2) - (width / 2)
			local yPos = ScrH() - height - 60 - (lp():Team() == TEAM_SPECTATOR and 50 or 0)
		end
		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )

				if ob:IsBot() then
					draw.SimpleText("Status: Playing (1x)", "HUDTimer", ScrW() / 2, yPos + 48, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				local header, pla
				if ob:IsBot() then
					header = "Spectating"
					pla =  szStyle .. " Replay " .. "(" .. ob:GetNWString("BotName", "Loading...") .. ")"
				else
					header = "Spectating"
					pla = szStyle .. " (" .. ob:Name() .. ")"
				end
       			 if last < velocity then
       			     coll = Color(0, 160, 200)
      			  end
       			 if last > velocity then
        		    coll = Color(255,0,0)
      			  end
       			 if last == velocity then
         		   if CurTime() > (lastUp + 0.5) then
          		      coll = color_white
         		       lastUp = CurTime()
         		   end
       			 end

				if pl:IsBot() then
					local per = math.ceil((time / data.pb) * 100) or 0
					draw.SimpleText("Progress: " .. per .. "%" or 0, "HUDTimer", ScrW() / 2, yPos - 44, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end

				local width = 200
				local height = 100
				local xPos = (ScrW() / 2) - (width / 2)
				local yPos = ScrH() - height - 60 - (lp():Team() == TEAM_SPECTATOR and 50 or 0)
      			last = current
       			draw.SimpleText(string.Split(velocity, ".")[1], "HUDTimerKindaUltraBig", ScrW() / 2, yPos - 110 + 50, coll, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, 15, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, 15, Color(0, 160, 200, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, 56, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, 56, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
			end
		end
	end,

	-- Flow Network
	function(pl, data)
		-- Size
		local width = 230
		local height = 95

		-- Positions
		local xPos = data.pos[1] 
		local yPos = data.pos[2]

		-- Colours
		local BASE = Settings:GetValue("PrimaryCol")
		local INNER = Settings:GetValue("SecondaryCol")
		local TEXT = Settings:GetValue("TextCol")
		local BAR = Settings:GetValue("AccentCol")
		local OUTLINE = Settings:GetValue("Outlines") and color_black or Color(0, 0, 0, 0)

		--local theme = Theme:Get("hud.flow.redesign")
		--local BASE = theme["Colours"]["Primary Colour"]
		--local INNER = theme["Colours"]["Secondary Colour"]
		--local BAR = theme["Colours"]["Accent Colour"]
		--local TEXT = theme["Colours"]["Text Colour"]
		--local OUTLINE = theme["Toggles"]["Outlines"] and color_black or Color(0, 0, 0, 0)

		-- Strafe HUD?
		if (data.strafe) then 
			xPos = xPos + 5

			-- Height/Width is a bit different on this
			height = height + 35
			width = width

			-- Easy calculations
			local x, y, w, h = 0, 0, 0, 0

			-- Draw base 
			surface.SetDrawColor(BASE)
			surface.DrawRect(ScrW() - xPos - width, ScrH() - yPos - height, width + 5, height)

			-- Draw inners
			surface.SetDrawColor(INNER)
			surface.DrawRect(ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 5), width - 5, 55)
			
			-- A
			x, y, w, h = ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 65), (width / 2) - 5, 27
			surface.SetDrawColor(data.a and BAR or INNER)
			surface.DrawRect(x, y, w, h)
			draw.SimpleText("A", "HUDTimer", x + w/2, y + h/2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			-- D
			x, y = ScrW() - xPos + 5 - width/2, ScrH() - yPos - (height - 65)
			surface.SetDrawColor(data.d and BAR or INNER)
			surface.DrawRect(x, y, w, h)
			draw.SimpleText("D", "HUDTimer", x + w/2, y + h/2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			-- Left
			x, y = ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 97)
			surface.SetDrawColor(data.l and BAR or INNER)
			surface.DrawRect(x, y, w, h)
			draw.SimpleText("Mouse Left", "HUDTimer", x + w/2, y + h/2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			-- Right
			x = ScrW() - xPos + 5 - width/2
			surface.SetDrawColor(data.r and BAR or INNER)
			surface.DrawRect(x, y, w, h)
			draw.SimpleText("Mouse Right", "HUDTimer", x + w/2, y + h/2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			-- Extra Keys
			x, y = ScrW() - xPos + 15 - width, ScrH() - yPos - (height - 20)
			draw.SimpleText("Extras: ", "HUDTimer", x, y, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Strafes
			draw.SimpleText("Strafes: " .. (data.strafes or 0), "HUDTimer", x, y + 23, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			x = ScrW() - xPos - 10
			draw.SimpleText("Duck", "HUDTimer", x, y, data.duck and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Jump", "HUDTimer", x - 42, y, data.jump and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText("S", "HUDTimer", x - 88, y, data.s and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText("W", "HUDTimer", x - 108, y, data.w and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText((data.sync or "Sync: 0%"), "HUDTimer", x, y + 23, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

			-- Outlines
			surface.SetDrawColor(OUTLINE)
			surface.DrawOutlinedRect(ScrW() - xPos - width, ScrH() - yPos - height, width + 5, height)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 5), width - 5, 55)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 65), (width / 2) - 5, 27)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width/2, ScrH() - yPos - (height - 65), (width / 2) - 5, 27)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 97), (width / 2) - 5, 27)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width/2, ScrH() - yPos - (height - 97), (width / 2) - 5, 27)

			return 
		end

		-- In spec
		if LocalPlayer():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )
				
				local header, pla
				if ob:IsBot() then
					header = "Spectating Bot"
					pla =  ob:GetNWString("BotName", "Loading...") .. " (" .. szStyle .. " style)"
				else
					header = "Spectating"
					pla = ob:Name() .. " (" .. szStyle .. ")"
				end

				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, ScrH() - 58 - 40, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, ScrH() - 60 - 40, Color(214, 59, 43, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, ScrH() - 18 - 40, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, ScrH() - 20 - 40, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
			end
		end

		-- Current Vel
		local velocity = math.floor(pl:GetVelocity():Length2D())

		-- Strings
		local time = "Time: "
		local pb = "PB: "

		-- Personal best
		local personal = data.pb 
		local personalf = ConvertTime(personal) .. data.recTp

		-- Current Time
		local current = data.current < 0 and 0 or data.current
		local currentf = ConvertTime(current) .. data.curTp

		-- Start Zone
		if pl:GetNWInt("inPractice", false) then 
			currentf = ""
			personalf = ""
			time = "Timer Disabled"
			pb = "Practice mode has no timer"
		elseif (current <= 0) and (not pl:IsBot()) then 
			currentf = ""
			personalf = ""
			time = "Timer Disabled"
			pb = "Leave the zone to start timer"
		end

		-- Draw base 
		surface.SetDrawColor(BASE)
		surface.DrawRect(xPos, ScrH() - yPos - 95, width, height)

		-- Draw inners
		surface.SetDrawColor(INNER)
		surface.DrawRect(xPos + 5, ScrH() - yPos - 90, width - 10, 55)
		surface.DrawRect(xPos + 5, ScrH() - yPos - 30, width - 10, 25)

		-- Bar
		local cp = math.Clamp(velocity, 0, 3500) / 3500
		surface.SetDrawColor(BAR)
		surface.DrawRect(xPos + 5, ScrH() - yPos - 30, cp * 220, 25)

		-- Text
		draw.SimpleText(time, "HUDTimer", (currentf != "" and xPos + 12 or xPos + width / 2), ScrH() - yPos - 75, TEXT, (currentf != "" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER), TEXT_ALIGN_CENTER)
		draw.SimpleText(pb, "HUDTimer", (currentf != "" and xPos + 13 or xPos + width / 2), ScrH() - yPos - 50, TEXT, (currentf != "" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER), TEXT_ALIGN_CENTER)
		draw.SimpleText(velocity .. " u/s", "HUDTimer", xPos + 115, ScrH() - yPos - 18, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(currentf, "HUDTimer", xPos + width - 12, ScrH() - yPos - 75, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText(personalf, "HUDTimer", xPos + width - 12, ScrH() - yPos - 50, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		-- Draw Outlines
		surface.SetDrawColor(OUTLINE)
		surface.DrawOutlinedRect(xPos, ScrH() - yPos - 95, width, height)
		surface.DrawOutlinedRect(xPos + 5, ScrH() - yPos - 90, width - 10, 55)
		surface.DrawOutlinedRect(xPos + 5, ScrH() - yPos - 30, width - 10, 25)
	end,

	-- Stellar Mod --
	function(pl, data)
		local ScrWidth, ScrHeight = ScrW, ScrH
		local w, h = ScrWidth(), ScrHeight()

			if data.strafe then sync = data.sync or sync return end

			local velocity = math.Round(pl:GetVelocity():Length2D())
			local time = "Time: "
			local pb = "Best: "
			local style = pl:GetNWInt("Style", 1)
			local stylename = Core:StyleName(style or 1) .. (pl:IsBot() and "" or "")
			local personal = ConvertTime(data.pb or 0)
			local current = data.current < 0 and 0 or data.current
			local currentf = ConvertTimeSM(current)

			CreateClientConVar( "kawaii_stellar_trans", "255", true, false, "kawaii stellar hud" )
			local trans = GetConVarNumber "kawaii_stellar_trans"
			CreateClientConVar("kawaii_stellar_trans", trans)

			jumps = pl.player_jumps or 0
			local base = Color(20, 20, 20, trans)
			local activity = current > 0 and 1 or 2
			activity = (pl:GetNWInt("inPractice", false) or (pl.TnF or pl.TbF)) and 3 or activity
			activity = activity == 1 and (pl:IsBot() and 4 or 1) or activity

			local box_y_css = -8
			local box_y_css2 = -8
			local text_y_css = -8
			local text_y_css2 = -8
			local text_y_css4 = -8
			local width = {162, 162, 162, 162}
			local width2 = {162, 162, 162, 162}

			width = width[activity]
			width2 = width2[activity]
			local height = {136, 136, 136, 136}
			height = height[activity]
			local activity_y = {58, 58, 58, 58}
			activity_y = activity_y[activity]

			local xPos = (ScrW()/2) - (width/2)
			local xPos2 = (ScrW()/2) - (width2/2)
			local yPos = ScrH() - height - activity_y
			local CSRound2 = 8
			local wrtext = "WR: "

			local wr, wrn
			if not WorldRecords or not WorldRecords[style] or #WorldRecords[style] == 0 then 
				wr = "No Record"
				wrn = ""
			else 
				wr = ConvertTime(WorldRecords[pl:GetNWInt("Style", 1)][2])
				wrn = "(" .. WorldRecords[pl:GetNWInt("Style", 1)][1] .. ")"
			end

			local pbtext
			if data.pb == 0 then 
				pbtext = "No Time"
			else 
				pbtext = cCTime(data.pb or 0)
			end

			local pbtop
			if data.pb == 0 then 
				pbtop = "No Time"
			else 
				pbtop = ConvertTime(data.pb or 0)
			end

			draw.SimpleText("WR: " .. wr .. " " .. wrn, "HUDcssBottom", 19, 24, color_white, text, TEXT_ALIGN_LEFT)
			draw.SimpleText(pb .. pbtop, "HUDcssBottom", 19, 50, color_white, text, TEXT_ALIGN_LEFT)	
			draw.SimpleText("Map: " .. game.GetMap(), "HUDcssBottom", 1670, 24, color_white, text, TEXT_ALIGN_LEFT)	
			if activity == 1 then
				local TimeText = "Time: " .. currentf
				local Vel = "Speed: " .. velocity
				local Scaling = TimeText
				local placement = "1"
				local Scaling = surface.GetTextSize(Scaling)
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css2, width, height, base)
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css2, width, 18, Color(40,40,40,trans))
				if trans == 255 then
					draw.RoundedBox(0, xPos, yPos + 2, width, 8, Color(40,40,40,trans))
				end
				draw.SimpleText("Map Zone", "sm_small", ScrW() / 2.002, text_y_css2 + yPos + 8, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Time: " .. currentf, "sm_small", ScrW() / 2, text_y_css + yPos + 36, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(Vel .. " u/s", "sm_small", ScrW() / 2.002, text_y_css + yPos + 59, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Style: " .. stylename, "sm_small", ScrW() / 2.002, text_y_css + yPos + 84, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Jumps: " .. jumps .. " | " .. sync .. "%", "sm_small", ScrW() / 2, text_y_css + yPos + 108, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			elseif activity == 2 then
				local TimeText = "Best: " .. pbtext
				local Vel = "Speed: " .. velocity
				local Scaling = TimeText
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css2, width, height, base)
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css2, width, 18, Color(40,40,40,trans))
				if trans == 255 then
					draw.RoundedBox(0, xPos, yPos + 2, width, 8, Color(40,40,40,trans))
				end
				draw.SimpleText("Map Zone", "sm_small", ScrW() / 2.002, text_y_css2 + yPos + 8, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Map Start Zone", "sm_small", ScrW() / 2.002, text_y_css2 + yPos + 36, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(Scaling, "sm_small", ScrW() / 2, text_y_css + yPos + 59, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Speed: " .. velocity .. " u/s", "sm_small", ScrW() / 2.007, text_y_css2 + yPos + 84, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Style: " .. stylename, "sm_small", ScrW() / 2.002, text_y_css + yPos + 108, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)	
			elseif activity == 3 then
				local TimeText = "Best: " .. pbtext
				local Vel = "Speed: " .. velocity
				local Scaling = TimeText
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css2, width, height, base)
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css2, width, 18, Color(40,40,40,trans))

				if trans == 255 then
					draw.RoundedBox(0, xPos, yPos + 2, width, 8, Color(40,40,40,trans))
				end
				draw.SimpleText("Map Zone", "sm_small", ScrW() / 2.002, text_y_css2 + yPos + 8, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Timer Disabled", "sm_small", ScrW() / 2.002, text_y_css2 + yPos + 36, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(Scaling, "sm_small", ScrW() / 2, text_y_css + yPos + 59, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Speed: " .. velocity .. " u/s", "sm_small", ScrW() / 2.007, text_y_css2 + yPos + 84, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Style: " .. stylename, "sm_small", ScrW() / 2.002, text_y_css + yPos + 108, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)	
			elseif activity == 4 then
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css, width, height - 20, base)
				draw.RoundedBox(CSRound2, xPos, yPos + box_y_css2, width, 18, Color(40,40,40,trans))
				draw.RoundedBox(0, xPos, yPos + 2, width, 8, Color(40,40,40,trans))
				draw.SimpleText("Replaying", "sm_small", ScrW() / 2.002, text_y_css2 + yPos + 8, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(stylename, "sm_small", ScrW() / 2, text_y_css2 + yPos + 20 + 22, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Time: " .. currentf, "sm_small", ScrW() / 2, text_y_css2 + yPos + 40 + 22, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("Speed: " .. velocity .. " u/s", "sm_small", ScrW() / 2, text_y_css2 + yPos + 60 + 22, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
	end,

	-- pG v3.1 --
	function(pl, data)
		local width = 230
		local height = 95
		local xPos = data.pos[1] 
		local yPos = data.pos[2]
		local BASE = Settings:GetValue("PrimaryCol")
		local INNER = Settings:GetValue("SecondaryCol")
		local TEXT = Settings:GetValue("TextCol")
		local BAR = _C.ImportantColor
		local OUTLINE = Settings:GetValue("Outlines") or Color(0, 0, 0, 0)

		if data.strafe then 
			local me = LocalPlayer()
			local ot = LocalPlayer()
			local t = nil

			if ot == me or not ot then
				t = me
			else
				t = ot
			end

			--[[if t.strafeavg then
				local ShowSync = Format("%.1f",t.strafeavg*100)
				--draw.SimpleText("Sync: " .. ShowSync .. "%", "HUDTimer", x, y + 23, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end--]]

			ShowKeys2.Color2 = color_white

			kawaiicenter = GetConVarNumber "kawaii_us_center"
			local velocity = math.Round(pl:GetVelocity():Length2D())
			local xPos2 = ScrW() / 2 - width / 2
			local yPos2 = ScrH() - 90 - height
			if kawaiicenter == 1 then
				draw.SimpleText(velocity .. " u/s", "HUDTimer2", ScrW() / 2, yPos2 - 520, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			local wantsKeys2 = ShowKeys2.Enabled2:GetBool()
			if !wantsKeys2 then return end
			if not kawaiihud == 5 then return end

			  local lpc = lp()
			  local currentPos = 0
			  local isSpectating = lpc:Team() == ts
			  local testSubject = lpc:GetObserverTarget()
			  local isValidSpectator = isSpectating and IsValid( testSubject ) and testSubject:IsPlayer()
			
			  if isValidSpectator then
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isSpecPressing(key)
				  if key == 2 and jumpTime > RealTime() then
					local pos = keyPositions[currentPos][key]
					draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					continue
				  end
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )

				  if key == 2 then
					jumpTime = RealTime() + jumpDisplay
				  end
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = testSubject:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
			  else
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isPressing(lpc, key)
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = lpc:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
				local pos = { ScrW() - 15, ScrH() - 15 }
			  end

			return 
		end
		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )

				local header, pla
				if ob:IsBot() then
					header = "Spectating Bot"
					pla =  ob:GetNWString("BotName", "Loading...") .. " (" .. szStyle .. " style)"
				else
					header = "Spectating"
					pla = ob:Name() .. " (" .. szStyle .. ")"
				end
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, ScrH() - 58 - 40, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, ScrH() - 60 - 40, Color(0, 132, 132, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, ScrH() - 18 - 40, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, ScrH() - 20 - 40, color_white, TEXT_ALIGN_CENTER )
			end
		end

		local velocity = math.Round(pl:GetVelocity():Length2D())
		local time = "Time: "
		local pb = "Best: "

		local personal = data.pb
		local personalf = ConvertTime(personal)
		local current = data.current < 0 and 0 or data.current
		local currentf = ConvertTimeGoing(current)

		surface.SetDrawColor( BASE )
		surface.DrawRect( 20, ScrH() - 145, 230, 125 )
		surface.SetDrawColor( INNER)
		surface.DrawRect( 25, ScrH() - 140, 220, 55 )
		surface.DrawRect( 25, ScrH() - 80, 220, 25 )
		surface.DrawRect( 25, ScrH() - 50, 220, 25 )

		local BarWidth = (math.Clamp( velocity, 0, 2000) / 2000 ) * 220

		wantraindow = GetConVarNumber "kawaii_flow_rainbow"

		if wantraindow == 1 then
			surface.SetDrawColor(HSVToColor( RealTime() * 40 % 360, 1, 1 ))
		else
			surface.SetDrawColor( Color(0, 132, 132, 255) )
		end

		surface.DrawRect( 25, ScrH() - 50, BarWidth, 25 )

		draw.SimpleText( velocity, "HUDFont", 135, ScrH() - 38, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		draw.SimpleText( time, "HUDFont", 30, ScrH() - 125, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( pb, "HUDFont", 30, ScrH() - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Remaining Time: " .. cTime(70 + CurTime()), "HUDFontSmall", 30, ScrH() - 68, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( currentf, "HUDFont", 120, ScrH() - 125, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( personalf, "HUDFont", 120, ScrH() - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end,

	-- George --
	function(pl, data)
		local width = 230
		local height = 95
		local xPos = data.pos[1] 
		local yPos = data.pos[2]
		local BASE = Settings:GetValue("PrimaryCol")
		local INNER = Settings:GetValue("SecondaryCol")
		local TEXT = Settings:GetValue("TextCol")
		local OUTLINE = Settings:GetValue("Outlines") or Color(0, 0, 0, 0)

		if data.strafe then 
			xPos = xPos + 5
			height = height + 35
			width = width
			local x, y, w, h = 0, 0, 0, 0
			ShowKeys2.Color2 = color_white

			kawaiicenter = GetConVarNumber "kawaii_us_center"
			local velocity = math.Round(pl:GetVelocity():Length2D())
			local xPos2 = ScrW() / 2 - width / 2
			local yPos2 = ScrH() - 90 - height
			if kawaiicenter == 1 then
				draw.SimpleText(velocity .. " u/s", "HUDTimer2", ScrW() / 2, yPos2 - 520, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			local wantsKeys2 = ShowKeys2.Enabled2:GetBool()
			if !wantsKeys2 then return end
			if not kawaiihud == 5 then return end

			  local lpc = lp()
			  local currentPos = 0
			  local isSpectating = lpc:Team() == ts
			  local testSubject = lpc:GetObserverTarget()
			  local isValidSpectator = isSpectating and IsValid( testSubject ) and testSubject:IsPlayer()
			
			  if isValidSpectator then
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isSpecPressing(key)
				  if key == 2 and jumpTime > RealTime() then
					local pos = keyPositions[currentPos][key]
					draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					continue
				  end
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )

				  if key == 2 then
					jumpTime = RealTime() + jumpDisplay
				  end
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = testSubject:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
			  else
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isPressing(lpc, key)
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = lpc:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
				local pos = { ScrW() - 15, ScrH() - 15 }
			  end

			return 
		end
		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )

				surface.SetDrawColor(Color(28, 32, 40))
				surface.DrawRect(10,10,300,30)

				surface.SetDrawColor(Color(32, 37, 46))
				surface.DrawRect(10,40,300,75)

				draw.SimpleText("Spectator Controls","VerdanaUI",170,25,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
				draw.SimpleText("Left/Right Click: Cycle through players.","VerdanaUI_B",15,55,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
				draw.SimpleText("Jump Key: Change spectator mode.","VerdanaUI_B",15,75,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
				draw.SimpleText("Reload Key: Toggle freeroam.","VerdanaUI_B",15,95,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

				surface.SetFont("VerdanaUI")
				local w, h = surface.GetTextSize(ob:Name() .. " (" .. szStyle .. ")")

				surface.SetDrawColor(Color(28, 32, 40))
				surface.DrawRect(ScrW()/2-(w+20)/2,10,w+20,30)

				surface.SetTextColor(color_white)
				surface.SetTextPos( ScrW()/2-w/2, 25-h/2 ) 
				surface.DrawText(ob:Name() .. " (" .. szStyle .. ")")
			end
		end

		local velocity = math.Round(pl:GetVelocity():Length2D())
		local personal = data.pb 
		local personalf = ConvertTime(personal)
		local current = data.current < 0 and 0 or data.current
		local currentf = ConvertTimeGoing(current)
		local style = pl:GetNWInt("Style", 1)
		local stylename = Core:StyleName(style or 1) .. (pl:IsBot() and "" or "")

		surface.SetDrawColor(Color(28, 32, 40))
		surface.DrawRect(10,ScrH()-90,200,30)
		surface.DrawRect(220,ScrH()-90,200,30)
		surface.SetDrawColor(Color(32, 37, 46))
		surface.DrawRect(10,ScrH()-60,200,50)
		surface.DrawRect(220,ScrH()-60,200,50)
	
		surface.SetDrawColor(Color(64, 69, 87))
		surface.DrawRect(20,ScrH()-50,180,30)

		local w = 0
		local v = 0

		if(pl && pl:IsValid() && pl.GetVelocity) then
			v = pl:GetVelocity():Length2D()
			local s = (math.min(v,2000))/2000
			w = math.Round(s*180)
		end

		v = math.Round(pl:GetVelocity():Length2D(v))

		wantraindow = GetConVarNumber "kawaii_flow_rainbow"

		if (w > 0) then
			if wantraindow == 1 then
				surface.SetDrawColor(HSVToColor( RealTime() * 40 % 360, 1, 1 ))
			else
				surface.SetDrawColor( Color(74, 82, 102) )
			end
			surface.DrawRect(20,ScrH()-50,w,30)
		end

		draw.SimpleText(v,"VerdanaUI",110,ScrH()-35,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText(stylename.." Timer","VerdanaUI",320,ScrH()-75,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText("Speed","VerdanaUI",110,ScrH()-75,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

		draw.SimpleText("Current:","VerdanaUI_B",230,ScrH()-45,Color(255, 255, 255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
		draw.SimpleText("Best:","VerdanaUI_B",230,ScrH()-25,Color(255, 255, 255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

		draw.SimpleText(currentf,"VerdanaUI_B",410,ScrH()-45,Color(255, 255, 255),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
		draw.SimpleText(personalf,"VerdanaUI_B",410,ScrH()-25,Color(255, 255, 255),TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER)
	end,

	-- Kawaii Flow --
	function(pl, data)
		local width = 230
		local height = 95
		local xPos = data.pos[1] 
		local yPos = data.pos[2]
		local BASE = Color(31, 31, 34, 170)
		local INNER = Color(32, 32, 36, 170)
		local TEXT = Settings:GetValue("TextCol")
		local BAR = _C.ImportantColor
		local OUTLINE = Color(0, 0, 0)

		if data.strafe then 
			xPos = xPos + 5
			height = height + 35
			width = width
			local x, y, w, h = 0, 0, 0, 0

			surface.SetDrawColor(BASE)
			surface.DrawRect(ScrW() - xPos - width, ScrH() - yPos - height, width + 5, height)

			surface.SetDrawColor(INNER)
			surface.DrawRect(ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 5), width - 5, 55)
	
			x, y, w, h = ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 65), (width / 2) - 5, 27
			surface.SetDrawColor(data.a and BAR or INNER)
			surface.DrawRect(x, y, w, h)
			draw.SimpleText("A", "HUDTimer", x + w/2, y + h/2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			x, y = ScrW() - xPos + 5 - width/2, ScrH() - yPos - (height - 65)
			surface.SetDrawColor(data.d and BAR or INNER)
			surface.DrawRect(x, y, w, h)
			draw.SimpleText("D", "HUDTimer", x + w/2, y + h/2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			x, y = ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 97)
			surface.SetDrawColor(data.l and BAR or INNER)
			surface.DrawRect(x, y, w, h)
			draw.SimpleText("Mouse Left", "HUDTimer", x + w/2, y + h/2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			x = ScrW() - xPos + 5 - width/2
			surface.SetDrawColor(data.r and BAR or INNER)
			surface.DrawRect(x, y, w, h)
			draw.SimpleText("Mouse Right", "HUDTimer", x + w/2, y + h/2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			x, y = ScrW() - xPos + 15 - width, ScrH() - yPos - (height - 20)
			draw.SimpleText("Extras: ", "HUDTimer", x, y, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			draw.SimpleText("Strafes: " .. (data.strafes or 0), "HUDTimer", x, y + 23, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			x = ScrW() - xPos - 10
			draw.SimpleText("Duck", "HUDTimer", x, y, data.duck and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Jump", "HUDTimer", x - 42, y, data.jump and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText("S", "HUDTimer", x - 88, y, data.s and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText("W", "HUDTimer", x - 108, y, data.w and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

			local me = LocalPlayer()
			local ot = LocalPlayer()
			local t = nil
			if ot == me or not ot then
				t = me
			else
				t = ot
			end

			--if t.strafeavg then
				--local ShowSync = Format("%.1f",t.strafeavg*100)
				draw.SimpleText("Sync: " .. sync .. "%","HUDTimer", x, y + 23, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			--end

			surface.SetDrawColor(OUTLINE)
			surface.DrawOutlinedRect(ScrW() - xPos - width, ScrH() - yPos - height, width + 5, height)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 5), width - 5, 55)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 65), (width / 2) - 5, 27)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width/2, ScrH() - yPos - (height - 65), (width / 2) - 5, 27)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width, ScrH() - yPos - (height - 97), (width / 2) - 5, 27)
			surface.DrawOutlinedRect(ScrW() - xPos + 5 - width/2, ScrH() - yPos - (height - 97), (width / 2) - 5, 27)

			ShowKeys2.Color2 = color_white

			kawaiicenter = GetConVarNumber "kawaii_us_center"
			local velocity = math.Round(pl:GetVelocity():Length2D())
			local xPos2 = ScrW() / 2 - width / 2
			local yPos2 = ScrH() - 90 - height
			if kawaiicenter == 1 then
				draw.SimpleText(velocity .. " u/s", "HUDTimer2", ScrW() / 2, yPos2 - 520, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			local wantsKeys2 = ShowKeys2.Enabled2:GetBool()
			if !wantsKeys2 then return end
			if not kawaiihud == 5 then return end

			  local lpc = lp()
			  local currentPos = 0
			  local isSpectating = lpc:Team() == ts
			  local testSubject = lpc:GetObserverTarget()
			  local isValidSpectator = isSpectating and IsValid( testSubject ) and testSubject:IsPlayer()
			
			  if isValidSpectator then
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isSpecPressing(key)
				  if key == 2 and jumpTime > RealTime() then
					local pos = keyPositions[currentPos][key]
					draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					continue
				  end
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )

				  if key == 2 then
					jumpTime = RealTime() + jumpDisplay
				  end
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = testSubject:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
			  else
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isPressing(lpc, key)
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = lpc:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
				local pos = { ScrW() - 15, ScrH() - 15 }
			  end

			return 
		end
		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )

				local header, pla
				if ob:IsBot() then
					header = "Spectating Bot"
					pla =  ob:GetNWString("BotName", "Loading...") .. " (" .. szStyle .. " style)"
				else
					header = "Spectating"
					pla = ob:Name() .. " (" .. szStyle .. ")"
				end
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, ScrH() - 58 - 40, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, ScrH() - 60 - 40, Color(214, 59, 43, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, ScrH() - 18 - 40, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, ScrH() - 20 - 40, color_white, TEXT_ALIGN_CENTER )
			end
		end

		local velocity = math.Round(pl:GetVelocity():Length2D())
		local time = "Time: "
		local pb = "PB: "

		local personal = data.pb 
		local personalf = ConvertTime(personal) .. data.recTp
		local current = data.current < 0 and 0 or data.current
		local currentf = ConvertTimeGoing(current) .. data.curTp

		if pl:GetNWInt("inPractice", false) then 
			currentf = ""
			personalf = ""
			time = "Timer Disabled"
			pb = "Practice mode has no timer"
		elseif current <= 0 and not pl:IsBot() then 
			currentf = ""
			personalf = ""
			time = "Timer Disabled"
			pb = "Leave the zone to start timer"
		end

		surface.SetDrawColor(BASE)
		surface.DrawRect(xPos, ScrH() - yPos - 95, width, height)

		surface.SetDrawColor(INNER)
		surface.DrawRect(xPos + 5, ScrH() - yPos - 90, width - 10, 55)
		surface.DrawRect(xPos + 5, ScrH() - yPos - 30, width - 10, 25)

		local cp = math.Clamp(velocity, 0, 3500) / 3500

		wantraindow = GetConVarNumber "kawaii_flow_rainbow"

		if wantraindow == 1 then
			surface.SetDrawColor(HSVToColor( RealTime() * 40 % 360, 1, 1 ))
		else
			surface.SetDrawColor(BAR)
		end
		
		surface.DrawRect(xPos + 5, ScrH() - yPos - 30, cp * 220, 25)

		draw.SimpleText(time, "HUDTimer", (currentf != "" and xPos + 12 or xPos + width / 2), ScrH() - yPos - 75, TEXT, (currentf != "" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER), TEXT_ALIGN_CENTER)
		draw.SimpleText(pb, "HUDTimer", (currentf != "" and xPos + 13 or xPos + width / 2), ScrH() - yPos - 50, TEXT, (currentf != "" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER), TEXT_ALIGN_CENTER)
		draw.SimpleText(velocity .. " u/s", "HUDTimer", xPos + 115, ScrH() - yPos - 18, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(currentf, "HUDTimer", xPos + width - 12, ScrH() - yPos - 75, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText(personalf, "HUDTimer", xPos + width - 12, ScrH() - yPos - 50, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		surface.SetDrawColor(OUTLINE)
		surface.DrawOutlinedRect(xPos, ScrH() - yPos - 95, width, height)
		surface.DrawOutlinedRect(xPos + 5, ScrH() - yPos - 90, width - 10, 55)
		surface.DrawOutlinedRect(xPos + 5, ScrH() - yPos - 30, width - 10, 25)
	end,

	-- pG 8.42 --
	function(pl, data)
		local width = 230
		local height = 95
		local xPos = data.pos[1] 
		local yPos = data.pos[2]
		local BASE = Color(31, 31, 34, 170)
		local INNER = Color(32, 32, 36, 170)
		local TEXT = Settings:GetValue("TextCol")
		local BAR = _C.ImportantColor
		local OUTLINE = Color(0, 0, 0)

		if data.strafe then 
			ShowKeys2.Color2 = color_white

			kawaiicenter = GetConVarNumber "kawaii_us_center"
			local velocity = math.Round(pl:GetVelocity():Length2D())
			local xPos2 = ScrW() / 2 - width / 2
			local yPos2 = ScrH() - 90 - height
			if kawaiicenter == 1 then
				draw.SimpleText(velocity .. " u/s", "HUDTimer2", ScrW() / 2, yPos2 - 520, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			local wantsKeys2 = ShowKeys2.Enabled2:GetBool()
			if !wantsKeys2 then return end
			if not kawaiihud == 5 then return end

			  local lpc = lp()
			  local currentPos = 0
			  local isSpectating = lpc:Team() == ts
			  local testSubject = lpc:GetObserverTarget()
			  local isValidSpectator = isSpectating and IsValid( testSubject ) and testSubject:IsPlayer()
			
			  if isValidSpectator then
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isSpecPressing(key)
				  if key == 2 and jumpTime > RealTime() then
					local pos = keyPositions[currentPos][key]
					draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					continue
				  end
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )

				  if key == 2 then
					jumpTime = RealTime() + jumpDisplay
				  end
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = testSubject:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
			  else
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isPressing(lpc, key)
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = lpc:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
				local pos = { ScrW() - 15, ScrH() - 15 }
			  end

			return 
		end
		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )

				local header, pla
				if ob:IsBot() then
					header = "Spectating Bot"
					pla =  ob:GetNWString("BotName", "Loading...") .. " (" .. szStyle .. " style)"
				else
					header = "Spectating"
					pla = ob:Name() .. " (" .. szStyle .. ")"
				end
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, 15, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( header, "HUDHeaderBig", ScrW() / 2, 15, Color(0, 160, 200, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, 56, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				draw.SimpleText( pla, "HUDHeader", ScrW() / 2, 56, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
			end
		end

		local velocity = math.Round(pl:GetVelocity():Length2D())

		local personal = data.pb 
		local personalf = ConvertTime(personal) .. data.recTp
		local current = data.current < 0 and 0 or data.current
		local currentf = ConvertTimeGoing(current) .. data.curTp

		local posX, posY = 0, (ScrH() - 70)
		local posYz = (ScrH() - 60)
		surface.SetDrawColor(Color(0,0,0,170))
		surface.DrawRect(xPos - 100, ScrH() - yPos - 40, width + 2000, 100)

		draw.SimpleText("Current Time:", "BottomHUDTime", 20, posY + 21, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT)
		draw.SimpleText("Current Time:", "BottomHUDTime", 20, posY + 19, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT)
		draw.SimpleText( currentf, "BottomHUDTime", 140, posY + 21, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT )
		draw.SimpleText( currentf, "BottomHUDTime", 140, posY + 19, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT )

		draw.SimpleText( "Personal Best:", "BottomHUDTime", 20, posY + 41, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT )
		draw.SimpleText( "Personal Best:", "BottomHUDTime", 20, posY + 39, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT )
		draw.SimpleText( personalf, "BottomHUDTime", 140, posY + 41, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT )
		draw.SimpleText( personalf, "BottomHUDTime", 140, posY + 39, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT  )

		local me = LocalPlayer()
		local ot = LocalPlayer()
		local t = nil
		if ot == me or not ot then
			t = me
		else
			t = ot
		end

		--if t.strafeavg then
			draw.SimpleText( "Sync: " .. sync .. "%", "BottomHUDVelocity", 1895, posYz + 32, color_black, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
			draw.SimpleText( "Sync: " .. sync .. "%", "BottomHUDVelocity", 1895, posYz + 30, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		--end

		if velocity >= 1 then
			draw.SimpleText("Velocity: " .. velocity .. " u/s", "BottomHUDVelocity", (ScrW() / 2) + 2, posYz + 30 + 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Velocity: " .. velocity .. " u/s", "BottomHUDVelocity", (ScrW() / 2) + 2, posYz + 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end,

	-- Roblox --
	function(pl, data)
		local width = 230
		local height = 95
		local xPos = data.pos[1] 
		local yPos = data.pos[2]
		local BASE = Settings:GetValue("PrimaryCol")
		local INNER = Settings:GetValue("SecondaryCol")
		local TEXT = Settings:GetValue("TextCol")
		local BAR = _C.ImportantColor
		local OUTLINE = Settings:GetValue("Outlines") or Color(0, 0, 0, 0)

		if data.strafe then 
			xPos = xPos + 5
			height = height + 35
			width = width
			local x, y, w, h = 0, 0, 0, 0

			--[[if t.strafeavg then
				local ShowSync = Format("%.1f",t.strafeavg*100)--]]
				draw.SimpleText("Sync: " .. sync .. "%","HUDTimer", x, y + 23, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			--end

			ShowKeys2.Color2 = color_white

			kawaiicenter = GetConVarNumber "kawaii_us_center"
			local velocity = math.Round(pl:GetVelocity():Length2D())
			local xPos2 = ScrW() / 2 - width / 2
			local yPos2 = ScrH() - 90 - height
			if kawaiicenter == 1 then
				draw.SimpleText(velocity .. " u/s", "HUDTimer2", ScrW() / 2, yPos2 - 520, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			local wantsKeys2 = ShowKeys2.Enabled2:GetBool()
			if !wantsKeys2 then return end
			if not kawaiihud == 5 then return end

			  local lpc = lp()
			  local currentPos = 0
			  local isSpectating = lpc:Team() == ts
			  local testSubject = lpc:GetObserverTarget()
			  local isValidSpectator = isSpectating and IsValid( testSubject ) and testSubject:IsPlayer()
			
			  if isValidSpectator then
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isSpecPressing(key)
				  if key == 2 and jumpTime > RealTime() then
					local pos = keyPositions[currentPos][key]
					draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					continue
				  end
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )

				  if key == 2 then
					jumpTime = RealTime() + jumpDisplay
				  end
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = testSubject:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
			  else
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isPressing(lpc, key)
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = lpc:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
				local pos = { ScrW() - 15, ScrH() - 15 }
			  end

			return 
		end
		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )

				local header, pla
				if ob:IsBot() then
					header = "Spectating Bot"
					pla =  ob:GetNWString("BotName", "Loading...") .. " (" .. szStyle .. " style)"
				else
					header = "Spectating"
					pla = ob:Name() .. " (" .. szStyle .. ")"
				end
				draw.SimpleText( "◀ " .. pla .. " ▶", "HUDHeader", ScrW() / 2, ScrH() - 60 - 40, color_white, TEXT_ALIGN_CENTER )
			end
		end

		local velocity = Format("%.2f",pl:GetVelocity():Length2D() / 13.5)

		local time = "Time: "
		local pb = "Record: "

		local personal = data.pb 
		local personalf = ConvertTime(personal)
		local current = data.current < 0 and 0 or data.current
		local currentf = ConvertTimeGoing(current)
		local style = pl:GetNWInt("Style", 1)
		local stylename = Core:StyleName(style or 1) .. (pl:IsBot() and "" or "")

		surface.SetDrawColor(Color(60,60,60))
		surface.DrawRect(xPos - 12, ScrH() - yPos - 95, width - 25, height + 10)

		surface.SetDrawColor(Color(45,45,45))
		surface.DrawRect(xPos - 8, ScrH() - yPos - 90, width - 9 - 25, 25)

		if current > 0.01 then
			status = time
		end

		if current > 0.01 and not pl:GetNWInt("inPractice", true) and pl:GetMoveType() != MOVETYPE_NOCLIP then 
			surface.SetDrawColor(Color(30,30,30))
		end

		surface.DrawRect(xPos - 8, ScrH() - yPos - 60, width - 9 - 25, 35)
		surface.SetDrawColor(Color(45,45,45))
		surface.DrawRect(xPos - 8, ScrH() - yPos - 20, width - 9 - 25, 25)

		local cp = math.Clamp(velocity, 0, 200) / 200

		wantraindow = GetConVarNumber "kawaii_flow_rainbow"

		if wantraindow == 1 then
			surface.SetDrawColor(HSVToColor( RealTime() * 40 % 360, 1, 1 ))
		else
			surface.SetDrawColor(Color(30,30,30))
		end
		
		surface.DrawRect(xPos - 8, ScrH() - yPos - 20, cp * 220, 25)

		if stylename == "Normal" then
			stylename = "Autohop"
		elseif stylename == "SW" then
			stylename = "Sideways"
		elseif stylename == "HSW" then
			stylename = "Half-Sideways"
		end

		 local personal
		 if data.pb == 0 then
			personal = "None    "
		 else
			personal = ConvertTime(data.pb or 0)
		 end

		draw.SimpleText(stylename, "RobloxTop", xPos + 92, ScrH() - yPos - 80, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(time, "HUDTimer", (currentf != "" and xPos or xPos + width / 2), ScrH() - yPos - 54, TEXT, (currentf != "" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER), TEXT_ALIGN_CENTER)
		draw.SimpleText(pb, "HUDTimer", (currentf != "" and xPos or xPos + width / 2), ScrH() - yPos - 34, TEXT, (currentf != "" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER), TEXT_ALIGN_CENTER)
		draw.SimpleText(velocity .. " u/s", "RobloxTop", xPos + 95, ScrH() - yPos - 8, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(currentf, "HUDTimer", xPos + width - 54, ScrH() - yPos - 54, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText(personal, "HUDTimer", xPos + width - 54, ScrH() - yPos - 34, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end,

	-- pG Old Remake --
	function(pl, data)
		local width = 230
		local height = 95
		local xPos = data.pos[1] 
		local yPos = data.pos[2]
		local BASE = Settings:GetValue("PrimaryCol")
		local INNER = Settings:GetValue("SecondaryCol")
		local TEXT = Settings:GetValue("TextCol")
		local BAR = _C.ImportantColor
		local OUTLINE = Settings:GetValue("Outlines") or Color(0, 0, 0, 0)

		if data.strafe then 
			xPos = xPos + 5
			height = height + 35
			width = width
			local x, y, w, h = 0, 0, 0, 0

			--[[if t.strafeavg then
				local ShowSync = Format("%.1f",t.strafeavg*100)--]]
				draw.SimpleText("Sync: " .. sync .. "%","HUDTimer", x, y + 23, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			--end

			ShowKeys2.Color2 = color_white

			kawaiicenter = GetConVarNumber "kawaii_us_center"
			local velocity = math.Round(pl:GetVelocity():Length2D())
			local xPos2 = ScrW() / 2 - width / 2
			local yPos2 = ScrH() - 90 - height
			if kawaiicenter == 1 then
				draw.SimpleText(velocity .. " u/s", "HUDTimer2", ScrW() / 2, yPos2 - 520, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			local wantsKeys2 = ShowKeys2.Enabled2:GetBool()
			if !wantsKeys2 then return end
			if not kawaiihud == 5 then return end

			  local lpc = lp()
			  local currentPos = 0
			  local isSpectating = lpc:Team() == ts
			  local testSubject = lpc:GetObserverTarget()
			  local isValidSpectator = isSpectating and IsValid( testSubject ) and testSubject:IsPlayer()
			
			  if isValidSpectator then
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isSpecPressing(key)
				  if key == 2 and jumpTime > RealTime() then
					local pos = keyPositions[currentPos][key]
					draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					continue
				  end
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )

				  if key == 2 then
					jumpTime = RealTime() + jumpDisplay
				  end
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = testSubject:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
			  else
				for key, text in pairs( keyStrings ) do
				  local willDisplay = isPressing(lpc, key)
				  if !willDisplay then continue end
				  local pos = keyPositions[currentPos][key]
				  text = string.upper( text )
				  draw.SimpleText( text, "HUDTimerMedThick", pos[1], pos[2], ShowKeys2.Color2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
				local currentAngle = lpc:EyeAngles().y
				local diff = norm( currentAngle - syncAxis )
				if diff > 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][128]
				  draw.SimpleText( "◀ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				elseif diff < 0 then
				  syncStill = 0
				  local pos = keyPositions[currentPos][256]
				  draw.SimpleText( "▶ ", "HUDTimerMedThick", pos[1], pos[2], ShowKeys.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				else
				  syncStill = syncStill + 1
				end
				syncAxis = currentAngle
				local pos = { ScrW() - 15, ScrH() - 15 }
			  end

			return 
		end
		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if IsValid( ob ) and ob:IsPlayer() then
				local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
				local szStyle = Core:StyleName( nStyle )

				local header, pla
				if ob:IsBot() then
					header = "Spectating Bot"
					pla =  ob:GetNWString("BotName", "Loading...") .. " (" .. szStyle .. " style)"
				else
					header = "Spectating"
					pla = ob:Name() .. " (" .. szStyle .. ")"
				end
				draw.SimpleText( "◀ " .. pla .. " ▶", "HUDHeader", ScrW() / 2, ScrH() - 60 - 40, color_white, TEXT_ALIGN_CENTER )
			end
		end

		local personal = data.pb 
		local current = data.current < 0 and 0 or data.current
		local speed = math.Round(pl:GetVelocity():Length2D())
		local recordTime = pGOldTime(personal)
		local currentTime = ConvertTimeGoing(current)

		local baseX = 10
		local baseY = ScrH() - 50
		local boxWidth = 260
		local boxHeight = 40
		local boxSpacing = 10

		-- Speed HUD Box
		draw.RoundedBox(4, baseX, baseY, boxWidth, boxHeight, Color(0, 0, 0, 150))
		draw.SimpleText("Speed", "HUDFont", baseX + 10, baseY + 10, Color(255, 255, 255), 0, 0)
		draw.SimpleText(speed .. " units/s", "HUDFont", baseX + boxWidth - 10, baseY + 10, Color(255, 255, 255), TEXT_ALIGN_RIGHT)

		-- Record HUD Box
		local recordBoxX = baseX + boxWidth + boxSpacing
		draw.RoundedBox(4, recordBoxX, baseY, boxWidth, boxHeight, Color(0, 0, 0, 150))
		draw.SimpleText("Record", "HUDFont", recordBoxX + 10, baseY + 10, Color(255, 255, 255), 0, 0)
		draw.SimpleText("Your record " .. recordTime, "HUDFont", recordBoxX + boxWidth - 10, baseY + 10, Color(255, 255, 255), TEXT_ALIGN_RIGHT)

		-- Current Time HUD Box
		local currentTimeBoxX = recordBoxX + boxWidth + boxSpacing
		draw.RoundedBox(4, currentTimeBoxX, baseY, boxWidth, boxHeight, Color(0, 0, 0, 150))
		draw.SimpleText("Current Time", "HUDFont", currentTimeBoxX + 10, baseY + 10, Color(255, 255, 255), 0, 0)
		draw.SimpleText(currentTime, "HUDFont", currentTimeBoxX + boxWidth - 10, baseY + 10, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
	end
}

-- Capture data for ssj 
local JHudStatistics = {0, 0, 0}
local JHudAnnounced = 0
net.Receive("kawaii.secret", function(_, _)
	local jumps = net.ReadInt(16)
	local gain = net.ReadFloat()
	local speed = net.ReadInt(18)

	JHudAnnounced = CurTime()
	JHudStatistics = {jumps, gain, speed}
end)


local JHudStatistics = {0, 0, 0, 0}
local JHudAnnounced = 0
net.Receive("kawaii.secret", function(_, _)
	local jumps = net.ReadInt(16)
	local gain = net.ReadFloat()
	local speed = net.ReadInt(18)
	local jss = net.ReadFloat()
	JHudAnnounced = CurTime()
	JHudStatistics = {jumps, gain, speed, jss}
end)

surface.CreateFont( "JHUD1Main", { size = 20, weight = 4000, font = "Trebuchet24" } )
surface.CreateFont( "JHUD1MainSmall", { size = 20, weight = 4000, font = "Trebuchet24" } )
surface.CreateFont( "JHUD1MainBIG", { size = 48, weight = 4000, font = "Trebuchet24" } )
surface.CreateFont( "JHUD1MainBIG2", { size = 28, weight = 4000, font = "Trebuchet24" } )

local secret = CreateClientConVar("kawaii_secret", 0, true)
local fade = 0
JHUD1OLD = {}
JHUD1OLD.Enabled = CreateClientConVar( "kawaii_jhudold", "0", true, false, "JHud Old Pos" )
local JHUD1OLD = JHUD1OLD.Enabled:GetBool()
GainCrosshair = {}
GainCrosshair.Enabled = CreateClientConVar( "kawaii_gaincrosshair", "0", true, false, "Gain colored crosshair" )
local GainCrosshair = GainCrosshair.Enabled:GetBool()

local initialData = {
    JSS = 0,
    LastTickVel = 0,
    AngleFraction = 1,
    LastUpdate = 0,
    Strafes = 0,
    Jumps = {},
    HoldingSpace = false
}

local hudSettings = {
    Enabled = false
}

local JHUD1 = {
    Data = initialData,
    HUD = hudSettings,
    DisplayData = {}
}

local counter = 0
local lastPercentage = 0    
local lastPercentageUpdate = 0
local lastCounterVal = "0"
local fading = 255
local sMessage, sAverage, color, lastUpdate = "", 0, color_black, 0

local function GetGainColor(gain)
local color = Color(255, 255, 255)
	return color
end

local function drawGain(gain)
    if JHUD1.HUD.Gain and gain then
        return gain
    else
        return ""
    end
end

local function drawStrafes(strafes)
    if JHUD1.HUD.Strafes and strafes then
        return strafes
    else
        return ""
    end
end

local function DrawJHUD1(jump, vel, sync, gain)
local width = 200
local height = 100
local xPos = ScrW() / 2 - width / 2
local yPos = ScrH() - 90 - height
local tc = color_white
kawaiijhudfix = GetConVarNumber "kawaii_secret"
if kawaiijhudfix == 0 then return end
if !lastUpdate then return end
local strafe = drawStrafes(strafes) 
local wide, tall = ScrW(), ScrH()
local font = "JHUD1MainBIG2"
local fontHeight = draw.GetFontHeight(font)

if lastUpdate + 2 < CurTime() then 
	fiou.a = fiou.a - 0.1
end

if not JHUD1.HUD.Enabled then
    return
end

color = color_white

if JHUD1.HUD.Enabled and jump and vel then
    local kawaiihud = GetConVarNumber("kawaii_jcs_hud")
    if kawaiihud == 1 or kawaiihud == 2 or kawaiihud == 4 or kawaiihud == 5 then
        return
    end

    if kawaiihud == 3 then
        if vel == 0 or jump == 0 then
            return
        end
        draw.SimpleText(jump .. sync .. ", " .. vel .. strafe, "Simplefont", ScrW() / 2, yPos + 123, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
end

local function JHUD1_UpdateSettings()
	net.Start "JHUD1_UpdateSettings"
	net.WriteBool(JHUD1.HUD.Enabled)
	net.SendToServer()
end
  
local function JHUD1_RetrieveSettings()
	JHUD1.HUD.Enabled = true
end
net.Receive( "JHUD1_RetrieveSettings", JHUD1_RetrieveSettings )

net.Receive("JHUD1_Notify", function()
local table = net.ReadTable()
local gain = net.ReadFloat()
local prestrafe = net.ReadBool()
fiou = GetGainColor(gain)
local str = ""
for k,v in pairs(table) do
	 str = str..v
end
if prestrafe then
	  str = str
hook.Add("HUDPaint", "JHUD1_Notify", function()
	DrawJHUD1(str)
 end)
  return
end

local str = string.Explode("|", str)
local jump = str[1]
local vel = str[2]
if #str > 2 then
local sync = str[3]
local gain = str[4]
local strafes = str[5]
hook.Add("HUDPaint", "JHUD1_Notify", function()
		DrawJHUD1(jump, vel, sync, gain, strafes)
	end)
	 return
end
hook.Add("HUDPaint", "JHUD1_Notify", function()
	DrawJHUD1(jump, vel)
	end)
end)

hook.Add("Think", "JHUD1_Notify", function()
	if CurTime() > lastUpdate + 1.5 then
	end
end)

JHUD12 = {
    Data = {
        JSS = 0,
        Strafes = 0,
        LastTickVel = 0,
        AngleFraction = 1,
        LastUpdate = 0,
        Jumps = {},
        HoldingSpace = false,
    },
    HUD = {
        Enabled = false,
    },
}
  
local counter = 0
local lastPercentage = 0    
local lastPercentageUpdate = 0
local lastCounterVal = "0"
local fading = 255
local sMessage, sAverage, color, lastUpdate = "", 0, Color(0,0,0), 0

local function GetGainColor(gain)
local color = Color(255, 255, 255)
	return color
end

local function DrawJHUD12(jump, vel, sync, gain, strafes)
	local width = 200
	local height = 100
	local xPos = (ScrW() / 2) - (width / 2)
	local yPos = ScrH() - 90 - height
	local tc = color_white
	
	local kawaiiJHUD12fix = GetConVarNumber("kawaii_secret")
	if kawaiiJHUD12fix == 0 or not lastUpdate then
		return
	end
	
	local wide, tall = ScrW(), ScrH()
	local font = "JHUD1MainBIG2"
	local fontHeight = draw.GetFontHeight(font)
	
	if lastUpdate + 2 < CurTime() then 
		fiou2.a = fiou2.a - 0.1
	end
	
	if not JHUD12.HUD.Enabled then
		return
	end
	
	color = color_white
	
	if jump and not vel then
		local kawaiihudlast = GetConVarNumber("kawaii_lastspeed")
		if kawaiihudlast == 1 then 
			draw.SimpleText("", "JHUD1MainBIG2", wide / 2, tall / 2 - 140, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	
	if JHUD12.HUD.Enabled and jump and vel then
		local kawaiihudlast = GetConVarNumber("kawaii_lastspeed")
		if kawaiihudlast == 1 then 
			draw.SimpleText(vel, "JHUD1MainBIG2", wide / 2, tall / 2 - 140, fiou2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		local kawaiihud = GetConVarNumber("kawaii_jcs_hud")
		if kawaiihud == 1 or kawaiihud == 2 or kawaiihud == 4 or kawaiihud == 5 then
			return
		end
	end
	
end

local function JHUD12_UpdateSettings()
	net.Start "JHUD12_UpdateSettings"
	net.WriteBool(JHUD12.HUD.Enabled)
	net.SendToServer()
end

local function JHUD12_RetrieveSettings()
	JHUD12.HUD.Enabled = true
end
net.Receive( "JHUD12_RetrieveSettings", JHUD12_RetrieveSettings )

net.Receive("JHUD12_Notify", function()
local table = net.ReadTable()
local gain = net.ReadFloat()
local prestrafe = net.ReadBool()
	fiou2 = GetGainColor(gain)
local str = ""
	for k,v in pairs(table) do
	str = str..v
	end
if prestrafe then
	str = str
	hook.Add("HUDPaint", "JHUD12_Notify", function()
		 DrawJHUD12(str)
	end)
	return
end

local str = string.Explode("|", str)
local jump = str[1]

local vel = str[2]
	  if #str > 2 then
		local sync = str[3]
		local gain = str[4]
		local strafes = str[5]
		hook.Add("HUDPaint", "JHUD12_Notify", function()
		  DrawJHUD12(jump, vel, sync, gain, strafes)
		end)
		return
	  end
 hook.Add("HUDPaint", "JHUD12_Notify", function()
	DrawJHUD12(jump, vel)
	end)
end)

hook.Add("Think", "JHUD12_Notify", function()
	if CurTime() > lastUpdate + 1.5 then
	end
end)

surface.CreateFont( "HUDTimerUltraBig", { size = 38, weight = 4000, font = "Trebuchet24" } )
surface.CreateFont( "HUDTimerKindaUltraBig", { size = 20, weight = 4000, font = "Trebuchet24" } )

local secret = CreateClientConVar("kawaii_secret", 0, true)

-- SSJ hud
local fade = 0
local function SSJ_HUD()
	local jump, gain, speed, jss = unpack(JHudStatistics)
	local color = Color(235, 49, 46)
	local color35 = Color(255, 255, 255)
	local color355 = Color(255, 255, 255)
	local color77 = Color(255, 255, 255)

     if speed > 0 then
	   if speed >= 277 then
	   	 color35 = Color(0, 160, 200)
	    else 
		  color35 = Color(255, 255, 255)
		end 
	 end

     if gain > 0 then
	   if gain >= 277 then
	   	 color35 = Color(0, 160, 200)
		end 
	 end

     if JHudAnnounced + 2 < CurTime() then 
        fade = fade + 0.5
        color35.a = math.Clamp(color35.a - fade, 0, 255)
        color35.a = color35.a
     else
        fade = 0
     end

     if JHudAnnounced + 2 < CurTime() then 
        fade = fade + 0.5
        color355.a = math.Clamp(color355.a - fade, 0, 255)
        color355.a = color355.a
     else
        fade = 0
     end

	 if JHudAnnounced + 2 < CurTime() then 
        fade = fade + 2
        color77.a = math.Clamp(color77.a - fade, 0, 255)
        color77.a = color77.a
     else
        fade = 0
     end

	if gain > 0 then
		if gain >= 80 then
			color = Color(0, 160, 200, 255)
		elseif gain > 70 and gain <= 80 then
			color = Color(39, 255, 0, 255)
		elseif gain > 60 and gain <= 70 then
			color = Color(255, 191, 0, 255)
		else
			color = Color(255, 0, 0, 255)
		end 
	end

	if JHudAnnounced + 2 < CurTime() then 
		fade = fade + 0.5
		color.a = color.a - fade 
	else
		fade = 0
	end

	local colorCR = Color(255, 255, 255)

	if gain > 0 then
		if gain >= 80 then
			colorCR = Color(0, 160, 200)
		elseif gain > 70 and gain <= 80 then
			colorCR = Color(39, 255, 0)
		elseif gain > 60 and gain <= 70 then
			colorCR = Color(255, 191, 0)
		else
			colorCR = Color(255, 255, 255)
		end 
	end

	--[[gaincrosshair = GetConVarNumber "kawaii_gaincrosshair"
	if gaincrosshair == 1 then
		surface.DrawCircle( ScrW() / 2, (ScrH() / 2) + 0.5, 4, colorCR )
		surface.DrawCircle( ScrW() / 2, (ScrH() / 2) + 0.5, 3, colorCR )
	end--]]

	gain = math.Round(gain, 2) .. "%"
	if jump <= 1 then 
		if gain == 0 then return end
		if speed == 0 then return end
		draw.SimpleText(math.Round(speed, 0), "JHUD1MainBIG", ScrW() / 2, ScrH() / 2 - 100, color355, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		if gain == 0 then return end
		if speed == 0 then return end
		draw.SimpleText(math.Round(speed, 0), "JHUD1MainBIG", ScrW() / 2, ScrH() / 2 - 100, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	local width = 200
	local height = 100
	local xPos = ScrW() / 2 - width / 2
	local yPos = ScrH() - 90 - height

	--[[if kawaiihud == 3 and jump <= 1 then
		draw.SimpleText(math.Round(speed, 0), "Simplefont", ScrW() / 2, yPos + 123, color355, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end--]]

	if jump <= 1 then
	else
		if gain == 0 then return end
		if speed == 0 then return end
		draw.SimpleText(gain, "JHUD1MainBIG2", ScrW() / 2, ScrH() / 2 - 60, color355, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if JHUD1OLD then
		if gain == 0 then return end
		if speed == 0 then return end
		if kawaiihud == 4 then
			draw.SimpleText(math.Round(speed, 0), "JHUD1Main", ScrW() / 2, ScrH() / 2 + 291, color35, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if jump <= 1 then
			else
				draw.SimpleText("(with " .. gain .. " gain)", "JHUD1Main", ScrW() / 2, ScrH() / 2 + 312, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end
end

function HUD:Draw(style, client, data) 
	self.Themes[selected_hud:GetInt()](client, data)
	if secret:GetInt() == 1 then 
		SSJ_HUD()
	end
end