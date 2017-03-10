local BlinkStaff = Class(function(self, inst)
    self.inst = inst
    self.onblinkfn = nil
    self.blinktask = nil
end)

function BlinkStaff:SpawnEffect(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("sand_puff_large_back").Transform:SetPosition(x, y - .1, z)
    SpawnPrefab("sand_puff_large_front").Transform:SetPosition(x, y, z)
end

local function OnBlinked(caster, self, pt)
    if caster.components.health ~= nil then
        caster.components.health:SetInvincible(false)
    end
    caster.Physics:Teleport(pt:Get())
    self:SpawnEffect(caster)
    caster:Show()
    if caster.DynamicShadow ~= nil then
        caster.DynamicShadow:Enable(true)
    end
    caster.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
end

function BlinkStaff:Blink(pt, caster)
    if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) or TheWorld.Map:IsPointNearHole(pt) then
        return false
    end

    if self.blinktask ~= nil then
        self.blinktask:Cancel()
    end

    self:SpawnEffect(caster)
    caster.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
    caster:Hide()
    if caster.DynamicShadow ~= nil then
        caster.DynamicShadow:Enable(false)
    end
    if caster.components.health ~= nil then
        caster.components.health:SetInvincible(true)
    end

    self.blinktask = caster:DoTaskInTime(.25, OnBlinked, self, pt)

    if self.onblinkfn ~= nil then
        self.onblinkfn(self.inst, pt, caster)
    end

    return true
end

return BlinkStaff
