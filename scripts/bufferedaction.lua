
BufferedAction = Class(function(self, doer, target, action, invobject, pos, recipe, distance, forced)
    self.doer = doer
    self.target = target
    self.initialtargetowner = target ~= nil and target.components.inventoryitem ~= nil and target.components.inventoryitem.owner or nil
    self.action = action
    self.invobject = invobject
    self.doerownsobject = doer ~= nil and invobject ~= nil and invobject.replica.inventoryitem ~= nil and invobject.replica.inventoryitem:IsHeldBy(doer)
    self.pos = pos
    self.onsuccess = {}
    self.onfail = {}
    self.recipe = recipe
    self.options = {}
    self.distance = distance or action.distance 
    self.forced = forced
    self.autoequipped = nil --true if invobject should've been auto-equipped
end)

function BufferedAction:Do()
    if self:IsValid() then
        
        local success, reason = self.action.fn(self)
        if success then
            if self.invobject and self.invobject:IsValid() then
                self.invobject:OnUsedAsItem(self.action)
            end
            self:Succeed()
            
        else
            self:Fail()
        end
        
        return success, reason
    end
end

function BufferedAction:TestForStart()
    if self:IsValid() then
        if self.action.testfn then
            local pass, reason = self.action.testfn(self)
            return pass, reason
        else
            return true
        end
    end
end

function BufferedAction:IsValid()
    return (self.invobject == nil or self.invobject:IsValid()) and
           (self.doer == nil or (self.doer:IsValid() and (not self.autoequipped or self.doer.replica.inventory:GetActiveItem() == nil))) and
           (self.target == nil or (self.target:IsValid() and self.initialtargetowner == (self.target.components.inventoryitem ~= nil and self.target.components.inventoryitem.owner or nil))) and
           (not self.doerownsobject or (self.doer ~= nil and self.invobject ~= nil and self.invobject.replica.inventoryitem ~= nil and self.invobject.replica.inventoryitem:IsHeldBy(self.doer))) and
           (self.validfn == nil or self.validfn())
end

function BufferedAction:GetActionString()
    if self.doer and self.doer.ActionStringOverride then
        local str = self.doer.ActionStringOverride(self.doer, self)
        if str then
            return str
        end
    end

    return GetActionString(self.action.id, self.action.strfn ~= nil and self.action.strfn(self) or nil)
end

function BufferedAction:__tostring()
    local str= self:GetActionString() .. " " .. tostring(self.target)
    
    if self.invobject then
        str = str.." With Inv:" .. tostring(self.invobject)
    end
    
    if self.recipe then
        str = str .. " Recipe:" ..self.recipe
    end
    return str
end

function BufferedAction:AddFailAction(fn)
    table.insert(self.onfail, fn)
end

function BufferedAction:AddSuccessAction(fn)
    table.insert(self.onsuccess, fn)
end

function BufferedAction:Succeed()
    for k,v in pairs(self.onsuccess) do
        v()
    end
    
    self.onsuccess = {}
    self.onfail = {}
    
end

function BufferedAction:Fail()
    for k,v in pairs(self.onfail) do
        v()
    end
    
    self.onsuccess = {}
    self.onfail = {}
end
