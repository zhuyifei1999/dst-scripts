local PopupDialogScreen = require "screens/popupdialog"
local ScriptErrorScreen = require "screens/scripterrorscreen"
local BigPopupDialogScreen = require "screens/bigpopupdialog"
local WorldGenScreen = require "screens/worldgenscreen"

require "scheduler"

SimTearingDown = false
SimShuttingDown = false
PerformingRestart = false

function SavePersistentString(name, data, encode, callback)
	
	if TheFrontEnd then
		TheFrontEnd:ShowSavingIndicator()
		local function cb()
			TheFrontEnd:HideSavingIndicator()
			if callback then
				callback()
			end
		end
		TheSim:SetPersistentString(name, data, encode, cb)
	else
		TheSim:SetPersistentString(name, data, encode, callback)
	end
end

function ErasePersistentString(name, callback)
   
	if TheFrontEnd then
		TheFrontEnd:ShowSavingIndicator()
		local function cb()		
			TheFrontEnd:HideSavingIndicator()
			if callback then
				callback()
			end
		end
		TheSim:ErasePersistentString(name, cb)
	else
		TheSim:ErasePersistentString(name, callback)
	end 
end

function Print( msg_verbosity, ... )
	if msg_verbosity <= VERBOSITY_LEVEL then
		print( ... )
	end
end

function SecondsToTimeString( total_seconds )
	local minutes = math.floor(total_seconds / 60)
	local seconds = math.floor(total_seconds - minutes*60)
	
	if minutes > 0 then
		return string.format("%d:%02d", minutes, seconds )
	else
		if seconds > 9 then
			return string.format("%02d", seconds )
		else
			return string.format("%d", seconds )
		end
	end
end

---PREFABS AND ENTITY INSTANTIATION

local modprefabinitfns = {}
function RegisterPrefabs(...)
    for i, prefab in ipairs({...}) do
        --print ("Register " .. tostring(prefab))
		-- allow mod-relative asset paths
			
		for i,asset in ipairs(prefab.assets) do
			if asset.type ~= "INV_IMAGE" and asset.type ~= "MINIMAP_IMAGE" then
				local resolvedpath = resolvefilepath(asset.file)
				assert(resolvedpath, "Could not find "..asset.file.." required by "..prefab.name)
				TheSim:OnAssetPathResolve(asset.file, resolvedpath)			
				asset.file = resolvedpath
			end
		end
        modprefabinitfns[prefab.name] = ModManager:GetPostInitFns("PrefabPostInit", prefab.name)
        Prefabs[prefab.name] = prefab
        
		TheSim:RegisterPrefab(prefab.name, prefab.assets, prefab.deps)
    end
end

PREFABDEFINITIONS = {}

function LoadPrefabFile( filename )
	--print("Loading prefab file "..filename)
    local fn, r = loadfile(filename)
    assert(fn, "Could not load file ".. filename)
	if type(fn) == "string" then
		assert(false, "Error loading file "..filename.."\n"..fn)
	end
    assert( type(fn) == "function", "Prefab file doesn't return a callable chunk: "..filename)
	local ret = {fn()}

	if ret then
		for i,val in ipairs(ret) do
			if type(val)=="table" and val.is_a and val:is_a(Prefab) then
				RegisterPrefabs(val)
				PREFABDEFINITIONS[val.name] = val
			end
		end
	end

	return ret
end

function RegisterAchievements(achievements)
    for i, achievement in ipairs(achievements) do
        --print ("Registering achievement:", achievement.name, achievement.id.steam, achievement.id.psn)
        TheGameService:RegisterAchievement(achievement.name, achievement.id.steam, achievement.id.psn)        
    end
end

function LoadAchievements( filename )
	--print("Loading achievement file "..filename)
    local fn, r = loadfile(filename)
    assert(fn, "Could not load file ".. filename)
	if type(fn) == "string" then
		assert(false, "Error loading file "..filename.."\n"..fn)
	end
    assert( type(fn) == "function", "Achievements file doesn't return a callable chunk: "..filename)
	local ret = {fn()}

	if ret then
		for i,val in ipairs(ret) do
			if type(val)=="table" then --and val.is_a and val:is_a(Achievements)then
				RegisterAchievements(val)
			end
		end
	end

	return ret
end

function SpawnPrefabFromSim(name)
    name = string.sub(name, string.find(name, "[^/]*$"))      
	name = string.lower(name)
	
    local prefab = Prefabs[name]
	if prefab == nil then
		print( "Can't find prefab " .. tostring(name) )
		return -1
	end

    if prefab then
        local inst = prefab.fn(TheSim)

        if inst ~= nil then

            inst:SetPrefabName(inst.prefab or name)

            local modfns = modprefabinitfns[inst.prefab or name]
            if modfns ~= nil then
                for k,mod in pairs(modfns) do
                    mod(inst)
                end
            end
            if inst.prefab ~= name then
                modfns = modprefabinitfns[name]
                if modfns ~= nil then
                    for k,mod in pairs(modfns) do
                        mod(inst)
                    end
                end
            end

            for k,prefabpostinitany in pairs(ModManager:GetPostInitFns("PrefabPostInitAny")) do
                prefabpostinitany(inst)
            end
            
            return inst.entity:GetGUID()
        else
            print( "Failed to spawn", name )
            return -1
        end
    end
