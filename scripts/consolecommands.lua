-- not local - debugkeys use it too
function ConsoleCommandPlayer()
    return (c_sel() and c_sel():HasTag("player") and c_sel()) or ThePlayer or AllPlayers[1]
end

local function Spawn(prefab)
    --TheSim:LoadPrefabs({prefab})
    return SpawnPrefab(prefab)
end

local function ConsoleWorldPosition()
    return TheInput.overridepos or TheInput:GetWorldPosition()
end

local function ConsoleWorldEntityUnderMouse()
    if TheInput.overridepos == nil then
        return TheInput:GetWorldEntityUnderMouse()
    else
        local x, y, z = TheInput.overridepos:Get()
        local ents = TheSim:FindEntities(x, y, z, 1)
        for i, v in ipairs(ents) do
            if v.entity:IsVisible() then
                return v
            end
        end
    end
end

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Console Functions -- These are simple helpers made to be typed at the console.
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- Show server announcements:
-- To send a one time announcement:   c_announce(msg)
-- To repeat a periodic announcement: c_announce(msg, interval)
-- To cancel a periodic announcement: c_announce()
function c_announce(msg, interval, category)
    if msg == nil then
        if TheWorld.__announcementtask ~= nil then
            TheWorld.__announcementtask:Cancel()
            TheWorld.__announcementtask = nil
        end
    elseif interval == nil then
        TheNet:Announce(msg, nil, nil, category)
    else
        if TheWorld.__announcementtask ~= nil then
            TheWorld.__announcementtask:Cancel()
        end
        TheWorld.__announcementtask = TheWorld:DoPeriodicTask(interval, function() TheNet:Announce(msg, nil, nil, category) end, 0)
    end
end

local function doreset()
    StartNextInstance({
        reset_action = RESET_ACTION.LOAD_SLOT,
        save_slot = SaveGameIndex:GetCurrentSaveSlot()
    })
end


-- Roll back *count* number of saves (default 1)
function c_rollback(count)
    if TheWorld ~= nil and TheWorld.ismastersim then
        count = math.max(0, count or 1) + 1
        TheNet:TruncateSnapshots(TheWorld.meta.session_identifier, -count)
        doreset()
    end
end

function c_save()
    if TheWorld ~= nil and TheWorld.ismastersim then
        TheWorld:PushEvent("save")
    end
end

-- Spawn At Cursor and select the new ent
-- Has a gimpy short name so it's easier to type from the console
function c_spawn(prefab, count)
    count = count or 1
    local inst = nil
    for i = 1, count do
        inst = DebugSpawn(prefab)
        inst.Transform:SetPosition(ConsoleWorldPosition():Get())
    end
    SetDebugEntity(inst)
    SuUsed("c_spawn_"..prefab , true)
    return inst
end

-- Shutdown the application, optionally close with out saving (saves by default)
function c_shutdown(save)
    print("c_shutdown", save)
    if save == false or TheWorld == nil then
        Shutdown()
    elseif TheWorld.ismastersim then
        for i, v in ipairs(AllPlayers) do
            v:OnDespawn()
        end
        TheSystemService:EnableStorage(true)
        SaveGameIndex:SaveCurrent(Shutdown, true)
    else
        SerializeUserSession(ThePlayer)
        Shutdown()
    end
end

-- Restart the server, optionally save before restarting (does not save by default)
function c_reset(save)
    if not InGamePlay() then
        StartNextInstance()
    elseif TheWorld ~= nil and TheWorld.ismastersim then
        if save then
            for i, v in ipairs(AllPlayers) do
                v:OnDespawn()
            end
            TheSystemService:EnableStorage(true)
            SaveGameIndex:SaveCurrent(doreset, true)
        else
            doreset()
        end
    end
end

