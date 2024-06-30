local cv_enabled = CreateClientConVar("wrsfx", "1", true, true, "WR sounds enabled state", 0, 1)
local cv_volume = CreateClientConVar("wrsfx_volume", "0.4", true, false, "WR sounds volume", 0, 1)

net.Receive("WRSFX_Broadcast", function(len, ply)
    if not cv_enabled:GetBool() then return end
    EmitSound("wrsfx/" .. net.ReadString(), vector_origin, -2, CHAN_AUTO, cv_volume:GetFloat())
end)

local function DispatchChatJoinMSG(um)
	local ply = um:ReadString()
	local mode = um:ReadString()
	local STEAMID = um:ReadString()
	if mode == "1" then
	elseif mode == "2" then
		chat.AddText(Color(255, 109, 10), "Server ", Color(255, 255 , 255), "| ", Color(255, 109, 10), ply, Color(255, 255 , 255), " (", Color(255, 109, 10), STEAMID, Color(255, 255 , 255), ")", Color(255, 255 , 255), " has joined the game.")
	elseif mode == "3" then
		chat.AddText(Color(255, 109, 10), "Server ", Color(255, 255 , 255), "| ", Color(255, 109, 10), ply, Color(255, 255 , 255), " (", Color(255, 109, 10), STEAMID, Color(255, 255 , 255), ")", Color(255, 255 , 255), " has disconnected the game.")
	end
end
usermessage.Hook("DispatchChatJoin", DispatchChatJoinMSG)

local WRSOUND = {}
WRSOUND.Enabled = CreateClientConVar("kawaii_recordsound", "1", true, false, "Enables WR Sounds")

local function RainbowColor(index, frequency)
    local r = math.sin(frequency * index + 0) * 127 + 128
    local g = math.sin(frequency * index + 2) * 127 + 128
    local b = math.sin(frequency * index + 4) * 127 + 128
    return Color(r, g, b)
end

local function RainbowText(text, frequency)
    local rainbowMessage = {}
    for i = 1, #text do
        local char = text:sub(i, i)
        local color = RainbowColor(i, frequency)
        table.insert(rainbowMessage, color)
        table.insert(rainbowMessage, char)
    end
    return rainbowMessage
end

local function DispatchChatWR(um)
    local ply = um:ReadString()
    local mode = um:ReadString()
    local STEAMID = um:ReadString()
    local WRSOUNDEnabled = WRSOUND.Enabled:GetBool()

    local message = string.format(
        "Server | New World Record! New Top Record.",
        ply
    )

    if WRSOUNDEnabled then
        surface.PlaySound("common/talk.wav")
    end

    local rainbowMessage = RainbowText(message, 0.05)

    chat.AddText(unpack(rainbowMessage))
end
usermessage.Hook("DispatchChatWR", DispatchChatWR)