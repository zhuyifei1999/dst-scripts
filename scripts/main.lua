-- Override the package.path in luaconf.h because it is impossible to find
package.path = "scripts\\?.lua;scriptlibs\\?.lua"

--defines
math.randomseed(os.time())
MAIN = 1
ENCODE_SAVES = BRANCH ~= "dev"
CHEATS_ENABLED = BRANCH == "dev" or (PLATFORM == "PS4" and CONFIGURATION ~= "PRODUCTION")
SOUNDDEBUG_ENABLED = false
WORLDSTATEDEBUG_ENABLED = false
ACCOMPLISHMENTS_ENABLED = PLATFORM == "PS4"
--DEBUG_MENU_ENABLED = true
DEBUG_MENU_ENABLED = BRANCH == "dev" or (PLATFORM == "PS4" and CONFIGURATION ~= "PRODUCTION")
METRICS_ENABLED = PLATFORM ~= "PS4"
TESTING_NETWORK = 1
AUTOSPAWN_MASTER_SLAVE = false
DEBUGRENDER_ENABLED = true
SHOWLOG_ENABLED = true

-- Networking related configuration
DEFAULT_JOIN_IP				= "127.0.0.1"
DISABLE_MOD_WARNING			= false
DEFAULT_SERVER_SAVE_FILE    = "/server_save"

RELOADING = false

--debug.setmetatable(nil, {__index = function() return nil end})  -- Makes  foo.bar.blat.um  return nil if table item not present   See Dave F or Brook for details

ExecutingLongUpdate = false

local servers =
{
	release = "http://dontstarve-release.appspot.com",
	dev = "http://dontstarve-dev.appspot.com",
	--staging = "http://dontstarve-staging.appspot.com",
    --staging is now the live preview branch
    staging = "http://dontstarve-release.appspot.com",
}
GAME_SERVER = servers[BRANCH]


TheSim:SetReverbPreset("default")

if PLATFORM == "NACL" then
	VisitURL = function(url, notrack)
		if notrack then
			TheSim:SendJSMessage("VisitURLNoTrack:"..url)
		else
			TheSim:SendJSMessage("VisitURL:"..url)
		end
	end
end

package.path = package.path .. ";scripts/?.lua"

--used for A/B testing and preview features. Gets serialized into and out of save games
GameplayOptions = 
{
}


--install our crazy loader!
local loadfn = function(modulename)
	--print (modulename, package.path)
    local errmsg = ""
    local modulepath = string.gsub(modulename, "%.", "/")
    for path in string.gmatch(package.path, "([^;]+)") do
        local filename = string.gsub(path, "%?", modulepath)
        filename = string.gsub(filename, "\\", "/")
        local result = kleiloadlua(filename)
        if result then
            return result
        end
        errmsg = errmsg.."\n\tno file '"..filename.."' (checked with custom loader)"
    end
  return errmsg    
end
table.insert(package.loaders, 1, loadfn)

--patch this function because NACL has no fopen
if TheSim then
    function loadfile(filename)
        filename = string.gsub(filename, ".lua", "")
        filename = string.gsub(filename, "scripts/", "")
        return loadfn(filename)
    end
end

if PLATFORM == "NACL" then
    package.loaders[2] = nil
elseif PLATFORM == "WIN32" then
end

--if not TheNet:GetIsClient() then
--	require("mobdebug").start()
--end
	
require("strict")
require("debugprint")
-- add our print loggers
AddPrintLogger(function(...) TheSim:LuaPrint(...) end)

require("config")

require("vector3")
require("mainfunctions")
require("preloadsounds")

require("mods")
require("json")
require("tuning")
require("languages/language")
require("strings")
require("stringutil")
require("dlcsupport_strings")
require("constants")
require("class")
require("actions")
require("debugtools")
require("simutil")
require("util")
require("scheduler")
require("stategraph")
require("behaviourtree")
require("prefabs")
require("prefabskin")
require("entityscript")
require("profiler")
require("recipes")
require("brain")
require("emitters")
require("dumper")
require("input")
require("upsell")
require("stats")
require("frontend")
require("netvars")
require("networking")
require("networkclientrpc")
require("shardnetworking")

if METRICS_ENABLED then
require("overseer")
end

require("fileutil")
require("screens/scripterrorscreen")
require("prefablist")
require("standardcomponents")
require("update")
require("fonts")
require("physics")
require("modindex")
require("mathutil")
require("components/lootdropper")
require("reload")
require("saveindex") -- Added by Altgames for Android focus lost handling
require("worldtiledefs")
require("gamemodes")
require("skinsutils")

if TheConfig:IsEnabled("force_netbookmode") then
	TheSim:SetNetbookMode(true)