-- Permanently delete the game world, regenerates a new world afterwards
-- NOTE: It is not recommended to use this instead of c_regenerateworld,
--       unless you need to regenerate only one shard in a cluster
function c_regenerateshard()
    if TheWorld ~= nil and TheWorld.ismastersim then
        SaveGameIndex:DeleteSlot(
            SaveGameIndex:GetCurrentSaveSlot(),
            doreset,
            true -- true causes world gen options to be preserved
        )
    end
end 

-- Permanently delete all game worlds in a server cluster, regenerates new worlds afterwards
-- NOTE: This will not work properly for any shard that is offline or in a loading state
function c_regenerateworld()
    if TheWorld ~= nil and TheWorld.ismastersim then
        TheNet:SendWorldResetRequestToServer()
    end
end

-- Remotely execute a lua string
function c_remote( fnstr )
    local x, y, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
    TheNet:SendRemoteExecute(fnstr, x, z)
end

-- c_despawn helper
local function dodespawn(player)
    if TheWorld ~= nil and TheWorld.ismastersim then
        --V2C: #spawn #despawn
        --     This was where we used to announce player left.
        --     Now we announce it when you actually disconnect
        --     but not during a shard migration disconnection.
        --TheNet:Announce(player:GetDisplayName().." "..STRINGS.UI.NOTIFICATION.LEFTGAME, player.entity, true, "leave_game")

        --Delete must happen when the player is actually removed
        --This is currently handled in playerspawner listening to ms_playerdespawnanddelete
        TheWorld:PushEvent("ms_playerdespawnanddelete", player)
    end
end

-- Despawn a player, returning to character select screen
function c_despawn(player)
    if TheWorld ~= nil and TheWorld.ismastersim then
        player = player or ConsoleCommandPlayer()
        if player ~= nil and player:IsValid() then
            --Queue it because remote command may currently be overriding
            --ThePlayer, which will get stomped during delete
            player:DoTaskInTime(0, dodespawn)
        end
    end
end

-- Return a listing of currently active players
function c_listplayers()
    local isdedicated = TheNet:GetServerIsDedicated()
    local index = 1
    for i, v in ipairs(TheNet:GetClientTable()) do
        if not isdedicated or v.performance == nil then
            print(string.format("%s[%d] %s <%s>", v.admin and "*" or " ", index, v.name, v.prefab))
            index = index + 1
        end
    end
end

-- Return a listing of AllPlayers table
function c_listallplayers()
    for i, v in ipairs(AllPlayers) do
        print(string.format("[%d] %s <%s>", i, v.name, v.prefab))
    end
end

-- Get the currently selected entity, so it can be modified etc.
-- Has a gimpy short name so it's easier to type from the console
function c_sel()
    return GetDebugEntity()
end

function c_select(inst)
    if not inst then
        inst = ConsoleWorldEntityUnderMouse()
    end
    print("Selected "..tostring(inst or "<nil>") )
    SetDebugEntity(inst)
    return inst
end

-- Print the (visual) tile under the cursor
function c_tile()
    local s = ""

    local map = TheWorld.Map
    local mx, my, mz = ConsoleWorldPosition():Get()
    local tx, ty = map:GetTileCoordsAtPoint(mx,my,mz)
    s = s..string.format("world[%f,%f,%f] tile[%d,%d] ", mx,my,mz, tx,ty)

    local tile = map:GetTileAtPoint(ConsoleWorldPosition():Get())
    for k,v in pairs(GROUND) do
        if v == tile then
            s = s..string.format("ground[%s] ", k)
            break
        end
    end

    print(s)
end

-- Apply a scenario script to the selection and run it.
function c_doscenario(scenario)
    local inst = GetDebugEntity()
    if not inst then
        print("Need to select an entity to apply the scenario to.")
        return
    end
    if inst.components.scenariorunner then
        inst.components.scenariorunner:ClearScenario()
    end

    -- force reload the script -- this is for testing after all!
    package.loaded["scenarios/"..scenario] = nil

    inst:AddComponent("scenariorunner")
    inst.components.scenariorunner:SetScript(scenario)
    inst.components.scenariorunner:Run()
    SuUsed("c_doscenario_"..scenario, true)
