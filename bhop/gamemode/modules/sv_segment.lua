Segment = {}
function Segment:WaypointSetup(client)
	if (not client.waypoints) then 
		client.waypoints = {}
		client.lastWaypoint = 0
		client.lastTele = 0
	end
end

function Segment:Reset(client)
	client.waypoints = nil
end

function Segment:SetWaypoint(client)
	self:WaypointSetup(client)
	if not client.Style == _C.Style.Segment or not client.Tn then return end

	table.insert(client.waypoints, {
		frame = Bot:GetFrame(client),
		pos = client:GetPos(),
		angles = client:EyeAngles(),
		vel = client:GetVelocity(),
		time = CurTime() - client.Tn + engine.TickInterval() / 0.1
	})
	Core:Send(client, "Print", { "Timer", Lang:Get( "SegmentSet" ) })
end

function Segment:GotoWaypoint(client)
	self:WaypointSetup(client)

	if not client.Style == _C.Style.Segment then 
		return end

	if #client.waypoints < 1 then 
		Core:Send(client, "Print", {"Timer", "Set a waypoint first."})
		return
	end

	local waypoint = client.waypoints[#client.waypoints]

	client:SetPos(waypoint.pos)
	client:SetLocalVelocity(waypoint.vel)
	client:SetEyeAngles(waypoint.angles)
	client.Tn = CurTime() - waypoint.time + engine.TickInterval() / 0.1

	Core:Send(player.GetAll(), "Scoreboard", {"normal", client, client.Tn})
	Core:Send(client, "Timer", {"Start", client.Tn})
	Spectator:PlayerRestart(client)

	Bot:StripFromFrame(client, waypoint.frame)

	client.lastTele = CurTime() + 0.5 + engine.TickInterval() / 0.1
	client.TnF = nil
	client.Tb = nil
	client.TbF = nil

	Spectator:PlayerRestart( client )
	SMgrAPI:ResetStatistics( client )
end


function Segment:RemoveWaypoint(client)
	self:WaypointSetup(client)

	if not client.Style == _C.Style.Segment then return end
	if #client.waypoints < 1 then 
		Core:Send(client, "Print", {"Timer", "Set a checkpoint first."})
		return
	end

	client.waypoints[#client.waypoints] = nil 
	Core:Send(client, "Print", {"Timer", "Checkpoint removed."})
	self:GotoWaypoint(client)
end

function Segment:Exit(client)
	UI:SendToClient(client, "segment", true)
end

UI:AddListener("segment", function(client, data)
	local id = data[1]
	if (id == "set") then 
		Segment:SetWaypoint(client)
	elseif (id == "goto") then
		Segment:GotoWaypoint(client)
	elseif (id == "remove") then 
		Segment:RemoveWaypoint(client)
	elseif (id == "reset") then
		client.hasWarning = client.hasWarning or false
		if (client.hasWarning) then 
			client:ConCommand("reset")
			client.hasWarning = false
		else 
			client.hasWarning = true 
			Core:Send(client, "Print", {"Timer", "Are you sure you wish to reset your checkpoints? Press again to confirm."})
			timer.Simple(3, function()
				client.hasWarning = false
			end)
		end 
	end
end)

Command:Register({"segment", "segmented", "seg"}, function(client)
	if client.Style ~= _C.Style.Segment then
		Command:RemoveLimit(client)
		Command.Style(client, nil, {_C.Style.Segment})
		Core:Send(client, "Print", {"Timer", "To reopen the segment menu at any time, use this command again."})
	end

	UI:SendToClient(client, "segment")
end)

local msg = "You must be in Segmented to use this command."
Command:Register({"cpsave"}, function(client)
	if client.Style == _C.Style.Segment then 
		Segment:SetWaypoint(client) 
	else
		Core:Send(client, "Print", {"Timer", msg})
	end
end)

Command:Register({"cpload"}, function(client) 
	if client.Style == _C.Style.Segment then 
		Segment:GotoWaypoint(client) 
	else
		Core:Send(client, "Print", {"Timer", msg})
	end
end)

concommand.Add("bhop_cpsave", function(client)
	if client.Style == _C.Style.Segment then 
		Segment:SetWaypoint(client) 
	else
		Core:Send(client, "Print", {"Timer", msg})
	end
end)

concommand.Add("bhop_cpload", function(client)
	if client.Style == _C.Style.Segment then 
		Segment:GotoWaypoint(client) 
	else
		Core:Send(client, "Print", {"Timer", msg})
	end
end)