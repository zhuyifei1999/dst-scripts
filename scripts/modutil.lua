
function ModInfoname(name)
	local prettyname = KnownModIndex:GetModFancyName(name)
	if prettyname == name then
		return name
	else
		return name.." ("..prettyname..")"
	end
end

-- This isn't for modders to use: see environment version added in InsertPostInitFunctions
function GetModConfigData(optionname, modname, get_local_config)
	assert(modname, "modname must be supplied manually if calling GetModConfigData from outside of modmain or modworldgenmain. Use ModIndex:GetModActualName(fancyname) function [fancyname is name string from modinfo].")
	local force_local_options = false
	if get_local_config ~= nil then force_local_options = get_local_config end
	local config, temp_options = KnownModIndex:GetModConfigurationOptions(modname, force_local_options)
	if config and type(config) == "table" then
		if temp_options then
			return config[optionname]
		else
			for i,v in pairs(config) do
				if v.name == optionname then
					if v.saved ~= nil then
						return v.saved 
					else 
						return v.default
					end
				end
			end
		end
	end
	return nil
end

local function AddModCharacter(name, gender)
    table.insert(MODCHARACTERLIST, name)
    if gender == nil then
		print( "Warning: Mod Character " .. name .. " does not currently specify a gender. Please update the call to AddModCharacter to include a gender. \"FEMALE\", \"MALE\", \"ROBOT\", or \"NEUTRAL\", or \"PLURAL\" " )
		gender = "NEUTRAL"
    end
    gender = gender:upper()
    if not CHARACTER_GENDERS[gender] then
		CHARACTER_GENDERS[gender] = {}
    end
    table.insert( CHARACTER_GENDERS[gender], name )
end

local function initprint(...)
	if KnownModIndex:IsModInitPrintEnabled() then
		local modname = getfenv(3).modname
		print(ModInfoname(modname), ...)
	end
end

-- Based on @no_signal's AddWidgetPostInit :)
local function DoAddClassPostConstruct(classdef, postfn)
	local constructor = classdef._ctor
	classdef._ctor = function (self, ...)
		constructor(self, ...)
		postfn(self, ...)
	end
	local mt = getmetatable(classdef)
	mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj, classdef)
        if classdef._ctor then
            classdef._ctor(obj, ...)
        end
        return obj
    end
end

local function AddClassPostConstruct(package, postfn)
	local classdef = require(package)
	assert(type(classdef) == "table", "Class file path '"..package.."' doesn't seem to return a valid class.")
	DoAddClassPostConstruct(classdef, postfn)
end

local function AddGlobalClassPostConstruct(package, classname, postfn)
	require(package)
	local classdef = rawget(_G, classname)
	if classdef == nil then
		classdef = require(package)
	end

	assert(type(classdef) == "table", "Class '"..classname.."' wasn't loaded to global from '"..package.."'.")
	DoAddClassPostConstruct(classdef, postfn)
end