end


-- Some helper shortcut functions
function c_sel_health()
    if c_sel() then
        local health = c_sel().components.health
        if health then
            return health
        else
            print("Gah! Selection doesn't have a health component!")
            return
        end
    else
        print("Gah! Need to select something to access it's components!")
    end
end

function c_sethealth(n)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.health ~= nil and not player:HasTag("playerghost") then
        SuUsed("c_sethealth", true)
        player.components.health:SetPercent(n)
    end
end

function c_setminhealth(n)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.health ~= nil and not player:HasTag("playerghost") then
        SuUsed("c_minhealth", true)
        player.components.health:SetMinHealth(n)
    end
end

function c_setsanity(n)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.sanity ~= nil and not player:HasTag("playerghost") then
        SuUsed("c_setsanity", true)
        player.components.sanity:SetPercent(n)
    end
end

function c_sethunger(n)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.hunger ~= nil and not player:HasTag("playerghost") then
        SuUsed("c_sethunger", true)
        player.components.hunger:SetPercent(n)
    end
end

function c_setbeaverness(n)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.beaverness ~= nil and not player:HasTag("playerghost") then
        SuUsed("c_setbeaverness", true)
        player.components.beaverness:SetPercent(n)
    end
end

function c_setmoisture(n)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.moisture ~= nil and not player:HasTag("playerghost") then
        SuUsed("c_setmoisture", true)
        player.components.moisture:SetPercent(n)
    end
end

function c_settemperature(n)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.temperature ~= nil and not player:HasTag("playerghost") then
        SuUsed("c_settemperature", true)
        player.components.temperature:SetTemperature(n)
    end
end

-- Work in progress direct connect code.
-- Currently, to join an online server you must authenticate first.
-- In the future this authentication will be taken care of for you.
function c_connect( ip, port, password )
    local start_worked = TheNet:StartClient( ip, port, 0, password )
    if start_worked then
        DisableAllDLC()
    end
    ShowCancelTip()
    ShowLoading()
    TheFrontEnd:Fade(false, 1)
    return start_worked
end

-- Put an item(s) in the player's inventory
function c_give(prefab, count)
    count = count or 1

    local MainCharacter = ConsoleCommandPlayer()
    
    if MainCharacter then
        for i=1,count do
            local inst = DebugSpawn(prefab)
            if inst then
print("giving ",inst)
                MainCharacter.components.inventory:GiveItem(inst)
                SetDebugEntity(inst)
                SuUsed("c_give_" .. inst.prefab)
            end
        end
    end
end

function c_mat(recname)
    local player = ConsoleCommandPlayer()
    local recipe = AllRecipes[recname]
    if player.components.inventory and recipe then
      for ik, iv in pairs(recipe.ingredients) do
            for i = 1, iv.amount do
                local item = SpawnPrefab(iv.type)
                player.components.inventory:GiveItem(item)
                SuUsed("c_mat_" .. iv.type , true)
            end
        end
    end
end

function c_pos(inst)
    return inst and Point(inst.Transform:GetWorldPosition())
end

function c_printpos(inst)
    print(c_pos(inst))
end

function c_teleport(x, y, z, inst)
    inst = inst or ConsoleCommandPlayer()
    if inst then
        inst.Transform:SetPosition(x, y, z)
        SuUsed("c_teleport", true)
    end
end

function c_move(inst)
    inst = inst or c_sel()
    inst.Transform:SetPosition(ConsoleWorldPosition():Get())
    SuUsed("c_move", true)
end

function c_goto(dest, inst)
    inst = inst or ConsoleCommandPlayer()
    if inst.Physics ~= nil then
        inst.Physics:Teleport(dest.Transform:GetWorldPosition())
    else
        inst.Transform:SetPosition(dest.Transform:GetWorldPosition())
    end
    SuUsed("c_goto", true)
    return dest
end

function c_inst(guid)
    return Ents[guid]
