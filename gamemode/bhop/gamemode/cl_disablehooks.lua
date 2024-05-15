function GM:FinishMove()
	return false
end

function GM:Tick()
	return false
end

function GM:Think()
	return false
end

local cmdlist = {
	cl_tfa_fx_impact_ricochet_enabled = { 0, GetConVarNumber },
	mat_bumpmap = { 0, GetConVarNumber },
	--rate = { 100000, GetConVarNumber },
	cl_tfa_fx_impact_ricochet_sparks = { 0, GetConVarNumber },
	cl_tfa_fx_impact_ricochet_sparklife = { 0, GetConVarNumber },
	cl_tfa_fx_gasblur = { 0, GetConVarNumber },
	cl_tfa_fx_muzzlesmoke = { 0, GetConVarNumber },
	cl_tfa_fx_impact_enabled = { 0, GetConVarNumber },
	cl_updaterate = { 30, GetConVarNumber },
	cl_cmdrate = { 30, GetConVarNumber },
	--cl_interp = { 0.01364, GetConVarNumber },
	cl_interpolate = { 0, GetConVarNumber },
	cl_interp_ratio = { 0, GetConVarNumber },
	cl_tfa_legacy_shells = { 1, GetConVarNumber },
	sgm_ignore_warnings = { 1, GetConVarNumber },
	r_shadows = { 0, GetConVarNumber }, 
	r_dynamic = { 0, GetConVarNumber }, 
	r_eyegloss = { 0, GetConVarNumber }, 
	r_eyemove = { 0, GetConVarNumber }, 
	r_flex = { 0, GetConVarNumber },
	r_drawtracers = { 0, GetConVarNumber },
	r_drawdetailprops = { 0, GetConVarNumber },
	r_shadowrendertotexture = { 0, GetConVarNumber }, 
	r_shadowmaxrendered = { 0, GetConVarNumber }, 
	r_drawmodeldecals = { 0, GetConVarNumber }, 
	cl_phys_props_enable = { 0, GetConVarNumber }, 
	cl_phys_props_max = { 0, GetConVarNumber }, 
	cl_threaded_bone_setup = { 1, GetConVarNumber }, 
	cl_threaded_client_leaf_system = { 1, GetConVarNumber }, 
	props_break_max_pieces = { 0, GetConVarNumber }, 
	r_propsmaxdist = { 0, GetConVarNumber }, 
	mat_shadowstate = { 0, GetConVarNumber }, 
	cl_show_splashes = { 0, GetConVarNumber },
	cl_ejectbrass = { 0, GetConVarNumber },
	cl_detailfade = { 800, GetConVarNumber },
	cl_smooth = { 0, GetConVarNumber },
	r_fastzreject = { -1, GetConVarNumber },
	r_decal_cullsize = { 1, GetConVarNumber },
	r_drawflecks = { 0, GetConVarNumber },
	r_lod = { 0, GetConVarNumber },
	cl_playerspraydisable = { 1, GetConVarNumber },
	r_spray_lifetime = { 1, GetConVarNumber },
	cl_lagcompensation = { 0, GetConVarNumber },
	lfs_volume = { 0, GetConVarNumber },

	cl_detaildist = { 0, GetConVarNumber },
	cl_drawmonitors = { 0, GetConVarNumber },
	mat_envmapsize = { 0, GetConVarNumber },
	mat_envmaptgasize = { 0, GetConVarNumber },
	mat_hdr_level = { 0, GetConVarNumber },
	mat_max_worldmesh_vertices = { 512, GetConVarNumber },
	mat_motion_blur_enabled = { 0, GetConVarNumber },
	mat_parallaxmap = { 0, GetConVarNumber },
	mat_reduceparticles = { 1, GetConVarNumber },
	mp_decals = { 1, GetConVarNumber },
	r_waterdrawreflection = { 0, GetConVarNumber },
	m9kgaseffect = { 0, GetConVarNumber },

	-- remove blood
	violence_ablood = { 0, GetConVarNumber },
	violence_hblood = { 0, GetConVarNumber },
	violence_agibs = { 0, GetConVarNumber },
	violence_hgibs = { 0, GetConVarNumber },

	r_threaded_client_shadow_manager = { 1, GetConVarNumber },
	r_threaded_particles = { 1, GetConVarNumber },
	r_threaded_renderables = { 1, GetConVarNumber },
	r_queued_decals = { 1, GetConVarNumber },
	r_queued_ropes = { 1, GetConVarNumber }, 
	r_queued_post_processing = { 1, GetConVarNumber },
	threadpool_affinity = { 4, GetConVarNumber },

	mem_max_heapsize = { 2048, GetConVarNumber },
	mat_queue_mode = { 2, GetConVarNumber },
	host_thread_mode = { 1, GetConVarNumber },

    studio_queue_mode = { 2, GetConVarNumber },
    gmod_mcore_test = { 1, GetConVarNumber },
}

