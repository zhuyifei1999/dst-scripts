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

function Trap:StartUpdate()
	if not self.task then
		self.task = self.inst:DoPeriodicTask(self.checkperiod, function() self:OnUpdate(self.checkperiod) end)
	end
end

function Trap:OnUpdate(dt)
    if self.isset then
        local guy = FindEntity(self.inst, self.range, function(guy)
            return not (guy.components.health and guy.components.health:IsDead() )
            and not (guy.components.inventoryitem and guy.components.inventoryitem:IsHeld() )
        end, {self.targettag})
        if guy then
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
        if self.onharvest then
            self.onharvest(self.inst)
        end

        local timeintrap = self.inst.components.timer:GetTimeElapsed("foodspoil") or TUNING.TOTAL_DAY_TIME * 2

        if self.starvedlootprefabs then
            for k,v in ipairs(self.starvedlootprefabs) do
                local loot = SpawnPrefab(v)
                if loot then
                    loot.Transform:SetPosition(self.inst:GetPosition():Get())

                    if loot.components.perishable then
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
    local perishTime = TUNING.TOTAL_DAY_TIME * 2
    
    if self.target.components.perishable then
        perishTime = self.target.components.perishable.perishremainingtime
    end
    
    self.starvedlootprefabs = {"spoiled_food"}
    
    if self.target.components.lootdropper then
        self.starvedlootprefabs = self.target.components.lootdropper:GenerateLoot()
    end

    self.inst.components.timer:StartTimer("foodspoil", perishTime)
end

function Trap:StopStarvation()
    self.inst.components.timer:StopTimer("foodspoil")
    self.starvedlootprefabs = nil
end

function Trap:DoSpring()
    self:StopUpdating()
	if self.target and self.target:HasTag("insprungtrap") then
		return -- this animal is already in a trap this tick, just waiting to be Remove()'d
	end
    
    if self.target and self.target:IsValid() and not self.target:IsInLimbo() then
        if self.onspring then
            self.onspring(self.inst, self.target, self.bait)
        end
        if self.target.components.inventoryitem and self.target.components.inventoryitem.trappable then
            self.lootprefabs = {self.target.prefab}
        else
            if self.target.components.lootdropper and self.target.components.lootdropper.trappable then
                self.lootprefabs = self.target.components.lootdropper:GenerateLoot()
            end
        end

        self:StartStarvation()

        if self.lootprefabs then
            self.target:PushEvent("ontrapped", {trapper=self.inst, bait=self.bait})
            ProfileStatsAdd("trapped_" .. self.target.prefab)
    		self.target:AddTag("insprungtrap") -- prevents the same ent from being caught in two traps on the same frame
            self.target:Remove()
        end
    end
    
    if self.bait and self.bait:IsValid() then
        if self.target and self.target:HasTag("baitstealer") and self.target.components.inventory then
            self.target.components.inventory:GiveItem(self.bait)
            self:RemoveBait()
        else
            self.bait:Remove()
        end
    else
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, 2)
        for k,v in pairs(ents) do
            if v.components.bait then
                -- check if the bait type is a valid bait for the thing we're trapping
                local validbait = false
                if self.target and self.target:HasTag("mole") and v:HasTag("molebait") then validbait = true end
                if not validbait and self.target and self.target.components.eater then
                    validbait = self.target.components.eater:CanEat(v)
                end
                -- don't remove items out of nearby chests, or the user's inventory
                if validbait and (v.components.inventoryitem == nil or v.components.inventoryitem.owner == nil) then
                    if self.target and self.target:HasTag("baitstealer") and self.target.components.inventory then
                        self.target.components.inventory:GiveItem(v)
                    else
                        v:Remove()
                    end
                    break
                end
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
        self.inst:PushEvent("harvesttrap")
        if self.onharvest then
			self.onharvest(self.inst)
        end
        
        local timeintrap = self.inst.components.timer:GetTimeElapsed("foodspoil") or 0
        if self.lootprefabs and doer.components.inventory then
            for k,v in ipairs(self.lootprefabs) do
                local loot = SpawnPrefab(v)
                if loot then
                    doer.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
                        if loot.components.perishable then
                        loot.components.perishable:LongUpdate(timeintrap)
                    end
                end
            end
        end
        self:Reset()
        
        if self.inst.components.finiteuses and self.inst.components.finiteuses:GetUses() > 0 then
            doer.components.inventory:GiveItem(self.inst, nil, self.inst:GetPosition())
        end
    end
end

function Trap:RemoveBait()
    if self.bait then
        if self.baitlayer then
            self.bait.AnimState:SetSortOrder(0)
        end
        self.bait.components.bait.trap = nil
        self.bait = nil
    end
end

function Trap:SetBait(bait)
    self:RemoveBait()
    if bait and bait.components.bait then
        self.bait = bait
        if self.baitlayer then
            self.bait.AnimState:SetSortOrder(self.baitsortorder)
        end
        bait.components.bait.trap = self
        bait.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        if self.onbaited then
            self.onbaited(self.inst, self.bait)
        end
    end
end

function Trap:BaitTaken(eater)
    if eater and eater:HasTag(self.targettag) then
        self.target = eater
        self:StopUpdating()
        self.inst:PushEvent("springtrap")
    elseif eater and eater:HasTag("baitstealer") then
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
        sprung = self.issprung,
        isset = self.isset,
        bait = self.bait and self.bait.GUID or nil,
        loot = self.lootprefabs,
        starvedloot = self.starvedlootprefabs,
    }, 
    {
		self.bait and self.bait.GUID or nil
    }
end

function Trap:OnLoad(data)
    self.sprung = data.sprung
    self.isset = data.isset
    
    --backwards compatability
    if type(data.loot) == "string" then
        self.lootprefabs = {data.loot}
    elseif type(data.loot) == "table" then
        self.lootprefabs = data.loot
    end

    if type(data.starvedloot) == "string" then
        self.starvedlootprefabs = {data.starvedloot}
    elseif type(data.starvedloot) == "table" then
        self.starvedlootprefabs = data.starvedloot
    else
        self.starvedlootprefabs = {"spoiled_food"}
    end
    
    if self.isset then
        self:StartUpdate()
    elseif self.sprung then
        self.inst:PushEvent("springtrap")
    end
    
end

function Trap:LoadPostPass(newents, savedata)
    if savedata.bait then
        local bait = newents[savedata.bait]
        if bait then
            self:SetBait(bait.entity)
        end
    end
end

return Trap
