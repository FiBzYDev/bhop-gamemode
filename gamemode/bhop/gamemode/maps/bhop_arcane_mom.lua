__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "func_dustmotes" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_precipitation" ) ) do
		ent:Remove()
	end	
end