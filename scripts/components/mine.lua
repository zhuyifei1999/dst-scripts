local mine_test_fn = function(dude, inst)
    return not (dude.components.health ~= nil and
                dude.components.health:IsDead())
        and dude.components.combat:CanBeAttacked(inst)
end
local mine_test_tags = { "monster", "character", "animal" }
-- See entityreplica.lua
local mine_must_tags = { "_combat" }

local function MineTest(inst, self)
    if self.radius ~= nil then
        local notags = { "notraptrigger", "flying", "playerghost" }
        table.insert(notags, self.alignment)

        local target = FindEntity(inst, self.radius, mine_test_fn, mine_must_tags, notags, mine_test_tags)
        if target ~= nil then
            self:Explode(target)
        end
    end
end

local function OnPutInInventory(inst)
    inst.components.mine:Deactivate()
end

local function onissprung(self, onissprung)
    if onissprung then
        self.inst:AddTag("minesprung")
    else
        self.inst:RemoveTag("minesprung")
    end
end

local Mine = Class(function(self, inst)
    self.inst = inst

    self.radius = nil
    self.onexplode = nil
    self.onreset = nil
    self.onsetsprung = nil
    self.target = nil
    self.issprung = false
    self.inactive = true
    
    self.alignment = "player"
    self.inst:ListenForEvent("onputininventory", OnPutInInventory)
end,
nil,
{
    issprung = onissprung,
})

function Mine:OnRemoveFromEntity()
    self:StopTesting()
    self.inst:RemoveEventCallback("onputininventory", OnPutInInventory)
    self.inst:RemoveTag("minesprung")
end

function Mine:SetRadius(radius)
    self.radius = radius
end

function Mine:SetOnExplodeFn(fn)
    self.onexplode = fn
end

function Mine:SetOnSprungFn(fn)
    self.onsetsprung = fn
end

function Mine:SetOnResetFn(fn)
    self.onreset = fn
end

function Mine:SetOnDeactivateFn(fn)
    self.ondeactivate = fn
end

function Mine:SetAlignment(alignment)
    self.alignment = alignment
end

function Mine:SetReusable(reusable)
    self.canreset = reusable
end

function Mine:Reset()
    self:StopTesting()
    self.target = nil
    self.issprung = false
    self.inactive = false
    if self.onreset ~= nil then
        self.onreset(self.inst)
    end
    self:StartTesting()
end

function Mine:StartTesting()
    if self.testtask ~= nil then
        self.testtask:Cancel()
    end
    self.testtask = self.inst:DoPeriodicTask(1 + math.random(), MineTest, math.random(.9, 1), self)
end

function Mine:StopTesting()
    if self.testtask ~= nil then
        self.testtask:Cancel()
        self.testtask = nil
    end
end

function Mine:Deactivate()
    self:StopTesting()
    self.issprung = false
    self.inactive = true    
    if self.ondeactivate ~= nil then
        self.ondeactivate(self.inst)
    end
end

function Mine:GetTarget()
    return self.target
end

function Mine:Explode(target)
    self:StopTesting()
    self.target = target
    self.issprung = true
    self.inactive = false    
    ProfileStatsAdd("trap_sprung_"..(target ~= nil and target.prefab or ""))
    if self.onexplode ~= nil then
        self.onexplode(self.inst, target)
    end
end

function Mine:OnSave()
    return (self.issprung and { sprung = true })
        or (self.inactive and { inactive = true })
        or nil
end

function Mine:OnLoad(data)
    if data.sprung then
        self.inactive = false
        self.issprung = true
        self:StopTesting()
        if self.onsetsprung ~= nil then
            self.onsetsprung(self.inst)
        end
    elseif data.inactive then
        self:Deactivate()
    else
        self:Reset()
    end
end

Mine.OnRemoveEntity = Mine.StopTesting

return Mine
