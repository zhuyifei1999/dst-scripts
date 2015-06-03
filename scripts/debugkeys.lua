require "consolecommands"

local function DebugKeyPlayer()
    return ConsoleCommandPlayer()
end

----this gets called by the frontend code if a rawkey event has not been consumed by the current screen
handlers = {}

-- Add commonly used commands here. 
-- Hitting F2 will append them to the current console history 
-- Hit  SHIFT-CTRL-F2 to add the current console history to this list (list is not saved between reloads!)
local LOCAL_HISTORY =
{
    "c_godmode(true)",
    "c_spawn('nightmarebeak',10)",
    "c_spawn('minotaur')",
}

function DoDebugKey(key, down)
    if handlers[key] then
        for k,v in ipairs(handlers[key]) do
            if v(down) then
                return true
            end
        end
    end
end

--use this to register debug key handlers from within this file
function AddGameDebugKey(key, fn, down)
    down = down or true
    handlers[key] = handlers[key] or {}
    table.insert( handlers[key], function(_down) if _down == down and inGamePlay then return fn() end end)
end

function AddGlobalDebugKey(key, fn, down)
    down = down or true
    handlers[key] = handlers[key] or {}
    table.insert( handlers[key], function(_down) if _down == down then return fn() end end)
end

function SimBreakPoint()
    if not TheSim:IsDebugPaused() then
        TheSim:ToggleDebugPause()
    end
end

-------------------------------------DEBUG KEYS

local currentlySelected
global("c_ent")
global("c_ang")

local function Spawn(prefab)
    --TheSim:LoadPrefabs({prefab})
    return SpawnPrefab(prefab)
end

local userName = TheSim:GetUsersName() 
--
-- Put your own username in here to enable "dprint"s to output to the log window 
if CHEATS_ENABLED and userName == "My Username" then
    global("CHEATS_KEEP_SAVE")
    global("CHEATS_ENABLE_DPRINT")
    global("DPRINT_USERNAME")
    global("c_ps")

    DPRINT_USERNAME = "My Username"
    CHEATS_KEEP_SAVE = true
    CHEATS_ENABLE_DPRINT = true
end

function InitDevDebugSession()
    --[[ To setup this function to be called when the game starts up edit stats.lua and patch the context:
                    function RecordSessionStartStats()
                        if not STATS_ENABLE then
                            return
                        end

                        if InitDevDebugSession then
                            InitDevDebugSession()
                        end
                     --- rest of function
    --]]
    -- Add calls that you want executed whenever a session starts
    -- Here, for example the minhealth is set so the player can't be killed
    -- and the autosave is disabled so that it
    -- doesnt' overwrite my carefully constructed debugging setup
    dprint("DEVDEBUGSESSION")
    global( "TheFrontEnd" )
    local player = ConsoleCommandPlayer()

    c_setminhealth(5)
    TheFrontEnd.consoletext.closeonrun = true
    TheWorld:PushEvent("ms_setautosaveenabled", false)
end

AddGlobalDebugKey(KEY_HOME, function()
    if not TheSim:IsDebugPaused() then
        print("Home key pressed PAUSING GAME")
        TheSim:ToggleDebugPause()
    end
    if TheInput:IsKeyDown(KEY_CTRL) then
        TheSim:ToggleDebugPause()
    else
        print("Home key pressed STEPPING")
        TheSim:Step()
    end
    return true
end)

AddGlobalDebugKey(KEY_F1, function()
    if TheInput:IsKeyDown(KEY_CTRL) then
        TheSim:TogglePerfGraph()
        return true
    else
        TheWorld:PushEvent("ms_lightwildfireforplayer", ThePlayer)
    end

end)

AddGlobalDebugKey(KEY_R, function()
    if TheInput:IsKeyDown(KEY_CTRL) then
        if TheInput:IsKeyDown(KEY_SHIFT) then
            c_regenerateworld()
        else
            c_reset()
        end
        return true
    end
end)

AddGameDebugKey(KEY_F2, function()
    if c_sel() == TheWorld then
        c_select(TheWorld.net)
    else
        c_select(TheWorld)
    end
end)

AddGameDebugKey(KEY_F3, function()
    for i=1,TheWorld.state.remainingdaysinseason do
        TheWorld:PushEvent("ms_advanceseason")
    end
end)

