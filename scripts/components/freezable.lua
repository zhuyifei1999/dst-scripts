local states = 
{
    FROZEN = "FROZEN",
    THAWING = "THAWING",
    NORMAL = "NORMAL",
}


local function WearOff(inst)
    local freezable = inst.components.freezable
    if freezable then
        if freezable.state == states.FROZEN then
            freezable:Thaw()
        elseif freezable.state == states.THAWING then
            freezable:Unfreeze()
        elseif freezable.coldness > 0 then
            freezable.coldness = math.max(0, freezable.coldness - 1)
            if freezable.coldness > 0 then
                freezable:StartWearingOff()
            end
        end
        freezable:UpdateTint()
    end
end

local function OnAttacked(inst, data)
    local freezable = inst.components.freezable

    if freezable and freezable:IsFrozen() then
        freezable.damagetotal = freezable.damagetotal + math.abs(data.damage)
        if freezable.damagetotal >= freezable.damagetobreak then
            freezable:Unfreeze()
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

function Freezable:SetResistance(resist)
    self.resistance = resist
end

function Freezable:SetDefaultWearOffTime(wearofftime)
    self.wearofftime = wearofftime
end

function Freezable:AddShatterFX(prefab, offset, followsymbol)
    table.insert(self.fxdata, {prefab=prefab, x = offset.x, y=offset.y, z=offset.z, follow=followsymbol})
end

function Freezable:SetShatterFXLevel(level, percent)
    self.fxlevel = level
--[[
	for k,v in pairs(self.fxchildren) do
	    if v.components.shatterfx then
	        v.components.shatterfx:SetLevel(level)
        end
	end
--]]
end

function Freezable:SpawnShatterFX()
    for k,v in pairs(self.fxdata) do
		local fx = SpawnPrefab(v.prefab)
		if fx then
			if v.follow then
				local follower = fx.entity:AddFollower()
				follower:FollowSymbol(self.inst.GUID, v.follow, v.x,v.y,v.z)
			else
			    self.inst:AddChild(fx)
			    fx.Transform:SetPosition(v.x, v.y, v.z)
			end
			--table.insert(self.fxchildren, fx)
			if fx.components.shatterfx then
				fx.components.shatterfx:SetLevel(self.fxlevel)
			end
		end
	end
end

function Freezable:IsFrozen( )
    return self.state == states.FROZEN or self.state == states.THAWING
end

function Freezable:GetDebugString()
    return string.format("%s: %d", self.state, self.coldness)
end

function Freezable:AddColdness(coldness, freezetime)
    self.coldness = math.max(0, self.coldness + coldness)
    self:UpdateTint()
    if self.coldness > self.resistance or self:IsFrozen() then
        self:Freeze(freezetime)
    elseif self.coldness == self.resistance then
        self:Freeze(freezetime)
    elseif self.coldness > 0 then
        self:StartWearingOff()
    end
end

function Freezable:StartWearingOff(wearofftime)
    if self.wearofftask then
        self.wearofftask:Cancel()
        self.wearofftask = nil
    end
    self.wearofftask = self.inst:DoTaskInTime(wearofftime or self.wearofftime, WearOff)
end

function Freezable:UpdateTint()
    if self.inst.AnimState then
        local defaultColor = Vector3(0, 0, 0)
        local frozenColor = Vector3(82/255,115/255,124/255)
        local r,g,b = defaultColor.x,defaultColor.y,defaultColor.z
        if self:IsFrozen() then
            r,g,b = frozenColor.x,frozenColor.y,frozenColor.z
        elseif self.coldness == 0 then
            r,g,b = defaultColor.x,defaultColor.y,defaultColor.z
        else
            local percent = self.coldness / self.resistance
            r = defaultColor.x+percent*frozenColor.x
            g = defaultColor.y+percent*frozenColor.y
            b = defaultColor.z+percent*frozenColor.z
        end

        self.inst.AnimState:SetAddColour(r, g, b, 0)
    end
end

function Freezable:Freeze(freezetime)
    if self.inst.entity:IsVisible() and not (self.inst.components.health and self.inst.components.health:IsDead()) then

        if self.onfreezefn then
            self.onfreezefn(self.inst)
        end

        local prevState = self.state
        self.state = states.FROZEN
        self:StartWearingOff(freezetime)
        self:UpdateTint()

        if self.inst.brain then
            self.inst.brain:Stop()
        end
        
        if self.inst.components.combat then
            self.inst.components.combat:SetTarget(nil)
        end
        
        if self.inst.components.locomotor then
            self.inst.components.locomotor:Stop()
        end

        if self.state ~= prevState then 
            self.inst:PushEvent("freeze")
        end
    end
end

function Freezable:Unfreeze()
    if (not self.inst.components.health or not self.inst.components.health:IsDead()) and self:IsFrozen() then

        self.state = states.NORMAL
        self.coldness = 0
        self.damagetotal = 0
        
        self:SpawnShatterFX()
        self:UpdateTint()
        
        if self.inst.brain then
            self.inst.brain:Start()
        end

        self.inst:PushEvent("unfreeze")

        -- prevent going from unfreeze immediately into an attack, it looks weird
        if self.inst.components.combat then
            self.inst.components.combat:BlankOutAttacks(0.3)
        end
    end
end

function Freezable:Thaw(thawtime)
    if (not self.inst.components.health or not self.inst.components.health:IsDead()) and self:IsFrozen() then
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

function Freezable:OnRemoveFromEntity()
    self.inst:RemoveTag("freezable") 
end


return Freezable
