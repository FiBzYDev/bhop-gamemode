local TriggerType = {
	OTHER = 1,
	TELEPORT = 2,
	TELE_FILTER = 3,
	PUSH = 4,
	BASEVEL = 5,
	GRAVITY = 6,
	ANTIPRE = 7,
	PLATFORM = 8,
	MAX = 8,
}

local MaterialEnum = {
	WIREFRAME = 0,
	DEFAULT = 1,
	SOLID = 2,
}

ShowHidden.TriggerType = TriggerType
ShowHidden.MaterialEnum = MaterialEnum

ShowHidden.DEFAULT_TRIGGERS_COLORS = {
	[TriggerType.PUSH] =        { color = Color(128, 255, 0, 255),  material = MaterialEnum.DEFAULT },
	[TriggerType.BASEVEL] =     { color = Color(0, 255, 0, 255),    material = MaterialEnum.DEFAULT },
	[TriggerType.GRAVITY] =     { color = Color(0, 255, 128, 255),  material = MaterialEnum.DEFAULT },
	[TriggerType.TELEPORT] =    { color = Color(0, 255, 0, 255),    material = MaterialEnum.DEFAULT },
	[TriggerType.TELE_FILTER] = { color = Color(255, 0, 128, 128),  material = MaterialEnum.DEFAULT },
	[TriggerType.ANTIPRE] =     { color = Color(192, 0, 255, 64),   material = MaterialEnum.SOLID },
	[TriggerType.PLATFORM] =    { color = Color(0, 128, 255, 128),  material = MaterialEnum.WIREFRAME },
	[TriggerType.OTHER] =       { color = Color(255, 192, 0, 128),  material = MaterialEnum.WIREFRAME },
}

ShowHidden.TRIGGERS_MATERIAL_NAMES = {
	[MaterialEnum.WIREFRAME] = "models/wireframe",
	[MaterialEnum.DEFAULT] = "tools/toolstrigger",
	[MaterialEnum.SOLID] = "!triggers_solid",
}

ShowHidden.TRACK_TRIGGERS = {
	["trigger_teleport_relative"] = true,
	["trigger_teleport"] = true,
	["trigger_push"] = true,
	["trigger_multiple"] = true,
}

ShowHidden.ALL_TYPES = math.pow(2, ShowHidden.TriggerType.MAX) - 1

function ShowHidden.CheckMask(mask, shift)
	return bit.band(mask, bit.rol(1, shift - 1)) ~= 0
end