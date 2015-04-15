local Widget = require "widgets/widget"

-------------------------------------------------------------------------------------------------------

local HUD_ATLAS = "images/hud.xml"
local WAITING = "desync1.tex"
local BUFFERING = "desync2.tex"
local SHOW_DELAY = 1

local Desync = Class(Widget, function(self, owner)
    self.owner = owner

    Widget._ctor(self, "Desync")

    local w, h = 60, 80
    self._icon = self:AddChild(Image(HUD_ATLAS, WAITING))
    self._icon:SetClickable(false)
    self._icon:SetPosition(w / 2 + 4, - h / 2 - 3)
    self._icon:SetTint(1, 1, 1, 0)

    self._state = nil
    self._statedirty = false
    self._step = 0
    self._blinkspeed = 10
    self._delay = SHOW_DELAY
    self:Hide()

    self.inst:ListenForEvent("desync_waiting", function() self:SetState("waiting") end, owner)
    self.inst:ListenForEvent("desync_buffering", function() self:SetState("buffering") end, owner)
    self.inst:ListenForEvent("desync_resumed", function() self:SetState() end, owner)
end)

function Desync:OnUpdate(dt)
    --At the end of each blink, check for state change
    if self._statedirty and self._step <= 0 then
        if self._state == "waiting" then
            self._icon:SetTexture(HUD_ATLAS, WAITING)
            self._blinkspeed = 10
        elseif self._state == "buffering" then
            self._icon:SetTexture(HUD_ATLAS, BUFFERING)
            self._blinkspeed = 7.5
        else
            self._icon:SetTint(1, 1, 1, 0)
            self:Hide()
            self:StopUpdating()
            self._delay = SHOW_DELAY
            return
        end
    end

    if self._delay > dt then
        self._delay = self._delay - dt
    else
        self._delay = 0
        self._icon:SetTint(1, 1, 1, (self._step > 255 and 510 - self._step or self._step) / 255)
        self._step = self._step + self._blinkspeed
        if self._step >= 510 then
            self._step = 0
        end
    end
end

function Desync:SetState(state)
    if state == "waiting" or state == "buffering" then
        if self._state ~= state then
            self._state = state
            self._statedirty = true
        end
        if not self.shown then
            self:Show()
            self:StartUpdating()
        end
    elseif self._state ~= nil then
        self._state = nil
        self._statedirty = true
    end
end

return Desync