end

function PrefabExists(name)
    return Prefabs[name] ~= nil
end

local renames = 
{
    feather = "feather_crow",
}

function SpawnPrefab(name, skin, skin_id, creator)	
    name = string.sub(name, string.find(name, "[^/]*$"))      
    name = renames[name] or name
    local guid = TheSim:SpawnPrefab(name, skin, skin_id, creator)
    return Ents[guid]
end

function SpawnSaveRecord(saved, newents)
    --print(string.format("~~~~~~~~~~~~~~~~~~~~~SpawnSaveRecord [%s, %s, %s]", tostring(saved.id), tostring(saved.prefab), tostring(saved.data)))
    local inst = SpawnPrefab(saved.prefab, saved.skinname, saved.skin_id)
    
    if inst then
		inst.Transform:SetPosition(saved.x or 0, saved.y or 0, saved.z or 0)
		if not inst.entity:IsValid() then
	        --print(string.format("SpawnSaveRecord [%s, %s] FAILED - entity invalid", tostring(saved.id), saved.prefab))
			return nil
		end

        if newents then
            
            --this is kind of weird, but we can't use non-saved ids because they might collide
            if saved.id  then
				newents[saved.id] = {entity=inst, data=saved.data} 
			else
				newents[inst] = {entity=inst, data=saved.data} 
			end
			
        end

		-- Attach scenario. This is a special component that's added based on save data, not prefab setup.
		if saved.scenario or (saved.data and saved.data.scenariorunner) then
			if inst.components.scenariorunner == nil then
				inst:AddComponent("scenariorunner")
			end
			if saved.scenario then
				inst.components.scenariorunner:SetScript(saved.scenario)
			end
		end
        inst:SetPersistData(saved.data, newents)

    else
        print(string.format("SpawnSaveRecord [%s, %s] FAILED", tostring(saved.id), saved.prefab))
    end

    return inst
end

function CreateEntity()
    local ent = TheSim:CreateEntity()
    local guid = ent:GetGUID()
    local scr = EntityScript(ent)
    Ents[guid] = scr
    NumEnts = NumEnts + 1
    return scr
end


local debug_entity = nil

function OnRemoveEntity(entityguid)
    
    PhysicsCollisionCallbacks[entityguid] = nil

    local ent = Ents[entityguid]
    if ent then
    	
		if debug_entity == ent then
			debug_entity = nil
		end
		
        BrainManager:OnRemoveEntity(ent)
        if PLATFORM ~= "PS4" then
            SGManager:OnRemoveEntity(ent)
        else
		    if ent.sg then
			    -- don't set ent.sg to nil, might still be referenced till end of frame
			    SGManager:RemoveInstance(ent.sg)
		    end
        end

        ent:KillTasks()
        NumEnts = NumEnts - 1
        Ents[entityguid] = nil
        
        if UpdatingEnts[entityguid] then
            UpdatingEnts[entityguid] = nil
            num_updating_ents = num_updating_ents - 1
        end

        if WallUpdatingEnts[entityguid] then
            WallUpdatingEnts[entityguid] = nil
        end
    end
end

function RemoveEntity(guid)
    local inst = Ents[guid]
    if inst then
        inst:Remove()
    end
end

function PushEntityEvent(guid, event, data)
    local inst = Ents[guid]
    if inst then
        inst:PushEvent(event, data)
    end
end

function GetEntityDisplayName(guid)
    local inst = Ents[guid]
    return inst ~= nil and inst:GetDisplayName() or ""
end

------TIME FUNCTIONS

function GetTickTime()
    return TheSim:GetTickTime()
end

local ticktime = GetTickTime()
function GetTime()
    return TheSim:GetTick()*ticktime
end

function GetTick()
    return TheSim:GetTick()
end

function GetTimeReal()
    return TheSim:GetRealTime()
end

---SCRIPTING
local Scripts = {}

function LoadScript(filename)
    if not Scripts[filename] then
        local scriptfn = loadfile("scripts/" .. filename)
    	assert(type(scriptfn) == "function", scriptfn)
        Scripts[filename] = scriptfn()
    end
    return Scripts[filename]
end


function RunScript(filename)
    local fn = LoadScript(filename)
    if fn then
        fn()
    end
end

function GetEntityString(guid)
    local ent = Ents[guid]

    if ent then
        return ent:GetDebugString()
    end

    return ""
end

function GetExtendedDebugString()
	if debug_entity and debug_entity.brain then
		return debug_entity:GetBrainString()
	elseif SOUNDDEBUG_ENABLED then
	    return GetSoundDebugString()
    elseif WORLDSTATEDEBUG_ENABLED then
        return TheWorld and TheWorld.components.worldstate and TheWorld.components.worldstate:Dump()
	end
	return ""
end

function GetDebugString()
 
	local str = {}
	table.insert(str, tostring(scheduler))
	
	if debug_entity then
		table.insert(str, "\n-------DEBUG-ENTITY-----------------------\n")
		table.insert(str, debug_entity.GetDebugString and debug_entity:GetDebugString() or "<no debug string>")
	end
	
    return table.concat(str)
end

function GetDebugEntity()
	return debug_entity
end

