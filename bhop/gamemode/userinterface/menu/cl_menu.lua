BHopTimer = {}
BHopTimer.Size = { [0] = { 1000, 700 }, [1] = { 800, 700 } }
BHopTimer.CustomSize = { [0] = { 350, 250 }, [1] = { 575, 375 } }

CreateClientConVar("non_table", "1", true, false, "DO nothing")

local customText = {[1] = "You can change this theme's settings with !custom",[2] = "Colors used on this theme can also be used on the Prestige Theme",[3] = "You can also apply Custom SMPanels Scheme Colors inside DevTools",}
local themeWarningText = {[1] = "This theme is not actively maintained anymore",[2] = "This means that it may be missing modern elements from other themes",[3] = "It may also cause issues with other plugins, proceed with caution!"}
local themeOptions = {[1] = "CS:S",[2] = "CS:S Shavit",[3] = "Simple",[4] = "Momentum Mod",[5] = "Flow Network",[6] = "Stellar Mod",[7] = "Prestige v3.1",[8] = "George",[9] = "Kawaii Flow",[10] = "Prestige 8.42", [11] = "Roblox", [12] = "pG Old"}
local enumeratorOptions = {[1] = "Zero",[2] = "One",[3] = "Two",[4] = "Three",[5] = "Four"}
local comparisonOptions = {[1] = "None",[2] = "PB",[3] = "WR",[4] = "Display Both",}
local sideTimerOptions = {[1] = "90",[2] = "100",[3] = "104",[4] = "105",[5] = "110"}
local angleOptions = {[1] = "1",[2] = "2",[3] = "4",[4] = "5",[5] = "14"}
local UnloadBFix = {[1] = "On/Off"}
local WRSounds = {[1] = "On/Off"}
local showKeysOptions = {[1] = "Center",[2] = "Bottom Right"}
local opacityOptions = {[1] = "Open"}
local chatTickOptions = {[1] = "warning",[2] = "buttonclick",[3] = "buttonrelease",[4] = "buttonrollover",[5] = "hint",[6] = "bell",[7] = "blip",[8] = "click",[9] = "downloaded",[10] = "balloon",[11] = "lowammo",[12] = "beep",[13] = "message",[14] = "switch",[15] = "tick",[16] = "disable"}
local chatTickPointer = {["warning"] = "resource/warning.wav",["buttonclick"] = "ui/buttonclick.wav",["buttonrelease"] = "ui/buttonclickrelease.wav",["buttonrollover"] = "ui/buttonrollover.wav",["hint"] = "ui/hint.wav",["bell"] = "buttons/bell1.wav",["blip"] = "buttons/blip2.wav",["click"] = "garrysmod/ui_click.wav",["downloaded"] = "garrysmod/content_downloaded.wav",["balloon"] = "garrysmod/balloon_pop_cute.wav",["lowammo"] = "common/warning.wav",["beep"] = "tools/ifm/beep.wav",["message"] = "friends/message.wav",["switch"] = "buttons/lightswitch2.wav"}
local footstepOptions = {[1] = "No Footsteps",[2] = "All Footsteps",[3] = "Local Footsteps"}
local paintOptions = {[1] = "red",[2] = "black",[3] = "blue",[4] = "brown",[5] = "cyan",[6] = "green",[7] = "orange",[8] = "pink",[9] = "purple",[10] = "white",[11] = "yellow",[12] = "yellow_med",[13] = "white_med",[14] = "pink_med",[15] = "blue_med",[16] = "red_med",[17] = "cyan_large",}
local timeScaleOptions = {[1] = "0.25",[2] = "0.50",[3] = "0.75",[4] = "1.00",[5] = "1.50",[6] = "2.00",[7] = "2.50",[8] = "3.00",[9] = "4.00",[10] = "5.00"}
local emitSoundOptions = {[1] = "bongo",[2] = "country",[3] = "cuban",[4] = "dust",[5] = "dusttwo",[6] = "dustthree",[7] = "flamenco",[8] = "latin",[9] = "mirame",[10] = "piano",[11] = "pianotwo",[12] = "radio",[13] = "guit",[14] = "bubblegum",[15] = "stop"}
local chatColorPaletteOptions = {[1] = "40",[2] = "10",[3] = "60",[4] = "5"}
local recordSoundOptions = {[1] = "Classic",[2] = "Melodic",[3] = "Modern"}

