local FollowText = require "widgets/followtext"

local DEFAULT_OFFSET = Vector3(0, -400, 0)

Line = Class(function(self, message, duration, noanim)
    self.message = message
    self.duration = duration
    self.noanim = noanim
end)

local Talker = Class(function(self, inst)
    self.inst = inst
    self.task = nil
    self.ignoring = nil
    self.mod_str_fn = nil
    self.offset = nil
    self.offset_fn = nil
end)

function Talker:SetOffsetFn(fn)
    self.offset_fn = fn
end

--"Chatter" functionality works together with ChattyNode and combat shouts, for NPC characters

local function OnChatterDirty(inst)
    local self = inst.components.talker
    if #self.chatter.strtbl:value() > 0 then
        local stringtable = STRINGS[self.chatter.strtbl:value()]
        if stringtable ~= nil then
            local str = stringtable[self.chatter.strid:value()]
            if str ~= nil then
                local t = self.chatter.strtime:value()
                self:Say(str, t > 0 and t or nil, nil, nil, true)
                return
            end
        end
    end
    self:ShutUp()
end

function Talker:MakeChatter()
    if self.chatter == nil then
        --for npc
        self.chatter =
        {
            strtbl = net_string(self.inst.GUID, "talker.chatter.strtbl", "chatterdirty"),
            strid = net_tinybyte(self.inst.GUID, "talker.chatter.strid", "chatterdirty"),
            strtime = net_tinybyte(self.inst.GUID, "talker.chatter.strtime"),
        }
        if not TheWorld.ismastersim then
            self.inst:ListenForEvent("chatterdirty", OnChatterDirty)
        end
    end
end

local function OnCancelChatter(inst, self)
    self.chatter.task = nil
    self.chatter.strtbl:set_local("")
end

function Talker:Chatter(strtbl, strid, time)
    if self.chatter ~= nil and TheWorld.ismastersim then
        self.chatter.strtbl:set(strtbl)
        --force at least the id dirty, so that it's possible to repeat strings
        self.chatter.strid:set_local(strid)
        self.chatter.strid:set(strid)
        self.chatter.strtime:set(time or 0)
        if self.chatter.task ~= nil then
            self.chatter.task:Cancel()
        end
        self.chatter.task = self.inst:DoTaskInTime(1, OnCancelChatter, self)
        OnChatterDirty(self.inst)
    end
end

function Talker:OnRemoveFromEntity()
    self.inst:RemoveEventCalback("chatterdirty", OnChatterDirty)
    if TheWorld.ismastersim then
        self.inst:RemoveTag("ignoretalking")
    end
    self:ShutUp()
end

function Talker:IgnoreAll(source)
    if self.ignoring == nil then
        self.ignoring = { [source or self] = true }
        if TheWorld.ismastersim then
            self.inst:AddTag("ignoretalking")
        end
    else
        self.ignoring[source or self] = true
    end
end

function Talker:StopIgnoringAll(source)
    if self.ignoring == nil then
        return
    end
    self.ignoring[source or self] = nil
    if next(self.ignoring) == nil then
        self.ignoring = nil
        if TheWorld.ismastersim then
            self.inst:RemoveTag("ignoretalking")
        end
    end
end

local function sayfn(self, script, nobroadcast, colour)
    local player = ThePlayer
    if self.inst.userid ~= nil and
        player ~= nil and
        TheFrontEnd.mutedPlayers ~= nil and
        TheFrontEnd.mutedPlayers[self.inst.userid] then
        if self.widget ~= nil then
            self.widget:Kill()
            self.widget = nil
        end
    elseif self.widget == nil and player ~= nil and player.HUD ~= nil then
        self.widget = player.HUD:AddChild(FollowText(self.font or TALKINGFONT, self.fontsize or 35))
    end

    if self.widget ~= nil then
        self.widget.symbol = self.symbol
        self.widget:SetOffset(self.offset_fn ~= nil and self.offset_fn(self.inst) or self.offset or DEFAULT_OFFSET)
        self.widget:SetTarget(self.inst)
        if colour ~= nil then
            self.widget.text:SetColour(unpack(colour))
        elseif self.colour ~= nil then
            self.widget.text:SetColour(self.colour.x, self.colour.y, self.colour.z, 1)
        end
    end

    for i, line in ipairs(script) do
        if line.message ~= nil then

            if self.mod_str_fn ~= nil then
                line.message = self.mod_str_fn(line.message)
            end

            line.message = GetSpecialCharacterPostProcess(self.inst.prefab, line.message)

            if self.widget ~= nil then
                self.widget.text:SetString(line.message)
            end
            self.inst:PushEvent("ontalk", { noanim = line.noanim })
            if not nobroadcast then
                TheNet:Talker(line.message, self.inst.entity)
            end
        elseif self.widget ~= nil then
            self.widget:Hide()
        end
        Sleep(line.duration)
    end

    if self.widget ~= nil then
        self.widget:Kill()
        self.widget = nil
    end

    self.inst:PushEvent("donetalking")
    self.task = nil
end

local function CancelSay(self)
    if self.task ~= nil then
        scheduler:KillTask(self.task)
        self.task = nil

        if self.widget ~= nil then
            self.widget:Kill()
            self.widget = nil
        end

        self.inst:PushEvent("donetalking")
    end
end

function Talker:Say(script, time, noanim, force, nobroadcast, colour)
    if TheWorld.ismastersim then
        if not force
            and (self.ignoring ~= nil or
                (self.inst.components.health ~= nil and self.inst.components.health:IsDead()) or
                (self.inst.components.sleeper ~= nil and self.inst.components.sleeper:IsAsleep())) then
            return
        end
        if self.ontalk ~= nil then
            self.ontalk(self.inst, script)
        end
    elseif not force then
        if self.inst:HasTag("ignoretalking") then
            return
        end
        local health = self.inst.replica.health
        if health ~= nil and health:IsDead() then
            return
        end
    end

    CancelSay(self)

    local lines = type(script) == "string" and { Line(script, time or 2.5, noanim) } or script
    if lines ~= nil then
        self.task = self.inst:StartThread(function() sayfn(self, lines, nobroadcast, colour) end)
    end
end

function Talker:ShutUp()
    CancelSay(self)

    if self.chatter ~= nil and TheWorld.ismastersim then
        self.chatter.strtbl:set("")
        if self.chatter.task ~= nil then
            self.chatter.task:Cancel()
            self.chatter.task = nil
        end
    end
end

Talker.OnRemoveEntity = CancelSay

return Talker
