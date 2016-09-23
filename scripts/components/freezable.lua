local states =
{
    FROZEN = "FROZEN",
    THAWING = "THAWING",
    NORMAL = "NORMAL",
}

local FREEZE_COLOUR = { 82 / 255, 115 / 255, 124 / 255, 0 }

local function WearOff(inst, self)
    if self.state == states.FROZEN then
        self:Thaw()
    elseif self.state == states.THAWING then
        self:Unfreeze()
    elseif self.coldness > 0 then
        self.coldness = math.max(0, self.coldness - 1)
        if self.coldness > 0 then
            self:StartWearingOff()
        end
    end
    self:UpdateTint()
end

local function OnAttacked(inst, data)
    local self = inst.components.freezable
    if self:IsFrozen() then
        self.damagetotal = self.damagetotal + math.abs(data.damage)
        if self.damagetotal >= self.damagetobreak then
            self:Unfreeze()
        end
    end
end
-----------------------------------------------------------------------------------------------------

local Freezable = Class(function(self, inst)
    self.inst = inst
    self.state = states.NORMAL
    self.resistance = 1
    self.coldness = 0
    self.wearofftime = 10

    self.damagetotal = 0
    self.damagetobreak = 0

    self.fxlevel = 1
    self.fxdata = {}
    --self.fxchildren = {}

    self.inst:ListenForEvent("attacked", OnAttacked)
    self.inst:AddTag("freezable")
end)

function Freezable:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("attacked", OnAttacked)
    self.inst:RemoveTag("freezable")
end

function Freezable:SetResistance(resist)
    self.resistance = resist
end

function Freezable:SetDefaultWearOffTime(wearofftime)
    self.wearofftime = wearofftime
end

function Freezable:AddShatterFX(prefab, offset, followsymbol)
    table.insert(self.fxdata, { prefab = prefab, x = offset.x, y = offset.y, z = offset.z, follow = followsymbol })
end

function Freezable:SetShatterFXLevel(level, percent)
    self.fxlevel = level
--[[
    for k, v in pairs(self.fxchildren) do
        if v.components.shatterfx then
            v.components.shatterfx:SetLevel(level)
        end
    end
--]]
end

function Freezable:SpawnShatterFX()
    for k, v in pairs(self.fxdata) do
        local fx = SpawnPrefab(v.prefab)
        if fx ~= nil then
            if v.follow ~= nil then
                local follower = fx.entity:AddFollower()
                follower:FollowSymbol(self.inst.GUID, v.follow, v.x, v.y, v.z)
            else
                self.inst:AddChild(fx)
                fx.Transform:SetPosition(v.x, v.y, v.z)
            end
            --table.insert(self.fxchildren, fx)
            if fx.components.shatterfx ~= nil then
                fx.components.shatterfx:SetLevel(self.fxlevel)
            end
        end
    end
end

function Freezable:IsFrozen()
    return self.state == states.FROZEN or self.state == states.THAWING
end

function Freezable:IsThawing()
    return self.state == states.THAWING
end

function Freezable:GetDebugString()
    return string.format("%s: %d / %d", self.state, self.coldness, self.resistance)
end

function Freezable:AddColdness(coldness, freezetime)
    self.coldness = math.max(0, self.coldness + coldness)
    self:UpdateTint()
    --V2C: when removing coldness, don't update freeze states here
    if coldness > 0 then
        if self.coldness >= self.resistance or self:IsFrozen() then
            self:Freeze(freezetime)
        elseif self.coldness > 0 then
            self:StartWearingOff()
        end
    end
end

function Freezable:StartWearingOff(wearofftime)
    if self.wearofftask ~= nil then
        self.wearofftask:Cancel()
    end
    self.wearofftask = self.inst:DoTaskInTime(wearofftime or self.wearofftime, WearOff, self)
end

function Freezable:UpdateTint()
    if self.inst.AnimState ~= nil then
        if self:IsFrozen() or self.coldness >= self.resistance then
            self.inst.AnimState:SetAddColour(unpack(FREEZE_COLOUR))
        elseif self.coldness <= 0 then
            self.inst.AnimState:SetAddColour(0, 0, 0, 0)
        else
            local percent = self.coldness / self.resistance
            self.inst.AnimState:SetAddColour(
                FREEZE_COLOUR[1] * percent,
                FREEZE_COLOUR[2] * percent,
                FREEZE_COLOUR[3] * percent,
                FREEZE_COLOUR[4] * percent
            )
        end
    end
end

--V2C: Calling this direclty isn't great; :AddColdness instead!
function Freezable:Freeze(freezetime)
    if self.inst.entity:IsVisible() and not (self.inst.components.health ~= nil and self.inst.components.health:IsDead()) then
        if self.onfreezefn ~= nil then
            self.onfreezefn(self.inst)
        end

        local prevState = self.state
        self.state = states.FROZEN
        self:StartWearingOff(freezetime)
        self:UpdateTint()

        if self.inst.brain ~= nil then
            self.inst.brain:Stop()
        end

        if self.inst.components.combat ~= nil then
            self.inst.components.combat:SetTarget(nil)
        end

        if self.inst.components.locomotor ~= nil then
            self.inst.components.locomotor:Stop()
        end

        if self.state ~= prevState then
            self.inst:PushEvent("freeze")
        end
    end
end

function Freezable:Unfreeze()
    if self:IsFrozen() and not (self.inst.components.health ~= nil and self.inst.components.health:IsDead()) then
        self.state = states.NORMAL
        self.coldness = 0
        self.damagetotal = 0

        self:SpawnShatterFX()
        self:UpdateTint()

        if self.inst.brain ~= nil then
            self.inst.brain:Start()
        end

        self.inst:PushEvent("unfreeze")

        -- prevent going from unfreeze immediately into an attack, it looks weird
        if self.inst.components.combat ~= nil then
            self.inst.components.combat:BlankOutAttacks(0.3)
        end
    end
end

function Freezable:Thaw(thawtime)
    if self:IsFrozen() and not (self.inst.components.health ~= nil and self.inst.components.health:IsDead()) then
        self.state = states.THAWING
        self.coldness = 0
        self.inst:PushEvent("onthaw")
        self:StartWearingOff(thawtime or self.wearofftime)
    end
end

-- Note: This doesn't push any events!
function Freezable:Reset()
    self.state = states.NORMAL
    self.coldness = 0
    self:UpdateTint()
end

return Freezable
