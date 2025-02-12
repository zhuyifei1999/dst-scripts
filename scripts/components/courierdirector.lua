-- FIXME(JBK): Walter ST: Remove this component and pull into Woby wheel.
local CourierDirector = Class(function(self, inst)
    self.inst = inst

    -- Recommended to explicitly add tag to prefab pristine state
    self.inst:AddTag("courierdirector")
end)

function CourierDirector:OnRemoveFromEntity()
    self.inst:RemoveTag("courierdirector")
end

return CourierDirector
