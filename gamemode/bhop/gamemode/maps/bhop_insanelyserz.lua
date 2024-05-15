__HOOK[ "InitPostEntity" ] = function()

	local opt = Core.GetMapVariable( "Options" )

	local list = Core.GetMapVariable( "OptionList" )

	opt = bit.bor( opt, list.NoSpeedLimit )

	Core.SetMapVariable( "Options", opt )

	Core.ReloadMapOptions()
end