function SetDebugEntity(inst)
    if debug_entity ~= nil and debug_entity:IsValid() then
        debug_entity.entity:SetSelected(false)
    end
    if inst ~= nil and inst:IsValid() then
        debug_entity = inst
        inst.entity:SetSelected(true)
    else
        debug_entity = nil
    end
end

function OnEntitySleep(guid)
    local inst = Ents[guid]
    if inst then
        
        if inst.OnEntitySleep then
			inst:OnEntitySleep()
        end
        
        
		inst:StopBrain()        

        if inst.sg then
            SGManager:Hibernate(inst.sg)
        end

		if inst.emitter then
			EmitterManager:Hibernate(inst.emitter)
		end

        for k,v in pairs(inst.components) do
            
            if v.OnEntitySleep then
                v:OnEntitySleep()
            end
        end

    end
end

function OnEntityWake(guid)
    local inst = Ents[guid]
    if inst then
    
        if inst.OnEntityWake then
			inst:OnEntityWake()
        end

        --V2C: Note that if this needs to work properly for networked
        --     entities on clients, then should use the slower check
        --     :HasTag("INLIMBO").  But there should be no networked
        --     entities on clients that can go to sleep.
        if not inst:IsInLimbo() then
			inst:RestartBrain()
			if inst.sg then
	            SGManager:Wake(inst.sg)
			end
		end
		
		if inst.emitter then
			EmitterManager:Wake(inst.emitter)
		end


        for k,v in pairs(inst.components) do
            if v.OnEntityWake then
                v:OnEntityWake()
            end
        end
    end
end

function ReplicateEntity(guid)
    Ents[guid]:ReplicateEntity()
end

------------------------------

function PlayNIS(nisname, lines)
    local nis = require ("nis/"..nisname)
    local inst = CreateEntity()

    inst:AddComponent("nis")
    inst.components.nis:SetName(nisname)
    inst.components.nis:SetInit(nis.init)
    inst.components.nis:SetScript(nis.script)
    inst.components.nis:SetCancel(nis.cancel)
    inst.entity:CallPrefabConstructionComplete()
    inst.components.nis:Play(lines)
    return inst
end



local paused = false
local simpaused = false
local default_time_scale = 1

function IsPaused()
    return paused
end

function IsSimPaused()
    return simpaused
end

global("PlayerPauseCheck")  -- function not defined when this file included

function SetDefaultTimeScale(scale)
	default_time_scale = scale
	if not paused then
		TheSim:SetTimeScale(default_time_scale)
	end
end

function SetSimPause(val)
	simpaused = val
end

function SetPause(val,reason)
    if val ~= paused then
		if val then
			paused = true
			TheMixer:PushMix("pause")
		else
			paused = false
			TheMixer:PopMix("pause")
		end
	end
    if PlayerPauseCheck then   -- probably don't need this check
        PlayerPauseCheck(val, reason)  -- must be done after SetTimeScale
    end
end

--- EXTERNALLY SET GAME SETTINGS ---
Settings = {}
function SetInstanceParameters(settings)
    if settings ~= "" then
        --print("SetInstanceParameters:",settings)
        Settings = json.decode(settings)
    end
end

Purchases = {}
function SetPurchases(purchases)
	if purchases ~= "" then
		Purchases = json.decode(purchases)
	end
end

--isshutdown means players have been cleaned up by OnDespawn()
--and the sim will shutdown after saving
function SaveGame(isshutdown, cb)
    if not TheNet:GetIsServer() then
        print("SaveGame disabled for Clients in Don't Starve Together")
        if cb ~= nil then
            cb(true)
        end
        return
    end

    local save = {}
    save.ents = {}

    --print("Saving...")
    --save the entities
    local nument = 0
    local saved_ents = {}
    local references = {}
    for k, v in pairs(Ents) do
        if v.persists and v.prefab ~= nil and v.Transform ~= nil and v.entity:GetParent() == nil and v:IsValid() then
            local x, y, z = v.Transform:GetWorldPosition()   
            local record, new_references = v:GetSaveRecord()
            record.prefab = nil

            if new_references ~= nil then
                references[v.GUID] = v
                for k1, v1 in pairs(new_references) do
                    references[v1] = v
                end
            end

            saved_ents[v.GUID] = record

            if save.ents[v.prefab] == nil then
                save.ents[v.prefab] = {}
            end
            table.insert(save.ents[v.prefab], record)
            record.prefab = nil
            nument = nument + 1
        end
    end

    --save out the map
    save.map =
    {
        revealed = "",
        tiles = "",
        roads = Roads,
    }

    local new_refs = nil
    local ground = TheWorld
    assert(ground ~= nil, "Cant save world without ground entity")
    if ground ~= nil then
        save.map.prefab = ground.worldprefab
        save.map.tiles = ground.Map:GetStringEncode()
        save.map.nav = ground.Map:GetNavStringEncode()
        save.map.width, save.map.height = ground.Map:GetSize()
        save.map.topology = ground.topology
        save.map.generated = ground.generated
        save.map.persistdata, new_refs = ground:GetPersistData()
        save.meta = ground.meta
        save.map.hideminimap = ground.hideminimap

        if new_refs ~= nil then
            for k, v in pairs(new_refs) do
                references[v] = ground
            end
        end

        local world_network = ground.net
        assert(world_network, "Cant save world without world_network entity")
        if world_network ~= nil then
            save.world_network = {}
            save.world_network.persistdata, new_refs = world_network:GetPersistData()

            if new_refs ~= nil then
                for k, v in pairs(new_refs) do
                    references[v] = world_network
                end
            end
        end
    end

    if not isshutdown and #AllPlayers > 0 then
        save.snapshot = { players = {} }
    end

    for i, player in ipairs(AllPlayers) do
        if player ~= nil then
            if save.snapshot ~= nil then
                table.insert(save.snapshot.players, player.userid)
            end
            SerializeUserSession(player)
        end
    end

    for k, v in pairs(references) do
        if saved_ents[k] ~= nil then
            saved_ents[k].id = k
        else
            print("Missing reference:", v, "->", k, Ents[k])
        end
    end

    save.mods = ModManager:GetModRecords()
    save.super = WasSuUsed()

    assert(save.map, "Map missing from savedata on save")
    assert(save.map.prefab, "Map prefab missing from savedata on save")
    assert(save.map.tiles, "Map tiles missing from savedata on save")
    assert(save.map.width, "Map width missing from savedata on save")
   	assert(save.map.height, "Map height missing from savedata on save")
    --assert(save.map.topology, "Map topology missing from savedata on save")
    assert(save.ents, "Entites missing from savedata on save")
    assert(save.mods, "Mod records missing from savedata on save")

    local PRETTY_PRINT = false
    local data = DataDumper(save, nil, not PRETTY_PRINT)

    local function callback()
        if isshutdown or #AllPlayers <= 0 then
            TheNet:TruncateSnapshots(save.meta.session_identifier)
        end
        TheNet:IncrementSnapshot()
        SaveGameIndex:Save(cb)
    end

    SerializeWorldSession(data, save.meta.session_identifier, callback)