local detours = {}

local function RunCommands()
    for cmd, data in pairs( cmdlist ) do
    	detours[cmd] = data[2](cmd)
    	RunConsoleCommand(cmd, data[1])
    end
end

hook.Add( "ShutDown", "roll back convars", function()
    for cmd, old_value in pairs(detours) do
        RunConsoleCommand(cmd, old_value)
    end
end)

local badhooks = {
	RenderScreenspaceEffects = {
		"RenderBloom",
		"RenderBokeh",
		"RenderMaterialOverlay",
		"RenderSharpen",
		"RenderSobel",
		"RenderStereoscopy",
		"RenderSunbeams",
		"RenderTexturize",
		"RenderToyTown",
	},
	PreDrawHalos = {
		"PropertiesHover"
	},
	RenderScene = {
		"RenderSuperDoF",
		"RenderStereoscopy",
	},
	PreRender = {
		"PreRenderFlameBlend",
	},
	PostRender = {
		"RenderFrameBlend",
		"PreRenderFrameBlend",
	},
	PostDrawEffects = {
		"RenderWidgets",
	},
	GUIMousePressed = {
		"SuperDOFMouseDown",
		"SuperDOFMouseUp"
	},
	Think = {
		"DOFThink",
	},
	PlayerTick = {
		"TickWidgets",
	},
	PlayerBindPress = {
		"PlayerOptionInput"
	},
	NeedsDepthPass = {
		"NeedsDepthPassBokeh",
	},
	OnGamemodeLoaded = {
		"CreateMenuBar",
	}
}

local rents = {
	['env_fire'] = true,
	['trigger_hurt'] = true,
	['prop_physics'] = true,
	['prop_ragdoll'] = true,
	['light'] = true,
	['spotlight_end'] = true,
	['beam'] = true,
	['point_spotlight'] = true,
	['env_sprite'] = true,
	['func_tracktrain'] = true,
	['light_spot'] = true,
	['point_template'] = true
}

for class, _ in pairs(rents) do
	for k, v in pairs(ents.FindByClass(class)) do
		v:Remove()
	end
end

local function RemoveHooks()
	for hook, hooks in pairs(badhooks) do
		for _, name in ipairs(hooks) do
			if isfunction(hook.Remove) then
				hook.Remove(hook, name)
			end
		end
	end
end

hook.Add("InitPostEntity", "InitPostEntity.OptimizeMe", function()
    timer.Simple(1, function()
        RunCommands()
        RemoveHooks()
    end)
end)

local SetFont = surface.SetFont
local GetTextSize = surface.GetTextSize
local font = "TargetID"

local cache = setmetatable({}, {
	__mode = "k"
})

timer.Create("surface.ClearFontCache", 1800, 0, function()
	for i = 1, #cache do
		cache[i] = nil
	end
end)

function surface.SetFont(_font)
	font = _font

	return SetFont(_font)
end

