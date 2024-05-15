local Doors = {["bhop_monster_jam"] = true,["bhop_bkz_goldbhop"] = true,["bhop_archives"] = true,["bhop_exzha"] = true,["bhop_aoki_final"] = true,["bhop_areaportal_v1"] = true,["bhop_ytt_space"] = true}
local NoDoors = {["bhop_hive"] = true,["bhop_fury"] = true,["bhop_mcginis_fix"] = true}
local Specials = {["bhop_lost_world"] = true,["bhop_lego2"] = true}
local Boosters = {["bhop_challenge2"] = 1,["bhop_ytt_space"] = 1.1,["bhop_dan"] = 1.5}
local PlatformIndexes, PlatformBooster = {}, {}

function IndexPlatform(id, booster)
	local Target = booster and PlatformBooster or PlatformIndexes
	local Value = booster or true
	Target[id] = Value
end

local function SelfEnts(ply)
	local ent = ply:GetGroundEntity()
	if IsValid(ent) and (ent:GetNWBool "Platform") then
		if (ent:GetClass() == "func_door" or ent:GetClass() == "func_button") and (ent.BHSp and ent.BHSp > 100) then
			local dl = 0.02
			ply.BoosterValue = ent.BHSp * 1.3
			timer.Simple(dl, function()
				if IsValid(ply) and ply.BoosterValue then
					local vel = ply:GetVelocity()
					if vel.z < 0 then
						ply.BoosterValue = ply.BoosterValue + math.abs(vel.z)
						ply:SetVelocity(Vector(0, 0, -vel.z))
					elseif vel.z == 0 and ply:KeyDown(IN_JUMP) then
						ply.BoosterValue = ply.BoosterValue + math.random(234, 248)
					end
					ply:SetVelocity(Vector(0, 0, ply.BoosterValue))
					ply.BoosterValue = nil
				end
			end)
		elseif (ent:GetClass() == "func_door" or ent:GetClass() == "func_button") then
			local dl = 2
			local fullColor = ent:GetColor()
			local dimColor = ColorAlpha(fullColor, 125)
			timer.Simple(dl, function()
				ent:SetOwner(ply)
				if CLIENT then
					ent:SetColor(dimColor)
				end
			end)
			timer.Simple(2, function()
				ent:SetOwner()
				if CLIENT then
					ent:SetColor(fullColor)
				end
			end)
		end
	end
end
hook.Add("OnPlayerHitGround", "selfents", SelfEnts)

local sf, sl, tn = string.find, string.lower, tonumber
local function KeyValueHook( ent, key, value )
	local map = game.GetMap()
	if NoDoors[map] then return end
	if sf(value, "modelindex") and sf(value, "AddOutput") then return "" end

	if ent:GetClass() == "func_door" then
		if Doors[map] then
			ent.IsP = true
		end
		if sf(sl(key), "movedir") and (value == "90 0 0") then
			ent.IsP = true
		end
		if sf(sl(key), "noise1") then
			ent.BHS = value
		end
		if sf(sl(key), "speed") then
			if tn(value) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tn(value)
		end
	elseif ent:GetClass() == "func_button" then
		if Doors[map] then
			ent.IsP = true
		end
		if sf(sl(key), "movedir") and (value == "90 0 0") then
			ent.IsP = true
		end
		if key == "spawnflags" then ent.SpawnFlags = value end
		if sf(sl(key), "sounds") then
			ent.BHS = value
		end
		if sf(sl(key), "speed") then
			if tn(value) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tn(value)
		end
	end

	if not Specials[ map ] then return end
	if map == "bhop_lost_world" then
		if ent:GetClass() == "trigger_push" then
			if string.find(string.lower(key), "speed") then
				if tonumber(value) == 1200 then
					return "1500"
				end
			end
		end
	elseif map == "bhop_exquisite" then
		for _,ent in pairs( ents.FindByClass("trigger_multiple") ) do
			if ent:GetPos() == Vector( 3264, -704.02, -974.49 ) then
				ent:Remove()
				break
			end
	end
	elseif map == "bhop_lego2" then
		if ent:GetClass() == "trigger_push" then
			if string.find(string.lower(key), "speed") then
				return tostring( tonumber( value ) + 80 )
			end
		end
	end
end
hook.Add( "EntityKeyValue", "KeyValueHook", KeyValueHook )