end

function ProcessJsonMessage(message)
    --print("ProcessJsonMessage", message)
	
	local player = ThePlayer
    
    local command = TrackedAssert("ProcessJsonMessage",  json.decode, message) 
    
    -- Sim commands
    if command.sim ~= nil then
		--print( "command.sim: ", command.sim )
    	--print("Sim command", message)
    	if command.sim == 'toggle_pause' then
    		--TheSim:TogglePause()
			SetPause(not IsPaused())
		elseif command.sim == 'upsell_closed' then
			HandleUpsellClose()
		elseif command.sim == 'quit' then
    		if player then
    			player:PushEvent("quit", {})
    		end
    	elseif type(command.sim) == 'table' and command.sim.playerid then
			TheFrontEnd:SendScreenEvent("onsetplayerid", command.sim.playerid)
    	end
    end
end

function LoadFonts()
	for k,v in pairs(FONTS) do
		TheSim:LoadFont(v.filename, v.alias)
	end
end

function UnloadFonts()
	for k,v in pairs(FONTS) do
		TheSim:UnloadFont(v.alias)
	end
end

function Start()
	if SOUNDDEBUG_ENABLED then
		require "debugsounds"
	end

	---The screen manager
	TheFrontEnd = FrontEnd()	
	require ("gamelogic")	
	
    CheckControllers()

end

function CheckControllers()
    local isConnected = TheInput:ControllerConnected()
    local sawPopup = Profile:SawControllerPopup() 
    if isConnected and not sawPopup then
            
        -- store previous controller enabled state so we can revert to it, then enable all controllers
        local controllers = {}
        local numControllers = TheInputProxy:GetInputDeviceCount()        
        for i = 1, (numControllers - 1) do
            local enabled = TheInputProxy:IsInputDeviceEnabled(i)
            table.insert(controllers, enabled)
        end
        
        -- enable all controllers so they can be used in the popup if desired
        Input:EnableAllControllers()
        
        local function enableControllers()          
            -- set all connected controllers as enabled in the player profile
            for i = 1, (numControllers - 1) do
                if TheInputProxy:IsInputDeviceConnected(i) then
                    local guid, data, enabled = TheInputProxy:SaveControls(i)                    
                    if not(nil == guid) and not(nil == data) then
                        Profile:SetControls(guid, data, enabled)
                    end
                end
            end
            
            Profile:ShowedControllerPopup()
            TheFrontEnd:PopScreen() -- pop after updating settings otherwise this dialog might show again!
            Profile:Save()
            scheduler:ExecuteInTime(0.05, function() Check_Mods() end)
        end
                
        local function disableControllers()                    
            Input:DisableAllControllers()
            Profile:ShowedControllerPopup()
            TheFrontEnd:PopScreen() -- pop after updating settings otherwise this dialog might show again!
            Profile:Save()
            scheduler:ExecuteInTime(0.05, function() Check_Mods() end)            
        end
                
        local function revertControllers()                     
            -- restore controller enabled/disabled to previous state
            for i = 1, (numControllers - 1) do
                TheInputProxy:EnableInputDevice(i, controllers[i])
            end
            
            Profile:ShowedControllerPopup()
            TheFrontEnd:PopScreen() -- pop after updating settings otherwise this dialog might show again!
            Profile:Save()
            scheduler:ExecuteInTime(0.05, function() Check_Mods() end)            
        end
        
        local popup = PopupDialogScreen(STRINGS.UI.MAINSCREEN.CONTROLLER_DETECTED_HEADER, STRINGS.UI.MAINSCREEN.CONTROLLER_DETECTED_BODY,
            {
                {text=STRINGS.UI.MAINSCREEN.ENABLECONTROLLER, cb = enableControllers},
                {text=STRINGS.UI.MAINSCREEN.DISABLECONTROLLER, cb = disableControllers}  
            }
        )
        for i,v in pairs(popup.menu.items) do
            v.text:SetSize(33)
        end
        if Input:ControllerAttached() then
            TheFrontEnd:StopTrackingMouse(true)
        end
        TheFrontEnd:PushScreen(popup)
    else
        if Input:ControllerAttached() then
            TheFrontEnd:StopTrackingMouse(true)
        end
        Check_Mods()
    end
