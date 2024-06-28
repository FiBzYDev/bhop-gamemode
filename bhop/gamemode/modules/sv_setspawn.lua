Setspawn = {}
Setspawn.Points = {}
local function SetspawnHandler(ply)
	if ply:Team() == TEAM_SPECTATOR then
		Core:Send(ply, "Print", {"Timer", "You have to be alive and playing to be able to use it"})
	return end
	if !ply:OnGround() then
		Core:Send(ply, "Print", {"Timer", "You have to touch the ground to be able to use it"})
	return end
	if ply:GetVelocity():Length2D() != 0 then
		Core:Send(ply, "Print", {"Timer", "You have to stay still to be able to use it"})
	return end
	local steamID = ply:SteamID()
	if !Setspawn.Points[steamID] then
		Setspawn.Points[steamID] = {}
	end
	local modelPos, eyeAngle = ply:GetPos(), ply:EyeAngles()
	local spawnIdentifier = (ply.Style == _C.Style.Bonus and 2 or 0)
	if !Zones:IsInside(ply, spawnIdentifier) then
		Core:Send(ply, "Print", {"Timer", "Unable to set spawn point, make sure you are in the starting zone"})
	return end
	Setspawn.Points[steamID][spawnIdentifier] = {modelPos, eyeAngle}
	Core:Send( ply, "Print", { "Timer", Lang:Get( "SetSpawn" ) } )
end
Command:Register({"setspawn", "spawnpoint", "ss"}, SetspawnHandler)