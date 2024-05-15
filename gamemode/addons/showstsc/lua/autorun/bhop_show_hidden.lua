-- ShowClips and ShowTriggers --
-- By CLazStudio

ShowHidden = ShowHidden or {}
ShowHidden.Refresh = (ShowHidden.Refresh ~= nil)
if SERVER then
	AddCSLuaFile("showstsc/lib/luabsp.lua")
	AddCSLuaFile("showstsc/sh_init.lua")
	AddCSLuaFile("showstsc/cl_init.lua")
	AddCSLuaFile("showstsc/cl_lang.lua")
	include("showstsc/sh_init.lua")
	include("showstsc/sv_init.lua")
else
	ShowHidden.luabsp = include("showstsc/lib/luabsp.lua")
	include("showstsc/sh_init.lua")
	include("showstsc/cl_init.lua")
	include("showstsc/cl_lang.lua")
end