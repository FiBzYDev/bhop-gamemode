AddCSLuaFile("modules/fpsfixes/cl_nixthelag.lua")

-- Let's remove a bunch of expensive stuff that is never used.

hook.Add("Initialize", "NixTheLag", function()
	-- Horrible amount of cycle usage, especially on the server.
	hook.Remove("PlayerTick", "TickWidgets")

	if SERVER then
		-- Forget what this is but probably retarded.
		if timer.Exists("CheckHookTimes") then
			timer.Remove("CheckHookTimes")
		end
	end

	if CLIENT then
		-- These call on bloated convar getting methods and aren't ever used anyway outside of sandbox.
		hook.Remove("RenderScreenspaceEffects", "RenderColorModify")
		hook.Remove("RenderScreenspaceEffects", "RenderBloom")
		hook.Remove("RenderScreenspaceEffects", "RenderToyTown")
		hook.Remove("RenderScreenspaceEffects", "RenderTexturize")
		hook.Remove("RenderScreenspaceEffects", "RenderSunbeams")
		hook.Remove("RenderScreenspaceEffects", "RenderSobel")
		hook.Remove("RenderScreenspaceEffects", "RenderSharpen")
		hook.Remove("RenderScreenspaceEffects", "RenderMaterialOverlay")
		hook.Remove("RenderScreenspaceEffects", "RenderMotionBlur")
		hook.Remove("RenderScene", "RenderStereoscopy")
		hook.Remove("RenderScene", "RenderSuperDoF")
		hook.Remove("GUIMousePressed", "SuperDOFMouseDown")
		hook.Remove("GUIMouseReleased", "SuperDOFMouseUp")
		hook.Remove("PreventScreenClicks", "SuperDOFPreventClicks")
		hook.Remove("PostRender", "RenderFrameBlend")
		hook.Remove("PreRender", "PreRenderFrameBlend")
		hook.Remove("Think", "DOFThink")
		hook.Remove("RenderScreenspaceEffects", "RenderBokeh")
		hook.Remove("NeedsDepthPass", "NeedsDepthPass_Bokeh")
	
		-- Useless since we disabled widgets above.
		hook.Remove("PostDrawEffects", "RenderWidgets")
	
		-- Could screw with people's point shops but whatever.
		hook.Remove("PostDrawEffects", "RenderHalos")
	
		-- Additional hooks to remove for better FPS.
		hook.Remove("HUDPaint", "RenderFlash")
		hook.Remove("HUDPaint", "RenderHintDisplay")
		hook.Remove("HUDPaint", "RenderVehicleBeam")
		hook.Remove("PostDrawEffects", "RenderPhysgunBeam")
		hook.Remove("Think", "CheckSchedules")
		hook.Remove("Think", "FireBullets")
		hook.Remove("Think", "AutoSaveThink")
		hook.Remove("Think", "ChatIndicatorsThink")
		hook.Remove("Think", "PlayerThink")
		hook.Remove("PlayerTick", "TickWidgets")
		hook.Remove("PlayerTick", "PlayerTick")
	
		-- Potentially unnecessary HUD elements
		hook.Remove("HUDPaint", "DrawTargetID")
		hook.Remove("HUDPaint", "DrawDeathNotice")
		hook.Remove("HUDPaint", "DrawPickupHistory")
		hook.Remove("HUDPaint", "DrawWeaponSelection")
		hook.Remove("HUDPaint", "DrawHUD")
	
		-- More hooks that can be removed for better performance
		hook.Remove("HUDPaint", "DrawWatermark")
		hook.Remove("HUDPaint", "DrawCrosshair")
		hook.Remove("PostDrawOpaqueRenderables", "RenderEffects")
		hook.Remove("RenderScreenspaceEffects", "RenderCombineOverlay")
		hook.Remove("RenderScreenspaceEffects", "RenderMaterialOverlay")
		hook.Remove("PostDrawOpaqueRenderables", "RenderScreenspaceEffects")
		hook.Remove("PostDrawTranslucentRenderables", "RenderScreenspaceEffects")
		hook.Remove("PostDrawTranslucentRenderables", "RenderWidgets")
		hook.Remove("PreDrawHalos", "PropertiesHover")
		hook.Remove("PreDrawHalos", "PropertiesHoverEntity")
		hook.Remove("PreDrawHalos", "AddEntityHalos")
	
		-- Hooks related to entity drawing that might not be necessary
		hook.Remove("PreDrawEffects", "RenderEffects")
		hook.Remove("PostDrawEffects", "RenderEffects")
		hook.Remove("RenderScreenspaceEffects", "RenderEffects")
		hook.Remove("RenderScreenspaceEffects", "RenderHalos")
		hook.Remove("RenderScreenspaceEffects", "RenderWidgets")
	
		-- Removing hooks related to weapon drawing that might not be necessary
		hook.Remove("HUDPaintBackground", "DrawHUDBackground")
		hook.Remove("PreDrawViewModel", "DrawViewModel")
		hook.Remove("PostDrawViewModel", "DrawViewModel")
		hook.Remove("PreDrawPlayerHands", "DrawPlayerHands")
		hook.Remove("PostDrawPlayerHands", "DrawPlayerHands")
	
		-- Other hooks that can potentially be removed for performance
		hook.Remove("Think", "MotionBlurThink")
		hook.Remove("RenderScreenspaceEffects", "RenderMotionBlur")
		hook.Remove("PostRender", "RenderBloom")
		hook.Remove("PostRender", "RenderMotionBlur")
		hook.Remove("PostRender", "RenderFrameBlend")
	end
	
end)

-- This probably chops off a few FPS (1 to 5) but stops many problems with frame spikes.
--[[hook.Add("Think", "ManualGC", function()
	collectgarbage("step", 192)
end)]]

local lastGC = CurTime()

hook.Add("Think", "ManualGC", function()
    if CurTime() - lastGC >= 5 then
        collectgarbage("step", 1000)
        lastGC = CurTime()
    end
end)