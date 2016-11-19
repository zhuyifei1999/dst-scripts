local DeployHelper = Class(function(self, inst)
    self.inst = inst

    --Don't need to add to pristine state since this
    --entire component should always be client-side.
    inst:AddTag("deployhelper")

    self.task = nil
    self.onenablehelper = nil
end)

local function OnStopHelper(inst, self)
    self.task = nil
    if self.onenablehelper ~= nil then
        self.onenablehelper(inst, false)
    end
end

function DeployHelper:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        OnStopHelper(self.inst, self)
    end
    inst:RemoveTag("deployhelper")
end

local function OnStopHelper(inst, self)
    self.task = nil
    if self.onenablehelper ~= nil then
        self.onenablehelper(inst, false)
    end
end

function DeployHelper:StartHelper(duration)
    if self.task == nil then
        self.task = self.inst:DoTaskInTime(duration or 1, OnStopHelper, self)
        if self.onenablehelper ~= nil then
            self.onenablehelper(self.inst, true)
        end
    elseif duration ~= nil and duration > GetTaskRemaining(self.task) then
        self.task:Cancel()
        self.task = self.inst:DoTaskInTime(duration, OnStopHelper, self)
    end
end

return DeployHelper