end

function c_list(prefab)
    local x,y,z = ConsoleCommandPlayer().Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 9001)
    for k,v in pairs(ents) do
        if v.prefab == prefab then
            print(string.format("%s {%2.2f, %2.2f, %2.2f}", tostring(v), v.Transform:GetWorldPosition()))
        end
    end
end

function c_listtag(tag)
    local tags = {tag}
    local x,y,z = ConsoleCommandPlayer().Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 9001, tags)
    for k,v in pairs(ents) do
        print(string.format("%s {%2.2f, %2.2f, %2.2f}", tostring(v), v.Transform:GetWorldPosition()))
    end
end

local lastroom = -1
function c_gotoroom(roomname, inst)
    inst = inst or ConsoleCommandPlayer()

    local found = nil
    local foundid = nil
    local reallowest = nil
    local reallowestid = nil
    local count = 0

    print("Finding room containing",roomname)

    roomname = string.lower(roomname)

    for i, node in ipairs(TheWorld.topology.nodes) do
        if string.lower(TheWorld.topology.ids[i]):find(roomname) then
            if reallowest == nil then
                reallowest = node
                reallowestid = i
            end
            count = count + 1
            if i > lastroom then
                found = node
                foundid = i
                break
            end
        end
    end

    if found == nil and reallowest ~= nil then
        found = reallowest
        foundid = reallowestid
    end

    if found ~= nil then
        print("Going to ", TheWorld.topology.ids[foundid], "("..count..")")
        c_teleport(found.cent[1],0,found.cent[2],inst)
        lastroom = foundid
    else
        print("Couldn't find a matching room.")
    end
end

local lastfound = -1
local lastprefab = nil
function c_findnext(prefab, radius, inst)
    inst = inst or ConsoleCommandPlayer() or TheWorld
    prefab = prefab or lastprefab
    lastprefab = prefab

    local trans = inst.Transform
    local found = nil
    local foundlowestid = nil
    local reallowest = nil
    local reallowestid = nil
    local reallowestidx = -1

    print("Finding a ",prefab)

    local x,y,z = trans:GetWorldPosition()
    local ents = {}
    if radius == nil then
        ents = Ents
    else
        -- note: this excludes CLASSIFIED
        ents = TheSim:FindEntities(x,y,z, radius)
    end
    local total = 0
    local idx = -1
    for k,v in pairs(ents) do
        if v ~= inst and v.prefab == prefab then
            total = total+1
            if v.GUID > lastfound and (foundlowestid == nil or v.GUID < foundlowestid) then
                idx = total
                found = v
                foundlowestid = v.GUID
            end
            if not reallowestid or v.GUID < reallowestid then
                reallowest = v
                reallowestid = v.GUID
                reallowestidx = total
            end
        end
    end
    if not found then
        found = reallowest
        idx = reallowestidx
    end
    if not found then
        print("Could not find any objects matching '"..prefab.."'.")
        lastfound = -1
    else
        print(string.format("Found %s (%d/%d)", found.GUID, idx, total ))
        lastfound = found.GUID
    end
    return found
end

function c_godmode()
    local player = ConsoleCommandPlayer()
    if player ~= nil then
        SuUsed("c_godmode", true)
        if player:HasTag("playerghost") then
            player:PushEvent("respawnfromghost")
            print("Reviving "..player.name.." from ghost.")
            return
        elseif player.components.health ~= nil then
            local godmode = player.components.health.invincible
            player.components.health:SetInvincible(not godmode)
            print("God mode: "..tostring(not godmode))
        end
    end
end

function c_supergodmode()
    local player = ConsoleCommandPlayer()
    if player ~= nil then
        SuUsed("c_supergodmode", true)
        if player:HasTag("playerghost") then
            player:PushEvent("respawnfromghost")
            print("Reviving "..player.name.." from ghost.")
            return
        elseif player.components.health ~= nil then
            local godmode = player.components.health.invincible
            player.components.health:SetInvincible(not godmode)
            c_sethealth(1)
            c_setsanity(1)
            c_sethunger(1)
            c_settemperature(25)
            c_setmoisture(0)
            print("God mode: "..tostring(not godmode))
        end
    end
