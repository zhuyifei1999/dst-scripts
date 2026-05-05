local TICK_PERIOD = TUNING.SKILLS.WX78.SHADOWDRONE_HARVESTER_PASSIVE_TICK_PERIOD
local VIRTUALHARVEST_MOTION_DELAY = 2.7 -- Padding time for the drone to start and stop.
local VIRTUALHARVEST_HARVEST_DELAY = 1.5 + VIRTUALHARVEST_MOTION_DELAY
local VIRTUALHARVEST_DEPOSIT_DELAY = 2.5 + VIRTUALHARVEST_MOTION_DELAY
-- NOTES(JBK): These timing values were calculated using emperical tests by watching the drones harvest the same plot as the virtual ones in a time of one minute.

local Socket_Shadow_Harvester = Class(function(self, inst)
    self.inst = inst
    self.harvestradius = 6

    self.simulatingharvesters = {}
    self.busyharvesters = {}
    self.items = {}

    self.ClearHarvesterLink = function(harvester)
        local item = self:GetItemForHarvester(harvester)
        self.inst:RemoveEventCallback("onputininventory", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnHarvesterRemoved, harvester)
        self.inst:RemoveEventCallback("braincommon_pickup_failed", self.OnHarvesterFailedAction, harvester)
        self.inst:RemoveEventCallback("braincommon_pickup_success", self.OnHarvesterSucceededAction, harvester)
        self.inst:RemoveEventCallback("entitysleep", self.OnHarvesterSleep, harvester)
        self.simulatingharvesters[harvester] = nil
        self.busyharvesters[harvester] = nil
        self.items[item] = nil
    end

    self.OnHarvesterSleep = function(harvester)
        self.ClearHarvesterLink(harvester)
        harvester:ClearBufferedAction() -- Cancel the pending action immediately.
    end

    self.OnHarvesterFailedAction = function(harvester, ba)
        self.ClearHarvesterLink(harvester)
        harvester:ClearBufferedAction() -- Cancel the pending action immediately.
    end

    self.OnHarvesterSucceededAction = function(harvester, ba)
        self.ClearHarvesterLink(harvester)
    end
    self.OnHarvesterRemoved = function(harvester)
        local item = self:GetItemForHarvester(harvester)
        self.inst:RemoveEventCallback("onputininventory", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnItemRemoved, item)
        self.simulatingharvesters[harvester] = nil
        self.busyharvesters[harvester] = nil
        self.items[item] = nil
    end
    self.OnItemRemoved = function(item)
        local harvester = self.items[item]
        self.ClearHarvesterLink(harvester)
        harvester:ClearBufferedAction() -- Cancel the pending action immediately.
    end

    self.OnTick = function()
        self:DoTick()
    end

    if self.inst.isplayer then
        -- Player must be harvesting or picking up items to proc it.
        self.inst:ListenForEvent("onpickupitem", self.OnTick)
        self.inst:ListenForEvent("picksomething", self.OnTick)
        self.inst:ListenForEvent("picksomethingfromaoe", self.OnTick)
    else
        -- Passively activate ticks.
        self.periodictask = self.inst:DoPeriodicTask(TICK_PERIOD, self.OnTick)
    end
end)

function Socket_Shadow_Harvester:OnRemoveFromEntity()
    if self.inst.isplayer then
        self.inst:RemoveEventCallback("onpickupitem", self.OnTick)
        self.inst:RemoveEventCallback("picksomething", self.OnTick)
        self.inst:RemoveEventCallback("picksomethingfromaoe", self.OnTick)
    else
        if self.periodictask then
            self.periodictask:Cancel()
            self.periodictask = nil
        end
    end
    for harvester, item in pairs(self.busyharvesters) do
        self.inst:RemoveEventCallback("onputininventory", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnHarvesterRemoved, harvester)
        self.inst:RemoveEventCallback("braincommon_pickup_failed", self.OnHarvesterFailedAction, harvester)
        self.inst:RemoveEventCallback("braincommon_pickup_success", self.OnHarvesterSucceededAction, harvester)
        self.inst:RemoveEventCallback("entitysleep", self.OnHarvesterSleep, harvester)
        self.simulatingharvesters[harvester] = nil
        self.busyharvesters[harvester] = nil
        self.items[item] = nil
        harvester:ClearBufferedAction() -- Cancel the pending action immediately.
        if harvester.components.inventory then
            harvester.components.inventory:DropEverything()
        end
    end
