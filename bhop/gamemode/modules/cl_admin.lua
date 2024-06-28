Admin = {}
Admin.Protocol = "Admin"
local Verify = false
local Secure = {}
local RawCache = {}
local DrawData = nil
local DrawTimer = nil
local ElemList = {}
local ElemCache = {}
local ElemData = {}
local screenshotRequest = false

function Admin:Receive( varArgs )
	local szType = tostring( varArgs[ 1 ] )
	if szType == "Open" then
		Secure.Setup = varArgs[ 2 ]
		Verify = true
		Window:Open( "Admin" )
	elseif szType == "Query" then
		local tab, func = varArgs[ 2 ], {}
		for i = 1, #tab do
			table.insert( func, tab[ i ][ 1 ] )
			table.insert( func, function() Admin:ReqAction( tab[ i ][ 2 ][ 1 ], tab[ i ][ 2 ][ 2 ] ) end )
		end
		Window.MakeQuery( tab.Caption, tab.Title, unpack( func ) )
	elseif szType == "EditZone" then
		Secure.Editor = varArgs[ 2 ] and varArgs[ 2 ] or nil
	elseif szType == "Request" then
		local tab = varArgs[ 2 ]
		Window.MakeRequest( tab.Caption, tab.Title, tab.Default, function( r ) Admin:ReqAction( tab.Return, r or tab.Default ) end, function() end )
	elseif szType == "Edit" then
		Admin.EditType = varArgs[ 2 ]
	elseif szType == "Raw" then
		RawCache = varArgs[ 2 ]
	elseif szType == "Message" then
		DrawData = varArgs[ 2 ]
		DrawTimer = CurTime()
	elseif szType == "Grab" then
		screenshotRequest = true
	elseif szType == "GUI" then
		Verify = true
		Window:Open( varArgs[ 2 ], varArgs[ 3 ], true )
	elseif szType == "GUIData" then
		Admin:SubmitAction( varArgs[ 2 ], varArgs[ 3 ] )
	end
end

function Admin:ReqAction( nID, varData )
	if not Verify then return end
	if not nID or nID < 0 then return end
	Link:Send( "Admin", { -1, nID, varData } )
end

function Admin:SendAction( nID, varData )
	if not Verify then return end
	if not nID or nID < 0 then return end
	Link:Send( "Admin", { -2, nID, varData } )
end

function Admin:IsAvailable() return Verify end

local function ButtonCallback( self )
	if self.Close then
		return Window:Close()
	elseif self.VIP and self.Extra then
		if self.Extra == "Random" then
			ElemCache["ColorChat"]:SetColor( Core.Util:RandomColor() )
		elseif self.Extra == "Gradient" then
			Link:Send( "Admin", { 1, { self.Extra, ElemCache["ColorTag"]:GetColor(), ElemCache["ColorName"]:GetColor(), ElemCache["TextName"]:GetValue() } } )
		elseif self.Extra == "Tag" or self.Extra == "Name" then
			Link:Send( "Admin", { 1, { self.Extra, ElemCache["Color" .. self.Extra]:GetColor(), ElemCache["Text" .. self.Extra]:GetValue() } } )
		else
			Link:Send( "Admin", { 1, { self.Extra, self.Extra == "Save" and ElemCache["ColorChat"]:GetColor() or nil } } )
		end
		return false
	end
	if not ElemData.Store then return end
	local data = ElemData.Store:GetValue()
	if not self.Require or (data != "" and data != ElemData.Default) then
		Admin:SendAction( self.Identifier, ElemData.Store:GetValue() )
	else
		Link:Print( "Admin", "You have to select or enter a valid player steam id." )
	end
end

local function CreateElement( data, parent )
	local elem = vgui.Create( data["Type"], parent )
	for func,args in pairs( data["Modifications"] ) do
		if func == "Sequence" then
			for _,seq in pairs( args ) do
				local f = elem[ seq[ 1 ] ]
				local d = f( elem, unpack( seq[ 2 ] ) )
				if seq[ 3 ] then
					local q = d[ seq[ 3 ] ]
					q( d, seq[ 4 ] )
				end
			end
		else
			local f = elem[ func ]
			f( elem, unpack( args ) )
		end
	end

	if data["Label"] then
		ElemCache[ data["Label"] ] = elem
	end

	if data["Type"] == "DListView" then
		elem.OnRowSelected = function( self, row )
			if ElemData.Store then
				ElemData.Store:SetText( self:GetLine( row ):GetValue( 2 ) )
			end
		end
	elseif data["Type"] == "DButton" then
		elem.Identifier = data["Identifier"]
		elem.Require = data["Require"]
		elem.VIP = data["VIP"]
		elem.Extra = data["Extra"]
		elem.Close = data["Close"]
		elem.DoClick = ButtonCallback
	end

	table.insert( ElemList, elem )
end

function Admin:SubmitAction( szID, varArgs )
	if szID == "Players" then
		local elem = ElemCache["PlayerList"]
		if not elem then return end
		for _,line in pairs( varArgs ) do
			elem:AddLine( unpack( line ) )
		end
	elseif szID == "Store" then
		ElemData.Store = ElemCache[ varArgs[ 1 ] ]
		ElemData.Default = varArgs[ 2 ]
	end
end

function Admin:GenerateGUI( parent, data )
	parent:Center()
	parent:MakePopup()

	ElemList = {}

	for i = 1, #data do
		local elemdata = data[ i ]
		CreateElement( elemdata, parent )
	end
end

