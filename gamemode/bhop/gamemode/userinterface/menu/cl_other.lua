Help = {}
Help.Size = { [0] = { 700, 500 }, [1] = { 800, 580 } }
Help.Size2 = { [0] = { 700, 700 }, [1] = { 800, 700 } }

local helpDescription = {
  [0] = "Welcome to SERVER!",
  [2] = "In this gamemode you will be strafing and jumping to reach the end of the map.",
  [3] = "It is your objective to reach the end as fast as possible and compete for the",
  [4] = "best time possible.",
  [6] = "If you are new to Bunny Hop, it is recommended to watch the tutorial!",
  [7] = "To watch the tutorial, click the button below that says 'Watch Tutorial'",
  [8] = "To view settings, commands, and more information, press F1 or do !menu",
  [9] = "Be sure to read the rules using !rules",
  [11] = "Enjoy and have fun!"
}

local settingsDescription = {
  [0] = "Here are the Movement Settings for the Gamemode!   CB Edge SldingFix v4.1",
  [2] = "    ~GMod~",
  [3] = "Air-accelerate | 500",
  [4] = "Air Cap | 32.8",
  [5] = "Jump Height | 290",
  [7] = "    ~CS:S~",
  [8] = "Base Air Cap: 30.0",
  [9] = "Base Air-accelerate | 1000.0        LandFix | Disabled",
  [10] = "RNGFix Non-Jump Velocity | 140.0             Sidespeed  - 10000",
  [12] = "Max Speed Fixes | Predict Gravity Fixes        Max Speed  - 10000",
  [13] = "Bunny Hop Movement by justa",
  [14] = "JCS Movement Version 4.7"
}

local rulesDescription = {
  [1] = {
    [0] = "These are the rules for the Timer",
    [2] = "• Cheating is not allowed under any circumstances",
    [3] = "• Using exploits within the Timer gamemode is not allowed and can result",
    [4] = "in getting your Timer profile reset",
    [5] = "• Bypassing autohop is not allowed",
    [6] = "• Using map exploits can vary per map, it's best to ask an admin first"
  },
  [2] = {
    [0] = "These are the rules for the Server",
    [2] = "• Disrespecting Admins will result in a mute or a temporary ban",
    [3] = "• Admin decisions are final, arguments will lead to a mute",
    [4] = "• Spam is ok as long as it's not obnoxious, anything above will result in a mute",
    [5] = "• Begging for an elevated status can result in a mute, consider using !donate",
    [6] = "• Alternate accounts are allowed as long as the main account is not banned"
  }
}

local CommandsDescription = {
  [0] = "Here are the list of all the Commands for the Gamemode!",
  [2] = "!r - Restart",
  [3] = "!ss - Set Spawn",
  [4] = "!glock - Give Weapon",
  [5] = "!wr - WR List Menu",
  [6] = "!style - List styles",
  [7] = "!menu - Open Main Menu",
  [8] = "!strafetrainer - Display Strafe Trainer",
  [9] = "!rules - Open Server Rules",
  [10] = "!trail <mode> - Show Path Trail",
  [11] = "!jhud - Open Sashbern's jhud menu",
  [12] = "!noclip - Toggles noclip on the player.",
  [13] = "!revoke - Allows the player to revoke their RTV",
  [14] = "!cp - Opens a window for the checkpoint system menu",
  [15] = "!rank - Opens a window that shows a list of ranks",
  [16] = "!top - Opens a window that shows the best players in the server",
  [17] = "!beat - Shows the maps you have completed and your time on it",
  [18] = "!left - Shows the maps you haven't completed and their difficulty",
  [19] = "!remove - Strip yourself of all weapons",
  [20] = "!flip - Switches your weapons to the other hand",
  [21] = "!show - Sets or toggles visibililty of the players.",
  [22] = "!showspec - Allows you to change the visibility of the spectator list",
  [23] = "!triggersmenu - Open triggers and clips menu.",
  [24] = "!showspec - Allows you to change the visibility of the spectator list",
  [25] = "!runs - Change the bot (!runs [style])",
  [26] = "!map - Prints the details about the map that is currently on",
  [27] = "!end - Go to the end zone of the normal timer",
  [28] = "!endbonus - Go to the end zone of the bonus",
  [29] = "!tuto - Print link for youtube tutorials in chat.",
  [30] = "!donate - Opens our site with the donate page opened",
  [31] = "!vip - For VIPs only: opens up the VIP panel",
  [32] = "!ssj - Opens a window with ssj settings (Speed of Sixth Jump)",
  [33] = ""
}