local function InsertPostInitFunctions(env, isworldgen)


	env.postinitfns = {}
	env.postinitdata = {}

	env.postinitfns.LevelPreInit = {}
	env.AddLevelPreInit = function(levelid, fn)
		initprint("AddLevelPreInit", levelid)
		if env.postinitfns.LevelPreInit[levelid] == nil then
			env.postinitfns.LevelPreInit[levelid] = {}
		end
		table.insert(env.postinitfns.LevelPreInit[levelid], fn)
	end
	env.postinitfns.LevelPreInitAny = {}
	env.AddLevelPreInitAny = function(fn)
		initprint("AddLevelPreInitAny")
		table.insert(env.postinitfns.LevelPreInitAny, fn)
	end
	env.postinitfns.TaskPreInit = {}
	env.AddTaskPreInit = function(taskname, fn)
		initprint("AddTaskPreInit", taskname)
		if env.postinitfns.TaskPreInit[taskname] == nil then
			env.postinitfns.TaskPreInit[taskname] = {}
		end
		table.insert(env.postinitfns.TaskPreInit[taskname], fn)
	end
	env.postinitfns.RoomPreInit = {}
	env.AddRoomPreInit = function(roomname, fn)
		initprint("AddRoomPreInit", roomname)
		if env.postinitfns.RoomPreInit[roomname] == nil then
			env.postinitfns.RoomPreInit[roomname] = {}
		end
		table.insert(env.postinitfns.RoomPreInit[roomname], fn)
	end

	env.AddLevel = function(...)
		arg = {...}
		initprint("AddLevel", arg[1], arg[2].id)
		require("map/levels")
		AddLevel(...)
	end
	env.AddTask = function(...)
		arg = {...}
		initprint("AddTask", arg[1])
		require("map/tasks")
		AddTask(...)
	end
	env.AddRoom = function(...)
		arg = {...}
		initprint("AddRoom", arg[1])
		require("map/rooms")
		AddRoom(...)
	end

	env.AddGameMode = function(game_mode, game_mode_text)
		initprint("AddGameMode", game_mode, game_mode_text)
		require("gamemodes")
		return AddGameMode(game_mode, game_mode_text)
	end

	env.GetModConfigData = function( optionname, get_local_config )
		initprint("GetModConfigData", optionname, get_local_config)
		return GetModConfigData(optionname, env.modname, get_local_config)
	end

	env.postinitfns.GamePostInit = {}
	env.AddGamePostInit = function(fn)
		initprint("AddGamePostInit")
		table.insert(env.postinitfns.GamePostInit, fn)
	end

	env.postinitfns.SimPostInit = {}
	env.AddSimPostInit = function(fn)
		initprint("AddSimPostInit")
		table.insert(env.postinitfns.SimPostInit, fn)
	end

	env.AddGlobalClassPostConstruct = function(package, classname, fn)
		initprint("AddGlobalClassPostConstruct", package, classname)
		AddGlobalClassPostConstruct(package, classname, fn)
	end

	env.AddClassPostConstruct = function(package, fn)
		initprint("AddClassPostConstruct", package)
		AddClassPostConstruct(package, fn)
	end


	------------------------------------------------------------------------------
	-- Everything above this point is available in Worldgen or Main.
	-- Everything below is ONLY available in Main.
	-- This allows us to provide easy access to game-time data without
	-- breaking worldgen.
	------------------------------------------------------------------------------
	if isworldgen then
		return
	end
	------------------------------------------------------------------------------


	env.AddAction = function( id, str, fn )
		local action
        if type(id) == "table" and id.is_a and id:is_a(Action) then
			--backwards compatibility with old AddAction
            action = id
        else
			assert( str ~= nil and type(str) == "string", "Must specify a string for your custom action! Example: \"Perform My Action\"")
			assert( fn ~= nil and type(fn) == "function", "Must specify a fn for your custom action! Example: \"function(act) --[[your action code]] end\"")
			action = Action()
			action.id = id
			action.str = str
			action.fn = fn
		end
		action.mod_name = env.modname

		assert( action.id ~= nil and type(action.id) == "string", "Must specify an ID for your custom action! Example: \"MYACTION\"")			

		initprint("AddAction", action.id)
		ACTIONS[action.id] = action

		--put it's mapping into a different IDS table, one for each mod
		if ACTION_MOD_IDS[action.mod_name] == nil then
			ACTION_MOD_IDS[action.mod_name] = {}
		end
		table.insert(ACTION_MOD_IDS[action.mod_name], action.id)
		ACTIONS[action.id].code = #ACTION_MOD_IDS[action.mod_name]

		STRINGS.ACTIONS[action.id] = action.str
		
		return ACTIONS[action.id]
	end

	env.AddComponentAction = function(actiontype, component, fn)
		-- just past this along to the global function
		AddComponentAction(actiontype, component, fn, env.modname)
	end

	env.postinitdata.MinimapAtlases = {}
	env.AddMinimapAtlas = function( atlaspath )
		initprint("AddMinimapAtlas", atlaspath)
		table.insert(env.postinitdata.MinimapAtlases, atlaspath)
	end

	env.postinitdata.StategraphActionHandler = {}
	env.AddStategraphActionHandler = function(stategraph, handler)
		initprint("AddStategraphActionHandler", stategraph)
		if not env.postinitdata.StategraphActionHandler[stategraph] then
			env.postinitdata.StategraphActionHandler[stategraph] = {}
		end
		table.insert(env.postinitdata.StategraphActionHandler[stategraph], handler)
	end

	env.postinitdata.StategraphState = {}
	env.AddStategraphState = function(stategraph, state)
		initprint("AddStategraphState", stategraph)
		if not env.postinitdata.StategraphState[stategraph] then
			env.postinitdata.StategraphState[stategraph] = {}
		end
		table.insert(env.postinitdata.StategraphState[stategraph], state)
	end

	env.postinitdata.StategraphEvent = {}
	env.AddStategraphEvent = function(stategraph, event)
		initprint("AddStategraphEvent", stategraph)
		if not env.postinitdata.StategraphEvent[stategraph] then
			env.postinitdata.StategraphEvent[stategraph] = {}
		end
		table.insert(env.postinitdata.StategraphEvent[stategraph], event)
	end

	env.postinitfns.StategraphPostInit = {}
	env.AddStategraphPostInit = function(stategraph, fn)
		initprint("AddStategraphPostInit", stategraph)
		if env.postinitfns.StategraphPostInit[stategraph] == nil then
			env.postinitfns.StategraphPostInit[stategraph] = {}
		end
		table.insert(env.postinitfns.StategraphPostInit[stategraph], fn)
	end


	env.postinitfns.ComponentPostInit = {}
	env.AddComponentPostInit = function(component, fn)
		initprint("AddComponentPostInit", component)
		if env.postinitfns.ComponentPostInit[component] == nil then
			env.postinitfns.ComponentPostInit[component] = {}
		end
		table.insert(env.postinitfns.ComponentPostInit[component], fn)
	end

	-- You can use this as a post init for any prefab. If you add a global prefab post init function, it will get called on every prefab that spawns.
	-- This is powerful but also be sure to check that you're dealing with the appropriate type of prefab before doing anything intensive, or else
	-- you might hit some performance issues. The next function down, player post init, is both itself useful and a good example of how you might
	-- want to write your global prefab post init functions.
	env.postinitfns.PrefabPostInitAny = {}
	env.AddPrefabPostInitAny = function(fn)
		initprint("AddPrefabPostInitAny")
		table.insert(env.postinitfns.PrefabPostInitAny, fn)
	end

	-- An illustrative example of how to use a global prefab post init, in this case, we're making a player prefab post init.
	env.AddPlayerPostInit = function(fn)
		env.AddPrefabPostInitAny( function(inst)
			if inst and inst:HasTag("player") then fn(inst) end
		end)
	end

	env.postinitfns.PrefabPostInit = {}
	env.AddPrefabPostInit = function(prefab, fn)
		initprint("AddPrefabPostInit", prefab)
		if env.postinitfns.PrefabPostInit[prefab] == nil then
			env.postinitfns.PrefabPostInit[prefab] = {}
		end
		table.insert(env.postinitfns.PrefabPostInit[prefab], fn)
	end

	-- the non-standard ones

	env.AddBrainPostInit = function(brain, fn)
		initprint("AddBrainPostInit", brain)
		local brainclass = require("brains/"..brain)
		if brainclass.modpostinitfns == nil then
			brainclass.modpostinitfns = {}
		end
		table.insert(brainclass.modpostinitfns, fn)
	end

	env.AddIngredientValues = function(names, tags, cancook, candry)
		require("cooking")
		initprint("AddIngredientValues", table.concat(names, ", "))
		AddIngredientValues(names, tags, cancook, candry)
	end

	env.cookerrecipes = {}
	env.AddCookerRecipe = function(cooker, recipe)
		require("cooking")
		initprint("AddCookerRecipe", cooker, recipe.name)
		AddCookerRecipe(cooker, recipe)
		if env.cookerrecipes[cooker] == nil then
	        env.cookerrecipes[cooker] = {}
	    end
	    if recipe.name then
	        table.insert(env.cookerrecipes[cooker], recipe.name)
	    end
	end

	env.AddModCharacter = function(name, gender)
		initprint("AddModCharacter", name, gender)
		AddModCharacter(name, gender)
	end

	env.AddRecipe = function(...)
		arg = {...}
		initprint("AddRecipe", arg[1])
		require("recipe")
		mod_protect_Recipe = false
		local rec = Recipe(...)
		mod_protect_Recipe = true
		rec:SetModRPCID()
		return rec
	end
	
	env.Recipe = function(...)
		print("Warning: function Recipe in modmain is deprecated, please use AddRecipe")
		return env.AddRecipe(...)
	end

	env.Prefab = Prefab

	env.Asset = Asset

	env.Ingredient = Ingredient

	env.LoadPOFile = function(path, lang)
		initprint("LoadPOFile", lang)
		require("translator")
		LanguageTranslator:LoadPOFile(path, lang)
	end

	env.RemapSoundEvent = function(name, new_name)
		initprint("RemapSoundEvent", name, new_name)
		TheSim:RemapSoundEvent(name, new_name)
	end

	env.AddReplicableComponent = function(name)
		initprint("AddReplicableComponent", name)
		AddReplicableComponent(name)
	end

	env.AddModRPCHandler = function(namespace, name, fn)
		initprint("AddModRPCHandler", namespace, name)
		AddModRPCHandler(namespace, name, fn)
	end

	env.SendModRPCToServer = function(id_table)
		initprint("SendModRPCToServer", id_table.namespace, id_table.id)
		SendModRPCToServer(id_table)
	end

	env.MOD_RPC = MOD_RPC

    env.SetModHUDFocus = function(focusid, hasfocus)
        initprint("SetModHUDFocus", focusid, hasfocus)
        if ThePlayer == nil or ThePlayer.HUD == nil then
            print("WARNING: SetModHUDFocus called when there is no active player HUD")
        end
        ThePlayer.HUD:SetModFocus(env.modname, focusid, hasfocus)
    end    
end

return {
			InsertPostInitFunctions = InsertPostInitFunctions,
		}
