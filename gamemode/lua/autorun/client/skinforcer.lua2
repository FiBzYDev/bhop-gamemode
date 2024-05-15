
if SERVER then
	AddCSLuaFile("skins/lightblue.lua")
	AddCSLuaFile()

	resource.AddSingleFile("materials/gwenskin/lightblue.png")
else
	include("skins/lightblue.lua")

	hook.Add("ForceDermaSkin", "skinforcehook", function()
		return "lightblue"
	end)
end
