local function ondryable(self)
    if self.product ~= nil and self.drytime ~= nil then
        self.inst:AddTag("dryable")
    else
        self.inst:RemoveTag("dryable")
    end
end

local Dryable = Class(function(self, inst)
    self.inst = inst
    self.product = nil
    self.drytime = nil
end,
nil,
{
    product = ondryable,
    drytime = ondryable,
})

function Dryable:OnRemoveFromEntity()
    self.inst:RemoveTag("dryable")
end

function Dryable:SetProduct(product)
    self.product = product
end

function Dryable:GetProduct()
    return self.product
end

function Dryable:GetDryingTime()
    return self.drytime
end

function Dryable:SetDryTime(time)
    self.drytime = time
end

return Dryable