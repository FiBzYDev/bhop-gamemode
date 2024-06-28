local colors = {
    ["red"] = {color = Color(255, 0, 0), size = 5},
    ["black"] = {color = Color(0, 0, 0), size = 5},
    ["blue"] = {color = Color(0, 0, 248), size = 5},
    ["brown"] = {color = Color(104, 49, 0), size = 5},
    ["cyan"] = {color = Color(0, 244, 248), size = 5},
    ["green"] = {color = Color(0, 252, 0), size = 100},
    ["orange"] = {color = Color(248, 148, 0), size = 5},
    ["pink"] = {color = Color(248, 0, 248), size = 5},
    ["purple"] = {color = Color(147, 0, 248), size = 5},
    ["white"] = {color = Color(255, 255, 255), size = 5},
    ["yellow"] = {color = Color(248, 252, 0), size = 5},
    ["yellow_med"] = {color = Color(248, 252, 0), size = 5},
    ["white_med"] = {color = Color(255, 255, 255), size = 5},
    ["pink_med"] = {color = Color(248, 0, 248), size = 5},
    ["blue_med"] = {color = Color(0, 0, 248), size = 5},
    ["red_med"] = {color = Color(255, 0, 0), size = 5},
    ["cyan_large"] = {color = Color(0, 244, 248), size = 5},
}

-- Add paint_size cvar
CreateConVar("paint_size", "5", FCVAR_ARCHIVE, "Size of the paint decal")

for v,_ in pairs(colors) do
    game.AddDecal("paint_" .. v, "decals/paint/laser_" .. v)
    if SERVER then
        resource.AddFile("materials/decals/paint/laser_" .. v .. ".vmt")
        resource.AddFile("materials/decals/paint/laser_" .. v .. "_med.vmt")
    end
end

if SERVER then
    util.AddNetworkString "PaintCreated"
    util.AddNetworkString "PaintHistory"
    util.AddNetworkString "UpdatePaintSize" -- Added network string for updating paint size
    local cooldown_time = 0.05
    local cooldown = {}
    local tempCache = {}
    local tempIndex = 1

    Command:Register( { "paintcolor" }, function( ply, args )
        if !ply.IsVIP then
            return Core:Send( ply, "Print", { "Notification", "You need to be an Elevated VIP in order to use this." } )
        end
        if !ply.PaintColor then ply.PaintColor = "red" end
        local newColor = string.lower( args[1] )
        local isValidPaint = colors[newColor]
        if !isValidPaint then
            Core:Send( ply, "Print", { "Notification", "This is an invalid color, locate your choices in the Donators tab inside the !menu panel | Color " .. newColor } )
            return
        end
        ply.PaintColor = newColor
        Core:Send( ply, "Print", { "Notification", "Your new paint color has changed to " .. newColor .. "." } )
    end )

    concommand.Add("sm_paint", function(ply)
        if !ply.IsVIP then return end
        if ply.Spectating then return end
        if cooldown[ply] and cooldown[ply] > RealTime() then return end
        cooldown[ply] = RealTime() + cooldown_time

        local eyePos = ply:EyePos() - Vector(0, 0, 16)
        local trace = ply:GetEyeTrace()
        local col = ply.PaintColor or "green"
        if !colors[col] then col = "green" end

        net.Start "PaintCreated"
            net.WriteVector(eyePos)
            net.WriteVector(trace.HitPos)
            net.WriteNormal(trace.HitNormal)
            net.WriteString(col)
        net.Broadcast()

        tempCache[tempIndex] = { trace.HitPos, trace.HitNormal, col }
        tempIndex = tempIndex + 1

        if tempIndex > 256 then
            tempIndex = 1
        end
    end)

    local function SendPaintHistory( ply )
        local cache = #tempCache
        if (cache == 0) then return end

        net.Start( "PaintHistory" )
            net.WriteUInt(cache, 8)
            for _,data in pairs(tempCache) do
                local pos, norm, col = data[1], data[2], data[3]
                net.WriteVector(pos)
                net.WriteNormal(norm)
                net.WriteString(col)
            end
        net.Send( ply )
    end

    local function RequestPaintHistory( ply )
        hook.Add("SetupMove",ply,function(self,ply,_,cmd)
            if self == ply and !cmd:IsForced() then
                SendPaintHistory( ply )
                hook.Remove("SetupMove",self)
            end
        end )
    end
    hook.Add( "PlayerInitialSpawn", "bhop_Paint.History", RequestPaintHistory )

    -- Function to send paint size update to clients
    local function SendPaintSizeUpdate(ply)
        net.Start("UpdatePaintSize")
        net.WriteFloat(GetConVar("paint_size"):GetFloat())
        net.Send(ply)
    end
    hook.Add("PlayerInitialSpawn", "SendPaintSizeUpdate", SendPaintSizeUpdate)
end

if CLIENT then
    local paintBeamCache = {}
    net.Receive("PaintCreated", function()
        local eye  = net.ReadVector()
        local pos  = net.ReadVector()
        local norm = net.ReadNormal()
        local col  = net.ReadString()
        util.Decal("paint_" .. col, pos - norm, pos, ColorAlpha(colors[col].color, 255), colors[col].size) -- Use paint size
        table.insert(paintBeamCache, {eye, pos, norm, col, CurTime()})
    end)

    net.Receive("PaintHistory", function(len, _)
        local indices = net.ReadUInt(8)
        local size = string.NiceSize(len)
        for i = 1, indices do
            local pos, norm, col = net.ReadVector(), net.ReadNormal(), net.ReadString()

            util.Decal("paint_" .. col, pos - norm, pos, ColorAlpha(colors[col].color, 255), colors[col].size) -- Use paint size
        end
    end)

    local cooldown_time = 0.05
    local cooldown = 0
    local bindedKey = input.LookupBinding( "sm_paint" ) or "g"
    local keyCode = input.GetKeyCode( bindedKey )

    local function BindTracker()
        local currentKey = input.LookupBinding( "sm_paint" ) or "g"
        if (currentKey == bindedKey) then return end

        bindedKey = currentKey
        keyCode = input.GetKeyCode( bindedKey )
    end
    timer.Create( "bhop_Paint.BindTracker", 1, 0, BindTracker )

    local function PaintSpammer()
        if vgui.CursorVisible() then return end
        if cooldown > RealTime() then return end

        cooldown = RealTime() + cooldown_time

        local isPressing = input.IsButtonDown( keyCode )
        if !isPressing then return end

        RunConsoleCommand( "sm_paint" )
    end
    hook.Add( "Think", "bhop_Paint.Spammer", PaintSpammer )

    -- Receive paint size update from server
    net.Receive("UpdatePaintSize", function()
        local size = net.ReadFloat()
        for _, color in pairs(colors) do
            color.size = size
        end
    end)
end
