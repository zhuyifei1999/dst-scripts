local function oncanbait(self)
    if self.isset and self.bait == nil then
        self.inst:AddTag("canbait")
    else
        self.inst:RemoveTag("canbait")
    end
end

local function onissprung(self, issprung)
    if issprung then
        self.inst:AddTag("trapsprung")
    else
        self.inst:RemoveTag("trapsprung")
    end
end

local function OnTimerDone(inst, data)
    if data.name == "foodspoil" then
        inst.components.trap:OnTrappedStarve()
    end
end

local Trap = Class(function(self, inst)
    self.inst = inst
    self.bait = nil
    self.issprung = false

    self.isset = false
    self.range = 1.5
    self.targettag = "smallcreature"
    self.checkperiod = .75
    self.onharvest = nil
    self.onbaited = nil
    self.onspring = nil

    self.inst:AddComponent("timer")
    self.inst:ListenForEvent("timerdone", OnTimerDone)
end,
nil,
{
    bait = oncanbait,
    isset = oncanbait,
    issprung = onissprung,
})

function Trap:OnRemoveFromEntity()
    self.inst:RemoveTag("canbait")
    self.inst:RemoveTag("trapsprung")
end

function Trap:SetOnHarvestFn(fn)
    self.onharvest = fn
end

function Trap:SetOnSpringFn(fn)
    self.onspring = fn
end

function Trap:GetDebugString()
    local str = nil
    if self.isset then 
        str = "SET! "
    elseif self.issprung then
        str = "SPRUNG! "
    else 
        str = "IDLE! "
    end

    if self.bait then
        str = str.."Bait:"..tostring(self.bait).." "
    end

    if self.target then
        str = str.."Target:"..tostring(self.target).." "
    end

    if self.lootprefabs and #self.lootprefabs > 0 then
        str = str.."Loot: "
        for k,v in pairs(self.lootprefabs) do
            str = str .. v.." "
        end
    end

    return str
end

function Trap:SetOnBaitedFn(fn)
    self.onbaited = fn
end

function Trap:IsFree() 
    return self.bait == nil
end

function Trap:IsBaited()
    return self.isset and not self.issprung and self.bait ~= nil
end

function Trap:Reset()
    self:StopUpdating()
    self.isset = false
    self.issprung = false
    self.lootprefabs = nil
    self.bait = nil
    self.target = nil
    self:StopStarvation()
end

function Trap:Disarm()
    self:Reset()
end

function Trap:Set()
    self:Reset()
    self.isset = true
    self:StartUpdate()
end

function Trap:StopUpdating()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

local function _OnUpdate(inst, self)
    self:OnUpdate(self.checkperiod)
end

function Trap:StartUpdate()
    if self.task == nil then
        self.task = self.inst:DoPeriodicTask(self.checkperiod, _OnUpdate, nil, self)
    end
end

local function CheckTrappable(guy)
    return guy.components.health == nil or not guy.components.health:IsDead()
end

function Trap:OnUpdate(dt)
    if self.isset then
        local guy = FindEntity(self.inst, self.range, CheckTrappable, { self.targettag }, { "INLIMBO" })
        if guy ~= nil then
            self.target = guy
            self:StopUpdating()
            self.inst:PushEvent("springtrap")
            self.target:PushEvent("trapped")
        end
    end
end

function Trap:OnTrappedStarve()
    if self.issprung then
        self.inst:PushEvent("harvesttrap")
        if self.onharvest ~= nil then
            self.onharvest(self.inst)
        end

        local timeintrap = self.inst.components.timer:GetTimeElapsed("foodspoil") or TUNING.TOTAL_DAY_TIME * 2

        if self.starvedlootprefabs ~= nil then
            for i, v in ipairs(self.starvedlootprefabs) do
                local loot = SpawnPrefab(v)
                if loot ~= nil then
                    loot.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                    if loot.components.perishable ~= nil then
                        loot.components.perishable:LongUpdate(timeintrap)
                    end
                end
            end
        end

        self:Reset()
        self.inst.sg:GoToState("empty")
    end
end

function Trap:StartStarvation()
    local perishTime =
        self.target.components.perishable ~= nil and
        self.target.components.perishable.perishremainingtime or
        TUNING.TOTAL_DAY_TIME * 2
    
    self.starvedlootprefabs =
        self.target.components.lootdropper ~= nil and
        self.target.components.lootdropper:GenerateLoot() or
        { "spoiled_food" }

    self.inst.components.timer:StartTimer("foodspoil", perishTime)
end

function Trap:StopStarvation()
    self.inst.components.timer:StopTimer("foodspoil")
    self.starvedlootprefabs = nil
end

local BAIT_TAGS = { "molebait" }
for k, v in pairs(FOODTYPE) do
    table.insert(BAIT_TAGS, "edible_"..v)
end