end

function c_find(prefab, radius, inst)
    inst = inst or ConsoleCommandPlayer()
    radius = radius or 9001

    local trans = inst.Transform
    local found = nil
    local founddistsq = nil

    local x,y,z = trans:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, radius)
    for k,v in pairs(ents) do
        if v ~= inst and v.prefab == prefab then
            if not founddistsq or inst:GetDistanceSqToInst(v) < founddistsq then 
                found = v
                founddistsq = inst:GetDistanceSqToInst(v)
            end
        end
    end
    return found
end

function c_findtag(tag, radius, inst)
    return GetClosestInstWithTag(tag, inst or ConsoleCommandPlayer(), radius or 1000)
end

function c_gonext(name)
    return c_goto(c_findnext(name))
end

function c_printtextureinfo( filename )
    TheSim:PrintTextureInfo( filename )
end

function c_simphase(phase)
    TheWorld:PushEvent("phasechange", {newphase = phase})
end

function c_anim(animname, loop)
    if GetDebugEntity() then
        GetDebugEntity().AnimState:PlayAnimation(animname, loop or false)
    else
        print("No DebugEntity selected")
    end
end

function c_light(c1, c2, c3)
    TheSim:SetAmbientColour(c1, c2 or c1, c3 or c1)
end

function c_spawn_ds(prefab, scenario)
    local inst = c_spawn(prefab)
    if not inst then
        print("Need to select an entity to apply the scenario to.")
        return
    end

    if inst.components.scenariorunner then
        inst.components.scenariorunner:ClearScenario()
    end

    -- force reload the script -- this is for testing after all!
    package.loaded["scenarios/"..scenario] = nil

    inst:AddComponent("scenariorunner")
    inst.components.scenariorunner:SetScript(scenario)
    inst.components.scenariorunner:Run()
end


function c_countprefabs(prefab, noprint)
    local count = 0
    for k,v in pairs(Ents) do
        if v.prefab == prefab then
            count = count + 1
        end
    end
    if not noprint then
        print("There are ", count, prefab.."s in the world.")
    end
    return count
end

function c_counttagged(tag, noprint)
    local count = 0
    for k,v in pairs(Ents) do
        if v:HasTag(tag) then
            count = count + 1
        end
    end
    if not noprint then
        print("There are ", count, tag.."-tagged ents in the world.")
    end
    return count
end

function c_countallprefabs()
    local total = 0
    local counted = {}
    for k,v in pairs(Ents) do
        if v.prefab and not table.findfield(counted, v.prefab) then 
            local num = c_countprefabs(v.prefab, true)
            counted[v.prefab] = num
            total = total + num
        end
    end

    local function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end

    for k,v in pairsByKeys(counted) do
        print(k, v)
    end

    print("There are ", GetTableSize(counted), " different prefabs in the world, ", total, " in total.")
end

function c_speedmult(multiplier)
    local inst = ConsoleCommandPlayer()
    if inst ~= nil then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "c_speedmult", multiplier)
    end
end

function c_testruins()
    ConsoleCommandPlayer().components.builder:UnlockRecipesForTech({SCIENCE = 2, MAGIC = 2})
    c_give("log", 20)
    c_give("flint", 20)
    c_give("twigs", 20)
    c_give("cutgrass", 20)
    c_give("lightbulb", 5)
    c_give("healingsalve", 5)
    c_give("batbat")
    c_give("icestaff")
    c_give("firestaff")
    c_give("tentaclespike")
    c_give("slurtlehat")
    c_give("armorwood")
    c_give("minerhat")
    c_give("lantern")
    c_give("backpack")
end


function c_teststate(state)
    c_sel().sg:GoToState(state)
end

