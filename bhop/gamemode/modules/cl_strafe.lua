-- HUD module used for my tutorials
-- Edited: justa 
-- Made my own "HUD" module piggy back off this code


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

local StrafeAxis = 0 -- Saves the last eye angle yaw for checking mouse movement
local StrafeButtons = nil -- Saves the buttons from SetupMove for displaying
local StrafeCounter = 0 -- Holds the amount of strafes
local StrafeLast = nil -- Your last strafe key for counting strafes
local StrafeDirection = nil -- The direction of your strafes used for displaying
local StrafeStill = 0 -- Counter to reset mouse movement

local fb, ik, lp = bit.band, input.IsKeyDown, LocalPlayer
local function norm( i ) if i > 180 then i = i - 360 elseif i < -180 then i = i + 360 end return i end -- Custom function to normalize eye angles

local StrafeData -- Your Sync value is stored here
local KeyADown, KeyDDown -- For displaying on the HUD
local MouseLeft, MouseRight --- For displaying on the HUD

local ViewGUI = CreateClientConVar( "kawaii_keys", "1", true, false ) -- GUI visibility
surface.CreateFont( "HUDFont2", { size = 20, weight = 800, font = "Tahoma" } )

function ResetStrafes() StrafeCounter = 0 end -- Resets your stafes (global)
function SetSyncData( data ) StrafeData = data end -- Sets your sync data (global)

-- Monitors the buttons and angles
local function MonitorInput( ply, data )
  StrafeButtons = data:GetButtons()
  
  local ang = data:GetAngles().y
  local difference = norm( ang - StrafeAxis )
  
  if difference > 0 then
	  StrafeDirection = -1
	  StrafeStill = 0
  elseif difference < 0 then
	  StrafeDirection = 1
	  StrafeStill = 0
  else
	  if StrafeStill > 20 then
		  StrafeDirection = nil
	  end
	  
	  StrafeStill = StrafeStill + 1
  end
  
  StrafeAxis = ang
end
hook.Add( "SetupMove", "MonitorInput", MonitorInput )

-- Monitors your key presses for strafe counting
local function StrafeKeyPress( ply, key )
  if ply:IsOnGround() then return end
  
  local SetLast = true
  if key == IN_MOVELEFT or key == IN_MOVERIGHT then
	  if StrafeLast != key then
		  StrafeCounter = StrafeCounter + 1
	  end
  else
	  SetLast = false
  end
  
  if SetLast then
	  StrafeLast = key
  end
end
hook.Add( "KeyPress", "StrafeKeys", StrafeKeyPress )

-- Paints the actual HUD
local function HUDPaintB()
  if not ViewGUI:GetBool() then return end
  if not IsValid( lp() ) then return end

  local data = {pos = {20, 20}, strafe = true, r = (MouseRight != nil), l = (MouseLeft != nil)}

  -- Setting the key colors
  if StrafeButtons then
	  if fb( StrafeButtons, IN_MOVELEFT ) > 0 then 
		  data.a = true 
	  end

	  if fb( StrafeButtons, IN_MOVERIGHT ) > 0 then
		  data.d = true 
	   end
  end
  
  -- Getting the direction for the mouse
  if StrafeDirection then
	  if StrafeDirection > 0 then
		  MouseLeft, MouseRight = nil, Color( 142, 42, 42, 255 )
	  elseif StrafeDirection < 0 then
		  MouseLeft, MouseRight = Color( 142, 42, 42, 255 ), nil
	  else
		  MouseLeft, MouseRight = nil, nil
	  end
  else
	  MouseLeft, MouseRight = nil, nil
  end
  
  -- If we have buttons, display them
  if StrafeButtons then
	  if fb( StrafeButtons, IN_FORWARD ) > 0 then
		  data.w = true 
	  end
	  if fb( StrafeButtons, IN_BACK ) > 0 then
		  data.s = true
	  end
	  if ik( KEY_SPACE ) or fb( StrafeButtons, IN_JUMP ) > 0 then
		  data.jump = true 
	  end
	  if fb( StrafeButtons, IN_DUCK ) > 0 then
		  data.duck = true
	  end
  end
  
  -- Display the amount of strafes
  if StrafeCounter then
	  data.strafes = StrafeCounter
  end
  
  -- If we have sync, display the sync
  if StrafeData then
	  data.sync = StrafeData
  end
  
  HUD:Draw(2, lp():Team() == TEAM_SPECTATOR and lp():GetObserverTarget() or lp(), data)