AddGameDebugKey(KEY_R, function()
    if TheInput:IsKeyDown(KEY_SHIFT) then
        local ent = TheInput:GetWorldEntityUnderMouse()
        if ent ~= nil and ent.prefab ~= nil then
            ent:Remove()
        end
        return true
    end 
end)

AddGameDebugKey(KEY_F4, function()
    if TheInput:IsKeyDown(KEY_CTRL) then 
        TheWorld:PushEvent("ms_forceprecipitation", false)
    else
        TheWorld:PushEvent("ms_forceprecipitation", true)
    end
    return true
end)

AddGameDebugKey(KEY_F5, function()
    if TheInput:IsKeyDown(KEY_SHIFT) then
        local pos = TheInput:GetWorldPosition()
        TheWorld:PushEvent("ms_sendlightningstrike", pos)
    else
        TheWorld:PushEvent("ms_setseasonlength", {season="autumn", length=12})
        TheWorld:PushEvent("ms_setseasonlength", {season="winter", length=10})
        TheWorld:PushEvent("ms_setseasonlength", {season="spring", length=12})
        TheWorld:PushEvent("ms_setseasonlength", {season="summer", length=10})
    end
    return true
end)

AddGameDebugKey(KEY_F6, function()
    -- F6 is used by the hot-reload functionality!
end)

AddGameDebugKey(KEY_F12, function()
    local positions = {}
    for i = 1, 500 do
        local s = i/32.0--(num/2) -- 32.0
        local a = math.sqrt(s*512.0)
        local b = math.sqrt(s)
        table.insert(positions, Vector3(math.sin(a)*b, 0, math.cos(a)*b))
    end

    local pos = DebugKeyPlayer():GetPosition()
    local delay = 0
    for i = 1, #positions do
        local sp = pos + (positions[i] * 1.2)
        DebugKeyPlayer():DoTaskInTime(delay, function() 
            local prefab = SpawnPrefab("houndstooth")
            prefab.Transform:SetPosition(sp:Get())
        end)
        --delay = delay + 0.03
    end
end)

AddGameDebugKey(KEY_F7, function()
    local player = ConsoleCommandPlayer()
    if player then
        local x, y, z = player.Transform:GetWorldPosition()
        for i, node in ipairs(TheWorld.topology.nodes) do
            if TheSim:WorldPointInPoly(x, z, node.poly) then
                print("/********************\\")
                print("Standing in", i)
                print("id", TheWorld.topology.ids[i])
                print("type", node.type)
                print("story depth", TheWorld.topology.story_depths[i])
                print("area", node.area)

                if TheInput:IsKeyDown(KEY_SHIFT) then
                    c_teleport(node.cent[1], 0, node.cent[2], player)
                    print("center", unpack(node.cent))
                elseif TheInput:IsKeyDown(KEY_CTRL) then
                    print("poly size", #node.poly)
                    for _,v in ipairs(node.poly) do
                        print("\t", unpack(v))
                    end

                    local idx = 1
                    local nextpoint = nil
                    nextpoint = function()
                        c_teleport(node.poly[idx][1], 0, node.poly[idx][2], player)
                        idx = idx + 1
                        if idx <= #node.poly then
                            player:DoTaskInTime(0.3, nextpoint)
                        end
                    end
                    nextpoint()
                end
                print("\\********************/")
            end
        end
    end
end)

---Spawn random items from the "items" table in a circles around me.

AddGameDebugKey(KEY_F8, function()
    --Spawns a lot of prefabs around you in rings.
    local items = {"grass"} --Which items spawn. 
    local player = DebugKeyPlayer()
    local pt = Vector3(player.Transform:GetWorldPosition())
    local theta = math.random() * 2 * PI
    local numrings = 10 --How many rings of stuff you spawn
    local radius = 5 --Initial distance from player
    local radius_step_distance = 1 --How much the radius increases per ring.
    local itemdensity = .1 --(X items per unit)
    local map = TheWorld.Map
    
    local finalRad = (radius + (radius_step_distance * numrings))
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, finalRad + 2)

    local numspawned = 0
    -- Walk the circle trying to find a valid spawn point
    for i = 1, numrings do
        local circ = 2*PI*radius
        local numitems = circ * itemdensity

        for i = 1, numitems do
            numspawned = numspawned + 1
            local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
            local wander_point = pt + offset
           
            if map:IsPassableAtPoint(wander_point:Get()) then
                local spawn = SpawnPrefab(GetRandomItem(items))
                spawn.Transform:SetPosition(wander_point:Get())
            end
            theta = theta - (2 * PI / numitems)
        end
        radius = radius + radius_step_distance
    end
    print("Made: ".. numspawned .." items")
    return true
end)