end

function Check_Mods()
    if MODS_ENABLED then
        --after starting everything up, give the mods additional environment variables
        ModManager:SetPostEnv(ThePlayer)

	    --By this point the game should have either a) disabled bad mods, or b) be interactive
	    KnownModIndex:EndStartupSequence(nil) -- no callback, this doesn't need to block and we don't need the results
	end

	--If we collected a non-fatal error during startup, display it now!
	for i,err in ipairs(PendingErrors) do
		DisplayError(err)
	end
end

--------------------------

exiting_game = false

-- Gets called ONCE when the sim first gets created. Does not get called on subsequent sim recreations!
function GlobalInit()
	TheSim:LoadPrefabs({"global"})
	LoadFonts()
	if PLATFORM == "PS4" then
		PreloadSounds()
	end
	--TheSim:SendHardwareStats()
	FirstStartupForNetworking = true
end

-- This is for joining a game: once we're done downloading the map, we load it and simreset
function LoadMapFile(map_name)
    if InGamePlay() then
        -- Must be a synchronous load if we're in any game play state (including lobby screen)
        DisableAllDLC()
        StartNextInstance({ reset_action = RESET_ACTION.LOAD_FILE, save_name = map_name })
        return
    end

    local screen = TheFrontEnd:GetActiveScreen()
    while screen ~= nil and not (screen.bg ~= nil and screen.bg.anim_root ~= nil and screen.bg.anim_root.portal ~= nil) do
        -- Check if we're on a screen with a portal anim
        -- If we're not, then pop the current screen and try again with the next screen down
        TheFrontEnd:PopScreen()
        screen = TheFrontEnd:GetActiveScreen()
    end

    if screen == nil then
        -- If there are no more screens, just do a generic fade
        TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
            DisableAllDLC()
            StartNextInstance({ reset_action = RESET_ACTION.LOAD_FILE, save_name = map_name })
        end, nil, nil, "white")
        return
    end

    -- If we have access to a portal, then start the animation fanciness!
    TheFrontEnd:Fade(true, SCREEN_FADE_TIME * 4, nil, nil, nil, "alpha")

    screen:Disable()
    screen.inst:DoTaskInTime(SCREEN_FADE_TIME, function(inst)
        screen.bg.anim_root.portal:GetAnimState():PlayAnimation("portal_blackout", false)
        TheFrontEnd:GetSound():PlaySound("dontstarve/together_FE/portal_flash")

        inst:DoTaskInTime(1.5, function() 
            TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
                DisableAllDLC()
                StartNextInstance({ reset_action = RESET_ACTION.LOAD_FILE, save_name = map_name })
            end, nil, nil, "white")
        end)
    end)
end

function JapaneseOnPS4()
	if PLATFORM=="PS4" and APP_REGION == "SCEJ" then
		return true
	end
	return false
end

function StartNextInstance(in_params, send_stats)

	if TheNet:GetIsServer() then
		NotifyLoadingState( LoadingStates.Loading )
	end
	
	local params = in_params or {}
	params.last_reset_action = Settings.reset_action

    params.load_screen_image = global_loading_widget.image_random

	if send_stats then
		SendAccumulatedProfileStats()
	end
				
	if LOADED_CHARACTER then 
		for i, v in ipairs(AllPlayers) do
			if v and v.components.talker then -- Make sure talker shuts down before we unload the character
				v.components.talker:ShutUp()
			end
		end
		TheSim:UnloadPrefabs(LOADED_CHARACTER) 
		LOADED_CHARACTER = nil
	end
	
	SimReset(params)
end

function ForceAssetReset()
	Settings.current_asset_set = "FORCERESET"
end

function SimReset(instanceparameters)
	SimTearingDown = true
	
	ModManager:UnloadPrefabs()

	if not instanceparameters then
		instanceparameters = {}
	end
	instanceparameters.last_asset_set = Settings.current_asset_set
	local params = json.encode(instanceparameters)
	TheSim:SetInstanceParameters(params)
	TheSim:Reset()
end

function RequestShutdown()
	if exiting_game then
		return
	end
	exiting_game = true
	
    if (not TheNet:GetServerIsDedicated()) then
	    TheFrontEnd:PushScreen(
	        PopupDialogScreen( STRINGS.UI.QUITTINGTITLE, STRINGS.UI.QUITTING,
	    	  {  }
	    	)
	    )
	end
	
	-----------------------------------------------------------------------------	
	-- Anything below here may not run if we don't have stats that need updating
	-----------------------------------------------------------------------------
	
	local stats = GetProfileStats(true)
	if string.len(stats) <= 12 then -- empty stats are '{"stats":[]}'
		Shutdown()
		return
	end

	SubmitExitStats()