end
hook.Add( "HUDPaint", "PaintB", HUDPaintB )

surface.CreateFont( "HUDcsstop", { size = 32, weight = 800, antialias = true, bold = true, font = "DermaDefaultBold" } )
surface.CreateFont( "HUDcss", { size = 21, weight = 800, bold = false, font = "DermaDefaultBold" } )

local function GetColour(percent)
    local offset = math.abs(1 - percent)

    if offset < 0.05 then 
        return Color(191, 64, 191)  -- Adjusted color for offset < 0.05
    elseif offset >= 0.05 and offset < 0.1 then 
        return Color(0, 200, 0)  -- Adjusted color for 0.05 <= offset < 0.1
    elseif offset >= 0.1 and offset < 0.25 then 
        return Color(220, 255, 0)  -- Adjusted color for 0.1 <= offset < 0.25
    elseif offset >= 0.25 and offset < 0.5 then 
        return Color(200, 150, 0)  -- Adjusted color for 0.25 <= offset < 0.5
    else 
        -- Get velocity magnitude directly within GetColour function
        local velocityMagnitude = LocalPlayer():GetVelocity():Length2D()

        -- Calculate the rate of whitening based on velocity magnitude
        local whiteningRate = 0.2  -- Adjust this value to control how fast the color turns whiter

        -- Adjust red value based on velocity magnitude (make it turn whiter with more speed)
        local redValue = math.Clamp(255 + (velocityMagnitude * whiteningRate), 0, 255)

        return Color(redValue, 255, 255)  -- Return adjusted color with red component turned whiter
    end
end

local value = 0 
net.Receive("train_update", function(_, _)
	value = net.ReadFloat()
end)	

STRAFETRAINER = {}
STRAFETRAINER.Enabled = CreateClientConVar("kawaii_strafetrainer", "0", true, false, "Strafe Trainer Display")

local function Display()
    local STRAFETRAINER = STRAFETRAINER.Enabled:GetBool()
    if not STRAFETRAINER then return end

    local lp = LocalPlayer()  -- Get the local player entity here

    if not IsValid(lp) then return end  -- Check if lp is valid
    if not lp:GetNWBool("strafetrainer") then return end
    if lp:GetMoveType() == MOVETYPE_NOCLIP then return end

    if not lp:KeyDown(IN_JUMP) then return end  -- Check if jump key is down

    local c = GetColour(value)
    local x = ScrW() / 2
    local y = ScrH() / 2 + 100
    local w = 240
    local size = 4
    local msize = size / 2
    local h = 14
    local movething = 22
    local spacing = 6
    local endingval = math.Round(value * 100)
    surface.SetDrawColor(c)

    if endingval >= 0 and endingval <= 200 then
        local move = w * value / 2
        surface.SetDrawColor(c)
        surface.DrawRect(x - w / 2 + move, y - movething / 2 + size / 2, size, movething)
    end

    y = y + 32
    surface.SetDrawColor(c)
    surface.DrawRect(x - w / 2 + size / 2, y, w - size, size)
    surface.SetDrawColor(color_white)
    surface.DrawRect(x - msize / 2, y + size, msize, h)
    if endingval >= 100 and endingval <= 105 then
        draw.SimpleText(endingval or 100, "HUDcss", x, y + size + spacing + h, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    else
        draw.SimpleText(100, "HUDcss", x, y + size + spacing + h, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    y = y - 32 * 2
    surface.SetDrawColor(c)
    surface.DrawRect(x - w / 2 + size / 2, y, w - size, size)
    surface.SetDrawColor(color_white)
    surface.DrawRect(x - msize / 2, y - h, msize, h)

    if endingval >= 0 and endingval <= 200 then
        local move = w * value / 2
        draw.SimpleText(endingval, "HUDcss", x, y - h - spacing, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    else
        draw.SimpleText("Out of Range", "HUDLabelSmall", x, y - h - spacing, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end
end
hook.Add("HUDPaint", "StrafeTrainer", Display)