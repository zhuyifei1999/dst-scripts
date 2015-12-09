require "class"
require "modutil"
require "prefabs"
local ModWarningScreen = require "screens/modwarningscreen"

MOD_API_VERSION = 10


MOD_AVATAR_LOCATIONS = { Default = "images/avatars/" }
--Add your avatar atlas locations for each prefab if you don't want to use the default mod avatar location


function AreServerModsEnabled()
	if ModManager == nil then
		print("AreServerModsEnabled returning false because ModManager hasn't been created yet.")
		return false
	end
	
	local enabled_server_mod_names = ModManager:GetEnabledServerModNames()
	return (#enabled_server_mod_names > 0)
end

function AreAnyModsEnabled()
	if ModManager == nil then
		print("AreAnyModsEnabled returning false because ModManager hasn't been created yet.")
		return false
	end
	
	local enabled_mod_names = ModManager:GetEnabledModNames()
	return (#enabled_mod_names > 0)
end

function GetEnabledModNamesDetailed() --just used for callstack reporting
	local name_details = {}
	
	for k,mod_name in pairs(ModManager:GetEnabledModNames()) do
		local modinfo = KnownModIndex:GetModInfo(mod_name)
		if modinfo ~= nil then
			local mod_details = mod_name
			
			if modinfo.name ~= nil then
				mod_details = mod_details .. ":" .. modinfo.name 
			end
			
			if modinfo.version ~= nil then
				mod_details = mod_details .. " version: " .. modinfo.version 
			end
			
			if modinfo.api_version ~= nil then
				mod_details = mod_details .. " api_version: " .. modinfo.api_version 
			end
		 
			table.insert(name_details, mod_details)
		end
	end		
		
	return name_details
end

function GetModVersion(mod_name, mod_info_use)
	if mod_info_use == "update_mod_info" then
		KnownModIndex:UpdateSingleModInfo(mod_name)
	end
	local modinfo = KnownModIndex:GetModInfo(mod_name)
	if modinfo ~= nil and modinfo.version ~= nil then
		return modinfo.version 
	else
		return ""
	end	
end

function GetEnabledModsModInfoDetails()
    local modinfo_details = {}

    for k,mod_name in pairs(ModManager:GetEnabledServerModNames()) do
        local modinfo = KnownModIndex:GetModInfo(mod_name)
        table.insert(modinfo_details, {
            name = mod_name,
            info_name = modinfo ~= nil and modinfo.name or mod_name,
            version = modinfo ~= nil and modinfo.version or "",
            version_compatible = modinfo ~= nil and modinfo.version_compatible or "",
            all_clients_require_mod = modinfo ~= nil and modinfo.all_clients_require_mod == true,
        })
    end

    return modinfo_details
end

function GetEnabledServerModsConfigData()
	local mods_config_data = {}
	for k,mod_name in pairs(ModManager:GetEnabledServerModNames()) do

		local modinfo = KnownModIndex:GetModInfo(mod_name)
		if modinfo ~= nil and modinfo.all_clients_require_mod then
			local config_data = {}
			local force_local_options = true
			local config = KnownModIndex:LoadModConfigurationOptions(mod_name, false)
			if config and type(config) == "table" then
				for i,v in pairs(config) do
			  		if v.saved ~= nil then
						config_data[v.name] = v.saved 
					else 
						config_data[v.name] = v.default
					end
				end
			end
	
			mods_config_data[mod_name] = config_data
		end
	end
	local encoded_data = DataDumper( mods_config_data, nil, false )
	return encoded_data
end

	
local function modprint(...)
	--print(unpack({...}))
end

local runmodfn = function(fn,mod,modtype)
	return (function(...)
		if fn then
			local status, r = xpcall( function() return fn(unpack(arg)) end, debug.traceback)
			if not status then
				print("error calling "..modtype.." in mod "..ModInfoname(mod.modname)..": \n"..r)
				ModManager:RemoveBadMod(mod.modname,r)
				ModManager:DisplayBadMods()
			else
				return r
			end
		end
	end)
end

ModWrangler = Class(function(self)
	self.modnames = {}
	self.mods = {}
	self.records = {}
	self.failedmods = {}
	self.enabledmods = {}
	self.loadedprefabs = {}
	self.servermods = nil
end)

function ModWrangler:GetEnabledModNames()
	return self.enabledmods
end

function ModWrangler:GetEnabledServerModTags()
	local tags = {}
	for k,mod_name in pairs(self.GetEnabledServerModNames()) do
		local modinfo = KnownModIndex:GetModInfo(mod_name)
			if modinfo ~= nil and modinfo.server_filter_tags ~= nil then
				for i,tag in pairs(modinfo.server_filter_tags) do
					table.insert(tags, tag)
				end
		end
	end
	return tags	
end

function ModWrangler:GetEnabledServerModNames()
	local server_mods = {}
	local mod_names = KnownModIndex:GetServerModNames()
	for _,modname in pairs(mod_names) do
		if KnownModIndex:IsModEnabled(modname) or KnownModIndex:IsModForceEnabled(modname) then
			local modinfo = KnownModIndex:GetModInfo(modname)
			if modinfo ~= nil then
				if not modinfo.client_only_mod then
					table.insert(server_mods, modname)
				end
			else
				table.insert(server_mods, modname)
			end
		end
	end
	return server_mods
end

function ModWrangler:GetServerModsNames()
	if TheWorld.ismastersim then
		return self:GetEnabledServerModNames() 
	else
		if self.servermods == nil then
			self.servermods = TheNet:GetServerModNames()
		end
		return self.servermods
	end
end

function ModWrangler:GetMod(modname)
	for i,mod in ipairs(self.mods) do
		if mod.modname == modname then
			return mod
		end
	end
end

function ModWrangler:SetModRecords(records)
	self.records = records
	for mod,record in pairs(self.records) do
		if table.contains(self.enabledmods, mod) then
			record.active = true
		else
			record.active = false
		end
	end

	for i,mod in ipairs(self.enabledmods) do
		if not self.records[mod] then
			self.records[mod] = {}
			self.records[mod].active = true
		end
	end
end

function ModWrangler:GetModRecords()
	return self.records
end

function CreateEnvironment(modname, isworldgen)

	local modutil = require("modutil")
	require("recipe") -- for Ingredient

	local env = 
	{
		TUNING=TUNING,
		modname = modname,
		pairs = pairs,
		ipairs = ipairs,
		print = print,
		math = math,
		table = table,
		type = type,
		string = string,
		tostring = tostring,
		Class = Class,
		GLOBAL = _G,
		MODROOT = "../mods/"..modname.."/",
	}

	if isworldgen == false then
		env.CHARACTERLIST = GetActiveCharacterList()
	end

	env.env = env

	--install our crazy loader!
	env.modimport = function(modulename)
		print("modimport: "..env.MODROOT..modulename)
        local result = kleiloadlua(env.MODROOT..modulename)
		if result == nil then
			error("Error in modimport: "..modulename.." not found!")
		elseif type(result) == "string" then
			error("Error in modimport: "..ModInfoname(modname).." importing "..modulename.."!\n"..result)
		else
        	setfenv(result, env.env)
            result()
        end
	end

	modutil.InsertPostInitFunctions(env, isworldgen)

	return env
end

function ModWrangler:LoadServerModsFile()
	local function ServerModSetup(product_id)
		TheNet:ServerModSetup(product_id)
	end
	local function ServerModCollectionSetup(collection_id)
		TheNet:ServerModCollectionSetup(collection_id)
	end
	
	local env = {
		ServerModSetup = ServerModSetup,
		ServerModCollectionSetup = ServerModCollectionSetup,
	}

	KnownModIndex:UpdateModInfo() --we have to update the modinfo so that we have the correct mod versions
	
	TheNet:BeginServerModSetup()
	
	local filename = "../mods/dedicated_server_mods_setup.lua"
	local fn = kleiloadlua( filename )
	if fn ~= nil then
		local mods_err_fn = function(err)
			print("########################################################")
			print("#ERROR: Failure to load dedicated_server_mods_setup.lua:", err)
			print("#Shutting down")
			print("########################################################")
			Shutdown()
		end
			
		if type(fn)=="string" then
			mods_err_fn(fn)
		else
			setfenv(fn, env)
			xpcall( fn, mods_err_fn )
		end
	end
	
	TheNet:DownloadServerMods()
end

function ModWrangler:DisableAllServerMods()
	local mod_names = KnownModIndex:GetServerModNames()
	for _,modname in pairs(mod_names) do
		KnownModIndex:Disable(modname)
	end
	KnownModIndex:Save()
end

local function IsInFrontEnd()
	return Settings.reset_action == nil or Settings.reset_action == RESET_ACTION.LOAD_FRONTEND
end

function ModWrangler:LoadMods(worldgen)	
	if not MODS_ENABLED then
		return
	end

	self.worldgen = worldgen or false

	if not worldgen and TheNet:IsDedicated() then
		self:LoadServerModsFile()
	end

	local mod_overrides = {}
	if not worldgen then
		
		if IsInFrontEnd() then
			--print("~~~~~~~~~~~~~~~~~~ Disable server mods and clear temp mod flags ~~~~~~~~~~~~~~~~~~ ")
			KnownModIndex:ClearAllTempModFlags() --clear all old temp mod flags when the game starts incase someone killed the process before disconnecting
			self:DisableAllServerMods()
		end
		
		--print( "### LoadMods for game ###" )
		KnownModIndex:UpdateModInfo()
		mod_overrides = KnownModIndex:LoadModOverides()
		KnownModIndex:ApplyEnabledOverrides(mod_overrides)
	end
	
	local moddirs = KnownModIndex:GetModsToLoad(self.worldgen)
	
	for i,modname in ipairs(moddirs) do
		if self.worldgen == false or (self.worldgen == true and KnownModIndex:IsModCompatibleWithMode(modname)) then
			table.insert(self.modnames, modname)

			if self.worldgen == false then
				-- Make sure we load the config data before the mod (but not during worldgen)
				KnownModIndex:LoadModConfigurationOptions(modname, not TheNet:GetIsServer())
				KnownModIndex:ApplyConfigOptionOverrides(mod_overrides)
			end

			local initenv = KnownModIndex:GetModInfo(modname)
			local env = CreateEnvironment(modname,  self.worldgen)
			env.modinfo = initenv

			table.insert( self.mods, env )
			local loadmsg = "Loading mod: "..ModInfoname(modname).." Version:"..env.modinfo.version
			if initenv.modinfo_message and initenv.modinfo_message ~= "" then
				loadmsg = loadmsg .. " ("..initenv.modinfo_message..")"
			end
			print(loadmsg)
		end
	end

	-- Sort the mods by priority, so that "library" mods can load first
	local function modPrioritySort(a,b)
		local apriority = (a.modinfo and a.modinfo.priority) or 0
		local bpriority = (b.modinfo and b.modinfo.priority) or 0
		if apriority == bpriority then
			return tostring(a.modinfo and a.modinfo.name) > tostring(b.modinfo and b.modinfo.name)
		else
			return apriority  > bpriority
		end
	end
	table.sort(self.mods, modPrioritySort)

	for i,mod in ipairs(self.mods) do
		table.insert(self.enabledmods, mod.modname)
		package.path = "..\\mods\\"..mod.modname.."\\scripts\\?.lua;"..package.path
		self:InitializeModMain(mod.modname, mod, "modworldgenmain.lua")
		if not self.worldgen then 
			-- worldgen has to always run (for customization screen) but modmain can be
			-- skipped for worldgen. This reduces a lot of issues with missing globals.
			self:InitializeModMain(mod.modname, mod, "modmain.lua")
		end
	end
end

function ModWrangler:InitializeModMain(modname, env, mainfile)
	if not KnownModIndex:IsModCompatibleWithMode(modname) then return end

	print("Mod: "..ModInfoname(modname), "Loading "..mainfile)

	local fn = kleiloadlua("../mods/"..modname.."/"..mainfile)
	if type(fn) == "string" then
		print("Mod: "..ModInfoname(modname), "  Error loading mod!\n"..fn.."\n")
		table.insert( self.failedmods, {name=modname,error=fn} )
		return false
	elseif not fn then
		print("Mod: "..ModInfoname(modname), "  Mod had no "..mainfile..". Skipping.")
		return true
	else
		local status, r = RunInEnvironment(fn,env)

		if status == false then
			print("Mod: "..ModInfoname(modname), "  Error loading mod!\n"..r.."\n")
			table.insert( self.failedmods, {name=modname,error=r} )
			return false
		else
			-- the env is an "out reference" so we're done here.
			return true
		end
	end
end

function ModWrangler:RemoveBadMod(badmodname,error)
	KnownModIndex:DisableBecauseBad(badmodname)

	table.insert( self.failedmods, {name=badmodname,error=error} )
end

function ModWrangler:DisplayBadMods()
	if self.worldgen then
		-- we can't save or show errors from worldgen! Up to the main game to display the error.
		for k,badmod in ipairs(self.failedmods) do
			local errormsg = badmod.error
			error(errormsg)
		end
		return
	end
	
			
	-- If the frontend isn't ready yet, just hold onto this until we can display it.

	if #self.failedmods > 0 then
		for i,failedmod in ipairs(self.failedmods) do
			KnownModIndex:DisableBecauseBad(failedmod.name)
			self:GetMod(failedmod.name).modinfo.failed = true
			print("Disabling "..ModInfoname(failedmod.name).." because it had an error.")
		end
	end
	-- There are several flows which may have disabled mods; now is a safe place to save those changes.
	KnownModIndex:Save()

	if TheFrontEnd then
		for k,badmod in ipairs(self.failedmods) do
			SetGlobalErrorWidget(
					STRINGS.UI.MAINSCREEN.MODFAILTITLE, 
					STRINGS.UI.MAINSCREEN.MODFAILDETAIL.." "..KnownModIndex:GetModFancyName(badmod.name).."\n"..badmod.error.."\n",
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
					STRINGS.UI.MAINSCREEN.MODFAILDETAIL2,
					20
					)
		end
		self.failedmods = {}
	end
end

function ModWrangler:RegisterPrefabs()
	if not MODS_ENABLED then
		return
	end

	for i,modname in ipairs(self.enabledmods) do
		local mod = self:GetMod(modname)

		mod.LoadPrefabFile = LoadPrefabFile
		mod.RegisterPrefabs = RegisterPrefabs
		mod.Prefabs = {}

		print("Mod: "..ModInfoname(mod.modname), "Registering prefabs")

		-- We initialize the prefabs in the sandbox and collect all the created prefabs back
		-- into the main world.
		if mod.PrefabFiles then
			for i,prefab_path in ipairs(mod.PrefabFiles) do
				print("Mod: "..ModInfoname(mod.modname), "  Registering prefab file: prefabs/"..prefab_path)
				local ret = runmodfn( mod.LoadPrefabFile, mod, "LoadPrefabFile" )("prefabs/"..prefab_path)
				if ret then
					for i,prefab in ipairs(ret) do
						print("Mod: "..ModInfoname(mod.modname), "    "..prefab.name)
						mod.Prefabs[prefab.name] = prefab
					end
				end
			end
		end

		local prefabnames = {}
		for name, prefab in pairs(mod.Prefabs) do
			table.insert(prefabnames, name)
			Prefabs[name] = prefab -- copy the prefabs back into the main environment
		end

		print("Mod: "..ModInfoname(mod.modname), "  Registering default mod prefab")

		RegisterPrefabs( Prefab("MOD_"..mod.modname, nil, mod.Assets, prefabnames) )

		local modname = "MOD_"..mod.modname
		TheSim:LoadPrefabs({modname})
		table.insert(self.loadedprefabs, modname)
	end
end

function ModWrangler:UnloadPrefabs()
	for i, modname in ipairs( self.loadedprefabs ) do
		print("unloading prefabs for mod "..ModInfoname(modname))
		TheSim:UnloadPrefabs({modname})
	end
end

function ModWrangler:SetPostEnv()

	local moddetail = ""

	--print("\n\n---MOD INFO SCREEN---\n\n")

	local modnames = ""
	local newmodnames = ""
	local failedmodnames = ""
	local forcemodnames = ""

	if #self.mods > 0 then
		for i,mod in ipairs(self.mods) do
			modprint("###"..mod.modname)
			--dumptable(mod.modinfo)
			if KnownModIndex:IsModNewlyBad(mod.modname) then
				modprint("@NEWLYBAD")
				failedmodnames = failedmodnames.."\""..KnownModIndex:GetModFancyName(mod.modname).."\" "
			elseif KnownModIndex:IsModForceEnabled(mod.modname) then
				modprint("@FORCEENABLED")
				mod.TheFrontEnd = TheFrontEnd
				mod.TheSim = TheSim
				mod.Point = Point
				mod.TheGlobalInstance = TheGlobalInstance

				for i,modfn in ipairs(mod.postinitfns.GamePostInit) do
					runmodfn( modfn, mod, "gamepostinit" )()
				end
	
				forcemodnames = forcemodnames.."\""..KnownModIndex:GetModFancyName(mod.modname).."\" "
			elseif KnownModIndex:IsModEnabled(mod.modname) then
				modprint("@ENABLED")
				mod.TheFrontEnd = TheFrontEnd
				mod.TheSim = TheSim
				mod.Point = Point
				mod.TheGlobalInstance = TheGlobalInstance

				for i,modfn in ipairs(mod.postinitfns.GamePostInit) do
					runmodfn( modfn, mod, "gamepostinit" )()
				end

				modnames = modnames.."\""..KnownModIndex:GetModFancyName(mod.modname).."\" "
			else
				modprint("@DISABLED")
			end
		end
	end

	--print("\n\n---END MOD INFO SCREEN---\n\n")
	if failedmodnames ~= "" then
		moddetail = moddetail.. STRINGS.UI.MAINSCREEN.FAILEDMODS.." "..failedmodnames.."\n"
	end

	if newmodnames ~= "" then
		moddetail = moddetail.. STRINGS.UI.MAINSCREEN.NEWMODDETAIL.." "..newmodnames.."\n"..STRINGS.UI.MAINSCREEN.NEWMODDETAIL2.."\n\n"
	end
	if modnames ~= "" then
		moddetail = moddetail.. STRINGS.UI.MAINSCREEN.MODDETAIL.." "..modnames.."\n\n"
	end
	if newmodnames ~= "" or modnames ~= "" then
		moddetail = moddetail.. STRINGS.UI.MAINSCREEN.MODDETAIL2.."\n\n"
	end
	if forcemodnames ~= "" then
		moddetail = moddetail.. STRINGS.UI.MAINSCREEN.FORCEMODDETAIL.." "..forcemodnames.."\n\n"
	end

	if (modnames ~= "" or newmodnames ~= "" or failedmodnames ~= "" or forcemodnames ~= "")  and TheSim:ShouldWarnModsLoaded() then
	--if (#self.enabledmods > 0)  and TheSim:ShouldWarnModsLoaded() then
		if not DISABLE_MOD_WARNING and IsInFrontEnd() then
			TheFrontEnd:PushScreen(
				ModWarningScreen(
					STRINGS.UI.MAINSCREEN.MODTITLE, 
					moddetail,
					{
						{text=STRINGS.UI.MAINSCREEN.TESTINGYES, cb = function() TheFrontEnd:PopScreen() end},
						{text=STRINGS.UI.MAINSCREEN.MODQUIT, cb = function()
																		KnownModIndex:DisableAllMods()
																		ForceAssetReset()
																		KnownModIndex:Save(function()
																			SimReset()
																		end)
																	end},
						{text=STRINGS.UI.MAINSCREEN.MODFORUMS, nopop=true, cb = function() VisitURL("http://forums.kleientertainment.com/forum/79-dont-starve-together-beta-mods-and-tools/") end }
					}))
		end
	elseif KnownModIndex:WasLoadBad() then
		TheFrontEnd:PushScreen(
			ModWarningScreen(
				STRINGS.UI.MAINSCREEN.MODSBADTITLE, 
				STRINGS.UI.MAINSCREEN.MODSBADLOAD,
				{
					{text=STRINGS.UI.MAINSCREEN.TESTINGYES, cb = function() TheFrontEnd:PopScreen() end},
					{text=STRINGS.UI.MAINSCREEN.MODFORUMS, nopop=true, cb = function() VisitURL("http://forums.kleientertainment.com/index.php?/forum/26-dont-starve-mods-and-tools/") end }
				}))
	end

	self:DisplayBadMods()
end

function ModWrangler:SimPostInit(wilson)
	for i,modname in ipairs(self.enabledmods) do
		local mod = self:GetMod(modname)
		for i,modfn in ipairs(mod.postinitfns.SimPostInit) do
			runmodfn( modfn, mod, "simpostinit" )(wilson)
		end
	end

	self:DisplayBadMods()
end

function ModWrangler:GetPostInitFns(type, id)
	local retfns = {}
	for i,modname in ipairs(self.enabledmods) do
		local mod = self:GetMod(modname)
		if mod.postinitfns[type] then
			local modfns = nil
			if id then
				modfns = mod.postinitfns[type][id]
			else
				modfns = mod.postinitfns[type]
			end
			if modfns ~= nil then
				for i,modfn in ipairs(modfns) do
					--print(modname, "added modfn "..type.." for "..tostring(id))
					table.insert(retfns, runmodfn(modfn, mod, id and type..": "..id or type))
				end
			end
		end
	end
	return retfns
end

function ModWrangler:GetPostInitData(type, id)
	local moddata = {}
	for i,modname in ipairs(self.enabledmods) do
		local mod = self:GetMod(modname)
		if mod.postinitdata[type] then
			local data = nil
			if id then
				data = mod.postinitdata[type][id]
			else
				data = mod.postinitdata[type]
			end

			if data ~= nil then
				--print(modname, "added moddata "..type.." for "..tostring(id))
				table.insert(moddata, data)
			end
		end
	end
	return moddata
end

function ModWrangler:GetVoteCommands()
	local commands = {}
	for i,modname in ipairs(self.enabledmods) do
		local mod = self:GetMod(modname)
		if mod.vote_commands then
			for command_name,command in pairs(mod.vote_commands) do
				commands[command_name] = command
			end
		end
	end
	return commands
end

function ModWrangler:IsModCharacterClothingSymbolExcluded( name, symbol )
	local commands = {}
	for i,modname in ipairs(self.enabledmods) do
		local mod = self:GetMod(modname)
		if mod.clothing_exclude and mod.clothing_exclude[name] then
			for _,excluded_sym in pairs(mod.clothing_exclude[name]) do
				if excluded_sym == symbol then
					return true
				end
			end
		end
	end
	return false
end

function ModVersionOutOfDate( mod_name )
    print("Mod: " .. mod_name .. " is out of date and needs to be updated for new users to be able to join the server.")
    --5th param true -> local server only announcement
    TheNet:Announce(string.format(STRINGS.MODS.VERSIONING.OUT_OF_DATE, KnownModIndex:GetModFancyName(mod_name)), nil, nil, nil, true)
end

function VerifyModVersions( mods_to_verify )
	TheSim:VerifyModVersions( mods_to_verify )
end

function ModWrangler:StartVersionChecking()
	if TheWorld.ismastersim then
		local mods_to_verify = {}
		for k,mod_name in pairs(ModManager:GetEnabledServerModNames()) do

			local modinfo = KnownModIndex:GetModInfo(mod_name)
			if modinfo.all_clients_require_mod then
				--print( "adding mod to verify ", mod_name )
				table.insert( mods_to_verify, mod_name )
				table.insert( mods_to_verify, modinfo.version )
			end
		end
		if #mods_to_verify > 0 then
			--Start mod version checking task
			local time = 2 * 60
			local limit = nil
			local initialdelay = 60
			local id = "mods_version_check"
			local per = scheduler:ExecutePeriodic( time, function() VerifyModVersions( mods_to_verify ) end, limit, initialdelay, id, self )
		end
    end
end

ModManager = ModWrangler()

---------------------------------------------

