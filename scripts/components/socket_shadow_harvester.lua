local TICK_PERIOD = TUNING.SKILLS.WX78.SHADOWDRONE_HARVESTER_PASSIVE_TICK_PERIOD

local Socket_Shadow_Harvester = Class(function(self, inst)
    self.inst = inst
    self.harvestradius = 6

    self.busyharvesters = {}
    self.items = {}

    self.ClearHarvesterLink = function(harvester)
        local item = self.busyharvesters[harvester]
        self.inst:RemoveEventCallback("onputininventory", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnHarvesterRemoved, harvester)
        self.inst:RemoveEventCallback("braincommon_pickup_failed", self.OnHarvesterFailedAction, harvester)
        self.inst:RemoveEventCallback("braincommon_pickup_success", self.OnHarvesterSucceededAction, harvester)
        self.inst:RemoveEventCallback("entitysleep", self.OnHarvesterSleep, harvester)
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
        local item = self.busyharvesters[harvester]
        self.inst:RemoveEventCallback("onputininventory", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnItemRemoved, item)
        self.busyharvesters[harvester] = nil
        self.items[item] = nil
    end
    self.OnItemRemoved = function(item)
        local harvester = self.items[item]
        self.inst:RemoveEventCallback("onputininventory", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnItemRemoved, item)
        self.inst:RemoveEventCallback("onremove", self.OnHarvesterRemoved, harvester)
        self.inst:RemoveEventCallback("braincommon_pickup_failed", self.OnHarvesterFailedAction, harvester)
        self.inst:RemoveEventCallback("braincommon_pickup_success", self.OnHarvesterSucceededAction, harvester)
        self.inst:RemoveEventCallback("entitysleep", self.OnHarvesterSleep, harvester)
        self.busyharvesters[harvester] = nil
        self.items[item] = nil
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
    local skilltreeupdater = self.inst.components.skilltreeupdater
    if skilltreeupdater then
        if skilltreeupdater:IsActivated("wx78_extradronerange") then
            extradronerange = extradronerange + TUNING.SKILLS.WX78.SHADOWDRONE_HARVESTER_FINDITEM_RADIUS_SKILLBOOST
        end
        if skilltreeupdater:IsActivated("wx78_circuitry_betabuffs_1") then
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

function Socket_Shadow_Harvester:DoTick_Internal(harvesters)
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
