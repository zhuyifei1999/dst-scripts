local writeables = require"writeables"

local function gettext(inst, viewer)
    local text = inst.components.writeable:GetText()
    return inst:HasTag("burnt") and GetDescription(viewer, inst, "BURNT") or
            text and string.format('"%s"', text)
            or GetDescription(viewer, inst, "UNWRITTEN")
end

local function onbuilt(inst, data)
    inst.components.writeable:BeginWriting(data.builder)
end

--V2C: NOTE: do not add "writeable" tag to pristine state because it is more
--           likely for players to encounter signs that are already written.
local function ontextchange(self, text)
    if text ~= nil then
        self.inst:RemoveTag("writeable")
        self.inst.AnimState:Show("WRITING")
    else
        self.inst:AddTag("writeable")
        self.inst.AnimState:Hide("WRITING")
    end
end

local function onwriter(self, writer)
    self.inst.replica.writeable:SetWriter(writer)
end

local Writeable = Class(function(self, inst)
    self.inst = inst
    self.text = nil

    self.writer = nil
    self.screen = nil

    self.onclosepopups = function(doer) -- yay closures ~gj -- yay ~v2c
        if doer == self.writer then
            self:EndWriting()
        end
    end

    self.generatorfn = nil

    inst.components.inspectable.getspecialdescription = gettext

    self.inst:ListenForEvent("onbuilt", onbuilt)
end,
nil,
{
    text = ontextchange,
    writer = onwriter,
})


function Writeable:OnSave()
    local data = {}

    data.text = self.text

    return data

end

function Writeable:OnLoad(data)
    self.text = data.text
end

function Writeable:GetText()
    return self.text
end

function Writeable:SetText(text)
    self.text = text
end

function Writeable:BeginWriting(doer)
    if self.writer == nil then
        self.inst:StartUpdatingComponent(self)

        self.writer = doer
        self.inst:ListenForEvent("ms_closepopups", self.onclosepopups, doer)
        self.inst:ListenForEvent("onremove", self.onclosepopups, doer)

        if doer.HUD ~= nil then
            self.screen = writeables.makescreen(self.inst, doer)
        end
    end
end

function Writeable:IsWritten()
    return self.text ~= nil
end

function Writeable:IsBeingWritten()
    return self.writer ~= nil
end

function Writeable:Write(doer, text)
    if self.writer == doer and doer ~= nil then
        self:SetText(text)
        self:EndWriting()
    end
end

function Writeable:EndWriting()
    if self.writer ~= nil then
        self.inst:StopUpdatingComponent(self)

        if self.screen ~= nil then
            self.writer.HUD:CloseWriteableWidget()
            self.screen = nil
        end

        self.inst:RemoveEventCallback("ms_closepopups", self.onclosepopups, self.writer)
        self.inst:RemoveEventCallback("onremove", self.onclosepopups, self.writer)
        self.writer = nil
    elseif self.screen ~= nil then
        --Should not have screen and no writer, but just in case...
        if self.screen.inst:IsValid() then
            self.screen:Kill()
        end
        self.screen = nil
    end
end

--------------------------------------------------------------------------
--Check for auto-closing conditions
--------------------------------------------------------------------------

function Writeable:OnUpdate(dt)
    if self.writer == nil then
        self.inst:StopUpdatingComponent(self)
    elseif not (self.writer:IsNear(self.inst, 3) and
                CanEntitySeeTarget(self.writer, self.inst)) then
        self:EndWriting()
    end
end

--------------------------------------------------------------------------

function Writeable:OnRemoveFromEntity()
    self:EndWriting()
    self.inst:RemoveTag("writeable")
    self.inst:RemoveEventCallback("onbuilt", onbuilt)
    if self.inst.components.inspectable ~= nil and
        self.inst.components.inspectable.getspecialdescription == gettext then
        self.inst.components.inspectable.getspecialdescription = nil
    end
end

Writeable.OnRemoveEntity = Writeable.EndWriting

return Writeable