function c_combatgear()
    local function give(prefab)
        if ConsoleCommandPlayer() then
            local inst = DebugSpawn(prefab)
            if inst then
                print("giving ",inst)
                ConsoleCommandPlayer().components.inventory:GiveItem(inst)
                ConsoleCommandPlayer().components.inventory:Equip(inst)
                SuUsed("c_give_" .. inst.prefab)
            end
        end
    end
    give("armorwood")
    give("footballhat")
    give("spear")
end

function c_combatsimulator(prefab, count, force)
    count = count or 1

    local x,y,z = ConsoleWorldPosition():Get()
    local MakeBattle = nil
    MakeBattle = function()
        local creature = DebugSpawn(prefab)
        creature:ListenForEvent("onremove", MakeBattle)
        creature.Transform:SetPosition(x,y,z)
        if creature.components.knownlocations then
            creature.components.knownlocations:RememberLocation("home", {x=x,y=y,z=z})
        end
        if force then
            local target = FindEntity(creature, 20, nil, {"_combat"})
            if target then
                creature.components.combat:SetTarget(target)
            end
            creature:ListenForEvent("droppedtarget", function()
                local target = FindEntity(creature, 20, nil, {"_combat"})
                if target then
                    creature.components.combat:SetTarget(target)
                end
            end)
        end
    end

    for i=1,count do
        MakeBattle()
    end
end

function c_dump()
    local ent = GetDebugEntity()
    if not ent then
        ent = ConsoleWorldEntityUnderMouse()
    end
    DumpEntity(ent)
end

function c_dumpseasons()
    local str = TheWorld.net.components.seasons:GetDebugString()
    print(str)
end

function c_dumpworldstate()
    print("")
    print("//======================== DUMPING WORLD STATE ========================\\\\")
    print("\n"..TheWorld.components.worldstate:Dump())
    print("\\\\=====================================================================//")
    print("")
end

function c_worldstatedebug()
    WORLDSTATEDEBUG_ENABLED = not WORLDSTATEDEBUG_ENABLED
end

function c_makeinvisible()
    local player = ConsoleCommandPlayer()
    player:AddTag("debugnoattack")
    print("Has debugnoattack tag?", player, player:HasTag("debugnoattack"))
end

function c_selectnext(name)
    return c_select(c_findnext(name))
end

function c_selectnear(prefab, rad)
    local player = ConsoleCommandPlayer()
    local x,y,z = player.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, rad or 30)
    local closest = nil
    local closeness = nil
    for k,v in pairs(ents) do
        if v.prefab == prefab then
            if closest == nil or player:GetDistanceSqToInst(v) < closeness then
                closest = v
                closeness = player:GetDistanceSqToInst(v)
            end
        end
    end
    if closest then
        c_select(closest)
    end
end


function c_summondeerclops()
    local player = ConsoleCommandPlayer()
    if player then 
        TheWorld.components.deerclopsspawner:SummonMonster(player)
    end
end

function c_summonbearger()
    local player = ConsoleCommandPlayer()
    print("Summoning bearger for player ", player)
    if player then 
        TheWorld.components.beargerspawner:SummonMonster(player)
    end
end

function c_gatherplayers()
    local x,y,z = ConsoleWorldPosition():Get()
    for k,v in pairs(AllPlayers) do
        v.Transform:SetPosition(x,y,z)
    end
end

function c_speedup()
    TheSim:SetTimeScale(TheSim:GetTimeScale() *10)
    print("Speed is now ", TheSim:GetTimeScale())
end

function c_skip(num)
    num = num or 1
    LongUpdate(TUNING.TOTAL_DAY_TIME * num)
end

function c_togglevotekick()
	TheWorld.net.components.voter:ToggleVoteKick()
end

function c_groundtype()
    local index, table = ConsoleCommandPlayer():GetCurrentTileType()
    print("Ground type is ", index)

    for k,v in pairs(table) do 
        print(k,v)
    end
end

