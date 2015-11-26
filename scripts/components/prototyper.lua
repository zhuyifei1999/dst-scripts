--Note: If you want to add a new tech tree you must also add it into the "NO_TECH" constant in constants.lua

local Prototyper = Class(function(self, inst)
    self.inst = inst

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("prototyper")

    self.trees =
    {
        SCIENCE = 0,
        MAGIC = 0,
        ANCIENT = 0,
    }

    self.on = false
    self.onturnon = nil
    self.onturnoff = nil
    self.doers = {}

    self.onremovedoer = function(doer) self:TurnOff(doer) end
end)

function Prototyper:OnRemoveFromEntity()
    self.inst:RemoveTag("prototyper")
    for k, v in pairs(self.doers) do
        self.inst:RemoveEventCallback("onremove", self.onremovedoer, k)
    end
    self.doers = nil
end

function Prototyper:TurnOn(doer)
    if not self.doers[doer] then
        self.doers[doer] = true
        self.inst:ListenForEvent("onremove", self.onremovedoer, doer)
        if not self.on then
            if self.onturnon ~= nil then
                self.onturnon(self.inst)
            end
            self.on = true
        end
    end
end

function Prototyper:TurnOff(doer)
    if self.doers[doer] then
        self.doers[doer] = nil
        self.inst:RemoveEventCallback("onremove", self.onremovedoer, doer)
        if next(self.doers) == nil and self.on then
            if self.onturnoff ~= nil then
                self.onturnoff(self.inst)
            end
            self.on = false
        end
    end
end

function Prototyper:GetTechTrees()
    return deepcopy(self.trees)
end

function Prototyper:Activate(doer)
    if self.onactivate ~= nil then
        self.onactivate(self.inst, doer)
    end
end

return Prototyper