end

function Socket_Shadow_Harvester:SetHarvestRadius(harvestradius)
    self.harvestradius = harvestradius
end

function Socket_Shadow_Harvester:GetHarvestRadius()
    local extradronerange = 0
    local owner = self.inst.components.linkeditem and self.inst.components.linkeditem:GetOwnerInst() or self.inst
    local skilltreeupdater = owner.components.skilltreeupdater
    if skilltreeupdater then
        if skilltreeupdater:IsActivated("wx78_extradronerange") then
            extradronerange = extradronerange + TUNING.SKILLS.WX78.SHADOWDRONE_HARVESTER_FINDITEM_RADIUS_SKILLBOOST
        end
        if (self.inst.isplayer or skilltreeupdater:IsActivated("wx78_bodycircuits")) and skilltreeupdater:IsActivated("wx78_circuitry_betabuffs_1") then
            if self.inst.GetModuleTypeCount then
                extradronerange = extradronerange + self.inst:GetModuleTypeCount("radar") * TUNING.SKILLS.WX78.SHADOWDRONE_HARVESTER_FINDITEM_RADIUS_RADAR
            end
        end
    end
    return self.harvestradius + extradronerange
end


function Socket_Shadow_Harvester:GetItemForHarvester(harvester)
    return self.busyharvesters[harvester]
end


local function Filter_OnlyPlantHarvestables(worker, ent, owner)
    return ent.components.pickable == nil or ent:HasOneOfTags(HARVESTABLE_PLANT_TARGET_TAGS)
end

function Socket_Shadow_Harvester:TryToFindItem()
    local container = self.inst.components.inventory or self.inst.components.container
    return FindPickupableItem(self.inst, self:GetHarvestRadius(), true, nil, self.items, nil, true, self.inst, Filter_OnlyPlantHarvestables, container)
end

function Socket_Shadow_Harvester:DoTick_Internal_Simulations_Traveling(harvester, target)
    -- Simulate traveling towards the target.
    local x1, y1, z1 = harvester.Transform:GetWorldPosition()
    local x2, y2, z2 = target.Transform:GetWorldPosition()
    local dx, dz = x2 - x1, z2 - z1
    local dist = math.sqrt(dx * dx + dz * dz)
    local runspeed = math.max(harvester.components.locomotor:RunSpeed(), 1) -- Intentionally getting the internal runspeed without modifiers.

    local traveltime = dist / runspeed
    if traveltime < TICK_PERIOD then
        -- Set arrival right onto destination.
        if harvester.Physics then
            harvester.Physics:Teleport(x2, y2, z2)
        else
            harvester.Transform:SetPosition(x2, y2, z2)
        end
        return true
    end

    -- Traveling to target.
    if dist > 0 then
        dx, dz = dx / dist, dz / dist
    end
    x1, z1 = x1 + dx * runspeed, z1 + dz * runspeed
    if harvester.Physics then
        harvester.Physics:Teleport(x1, y1, z1)
    else
        harvester.Transform:SetPosition(x1, y1, z1)
    end
    return false
end

