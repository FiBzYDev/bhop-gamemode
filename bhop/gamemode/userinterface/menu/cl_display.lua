SMPanels = {}
SMPanels.DockSize = { [0] = 35, [1] = 50 }
SMPanels.BarSize = { [0] = 65, [1] = 85 }
SMPanels.ConvarSize = { [0] = 35, [1] = 45 }
SMPanels.GenericSize = { [0] = 40, [1] = 55 }
SMPanels.BoxSize = { [0] = 20, [1] = 30 }

local genericButton = { [0] = { 120, 30 }, [1] = { 160, 40 } }
local boxButton = { [0] = 20, [1] = 30 }
local barButton = { [0] = 50, [1] = 70 }
local closeButton = { [0] = 20, [1] = 30 }

SMPanels.BoxButton = genericButton

local sliderMenu = nil
local KeyLimit = false
local KeyLimitDelay = 1 / 4
local KeyChecker = LocalPlayer

local convarText = { [0] = "", [1] = "⬛", [false] = "", [true] = "⬛" }
local function CreateEmptyFrame()
	local Frame = vgui.Create "DFrame"
	Frame:SetTitle ""
	Frame:SetDraggable( false )
	Frame:ShowCloseButton( false )
	Frame.Paint = function() end

	return Frame
end

local function CreatePopupFrame()
	local Frame = vgui.Create "DFrame"
	Frame:SetTitle ""
	Frame:SetDraggable( false )
	Frame:ShowCloseButton( false )
	Frame:MakePopup()
	Frame:SetAlpha( 0 )
	Frame:AlphaTo( 255, 0.4, 0, function() end )

	return Frame
end

local function CreateParentScrollFrame( parent )
	ScrollPanel = vgui.Create( "DScrollPanel", parent )

	local sbar = ScrollPanel:GetVBar()
	function sbar:Paint( w, h ) end
	function sbar.btnUp:Paint( w, h ) draw.RoundedBox( 0, w / 2, 0, w / 2, h, Color(0,0,0,0) ) end
	function sbar.btnDown:Paint( w, h ) draw.RoundedBox( 0, w / 2, 0, w / 2, h, Color(0,0,0,0) ) end
	function sbar.btnGrip:Paint( w, h ) draw.RoundedBox( 0, w / 2, 0, w / 2, h, color_white ) end

	return ScrollPanel
end

local function CreateCloseButton( parent )
	local font = Interface:GetBoldFont()
	local size = closeButton[ Interface.Scale ]
	local bezel = Interface:GetBezel( "Medium" )

	local parWidth, _ = parent:GetSize()
	local posx, posy = (parWidth - size - bezel), bezel

	local Button = vgui.Create( "DButton", parent )
	Button:SetFont( font )
	Button:SetText( "X" )
	Button:SetTextColor( color_white )
	Button:SetSize( size, size )
	Button:SetPos( posx, posy )
	Button.Paint = function( self, w, h )
	local cl = Interface.BackgroundColor
	draw.RoundedBox( 0, 0, 0, w, h, Color( cl.r, cl.g, cl.b, 0 ) )
	end

	Button.DoClick = function()
		if !parent or !IsValid( parent ) then return end
		parent.RunAlphaTest = false

		parent:AlphaTo( 0, 0.4, 0, function() end )
		parent:SetMouseInputEnabled( false )
		parent:SetKeyboardInputEnabled( false )

		timer.Simple( 0.5, function()
			parent:Remove()
			parent = nil
		end )
	end

	return Button
end

local bluecolor = Color(55, 122, 151)

local function CreateButton(parent, text, size, pos)
    local font = Interface:GetBoldFont()
    local Button = vgui.Create("DButton", parent)
    Button:SetFont(font)
    Button:SetText(text)
    Button:SetTextColor(color_white)
    Button:SetSize(unpack(size))
    Button:SetPos(unpack(pos))

    Button.Paint = function(self, w, h)
        local cl = Interface.ForegroundColor
        if parent.MenuOpen then
            cl = bluecolor -- Use blue color when menu is open
        end
        draw.RoundedBox(0, 0, 0, w, h, Color(cl.r, cl.g, cl.b, 255))
    end

    Button.DoClick = function()
        parent.RunAlphaTest = false
    end

    return Button