function surface.GetTextSize(text)
	if text == nil or text == "" then return 1, 1 end

	if not cache[font] then
		cache[font] = {}
	end

	if not cache[font][text] then
		local w, h = GetTextSize(text)

		cache[font][text] = {
			w = w,
			h = h
		}

		return w, h
	end

	return cache[font][text].w, cache[font][text].h
end

RunConsoleCommand("r_decals", 10)
RunConsoleCommand("mp_decals", 10)
hook.Add("NeedsDepthPass", "RemoveRenderDepth", function() return false end)

timer.Create("CleanBodys", 60, 0, function()
	RunConsoleCommand("r_cleardecals")

	for _, ent in ipairs(ents.FindByClass("class C_ClientRagdoll")) do
		ent:Remove()
	end

	for _, ent in ipairs(ents.FindByClass("class C_PhysPropClientside")) do
		if not IsValid(ent:GetParent()) then
			ent:Remove()
		end
	end
end)

function render.SupportsHDR()
    return false
end

function render.SupportsPixelShaders_2_0()
    return false
end

function render.SupportsPixelShaders_1_4()
    return false
end

function render.SupportsVertexShaders_2_0()
    return false
end

function render.GetDXLevel()
    return 80
end

function GM:UpdateAnimation() end
function GM:GrabEarAnimation() end
function GM:MouthMoveAnimation() end
function GM:DoAnimationEvent() end
function GM:AdjustMouseSensitivity() end
function GM:CalcViewModelView() end
function GM:PreDrawViewModel() end
function GM:PostDrawViewModel() end
function GM:HUDDrawTargetID() return true end
function GM:Think() return end
function GM:Tick() return end
function GM:PlayerTick() return end
function GM:CanUndo() return end
function GM:PreUndo() return end
function GM:PlayerHurt() return end
function GM:ShowHelp() return end
function GM:EntityEmitSound() return end
function GM:OnAchievementAchieved( ply, achid ) return end
function GM:PostProcessPermitted( str ) return end
function GM:InputMouseApply( cmd, x, y, angle ) return end
function GM:PlayerButtonDown( ply, btn ) return end
function GM:PlayerButtonUp( ply, btn ) return end
function GM:Initialize() return end
function GM:LimitHit( name ) return end
function GM:OnUndo( name, strCustomString ) return end
function GM:OnCleanup( name ) return end
function GM:UnfrozeObjects( num ) return end
function GM:HUDPaint() return true end
function GM:PostRenderVGUI() return end
function GM:DrawPhysgunBeam( ply, weapon, bOn, target, boneid, pos ) return end
function GM:NetworkEntityCreated( ent ) return end
function GM:SpawnMenuEnabled() return end
function GM:SpawnMenuOpen() return end
function GM:SpawnMenuOpened() return end
function GM:SpawnMenuClosed() return end
function GM:SpawnMenuCreated(spawnmenu) return end
function GM:ContextMenuEnabled() return end
function GM:ContextMenuOpen() return end
function GM:ContextMenuOpened() return end
function GM:ContextMenuClosed() return end
function GM:ContextMenuCreated() return end
function GM:GetSpawnmenuTools( name ) return end
function GM:AddSTOOL( category, itemname, text, command, controls, cpanelfunction ) return end
function GM:PreReloadToolsMenu() return end
function GM:AddGamemodeToolMenuTabs() return end
function GM:AddToolMenuTabs() return end
function GM:AddGamemodeToolMenuCategories() return end
function GM:AddToolMenuCategories() return end
function GM:PopulateToolMenu() return end
function GM:PostReloadToolsMenu() return end
function GM:PopulatePropMenu() return end
function GM:ShowTeam() return end
function GM:HideTeam() return end
function GM:Initialize() return end
function GM:InitPostEntity() return end
function GM:Think() return end
function GM:PlayerBindPress( pl, bind, down ) return end
--function GM:HUDShouldDraw( name ) return true end
--function GM:HUDPaintBackground() return true end
--function GM:GUIMouseDoublePressed( mousecode, AimVector ) return true end
function GM:ShutDown() return end
function GM:RenderScreenspaceEffects() return true end
function GM:GetTeamColor( ent ) return end
function GM:GetTeamNumColor( num ) return end
function GM:OnPlayerChat( player, strText, bTeamOnly, bPlayerIsDead ) return end
function GM:OnChatTab( str ) return end
function GM:StartChat( teamsay ) return end
function GM:FinishChat() return end
function GM:ChatTextChanged( text ) return end
function GM:ChatText( playerindex, playername, text, filter ) return end
function GM:PostProcessPermitted( str ) return end
function GM:PostRenderVGUI() return end
function GM:PreRender() return end
function GM:PostRender() return end
function GM:RenderScene( origin, angle, fov ) return end
function GM:CalcVehicleView( Vehicle, ply, view ) return end
function GM:CalcView( ply, origin, angles, fov, znear, zfar ) return end
function GM:ShouldDrawLocalPlayer( ply ) return end
function GM:AdjustMouseSensitivity( fDefault ) return end
function GM:ForceDermaSkin() return end
function GM:PostPlayerDraw( ply ) return end
function GM:PrePlayerDraw( ply ) return end
function GM:GetMotionBlurValues( x, y, fwd, spin ) return end
function GM:InputMouseApply( cmd, x, y, angle ) return end
function GM:OnAchievementAchieved( ply, achid ) return end
function GM:PreDrawSkyBox() return end
function GM:PostDrawSkyBox() return end
function GM:PostDraw2DSkyBox() return end
function GM:PreDrawOpaqueRenderables( bDrawingDepth, bDrawingSkybox ) return end
function GM:PostDrawOpaqueRenderables( bDrawingDepth, bDrawingSkybox ) return end
function GM:PreDrawTranslucentRenderables( bDrawingDepth, bDrawingSkybox ) return end
function GM:PostDrawTranslucentRenderables( bDrawingDepth, bDrawingSkybox ) return end
function GM:CalcViewModelView( Weapon, ViewModel, OldEyePos, OldEyeAng, EyePos, EyeAng ) return end
function GM:PreDrawViewModel( ViewModel, Player, Weapon ) return end
function GM:PostDrawViewModel( ViewModel, Player, Weapon ) return end
function GM:DrawPhysgunBeam( ply, weapon, bOn, target, boneid, pos ) return end
function GM:NetworkEntityCreated( ent ) return end
function GM:CreateMove( cmd ) return end
function GM:PreventScreenClicks( cmd ) return end
function GM:GUIMousePressed( mousecode, AimVector ) return end
function GM:GUIMouseReleased( mousecode, AimVector ) return end
function GM:PlayerClassChanged( ply, newID ) return end
function GM:PreDrawHUD() return end
function GM:PostDrawHUD() return end
function GM:DrawOverlay() return end
function GM:DrawMonitors() return end
function GM:PreDrawEffects() return end
function GM:PostDrawEffects() return end
function GM:PreDrawHalos() return end
function GM:CloseDermaMenus() return end
function GM:CreateClientsideRagdoll( entity, ragdoll ) return end
function GM:VehicleMove( ply, vehicle, mv ) return end

hook.Add("PlayerButtonDown","PlayerButtonDown",function()
	hook.Remove("PlayerButtonDown", "PlayerButtonDown")
end)
hook.Add("PlayerButtonUp","PlayerButtonUp",function()
	hook.Remove("PlayerButtonUp", "PlayerButtonUp")
end)
hook.Add("Think","Think",function()
	hook.Remove("Think", "Think")
end)
hook.Add("Tick","Tick",function()
	hook.Remove("Tick", "Tick")
end)
hook.Add("PlayerTick","PlayerTick",function()
	hook.Remove("PlayerTick", "PlayerTick")
end)
hook.Add("Move","Move",function()
	hook.Remove("Move", "Move")
end)
hook.Add("StartMove","StartMove",function()
	hook.Remove("StartMove", "StartMove")
end)
hook.Add("FinishMove","FinishMove",function()
	hook.Remove("FinishMove", "FinishMove")
end)