function Socket_Shadow_Harvester:DoTick_Internal_Simulations(harvesters)
    -- Simulate busy harvesters that are also asleep.
    for _, harvester in ipairs(harvesters) do
        if harvester:IsAsleep() then
            local currenttime = GetTime()

            -- Get and setup simulation data for state retention.
            local simulationdata = self.simulatingharvesters[harvester]
            if not simulationdata then
                simulationdata = {}
                self.simulatingharvesters[harvester] = simulationdata
            end

            -- Handle delays.
            local delaytime = simulationdata.delaytime
            if delaytime then
                delaytime = delaytime - TICK_PERIOD
                if delaytime <= 0 then
                    delaytime = nil
                    simulationdata.delaytime = delaytime
                end
            end

            if not delaytime then
                -- Do actions.
                local helditem = harvester.components.inventory:GetFirstItemInAnySlot()
                if helditem then
                    if self:DoTick_Internal_Simulations_Traveling(harvester, self.inst) then
                        -- Arrived back at the owner to deposit the helditem into the owner's storage.
                        local action
                        if self.inst.isplayer then
                            action = ACTIONS.GIVEALLTOPLAYER
                        elseif self.inst.components.trader then
                            action = ACTIONS.GIVE
                        elseif self.inst.components.container then
                            action = ACTIONS.STORE
                        end

                        local success
                        if action then
                            success = BufferedAction(harvester, self.inst, action, helditem):Do()
                        end
                        if not success then
                            harvester.components.inventory:DropEverything()
                        end
                        delaytime = VIRTUALHARVEST_DEPOSIT_DELAY
                    end
                else
                    local item = self:GetItemForHarvester(harvester)
                    if item then
                        if self:DoTick_Internal_Simulations_Traveling(harvester, item) then
                            -- Arrived at the item to harvest or pickup.
                            local pickable = item:HasTag("pickable")
                            -- Special handling for this to simulate the pickup logic and proper events.
                            local ba = BufferedAction(harvester, item, item.components.trap ~= nil and ACTIONS.CHECKTRAP or pickable and ACTIONS.PICK or ACTIONS.PICKUP)
                            ba:AddFailAction(function()
                                harvester:PushEvent("braincommon_pickup_failed", ba)
                            end)
                            ba:AddSuccessAction(function()
                                harvester:PushEvent("braincommon_pickup_success", ba)
                            end)
                            ba:Do()
                            delaytime = VIRTUALHARVEST_HARVEST_DELAY
                        end
                    end
                end
            end

            -- Add delays if any were set.
            simulationdata.delaytime = delaytime
        else
            self.simulatingharvesters[harvester] = nil
        end
    end
end

function Socket_Shadow_Harvester:DoTick_Internal(harvesters)
    if self.inst:IsAsleep() then
        self:DoTick_Internal_Simulations(harvesters)
    end

    local freeharvester
    for _, harvester in ipairs(harvesters) do
        if not self.busyharvesters[harvester] then
            freeharvester = harvester
            break
        end
    end
    if not freeharvester then
        return false
    end

    local item = self:TryToFindItem()
    if not item then
        return false
    end

    self.busyharvesters[freeharvester] = item
    self.items[item] = freeharvester
    self.inst:ListenForEvent("onremove", self.OnHarvesterRemoved, freeharvester)
    self.inst:ListenForEvent("onputininventory", self.OnItemRemoved, item)
    self.inst:ListenForEvent("onremove", self.OnItemRemoved, item)
    self.inst:ListenForEvent("braincommon_pickup_failed", self.OnHarvesterFailedAction, freeharvester)
    self.inst:ListenForEvent("braincommon_pickup_success", self.OnHarvesterSucceededAction, freeharvester)
    self.inst:ListenForEvent("entitysleep", self.OnHarvesterSleep, freeharvester)
    return true
end

function Socket_Shadow_Harvester:DoTick()
    local petleash = self.inst.components.petleash
    if not petleash then
        return
    end

    local harvesters = petleash:GetPetsWithPrefab("wx78_shadowdrone_harvester")
    if not harvesters then
        return
    end

    while self:DoTick_Internal(harvesters) do
        -- Repeat until we can no longer send a drone off.
    end
end

return Socket_Shadow_Harvester
