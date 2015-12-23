local function OnAnimOver(inst)
    if inst.sg:HasStateTag("idle") then
        inst.components.frostybreather:EmitOnce()
    end
end

local FrostyBreather = Class(function(self, inst)
    self.inst = inst
    self.breath = nil
    self.offset = Vector3(0, 0, 0)

    self.inst:ListenForEvent("animover", OnAnimOver)

    self.inst:StartUpdatingComponent(self)
end)

function FrostyBreather:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("animover", OnAnimOver)
end

function FrostyBreather:OnUpdate(dt)
    if self.breath == nil and TheWorld.state.temperature < TUNING.FROSTY_BREATH then
        self:Enable()
    elseif self.breath ~= nil and TheWorld.state.temperature > TUNING.FROSTY_BREATH then
        self:Disable()
    end
end

function FrostyBreather:Enable()
    if self.breath == nil then
        self.breath = SpawnPrefab("frostbreath")
        self.inst:AddChild(self.breath)
        self.breath.Transform:SetPosition(self.offset:Get())
    end
end

function FrostyBreather:Disable()
    if self.breath ~= nil then
        self.inst:RemoveChild(self.breath)
        self.breath:Remove()
        self.breath = nil
    end
end

function FrostyBreather:EmitOnce()
    if self.breath ~= nil and self.inst.AnimState:GetCurrentFacing() ~= FACING_UP then
        self.breath:Emit()
    end
end

function FrostyBreather:SetOffset(x, y, z)
    self.offset.x, self.offset.y, self.offset.z = x, y, z
    if self.breath ~= nil then
        self.breath.Transform:SetPosition(x, y, z)
    end
end

function FrostyBreather:GetOffset()
    return self.offset:Get()
end

return FrostyBreather