end

function SMPanels.Label( l )
	local parent = l.parent
	local posx, posy = l.x, l.y
	local font = l.boldfont and Interface:GetBoldFont() or Interface:GetFont()
	local color = l.color or color_white
	local text = l.text

	local label = vgui.Create( "DLabel", parent )
	label:SetPos( posx, posy )
	label:SetFont( font )
	label:SetColor( color )
	label:SetText( text )
	label:SizeToContents()

	return label
end

function SMPanels.Tooltip( t )
	local parent = t.parent
	local text = t.text

	local font = Interface:GetBoldFont()
	local basePanel = vgui.Create "Panel"
	basePanel:SetVisible( false )
	basePanel.Paint = function( _, w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color( 43, 43, 43 ) ) end

	local textPanel = vgui.Create( "DLabel", basePanel )
	textPanel:SetFont( font )
	textPanel:SetColor( color_white )
	textPanel:SetText( text )
	textPanel:SizeToContents()
	textPanel:SetPos( 5, 5 )
	basePanel.Text = textPanel

	local width, height = textPanel:GetWide() + 10, textPanel:GetTall() + 10
	basePanel:SetSize( width, height )
	parent:SetTooltipPanel( basePanel )
end

function SMPanels.ContentFrame( c )
	local parent = c.parent
	local title = c.title
	local center, posx, posy = c.center, c.x, c.y
	local content = c.content
	local noclose = c.noclose

	if parent and parent:IsValid() then
		local basePan = parent:GetChildren()
		parent:SetEnabled( false )
		for _,basePanel in pairs( basePan ) do
			basePanel:SetEnabled( false )
		end
	end

	local width, height = Interface:GetTextWidth( content ), Interface:GetTextHeight( content, Interface:GetBezel( "TinyFrame" ), false )
	local Frame = CreatePopupFrame()
	Frame:SetSize( width, height )

	Frame.Title = title
	Frame.BlurStart = SysTime()

	if center then
		Frame:Center()
	else
		Frame:SetPos( posx, posy )
	end

	Frame.Paint = function( self, w, h )
		Derma_DrawBackgroundBlur( self, self.BlurStart )

		local bezel = Interface:GetBezel( "TinyFrame" )
		draw.RoundedBox( 0, 0, 0, w, h, Interface.BackgroundColor )
		draw.RoundedBoxEx( 0, 0, 0, w, bezel, Interface.ForegroundColor, true, true )

		draw.SimpleText( self.Title, Interface:GetBoldFont(), w / 2, Interface:GetBezel( "Large" ), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		for i,text in pairs( content ) do
			draw.SimpleText( text, Interface:GetFont(), Interface:GetBezel( "Medium" ), bezel + Interface:GetBezel( "Large" ) + ( Interface.FontHeight[Interface.Scale] * ( i - 1 ) ), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
	end

	if (!noclose) then
		local sizex, sizey = unpack( genericButton[Interface.Scale] )
		local pSizex, pSidey = Frame:GetSize()
		local bposx, bposy = (pSizex / 2) - (sizex / 2), (pSidey - sizey) - Interface:GetBezel( "Medium" )

		local Button = CreateButton( Frame, "Dismiss", { sizex, sizey }, { bposx, bposy } )
		Button.DoClick = function()
			if !Frame or !IsValid( Frame ) then return end

			if parent and parent:IsValid() then
				parent:SetEnabled( true )
				local basePan = parent:GetChildren()
				for _,basePanel in pairs( basePan ) do
					basePanel:SetEnabled( true )
				end
			end

			Frame:AlphaTo( 0, 0.4, 0, function()
				Frame:Remove()
				Frame = nil
			end )
		end
	end

	Frame.Think = function()
		Frame:MoveToFront()
	end

	return Frame
end

function SMPanels.AgreementFrame( c )
	local parent = c.parent
	local title = c.title
	local center, posx, posy = c.center, c.x, c.y
	local content = c.content
	local callback = c.callback

	if parent and parent:IsValid() then
		local basePan = parent:GetChildren()
		parent:SetEnabled( false )
		for _,basePanel in pairs( basePan ) do
			basePanel:SetEnabled( false )
		end
	end

	local width, height = Interface:GetTextWidth( content ), Interface:GetTextHeight( content, Interface:GetBezel( "TinyFrame" ), false )
	local bezel = Interface:GetBezel "Medium"
	local Frame = CreatePopupFrame()
	Frame:SetSize( width, height )

	Frame.Title = title
	Frame.BlurStart = SysTime()

	if center then
		Frame:Center()
	else
		Frame:SetPos( posx, posy )
	end

	Frame.Paint = function( self, w, h )
		Derma_DrawBackgroundBlur( self, self.BlurStart )

		local bezel = Interface:GetBezel( "TinyFrame" )
		draw.RoundedBox( 0, 0, 0, w, h, Interface.BackgroundColor )
		draw.RoundedBoxEx( 0, 0, 0, w, bezel, Interface.ForegroundColor, true, true )

		draw.SimpleText( self.Title, Interface:GetBoldFont(), w / 2, Interface:GetBezel( "Large" ), CL.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		for i,text in pairs( content ) do
			draw.SimpleText( text, Interface:GetFont(), Interface:GetBezel( "Medium" ), bezel + Interface:GetBezel( "Large" ) + ( Interface.FontHeight[Interface.Scale] * ( i - 1 ) ), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
	end

	local sizex, sizey = unpack( genericButton[Interface.Scale] )
	local pSizex, pSidey = Frame:GetSize()
	local bposx, bposy = (pSizex / 2) - (sizex), (pSidey - sizey) - Interface:GetBezel( "Medium" )

	local Button = CreateButton( Frame, "Yes", { sizex, sizey }, { bposx, bposy } )
	Button.DoClick = function()
		if !Frame or !IsValid( Frame ) then return end

		if parent and parent:IsValid() then
			parent:SetEnabled( true )
			local basePan = parent:GetChildren()
			for _,basePanel in pairs( basePan ) do
				basePanel:SetEnabled( true )
			end
		end

		Frame.BlurStart = SysTime() + 0.4
		Frame:AlphaTo( 0, 0.4, 0, function()
			Frame:Remove()
			Frame = nil
		end )

		callback()
	end

	bposx, bposy = (pSizex / 2) + bezel, (pSidey - sizey) - Interface:GetBezel( "Medium" )

	local Button2 = CreateButton( Frame, "No", { sizex, sizey }, { bposx, bposy } )
	Button2.DoClick = function()
		if !Frame or !IsValid( Frame ) then return end

		if parent and parent:IsValid() then
			parent:SetEnabled( true )
			local basePan = parent:GetChildren()
			for _,basePanel in pairs( basePan ) do
				basePanel:SetEnabled( true )
			end
		end

		Frame.BlurStart = SysTime() + 0.4
		Frame:AlphaTo( 0, 0.4, 0, function()
			Frame:Remove()
			Frame = nil
		end )
	end

	Frame.Think = function()
		Frame:MoveToFront()
	end

	return Frame
end

function SMPanels.HoverFrame( h )
	local title, subTitle = h.title, h.subTitle
	local center, posx, posy = h.center, h.x, h.y
	local width, height = h.w, h.h

	local Frame = CreatePopupFrame()
	local bezel = Interface:GetBezel( "Frame" )

	Frame:SetSize( width, height )

	Frame.Title = title
	Frame.SubTitle = subTitle

	if center then
		Frame:Center()
	else
		Frame:SetPos( posx, posy )
	end

	Frame.Paint = function( self, fw, fh )
		draw.RoundedBox( 0, 0, 0, fw, fh, Interface.BackgroundColor )
		draw.RoundedBoxEx( 0, 0, 0, fw, bezel, Interface.ForegroundColor, true, true )

		draw.SimpleText( self.Title, Interface:GetBoldFont(), fw / 2, Interface:GetBezel( "Large" ), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( self.SubTitle, Interface:GetFont(), fw / 2, bezel - Interface:GetBezel( "Large" ), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local text = (Frame.CustomText or Frame.Loading and "Loading..." or "")
		draw.SimpleText( text, Interface:GetFont(), fw / 2, fh / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local _, _, boundsw, boundsh = Frame:GetBounds()
	Frame.Page = CreateParentScrollFrame( Frame )
	Frame.Page:SetSize( boundsw, boundsh - bezel )
	Frame.Page:SetPos( 0, bezel )
	Frame.Page:SetAlpha( 255 )

	CreateCloseButton( Frame )

	return Frame
end

function SMPanels.MultiHoverFrame( m )
	local title, subTitle = m.title, m.subTitle
	local center, posx, posy = m.center, m.x, m.y
	local width, height = m.w, m.h
	local pagedata = m.pages

	local Frame = CreatePopupFrame()
	Frame:SetSize( width, height )

	Frame.Title = title
	Frame.SubTitle = subTitle

	Frame.Pages = {}
	Frame.Page = 1

	if center then
		Frame:Center()
	else
		Frame:SetPos( posx, posy )
	end

	Frame.Paint = function( self, w, h )
		local bezel = Interface:GetBezel( "Frame" )
		draw.RoundedBox( 0, 0, 0, w, h, Interface.BackgroundColor )
		draw.RoundedBoxEx( 0, 0, 0, w, bezel, Interface.ForegroundColor, true, true )

		draw.SimpleText( self.Title, Interface:GetBoldFont(), w / 10, Interface:GetBezel( "Large" ), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( self.SubTitle, Interface:GetFont(), w / 2, bezel - Interface:GetBezel( "Large" ), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local text = (Frame.CustomText or Frame.Loading and "Loading..." or "")
		draw.SimpleText( text, Interface:GetFont(), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	CreateCloseButton( Frame )

	local buttonSize = math.ceil( width / #pagedata )
	local _, _, boundsw, boundsh = Frame:GetBounds()
	for i = 1, #pagedata do
		local pageText = pagedata[i]
		local _, buttonSizey = unpack( genericButton[Interface.Scale] )

		local bezel = Interface:GetBezel( "Frame" ) + buttonSizey

		Frame.Pages[i] = CreateParentScrollFrame( Frame )
		Frame.Pages[i]:SetSize( boundsw, boundsh - bezel )
		Frame.Pages[i]:SetPos( 0, bezel )
		Frame.Pages[i]:SetAlpha( 255 )
		if (i != 1) then Frame.Pages[i]:SetVisible( false ) Frame.Pages[i]:SetAlpha( 255 ) end

		local bposx, bposy = ( buttonSize * (i - 1) ), ( Interface:GetBezel( "Frame" ) )
		local sizex, sizey = buttonSize, buttonSizey

		local PageButton = CreateButton( Frame, pageText, { sizex, sizey }, { bposx, bposy } )
		PageButton.Index = i
		PageButton.Paint = function( self, w, h )
		local cl = Interface.ForegroundColor
		draw.RoundedBox( 0, 0, 0, w, h, Color( cl.r, cl.g, cl.b, 255 ) )
		end

		PageButton.DoClick = function()
  		    local currentpage = Frame.Pages[Frame.Page]
  		    local newpage = Frame.Pages[i]
   		    if newpage == currentpage then

   		       PageButton:SetTextColor( bluecolor )
     		   return
 		    end


  		    for _, button in pairs(Frame.Pages) do
                if button.ButtonEntry then
                    button.ButtonEntry:SetTextColor( color_white )
                end
            end
			
			PageButton:SetTextColor( bluecolor )
			surface.PlaySound("UI/buttonclick.wav")

            currentpage:AlphaTo(0, 0.15, 0, function()
                currentpage:SetVisible(false)
                newpage:SetVisible(true)

                newpage:AlphaTo(255, 0.15, 0, function() end)
            end)
			

            Frame.Page = i
        end

		Frame.Pages[i].ButtonEntry = PageButton
	end

	return Frame
end

function SMPanels.SettingBox(b)
    local parent = b.parent
    local text = b.text
    local posx, posy = b.x, b.y
    local width, height = Interface:GetTextWidth({ text }), boxButton[Interface.Scale]
    local convar = GetConVar(b.convar)
    local tooltip = b.tip
    local func = b.func

    if not convar then
        print("Invalid ConVar specified:", b.convar)
        return -- Return early if ConVar is nil
    end

    local con_value = convar:GetInt()

    local Button = vgui.Create("DButton", parent)
    Button:SetSize(width, height)
    Button:SetPos(posx, posy)
    Button:SetText("")
    Button.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, height + 2, height + 2, color_white)
        draw.RoundedBox(0, 0, 0, height, height, Interface.ForegroundColor)
        draw.SimpleText(text, Interface:GetTinyFont(), height + Interface:GetBezel("Medium"), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(convarText[con_value], Interface:GetTinyFont(), height / 2.3, h / 2.5, Color(70, 70, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    Button.DoClick = function()
        local newvalue = 1 - con_value
        LocalPlayer():ConCommand(convar:GetName() .. " " .. newvalue)
        con_value = newvalue

        if func then
            func(newvalue) -- Pass the new value to the function if it's provided
        end
    end

    SMPanels.Tooltip({ parent = Button, text = tooltip })

    return Button
end


function SMPanels.SettingInfo(b)
    local parent = b.parent
    local text = b.text
    local posx, posy = b.x, b.y
    local width, height = Interface:GetTextWidth({ text }), boxButton[Interface.Scale]
    local func = b.func

    -- Check if the convar parameter is provided and valid
    if b.convar then
        local convar = GetConVar(b.convar)
        if convar then
            local con_text = convar:GetName()
            local con_value = convar:GetInt()

            local Button = vgui.Create("DButton", parent)
            Button:SetSize(width, height)
            Button:SetPos(posx, posy)
            Button:SetText("")
            Button.Paint = function(self, w, h)
                draw.SimpleText(text, "m_hLargeFontTiny2", height + Interface:GetBezel("Medium"), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            return Button
        else
            print("Invalid convar specified:", b.convar)
        end
    else
        print("No convar specified for setting info:", text)
    end
end

function SMPanels.EndList(b)
    local parent = b.parent
    local posx, posy = b.x, b.y
    local width, height = 0, boxButton[Interface.Scale] -- You might adjust the width as needed

    local Button = vgui.Create("DButton", parent)
    Button:SetSize(width, height)
    Button:SetPos(posx, posy)
    Button:SetText("")
    Button.Paint = function(self, w, h)
        -- This empty Paint function will not draw anything, effectively acting as a separator or empty space
    end

    return Button
end

function SMPanels.ToggleBox( b )
	local parent = b.parent
	local text = b.text
	local posx, posy = b.x, b.y
	local width, height = Interface:GetTextWidth( { text } ), boxButton[Interface.Scale]

	local Button = vgui.Create( "DButton", parent )
	Button:SetSize( width, height )
	Button:SetPos( posx, posy )
	Button:SetText( "" )

	Button.Checked = false

	Button.Paint = function( self, w, h )
		draw.RoundedBox( 6, 0, 0, height, height, Interface.ForegroundColor )
		draw.SimpleText( text, Interface:GetTinyFont(), height + Interface:GetBezel( "Medium" ), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( convarText[Button.Checked], Interface:GetTinyFont(), height / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	Button.DoClick = function()
		Button.Checked = !Button.Checked
	end

	return Button
end

function SMPanels.Button( b )
	local parent = b.parent
	local text = b.text
	local func = b.func
	local fWidth = b.w
	local fScale = b.scale
	local x, y = b.x, b.y
	local tip = b.tip
	local font = b.font or Interface:GetFont()

	local width, height = unpack( genericButton[Interface.Scale] )
	if fScale then
		width = Interface:GetTextWidth( { text } )
	end

	local Button = vgui.Create( "DButton", parent )
	Button:SetFont( font )
	Button:SetText( text )
	Button:SetTextColor( color_white )
	Button:SetSize( fWidth or width, height )
	Button:SetPos( x, y )
	Button.Paint = function( self, w, h )
		local cl = Interface.ForegroundColor
			draw.RoundedBox( 0, 0, 0, w, h, Color( cl.r, cl.g, cl.b, 255 ) )
	end

	Button.DoClick = function()
		func()
	end

	if tip then
		SMPanels.Tooltip( { parent = Button, text = tip } )
	end

	return Button
end

function SMPanels.ButtonScroll( b )
	local parent = b.parent
	local text = b.text
	local func = b.func
	local fWidth = b.w
	local fScale = b.scale
	local x, y = b.x, b.y
	local tip = b.tip
	local font = b.font or Interface:GetFont()

	local width, height = unpack( genericButton[Interface.Scale] )
	if fScale then
		width = Interface:GetTextWidth( { text } )
	end

	local Button = vgui.Create( "DButton", parent )
	Button:SetFont( font )
	Button:SetText( text )
	Button:SetTextColor( color_white )
	Button:SetSize( fWidth or width, height )
	Button:SetPos( x, y )
	Button.Paint = function( self, w, h )
	end

	return Button
end

function SMPanels.MultiButton(m)
    local parent = m.parent
    local text = m.text
    local selectionText = m.select
    local func = m.func
    local x, y = m.x, m.y
    local tip = m.tip
    local norep = m.norep
    local reverse = m.reverse

    local _, height = unpack(genericButton[Interface.Scale])
    local width = Interface:GetTextWidth({ text })

    for _, expandables in pairs(selectionText) do
        local testWidth = Interface:GetTextWidth({ expandables })
        if testWidth > width then
            width = testWidth
        end
    end

    local Button = {}
    Button.Extend = {}

    for i, expandables in pairs(selectionText) do
        Button.Extend[i] = vgui.Create("DButton", parent)
        Button.Extend[i]:SetFont(Interface:GetFont())
        Button.Extend[i]:SetText(expandables)
        Button.Extend[i]:SetTextColor(color_white)
        Button.Extend[i]:SetSize(width, height)
        Button.Extend[i]:SetPos(x, y)
        Button.Extend[i]:SetEnabled(false)
        Button.Extend[i]:SetAlpha(0)
        Button.Extend[i].Paint = function(self, w, h)
            local cl = Interface.ForegroundColor
            if self:IsHovered() then
                cl = ColorAlpha(cl, 255)
            else
                cl = Color(43, 43, 43)
            end

            if i == #selectionText then
                draw.RoundedBoxEx(0, 0, 0, w, h, cl, reverse, reverse, not reverse, not reverse)
            else
                draw.RoundedBox(0, 0, 0, w, h, cl)
            end

            -- Draw the outline
            local outlineColor = self:IsHovered() and Color(255, 255, 255) or cl
            surface.SetDrawColor(outlineColor)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        Button.Extend[i].DoClick = function()
            if not norep then
                Button.Base:SetText(expandables)
            end

            func(i)

            Button.Base.Opened = false
            for _, buttons in pairs(Button.Extend) do
                buttons:SetEnabled(false)
                buttons:AlphaTo(0, 0.2, 0, function()
                    buttons:MoveToBack()
                end)
                buttons:MoveTo(x, y, 0.2)
            end
        end
    end

    Button.Base = vgui.Create("DButton", parent)
    Button.Base:SetFont(Interface:GetFont())
    Button.Base:SetText(text)
    Button.Base:SetTextColor(color_white)
    Button.Base:SetSize(width, height)
    Button.Base:SetPos(x, y)

    Button.Base.Opened = false
    Button.Base.Paint = function(self, w, h)
        local cl = Interface.ForegroundColor
        if self.Opened then
            cl = Color(43, 43, 43)
        end

		draw.RoundedBox(34, 0, 0, 255, 33, cl)

        if self.Opened then
            draw.RoundedBoxEx(0, 0, 0, w, h, cl, not reverse, not reverse, reverse, reverse)
        else
            --draw.RoundedBox(0, 0, 0, w, h, cl)
        end

        -- Draw the outline
        local outlineColor = self:IsHovered() and color_white or cl
        --surface.SetDrawColor(outlineColor)
        --surface.DrawOutlinedRect(0, 0, w, h)
    end

    Button.Base.DoClick = function()
        if parent.lastOpen and (parent.lastOpen != Button) then
            parent.lastOpen.Base.Opened = false
            local tempX, tempY = parent.lastOpen.Base:GetPos()

            for _, buttons in pairs(parent.lastOpen.Extend) do
                buttons:SetEnabled(false)
                buttons:AlphaTo(0, 0.2, 0, function()
                    buttons:MoveToBack()
                end)
                buttons:MoveTo(tempX, tempY, 0.2)
            end
        end

        if not Button.Base.Opened then
            Button.Base.Opened = true
            for i, buttons in pairs(Button.Extend) do
                buttons:MoveToFront()

                buttons:AlphaTo(255, 0.2, 0, function()
                    buttons:SetEnabled(true)
                end)

                local newPos = 0
                if reverse then
                    newPos = y - (height * i)
                else
                    newPos = y + (height * i)
                end

                buttons:MoveTo(x, newPos, 0.2)
            end
        else
            Button.Base.Opened = false
            for _, buttons in pairs(Button.Extend) do
                buttons:SetEnabled(false)
                buttons:AlphaTo(0, 0.2, 0, function()
                    buttons:MoveToBack()
                end)
                buttons:MoveTo(x, y, 0.2)
            end
        end

        parent.lastOpen = Button
    end

    if tip then
        SMPanels.Tooltip({ parent = Button.Base, text = tip })
    end

    return Button.Base
end

function SMPanels.TextEntry( t )
	local parent = t.parent
	local x, y = t.x, t.y
	local width, height = t.w, t.h
	local text = t.text
	local func = t.func
	local noremove = t.noremove

	if !text then text = "" end

	local Entry = vgui.Create( "DTextEntry", parent )
	Entry:SetPos( x, y )
	Entry:SetSize( width, height )
	Entry:SetFont(Interface:GetFont())
	Entry:SetText( text )
	Entry:SetCursorColor(color_white)
	Entry:SetTextColor(color_white)
	Entry:SetHighlightColor(Interface.BackgroundColor)
	Entry:SelectAllOnFocus()

	Entry.Paint = function( self, w, h )
		local cl = Interface.ForegroundColor
		local bezel = Interface:GetBezel( "Medium" )

		local currentText = self:GetText()
		local currentFont = Interface:GetFont()

		draw.RoundedBox( 0, 0, 0, w, h, cl )

		surface.SetFont( currentFont )
		surface.SetTextColor( color_white )

		local entryWidth = Interface:GetTextWidth( { currentText }, currentFont )
		if (entryWidth > w) then
			surface.SetTextPos( (w + bezel) - entryWidth, bezel )
		else
			surface.SetTextPos( bezel, bezel )
		end

		self:DrawTextEntryText( self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor() )
	end

	Entry.OnGetFocus = function()
		if noremove then return end

		local currentText = Entry:GetText()
		if (currentText != text) then return end

		Entry:SetText( "" )
	end

	Entry.OnEnter = function()
		if !func then return end

		func( Entry:GetText() )
	end

	return Entry
end

function SMPanels.ColorPalette( c )
	local parent = c.parent
	local width, height = c.w, c.h
	local xpos, ypos = c.x, c.y
	local defaultColor = c.default or color_white
	local convar = c.convar
	local red, green, blue = (convar .. "r"), (convar .. "g"), (convar .. "b")

	local Palette = vgui.Create( "DColorMixer", parent )
	Palette:SetPos( xpos, ypos )
	Palette:SetSize( width, height )
	Palette:SetPalette( false )
	Palette:SetAlphaBar( false )
	Palette:SetWangs( true )
	Palette:SetColor( defaultColor )

	function Palette:ValueChanged( tColor )
		local colored = Color( tColor.r, tColor.g, tColor.b )

		Palette:SetConVarR( red )
		Palette:SetConVarG( green )
		Palette:SetConVarB( blue )
	end

	return Palette
end

function SMPanels.LongBar( l )
	local parent = l.parent
	local lefttext = l.ltext
	local righttext = l.rtext

	local width, height = parent:GetWide() - ( Interface:GetBezel( "Medium" ) * 2 ), barButton[Interface.Scale]
	local posx, posy = Interface:GetBezel( "Medium" ), l.pos

	local Bar = vgui.Create( "DButton", parent )
	Bar:SetSize( width, height )
	Bar:SetPos( posx, posy )
	Bar:SetText( "" )
	Bar.Paint = function( self, w, h )
		local cl = Interface.ForegroundColor

			draw.RoundedBox( 6, 0, 0, w, h, Color( 255, cl.g, cl.b, 255 ) )


		draw.SimpleText( lefttext, Interface:GetFont(), Interface:GetBezel( "Medium" ), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( righttext, Interface:GetFont(), w - Interface:GetBezel( "Medium" ), h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	end

	Bar.DoClick = l.func

	return Bar
end

function SMPanels.LongBarInfo( l )
	local parent = l.parent
	local middletext = l.mtext
	local lefttext = l.ltext
	local righttext = l.rtext

	local width, height = parent:GetWide() - ( Interface:GetBezel( "Medium" ) * 2 ), barButton[Interface.Scale]
	local posx, posy = Interface:GetBezel( "Medium" ), l.pos

	local Bar = vgui.Create( "DButton", parent )
	Bar:SetSize( width, height )
	Bar:SetPos( posx, posy )
	Bar:SetText( "" )
	Bar.Paint = function( self, w, h )
		local cl = Interface.ForegroundColor

			draw.RoundedBox( 6, 0, 0, w, h, Color( cl.r, cl.g, cl.b, 255 ) )


		draw.SimpleText( middletext, Interface:GetFont(), Interface:GetBezel( "Medium" ), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM )

		draw.SimpleText( lefttext, Interface:GetTinyFont(), Interface:GetBezel( "Medium" ), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( righttext, Interface:GetTinyFont(), w - Interface:GetBezel( "Medium" ), h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )
	end

	Bar.DoClick = ( l.func or function() end )

	return Bar
end

function SMPanels.Avatar( a )
	local parent = a.parent
	local player = a.player
	local x, y = a.x, a.y
	local size = a.size
	local convert

	local Avatar = vgui.Create( "AvatarImage", parent )
	Avatar:SetSize( size, size )
	Avatar:SetPos( x, y )
	Avatar:SetCursor( "hand" )

	if isstring( player ) then
		convert = util.SteamIDTo64( player )
		Avatar:SetSteamID( convert, size )
	else
		Avatar:SetPlayer( player, size )
	end

	Avatar.OnMousePressed = function(self)
		if convert then
			local url = "http://steamcommunity.com/profiles/" .. convert
			gui.OpenURL(url)
		else
			player:ShowProfile()
		end
	end

	return Avatar
end