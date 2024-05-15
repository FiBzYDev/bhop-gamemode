PRIMARY = Settings:GetValue("PrimaryCol")
SECONDARY = Settings:GetValue("SecondaryCol")
TRI = Settings:GetValue("TertiaryCol")
ACCENT = Settings:GetValue("AccentCol")
TEXT = Settings:GetValue("TextCol") 
OUTLINE = Settings:GetValue("Outlines")

-- Scoreboard
surface.CreateFont("hud.subinfo", {font = "Tahoma", size = 12, weight = 300, antialias = true})
surface.CreateFont("hud.smalltext", {font = "Roboto", size = 14, weight = 0, antialias = true})
surface.CreateFont("hud.subtitle", {font = "Roboto", size = 18, weight = 0, antialias = true, italic = false})
surface.CreateFont("hud.subtitleverdana", {font = "Verdana", size = 14, weight = 0, antialias = true, italic = false})
surface.CreateFont("hud.subinfo2", {font = "Roboto", size = 10, weight = 0, antialias = true})
surface.CreateFont("hud.subinfo", {font = "Roboto", size = 12, weight = 300, antialias = true})
surface.CreateFont("hud.simplefont", {font = "Roboto", size = 21, weight = 900, antialias = true})

surface.CreateFont("hud.title", {font = "coolvetica", size = 20, weight = 100, antialias = true})
surface.CreateFont("hud.title2.1", {font = "Verdana", size = 14, weight = 0, antialias = true})
surface.CreateFont("hud.smalltext", {font = "Roboto", size = 14, weight = 0, antialias = true})
surface.CreateFont("ascii.font", {font = "", size = 9, weight = 0, antialias = true})
surface.CreateFont("hud.title2", {font = "Roboto", size = 16, weight = 0, antialias = true})
surface.CreateFont("hud.credits", {font = "Tahoma", size = 12, weight = 100, antialias = true})
surface.CreateFont("zedit.cam", {font = "Roboto", size = 100, weight = 300, antialias = true})

surface.CreateFont("ui.mainmenu.close", {size = 20, weight = 1000, font = "Verdana Regular"})
surface.CreateFont("ui.mainmenu.button", {size = 18, weight = 500, font = "Roboto"})
surface.CreateFont("ui.mainmenu.button-bold", {size = 18, weight = 600, font = "Roboto"})
surface.CreateFont("ui.mainmenu.button2", {size = 19, weight = 500, font = "Roboto"})
surface.CreateFont("ui.mainmenu.desc", {size = 17, weight = 500, font = "Roboto", additive=true})
surface.CreateFont("ui.mainmenu.title", {size = 20, weight = 500, font = "Roboto"})
surface.CreateFont("ui.mainmenu.title2", {size = 20, weight = 500, font = "Roboto"})

local ranks = {"VIP", "VIP+", "Moderator", "Admin", "Zone Admin", "Super Admin", "Developer", "Manager", "Founder", "Owner"}

local function AddMessage(prefix, message)
	chat.AddText(Color(0, 200, 200), "Server", color_white, " | ", message)
end

local scoreboard 
local con = function(ns) return ConvertTime(ns) end

local fl, fo  = math.floor, string.format
local function cTime(ns)
	if ns > 3600 then
		return fo( "%d:%.2d:%.2d", fl( ns / 3600 ), fl( ns / 60 % 60 ), fl( ns % 60 ) )
	elseif ns > 60 then 
		return fo( "%.1d:%.2d", fl( ns / 60 % 60 ), fl( ns % 60 ) )
	else
		return fo( "%.1d", fl( ns % 60 ) )
	end
end

-- Initialize variables
local cycleText = {"Welcome", "Velocity"}  -- Initial text with placeholders
local cycleText2 = {"You're here!", "v7.26" .. ""}  -- Initial text with placeholders
local cycleDelay = 5  -- Delay in seconds between text changes
local lastUpdateTime = 0
local currentTextIndex = 1  -- Index to track the current text to display