-- Define panel variable
local panel = nil

-- Function to open Rules panel
function Help:OpenRules()
    if panel and IsValid(panel) then panel:Remove() end
    panel = nil

    RunConsoleCommand("sl_help", "0")

    local size = Help.Size[Interface.Scale]
    local boxSize = SMPanels.BoxButton[Interface.Scale]
    local bezel = Interface:GetBezel("Medium")
    local fontHeight = Interface.FontHeight[Interface.Scale]

    panel = SMPanels.HoverFrame({ title = "Bunny Hop", subTitle = "Created by: FiBzY, Edited by: justa, and ClazStudio", center = true, w = size[1], h = size[2] })

    local writeable = panel.Page
    for line, text in pairs(helpDescription) do
        SMPanels.Label({ parent = writeable, x = bezel, y = bezel + (fontHeight * line), text = text })
    end

    local posx = (writeable:GetWide() / 2) - (boxSize[1] / 2)
    local posy = (writeable:GetTall() - boxSize[2] - bezel)

    local function openTutorial()
        gui.OpenURL("https://www.youtube.com/watch?v=_0g4yq3eEUo")
    end

    SMPanels.Button({ parent = writeable, text = "Tutorial", func = openTutorial, x = posx, y = posy })
end

-- Function to open Settings panel
function Help:OpenSettings()
    if panel and IsValid(panel) then panel:Remove() end
    panel = nil

    local size = Help.Size[Interface.Scale]
    local bezel = Interface:GetBezel("Medium")
    local fontHeight = Interface.FontHeight[Interface.Scale]

    panel = SMPanels.HoverFrame({ title = "Movement Settings", subTitle = "List", center = true, w = size[1], h = size[2] })

    local writeable = panel.Page
    for line, text in pairs(settingsDescription) do
        SMPanels.Label({ parent = writeable, x = bezel, y = bezel + (fontHeight * line), text = text })
    end
end

-- Function to open RulesC panel
function Help:OpenRulesC()
    if panel and IsValid(panel) then panel:Remove() end
    panel = nil

    local size = Help.Size[Interface.Scale]
    local bezel = Interface:GetBezel("Medium")
    local fontHeight = Interface.FontHeight[Interface.Scale]

    panel = SMPanels.MultiHoverFrame({ title = "Rules Board", subTitle = "Be sure to follow these rules!", center = true, w = size[1], h = size[2], pages = { "Timer", "Server" } })

    for group, data in pairs(rulesDescription) do
        local writeable = panel.Pages[group]

        for line, text in pairs(data) do
            SMPanels.Label({ parent = writeable, x = bezel, y = bezel + (fontHeight * line), text = text })
        end
    end
end

-- Function to open Commands panel
function Help:OpenCommands()
    if panel and IsValid(panel) then panel:Remove() end
    panel = nil

    local size = Help.Size2[Interface.Scale]
    local bezel = Interface:GetBezel("Medium")
    local fontHeight = Interface.FontHeight[Interface.Scale]

    panel = SMPanels.HoverFrame({ title = "Commands", subTitle = "List of the commands", center = true, w = size[1], h = size[2] })

    local writeable = panel.Page
    for line, text in pairs(CommandsDescription) do
        SMPanels.Label({ parent = writeable, x = bezel, y = bezel + (fontHeight * line), text = text })
    end
end

-- CSS Tester function for texture checking
local CSSTestText = {
    [1] = "It appears that you do not have the Counter-Strike: Source textures!",
    [2] = "As a result, many maps will be unplayable due to this error.",
    [3] = "We highly recommend picking up these textures from the Steam Store",
    [4] = "or from another trustworthy source!"
}

local function CSSTester()
    if not Interface.Started then
        timer.Simple(0.15, function() CSSTester() end)
        return
    end

    local mat = Material("cs_italy/cobble02.vtf")
    if mat:IsError() then
        SMPanels.ContentFrame({ title = "Texture Error", center = true, content = CSSTestText })
        Surf:Notify("Error", "Failed to locate a valid Counter-Strike: Source material!")
    end
end

hook.Add("Initialize", "CSSTest", CSSTester)