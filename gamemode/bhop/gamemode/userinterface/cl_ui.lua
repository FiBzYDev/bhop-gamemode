-- UI API --
-- Edited: justa

UI = {}
UI.ActiveNumberedUIPanel = false

local lp = LocalPlayer

-- Scrollable
function UI:Scrollable(base, height, hoverCol, data, custom)
	-- Hmm?
	if (not base.contents) then 
		base.contents = {}
	end

	-- Panel
	local ui = base:Add("DButton")
	ui:SetPos(0, height * #base.contents)
	ui:SetSize(base:GetWide(), height)
	ui:SetText("")
	ui.data = data
	ui.custom = custom 
	ui.hoverCol = hoverCol
	ui.height = height
	ui.hoverFade = 0 
	ui.fcol = false 

	local initialy = height / 2
	
	-- its so bad 
	if not base:GetParent().themec then 
		base:GetParent().themec = base:GetParent():GetParent().themec
	end

	-- Draw
	function ui:Paint(width, height)
		local accent = UI_ACCENT
		accent = Color(accent.r, accent.g, accent.b, self.hoverFade)

		if ((hoverCol) and (self.isHovered)) or self.fcol then 
			surface.SetDrawColor(self.fcol and self.fcol or accent)
			surface.DrawRect(0, 0, width - (base.scrollbar and 16 or 0), height)
		end 

		-- Draw dat sheet
		local text = UI_TEXT1
		for k, v in pairs(data) do
			local x = (width / #data) * (k - 1)
			if (custom) then 
				x = (width / custom[1]) * custom[2][k]
			end

			local align = TEXT_ALIGN_LEFT
			if k == #data and (#data ~= 1) then 
				x = width - (base.scrollbar and 16 or 0) - 20
				align = TEXT_ALIGN_RIGHT
			end 

			-- Map name
			if type(v) == 'table' then 
				if v[1] == 'name' then 
					draw.SimpleText(LocalPlayer:Nick(), "ui.mainmenu.button", 10 + x, initialy, text, align, TEXT_ALIGN_CENTER)
				else 
					draw.SimpleText(v[1], "ui.mainmenu.button", 10 + x, initialy, v[2], align, TEXT_ALIGN_CENTER)
				end 
			else
				draw.SimpleText(v, "ui.mainmenu.button", 10 + x, initialy, text, align, TEXT_ALIGN_CENTER)
			end
		end

		self:CPaint(width, height)
	end

	-- Custom paint
	function ui:CPaint()
	end

	-- Force col
	function ui:SetColor(cust)
		if cust then 
			self.fcol = cust 
		else 
			self.fcol = Color(255, 255, 255, 75)
		end 
	end 

	-- Rem col 
	function ui:RemoveColor()
		self.fcol = false 
	end 

	-- Think
	function ui:Think()
		if self.isHovered and not self:IsHovered() then 
			self.hoverFade = 0 
		elseif self.isHovered and self.hoverFade < 75 then 
			self.hoverFade = self.hoverFade + 0.75
		end 

		self.isHovered = self:IsHovered()
	end

	-- Insert
	table.insert(base.contents, ui)

	-- Will there be a scrollbar?
	if (#base.contents * height) > base:GetTall() then 
		base.scrollbar = true
	end

	-- Return
	return ui
end

function UI:MapScrollable(base, data, custom, onClick)
	-- Panel
	local ui = self:Scrollable(base, 40, true, data, custom)
	ui.onClick = onClick

	-- On click
	function ui:OnMousePressed()
		onClick(self, data)
	end

	function ui:SizeToAndAdjustOthers(w, h, t, d, revert)
		local inith = self:GetTall()

		self:SizeTo(w, h, t, 0)
		self.inith = inith 
		
		if not revert then 
			self.adjusted = true 
		end

		local foundSelf = false 
		local movedReverted = false
		for k, v in pairs(base.contents) do 
			if v == self then 
				foundSelf = true 
				continue
			elseif v.adjusted then 
				if not foundSelf then 
					v:SizeTo(w, v.inith, t, d)
				else end
				v.adjusted = false
			end

			if foundSelf then
				local x, y = v:GetPos() 
				v:MoveTo(w, y + h - inith, t, 0)
			end
		end
	end

	return ui
end

function UI:NumberedUIPanel(title, ...)
	local options = {...}
    local pan = vgui.Create("DPanel")

    pan.hasPages = #options > 7 and true or false
    pan.page = 1

    local width = 200
    local height = 75 + ((pan.hasPages and 7 or #options) * 20) -- Update to use 7 instead of 9
    local xPos, yPos = 20, (ScrH() / 2) - (height / 2)

    pan:SetSize(width, height)
    pan:SetPos(xPos, yPos)
    pan.title = title
    pan.options = options

    if (self.ActiveNumberedUIPanel) then
        self.ActiveNumberedUIPanel:Exit()
    end

	local largest = ""
	for index, option in pairs(pan.options) do
		if (option.bool ~= nil) then
			local o1 = option.customBool and option.customBool[1] or "ON"
			local o2 = option.customBool and option.customBool[2] or "OFF"
			option.defname = option.name
			option.name = "[" .. (option.bool and o1 or o2) .. "] " .. option.name
		end

		largest = (#option.name > #largest) and option.name or largest
	end

	surface.SetFont "HUDLabelMed"
	local width_largest = select(1, surface.GetTextSize(largest)) + 20

	if (width_largest > 180) then
		pan:SetWide((width_largest * 1.1) + 44)
	end

	pan.Paint = function(self, width, height)
		local primary = Settings:GetValue("PrimaryCol")
		local text2 = Settings:GetValue("TextCol2")
		local outline = Settings:GetValue("Outlines")
		local text = Settings:GetValue("TextCol")

		surface.SetDrawColor( Color(44, 44, 44))
		surface.DrawRect(0, 0, width, height)

		surface.SetDrawColor(Color(38, 38, 38))
		surface.DrawRect(0, 0, width, 30)

		surface.SetDrawColor(Color(38, 38, 38))
		surface.DrawOutlinedRect(0, 0, width, height)

		draw.SimpleText(self.title, "hud.title", 10, 15, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		local i = 1
		for index = 1 + ((self.page - 1) * 7), ((self.page - 1) * 7) + 7 do
			if (not self.options[index]) then break end

			local option = self.options[index]
			draw.SimpleText(i .. ". " .. option.name, "HUDLabelMed", 10, 25 + (i * 20), option.col and option.col or text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			i = i + 1
		end

		local index = self.hasPages and 7 or #self.options

		draw.SimpleText("0. Exit", "HUDLabelMed", 10, 35 + ((index + (self.hasPages and 3 or 1)) * 20), text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		if (self.hasPages) then
			draw.SimpleText("8. Previous", "HUDLabelMed", 10, 35 + ((index + 1) * 20), text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("9. Next", "HUDLabelMed", 10, 35 + ((index + 2) * 20), text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	pan.keylimit = false
	pan.Think = function(self)
		-- Initialize key to -1
		local key = -1
	
		-- Check which key is pressed
		for id = 1, 10 do
			if input.IsKeyDown(id) then
				key = id - 1
				break
			end
		end
	
		-- Check if the player is typing
		if lp and IsValid(lp()) and lp():IsTyping() then
			key = -1
		end
	
		-- Process key press if valid and not in key limit
		if (key > 0) and (key <= 9) and (not self.keylimit) then
			if (key == 8) and (self.hasPages) then
				self.page = (self.page == 1 and 1 or self.page - 1)
			elseif (key == 9) and (self.hasPages) then
				local max = math.ceil(#self.options / 7)
				self.page = self.page == max and self.page or self.page + 1
				self:OnNext(self.page == max)
			else
				local pageAddition = (self.page - 1) * 7
				if (not self.options[key + pageAddition]) or (not self.options[key + pageAddition]["function"]) then
					return
				end
				self.options[key + pageAddition]["function"]()
			end
	
			-- Set keylimit to true and reset after delay
			self.keylimit = true
			timer.Simple(self.keydelay or 0.4, function()
				if IsValid(self) then
					self.keylimit = false
				end
			end)
		elseif (key == 0) then
			-- Exit on key 0
			self:OnExit()
			self:Exit()
		end
	
		-- Call OnThink again
		self:OnThink()
	end

	function pan:UpdateTitle(title)
		self.title = title
	end

	function pan:UpdateOption(optionId, title, colour, f)
		if (not self.options[optionId]) then
			return end

		if (title) then
			self.options[optionId]["name"] = title
		end

		if (colour) then
			self.options[optionId]["col"] = colour
		end

		if (f) then
			self.options[optionId]["function"] = f
		end
	end

	function pan:UpdateOptionBool(optionId)
		if (not self.options[optionId]) or (self.options[optionId].bool == nil) then
			return end

		self.options[optionId].bool = (not self.options[optionId].bool)

		local o1 = self.options[optionId].customBool and self.options[optionId].customBool[1] or "ON"
		local o2 = self.options[optionId].customBool and self.options[optionId].customBool[2] or "OFF"
		self.options[optionId].name = "[" .. (self.options[optionId].bool and o1 or o2) .. "] " .. self.options[optionId].defname
	end

	function UI:ScrollablePanel(parent, x, y, width, height, data)
		-- Scroll
		local ui = parent:Add("DScrollPanel")
	
		-- Top
		local top = parent:Add("DPanel")
		top:SetPos(x, y)
		top:SetSize(width, 20)
	
		-- Paint
		function top:Paint(width, height)
			local col = UI_TRI
			local text = UI_TEXT2
			surface.SetDrawColor(Color(100,100,100))
			surface.DrawRect(0, height - 2, width, 1)
			--surface.DrawRect(0, 0, width, height)
	
			-- Draw titles
			for k, v in pairs(data[1]) do 
				local x = (width / data[2]) * data[3][k]
	
				local align = TEXT_ALIGN_LEFT
				if k == #data[1] and (#data[1] ~= 1) then 
					align = TEXT_ALIGN_RIGHT
					x = width - (ui.scrollbar and 16 or 0) - 20
				end 
	
				-- Map name
				draw.SimpleText(v, "hud.smalltext",  10+x, 0, text, align, TEXT_ALIGN_TOP)
			end
		end
	
		local sortbutts = {}
		local lastsorted = {1, 0}
		for k, v in pairs(data[1]) do 
			local x = (width / data[2]) * data[3][k]
	
			sortbutts[k] = top:Add("DButton")
			sortbutts[k]:SetPos(x, 0)
			sortbutts[k]:SetWide(100)
			sortbutts[k].Paint = function() end
			sortbutts[k]:SetText("")
			sortbutts[k].OnMousePressed = function()
				if ui.nosort then return end
				-- remove current
				local copied = table.Copy(ui.contents)
				for k, v in pairs(ui.contents) do 
					ui.contents[k]:Remove()
					ui.contents[k] = nil 
				end
	
				-- sort 
				if (lastsorted[1] == k) and (lastsorted[2] == 0) then 
					table.sort(copied, function(a, b)
						lastsorted = {k, 1}
						return (tonumber(a.data[k]) and tonumber(a.data[k]) or a.data[k]) > (tonumber(b.data[k]) and tonumber(b.data[k]) or b.data[k])
					end)
				else 
					table.sort(copied, function(a, b)
						lastsorted = {k, 0}
						return (tonumber(a.data[k]) and tonumber(a.data[k]) or a.data[k]) < (tonumber(b.data[k]) and tonumber(b.data[k]) or b.data[k])
					end)
				end
	
				-- readd
				for k, v in pairs(copied) do
					UI:MapScrollable(ui, v.data, v.custom, v.onClick)
				end
			end
		end
	
		-- Set up 
		ui:SetSize(width, height - 21)
		ui:SetPos(x, y + 21)
	
		-- VBar
		local vbar = ui:GetVBar()
		vbar:SetHideButtons(true)
	
		-- The main bar
		function vbar:Paint(width, height)
		end
	
		function vbar.btnUp:Paint(width, height)
		end
	
		function vbar.btnDown:Paint(width, height)
		end
	
		function vbar.btnGrip:Paint(width, height)
			local col = Color(100,100,100)
			surface.SetDrawColor(col)
			surface.DrawRect(1, 0, width - 1, height)
		end
	
		local old = ui.SetVisible 
		function ui:SetVisible(arg)
			old(self, arg)
			top:SetVisible(arg)
		end 
	
		-- Return
		return ui, top
	end

	function pan:OnThink()
	end

	function pan:Exit()
		UI.ActiveNumberedUIPanel = false
		self:Remove()
		pan = nil
	end

	function pan:OnExit()
	end

	function pan:SelectOption(id)
		self.options[id]["function"]()
	end

	function pan:SetCustomDelay(delay)
		self.keydelay = delay
	end

	function pan:ForceNextPrevious(bool)
		self.hasPages = true
		self:SetTall(75 + 180)

		local posx, posy = self:GetPos()
		self:SetPos(posx, ScrH() / 2 - ((75 + 180) / 2))
	end

	function pan:UpdateLongestOption()
		local largest = ""
		for index, option in pairs(self.options) do
			largest = (#option.name > #largest) and option.name or largest
		end

		surface.SetFont "HUDLabelMed"
		local width_largest = select(1, surface.GetTextSize(largest)) + 20

		if (width_largest > 180) then
			self:SetWide((width_largest * 1.1) + 44)
		end
	end

	function pan:OnNext()
	end

	self.ActiveNumberedUIPanel = pan

	return pan
end

function UI:SendCallback(handle, data)
	net.Start "userinterface.network"
		net.WriteString(handle)
		net.WriteTable(data)
	net.SendToServer()
end

local DATA = {}
function UI:AddListener(id, func)
	DATA[id] = func
end

net.Receive("userinterface.network", function(_, cl)
	local network_id = net.ReadString()
	local network_data = net.ReadTable()

	if (not DATA[network_id]) then return end

	DATA[network_id](cl, network_data)
end)

local function CP_Callback(id)
	return function() UI:SendCallback("checkpoints", {id}) end
end

UI:AddListener("checkpoints", function(_, data)
	local update = data[1] or false

	if update and (UI.checkpoints) then
		if (update == "angles") then
			UI.checkpoints:UpdateOptionBool(7)
			return
		end

		local current = data[2]
		local all = data[3] or nil
		surface.PlaySound( "garrysmod/ui_click.wav" )
		if (not current) then
			UI.checkpoints:UpdateTitle("Checkpoints")
			return
		end

		UI.checkpoints:UpdateTitle("Checkpoint: " .. current .. " / 150")
	elseif (not UI.checkpoints) or (not UI.checkpoints.title) then
		UI.checkpoints = UI:NumberedUIPanel("Checkpoints",
			{["name"] = "Save checkpoint", ["function"] = CP_Callback("save")},
			{["name"] = "Teleport to checkpoint", ["function"] = CP_Callback("tp")},
			{["name"] = "Next checkpoint", ["function"] = CP_Callback("next")},
			{["name"] = "Previous checkpoint", ["function"] = CP_Callback("prev")},
			{["name"] = "Delete checkpoint", ["function"] = CP_Callback("del")},
			{["name"] = "Reset checkpoints", ["function"] = CP_Callback("reset")},
			{["name"] = "Use Angles", ["function"] = CP_Callback("angles"), ["bool"] = true}
		)
	end
end)

local function SSJ_Callback(key)
	return function() UI:SendCallback("ssj", {key}) end
end

UI:AddListener("ssj", function(_, data)
	local data = data[1] or false

	if tonumber(data) and UI.ssj then
		UI.ssj:UpdateOptionBool(tonumber(data))
	elseif (not UI.ssj) or (not UI.ssj.title) and (not tonumber(data)) then
		UI.ssj = UI:NumberedUIPanel("SSJ Menu",
			{["name"] = "Toggle", ["function"] = SSJ_Callback(1), ["bool"] = data[1]},
			{["name"] = "Mode", ["function"] = SSJ_Callback(2), ["bool"] = data[2], ["customBool"] = {"All", "6th"}},
			{["name"] = "Speed Difference", ["function"] = SSJ_Callback(3), ["bool"] = data[3]},
			{["name"] = "Height Difference", ["function"] = SSJ_Callback(4), ["bool"] = data[4]},
			{["name"] = "Observers Stats", ["function"] = SSJ_Callback(5), ["bool"] = data[5]},
			{["name"] = "Gain Percentage", ["function"] = SSJ_Callback(6), ["bool"] = data[6]},
			{["name"] = "Strafes Per Jump", ["function"] = SSJ_Callback(7), ["bool"] = data[7]},
			{["name"] = "Show JSS", ["function"] = SSJ_Callback(8), ["bool"] = data[8]},
			{["name"] = "Show Eff", ["function"] = SSJ_Callback(9), ["bool"] = data[9]},
			{["name"] = "Show Time", ["function"] = SSJ_Callback(10), ["bool"] = data[10]}
		)
	end
end)

RTVStart = false
RTVSelected = false

local rainbowColors = {
    Color(255, 0, 0),     -- Red
    Color(255, 127, 0),   -- Orange
    Color(255, 255, 0),   -- Yellow
    Color(0, 255, 0),     -- Green
    Color(0, 0, 255),     -- Blue
    Color(75, 0, 130),    -- Indigo
    Color(148, 0, 211)    -- Violet
}

local rainbowIndex = 1  -- Initial index for rainbow color

local function RainbowColorEffect()
    local color = rainbowColors[rainbowIndex]
    rainbowIndex = (rainbowIndex % #rainbowColors) + 1  -- Cycle through rainbow colors
    return color
end

local function RTV_Callback(id)
    return function()
        local accent = RainbowColorEffect()  -- Get rainbow color for accent
        local text = Settings:GetValue("TextCol")
        local old = false

        if (UI.rtv.options[id].col) and (UI.rtv.options[id].col == accent) then
            return end

        RTVSelected = id
        UI.rtv:UpdateOption(id, false, accent, false)
        for k, v in pairs(UI.rtv.options) do
            if (k ~= id) then
                if (v.col) and (v.col == accent) then
                    old = k
                end

                UI.rtv:UpdateOption(k, false, text, false)
            end
        end

        UI:SendCallback("rtv", {id, old})
    end
end

UI:AddListener("rtv", function(_, data, isRevote)
local id = data[1]
local info = data[2]

if id == "GetList" then
    local ui_options = {}

    local mapInfotier = {
        ["bhop_asko"] = {tier = 1},
        ["bhop_newdun"] = {tier = 1},
        ["bhop_stref_amazon"] = {tier = 2},
    }

    for k, v in pairs(info) do
        local mapName = v[1]
        local mapData = mapInfotier[mapName]
        local tierName = mapData and "Tier " .. mapData.tier or ""

        local name = "[0] " .. mapName .. (tierName ~= "" and " - " .. tierName or "") .. " (" .. v[2] .. " points, " .. v[3] .. " plays)"
        table.insert(ui_options, {["name"] = name, ["function"] = RTV_Callback(k)})
    end

    table.insert(ui_options, {["name"] = "[0] Extend the current map", ["function"] = RTV_Callback(6)})
    table.insert(ui_options, {["name"] = "[0] Go to a randomly selected map", ["function"] = RTV_Callback(7)})

    UI.rtv = UI:NumberedUIPanel("", unpack(ui_options))
    RTVStart = isRevote and (RTVStart or CurTime() + 15) or CurTime() + 15

    function UI.rtv:OnThink()
        local s = math.Round(RTVStart - CurTime())

        if s <= 0 then
            self:Exit()
            RTVStart = false
            RTVSelected = false
            return
        end

        self.title = "Map Vote (" .. s .. "s remaining)"
    end

	local rainbowColors = {
		Color(255, 0, 0),     -- Red
		Color(255, 127, 0),   -- Orange
		Color(255, 255, 0),   -- Yellow
		Color(0, 255, 0),     -- Green
		Color(0, 0, 255),     -- Blue
		Color(75, 0, 130),    -- Indigo
		Color(148, 0, 211)    -- Violet
	}
	
	local rainbowIndex = 1  -- Initial index for rainbow color
	
	local function RainbowTextEffect(text)
		local charTable = {}
		local len = #text
	
		for i = 1, len do
			table.insert(charTable, rainbowColors[rainbowIndex])
			table.insert(charTable, text:sub(i, i))
			rainbowIndex = rainbowIndex % #rainbowColors + 1  -- Cycle through rainbow colors
		end
	
		return charTable
	end

    function UI.rtv:OnExit()
        Link:Print("Notification", "You can reopen this menu with !revote")
    end

		UI.rtv:SetCustomDelay(3)
	elseif (id == "VoteList") then
		if (not UI.rtv) or (not UI.rtv.title) then
			return end
		for k, v in pairs(info) do
			local name = UI.rtv.options[k].name
			name = "[" .. v .. "] " .. (v <= 10 and name:Right(#name - 4) or name:Right(#name - 5))
			surface.PlaySound( "garrysmod/ui_click.wav" )
			UI.rtv:UpdateOption(k, name, false, false)
		end
	elseif (id == "InstantVote") then
		UI.rtv:SelectOption(info)
	elseif (id == "Revote") then 
		if (not UI.rtv) or (not UI.rtv.title) then 
			DATA["rtv"](_, {"GetList", info}, true)
			if (RTVSelected) then 
				UI.rtv:UpdateOption(RTVSelected, false, RainbowTextEffect(text), false)
			end
		end
	end
end)

local function SEGMENT_Callback(id)
	return function() UI:SendCallback("segment", {id}) 
		surface.PlaySound( "garrysmod/ui_click.wav" )
	end
end

UI:AddListener("segment", function(_, data)
	if (data) and (data[1]) and (UI.segment) and (UI.segment.title) then
		UI.segment:Exit()
		return
	end

	if (data and data[1]) then return end

	UI.segment = UI:NumberedUIPanel("Segment Menu",
		{["name"] = "Teleport to checkpoint", ["function"] = SEGMENT_Callback("set")},
		{["name"] = "Previous checkpoint", ["function"] = SEGMENT_Callback("goto")},
		{["name"] = "Delete checkpoint", ["function"] = SEGMENT_Callback("remove")},
		{["name"] = "Reset Checkpoint", ["function"] = SEGMENT_Callback("reset")}
	)
end)

local function WR_OnPress(Index, szMap, nStyle, Item, Speed)
	return function()
		if Admin.EditType and Admin.EditType == 17 and (game.GetMap() == szMap) then
			Admin:ReqAction(Admin.EditType, {nStyle, Index, Item[1], Item[2]})
			return 
		end

		if Speed then
			local place = Index
			local time = Timer:Convert(Item[3] or 0)
			local pl = Item[2] or ""
			local id = Item[1] or ""
			local date = Item[4] or ""
			local style = Core:StyleName(nStyle) or ""
			local jumps = Speed[3] or ""
			local topvel = Speed[1] or ""
			local avgvel = Speed[2] or ""
			local sync = (Speed[4] or "") .. "%"
			local str = string.format("Player %s (%s) achieved #%s on %s on %s style (at: %s) with a time of %s. (Average Vel: %s u/s, Top Vel: %s u/s, Jumps: %s, Sync: %s)",
				pl, id, place, szMap, style, date, time, avgvel, topvel, jumps, sync)

			Link:Print( "Timer", str )
		end
	end
end

UI:AddListener("wr", function(_, data)
	local wrList = data[1]
	local recordStyle = data[2]
	local page = data[3]
	local recordsTotal = data[4]
	local map = data[5] or game.GetMap()

	if (page ~= 1) and (UI.WR) and (UI.WR.title) then
		for k, v in pairs(wrList) do
			local data
			if (not v[5] or #v[5] < 4) then 
				data = {}
			else
				data = Core.Util:StringToTab(v[5])
			end
			local jumps = data[3] or 0
			UI.WR.options[k] = {["name"] = ("#" .. k .. " - " .. v[2] .. " (" .. Timer:Convert(v[3]) .. ", " .. jumps .. " jumps)"), ["function"] = WR_OnPress(k, map, recordStyle, v, data)}
		end

		UI.WR.page = UI.WR.page + 1
		UI.WR:UpdateLongestOption()

		return
	end

	local options = {}
	for k, v in pairs(wrList) do
		local data
		if (not v[5] or #v[5] < 4) then 
			data = {}
		else
			data = Core.Util:StringToTab(v[5])
		end
		local jumps = data[3] or 0
		options[k] = {["name"] = ("#" .. k .. " - " .. v[2] .. " (" .. Timer:Convert(v[3]) .. ", " .. jumps .. " jumps)"), ["function"] = WR_OnPress(k, map, recordStyle, v, data)}
	end

	UI.WR = UI:NumberedUIPanel(Core:StyleName(recordStyle) .. " Records (#" .. recordsTotal .. ")", unpack(options))
	UI.WR:ForceNextPrevious(true)
	UI.WR.recordCount = recordsTotal
	UI.WR.style = recordStyle
	UI.WR.map = map or game.GetMap()

	function UI.WR:OnNext(hitMax)
		if (hitMax) and ((self.page * 7) < self.recordCount) then
			Link:Send("WRList", {self.page + 1, self.style, self.map})
		end
	end
end)