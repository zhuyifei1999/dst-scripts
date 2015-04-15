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
	self.validcolour = {204/255,131/255,57/255,.3}
	self.invalidcolour = {1,0,0,.3}

end)

function Reticule:CreateReticule()
	local reticule = SpawnPrefab(self.reticuleprefab)

	if not reticule then return end

	if self.targetfn then
		self.targetpos = self.targetfn()
	end

	if self.targetpos then
		reticule.Transform:SetPosition(self.targetpos:Get())
	end

	self.reticule = reticule

	self.inst:StartUpdatingComponent(self)
end

function Reticule:DestroyReticule()
	if not self.reticule then return end
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

	local x0, y0, z0 = self.reticule.Transform:GetWorldPosition()
	local x, y, z = self.targetpos:Get()

	if self.ease then
		x = Lerp(x0, self.targetpos.x, dt * self.smoothing)
		y = Lerp(y0, self.targetpos.y, dt * self.smoothing)
		z = Lerp(z0, self.targetpos.z, dt * self.smoothing)		
	end
	
    if TheWorld.Map:IsPassableAtPoint(self.targetpos:Get()) then
        self.reticule.components.colourtweener:StartTween(self.validcolour, 0)
        self.reticule.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        self.reticule:Show()
    else
        self.reticule.components.colourtweener:StartTween(self.invalidcolour, 0)
        self.reticule.AnimState:ClearBloomEffectHandle()
        self.reticule:Hide()
    end

	self.reticule.Transform:SetPosition(x, y, z)
end

return Reticule