end

function Shutdown()

    SimShuttingDown = true

	for i, v in ipairs(AllPlayers) do
		if v and v.components.talker then -- Make sure talker shuts down before we unload the character
		    print("Shutdown: shutting up talker")
			v.components.talker:ShutUp()
		end
	end

	Print(VERBOSITY.DEBUG, 'Ending the sim now!')
	SubmitQuitStats()
	
	UnloadFonts()

	-- warning, we don't want to run much code here. We're in a strange mix of loaded assets and mapped paths
	-- as a bonus, the fonts are unloaded, so no asserting...	
	TheSim:UnloadAllPrefabs()
	ModManager:UnloadPrefabs()
	
	TheSim:Quit()
end

PendingErrors = {}

function DisplayError(error)
	if not TheFrontEnd then
		print("Error error! We tried displaying an error but TheFrontEnd isn't ready yet...")
		table.insert(PendingErrors, error)
		return
	end

    SetPause(true,"DisplayError")
    if TheFrontEnd:IsDisplayingError() then
        return nil
    end

	print (error) -- Failsafe since sometimes the error screen is no shown

    local modnames = ModManager:GetEnabledModNames()

    if #modnames > 0 then
        local modnamesstr = ""
        for k,modname in ipairs(modnames) do
            modnamesstr = modnamesstr.."\""..KnownModIndex:GetModFancyName(modname).."\" "
        end

        TheFrontEnd:DisplayError(
            ScriptErrorScreen(
                STRINGS.UI.MAINSCREEN.MODFAILTITLE, 
                error,
                {
                    {text=STRINGS.UI.MAINSCREEN.SCRIPTERRORQUIT, cb = function() TheSim:ForceAbort() end},
					{text=STRINGS.UI.MAINSCREEN.MODQUIT, cb = function()
																	KnownModIndex:DisableAllMods()
																	ForceAssetReset()
																	KnownModIndex:Save(function()
																		SimReset()
																	end)
																end},
                    {text=STRINGS.UI.MAINSCREEN.MODFORUMS, nopop=true, cb = function() VisitURL("http://forums.kleientertainment.com/index.php?/forum/26-dont-starve-mods-and-tools/") end }
                },
                ANCHOR_LEFT,
                STRINGS.UI.MAINSCREEN.SCRIPTERRORMODWARNING..modnamesstr,
                20
                ))
    else
        TheFrontEnd:DisplayError(
            ScriptErrorScreen(
                STRINGS.UI.MAINSCREEN.MODFAILTITLE, 
                error,
                {
                    {text=STRINGS.UI.MAINSCREEN.SCRIPTERRORQUIT, cb = function() TheSim:ForceAbort() end},
                    {text=STRINGS.UI.MAINSCREEN.FORUM, nopop=true, cb = function() VisitURL("http://forums.kleientertainment.com/index.php?/forum/26-dont-starve-mods-and-tools/") end }
                },
                ANCHOR_LEFT,
                nil,
                20
                ))
    end
end

function SetPauseFromCode(pause)
    if pause then
        if inGamePlay and not IsPaused() then
			local PauseScreen = require "screens/pausescreen"
            TheFrontEnd:PushScreen(PauseScreen())
        end
    end
end

function InGamePlay()
	return inGamePlay
end

function IsMigrating()
    --Right now the only way to really tell if we are migrating is if we are neither in FE or in gameplay, which results in no screen...
    --      e.g. if there is no active screen
    --THIS SHOULD BE IMPROVED YARK YARK YARK
    return TheFrontEnd:GetActiveScreen() == nil
end

--DoRestart helper
local function postsavefn()
    TheNet:Disconnect(true)
    EnableAllMenuDLC()
    StartNextInstance()
    inGamePlay = false
    PerformingRestart = false
end

--DoRestart helper
local function savefn()
    if TheWorld == nil then
        postsavefn()
    elseif TheWorld.ismastersim then
        for i, v in ipairs(AllPlayers) do
            v:OnDespawn()
        end
        TheSystemService:EnableStorage(true)
        SaveGameIndex:SaveCurrent(postsavefn, true)
    else
        SerializeUserSession(ThePlayer)
        postsavefn()
    end
end

function DoRestart(save)
    print("DoRestart:", save)
    if not PerformingRestart then
        PerformingRestart = true
        ShowLoading()
        TheFrontEnd:Fade(false, 1, save and savefn or postsavefn)
    end
end

local screen_fade_time = .25

function OnPlayerLeave(player_guid, expected)
    if TheWorld.ismastersim and player_guid ~= nil then
		local player = Ents[player_guid]
		if player ~= nil then
            --V2C: #spawn #despawn
            --     This was where we used to announce player left.
            --     Now we announce it when you actually disconnect
            --     but not during a shard migration disconnection.
			--TheNet:Announce(player:GetDisplayName().." "..STRINGS.UI.NOTIFICATION.LEFTGAME, player.entity, true, "leave_game")

            --Save must happen when the player is actually removed
            --This is currently handled in playerspawner listening to ms_playerdespawn
            TheWorld:PushEvent("ms_playerdisconnected", {player=player, wasExpected=expected})
            TheWorld:PushEvent("ms_playerdespawn", player)
		end
	end