AddGameDebugKey(KEY_PAGEUP, function()
    if TheInput:IsKeyDown(KEY_SHIFT) then
        TheWorld:PushEvent("ms_deltawetness", 5)
    elseif TheInput:IsKeyDown(KEY_CTRL) then
        TheWorld:PushEvent("ms_deltamoisture", 100)
    elseif TheInput:IsKeyDown(KEY_ALT) then
        TheWorld:PushEvent("ms_setsnowlevel", TheWorld.state.snowlevel + .5)
    else
        TheWorld:PushEvent("ms_advanceseason")
    end
    return true
end)

AddGameDebugKey(KEY_PAGEDOWN, function()
    if TheInput:IsKeyDown(KEY_SHIFT) then
        TheWorld:PushEvent("ms_deltawetness", -5)
    elseif TheInput:IsKeyDown(KEY_CTRL) then
        TheWorld:PushEvent("ms_deltamoisture", -100)
    elseif TheInput:IsKeyDown(KEY_ALT) then
        TheWorld:PushEvent("ms_setsnowlevel", TheWorld.state.snowlevel - .5)
    else
        TheWorld:PushEvent("ms_retreatseason")
    end
    return true
end)


AddGameDebugKey(KEY_O, function()
    if TheInput:IsKeyDown(KEY_SHIFT) then
        print("Going normal...")
        --TheWorld:PushEvent("ms_setphase", "dusk")
        --TheSim:SetAmbientColour(0.8,0.8,0.8)
        -- Normal ruins (pretty, light, healthy)
        --GetCeiling().MapCeiling:AddSubstitue(GROUND.WALL_HUNESTONE,GROUND.WALL_HUNESTONE_GLOW)
        --GetCeiling().MapCeiling:AddSubstitue(GROUND.WALL_STONEEYE,GROUND.WALL_STONEEYE_GLOW)
        local retune = require("tuning_override")
        retune.colourcube("ruins_light_cc")
        retune.areaambientdefault("cave")
        TheWorld:PushEvent("setambientsounddaytime", 1)
        --civruinsAMB (1.0)
    elseif TheInput:IsKeyDown(KEY_ALT) then
        print("Going evil...")
        --TheWorld:PushEvent("ms_setphase", "night")
        --TheSim:SetAmbientColour(0.0,0.0,0.0)
        --GetCeiling().MapCeiling:ClearSubstitues()
        -- Evil ruins (ugly, dark, unhealthy)
        local retune = require("tuning_override")
        retune.colourcube("ruins_dark_cc")
        retune.areaambient("CIVRUINS")
        TheWorld:PushEvent("setambientsounddaytime", 2)
        --civruinsAMB (2.0)
    end
    
    return true
end)

AddGameDebugKey(KEY_F9, function()
    LongUpdate(TUNING.TOTAL_DAY_TIME*.25)
    return true
end)

AddGameDebugKey(KEY_F10, function()
    TheWorld:PushEvent("ms_nextphase")
    return true
end)


AddGameDebugKey(KEY_F11, function()
    --GetNightmareClock():NextPhase()
    return true
end)

local potatoparts = { "teleportato_ring", "teleportato_box", "teleportato_crank", "teleportato_potato", "teleportato_base", "adventure_portal" }
local potatoindex = 1

