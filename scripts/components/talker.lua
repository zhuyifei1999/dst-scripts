local FollowText = require "widgets/followtext"

local PLAYERGHOST_OFFSET = Vector3(0, -700, 0)
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
end)

function Talker:OnRemoveFromEntity()
    if TheWorld.ismastersim then
        self.inst:RemoveTag("ignoretalking")
    end
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
        player.mutedPlayers ~= nil and
        player.mutedPlayers[self.inst.userid] then
        if self.widget ~= nil then
            self.widget:Kill()
            self.widget = nil
        end
    elseif self.widget == nil and player ~= nil and player.HUD ~= nil then
        self.widget = player.HUD:AddChild(FollowText(self.font or TALKINGFONT, self.fontsize or 35))
    end

    if self.widget ~= nil then
        self.widget.symbol = self.symbol
        --#srosen this was originally a hack for PAX, but this might be a totally acceptable way to do this...
        --V2C: this turned out to be the better way now =)
        self.widget:SetOffset(self.inst:HasTag("playerghost") and PLAYERGHOST_OFFSET or self.offset or DEFAULT_OFFSET)
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

    self:ShutUp()

    local lines = type(script) == "string" and { Line(script, time or 2.5, noanim) } or script
    if lines ~= nil then
        self.task = self.inst:StartThread(function() sayfn(self, lines, nobroadcast, colour) end)
    end
end

function Talker:ShutUp()
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

Talker.OnRemoveEntity = Talker.ShutUp

return Talker
