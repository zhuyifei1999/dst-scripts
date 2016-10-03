--------------------------------------------------------------------------
--[[ PrefabSwapManager class definition ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Debug logs ]]
--------------------------------------------------------------------------

--DEBUG LOGS

--To turn ON: 1. replace all "[[#DBGLOG" with "#DEBUG_LOG_BEGIN"
--            2. replace all "#DBGLOG]]" with "#DEBUG_LOG_END"

--To turn OFF: 1. replace all "#DEBUG_LOG_BEGIN" with "[[#DBGLOG"
--             2. replace all "#DEBUG_LOG_END"   with "#DBGLOG]]"

return Class(function(self, inst)

assert(TheWorld.ismastersim, "PrefabSwapManager should not exist on client")

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local easing = require("easing")
local prefabswap_list = require("prefabswap_list")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local BASE_RADIUS = 20
local EXCLUDE_RADIUS = 3
local BASE_AREA =  BASE_RADIUS * BASE_RADIUS * PI
local UPDATE_ENTS_PER_FRAME = 30

local MIN_PLAYER_DISTANCE = 64 *1.2
--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _new_year = "winter" --next season after default "autumn"
local _changes = {}
local _petrification = nil
local _newents = {}
local _ents1 = {}
local _ents2 = {}
local _tasks = {}
local _next_task_id = 0
local _updating = false
local _idle_since_swap = false

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function StartUpdating()
    if not _updating then
        _updating = true
        inst:StartUpdatingComponent(self)
        --[[#DBGLOG
        print("PrefabSwapManager started")
        --#DBGLOG]]
    end
    _idle_since_swap = false
end

local function StopUpdating()
    if _updating then
        _updating = false
        inst:StopUpdatingComponent(self)
        --Clear petrification queue once we're done updating
        _petrification = nil
        --[[#DBGLOG
        print("PrefabSwapManager stopped")
        --#DBGLOG]]
    end
end

local function setUpChanges(swapIn, swapOut)
    -- a new prefab coming in may have several things it wants to do.. spawn in
    -- several new prefab types, run some event functions etc.

    -- also, there may be a number of old prefabs that need to dissapear and in several ways.
    -- for example: first they may need ot get sick, and then they need to die off.

    -- this function processes the prefabswap_list data into blocks that each do one piece of
    -- those previously mentioned tasks. They

    -- sets the new prefab to start spawing in.
    if swapIn then
        if swapIn.trigger and swapIn.trigger.prefab_spawns then
            local inSet = {}
            inSet.triggers = {}
            if swapIn.trigger.season then
                table.insert(inSet.triggers,swapIn.trigger.season)
            end
            if swapIn.trigger.event then
                table.insert(inSet.triggers,swapIn.trigger.event)
            end

            inSet.state = "spawn_in"
            inSet.swap = swapIn

            table.insert(_changes, inSet)
        end

        -- sets new events to happen
        if swapIn.trigger and swapIn.trigger.prefab_events then
            local inSet2 = {}
            inSet2.triggers = {}
            if swapIn.trigger.season then
                table.insert(inSet2.triggers,swapIn.trigger.season)
            end
            if swapIn.trigger.event then
                table.insert(inSet2.triggers,swapIn.trigger.event)
            end

            inSet2.name = swapIn.name
            inSet2.state = "spawn_event"

            table.insert(_changes, inSet2)
        end
    end
    -- sets the old perfabs to start showing that they will leave
    if swapOut then
        if swapOut.trigger and swapOut.trigger.prefab_disease then
            local outSet = {}
            outSet.triggers = {}
            if swapIn.trigger.season then
                table.insert(outSet.triggers,swapIn.trigger.season)
            end
            if swapIn.trigger.event then
                table.insert(outSet.triggers,swapIn.trigger.event)
            end      

            outSet.state = "signal_out"
            outSet.swap = swapOut

            table.insert(_changes, outSet)
        end
    end
end


local function OnNewYear(self)
-- statuses
--  "active"
--  "fading"
--  "inactive"

    local swapBank = TheWorld.prefabswapstatus
    if swapBank  then

        local potentials = {}

        local potentialIndex = 1
        local currents = {}

        for i,category in pairs(swapBank)do
            for k,swap in ipairs(category)do
                if swap.status == "active" then
                    currents[i] = {categoryIndex=i,swapIndex=k}
                else
                    if swap.trigger then
                        if not potentials[potentialIndex] then
                            potentials[potentialIndex] = {}
                        end
                        table.insert(potentials[potentialIndex],{categoryIndex=i,swapIndex=k})

                        potentialIndex =  potentialIndex + 1
                    end
                end
            end
        end

        local next_swaps = prefabswap_list:getNextSwaps()

        if next_swaps then
            -- use next_spawns, if it exists, to force set this years changes
            for category, newswap in pairs(next_swaps) do

                for k, v in pairs(swapBank) do
                    if k == category then

                        local current = nil
                        if currents[k] then
                            current = currents[k]
                        end

                        local newPrefabSet = nil
                        for i, set in ipairs(v) do

                            if  set.name == newswap and swapBank[ current.categoryIndex ][ current.swapIndex ].name ~= newswap then
                                swapBank[ current.categoryIndex ][ current.swapIndex ].status = "inactive" 
                                print("NEW PREFAB =", set.name )
                                if not set.noActive then
                                    set.status = "active"
                                end
                                newPrefabSet = set

                                local currentPrefabset = nil
                                if current then
                                    currentPrefabset = swapBank[ current.categoryIndex ][ current.swapIndex ]
                                end

                                setUpChanges( newPrefabSet, currentPrefabset )
                            end
                        end
                    end
                end
            end
            prefabswap_list.setNextSwaps(nil)
        else
            -- no next_swaps, do the usual random selection
            for i = 1, TUNING.NUM_PREFAB_SWAPS do

                if #potentials > 0 then
                    -- only choose from a category once, then it's removed.

                    local categorySelectionIndex = math.random(#potentials)

                    local swapSelectionIndex = math.random(#potentials[categorySelectionIndex])

                    local selected = potentials[categorySelectionIndex][swapSelectionIndex]

                    local current = nil
                    if currents[selected.categoryIndex] then
                        current = currents[selected.categoryIndex]
                    --    swapBank[ current.categoryIndex ][ current.swapIndex ].status = "inactive"
                    end
                    -- SET UP THE TRIGGER FOR WHEN IT SHOULD START GETTING SICK
                    -- SET UP TRIGGER FOR WHEN IT SHOULD THEN BE REMOVED

                    -- turn on the new prefab
                    print("NEW PREFAB =", swapBank[ selected.categoryIndex ][ selected.swapIndex ].name )

                    if not swapBank[ selected.categoryIndex ][ selected.swapIndex ].noActive then
                   --     swapBank[ selected.categoryIndex ][ selected.swapIndex ].status = "active"
                    end

                    local newPrefabSet = swapBank[ selected.categoryIndex ][ selected.swapIndex ]

                    local currentPrefabset = nil
                    if current then
                        currentPrefabset = swapBank[ current.categoryIndex ][ current.swapIndex ]
                    end

                    setUpChanges( newPrefabSet, currentPrefabset )

                    -- SET UP TRIGGER FOR WHEN IT SHOULD BE BEING ADDED INTO THE WORLD, AND HOW.

                    --  remove that category from the potentials.
                    table.remove(potentials,categorySelectionIndex)
                end
            end
        end    
    end

end

local function TestForRegrow(x, y, z, prefab, densityTarget, disease_check_Tag)


    local ents = TheSim:FindEntities(x,y,z, EXCLUDE_RADIUS)
    if #ents > 0 then
        -- Too dense
        print("REMOVING LOCATION")
        return false
    end

    local ents = TheSim:FindEntities(x,y,z, BASE_RADIUS, nil, nil, { "structure", "wall" })
    if #ents > 0 then
        -- Don't spawn inside bases
        return false
    end

    if densityTarget and disease_check_Tag then

        local ents = TheSim:FindEntities(x,y,z, BASE_RADIUS, { disease_check_Tag }, nil, nil )

        local density = #ents/BASE_AREA * 100
        --print("DENSITY CHECK", prefab, #ents, density, densityTarget) 
        if density > densityTarget then
            --print("TOO DENSE")
            return false
        end

    end    

    local tile = TheWorld.Map:GetTileAtPoint(x,y,z)
    if not (TheWorld.Map:CanPlantAtPoint(x, y, z) and
            TheWorld.Map:CanPlacePrefabFilteredAtPoint(x,y,z, prefab))
        or tile == GROUND.ROAD
        or (RoadManager ~= nil and RoadManager:IsOnRoad(x, 0, z)) then
        -- Not ground we can grow on
        return false
    end
    return true
end

local function managePrefabsSpawnInOverTime(inst, prefab, coordsList, spawnTime, spawnTimeRand, taskID)
    _tasks[taskID]:Cancel()
    _tasks[taskID] = nil

    local location = math.random(#coordsList)
    local x = coordsList[location].x
    local z = coordsList[location].z

    local player_in_range = IsAnyPlayerInRange(x,0,z, MIN_PLAYER_DISTANCE, nil)
    local regrow_ok = TestForRegrow(x,0,z, prefab) 

    if regrow_ok and not player_in_range then
        local instance = SpawnPrefab(prefab)
        if instance ~= nil then
            instance.Transform:SetPosition(x,0,z)
            if instance.components.diseaseable ~= nil then
                instance.components.diseaseable:OnRebirth()
            end
        end
        table.remove(coordsList,location)
    else
        print("failed to regrow",prefab)
    end

    if #coordsList > 0 then
        local time = math.max(spawnTime - spawnTimeRand  + (math.random()*spawnTimeRand*2),1)
        _tasks[_next_task_id] = inst:DoTaskInTime(time, managePrefabsSpawnInOverTime, prefab, coordsList, spawnTime, spawnTimeRand, _next_task_id)
        _next_task_id = _next_task_id + 1
    end
end


local function repopulatePrefabByDensity(prefab_data, disease_check_Tag)

    local prefab = prefab_data.prefab

    local totalNumber = 0
    local guessNumber = 0
    local totalErrors = 0
    for area, v in pairs(TheWorld.topology.nodes) do
        local densityList = TheWorld.generated.densities[TheWorld.topology.ids[area]]

        if densityList and densityList[prefab] then
            local localTotal = 0

            local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(TheWorld.topology.nodes[area].x, TheWorld.topology.nodes[area].y, TheWorld.topology.nodes[area].poly, 999)
            local tiles = #points_x
            local coordsList = {}
            local predictedLocalTotal = #points_x*densityList[prefab]
            guessNumber = guessNumber + predictedLocalTotal

            -- get the total number expected based off the total number of points returned 
            for i = #points_x, 1, -1 do
                local random = math.random()

                if random <= densityList[prefab] then
           --         print("CALK ===","+++",random,densityList[prefab])
                    localTotal = localTotal + 1
                else
            --        print("CALK ===","   ",random,densityList[prefab])
                end
            end

            -- remove locations that wont work
            for i = #points_x, 1, -1 do
                local x = points_x[i]
                local z = points_y[i]

                if not TestForRegrow(x,0,z, prefab, densityList[prefab], disease_check_Tag) then
                    table.remove(points_x,i)
                    table.remove(points_y,i)
                end
            end

            -- create the coords list
            local errors = 0
            for i = 1, localTotal, 1 do
                if #points_x > 0 then
                    local randLoc = math.random(#points_x)

                    local x = points_x[randLoc]
                    local z = points_y[randLoc]

                    table.insert(coordsList,{x=x,z=z})
                    totalNumber = totalNumber + 1

                    table.remove(points_x,randLoc)
                    table.remove(points_y,randLoc)
                else
                    errors= errors + 1
                end
            end
            totalErrors = totalErrors + errors

            print("area: "..area,"num of tiles: "..tiles,"prefab: "..prefab,"density: "..densityList[prefab],"= "..localTotal .."/"..predictedLocalTotal, "pinched:"..errors)

            coordsList = shuffleArray(coordsList)

            if #coordsList > 0 then
                _tasks[_next_task_id] = inst:DoTaskInTime(prefab_data.delayTime + TUNING.TOTAL_DAY_TIME, managePrefabsSpawnInOverTime, prefab, coordsList, prefab_data.spawnTime, prefab_data.spawnTimeRand, _next_task_id)
                _next_task_id = _next_task_id + 1
            end
        end
    end

    print(" --> RESULT", totalNumber.."/"..guessNumber, totalErrors)
end

local function processTrigger(change)

    if #change.triggers == 0 then
        if change.state == "signal_out" then

            local swap = change.swap
            swap.status = "inactive"

            for i, prefab_data in ipairs(swap.trigger.prefab_disease) do
                print("######################")
                print("SIGNAL SPAWN OUT ",prefab_data.prefab)
                StartUpdating()
            end

        elseif change.state == "spawn_in" then
            
            local swap = change.swap

            if not swap.noActive then
                swap.status = "active"
            end
            if swap.trigger.prefab_spawns then

                for i, prefab_data in ipairs(swap.trigger.prefab_spawns) do
                    print("######################")
                    print("SIGNAL SPAWN IN ",prefab_data.prefab)

                    TheWorld:PushEvent("ms_spawnsetpiece"..prefab_data.prefab, { delay = 0, delayvariance = TUNING.TOTAL_DAY_TIME })

                    repopulatePrefabByDensity(prefab_data,swap.trigger.disease_check)
                end
            end

        elseif change.state == "spawn_event" then
            local swapData = prefabswap_list.getPrefabSwapsForSwapManager()

            for i, swapItems in pairs(swapData) do
                for d, swap in ipairs(swapItems) do
                    if swap.name == change.name then
                        for t, event in ipairs(swap.trigger.prefab_events) do
                            event(TheWorld)
                        end
                    end
                end
            end

        end

    end
end

local function GetPrefabDiseaseData(prefab)
    if TheWorld.prefabswapstatus ~= nil then
        for i,category in pairs(TheWorld.prefabswapstatus) do
            for k,swap in ipairs(category) do
                for p,swapPrefab in ipairs(swap.prefabs) do
                    if prefab == swapPrefab then
                        --nil if active
                        --empty table if diseased with no immunity data
                        --otherwise table with immunity data
                        return swap.status ~= "active"
                            and { disease_immunities = swap.trigger.disease_immunities }
                            or nil
                    end
                end
            end
        end
    end
    return nil --prefab not in swap data, return it as active
end

local function GetPrefabPetrificationData(prefab)
    return (prefab == "evergreen" or prefab == "evergreen_sparse")
        and _petrification
        or nil
end

local function IsTracking(target)
    return target.prefab ~= nil
        and (   (_ents1[target.prefab] ~= nil and _ents1[target.prefab][target] ~= nil) or
                (_ents2[target.prefab] ~= nil and _ents2[target.prefab][target] ~= nil) )
        or _newents[target] ~= nil
end

--helper for StopTracking
local function _StopTrackingInEnts(target, ents)
    local prefabents = ents[target.prefab]
    if prefabents ~= nil and prefabents[target] ~= nil then
        prefabents[target] = nil
        if next(prefabents) == nil then
            ents[target.prefab] = nil
        end
        return true
    end
end

local function StopTracking(target)
    if _newents[target] or _StopTrackingInEnts(target, _ents1) or _StopTrackingInEnts(target, _ents2) then
        _newents[target] = nil
        inst:RemoveEventCallback("onremove", StopTracking, target)
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function checkForChanges(inst, trigger)
    print("PREFAB SWAP TRIGGER:", trigger)

    if trigger == _new_year then
        OnNewYear(self)
    end

    for i,change in ipairs(_changes)do
        for p=#change.triggers,1,-1 do
            if trigger == change.triggers[p] then
                table.remove(change.triggers, p)
                processTrigger(change)
            end
        end
    end
end

local function OnUnregisterDiseaseable(inst, target)
    StopTracking(target)
end

local function OnRegisterDiseaseable(inst, target)
    if not IsTracking(target) then
        --Use _newents instead of directly into _ents2 because target.prefab
        --may not be set yet if this event was triggered during construction
        _newents[target] = true
        inst:ListenForEvent("onremove", StopTracking, target)
        StartUpdating()
    end
end

local function OnPetrifyForest(inst, data)
    if data ~= nil and data.area ~= nil then
        if _petrification == nil then
            _petrification = { areas = { data.area } }
        else
            table.insert(_petrification.areas, data.area)
        end
        StartUpdating()
    end
end

local function OnSetStartSeason(inst, season)
    if season == "autumn" then
        _new_year = "winter"
    elseif season == "winter" then
        _new_year = "spring"
    elseif season == "spring" then
        _new_year = "summer"
    elseif season == "summer" then
        _new_year = "autumn"
    end
end

local function OnSetNextPrefabSwaps(inst, setdata)
    prefabswap_list.setNextSwaps(setdata)
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

self:WatchWorldState("season", checkForChanges)
self:WatchWorldState("precipitation", checkForChanges)
self:WatchWorldState("moonphase", checkForChanges)
inst:ListenForEvent("ms_registerdiseaseable", OnRegisterDiseaseable)
inst:ListenForEvent("ms_unregisterdiseaseable", OnUnregisterDiseaseable)
inst:ListenForEvent("ms_petrifyforest", OnPetrifyForest)
inst:ListenForEvent("ms_setstartseason", OnSetStartSeason)
inst:ListenForEvent("ms_setnextprefabswaps", OnSetNextPrefabSwaps)

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

--[[#DBGLOG
local _log_new
local _log_diseased
local _log_ignored
--#DBGLOG]]

--Helper for OnUpdate->_ProcessEnts
local function _ProcessEnt(ent, data)
    if data.disease_immunities ~= nil and
        data.disease_immunities.terrain ~= nil and
        data.disease_immunities.terrain == TheWorld.Map:GetTileAtPoint(ent.Transform:GetWorldPosition()) then
        --This prefab is immune to disease while on this terrain
        --[[#DBGLOG
        _log_ignored[ent.prefab] = (_log_ignored[ent.prefab] or 0) + 1
        --#DBGLOG]]
        return
    end
    if data.areas ~= nil then
        local isinarea = false
        local x, y, z = ent.Transform:GetWorldPosition()
        for i, v in ipairs(data.areas) do
            local node = TheWorld.topology.nodes[v]
            if TheSim:WorldPointInPoly(x, z, node.poly) then
                --This prefab is within the affected node area
                isinarea = true
                break
            end
        end
        if not isinarea then
            --[[#DBGLOG
            _log_ignored[ent.prefab] = (_log_ignored[ent.prefab] or 0) + 1
            --#DBGLOG]]
            return
        end
    end
    --[[#DBGLOG
    _log_diseased[ent.prefab] = (_log_diseased[ent.prefab] or 0) + 1
    --#DBGLOG]]
    _idle_since_swap = false
    StopTracking(ent)
    ent.components.diseaseable:Start()
end

--Helper for OnUpdate
local function _ProcessEnts(remaining)
    --Using update pages _ents1, _ents2, as well as queued _newents,
    --we can split updates across multiple frames, as well as handle
    --tables mutating (due to callbacks) while we iterate over them.

    --if page 1 is empty, then swap pages
    local prefab, prefabents1 = next(_ents1)
    if prefab == nil then
        --move new entities into page 2
        local ent = next(_newents)
        while ent ~= nil do
            local prefabents2 = _ents2[ent.prefab]
            if prefabents2 == nil then
                _ents2[ent.prefab] = { [ent] = true }
            else
                prefabents2[ent] = true
            end
            _newents[ent] = nil
            --[[#DBGLOG
            _log_new[ent.prefab] = (_log_new[ent.prefab] or 0) + 1
            --#DBGLOG]]
            if remaining <= 1 then
                return 0
            end
            remaining = remaining - 1
            ent = next(_newents)
        end

        --Stop if no changes for an entire page swap
        if _idle_since_swap then
            --[[#DBGLOG
            print("PrefabSwapManager idle since last swap")
            --#DBGLOG]]
            StopUpdating()
            return 0
        end

        --swap pages
        prefab, prefabents1 = next(_ents2)
        if prefab ~= nil then
            local temp = _ents1
            _ents1 = _ents2
            _ents2 = temp
            _idle_since_swap = true
            --[[#DBGLOG
            print("PrefabSwapManager page swap")
            --#DBGLOG]]
        else
            --both pages empty
            StopUpdating()
            return 0
        end
    end

    local prefabents2 = _ents2[prefab]
    local diseasedata = GetPrefabDiseaseData(prefab) or GetPrefabPetrificationData(prefab)

    if diseasedata ~= nil then
        --move entity to page 2, then trigger disease on it
        local ent = next(prefabents1)
        if prefabents2 == nil then
            _ents2[prefab] = { [ent] = true }
        else
            prefabents2[ent] = true
        end
        prefabents1[ent] = nil
        if next(prefabents1) == nil then
            _ents1[prefab] = nil
        end
        _ProcessEnt(ent, diseasedata)
        remaining = remaining - 1
    elseif prefabents2 == nil then
        --[[#DBGLOG
        _log_ignored[prefab] = (_log_ignored[prefab] or 0) + GetTableSize(prefabents1)
        --#DBGLOG]]
        --move entire prefab table to page 2 if it doesn't need to disease
        _ents2[prefab] = prefabents1
        _ents1[prefab] = nil
        remaining = remaining - 1
    else
        --move entities to existing prefab table in page 2 if they don't need to disease
        for k, v in pairs(prefabents1) do
            --[[#DBGLOG
            _log_ignored[prefab] = (_log_ignored[prefab] or 0) + 1
            --#DBGLOG]]
            prefabents2[k] = v
            if remaining <= 1 then
                if next(prefabents1) == nil then
                    _ents1[prefab] = nil
                end
                return 0
            end
            remaining = remaining - 1
        end
        _ents1[prefab] = nil
    end

    return remaining
end

function self:OnUpdate(dt)
    --[[#DBGLOG
    _log_new = {}
    _log_diseased = {}
    _log_ignored = {}
    --#DBGLOG]]

    --Loop this way to avoid recursive calls
    local i = _ProcessEnts(UPDATE_ENTS_PER_FRAME)
    while i > 0 do
        i = _ProcessEnts(i)
    end

    --[[#DBGLOG
    local printed = false
    for k, v in pairs(_log_new) do
        printed = true
        print(string.format("Tracked %d %s(s)", v, k))
    end
    for k, v in pairs(_log_diseased) do
        printed = true
        print(string.format("Diseased %d %s(s)", v, k))
    end
    for k, v in pairs(_log_ignored) do
        printed = true
        print(string.format("Ignored %d %s(s)", v, k))
    end
    if printed then
        print("---------------")
    end
    --#DBGLOG]]
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:IsDiseasedPrefab(prefab)
    return GetPrefabDiseaseData(prefab) ~= nil
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local tasks = {}
    for k, task in pairs(_tasks) do
        if task.arg ~= nil then
            table.insert(tasks, {
                time = GetTaskRemaining(task),
                arg1 = task.arg[2],
                arg2 = task.arg[3],
                arg3 = task.arg[4],
                arg4 = task.arg[5],
            })
        end
    end

    return
    {
        changes = _changes,
        tasks = next(tasks) ~= nil and tasks or nil,
        petrification = _petrification ~= nil and _petrification.areas or nil,
    }
end

function self:OnLoad(data)
    if data ~= nil then
        if data.changes ~= nil then
            _changes = data.changes
        end
        if data.tasks ~= nil then
            for i, taskdata in ipairs(data.tasks) do
                _tasks[_next_task_id] = inst:DoTaskInTime(taskdata.time, managePrefabsSpawnInOverTime, taskdata.arg1, taskdata.arg2, taskdata.arg3, taskdata.arg4, _next_task_id)
                _next_task_id = _next_task_id + 1
            end
        end
        if data.petrification ~= nil then
            for i, v in ipairs(data.petrification) do
                OnPetrifyForest(inst, { area = v })
            end
        end
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
