surface.CreateFont( "m_hMediumFontTiny", { size = 18, weight = 800, font = "Arial" } )
surface.CreateFont( "m_hLargeFontTiny", { size = 20, weight = 800, font = "Arial" } )
surface.CreateFont( "m_hLargeFontTiny2", { size = 17, weight = 800, font = "Arial" } )
surface.CreateFont( "m_hMediumFont", { size = 20, weight = 600, font = "Arial" } )
surface.CreateFont( "m_hLargeFont", { size = 23, weight = 600, font = "Arial" } )
surface.CreateFont( "m_hMediumFontItalics", { size = 18, weight = 600, italic = true, font = "Arial" } )
surface.CreateFont( "m_hLargeFontItalics", { size = 23, weight = 600, italic = true, font = "Arial" } )
surface.CreateFont( "m_hMediumBoldFont", { size = 20, weight = 800, font = "Arial" } )
surface.CreateFont( "m_hLargeBoldFont", { size = 23, weight = 800, font = "Arial" } )
surface.CreateFont( "m_hMediumBoldFontItalics", { size = 20, weight = 600, italic = true, font = "Arial" } )
surface.CreateFont( "m_hLargeBoldFontItalics", { size = 25, weight = 600, italic = true, font = "Arial" } )
surface.CreateFont( "m_hMediumBigFont", { size = 28, weight = 800, font = "Arial" } )
surface.CreateFont( "m_hLargeBigFont", { size = 33, weight = 800, font = "Arial" } )

Interface = {}
Interface.Started = false
Interface.Scale = 0
Interface.TinyFont = { [0] = "m_hMediumFontTiny", [1] = "m_hLargeFontTiny" }
Interface.TinyFontInfo = { [0] = "m_hMediumFontTiny2", [1] = "m_hLargeFontTiny2" }
Interface.Font = { [0] = "m_hMediumFont", [1] = "m_hLargeFont" }
Interface.BoldFont = { [0] = "m_hMediumBoldFont", [1] = "m_hLargeBoldFont" }
Interface.BigFont = { [0] = "m_hMediumBigFont", [1] = "m_hLargeBigFont" }
Interface.FontItalics = { [0] = "m_hMediumFontItalics", [1] = "m_hLargeFontItalics" }
Interface.BoldFontItalics = { [0] = "m_hMediumBoldFontItalics", [1] = "m_hLargeBoldFontItalics" }
Interface.TinyFontHeight = { [0] = 15, [1] = 23 }
Interface.FontHeight = { [0] = 27, [1] = 35 }
Interface.FrameBezel = { [0] = 60, [1] = 80 }
Interface.TinyFrameBezel = { [0] = 30, [1] = 40 }
Interface.TinyBezel = { [0] = 3.5, [1] = 5 }
Interface.MediumBezel = { [0] = 12, [1] = 15 }
Interface.MediumBezel2 = { [0] = 8, [1] = 8 }
Interface.LargeBezel = { [0] = 18, [1] = 23 }
Interface.BigBezel = { [0] = 23, [1] = 30 }
Interface.BackgroundColor = Color( 43, 43, 43 )
Interface.ForegroundColor = Color( 54, 54, 54 )
Interface.HighlightColor = Color( 55, 122, 151 )
Interface.Wide = 0

local lookup = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudSuitPower = true
}

hook.Add("HUDShouldDraw", "HUD_Hide", function(name)
	if lookup[name] then return false end
end)

function Interface:GetBezel( bezel )
	local bezelSend = nil
	if bezel == "Frame" then
		bezelSend = Interface.FrameBezel[Interface.Scale]
	elseif bezel == "TinyFrame" then
		bezelSend = Interface.TinyFrameBezel[Interface.Scale]
	elseif bezel == "Tiny" then
		bezelSend = Interface.TinyBezel[Interface.Scale]
	elseif bezel == "Medium" then
		bezelSend = Interface.MediumBezel[Interface.Scale]
	elseif bezel == "MediumInfo" then
		bezelSend = Interface.MediumBezel2[Interface.Scale]
	elseif bezel == "Large" then
		bezelSend = Interface.LargeBezel[Interface.Scale]
	elseif bezel == "Big" then
		bezelSend = Interface.BigBezel[Interface.Scale]
	end

	if !bezelSend then
		BHOP:Notify( "Warning", "Attempted to request bezel without specifying a type, defaulting to MediumBezel" )
		bezelSend = Interface.MediumBezel[Interface.Scale]
	end

	return bezelSend
end

function Interface:GetTinyFont()
	return Interface.TinyFont[ Interface.Scale ]
end

function Interface:GetFont( italic )
	return italic and Interface.FontItalics[Interface.Scale] or Interface.Font[ Interface.Scale ]
end

function Interface:GetBigFont()
	return Interface.BigFont[ Interface.Scale ]
end

function Interface:GetBoldFont( italic )
	return italic and Interface.BoldFontItalics[Interface.Scale] or Interface.BoldFont[ Interface.Scale ]
end

function Interface:SplitText( text )
	local tab = string.Split( text, "\n" )

	return tab
end

function Interface:GetTextWidth( tab, font )
	if !tab or !istable( tab ) or #tab == 0 then
		BHOP:Notify( "Warning", "Attempted to get text width but either an invalid comparison was sent or there's nothing to compare, defaulting to 0" )
	return 0 end

	surface.SetFont( font or Interface:GetFont() )

	local w = 0
	local getTextSize = surface.GetTextSize

	for i = 1, #tab do
		local index = tab[i]
		if !index then continue end

		local text = istable(index) and ( i .. ") " .. index[1] ) or index
		local textW = getTextSize( text )

		if textW >= w then
			w = textW
		end
	end

	local add = ( i == -1 and Interface:GetBezel( "Large" ) * 2 or Interface:GetBezel( "Medium" ) * 2 )
	return w + add
end

function Interface:GetTextHeight( tab, add, close )
	local additive = add or 0
	local fontheight = Interface.FontHeight[Interface.Scale]
	local height = 0

	height = ( ( Interface:GetBezel( "Medium" ) * 2 ) + ( fontheight * #tab ) + ( additive * 2 ) )

	if close then
		height = height - ( Interface:GetBezel( "Medium" ) * 4 )
	end

	return height
end