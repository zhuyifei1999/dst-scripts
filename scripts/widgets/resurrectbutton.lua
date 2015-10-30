local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"

local ResurrectButton = Class(Widget, function(self, owner)
    Widget._ctor(self, "Resurrect Button")
    self.owner = owner

    self.button = self:AddChild(ImageButton("images/hud.xml", "effigy_button.tex", "effigy_button_mouseover.tex", "effigy_button.tex"))
    self.button:SetOnClick(function() self:DoResurrect() end)

    self.text = self:AddChild(Text(TALKINGFONT, 28))
    self.text:SetPosition(0, -85, 0)
    self:OnShow()

    self.inst:ListenForEvent("continuefrompause", function()
        if self.shown then
            self:OnShow()
        end
    end, TheWorld)
end)

function ResurrectButton:SetScale(pos, y, z)
    ResurrectButton._base.SetScale(self, pos, y, z)
    if type(pos) == "number" then
        self.text.inst.UITransform:SetScale(1 / pos, 1 / (y or pos), 1 / (z or pos))
    else
        self.text.inst.UITransform:SetScale(1 / pos.x, 1 / pos.y, 1 / pos.z)
    end
end

function ResurrectButton:OnShow()
    if TheInput:ControllerAttached() then
        self.text:SetString(TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_MENU_MISC_1).." "..STRINGS.ACTIONS.REMOTERESURRECT)
        self.text:Show()
    else
        self.text:Hide()
    end
end

--Called from PlayerHud:OnControl
function ResurrectButton:CheckControl(control, down)
    if self.shown and down and control == CONTROL_MENU_MISC_1 then
        self:DoResurrect()
        return true
    end
end

function ResurrectButton:DoResurrect()
    if self.owner.components.playercontroller ~= nil then
        self.owner.components.playercontroller:DoResurrectButton()
    end
end

return ResurrectButton