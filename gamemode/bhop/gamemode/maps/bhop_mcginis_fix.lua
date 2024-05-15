local tmrPositions = {
	Vector(-6080, -1296, -1413.93),
	Vector(-6408, -1296, -1413.93),
	Vector(-6808, -1296, -1413.93),
	Vector(-6896, -1472, -1413.93),
	Vector(-6896, -1728, -1413.93),
	Vector(-6896, -2048, -1413.93),
	Vector(-6896, -2320, -1413.93),
}

local function RemoveEntitiesByClass(className)
	for _, ent in pairs(ents.FindByClass(className)) do
		if IsValid(ent) then
			ent:Remove()
		end
	end
end

__HOOK["InitPostEntity"] = function()
	-- Remove game_player_equip entities
	RemoveEntitiesByClass("game_player_equip")

	-- Remove specific trigger_teleport entities
	local teleportPositionsToRemove = {
		Vector(10240.1, -14144, -4816),
		Vector(10240.1, -14336, -4816)
	}
	for _, pos in pairs(teleportPositionsToRemove) do
		for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
			if IsValid(ent) and ent:GetPos() == pos then
				ent:Remove()
			end
		end
	end

	-- Remove specific func_tanktrain entities
	local trainPositionsToRemove = {
		Vector(10240.1, -14144, -4824),
		Vector(10240.1, -14336, -4824)
	}
	for _, pos in pairs(trainPositionsToRemove) do
		for _, ent in pairs(ents.FindByClass("func_tanktrain")) do
			if IsValid(ent) and ent:GetPos() == pos then
				ent:Remove()
			end
		end
	end

	-- Remove path_track entities with "train" in their name
	for _, ent in pairs(ents.FindByClass("path_track")) do
		if IsValid(ent) and string.find(ent:GetName(), "train", 1, true) then
			ent:Remove()
		end
	end

	-- Remove trigger_multiple entities at specific positions
	for _, pos in pairs(tmrPositions) do
		for _, ent in pairs(ents.FindByClass("trigger_multiple")) do
			if IsValid(ent) and ent:GetPos() == pos then
				ent:Remove()
			end
		end
	end

	-- Open all func_door entities
	for _, ent in pairs(ents.FindByClass("func_door")) do
		if IsValid(ent) then
			ent:Fire("Open")
		end
	end
end

__HOOK["EntityKeyValue"] = function(ent, key, value)
	if IsValid(ent) and ent:GetClass() == "func_door" and string.lower(key) == "wait" and tonumber(value) == 4 then
		return "-1"  -- Override the "wait" value for specific func_door entities
	end
end