function c_searchprefabs(str)
    local regex = ""
    for i=1,str:len() do
        if i > 1 then
            regex = regex .. ".*"
        end
        regex = regex .. str:sub(i,i)
    end
    local res = {}
    for prefab,v in pairs(Prefabs) do
        local s,f = string.lower(prefab):find(regex)
        if s ~= nil then
            -- Tightest match first, with a bias towards the match near the beginning, and shorter prefab names
            local weight = (f-s) - (100-s)/100 - (100-prefab:len())/100
            table.insert(res, {name=prefab,weight=weight})
        end
    end

    table.sort(res, function(a,b) return a.weight < b.weight end)

    if #res == 0 then
        print("Found no prefabs matching "..str)
    elseif #res == 1 then
        print("Found a prefab called "..res[1].name)
        return res[1].name
    else
        print("Found "..tostring(#res).." matches:")
        for i,v in ipairs(res) do
            print("\t"..v.name)
        end
        return res[1].name
    end
end

function c_maintainhealth(player, percent)
    player = player or ConsoleCommandPlayer()
    if player.debug_maintainhealthtask ~= nil then
        player.debug_maintainhealthtask:Cancel()
    end
    player.debug_maintainhealthtask = player:DoPeriodicTask(3, function(inst) inst.components.health:SetPercent(percent or 1) end)
end

function c_maintainsanity(player, percent)
    player = player or ConsoleCommandPlayer()
    if player.debug_maintainsanitytask ~= nil then
        player.debug_maintainsanitytask:Cancel()
    end
    player.debug_maintainsanitytask = player:DoPeriodicTask(3, function(inst) inst.components.sanity:SetPercent(percent or 1) end)
end

function c_maintainhunger(player, percent)
    player = player or ConsoleCommandPlayer()
    if player.debug_maintainhungertask ~= nil then
        player.debug_maintainhungertask:Cancel()
    end
    player.debug_maintainhungertask = player:DoPeriodicTask(3, function(inst) inst.components.hunger:SetPercent(percent or 1) end)
end

function c_maintaintemperature(player, temp)
    player = player or ConsoleCommandPlayer()
    if player.debug_maintaintemptask ~= nil then
        player.debug_maintaintemptask:Cancel()
    end
    player.debug_maintaintemptask = player:DoPeriodicTask(3, function(inst) inst.components.temperature:SetTemperature(temp or 25) end)
end

function c_maintainmoisture(player, percent)
    player = player or ConsoleCommandPlayer()
    if player.debug_maintainmoisturetask ~= nil then
        player.debug_maintainmoisturetask:Cancel()
    end
    player.debug_maintainmoisturetask = player:DoPeriodicTask(3, function(inst) inst.components.moisture:SetPercent(percent or 0) end)
end

-- Use this instead of godmode if you still want to see deltas and things
function c_maintainall(player)
    player = player or ConsoleCommandPlayer()
    c_maintainhealth(player)
    c_maintainsanity(player)
    c_maintainhunger(player)
    c_maintaintemperature(player)
    c_maintainmoisture(player)
end

function c_cancelmaintaintasks(player)
    player = player or ConsoleCommandPlayer()
    if player.debug_maintainhealthtask ~= nil then
        player.debug_maintainhealthtask:Cancel()
        player.debug_maintainhealthtask = nil
    end
    if player.debug_maintainsanitytask ~= nil then
        player.debug_maintainsanitytask:Cancel()
        player.debug_maintainsanitytask = nil
    end
    if player.debug_maintainhungertask ~= nil then
        player.debug_maintainhungertask:Cancel()
        player.debug_maintainhungertask = nil
    end
    if player.debug_maintaintemptask ~= nil then
        player.debug_maintaintemptask:Cancel()
        player.debug_maintaintemptask = nil
    end
    if player.debug_maintainmoisturetask ~= nil then
        player.debug_maintainmoisturetask:Cancel()
        player.debug_maintainmoisturetask = nil
    end
end

function c_removeallwithtags(...)
    local count = 0
    for k,ent in pairs(Ents) do
        for i,tag in ipairs(arg) do
            if ent:HasTag(tag) then
                ent:Remove()
                count = count + 1
                break
            end
        end
    end
    print("removed",count)
end

function c_netstats()
    local stats = TheNet:GetNetworkStatistics()
    if not stats then print("No Netstats yet") end

    for k,v in pairs(stats) do
        print(k.." -> "..tostring(v))
    end
end

function c_removeall(name)
    local count = 0
    for k,ent in pairs(Ents) do
        if ent.prefab == name then
            ent:Remove()
            count = count + 1
        end
    end
    print("removed",count)
end

function c_forcecrash(unique)
    local path = "a"
    if unique then
        path = string.random(10, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUV")
    end

    if TheWorld then
        TheWorld:DoTaskInTime(0,function() _G[path].b = 0 end)
    elseif TheFrontEnd then
        TheFrontEnd.screenroot.inst:DoTaskInTime(0,function() _G[path].b = 0 end)
    end
end

function c_migrationportal(worldId, portalId)
    local inst = c_spawn("migration_portal")
    if portalId then
        inst.components.worldmigrator:SetRecievedPortal( worldId, portalId )
    else
        inst.components.worldmigrator:SetDestinationWorld( worldId )
    end
end

function c_goadventuring()
    c_give("lantern")
    c_give("minerhat")
    c_give("axe")
    c_give("pickaxe")
    c_give("footballhat")
    c_give("armorwood")
    c_give("spear")
    c_give("carrot_cooked", 10)
    c_give("berries_cooked", 10)
    c_give("smallmeat_dried", 5)
    c_give("flowerhat")
    c_give("cutgrass", 20)
    c_give("twigs", 20)
    c_give("log", 20)
    c_give("flint", 20)
    c_spawn("backpack")
end

function c_sounddebug()
    if not package.loaded["debugsounds"] then
        require "debugsounds"
    end
    SOUNDDEBUG_ENABLED = true
    TheSim:SetDebugRenderEnabled(true)
end

function c_migrateto(worldId, portalId)
    portalId = portalId or 1
    TheWorld:PushEvent(
        "ms_playerdespawnandmigrate",
        { player = ConsoleCommandPlayer(), portalid = portalId, worldid = worldId }
    )
end

function c_debugshards()
    local count = 0
    print("Connected shards:")
    for k,v in pairs(Shard_GetConnectedShards()) do
        print("\t",k,v)
        count = count + 1
    end
    print(count, "shards")
    count = 0
    print("Known portals:")
    for i,v in ipairs(ShardPortals) do
        print("\t",v,v.components.worldmigrator:GetDebugString())
        count = count + 1
    end
    print(count, "known portals")
    count = 0
    print("Portal targets actually available:")
    for i,v in ipairs(ShardPortals) do
        print("\t",v,Shard_IsWorldAvailable(v.components.worldmigrator.linkedWorld))
    end
    print("Portals not known:")
    local portals = {}
    for k,v in pairs(Ents) do
        if v.components and v.components.worldmigrator then
            table.insert(portals, v)
        end
    end
    for i,v in ipairs(portals) do
        local found = false
        for i2,v2 in ipairs(ShardPortals) do
            if v == v2 then
                found = true
                break
            end
        end
        if not found then
            print("\t",v)
            count = count + 1
        end
    end
    print(count, "unknown portals")
    count = 0
end

function c_reregisterportals()
    local shards = Shard_GetConnectedShards()
    for i,v in ipairs(ShardPortals) do
        v.components.worldmigrator:SetDestinationWorld(next(shards))
    end
end

function c_repeatlastcommand()
    local history = GetConsoleHistory()
    if #history > 0 then
        if history[#history] == "c_repeatlastcommand()" then
            -- top command is this one, so we want the second last command
            history[#history] = nil
        end
        ExecuteConsoleCommand(history[#history])
    end
end
