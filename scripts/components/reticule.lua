--[[
Add this component to items that need a targetting reticule
during use with a controller. Creation of the reticule is handled by
playercontroller.lua equip and unequip events.
--]]
local Reticule = Class(function(self, inst)
    self.inst = inst
    self.targetpos = nil
    self.ease = false
    self.smoothing = 6.66
    self.targetfn = nil
    self.reticuleprefab = "reticule"
    self.reticule = nil
    self.validcolour = { 204 / 255, 131 / 255, 57 / 255, .3 }
    self.invalidcolour = { 1, 0, 0, .3 }
end)

function Reticule:CreateReticule()
    local reticule = SpawnPrefab(self.reticuleprefab)
    if reticule == nil then
        return
    end

    if self.targetfn ~= nil then
        self.targetpos = self.targetfn()
    end

    if self.targetpos ~= nil then
        reticule.Transform:SetPosition(self.targetpos:Get())
    end

    self.reticule = reticule

    self.inst:StartUpdatingComponent(self)
end

function Reticule:DestroyReticule()
    if self.reticule == nil then
        return
    end
    self.reticule:Remove()
    self.reticule = nil
    self.inst:StopUpdatingComponent(self)
end

function Reticule:OnUpdate(dt)
    if self.targetfn == nil then
        return
    end

    self.targetpos = self.targetfn()
    if self.targetpos == nil then
        return
    end

    local x, y, z = self.targetpos:Get()
    if TheWorld.Map:IsPassableAtPoint(x, y, z) and not TheWorld.Map:IsPointNearHole(self.targetpos) then
        self.reticule.components.colourtweener:StartTween(self.validcolour, 0)
        self.reticule.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    else
        self.reticule.components.colourtweener:StartTween(self.invalidcolour, 0)
        self.reticule.AnimState:ClearBloomEffectHandle()
    end

    if self.ease then
        local x0, y0, z0 = self.reticule.Transform:GetWorldPosition()
        x = Lerp(x0, x, dt * self.smoothing)
        y = Lerp(y0, y, dt * self.smoothing)
        z = Lerp(z0, z, dt * self.smoothing)
    end
    self.reticule.Transform:SetPosition(x, y, z)
end

return Reticule