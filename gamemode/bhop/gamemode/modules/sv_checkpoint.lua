Checkpoints = {}

function Checkpoints:SetUp(pl)
	if not pl.checkpoints then 
		pl.checkpoints = {}
		pl.checkpoint_current = 0
		pl.checkpoint_angles = true
	end

	local practice = pl:GetNWInt("inPractice", false)
	if not practice then 
		Core:Send(pl, "Print", { "Timer", Lang:Get( "StopTimer" ) })
	end

	pl:SetNWInt("inPractice", true)

	if pl.Tn or pl.Tb then
		pl:StopAnyTimer()
	end
end

function Checkpoints:GetCurrent(pl)
	return pl.checkpoint_current
end

function Checkpoints:SetCurrent(pl, current)
	pl.checkpoint_current = current
end

function Checkpoints:Next(pl)
	local current = self:GetCurrent(pl)

	if not pl.checkpoints[current + 1] then return end 

	self:SetCurrent(pl, current + 1)

	UI:SendToClient(pl, "checkpoints", true, current + 1, #pl.checkpoints)
end

function Checkpoints:Previous(pl)
	local current = self:GetCurrent(pl)

	if not pl.checkpoints[current - 1] then return end 

	self:SetCurrent(pl, current - 1)

	UI:SendToClient(pl, "checkpoints", true, current - 1, #pl.checkpoints)
end

function Checkpoints:ReorderFrom(pl, index, method)
	if method == "add" then
		for i = #pl.checkpoints, index, -1 do 
			pl.checkpoints[i + 1] = pl.checkpoints[i]
		end
	elseif method == "del" then
		local newcheckpoints = {}
		local i = 1

		for k, v in pairs(pl.checkpoints) do 
			newcheckpoints[i] = v
			i = i + 1
		end

		pl.checkpoints = newcheckpoints
	end
end

function Checkpoints:Save(pl)
	self:SetUp(pl)

	local d = IsValid(pl:GetObserverTarget()) and pl:GetObserverTarget() or pl
	local vel = d:GetVelocity()
	local pos = d:GetPos()
	local angles = d:EyeAngles()
	local current = self:GetCurrent(pl)

	if #pl.checkpoints > 99 then 
		Core:Send(pl, "Print", {"Timer", "Sorry, you are only allowed a maximum of 100 checkpoints!"})
		return 
	end

	if pl.checkpoints[current + 1] then 
		self:ReorderFrom(pl, current + 1, "add")
	end

	pl.checkpoints[current + 1] = {vel, pos, angles}

	self:SetCurrent(pl, current + 1)

	UI:SendToClient(pl, "checkpoints", true, current + 1, #pl.checkpoints)

	-- Calculate the timing using the tick-based method
	local tickInterval = engine.TickInterval()
	local timing = CurTime() - pl.Tn + tickInterval / 0.1

	-- Store the timing with the checkpoint data
	pl.checkpoints[current + 1].time = timing
end

function Checkpoints:Teleport(pl)
	self:SetUp(pl)

	local current = self:GetCurrent(pl)
	local data = pl.checkpoints[current]

	pl:SetLocalVelocity(data[1])
	pl:SetPos(data[2])

	if (pl.checkpoint_angles) then 
		pl:SetEyeAngles(data[3])
	end

	-- Calculate the timing using the tick-based method
	local tickInterval = engine.TickInterval()
	local timing = CurTime() - data.time + tickInterval / 0.1

	-- Set the player's timer to the calculated timing
	pl.Tn = timing
end

function Checkpoints:Reset(pl)
	self:SetUp(pl)

	if #pl.checkpoints < 1 then 
		return end 

	self:SetCurrent(pl, 0)

	pl.checkpoints = {}

	UI:SendToClient(pl, "checkpoints", true, false)
end

function Checkpoints:Delete(pl)
	self:SetUp(pl)

	if #pl.checkpoints < 1 then 
		return end 

	if #pl.checkpoints == 1 then return self:Reset(pl) end

	local current = self:GetCurrent(pl)

	pl.checkpoints[current] = nil 
	self:ReorderFrom(pl, current, "del")

	if current ~= 1 and not pl.checkpoints[current - 1] then 
		self:SetCurrent(pl, current + 1)
	elseif current ~= 1 then
		self:SetCurrent(pl, current - 1)
	end

	UI:SendToClient(pl, "checkpoints", true, self:GetCurrent(pl), #pl.checkpoints)
end

local function CheckpointOpen(pl, args)
	UI:SendToClient(pl, "checkpoints")

	if not practice then 
		Core:Send(pl, "Print", { "Timer", Lang:Get( "StopTimer" ) })
	end

	pl:SetNWInt("inPractice", true)

	if pl.checkpoints then 
		UI:SendToClient(pl, "checkpoints", true, Checkpoints:GetCurrent(pl), #pl.checkpoints)
	end

	if pl.Tn or pl.Tb or not pl:GetNWInt("inPractice", false) then 
		Core:Send(pl, "Print", { "Timer", Lang:Get( "DacTimer" ) })
	end
end
Command:Register({"cp", "checkpoints", "cps"}, CheckpointOpen)

UI:AddListener("checkpoints", function(client, data)
	local id = data[1]
	if id == "save" then 
		Checkpoints:Save(client)
	elseif id == "tp" then
		Checkpoints:Teleport(client)
	elseif id == "next" then 
		Checkpoints:Next(client)
	elseif id == "prev" then 
		Checkpoints:Previous(client)
	elseif id == "del" then 
		Checkpoints:Delete(client)
	elseif id == "reset" then 
		Checkpoints:Reset(client)
	elseif id == "angles" then 
		Checkpoints:SetUp(client)
		client.checkpoint_angles = (not client.checkpoint_angles)

		UI:SendToClient(client, "checkpoints", "angles", client.checkpoint_angles)
	end
end)
concommand.Add("bhop_checkpoint_save", function(cl) Checkpoints:Save(cl) end)
concommand.Add("bhop_checkpoint_tele", function(cl)	Checkpoints:Teleport(cl) end)
concommand.Add("bhop_checkpoint_next", function(cl)	Checkpoints:Next(cl) end)
concommand.Add("bhop_checkpoint_prev", function(cl)	Checkpoints:Previous(cl) end)
concommand.Add("bhop_checkpoint_del", function(cl) Checkpoints:Delete(cl) end)
concommand.Add("bhop_checkpoint_reset", function(cl) Checkpoints:Reset(cl) end)