end

-- Receive a message that does not disconnect the user
function OnPushPopupDialog( message )
	local title = STRINGS.UI.POPUPDIALOG.TITLE[message] or STRINGS.UI.POPUPDIALOG.TITLE.DEFAULT 
	message = STRINGS.UI.POPUPDIALOG.BODY[message] or STRINGS.UI.POPUPDIALOG.BODY.DEFAULT
	
	local function doclose( )
		TheFrontEnd:PopScreen( )
	end
		    
	TheFrontEnd:PushScreen( PopupDialogScreen(title, message, { {text=STRINGS.UI.POPUPDIALOG.OK, cb = function() doclose( ) end}  }) )
	local screen = TheFrontEnd:GetActiveScreen()
	if screen then
		screen:Enable()
	end
end

-- Receive a disconnect notification
function OnNetworkDisconnect( message, should_reset, force_immediate_reset, details )
	-- The client has requested we immediately close this connection
	if force_immediate_reset == true then
	    DoRestart(true)
	    return
	end

    local screen = TheFrontEnd:GetActiveScreen()
    if screen and screen.name == "ConnectingToGamePopup" then
        TheFrontEnd:PopScreen()
    end
	
	--If we plan to serialize a user session, we should do it now.  It will be too late later.
	if ThePlayer ~= nil then
		SerializeUserSession(ThePlayer)
	end

    --Don't need to reset if we're in FE already
    --NOTE: due to migration, we can be in neither gameplay nor FE
    --      INVALID_CLIENT_TOKEN is a special case; we want to
    --      boot the user back to the main menu even if they're in the FE
    should_reset = should_reset and (InGamePlay() or IsMigrating() or message == "INVALID_CLIENT_TOKEN")
	local function doquit( should_reset )
		if should_reset == true then
			DoRestart(false) --don't save again
		else
		    TheNet:Disconnect(false)
		    TheFrontEnd:PopScreen()
		    -- Make sure we try to enable the screen behind this
		    local screen = TheFrontEnd:GetActiveScreen()
		    if screen then
		    	screen:Enable()
		    end
		end	
	end

	local title = STRINGS.UI.NETWORKDISCONNECT.TITLE[message] or STRINGS.UI.NETWORKDISCONNECT.TITLE.DEFAULT 
	message = STRINGS.UI.NETWORKDISCONNECT.BODY[message] or STRINGS.UI.NETWORKDISCONNECT.BODY.DEFAULT
	
	-- Append details to this message
	if details ~= nil and details ~= "" then
		message = message .. "\nReason: " .. details
	end

	if TheFrontEnd:GetFadeLevel() > 0 then --we're already fading
		if TheFrontEnd.fadedir == false then
			local cb = TheFrontEnd.fadecb
			TheFrontEnd.fadecb = function()
				if cb then cb() end
				TheFrontEnd:PushScreen( PopupDialogScreen(title, message, { {text=STRINGS.UI.NETWORKDISCONNECT.OK, cb = function() doquit( should_reset ) end}  }) )
				local screen = TheFrontEnd:GetActiveScreen()
			    if screen then
			    	screen:Enable()
			    end
		    	TheFrontEnd:Fade(true, screen_fade_time)
			end
		else
			TheFrontEnd:PushScreen( PopupDialogScreen(title, message, { {text=STRINGS.UI.NETWORKDISCONNECT.OK, cb = function() doquit( should_reset ) end}  }) )
			local screen = TheFrontEnd:GetActiveScreen()
		    if screen then
		    	screen:Enable()
		    end
		    TheFrontEnd:Fade(true, screen_fade_time)
		end
	else
		-- TheFrontEnd:Fade(false, screen_fade_time, function()
	        TheFrontEnd:PushScreen( PopupDialogScreen(title, message, { {text=STRINGS.UI.NETWORKDISCONNECT.OK, cb = function() doquit( should_reset ) end}  }) )
	        local screen = TheFrontEnd:GetActiveScreen()
		    if screen then
		    	screen:Enable()
		    end
	        -- TheFrontEnd:Fade(true, screen_fade_time)
	    -- end)
	end
	return true
end

OnAccountEventListeners = {}

function RegisterOnAccountEventListener( listener )
	table.insert( OnAccountEventListeners, listener )
end

function RemoveOnAccountEventListener( listener_to_remove )
	local index = 1
	for k,listener in pairs(OnAccountEventListeners) do
		if listener == listener_to_remove then
			table.remove( OnAccountEventListeners, index )
			break
		end
		index = index + 1
	end
end

function OnAccountEvent( success, event_code, custom_message )
	for k,listener in pairs(OnAccountEventListeners) do
		if listener ~= nil then
			listener:OnAccountEvent( success, event_code, custom_message )
		end
	end
end

function TintBackground( bg )
    --if IsDLCEnabled(REIGN_OF_GIANTS) then
    --    bg:SetTint(unpack(BGCOLOURS.PURPLE))
    --else
        -- bg:SetTint(unpack(BGCOLOURS.GREY))
        bg:SetTint(unpack(BGCOLOURS.FULL))
    --end
end

-- Global for saving game on Android focus lost event
function OnFocusLost()
	--check that we are in gameplay, not main menu
	if PLATFORM == "ANDROID" and inGamePlay then
		SetPause(true)
		SaveGameIndex:SaveCurrent()
	end
