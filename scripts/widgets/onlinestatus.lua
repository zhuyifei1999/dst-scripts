local Widget = require "widgets/widget"
local Text = require "widgets/text"

-------------------------------------------------------------------------------------------------------

local OnlineStatus = Class(Widget, function(self)
    Widget._ctor(self, "OnlineStatus")

    self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.textshadow = self.fixed_root:AddChild(Text(NEWFONT_OUTLINE, 35))
    self.textshadow:SetColour(.1,.1,.1,1)

    self.label = self.fixed_root:AddChild(Text(NEWFONT_OUTLINE, 35, STRINGS.UI.MAINSCREEN.STEAM))
    self.label:SetColour(1,1,1,1)
    self.label:Hide()

    self.text = self.fixed_root:AddChild(Text(NEWFONT_OUTLINE, 35))

    local w,h = self.label:GetRegionSize()
    local shadow_offset = 2

    self.text:SetPosition( RESOLUTION_X*.4 + w-27, RESOLUTION_Y*.5 - BACK_BUTTON_Y*.66 )
    self.textshadow:SetPosition( RESOLUTION_X*.4 + shadow_offset + w-27, RESOLUTION_Y*.5 - BACK_BUTTON_Y*.66 + shadow_offset )

    self:StartUpdating()
end)

function OnlineStatus:OnUpdate()
    if TheFrontEnd:GetIsOfflineMode() or not TheSim:IsSteamLoggedOn() then
        self.text:SetString(STRINGS.UI.MAINSCREEN.STEAM_OFFLINE)
        self.textshadow:SetString(STRINGS.UI.MAINSCREEN.STEAM_OFFLINE)
        self.text:SetColour(242/255, 99/255, 99/255, 255/255)
        self.text:Show()
        self.textshadow:Show()
    end
end

return OnlineStatus