local HARVEST_MUSTTAGS  = {"pickable"}
local HARVEST_CANTTAGS  = {"INLIMBO", "FX"}
local HARVEST_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}

local TICK_PERIOD = TUNING.SKILLS.WX78.HARVEST_PASSIVE_TICK_PERIOD

local function OnTendrilExpired(tendril)
    local x, y, z = tendril.Transform:GetWorldPosition()
    local fx = SpawnPrefab("shadow_puff")
    fx.Transform:SetPosition(x, y, z)
end

local Socket_Shadow_Harvester = Class(function(self, inst)
    self.inst = inst
    self.harvestradius = 4
    self.travelspeed = 2
    self.maxtendrils = 1

    self.ontendrilremoved = function(tendril)
        local item = self.tendrils[tendril]
        item:RemoveEventCallback("onremove", self.onitemremoved)
        self.tendrilscount = self.tendrilscount - 1
        self.tendrils[tendril] = nil
        self.items[item] = nil
        OnTendrilExpired(tendril)
    end
    self.onitemremoved = function(item)
        local tendril = self.items[item]
        tendril:RemoveEventCallback("onremove", self.ontendrilremoved)
        self.tendrilscount = self.tendrilscount - 1
        self.tendrils[tendril] = nil
        self.items[item] = nil
        OnTendrilExpired(tendril)
        tendril:Remove()
    end
    self.tendrilscount = 0
    self.tendrils = {} -- The key is the tendril and value is the item it is going after.
    self.items = {} -- An inverted table of self.tendrils for lookups.
    
    self.OnTick = function()
        self:DoTick()
    end
    if self.inst.isplayer then
        -- Player must be harvesting or picking up items to proc it.
        self.OnAoETick = function(inst, data)
            if data and data.harvestedcount then
                for i = 1, data.harvestedcount do
                    self:DoTick()
                end
            end
        end
        self.inst:ListenForEvent("onpickupitem", self.OnTick)
        self.inst:ListenForEvent("picksomething", self.OnTick)
        self.inst:ListenForEvent("picksomethingfromaoe", self.OnAoETick)
    else
        -- Passively activate ticks.
        self.periodictask = self.inst:DoPeriodicTask(TICK_PERIOD, self.OnTick)
    end
end)

function Socket_Shadow_Harvester:OnRemoveFromEntity()
    if self.inst.isplayer then
        self.inst:RemoveEventCallback("onpickupitem", self.OnTick)
        self.inst:RemoveEventCallback("picksomething", self.OnTick)
        self.inst:RemoveEventCallback("picksomethingfromaoe", self.OnAoETick)
    else
        if self.periodictask then
            self.periodictask:Cancel()
            self.periodictask = nil
        end
    end
    for tendril, item in pairs(self.tendrils) do
        tendril:Remove()
    end
end

function Socket_Shadow_Harvester:SetHarvestRadius(harvestradius)
    self.harvestradius = harvestradius
end

function Socket_Shadow_Harvester:SetTravelSpeed(travelspeed)
    self.travelspeed = travelspeed
end

function Socket_Shadow_Harvester:SetMaxTendrils(maxtendrils)
    self.maxtendrils = maxtendrils
end



function Socket_Shadow_Harvester:RemoveOnTendrilsFinished()
    self.removeontendrilsfinished = true
end


function Socket_Shadow_Harvester:ClearItem()
    if self.item then
        self.inst:RemoveEventCallback("onremove", self.onitemremoved, self.item)
        self.item = nil
    end
end

function Socket_Shadow_Harvester:SetItem(item)
    self:ClearItem()
    self.item = item
    self.inst:ListenForEvent("onremove", self.onitemremoved, self.item)
end

function Socket_Shadow_Harvester:HarvestItem_Internal(tendril, item)
    local didpickup = false
    if item.components.trap then
        item.components.trap:Harvest(self.inst)
        didpickup = true
    elseif item.components.pickable then
        if item:HasTag("pickable") then
            if item.components.pickable.picksound then
                if self.inst.SoundEmitter then
                    self.inst.SoundEmitter:PlaySound(item.components.pickable.picksound)
                end
            end
            local success, loot = item.components.pickable:Pick(TheWorld)
            if loot then
                for _, item in ipairs(loot) do
                    Launch2(item, item, 1.5, 1, 0.2, 0)
                end
            end
        end
        didpickup = true
    end

    if self.inst.components.minigame_participator then
        local minigame = self.inst.components.minigame_participator:GetMinigame()
        if minigame then
            minigame:PushEvent("pickupcheat", { cheater = self.inst, item = item })
        end
    end

    if not didpickup then
        local item_pos = item:GetPosition()
        if item.components.stackable ~= nil then
            item = item.components.stackable:Get()
        end
        local container = self.inst.components.inventory or self.inst.components.container
        container:GiveItem(item, nil, item_pos)
    end
    tendril:Remove()
    if self.onusedfn then
        self.onusedfn(self.inst)
    end
end

function Socket_Shadow_Harvester:TryToFindItem()
    local container = self.inst.components.inventory or self.inst.components.container
    return FindPickupableItem(self.inst, self.harvestradius, true, nil, self.items, nil, true, self.inst, nil, container)
end

function Socket_Shadow_Harvester:DoTick()
    if self.tendrilscount >= self.maxtendrils then
        return
    end

    local item = self:TryToFindItem()
    if not item then
        return
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local tendril = SpawnPrefab("shadow_harvester_trail")
    tendril.Transform:SetPosition(x, y, z)

    local updatelooper = tendril:AddComponent("updatelooper")
    local timeout = (math.sqrt(tendril:GetDistanceSqToInst(item)) / self.travelspeed) + 0.5
    updatelooper:AddOnUpdateFn(function(tendril, dt)
        local item = self.tendrils[tendril]
        local isbad
        if item.components.pickable then
            isbad = not item:HasTag("pickable")
        elseif item.components.inventoryitem then
            isbad = item.components.inventoryitem.owner ~= nil
        end
        timeout = timeout - dt
        if isbad or timeout <= 0 then
            tendril:Remove()
            return
        end

        local x1, y1, z1 = tendril.Transform:GetWorldPosition()
        local x2, y2, z2 = item.Transform:GetWorldPosition()

        local curx, curz
        local distsq = math2d.DistSq(x1, z1, x2, z2)
        local finished
        local traveldist = self.travelspeed * dt
        if distsq < traveldist * traveldist then
            curx, curz = x2, z2
            finished = true
        else
            local dx, dz = x2 - x1, z2 - z1
            local dist = math.sqrt(distsq)
            local dirx, dirz = dx / dist, dz / dist
            curx, curz = x1 + dirx * traveldist, z1 + dirz * traveldist
        end
        tendril.Transform:SetPosition(curx, 0, curz)
        if finished then
            self:HarvestItem_Internal(tendril, item)
        end
    end)

    self.tendrilscount = self.tendrilscount + 1
    self.tendrils[tendril] = item
    self.items[item] = tendril
    tendril:ListenForEvent("onremove", self.ontendrilremoved)
    item:ListenForEvent("onremove", self.onitemremoved)
end

return Socket_Shadow_Harvester