end


--debug key init
if CHEATS_ENABLED then
	require "debugkeys"
end


print ("running main.lua\n")
TheSystemService:SetStalling(true)

VERBOSITY_LEVEL = VERBOSITY.ERROR
if CONFIGURATION ~= "Production" then
	VERBOSITY_LEVEL = VERBOSITY.DEBUG
end

-- uncomment this line to override
VERBOSITY_LEVEL = VERBOSITY.WARNING

--instantiate the mixer
local Mixer = require("mixer")
TheMixer = Mixer.Mixer()
require("mixes")
TheMixer:PushMix("start")


Prefabs = {}
Ents = {}
AwakeEnts = {}
UpdatingEnts = {}
NewUpdatingEnts = {}
StopUpdatingEnts = {}

StopUpdatingComponents = {}

WallUpdatingEnts = {}
NewWallUpdatingEnts = {}
num_updating_ents = 0
NumEnts = 0


TheGlobalInstance = nil

global("TheCamera")
TheCamera = nil
global("SplatManager")
SplatManager = nil
global("ShadowManager")
ShadowManager = nil
global("RoadManager")
RoadManager = nil
global("EnvelopeManager")
EnvelopeManager = nil
global("PostProcessor")
PostProcessor = nil

global("FontManager")
FontManager = nil
global("MapLayerManager")
MapLayerManager = nil
global("Roads")
Roads = nil
global("TheFrontEnd")
TheFrontEnd = nil
global("TheWorld")
TheWorld = nil
global("TheFocalPoint")
TheFocalPoint = nil
global("ThePlayer")
ThePlayer = nil
global("AllPlayers")
AllPlayers = {}
global("SERVER_TERMINATION_TIMER")
SERVER_TERMINATION_TIMER = -1

require("globalvariableoverrides")


inGamePlay = false

local function ModSafeStartup()

	-- If we failed to boot last time, disable all mods
	-- Otherwise, set a flag file to test for boot success.

	---PREFABS AND ENTITY INSTANTIATION

	ModManager:LoadMods()

	-- Apply translations
	TranslateStringTable( STRINGS )

	-- Register every standard prefab with the engine

	-- This one needs to be active from the get-go.
	LoadPrefabFile("prefabs/global")
    LoadAchievements("achievements.lua")

    local FollowCamera = require("cameras/followcamera")
    TheCamera = FollowCamera()

	--- GLOBAL ENTITY ---
    --[[Non-networked entity]]
    TheGlobalInstance = CreateEntity()
    TheGlobalInstance.entity:AddTransform()
    TheGlobalInstance.entity:SetCanSleep(false)
    TheGlobalInstance.persists = false
    TheGlobalInstance:AddTag("CLASSIFIED")

	if RUN_GLOBAL_INIT then
		GlobalInit()
	end

	SplatManager = TheGlobalInstance.entity:AddSplatManager()
	ShadowManager = TheGlobalInstance.entity:AddShadowManager()
	ShadowManager:SetTexture( "images/shadow.tex" )
	RoadManager = TheGlobalInstance.entity:AddRoadManager()
	EnvelopeManager = TheGlobalInstance.entity:AddEnvelopeManager()

	PostProcessor = TheGlobalInstance.entity:AddPostProcessor()
	local IDENTITY_COLOURCUBE = "images/colour_cubes/identity_colourcube.tex"
	PostProcessor:SetColourCubeData( 0, IDENTITY_COLOURCUBE, IDENTITY_COLOURCUBE )
	PostProcessor:SetColourCubeData( 1, IDENTITY_COLOURCUBE, IDENTITY_COLOURCUBE )

	FontManager = TheGlobalInstance.entity:AddFontManager()
	MapLayerManager = TheGlobalInstance.entity:AddMapLayerManager()

    -- I think we've got everything we need by now...
    if TheSim:GetNumLaunches() == 1 then
        RecordGameStartStats()
    end

end

SetInstanceParameters(json_settings)

if not MODS_ENABLED then
	-- No mods in nacl, and the below functions are async in nacl
	-- so they break because Main returns before ModSafeStartup has run.
	ModSafeStartup()
else
	KnownModIndex:Load(function() 
		KnownModIndex:BeginStartupSequence(function()
			ModSafeStartup()
		end)
	end)
end

require "stacktrace"
require "debughelpers"

TheSystemService:SetStalling(false)


--load the user's custom commands into the game
local filename = "../customcommands.lua"
TheSim:GetPersistentString( filename,
	function(load_success, str)
		if load_success == true then
			local fn = loadstring(str)
			local success, savedata = xpcall(fn, debug.traceback)
		end
	end
)