local panel = nil
function BHopTimer.Open()
	if panel and IsValid( panel ) then panel:Remove() end
	panel = nil

	local size = BHopTimer.Size[Interface.Scale]
	panel = SMPanels.MultiHoverFrame( { title = "Settings Menu", subTitle = "", center = true, w = size[1], h = size[2], pages = { "Timer", "Client", "Donator", "About" } } )

	timer.Simple( 0.5, function() panel.RunAlphaTest = true end )
	panel.ThinkCompare = 0

	panel.Think = function()
		if !panel.RunAlphaTest then return end
	end

	local bezel = Interface:GetBezel( "Medium" )
	local padSize = SMPanels.ConvarSize[Interface.Scale] - 5
	local boxSize = SMPanels.GenericSize[Interface.Scale]
	local barSize = SMPanels.BarSize[Interface.Scale]
	local fontHeight = Interface.FontHeight[Interface.Scale]

	do
		local function CustomNotify()
			SMPanels.ContentFrame( { parent = panel, title = "Custom Theme Notice", center = true, content = customText } )
		end

		local function ThemeWarningNotify()
			SMPanels.ContentFrame( { parent = panel, title = "Legacy Theme Notice", center = true, content = themeWarningText } )
		end

		local panParent = panel.Pages[1]

		function BHopTimer.ChangeTheme( int )
			local themeSkin = themeOptions[int]
			if !themeSkin then return end

			RunConsoleCommand( "kawaii_jcs_hud", tostring(int - 0) )

			Link:Print( "Timer", "Your theme has been changed to " .. themeSkin .. "" )
		end

		function BHopTimer.ChangeEnumerator( int )
			local enumatorValue = enumeratorOptions[int]
			if !enumatorValue then return end

			RunConsoleCommand( "sl_enumerator", tostring(int - 1) )

			Link:Print( "Timer", "Your decimal count has been set to " .. enumatorValue .. " points" )
		end

		function BHopTimer.ChangeComparison( int )
			local comparisonValue = comparisonOptions[int]
			if !comparisonValue then return end

			RunConsoleCommand( "sl_comparison_type", tostring(int - 1) )

			Link:Print( "Timer", "Your comparison type has been set to " .. comparisonValue )
		end

		function BHopTimer.ChangeSideTimerPosition( int )
			local sideTimerValue = sideTimerOptions[int]
			if !sideTimerValue then return end

			RunConsoleCommand( "kawaii_fov", sideTimerValue )

			Link:Print( "Timer", "Your FoV has been set to " .. sideTimerValue .. "." )
		end

		function BHopTimer.ClacAnglesOptions( int )
			local angleOptions = angleOptions[int]
			if !angleOptions then return end

			RunConsoleCommand( "kawaii_view_angle", angleOptions )

			Link:Print( "Timer", "Your Clac Angles has been set to " .. angleOptions .. ", rejoin for it to take effect." )
		end

		function BHopTimer.WRSounds( int )
			RunConsoleCommand( "say", "!wrsfx " )
		end

		function BHopTimer.ST( int )
			Link:Print( "Timer", "You have edited changes to map change show triggers, rejoin to valid changes." )
		end

		function BHopTimer.SC( int )
			Link:Print( "Timer", "You have edited changes to map change clip triggers, rejoin to valid changes." )
		end

		function BHopTimer.HP( int )
			Link:Print( "Timer", "You have edited changes to hide painter, rejoin to valid changes." )
		end

		function BHopTimer.CP( int )
			Link:Print( "Timer", "You have edited changes to gain colored crosshair, rejoin to valid changes." )
		end

		function BHopTimer.TT( int )
			RunConsoleCommand( "say", "/time" )
		end

		function BHopTimer.UnloadBoosterFx( int )
			RunConsoleCommand( "say", "/gravityboosterfix " )
		end

		function BHopTimer.ChangeShowKeysPosition( int )
			local showKeysValue = showKeysOptions[int]
			if !showKeysValue then return end

			RunConsoleCommand( "kawaii_showkeys_pos", tostring(int - 1) )

			Link:Print( "Timer", "Your ShowKeys Position has been moved towards the " .. showKeysValue )
		end

		function BHopTimer.ChangeChatColorPalette( int )
			local paletteValue = chatColorPaletteOptions[int]
			if !paletteValue then return end

			RunConsoleCommand( "kawaii_skybox_speed", paletteValue )
	
			Link:Print( "Timer", "Your Skybox Speed has been set to " .. paletteValue )
		end

		function BHopTimer.ChangeRecordSound( int )
			local recordValue = recordSoundOptions[int]
			if !recordValue then return end

			RunConsoleCommand( "sl_sound_theme", tostring(int - 1) )

			Link:Print( "Timer", "Your Record Soundtrack has been set to " .. recordValue )
		end

		function BHopTimer.ChangeHUDOpacity(int)
			local opacityValue = opacityOptions[int]
			if !opacityValue then return end
			RunConsoleCommand( "kawaii_thememanager" )
		end

		local function OpenDevTools()
			panel.RunAlphaTest = false
			panel:AlphaTo( 0, 0.4, 0, function() end )
			panel:SetMouseInputEnabled( false )
			panel:SetKeyboardInputEnabled( false )

			DevTools:Open()

			timer.Simple( 0.5, function()
				panel:Remove()
				panel = nil
			end )
		end