function Trap:DoSpring()
    self:StopUpdating()
    if self.target ~= nil and not self.target:IsValid() then
        return -- this animal is already in a trap this tick, just waiting to be Remove()'d
    end

    if self.target ~= nil and not self.target:IsInLimbo() and
        not (self.target.components.health ~= nil and self.target.components.health:IsDead()) then
        if self.onspring ~= nil then
            self.onspring(self.inst, self.target, self.bait)
        end

        self.lootprefabs =
            (self.target.components.inventoryitem ~= nil and self.target.components.inventoryitem.trappable and { self.target.prefab }) or
            (self.target.components.lootdropper ~= nil and self.target.components.lootdropper.trappable and self.target.components.lootdropper:GenerateLoot()) or
            nil

        self:StartStarvation()

        if self.lootprefabs ~= nil then
            self.target:PushEvent("ontrapped", { trapper = self.inst, bait = self.bait })
            ProfileStatsAdd("trapped_"..self.target.prefab)
            self.target:Remove()
        end
    else
        self.lootprefabs = nil
    end

    if self.bait ~= nil and self.bait:IsValid() then
        if self.target ~= nil and self.target.components.inventory ~= nil and self.target:HasTag("baitstealer") then
            self.target.components.inventory:GiveItem(self.bait)
            self:RemoveBait()
        else
            self.bait:Remove()
        end
    elseif self.target ~= nil then
        local ismole = self.target:HasTag("mole")
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 2, nil, { "INLIMBO" }, BAIT_TAGS)
        for i, v in ipairs(ents) do
            if v.components.bait ~= nil
                and (ismole and v:HasTag("molebait") or
                    (self.target.components.eater ~= nil and self.target.components.eater:CanEat(v))) then
                -- bait type is a valid bait for the thing we're trapping
                if self.target.components.inventory ~= nil and self.target:HasTag("baitstealer") then
                    self.target.components.inventory:GiveItem(v)
                else
                    v:Remove()
                end
                break
            end
        end
    end

    self.target = nil
    self.bait = nil
    self.isset = false
    self.issprung = true
    --self.inst:RemoveComponent("inventoryitem")
end

function Trap:IsSprung()
    return self.issprung
end

function Trap:Harvest(doer)
    if self.issprung then
        --Cache these because trap may become invalid in callbacks
        local pos = self.inst:GetPosition()
        local timeintrap = self.inst.components.timer ~= nil and self.inst.components.timer:GetTimeElapsed("foodspoil") or 0

        self.inst:PushEvent("harvesttrap")
        if self.onharvest ~= nil then
            self.onharvest(self.inst)
        end
        --WARNING: May have become invalid now!

        local inventory = doer ~= nil and doer.components.inventory or nil
        if self.lootprefabs ~= nil then
            for i, v in ipairs(self.lootprefabs) do
                local loot = SpawnPrefab(v)
                if loot ~= nil then
                    if inventory ~= nil then
                        inventory:GiveItem(loot, nil, pos)
                    else
                        loot.Transform:SetPosition(pos:Get())
                    end
                    if loot.components.perishable ~= nil then
                        loot.components.perishable:LongUpdate(timeintrap)
                    end
                end
            end
        end

        if self.inst:IsValid() then
            self:Reset()

            if inventory ~= nil and
                self.inst.components.finiteuses ~= nil and
                self.inst.components.finiteuses:GetUses() > 0 then
                inventory:GiveItem(self.inst, nil, pos)
            end
        end
    end
end

function Trap:RemoveBait()
    if self.bait ~= nil then
        if self.baitsortorder ~= nil then
            self.bait.AnimState:SetFinalOffset(0)
        end
        self.bait.components.bait.trap = nil
        self.bait = nil
    end
end

function Trap:SetBait(bait)
    self:RemoveBait()
    if bait ~= nil and bait.components.bait ~= nil then
        self.bait = bait
        if self.baitsortorder ~= nil then
            self.bait.AnimState:SetFinalOffset(self.baitsortorder)
        end
        bait.components.bait.trap = self
        bait.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        if self.onbaited ~= nil then
            self.onbaited(self.inst, self.bait)
        end
    end
end

function Trap:BaitTaken(eater)
    if eater ~= nil and (eater:HasTag(self.targettag) or eater:HasTag("baitstealer")) then
        self.target = eater
        self:StopUpdating()
        self.inst:PushEvent("springtrap")
    else
        self:RemoveBait()
    end
end

function Trap:AcceptingBait()
    return self.isset and self.bait == nil
end

function Trap:OnSave()
    return
    {
        sprung = self.issprung or nil,
        isset = self.isset or nil,
        bait = self.bait ~= nil and self.bait.GUID or nil,
        loot = self.lootprefabs,
        starvedloot = self.starvedlootprefabs,
    },
    {
        self.bait ~= nil and self.bait.GUID or nil,
    }
end

function Trap:OnLoad(data)
    self.issprung = (data.sprung == true)
    self.isset = (data.isset == true)

    --backwards compatability
    self.lootprefabs =
        (type(data.loot) == "string" and { data.loot }) or
        (type(data.loot) == "table" and data.loot) or
        nil

    self.starvedlootprefabs =
        (type(data.starvedloot) == "string" and { data.starvedloot }) or
        (type(data.starvedloot) == "table" and data.starvedloot) or
        { "spoiled_food" }

    if self.isset then
        self:StartUpdate()
    elseif self.issprung then
        self.inst:PushEvent("springtrap", { loading = true })
    end
end

function Trap:LoadPostPass(newents, savedata)
    if savedata.bait ~= nil then
        local bait = newents[savedata.bait]
        if bait ~= nil then
            self:SetBait(bait.entity)
        end
    end
end

return Trap
