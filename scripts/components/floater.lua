local Floater = Class(function(self, inst)
    self.inst = inst

    if TheNet:GetIsMasterSimulation() then
        self.inst:ListenForEvent("on_landed", function() self:OnLandedServer() end)
        self.inst:ListenForEvent("on_no_longer_landed", function() self:OnNoLongerLandedServer() end)
        self.inst:ListenForEvent("onremove", function() self:OnNoLongerLandedServer() end)
    end

    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("floater.landed", function() self:OnLandedClient() end)
        self.inst:ListenForEvent("floater.nolongerlanded", function() self:OnNoLongerLandedClient() end)
    end

    self.size = "small"
    self.vert_offset = nil
    self.xscale = 1.0
    self.yscale = 1.0
    self.zscale = 1.0
    self.should_parent_effect = true
    self.do_bank_swap = false
    self.float_index = 1
    self.swap_data = nil
    self.showing_effect = false

    self.landed_event = net_event(inst.GUID, "floater.landed")
    self.no_longer_landed_event = net_event(inst.GUID, "floater.nolongerlanded")
end)

--small/med/large
function Floater:SetSize(size)
	self.size = size
end

function Floater:SetVerticalOffset(offset)
    self.vert_offset = offset
    if self.vert_offset ~= nil then
        if self.front_fx ~= nil then
            self.front_fx.Transform:SetPosition(0, self.vert_offset, 0)
        end
        if self.back_fx ~= nil then
            self.back_fx.Transform:SetPosition(0, self.vert_offset, 0)
        end
    end
end

function Floater:SetScale(scale)
    if scale ~= nil then
        if type(scale) == "table" then
            self.xscale = scale[1]
            self.yscale = scale[2]
            self.zscale = scale[3]
        else
            self.xscale = scale
            self.yscale = scale
            self.zscale = scale
        end

        if self.front_fx ~= nil then
            self.front_fx.Transform:SetScale(self.xscale, self.yscale, self.zscale)
        end
        if self.back_fx ~= nil then
            self.back_fx.Transform:SetScale(self.xscale, self.yscale, self.zscale)
        end
    end
end

function Floater:SetBankSwapOnFloat(should_bank_swap, float_index, swap_data)
    self.do_bank_swap = should_bank_swap
    self.float_index = float_index or 1
    self.swap_data = swap_data
end

function Floater:ShouldShowEffect()
	local pos_x, pos_y, pos_z = self.inst.Transform:GetWorldPosition()

	return  not TheWorld.Map:IsPassableAtPoint(pos_x, 0, pos_z) and
            not TheWorld.Map:IsVisualGroundAtPoint(pos_x, 0, pos_z)
end

function Floater:AttachEffect(effect)
    if self.should_parent_effect then
        effect.entity:SetParent(self.inst.entity)
        effect.Transform:SetPosition(0, self.vert_offset or 0, 0)
    else
        local my_x, my_y, my_z = self.inst.Transform:GetWorldPosition()
        effect.Transform:SetPosition(my_x, my_y + (self.vert_offset or 0), my_z)
    end

    effect.Transform:SetScale(self.xscale, self.yscale, self.zscale)
end

function Floater:OnLandedServer()
    if not self.showing_effect and self:ShouldShowEffect() then
        -- If something lands in a place where the water effect should be shown, and it has an inventory component,
        -- update the inventory component to represent the associated wetness.
        -- Don't apply the wetness to something held by someone, though.
        if self.inst.components.inventoryitem ~= nil and not self.inst.components.inventoryitem:IsHeld() then
            self.inst.components.inventoryitem:AddMoisture(75)
        end

        self.inst:PushEvent("floater_startfloating")
        self.landed_event:push()
        self.showing_effect = true
    end
end

function Floater:OnLandedClient()
    self.front_fx = SpawnPrefab("float_fx_front")
    self:AttachEffect(self.front_fx)
    self.front_fx.AnimState:PlayAnimation("idle_front_" .. self.size, true)

    self.back_fx = SpawnPrefab("float_fx_back")
    self:AttachEffect(self.back_fx)
    self.back_fx.AnimState:PlayAnimation("idle_back_" .. self.size, true)

    self.inst.AnimState:SetFloatParams(-0.05, 1.0)

    if self.do_bank_swap then
        if self.float_index < 0 then
            self.inst.AnimState:SetBankAndPlayAnimation("floating_item", "left")
        else
            self.inst.AnimState:SetBankAndPlayAnimation("floating_item", "right")
        end
        self.inst.AnimState:SetTime(math.abs(self.float_index) * FRAMES)
        self.inst.AnimState:Pause()

        if self.swap_data ~= nil then
            local symbol = self.swap_data.sym_name or self.swap_data.sym_build
            self.inst.AnimState:OverrideSymbol("swap_spear", self.swap_data.sym_build, symbol)
        end
    end    
end

function Floater:OnNoLongerLandedServer()
    if self.showing_effect then
        self.inst:PushEvent("floater_stopfloating")
        self.no_longer_landed_event:push()
        self.showing_effect = false
    end
end

function Floater:OnNoLongerLandedClient()
    self.inst.AnimState:SetFloatParams(0.0, 0.0)

    if self.front_fx ~= nil and self.front_fx:IsValid() then
        self.front_fx:Remove()
        self.front_fx = nil
    end
    if self.back_fx ~= nil and self.back_fx:IsValid() then
        self.back_fx:Remove()
        self.back_fx = nil
    end

    if self.do_bank_swap then
        local bank = self.swap_data ~= nil and self.swap_data.bank or self.inst.prefab
        local anim = self.swap_data ~= nil and self.swap_data.anim or "idle"
        self.inst.AnimState:SetBankAndPlayAnimation(bank, anim)

        if self.swap_data ~= nil then
            self.inst.AnimState:ClearOverrideSymbol("swap_spear")
        end
    end    
end

return Floater
