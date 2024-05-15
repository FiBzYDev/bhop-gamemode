__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "env_sun" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "prop_*" ) ) do
		ent:Remove()
	end
end