local function GrabScreenshot()
	if !screenshotRequest then return end
	screenshotRequest = false
	local data = util.Compress( util.Base64Encode( render.Capture( { format = "jpeg", w = ScrW(), h = ScrH(), x = 0, y = 0, quality = 1 } ) ) )
	local length = #data
	net.Start( Link.Protocol2 )
	net.WriteUInt( length, 32 )
	net.WriteData( data, length )
	net.SendToServer()
end
hook.Add( "PostRender", "bhop_GrabScreenshot", GrabScreenshot )

local function ReceiveGrab()
	local id = net.ReadString()
	local length = net.ReadUInt( 32 )

	if id == "Help" then
		if length > 0 then
			local data = util.Decompress( net.ReadData( length ) )
			if not data then return Link:Print( "Notification", "Couldn't load help" ) end

			Cache.H_Data = util.JSONToTable( data )
		end

		return Client:ShowHelp( Cache.H_Data )
	end

	local data = util.Decompress( net.ReadData( length ) )
	if id == "Data" then
		if not data then return Link:Print( "Admin", "Couldn't obtain data!" ) end

		local frame = vgui.Create( "DFrame" )
		frame:SetSize( ScrW() * 0.8, ScrH() * 0.8 )
		frame:MakePopup()
		frame:Center()
		frame:SetTitle( "Admin Data" )

		local html = frame:Add("HTML")
		html:SetHTML([[<style type="text/css">body{margin:0;padding:0;overflow:hidden;} img{width:100%;height:100%;}</style><img src="data:image/jpg;base64,]] .. data .. [[">]])
		html:Dock( FILL )
	elseif id == "List" then
		if not data then return Link:Print( "Notification", "An error occurred while obtaining data!" ) end
		local tab = util.JSONToTable( data )
		if not tab[ 1 ] or not tab[ 2 ] then return end
		Cache:M_Save( tab[ 1 ], tab[ 2 ], true )
	end
end
net.Receive( Link.Protocol2, ReceiveGrab )

-- Define a ConVar for enabling/disabling snapping
CreateConVar("kawaii_drawarea_snap", "0", { FCVAR_ARCHIVE, FCVAR_CLIENTCMD_CAN_EXECUTE }, "Enable/disable snapping in draw area editor")

local DrawLaser = Material("sprites/jscfixtimer")
local Col = HSVToColor(RealTime() * 40 % 360, 1, 1)
local DrawWidth = 1

local function RoundTo(val, grid)
    return math.Round(val / grid) * grid
end

local function SnapPosition(pos)
    if GetConVar("kawaii_drawarea_snap"):GetBool() then
        local gridSize = 32  -- Default grid size
        local lp = LocalPlayer()

        local n = 32  -- Default grid size
        local z = false  -- Default value for z

        if lp:KeyDown(IN_SPEED) then
            z = true  -- Set z to true for faster snapping
        end
        if lp:KeyDown(IN_DUCK) then
            n = 16  -- Set a smaller grid size if the player is crouching
        end

        gridSize = n

        return Vector(RoundTo(pos.x, gridSize), RoundTo(pos.y, gridSize), RoundTo(pos.z, gridSize))
    else
        return pos  -- Return the original position if snapping is disabled
    end
end

local function DrawAreaEditor()
    if Secure.Editor and Secure.Editor.Active then
        local Start, End = Secure.Editor.Start, SnapPosition(LocalPlayer():GetPos())
        local Min = Vector(math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z))
        local Max = Vector(math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128))

        local Center = (Min + Max) / 2
        local Size = Max - Min

        local C1 = Center + Vector(-Size.x / 2, -Size.y / 2, -Size.z / 2)
        local C2 = Center + Vector(-Size.x / 2, Size.y / 2, -Size.z / 2)
        local C3 = Center + Vector(Size.x / 2, Size.y / 2, -Size.z / 2)
        local C4 = Center + Vector(Size.x / 2, -Size.y / 2, -Size.z / 2)
        local C5 = Center + Vector(-Size.x / 2, -Size.y / 2, Size.z / 2)
        local C6 = Center + Vector(-Size.x / 2, Size.y / 2, Size.z / 2)
        local C7 = Center + Vector(Size.x / 2, Size.y / 2, Size.z / 2)
        local C8 = Center + Vector(Size.x / 2, -Size.y / 2, Size.z / 2)

        render.SetMaterial(DrawLaser)

        render.DrawBeam(C1, C2, DrawWidth, 0, 1, Col)
        render.DrawBeam(C2, C3, DrawWidth, 0, 1, Col)
        render.DrawBeam(C3, C4, DrawWidth, 0, 1, Col)
        render.DrawBeam(C4, C1, DrawWidth, 0, 1, Col)

        render.DrawBeam(C5, C6, DrawWidth, 0, 1, Col)
        render.DrawBeam(C6, C7, DrawWidth, 0, 1, Col)
        render.DrawBeam(C7, C8, DrawWidth, 0, 1, Col)
        render.DrawBeam(C8, C5, DrawWidth, 0, 1, Col)

        render.DrawBeam(C1, C5, DrawWidth, 0, 1, Col)
        render.DrawBeam(C2, C6, DrawWidth, 0, 1, Col)
        render.DrawBeam(C3, C7, DrawWidth, 0, 1, Col)
        render.DrawBeam(C4, C8, DrawWidth, 0, 1, Col)
    end
end

hook.Add("PostDrawOpaqueRenderables", "PreviewArea", DrawAreaEditor)