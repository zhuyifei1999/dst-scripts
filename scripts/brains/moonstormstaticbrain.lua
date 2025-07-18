require "behaviours/wander"

local MAX_WANDER_DIST = 8

local WanderTimes = {
    minwalktime = 3,
    randwalktime = 1,
    minwaittime = 0.5,
    randwaittime = 1,
}

local MoonstormStaticBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetDirectionFn(inst)
    local angle = math.random() * PI2
    local x, y, z = inst.Transform:GetWorldPosition()
    local tx, tz = x + math.cos(angle), z + math.sin(angle)
    local moonstorms = TheWorld.net and TheWorld.net.components.moonstorms or nil
    if moonstorms then
        if not moonstorms:IsXZInMoonstorm(tx, tz) then
            for i = 1, 8 do
                local testangle = angle + (i / PI2)
                tx, tz = x + math.cos(testangle), z + math.sin(testangle)
                if moonstorms:IsXZInMoonstorm(tx, tz) then
                    return testangle
                end
            end
        end
    end
    return angle
end

function MoonstormStaticBrain:OnStart()
    local root = PriorityNode({
        Wander(self.inst, function() return self.inst:GetPosition() end, MAX_WANDER_DIST, WanderTimes, GetDirectionFn),
    }, 1)

    self.bt = BT(self.inst, root)
end

return MoonstormStaticBrain