local settings = {
    { text = "Show User Interface", convar = "sl_showgui", tip = "Toggles the user interface visibility" },
    { text = "Show Jump Hud", convar = "kawaii_secret", tip = "Toggles the visibility of the Jump Hud in your timer" },
    { text = "Show Old Jump Hud", convar = "kawaii_jhudold", tip = "Toggles the visibility of the Older Jump Hud in your timer" },
    { text = "Show Last Speed Jump Hud", convar = "kawaii_lastspeed", tip = "Toggles the visibility of the last speed Jump Hud in your timer" },
    { text = "Show Rainbow Bar", convar = "kawaii_flow_rainbow", tip = "Toggles the visibility of the rainbow Speed Bar in your timer" },
    { text = "Show Strafe Trainer", convar = "kawaii_strafetrainer", tip = "Toggles the visibility of the Strafe Trainer in your timer" },
    { text = "Enable Record Sounds", convar = "kawaii_recordsound", tip = "Toggles the record sounds on the server" },
    { text = "Enable Map Change Show Triggers", convar = "kawaii_mapchangestriggers", tip = "Toggles show triggers on map change on the server" },
    { text = "Enable Map Change Show Clips", convar = "kawaii_mapchangesclips", tip = "Toggles show clips on map change on the server" },
    { text = "Show Anti-Cheats", convar = "kawaii_anticheats", tip = "If enabled, shows the Anti-Cheat Zones, otherwise hidden" },
    { text = "Auto Hop Prediction", convar = "kawaii_autopred", tip = "If disabled, jump prediction will work like CS:S" },
    { text = "Show Spectators", convar = "sl_showspec", tip = "Toggles the visibility of the spectator listings" },
    { text = "Show Keys", convar = "kawaii_showkeys", tip = "Toggles the visibility of the showkeys plugin" },
    { text = "Show Middle Flow Keys", convar = "kawaii_showkeys_flow2", tip = "Toggles the visibility of the Flow showkeys plugin" },
    { text = "Show Side Sync", convar = "kawaii_sidesync", tip = "Toggles the visibility of the Side Sync option" },
    { text = "Enable CS:S Mouse Correction", convar = "kawaii_mousesource", tip = "Edits the Mose Sensitivity to a smoother value" },
    { text = "Show Units in Center", convar = "kawaii_us_center", tip = "Displays the unit velocity in the middle of the screenspace" },
    { text = "Show Total Time", convar = "non_table", tip = "Messages you the total time of your run when completing a stage" },
    { text = "Show Zones", convar = "kawaii_showzones", tip = "Toggles the checkpoint type on the saveloc plugin" },
    { text = "Show Speed Stats", convar = "sl_speedstats", tip = "Toggles the visibility the Zone" },
    { text = "Enable Strafe Trainer", convar = "kawaii_strafetrainer", tip = "Enables the strafetrainer display" },
    { text = "Suppress Viewpunch", convar = "kawaii_suppress_viewpunch", tip = "Enables the Suppress Viewpunch" },
    { text = "Suppress Viewpunch Weapon", convar = "bhop_weaponsway", tip = "Enables the Weapon Suppress Viewpunch" },
    { text = "CS:S Weapon Reload Loop", convar = "kawaii_css_reloading", tip = "Enables the CS:S Weapon Loop Reload" },
    { text = "Show Credits and Version", convar = "kawaii_credits", tip = "Enables credits and version display on bottom left" }
}