-- Function to update the cycle text with player's speed and server name
local function UpdateCycleText(ply)
    if IsValid(ply) then
        local speed = math.Round(ply:GetVelocity():Length2D())  -- Get player's speed
        if speed > 33 then
          cycleText[1] = "Velocity (" .. speed .. " u/s)"  -- Update velocity in text
        end
        cycleText[2] = "your server name"  -- Update server name in text
    end
end

-- Function to update the cycle text with player's speed and server name
local function UpdateCycleText2(ply)
    if IsValid(ply) then
        local speed = math.Round(ply:GetVelocity():Length2D())  -- Get player's speed
        if speed > 33 then
          cycleText2[1] = "Velocity (" .. speed .. " u/s)"  -- Update velocity in text
        end
        cycleText2[2] = "your server name"  -- Update server name in text
    end
end

local function CreateScoreboard(shouldHide)
    if (shouldHide) then
        if not scoreboard then return end 

        CloseDermaMenus()
        scoreboard:Remove()
		scoreboard = nil
		
		gui.EnableScreenClicker(false)
		return
    end

    if scoreboard then return end 
    
    local WIDTH = 1100
    local HEIGHT = 600

    if ScrW() < WIDTH then 
        WIDTH = ScrW() * 0.9 
        HEIGHT = ScrH() * 0.5 
    end

	gui.EnableScreenClicker(false)

	scoreboard = vgui.Create("EditablePanel")
	scoreboard:SetSize(WIDTH, HEIGHT)
    scoreboard:Center()

    scoreboard.spectators = {}

    local height = 54 
    local x = 6
    local width = WIDTH - (x * 2)
    
    function scoreboard:Paint(w, h)
        PRIMARY = Color(47, 47, 47)
        SECONDARY = Color(44, 44, 44)
        TRI = Color(38, 38, 38, 255)
        ACCENT =  Color(0, 160, 200)
        TEXT = Settings:GetValue("TextCol")
        OUTLINE = Settings:GetValue("Outlines")

        surface.SetDrawColor(TRI)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(PRIMARY)
        surface.DrawRect(x, x, w - (x * 2), (height * 2) + x)

        local curTime = CurTime()

        -- Check if it's time to update the text
        if curTime - lastUpdateTime >= cycleDelay then
            lastUpdateTime = curTime
            currentTextIndex = currentTextIndex % 2 + 1  -- Cycle between 1 and 2
            UpdateCycleText(LocalPlayer())  -- Update text with local player's speed and server name
        end

        local y = (height + x + x) / 2

        draw.SimpleText(cycleText[currentTextIndex], "ui.mainmenu.title2", w / 2, y, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(game.GetMap(), "ui.mainmenu.button", x+x, (height + x + x) / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Timeleft: " .. cTime(70 + CurTime()), "ui.mainmenu.button", w - x - x, (height + x + x) / 2, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        -- Specs 
        local lst = ""
        for k, v in pairs(self.spectators) do 
            lst = lst .. v:Nick() .. ", "
        end
        
        if string.EndsWith(lst, ", ") then 
            lst = string.sub(lst, 1, #lst - 2)
        else 
            lst = "None"
        end

        draw.SimpleText("Spectators: " .. lst, "ui.mainmenu.button", x + 2, h - (height / 3) - (x / 2) + 1, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Players: " .. #player.GetHumans() .. "/" .. game.MaxPlayers()-2, "ui.mainmenu.button", w - x - 2, h - (height / 3) - (x / 2) + 1, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        if curTime - lastUpdateTime >= cycleDelay then
            lastUpdateTime = curTime
            currentTextIndex = currentTextIndex % 2 + 1  -- Cycle between 1 and 2
            UpdateCycleText2(LocalPlayer())  -- Update text with local player's speed and server name
        end

        draw.SimpleText(cycleText2[currentTextIndex], "ui.mainmenu.button", w - x - 550, h - (height / 3) - (x / 2) + 1, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    scoreboard.bots = scoreboard:Add("DPanel")
    scoreboard.bots:SetPos(x * 2, height + x)
    scoreboard.bots:SetSize(width - (x * 2), height)
    scoreboard.bots.list = {}

    scoreboard.specs = scoreboard:Add("DPanel")
    scoreboard.specs:SetPos(x, HEIGHT - 34)
    scoreboard.specs:SetSize(width, 34)
    scoreboard.specs.Paint = function() end 

    function bDermaMenu(v, a)
        local b = PRIMARY
        local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
        local col2 = Color(b.r + 10, b.g + 10, b.b + 10, 255)

        if not a then 
            scoreboard.menu = DermaMenu()
        else 
            scoreboard.menu = a 
        end 

        scoreboard.menu:SetDrawBorder(false)
        scoreboard.menu:SetDrawColumn(false)
        scoreboard.menu:SetMinimumWidth(200)
        scoreboard.menu.Paint = function(s,w,h) 
            surface.SetDrawColor(s:IsHovered() and col or col2)
            surface.DrawRect(0, 0, w, h)
        end

        if not a then 
            scoreboard.menu:AddOption("Spectate", function()
                LocalPlayer():ConCommand("say !spectate " .. v:Name())
            end)
        end 

        scoreboard.menu:AddOption("Copy SteamID", function() 
            SetClipboardText(v:IsBot() and v.steamid or v:SteamID())
            AddMessage("Server", v:Nick() .. "'s steamid copied to clipboard.")
        end)

        scoreboard.menu:AddOption("Goto Profile", function() 
            gui.OpenURL("http://www.steamcommunity.com/profiles/" .. (v:IsBot() and util.SteamIDTo64(v.steamid) or v:SteamID64()))
        end)

        if not v:IsBot() then 
            scoreboard.menu:AddSpacer()

            scoreboard.menu:AddOption("Mute Player", function() end)
            scoreboard.menu:AddOption("Gag Player", function() end)

            scoreboard.menu:AddSpacer()

            scoreboard.menu:AddOption("Kick Player", function() end)
            scoreboard.menu:AddOption("Ban Player", function() end)
        end

        for i = 1, scoreboard.menu:ChildCount() do 
            local v = scoreboard.menu:GetChild(i)

            if v.SetTextColor then 
                function v:Paint(w, h) 
                    surface.SetDrawColor(self:IsHovered() and col or col2)
                    surface.DrawRect(0, 0, w, h)
                end
                v:SetTextColor(TEXT)
                v:SetFont("ui.mainmenu.button")
                v:SetIsCheckable(false)
            else 
            end 
        end

        if not a then 
         scoreboard.menu:Open() end
    end

    function scoreboard.specs:OnMousePressed()
        local b = PRIMARY
        local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
        local col2 = Color(b.r + 10, b.g + 10, b.b + 10, 255)

        scoreboard.smenu = DermaMenu()
        self.lst = {}

        scoreboard.smenu:SetDrawBorder(false)
        scoreboard.smenu:SetDrawColumn(false)
        scoreboard.smenu:SetMinimumWidth(200)
        scoreboard.smenu.Paint = function(s,w,h) 
            surface.SetDrawColor(s:IsHovered() and col or col2)
            surface.DrawRect(0, 0, w, h)
        end

        for k, v in pairs(scoreboard.spectators) do 
            local x = scoreboard.smenu:AddSubMenu(v:Nick(), function() 
                bDermaMenu(v, self.lst[k])
            end)

            bDermaMenu(v, x)
        end 

        for i = 1, scoreboard.smenu:ChildCount() do 
            local v = scoreboard.smenu:GetChild(i)

            if v.SetTextColor then 
                function v:Paint(w, h) 
                    surface.SetDrawColor(self:IsHovered() and col or col2)
                    surface.DrawRect(0, 0, w, h)
                end
                v:SetTextColor(TEXT)
                v:SetFont("ui.mainmenu.button")
                v:SetIsCheckable(false)
            else 
            end 
        end
        scoreboard.smenu:Open()
    end 

    local gap = x / 2
    function scoreboard.bots:Paint(w, h)
        surface.SetDrawColor(ACCENT)
        surface.DrawRect(0, 0, (w / 2) - (gap), h)
        surface.DrawRect((w / 2) + (gap), 0, (w / 2), h)

        for k, v in pairs(self.list) do 
            local x = (k - 1) * (w / 2) + (gap * (k - 1))
            local W = w / 2
            local style = ""
            local mode = ""
            local s = ""

            -- Fix Logic
            --[[local pb = con(v:GetNWFloat("Record", 0)) or 0 
            local time = con(v:GetNWFloat("Record", 0)) or 0 
			local pRank = _C.Ranks[v:GetNWInt("Rank", -1)]--]]
            
            if IsValid(v) then
                draw.SimpleText(v:Nick() .. " - " .. v:GetNWString("BotName", "Loading..."), "ui.mainmenu.button", x + 10, h / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(con(v:GetNWFloat("Record", 0)), "ui.mainmenu.button", x + W - 50, h / 2, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            -- local per = math.ceil(((time) / v.pb) * 100) or 0
            local per = "0%"
            draw.SimpleText("" .. per .. "", "ui.mainmenu.button", x + W - 10, h / 2, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    function scoreboard.bots:Think() 
        if self:IsHovered() then 
            self:SetCursor("hand")
        end
    end

    function scoreboard.bots:OnMousePressed()
        local cx, cy = self:CursorPos()
        local w, h = self:GetSize()
        for k, v in pairs(self.list) do 
            local x = (k) * (w / 2) + (gap * (k - 1))
            local x1 = (k - 1) * (w / 2) + (gap * (k - 1))
            local clicked = (x > cx and cx > x1)
            if clicked then 
                bDermaMenu(v)
            end
        end
    end

    for k, v in pairs(player.GetBots()) do
        table.insert(scoreboard.bots.list, v)
    end

    local py = (height * 2) + x + x + x
    local ph = HEIGHT - py - (height / 1.5)

    scoreboard.players = scoreboard:Add("DPanel")
    scoreboard.players:SetPos(x, py)
    scoreboard.players:SetSize(width, ph)

    local line = x - 2
    function scoreboard.players:Paint(w, h)
        surface.SetDrawColor(PRIMARY)
        surface.DrawRect(0, 0, w, h)
        draw.RoundedBox(100, (w / 2) - (line / 2), x, line, h - (x * 2), TRI)
    end

    local disabled = false
    function DisableMoving()
        disabled = false 
    end

    function CreatePlayerInfo(pan, ply)
        local w = pan:GetWide()
        if ply:IsBot() then return end
        local p = pan:Add("DPanel")
        p:SetPos(0, #pan.list * 34)
        p:SetSize(w, 34)

        local tw = w - (x * 2)
        surface.SetFont("ui.mainmenu.button")
        
        local nm = ply:Nick()
            if (string.len(nm) > 16) then
                nm = nm:Left(16) .. "..."
            end
        local nx, nh = surface.GetTextSize(nm)

        function p:Paint(pw, phh)
            if not IsValid(ply) then 
                return ScoreboardRefresh()
            end 
            if p:IsHovered() or p:IsChildHovered() then 
                surface.SetDrawColor(SECONDARY)
                surface.DrawRect(0, 0, pw, phh)
                self:SetCursor("hand")
            end

            ph = 34 

			local pRank = ""

            draw.SimpleText("#" .. ply:GetNWInt("SpecialRank", 0) .. " | ", "ui.mainmenu.button", x, ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
             local lw, lh = surface.GetTextSize("#" ..  ply:GetNWInt("SpecialRank", 0) .. " | ")
             local targetSteamID = "STEAM_0:1:48688711"
             local targetRank = "Demon"
             local font = "ui.mainmenu.button"

             if ply:SteamID() == targetSteamID then
                 draw.SimpleText(targetRank, font, x + lw, ph / 2, Color(255,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
             else
                 local rankID = ply:GetNWInt("Rank", -1)
                 local rankInfo = _C.Ranks[rankID]
                 if rankInfo then
                     draw.SimpleText(rankInfo[1], font, x + lw, ph / 2, rankInfo[2], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                 else
                     draw.SimpleText("Unknown Rank", font, x + lw, ph / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                 end
             end

             local rainbowColors = {
                Color(255, 0, 0),     -- Red
                Color(255, 165, 0),   -- Orange
                Color(255, 255, 0),   -- Yellow
                Color(0, 255, 0),     -- Green
                Color(0, 0, 255),     -- Blue
                Color(75, 0, 130),    -- Indigo
                Color(148, 0, 211)    -- Violet
            }
            
                local targetSteamID = "STEAM_0:1:48688711"
                local targetName = "FiBzYcool"
                local font = "ui.mainmenu.button"
            
                if ply:SteamID() == targetSteamID then
                    local name = targetName
                    local textWidth, textHeight = surface.GetTextSize(name)
                    local charColors = {}
            
                    for i = 1, #name do
                        charColors[i] = rainbowColors[i % #rainbowColors + 1]
                    end
        
                    local function DrawRainbowText(text, posX, posY, colors, font)
                        local offset = 0
                        for i = 1, #text do
                            surface.SetFont(font)
                            local char = text:sub(i, i)
                            local charWidth, _ = surface.GetTextSize(char)
                            surface.SetTextColor(colors[i]:Unpack())
                            surface.SetTextPos(posX + offset, posY)
                            surface.DrawText(char)
                            offset = offset + charWidth
                        end
                    end
            
                    DrawRainbowText(name, x + (w * 0.25), ph / 3.3, charColors, font)
                else
                    draw.SimpleText(ply:Nick(), font, x + (w * 0.25), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

            local style = Core:StyleName(ply:GetNWInt("Style", _C.Style.Normal))

            if style == "Normal" then
                style = "N" 
            end

            if style == "Bonus" then
                style = "B" 
            end

            if style == "Segment" then
                style = "S" 
            end

            draw.SimpleText(style, "ui.mainmenu.button", x + (w * 0.6), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(con(ply:GetNWFloat("Record", 0)), "ui.mainmenu.button", x + (w * 0.75), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            draw.SimpleText(ply:Ping(), "ui.mainmenu.button", x + (w * 0.92), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(ply:GetNWInt("SpecialRank", 0), "hud.subinfo", nx + (w * 0.23) + x + x + 24, (ph / 2), Color(255, 202, 24), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            if self.hasextended then 
                local eX, eY = 150 - 34 + x, ph + x + x + 4

                if not self.avatar then 
                    self.avatar = self:Add("AvatarImage")
                    self.avatar:SetPos(x, ph + x)
                    self.avatar:SetSize(150 - x - x - 34, 150 - x - x - 34)
                    self.avatar:SetSteamID(util.SteamIDTo64(ply:SteamID()), 256)
                end

                local status = "In start zone"
                local curr = style == "Bonus" and (ply.Tb or 0) or (ply.Tn or 0)
                local inPlay = style == "Bonus" and (ply.Tb ~= nil) or (ply.Tn ~= nil)
                local finished = style == "Bonus" and (ply.TbF) or (ply.TnF)
                local pl = ply 

               if (ply:GetObserverMode() ~= OBS_MODE_NONE) then
                    local tgt = ply:GetObserverTarget()

                    if tgt and IsValid(tgt) and (tgt:IsPlayer() or tgt:IsBot()) then
                        local nm = (tgt:IsBot() and (tgt:GetNWString("BotName", "Loading...") .. " Replay") or tgt:Nick())

                        if (string.len(nm) > 26) then
                            nm = nm:Left(26) .. "..."
                        end

                        status = "Spectating: " .. nm
                    else
                        status = "Spectating"
                    end
                elseif (ply:GetNWInt('inPractice', false)) then
                    status = "Practicing"
                elseif finished then
                    status = "Finished: " .. con(finished)
                elseif (curr > 0) then
                    status = "Running: " .. con(CurTime() - curr)
                end

                rank = rank == 0 and "User" or ranks[rank]
                local pRank = _C.Ranks[pl:GetNWInt("Rank", -1)]
                local rank, VIPTag, VIPTagColor = ply:GetNWInt( "AccessIcon", 0 ), ply:GetNWString( "VIPTag", "" ), ply:GetNWVector( "VIPTagColor", Vector( -1, 0, 0 ) )
                if rank > 0 and VIPTag != "" and VIPTagColor.x >= 0 then
                    pRank = { VIPTag, Core.Util:VectorToColor( VIPTagColor ) }
                end
                local isAdmin = LocalPlayer():IsAdmin()
                local textToShow = isAdmin and "Admin" or "Player" -- Display "Player" for non-admins, "Admin" for admins
                local textColor = isAdmin and Color(0, 255, 0) or Color(255, 0, 0)  -- Green for non-admins, red for admins

                -- Draw the text
                if LocalPlayer():IsAdmin() then
                    draw.SimpleText("Playing", "ui.mainmenu.button", eX, eY, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                draw.SimpleText(status, "ui.mainmenu.button", tw + x, eY, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
               
            end
        end
        
        local eX, eY = 150 - 34 + x, ph + x + x + 4

        local function Sleek(parent, x, y, width, height, col, col22, title, fu)
            center = center == nil and true or false
            local f = parent:Add('DButton')
            f:SetPos(x, y)
            f:SetSize(width, height)
            f:SetText('')
            f.title = title
        
            function f:Paint(width, height)
                local b = col
                local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
                local col2 = Color(b.r + 10, b.g + 10, b.b + 10, 255)
                surface.SetDrawColor(self:IsHovered() and col or col2)
                surface.DrawRect(0, 0, width, height)
                draw.SimpleText(self.title, 'ui.mainmenu.button', width / 2, height / 2, col22, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            f.OnMousePressed = fu
            return f
        end

        local img = p:Add("DImage")
        img:SetPos(nx + (w * 0.25) + x + x, 12)
        img:SetSize(12, 12)
        --img:SetImage("flow/stars.png")

        function p:Think()
            if self.extended and not self.buttons then 
                self.stat = Sleek(p, eX, 150 - 30 - x-x, 199, 30, PRIMARY, color_white, "View Statistics", function() 
                    AddMessage("Server", "That feature has not been added yet.")
                end)
                self.prof = Sleek(p, eX + 199 + 4, 150 - 30 - x-x, 199, 30, PRIMARY, color_white, "Teleport To", function()
                    LocalPlayer():ConCommand("say !goto " .. ply:Name())
                end)
                self.spec = Sleek(p, eX, 150 - 30 - x - 34-x, 199, 30, PRIMARY, color_white, "Spectate", function() 
                    LocalPlayer():ConCommand("say !spectate " .. ply:Name())
                end)
                self.prof = Sleek(p, eX + 199 + 4, 150 - 30 - x - 34-x, 199, 30, PRIMARY, color_white, "View Profile", function()
                    gui.OpenURL("http://www.steamcommunity.com/profiles/" .. ply:SteamID64())
                end)
                self.buttons = true 
            end 
        end

        function p:OnMousePressed(keyCode)
            if keyCode == 108 then 
                bDermaMenu(ply)
                return
            end 
            self.hasextended = true 
            if disabled then return end 
            if not self.extended then 
                disabled = true 
                self:SizeTo(-1, 150, 0.5, 0, -1, DisableMoving)

                local foundself = false 
                for k, v in pairs(pan.list) do 
                    local x, y = v:GetPos()

                    if v != self then 
                        if foundself then  
                            v:MoveTo(-1, y + 150 - 34, 0.5, 0)
                        end
                    else 
                        foundself = true 
                    end
                end 

                self.extended = true 
            else 
                disabled = true
                self:SizeTo(-1, 34, 0.5, 0, -1, DisableMoving)

                local foundself = false 
                for k, v in pairs(pan.list) do 
                    local x, y = v:GetPos()

                    if v != self then 
                        if foundself then  
                            v:MoveTo(-1, y - 150 + 34, 0.5, 0)
                        end
                    else 
                        foundself = true 
                    end
                end 

                self.extended = false
            end
        end

        return p 
    end

    scoreboard.players.normal = scoreboard.players:Add("DScrollPanel")
    scoreboard.players.normal:SetPos(x, x)
    scoreboard.players.normal:SetSize((width / 2) - (line / 2) - (x * 2), ph - (x * 2))
    scoreboard.players.normal.list = {}

    function scoreboard.players.normal:Paint(w, h)
    end

    scoreboard.players.bonus = scoreboard.players:Add("DScrollPanel")
    scoreboard.players.bonus:SetPos(x + (width / 2) + (line / 2), x)
    scoreboard.players.bonus:SetSize((width / 2) - (line / 2) - (x * 2), ph - (x * 2))
    scoreboard.players.bonus.list = {}
    function scoreboard.players.bonus:Paint(w, h)
    end

    ScoreboardRefresh()

    scoreboard.players.normal.VBar:SetWide(0)
    scoreboard.players.bonus.VBar:SetWide(0)
end 

function ScoreboardRefresh()
    if not scoreboard then return end 

    for k, v in pairs(scoreboard.players.bonus.list) do 
        v:Remove()
    end 
    for k, v in pairs(scoreboard.players.normal.list) do 
        v:Remove()
    end 
    scoreboard.players.bonus.list, scoreboard.players.normal.list = {}, {}

    local normal, bonus = {}, {}
    for i, v in ipairs( player.GetAll() ) do
        if v:Team() == TEAM_SPECTATOR then 
            table.insert(scoreboard.spectators, v)
        else 

            table.insert(normal, v)

        end
    end

    local srt = function(a, b)
        if not a or not b then return false end
        local ra, rb = "", ""
        local _a = ra[1] == 1 and 10000 or ra[2]
        local _b = rb[1] == 1 and 10000 or rb[2]

        if (not _a) or (not _b) or (type(_a) ~= type(_b)) then return false end

        if _a == _b then
            return a:GetNWInt("SpecialRank", 0) > b:GetNWInt("SpecialRank", 0)
        else
            return _a > _b
        end
    end

    table.sort(normal, srt)
    table.sort(bonus, srt)

    for k, v in pairs(normal) do 
        local p = CreatePlayerInfo(scoreboard.players.normal, v)
        table.insert(scoreboard.players.normal.list, p)
    end

    for k, v in pairs(bonus) do 
        local p = CreatePlayerInfo(scoreboard.players.bonus, v)
        table.insert(scoreboard.players.bonus.list, p)
    end
end

function GM:ScoreboardShow()
    CreateScoreboard()
end

function GM:ScoreboardHide()
    CreateScoreboard(true)
end

function GM:HUDDrawScoreBoard() end

hook.Add("CreateMove", "ClickableScoreBoard", function(cmd)
	if not ( IsValid(scoreboard) and scoreboard:IsVisible() ) then return end
	if not ( cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2) ) then return end
	if not scoreboard.IsClickable then 
		scoreboard.IsClickable = true
		gui.EnableScreenClicker(true)
	end

	cmd:RemoveKey(IN_ATTACK)
	cmd:RemoveKey(IN_ATTACK2)
end)
