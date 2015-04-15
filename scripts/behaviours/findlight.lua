local SEE_DIST = 30
local SAFE_DIST = 5

FindLight = Class(BehaviourNode, function(self, inst)
    BehaviourNode._ctor(self, "FindLight")
    self.inst = inst
    self.targ = nil
end)

function FindLight:DBString()
    return string.format("Stay near light %s", tostring(self.targ))
end

function FindLight:Visit()
    if self.status == READY then
        self:PickTarget()
        self.status = RUNNING
    end

    if self.status == RUNNING then
        if not (self.targ ~= nil and self.targ:IsValid() and self.targ:HasTag("lightsource")) then
            self.status = FAILED
        elseif self.inst:IsNear(self.targ, SAFE_DIST) then
            self.inst.components.locomotor:Stop()
            self:Sleep(.5)
        else
            self.inst.components.locomotor:RunInDirection(self.inst:GetAngleToPoint(self.targ.Transform:GetWorldPosition()))
        end
    end
end

function FindLight:PickTarget()
    self.targ = GetClosestInstWithTag("lightsource", self.inst, SEE_DIST)
end