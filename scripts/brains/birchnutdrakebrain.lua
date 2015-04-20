require "behaviours/panic"
require "behaviours/standstill"
require "behaviours/chaseandattack"
require "behaviours/leash"
require "behaviours/wander"

local BirchNutDrakeBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local MAX_WANDER_DIST = 5

local function ExitAction(inst)
    if not inst:HasTag("exit") then
        inst:AddTag("exit")
        inst.sg:GoToState("idle")
        inst:DoTaskInTime(.3, function(inst)
            inst.sg:GoToState("exit")
        end)
    end
end

function BirchNutDrakeBrain:OnStart()
    local root = 
    PriorityNode(
    {
        WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        Leash(self.inst, self.inst.components.knownlocations:GetLocation("spawnpoint"), 20, 5),
        ChaseAndAttack(self.inst, 12, 21),
        --StandStill(self.inst),
        --Wander(self.inst, function() return self.inst:GetPosition() end, MAX_WANDER_DIST),
        DoAction(self.inst, ExitAction, "exit", true),
    }, .25)
    self.bt = BT(self.inst, root)
end

function BirchNutDrakeBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", Point(self.inst.Transform:GetWorldPosition()))
end

return BirchNutDrakeBrain