local y = bezel
for i, setting in ipairs(settings) do
    SMPanels.SettingBox({
        parent = panParent,
        x = bezel,
        y = y,
        text = setting.text,
        convar = setting.convar,
        tip = setting.tip,
        func = setting.func
    })
    SMPanels.SettingInfo({
        parent = panParent,
        x = bezel,
        y = y + padSize,
        text = setting.tip,
        convar = setting.convar,
        tip = ""
    })
    SMPanels.SettingInfo({
        parent = panParent,
        x = bezel,
        y = y + (padSize * 2),
        text = "",
        convar = "non_table",
        tip = ""
    })
    y = y + (padSize * 3)
end
SMPanels.EndList({
    parent = panParent,
    x = bezel,
    y = y,
    text = "",
    convar = "non_table",
    tip = ""
})

		local tmSize = panParent:GetWide() - Interface:GetTextWidth( { "Pick a Theme ⇩" }, Interface:GetFont() )
		local emSize = panParent:GetWide() - Interface:GetTextWidth( { "Set Decimal Number ↓" }, Interface:GetFont() )
		local cpSize = panParent:GetWide() - Interface:GetTextWidth( { "Set Comparison Type ↓" }, Interface:GetFont() )
		local stSize = panParent:GetWide() - Interface:GetTextWidth( { "Set FoV Value ↓" }, Interface:GetFont() )
		local skSize = panParent:GetWide() - Interface:GetTextWidth( { "Set ShowKeys Position ↓" }, Interface:GetFont() )
		local ctSize = panParent:GetWide() - Interface:GetTextWidth( { "Rainbow Skybox Speed ↓" }, Interface:GetFont() )
		local hoSize = panParent:GetWide() - Interface:GetTextWidth( { "Set a Theme ⇩" }, Interface:GetFont() )
		local bfixSize = panParent:GetWide() - Interface:GetTextWidth( { "Boosterfix ⇩" }, Interface:GetFont() )
		local WRSize = panParent:GetWide() - Interface:GetTextWidth( { "WR Sounds ⇩" }, Interface:GetFont() )
		local dtSize = panParent:GetWide() - Interface:GetTextWidth( { "Open Beta Options ⇩" }, Interface:GetFont() )
		local CVSize = panParent:GetWide() - Interface:GetTextWidth( { "Clac View ⇩" }, Interface:GetFont() )
	
		SMPanels.MultiButton( { parent = panParent, text = "Pick a Theme ⇩", tip = "Change the appearance of your Timer/GUI menus", select = themeOptions, func = BHopTimer.ChangeTheme, x = tmSize - bezel, y = bezel, norep = true } )
		SMPanels.MultiButton( { parent = panParent, text = "Set Decimal Number ⇩", tip = "Determines what the timer will round closest to", select = enumeratorOptions, func = BHopTimer.ChangeEnumerator, x = emSize - bezel, y = bezel + (boxSize * 1), norep = true } )
		SMPanels.MultiButton( { parent = panParent, text = "Set Comparison Type ⇩", tip = "Determines how your timer will compare to races", select = comparisonOptions, func = BHopTimer.ChangeComparison, x = cpSize - bezel, y = bezel + (boxSize * 2), norep = true } )
		SMPanels.MultiButton( { parent = panParent, text = "Set FOV Value ⇩", tip = "Change players FoV", select = sideTimerOptions, func = BHopTimer.ChangeSideTimerPosition, x = stSize - bezel, y = bezel + (boxSize * 3), norep = true } )
		SMPanels.MultiButton( { parent = panParent, text = "Set ShowKeys Position ⇩", tip = "Change the position of your ShowKeys", select = showKeysOptions, func = BHopTimer.ChangeShowKeysPosition, x = skSize - bezel, y = bezel + (boxSize * 4), norep = true } )
		SMPanels.MultiButton( { parent = panParent, text = "Rainbow Skybox Speed ⇩", tip = "Need Rainbow Skybox Enabled in Client Tab to work", select = chatColorPaletteOptions, func = BHopTimer.ChangeChatColorPalette, x = ctSize - bezel, y = bezel + ( boxSize * 5 ), norep = true } )
		SMPanels.MultiButton( { parent = panParent, text = "Set a Theme ⇩", tip = "Modifie la transparence de votre HUD", select = opacityOptions, func = BHopTimer.ChangeHUDOpacity, x = hoSize - bezel, y = bezel + ( boxSize * 6 ), norep = true } )
		SMPanels.MultiButton( { parent = panParent, text = "Boosterfix ⇩", tip = "Activates/Deactivates Constant BoosterFix", select = UnloadBFix, func = BHopTimer.UnloadBoosterFx, x = bfixSize - bezel, y = bezel + ( boxSize * 7 ), norep = true } )
		SMPanels.MultiButton( { parent = panParent, text = "WR Sounds ⇩", tip = "Activates/Deactivates WR Sounds", select = WRSounds, func = BHopTimer.WRSounds, x = WRSize - bezel, y = bezel + ( boxSize * 8 ), norep = true } )
		SMPanels.Button( { parent = panParent, text = "Open Beta Options ⇩", tip = "Open the new options", func = OpenDevTools, scale = true, x = dtSize - bezel, y = bezel + (boxSize * 9) } )
		SMPanels.MultiButton( { parent = panParent, text = "Clac View ⇩", tip = "Open clac view angles changer (default 4)", select = angleOptions, func = BHopTimer.ClacAnglesOptions, x = WRSize - bezel, y = bezel + ( boxSize * 10 ), norep = true } )
	end

	do
		local panParent = panel.Pages[2]
		local chattickButton = nil
		local footstepButton = nil

		function BHopTimer.ChangeChatTick( int )
			local chatTickValue = chatTickOptions[int]
			if !chatTickValue then return end

			chattickButton:SetText( "Set Chat Tick" )
			RunConsoleCommand( "sl_chattick", chatTickValue )

			Link:Print( "Timer", "Your chat tick sound is set to " .. chatTickValue )
			if chatTickPointer[chatTickValue] then
				surface.PlaySound( chatTickPointer[chatTickValue] )
			else
				if (chatTickValue == "disable") then return end

				chat.PlaySound()
			end
		end

		function BHopTimer.ChangeFootstep( int )
			local footStepValue = footstepOptions[int]
			if !footStepValue then return end

			footstepButton:SetText( "Set Footstep Preference" )
			RunConsoleCommand( "sl_footsteps", tostring(int - 1) )

			Link:Print( "Timer", "Your Footstep Preference has been set to " .. footStepValue )
		end

		local function ToggleMulticore()
			local multicoreValue = GetConVar("gmod_mcore_test"):GetBool()
			if multicoreValue then
				RunConsoleCommand( "gmod_mcore_test", "0" )
				RunConsoleCommand( "cl_threaded_bone_setup", "0" )
				RunConsoleCommand( "mat_queue_mode", "1" )
			else
				RunConsoleCommand( "gmod_mcore_test", "1" )
				RunConsoleCommand( "cl_threaded_bone_setup", "1" )
				RunConsoleCommand( "mat_queue_mode", "-1" )
			end

			Link:Print( "Timer", "Multicore Rendering has been " .. (not multicoreValue and "Enabled" or "Disabled" ) )
		end

		local settingsData = {
			{ text = "Enable Custom Chatbox", convar = "kawaii_customchatbox", tip = "Enables Kawaiiclan custom Chatbox", func = openHelp },
			{ text = "Enable Gain Crosshair", convar = "kawaii_gaincrosshair", tip = "Enables Gain Colored Chrosshair on map change", func = BHopTimer.GC },
			{ text = "Enable Hide Painter", convar = "kawaii_hidepainter", tip = "Hides painter on map change", func = BHopTimer.HP },
			{ text = "Render 3D Sky", convar = "r_3dsky", tip = "Renders the 3D skybox on maps which contain them. Disabling this will drastically improve your fps under certain scenarios" },
			{ text = "Render Skybox", convar = "r_skybox", tip = "Renders the skybox on maps which contain them." },
			{ text = "Render Dark Screen", convar = "kawaii_dark", tip = "Renders the Darker Screen." },
			{ text = "Render Rainbow Skybox", convar = "kawaii_skybox", tip = "Renders the Rainbow skybox option." },
			{ text = "Render Other Players", convar = "sl_showothers", tip = "Renders other players on the server. Disabling this will improve your fps if your graphics card struggles with player animations" },
			{ text = "Render Water Reflections", convar = "r_waterdrawreflection", tip = "Renders the water reflections. Disabling this will improve your fps on water-heavy maps" },
			{ text = "Render Speculars", convar = "mat_specular", tip = "Renders the specularity for perf testing. Disabling this will drastically improve your fps under heavy reflective maps" },
			{ text = "Render HDR Bloom", convar = "mat_bloomscale", tip = "Renders the HDR Boom. Disabling this will drastically improve your fps" },
			{ text = "Use Increased Gamma", convar = "mat_monitorgamma_tv_enabled", tip = "Increases the overall brightness by increasing the gamma." },
			{ text = "Compress Textures", convar = "mat_compressedtextures", tip = "Compress all texture materials. This doesn't affect performance in most cases." },
			{ text = "Render Zones", convar = "kawaii_showzones", tip = "Renders the zone boxes. Disabling this might improve your fps on maps with overbuffered entities" },
			{ text = "Render Flat Zones", convar = "kawaii_showflatzones", tip = "Renders the flat zone boxes. Enabling this might improve your fps on maps with overbuffered entities" },
			{ text = "Render Target IDs", convar = "sl_targetids", tip = "Renders the targetid text when looking at a player. This is enabled by default" },
			{ text = "Render Derma Blurs", convar = "sl_blur", tip = "Renders the blur animation when opening a derma panel. Disabling this will improve your fps" },
			{ text = "Display Server Messages", convar = "sl_printchat", tip = "Shows server messages in chat. This should normally be on by default. This does not disable the chat" },
			{ text = "Render Developer Bloom", convar = "sl_forcebloom", tip = "Renders the bloom used on the sandbox engine" },
			{ text = "Render Developer Blur", convar = "sl_forcemotion", tip = "Renders the motion blur used on the sandbox engine" },
			{ text = "Render Developer Focus", convar = "sl_forcefocus", tip = "Renders the toytown vision used on the sandbox engine" },
			{ text = "Render Developer Bokeh", convar = "pp_bokeh", tip = "Renders the bokeh effect used on the sandbox engine" },
			{ text = "Render Motion Blur", convar = "kawaii_css_motionblur", tip = "Renders the Motion Blur effect" },
			{ text = "Render Rainbow Zones", convar = "kawaii_rainbowzones", tip = "Renders the rainbow zones" }
		}
		
		local padSize = 30
		local panParent = panel.Pages[2]
		local bezel = 10
		local y = 10
		for i, settingsData in ipairs(settingsData) do
			SMPanels.SettingBox({
				parent = panParent,
				x = bezel,
				y = y,
				text = settingsData.text,
				convar = settingsData.convar,
				tip = settingsData.tip,
				func = settingsData.func
			})
			SMPanels.SettingInfo({
				parent = panParent,
				x = bezel,
				y = y + padSize,
				text = settingsData.tip,
				convar = settingsData.convar,
				tip = ""
			})
			SMPanels.SettingInfo({
				parent = panParent,
				x = bezel,
				y = y + (padSize * 2),
				text = "",
				convar = "non_table",
				tip = ""
			})
			y = y + (padSize * 3)
		end
		SMPanels.EndList({
			parent = panParent,
			x = bezel,
			y = y,
			text = "",
			convar = "non_table",
			tip = ""
		})
		SMPanels.EndList({ parent = panParent, x = bezel, y = bezel + (padSize * (#settingsData / 3 * 2) + padSize), text = "", convar = "non_table", tip = "" })		

		local mcSize = panParent:GetWide() - Interface:GetTextWidth( { "Toggle Multicore Rendering" }, Interface:GetFont() )
		local ctSize = panParent:GetWide() - Interface:GetTextWidth( { "Set Chat Tick ⇩" }, Interface:GetFont() )
		local fsSize = panParent:GetWide() - Interface:GetTextWidth( { "Set Footstep Preference ⇩" }, Interface:GetFont() )

		SMPanels.Button( { parent = panParent, text = "Toggle Multicore Rendering", tip = "Enables/Disables the new multicore rendering engine", func = ToggleMulticore, scale = true, x = mcSize - bezel, y = bezel } )
		chattickButton = SMPanels.MultiButton( { parent = panParent, text = "Set Chat Tick ⇩", tip = "Changes the sound that is played when a new chat message appears", select = chatTickOptions, func = BHopTimer.ChangeChatTick, x = ctSize - bezel, y = bezel + (boxSize * 1) } )
		footstepButton = SMPanels.MultiButton( { parent = panParent, text = "Set Footstep Preference ⇩", tip = "Determines when player footsteps should be played", select = footstepOptions, func = BHopTimer.ChangeFootstep, x = fsSize - bezel, y = bezel + (boxSize * 2) } )
	end

	do
		local panParent = panel.Pages[3]

		local paintColorButton = nil
		local timeScaleButton = nil
		local emitSoundButton = nil

		function BHopTimer.ChangePaintColor( int )
			local paintColor = paintOptions[int]
			if !paintColor then return end

			paintColorButton:SetText( "Paint Color" )
			RunConsoleCommand( "say", "/paintcolor " .. paintColor )
		end

		function BHopTimer.ChangeTimescale( int )
			local timeScale = timeScaleOptions[int]
			if !timeScale then return end

			timeScaleButton:SetText( "Timescale Value" )
			RunConsoleCommand( "say", "/timescale " .. timeScale )
		end

		function BHopTimer.DoEmitSound( int )
			local emitSound = emitSoundOptions[int]
			if !emitSound then return end

			emitSoundButton:SetText( "Emit Sound" )
			RunConsoleCommand( "say", "/emitsound " .. emitSound )
		end

		local function OpenVIPMenu()
			panel.RunAlphaTest = false
			panel:AlphaTo( 0, 0.4, 0, function() end )
			panel:SetMouseInputEnabled( false )
			panel:SetKeyboardInputEnabled( false )

			RunConsoleCommand( "say", "/vip" )

			timer.Simple( 0.5, function()
				panel:Remove()
				panel = nil
			end )
		end

		local function ToggleVIP()
			Link:Send( "Admin", { -2, 34, nil } )
		end

		local isVIP = LocalPlayer():GetNWBool( "VIPStatus" )
		if !isVIP then
			panParent.Paint = function( self, w, h )
				draw.SimpleText( "This requires a donator subscription running", Interface:GetFont(), bezel, bezel, color_white )
				draw.SimpleText( "You can donate to the server by using !donate", Interface:GetFont(), bezel, bezel + (fontHeight * 1), color_white )

				draw.SimpleText( "Cool benefits include:", Interface:GetFont(), bezel, bezel + (fontHeight * 3), color_white )
				draw.SimpleText( "• Custom Name/Rank with Custom Colors", Interface:GetFont(), bezel, bezel + (fontHeight * 4), color_white )
				draw.SimpleText( "• Paint Functionality", Interface:GetFont(), bezel, bezel + (fontHeight * 5), color_white )
				draw.SimpleText( "• Server Join Priority", Interface:GetFont(), bezel, bezel + (fontHeight * 6), color_white )
				draw.SimpleText( "• Early access to new features", Interface:GetFont(), bezel, bezel + (fontHeight * 7), color_white )
				draw.SimpleText( "• The feeling that you helped this server running", Interface:GetFont(), bezel, bezel + (fontHeight * 8), color_white )
			end
		else
			local tsSize = panParent:GetWide() - Interface:GetTextWidth( { "Timescale Value ⇩" }, Interface:GetFont() )
			local esSize = panParent:GetWide() - Interface:GetTextWidth( { "Play a Sound ⇩" }, Interface:GetFont() )

			paintColorButton = SMPanels.MultiButton( { parent = panParent, text = "Pick Paint Color ⇩", tip = "Determines what paint color will be used when using sm_paint in console", select = paintOptions, func = BHopTimer.ChangePaintColor, x = bezel, y = bezel } )

			timeScaleButton = SMPanels.MultiButton( { parent = panParent, text = "Timescale Value ⇩", tip = "Changes how long the engine processes your movement", select = timeScaleOptions, func = BHopTimer.ChangeTimescale, x = tsSize - bezel, y = bezel } )
			emitSoundButton = SMPanels.MultiButton( { parent = panParent, text = "Play a Sound ⇩", tip = "Plays a sound that nearby players can hear", select = emitSoundOptions, func = BHopTimer.DoEmitSound, x = esSize - bezel, y = bezel + (boxSize * 1) } )

			SMPanels.Button( { parent = panParent, text = "Open VIP Menu ⇩", tip = "Opens the donator menu", func = OpenVIPMenu, scale = true, x = bezel, y = bezel + (boxSize * 1) } )
			SMPanels.Button( { parent = panParent, text = "Toggle VIP Visibility ⇩", tip = "Determines if your VIP status (such as name/color/rank) should be displayed to everyone", func = ToggleVIP, scale = true, x = bezel, y = bezel + (boxSize * 2) } )
		end
	end

	do
		local panParent = panel.Pages[4]
		local function openCreatorsProfile()
			gui.OpenURL( "https://steamcommunity.com/id/fibzysending/" )
		end

		local function openHelp()
			panel.RunAlphaTest = false
			panel:AlphaTo( 0, 0.4, 0, function() end )
			panel:SetMouseInputEnabled( false )
			panel:SetKeyboardInputEnabled( false )

			Help:OpenRules()

			timer.Simple( 0.5, function()
				panel:Remove()
				panel = nil
			end )
		end

		local pcSize = panParent:GetWide() - Interface:GetTextWidth( { "Print Commands" }, Interface:GetFont() )

		panParent.Paint = function( self, w, h )
			draw.SimpleText( "This server runs the latest version of KawaiiClan (ver. " .. 7.26 .. ")", Interface:GetFont(), bezel, bezel, color_white )
			draw.SimpleText( "FiBzY is the maintainer of this gamemode, their profile is listed below", Interface:GetFont(), bezel, bezel + (fontHeight * 1), color_white )

			local text = "Big thanks to justa"
			local font = Interface:GetFont()
			local x = bezel
			local y = bezel + (fontHeight * 2)
			
			-- Define rainbow colors
			local rainbowColors = {
				Color(255, 0, 0),     -- Red
				Color(255, 165, 0),   -- Orange
				Color(255, 255, 0),   -- Yellow
				Color(0, 255, 0),     -- Green
				Color(0, 0, 255),     -- Blue
				Color(75, 0, 130),    -- Indigo
				Color(238, 130, 238), -- Violet
			}
			
			local colorIndex = 1 
			
			for i = 1, #text do
				local char = text:sub(i, i)
			
				draw.SimpleText(char, font, x, y, rainbowColors[colorIndex])
			
				x = x + surface.GetTextSize(char)
			
				colorIndex = colorIndex < #rainbowColors and colorIndex + 1 or 1
			end

			draw.SimpleText( "Lastest update date: 5/1/24", Interface:GetFont(), bezel, bezel + (fontHeight * 4), color_white )
	
			draw.SimpleText( "Quick command list (most commonly used):", Interface:GetFont(), bezel, bezel + (fontHeight * 6), color_white )
			draw.SimpleText( "• /restart - Takes you to the start of the map", Interface:GetFont(), bezel, bezel + (fontHeight * 7), color_white )
			draw.SimpleText( "• /setspawn - Sets the spawn point", Interface:GetFont(), bezel, bezel + (fontHeight * 8), color_white )
			draw.SimpleText( "• /styles - Gives you a list of styles to select from", Interface:GetFont(), bezel, bezel + (fontHeight * 9), color_white )
			draw.SimpleText( "• /nominate - Gives you a list of maps available on the server", Interface:GetFont(), bezel, bezel + (fontHeight * 10), color_white )
			draw.SimpleText( "• /mapinfo - Gives you a quick information about the current map", Interface:GetFont(), bezel, bezel + (fontHeight * 11), color_white )
			draw.SimpleText( "• /wr - Displays the current record holder on the current map in chat", Interface:GetFont(), bezel, bezel + (fontHeight * 12), color_white )
			draw.SimpleText( "• /rank - Displays the rank you have on the current map", Interface:GetFont(), bezel, bezel + (fontHeight * 13), color_white )
			draw.SimpleText( "• /rtv - Places your vote to change the current map to something else", Interface:GetFont(), bezel, bezel + (fontHeight * 14), color_white )
			draw.SimpleText( "• /profile - Opens a panel that contains your profile stats", Interface:GetFont(), bezel, bezel + (fontHeight * 15), color_white )
		end

		SMPanels.Button( { parent = panParent, text = "Open maintainer's profile ⇩", tip = "Opens the developer's Steam Community Profile", func = openCreatorsProfile, scale = true, x = bezel, y = panParent:GetTall() - boxSize } )
		SMPanels.Button( { parent = panParent, text = "Open Help Menu ⇩", tip = "Opens the help menu that is displayed on a new player's join", func = openHelp, scale = true, x = pcSize - bezel, y = panParent:GetTall() - boxSize } )
	end
end