__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector(4792, -456, -4489.5) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector(4792, -696, -4489.5) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector(4792, -936, -4489.5) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector(4792, -1176, -4489.5) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector(4792, -1416, -4489.5) then
			ent:Remove()
		end
	end
end