end

function OnFocusGained()
	--check that we are in gameplay, not main menu
	if inGamePlay then
		if PLATFORM == "ANDROID" then
			SetPause(false)
		end
	end
end

local function OnUserPickedCharacter(char, skin_base, clothing_body, clothing_hand, clothing_legs)
    local function doSpawn()
        TheFrontEnd:PopScreen()
        TheNet:SendSpawnRequestToServer(char, skin_base, clothing_body, clothing_hand, clothing_legs)
    end

    TheFrontEnd:Fade(false, 1, doSpawn, nil, nil, "white")
end
-- TEMP DEBUG DIABU
Debug_Select = OnUserPickedCharacter

Debug_DieRevive = function()
    ConsoleCommandPlayer().components.health:SetPercent(0)
    ConsoleCommandPlayer():DoTaskInTime(2, function()
        ConsoleCommandPlayer():PushEvent("respawnfromghost")
        ConsoleCommandPlayer().components.hunger:SetPercent(1)
        ConsoleCommandPlayer().components.health:SetPercent(1)
        ConsoleCommandPlayer().components.sanity:SetPercent(1)
    end)
end


-- 

function ResumeRequestLoadComplete(success)
    --If successful then don't do anything, game will automatically
    --activate and fade in once the user's player is downloaded
    if not success then
        TheNet:DeleteUserSession(TheNet:GetUserID())
        local LobbyScreen = require "screens/lobbyscreen" 
        TheFrontEnd:PushScreen(LobbyScreen(Profile, OnUserPickedCharacter, false))
        TheFrontEnd:Fade(true, 1, nil, nil, nil, "white")
        TheWorld:PushEvent("entercharacterselect")
    end
end

--data is raw string data from save file
function ParseUserSessionData(data)
    local success, playerdata = RunInSandboxSafe(data)
    if success then
        --Here we can do some validation on data and/or prefab if we want
        --e.g. Resuming a mod character without the mod loaded?
        return playerdata, playerdata.prefab
    end
    return nil, ""
end

--data is lua table
function ResumeExistingUserSession(data, guid)
	if TheNet:GetIsServer() then
		local player = Ents[guid]
		if player ~= nil then
			player:SetPersistData( data.data or {} )

			-- Spawn the player to last known location
			TheWorld.components.playerspawner:SpawnAtLocation(TheWorld, player, data.x or 0, data.y or 0, data.z or 0, true)
		end
	end
end

function RestoreSnapshotUserSession(sessionid, userid)
    local file = TheNet:GetUserSessionFile(sessionid, userid)
    if file ~= nil then
        print("Restoring user session from "..file)
        TheSim:GetPersistentString(file, function(success, str)
            if success and str ~= nil and #str > 0 then
                local playerdata, prefab = ParseUserSessionData(str)
                if playerdata ~= nil and GetTableSize(playerdata) > 0 and prefab ~= nil and prefab ~= "" then
                    local player = SpawnPrefab(prefab)
                    if player ~= nil then
                        player.userid = userid
                        player:SetPersistData(playerdata.data or {})
                        player.Physics:Teleport(playerdata.x or 0, playerdata.y or 0, playerdata.z or 0)
                    end
                end
            end
        end)
    end
end

-- Execute arbitrary lua
function ExecuteConsoleCommand(fnstr, guid, x, z)
    local saved_ThePlayer
    if guid ~= nil then
        saved_ThePlayer = ThePlayer
        ThePlayer = guid ~= nil and Ents[guid] or nil
    end
    TheInput.overridepos = x ~= nil and z ~= nil and Vector3(x, 0, z) or nil

	local status, r = pcall(loadstring(fnstr))
	if not status then
		nolineprint(r)
	end

    if guid ~= nil then
        ThePlayer = saved_ThePlayer
    end
    TheInput.overridepos = nil
end

LoadingStates = { 
		None = 0,
		Loading = 1,
		Generating = 2,
		DoneGenerating = 3,
		DoneLoading = 4
	}
				
function NotifyLoadingState( loading_state )
	if TheNet:GetIsClient() then
		if loading_state == LoadingStates.Loading then
			ShowLoading()
			TheFrontEnd:Fade(false, 1)
		elseif loading_state == LoadingStates.Generating then
			local inst = CreateEntity()
			inst:DoTaskInTime(0.15, function(inst) TheFrontEnd:PopScreen() TheFrontEnd:PushScreen(WorldGenScreen(nil, nil, nil)) inst.entity:Retire() end)
		elseif loading_state == LoadingStates.DoneGenerating then
			TheFrontEnd:PopScreen()		
		end
	elseif TheNet:GetIsServer() then
		TheNet:NotifyLoadingState( loading_state )
	end
end


function BuildTagsStringCommon(tagsTable)
    -- Mods tags
    for i,mod_tag in pairs( KnownModIndex:GetEnabledModTags() ) do
        table.insert(tagsTable, mod_tag)
    end
    -- Vote command tags
    if TheSim:GetSetting("misc", "vote_kick_enabled") == "true" then
		table.insert(tagsTable, "vote kick")
    end
    
    -- Concat & return the string
    return table.concat(tagsTable, ", ")
end

require("dlcsupport")