AddGameDebugKey(KEY_1, function()
    if TheInput:IsKeyDown(KEY_CTRL) then
        local MainCharacter = DebugKeyPlayer()
        local part = nil
        for k,v in pairs(Ents) do
            if v.prefab == potatoparts[potatoindex] then
                part = v
                break
            end
        end
        potatoindex = ((potatoindex) % #potatoparts)+1
        if MainCharacter and part then
            MainCharacter.Transform:SetPosition(part.Transform:GetWorldPosition())
        end
        return true
    end
    
end)

AddGameDebugKey(KEY_X, function()
    currentlySelected = TheInput:GetWorldEntityUnderMouse()
    if currentlySelected then
        c_ent = currentlySelected
        dprint(c_ent)
    end
    if TheInput:IsKeyDown(KEY_CTRL) and c_ent then
        dtable(c_ent,1)
    end
    return true
end)

AddGlobalDebugKey(KEY_LEFTBRACKET, function()
    TheSim:SetTimeScale(TheSim:GetTimeScale() - .25)
    return true
end)

AddGlobalDebugKey(KEY_RIGHTBRACKET, function()
    TheSim:SetTimeScale(TheSim:GetTimeScale() + .25)
    return true
end)

AddGameDebugKey(KEY_KP_PLUS, function()
    local MainCharacter = DebugKeyPlayer()
    if MainCharacter ~= nil then
        if TheInput:IsKeyDown(KEY_CTRL) then
            MainCharacter.components.sanity:DoDelta(5)
        elseif TheInput:IsKeyDown(KEY_SHIFT) then
            MainCharacter.components.hunger:DoDelta(50)
        elseif TheInput:IsKeyDown(KEY_ALT) then
            MainCharacter.components.sanity:DoDelta(50)
        else
            MainCharacter.components.health:DoDelta(50, nil, "debug_key")
            c_sethunger(1)
            c_sethealth(1)
            c_setsanity(1)
        end
    end
    return true
end)

AddGameDebugKey(KEY_KP_MINUS, function()
    local MainCharacter = DebugKeyPlayer()
    if MainCharacter then
        if TheInput:IsKeyDown(KEY_CTRL) then
            --MainCharacter.components.temperature:DoDelta(-10)
            --TheSim:SetTimeScale(TheSim:GetTimeScale() - .25)
            MainCharacter.components.sanity:DoDelta(-5)
        elseif TheInput:IsKeyDown(KEY_SHIFT) then
            MainCharacter.components.hunger:DoDelta(-25)
        elseif TheInput:IsKeyDown(KEY_ALT) then
            MainCharacter.components.sanity:SetPercent(0)
        else
            MainCharacter.components.health:DoDelta(-25, nil, "debug_key")
        end
    end
    return true
end)

AddGameDebugKey(KEY_T, function()
    -- Moving Teleport to just plain T as I am getting a sore hand from CTRL-T - Alia
    local MainCharacter = DebugKeyPlayer()
    if MainCharacter then
        MainCharacter.Physics:Teleport(TheInput:GetWorldPosition():Get())
    end   
    return true
end)

AddGameDebugKey(KEY_G, function()
    if TheInput:IsKeyDown(KEY_CTRL) then
        local MouseCharacter = TheInput:GetWorldEntityUnderMouse()
        if MouseCharacter then
            if MouseCharacter.components.growable then
                MouseCharacter.components.growable:DoGrowth()
            elseif MouseCharacter.components.fueled then
                MouseCharacter.components.fueled:SetPercent(1)
            elseif MouseCharacter.components.harvestable then
                MouseCharacter.components.harvestable:Grow()
            elseif MouseCharacter.components.pickable then
                MouseCharacter.components.pickable:Regen()
            elseif MouseCharacter.components.setter then
                MouseCharacter.components.setter:SetSetTime(0.01)
                MouseCharacter.components.setter:StartSetting()
            elseif MouseCharacter.components.cooldown then
                MouseCharacter.components.cooldown:LongUpdate(MouseCharacter.components.cooldown.cooldown_duration)
            end
        end
    else
        c_godmode()
    end
    return true
end)

AddGameDebugKey(KEY_P, function()
    if TheInput:IsKeyDown(KEY_CTRL) then
        local MouseCharacter = TheInput:GetWorldEntityUnderMouse()
        MouseCharacter = MouseCharacter or DebugKeyPlayer()
        if MouseCharacter then
            local pinnable = MouseCharacter.components.pinnable 
            if pinnable then
                if pinnable:IsStuck() then
                    pinnable:Unstick()
                else
                    pinnable:Stick()
                end
            end
        end
    end
    return true
end)

AddGameDebugKey(KEY_K, function()
    if TheInput:IsKeyDown(KEY_CTRL) then
        local MouseCharacter = TheInput:GetWorldEntityUnderMouse()
        if MouseCharacter and MouseCharacter ~= DebugKeyPlayer() then
            if MouseCharacter.components.health then
                MouseCharacter.components.health:Kill()
            elseif MouseCharacter.Remove then
                MouseCharacter:Remove()
            end
        end
    end
    return true
end)

local DebugTextureVisible = false
local MapLerpVal = 0.0

AddGlobalDebugKey(KEY_KP_DIVIDE, function()
    if TheInput:IsKeyDown(KEY_ALT) then
        print("ToggleFrameProfiler")
        TheSim:ToggleFrameProfiler()
    else
        TheSim:ToggleDebugTexture()

        DebugTextureVisible = not DebugTextureVisible
        print("DebugTextureVisible",DebugTextureVisible)
    end
    return true
end)

AddGlobalDebugKey(KEY_EQUALS, function()
    if DebugTextureVisible then
        local val = 1
        if TheInput:IsKeyDown(KEY_ALT) then
            val = 10
        elseif TheInput:IsKeyDown(KEY_CTRL) then
            val = 100
        end
        TheSim:UpdateDebugTexture(val)
    else
        if TheWorld then
            MapLerpVal = MapLerpVal + 0.1
            TheWorld.Map:SetOverlayLerp(MapLerpVal)
        end
    end
    return true
end)

AddGlobalDebugKey(KEY_MINUS, function()
    if DebugTextureVisible then
        local val = 1
        if TheInput:IsKeyDown(KEY_ALT) then
            val = 10
        elseif TheInput:IsKeyDown(KEY_CTRL) then
            val = 100
        end
        TheSim:UpdateDebugTexture(-val)
    else
        if TheWorld then
            MapLerpVal = MapLerpVal - 0.1 
            TheWorld.Map:SetOverlayLerp(MapLerpVal)
        end
    end
    
    return true
end)

local enable_fog = true
local hide_revealed = false
AddGameDebugKey(KEY_M, function()
    local MainCharacter = DebugKeyPlayer()
    if MainCharacter then
        if TheInput:IsKeyDown(KEY_CTRL) then
            enable_fog = not enable_fog
            TheWorld.minimap.MiniMap:EnableFogOfWar(enable_fog)
        elseif TheInput:IsKeyDown(KEY_SHIFT) then
            hide_revealed = not hide_revealed
            TheWorld.minimap.MiniMap:ContinuouslyClearRevealedAreas(hide_revealed)
        end
    end
    return true
end)

AddGameDebugKey(KEY_S, function()
    if TheInput:IsKeyDown(KEY_CTRL) then
        TheWorld:PushEvent("save")
        return true         
    end
end)

AddGameDebugKey(KEY_A, function()
    if TheInput:IsKeyDown(KEY_CTRL) then
        local MainCharacter = DebugKeyPlayer()
        if MainCharacter.components.builder ~= nil then
            MainCharacter.components.builder:GiveAllRecipes()
            MainCharacter:PushEvent("techlevelchange")
        end
        return true
    end
end)

AddGameDebugKey(KEY_KP_MULTIPLY, function()
    if TheInput:IsDebugToggleEnabled() then
        c_give("devtool")
        return true
    end
end)

AddGameDebugKey(KEY_KP_DIVIDE, function()
    if TheInput:IsDebugToggleEnabled() then
        DebugKeyPlayer().components.inventory:DropEverything(false, true)
        return true
    end
end)

AddGameDebugKey(KEY_C, function()
    if userName ~= "David Forsey" then
        if TheInput:IsKeyDown(KEY_CTRL) then
            local IDENTITY_COLOURCUBE = "images/colour_cubes/identity_colourcube.tex"
            PostProcessor:SetColourCubeData( 0, IDENTITY_COLOURCUBE, IDENTITY_COLOURCUBE )
            PostProcessor:SetColourCubeLerp( 0, 0 )
        end
    else
        if not c_ent then return end

        global("c_ent_mood")
        local pos = c_ent.components.knownlocations.GetLocation and c_ent.components.knownlocations:GetLocation("rookery")
        if pos and TheInput:IsKeyDown(KEY_CTRL) then
            c_teleport(pos.x, pos.y, pos.z)
        elseif pos then
            c_teleport(pos.x, pos.y, pos.z, c_ent)
        end
    end
    
    return true
end)

AddGlobalDebugKey(KEY_PAUSE, function()
    print("Toggle pause")
    
    TheSim:ToggleDebugPause()
    TheSim:ToggleDebugCamera()
    
    if TheSim:IsDebugPaused() then
        TheSim:SetDebugRenderEnabled(true)
        if TheCamera.targetpos then
            TheSim:SetDebugCameraTarget(TheCamera.targetpos.x, TheCamera.targetpos.y, TheCamera.targetpos.z)
        end
        
        if TheCamera.headingtarget then
            TheSim:SetDebugCameraRotation(-TheCamera.headingtarget-90)  
        end
    end
    return true
end)

AddGameDebugKey(KEY_H, function()
    if TheInput:IsKeyDown(KEY_LCTRL) then
        ThePlayer.HUD:Toggle()
    elseif TheInput:IsKeyDown(KEY_ALT) then
        TheWorld.components.hounded:ForceNextHoundWave()
    end
end)

AddGameDebugKey(KEY_INSERT, function()
    if TheInput:IsDebugToggleEnabled() then
        if not TheSim:GetDebugRenderEnabled() then
            TheSim:SetDebugRenderEnabled(true)
        end
        if TheInput:IsKeyDown(KEY_SHIFT) then
            TheSim:ToggleDebugCamera()
        else
            TheSim:SetDebugPhysicsRenderEnabled(not TheSim:GetDebugPhysicsRenderEnabled())
        end
    end
    return true
end)

AddGameDebugKey(KEY_I, function()
    if TheInput:IsKeyDown(KEY_SHIFT) and not TheInput:IsKeyDown(KEY_CTRL) then
        c_spawn("dragonfly")
    elseif TheInput:IsKeyDown(KEY_CTRL) and not TheInput:IsKeyDown(KEY_SHIFT) then
        c_spawn("lavae")
    elseif TheInput:IsKeyDown(KEY_CTRL) and TheInput:IsKeyDown(KEY_SHIFT) then
        local lavae = {}
        for k, v in pairs(Ents) do
            if v.prefab == "lavae" then
                table.insert(lavae, v)
            end
        end

        for k,v in pairs(lavae) do
            v.LockTargetFn(v, ConsoleCommandPlayer())
        end
    end

    return true
end)

-------------------------------------------MOUSE HANDLING

local function DebugRMB(x,y)
    local MouseCharacter = TheInput:GetWorldEntityUnderMouse()
    local pos = TheInput:GetWorldPosition()

    if TheInput:IsKeyDown(KEY_CTRL) and
       TheInput:IsKeyDown(KEY_SHIFT) and
       c_sel() and c_sel().prefab then
        local spawn = c_spawn(c_sel().prefab)
        if spawn then
            spawn.Transform:SetPosition(pos:Get())
        end
   elseif TheInput:IsKeyDown(KEY_CTRL) then
        if MouseCharacter then
            if MouseCharacter.components.health and MouseCharacter ~= DebugKeyPlayer() then
                MouseCharacter.components.health:Kill()
            elseif MouseCharacter.Remove then
                MouseCharacter:Remove()
            end
        else
            local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 5)
            for k,v in pairs(ents) do
                if v.components.health and v ~= DebugKeyPlayer() then
                    v.components.health:Kill()
                end
            end
        end
    elseif TheInput:IsKeyDown(KEY_ALT) then

        print(DebugKeyPlayer():GetAngleToPoint(pos))

    elseif TheInput:IsKeyDown(KEY_SHIFT) then
        if MouseCharacter then
            SetDebugEntity(MouseCharacter)
        else
            SetDebugEntity(TheWorld)
        end
    end
end

local function DebugLMB(x,y)
    if TheSim:IsDebugPaused() then
        SetDebugEntity(TheInput:GetWorldEntityUnderMouse())
    end
end

function DoDebugMouse(button, down,x,y)
    if not down then return false end
    
    if button == MOUSEBUTTON_RIGHT then
        DebugRMB(x,y)
    elseif button == MOUSEBUTTON_LEFT then
        DebugLMB(x,y)   
    end
    
end

function DoReload()
    dofile("scripts/reload.lua")
end
