local Widget = require "widgets/widget"
local Text = require "widgets/text"

-------------------------------------------------------------------------------------------------------

local OnlineStatus = Class(Widget, function(self, show_borrowed_info )
    Widget._ctor(self, "OnlineStatus")

	self.show_borrowed_info = show_borrowed_info
	
    self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.textshadow = self.fixed_root:AddChild(Text(NEWFONT_OUTLINE, 32))
    self.textshadow:SetColour(.1,.1,.1,1)

    self.text = self.fixed_root:AddChild(Text(NEWFONT_OUTLINE, 32))

    self:StartUpdating()
end)

function OnlineStatus:OnUpdate()
	local shadow_offset = -1
	if self.show_borrowed_info and TheSim:IsBorrowed() then
		self.text:SetString(STRINGS.UI.MAINSCREEN.FAMILY_SHARED)
        self.textshadow:SetString(STRINGS.UI.MAINSCREEN.FAMILY_SHARED)
		self.text:SetPosition( RESOLUTION_X*.4 - 72, RESOLUTION_Y*.5 - 50 )
		self.textshadow:SetPosition( RESOLUTION_X*.4 + shadow_offset - 72, RESOLUTION_Y*.5 - 50 + shadow_offset )
        self.text:SetColour(80/255, 143/255, 244/255, 255/255)
        self.text:Show()
        self.textshadow:Show()
    end
    
    if TheFrontEnd:GetIsOfflineMode() or not TheSim:IsLoggedOn() then
        self.text:SetString(STRINGS.UI.MAINSCREEN.OFFLINE)
        self.textshadow:SetString(STRINGS.UI.MAINSCREEN.OFFLINE)
        self.text:SetColour(242/255, 99/255, 99/255, 255/255)
		self.text:SetPosition( RESOLUTION_X*.4 + 50, RESOLUTION_Y*.5 - BACK_BUTTON_Y*.66 )
		self.textshadow:SetPosition( RESOLUTION_X*.4 + shadow_offset + 50, RESOLUTION_Y*.5 - BACK_BUTTON_Y*.66 + shadow_offset )
        self.text:Show()
        self.textshadow:Show()
    end
end

return OnlineStatus