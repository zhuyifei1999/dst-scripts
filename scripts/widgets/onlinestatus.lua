local Widget = require "widgets/widget"
local Text = require "widgets/text"

-------------------------------------------------------------------------------------------------------

local OnlineStatus = Class(Widget, function(self)
    Widget._ctor(self, "OnlineStatus")

    self.labelshadow = self:AddChild(Text(BUTTONFONT, 37))
    self.labelshadow:SetRegionSize( 300, 50 )
    self.labelshadow:SetPosition( -122, 55, 0 ) 
    self.labelshadow:SetColour(.1,.1,.1,1)
    self.labelshadow:SetString(STRINGS.UI.MAINSCREEN.STEAM)

    self.textshadow = self:AddChild(Text(BUTTONFONT, 37))
    self.textshadow:SetRegionSize( 300, 50 )
    self.textshadow:SetPosition( -57, 55, 0 )
    self.textshadow:SetColour(.1,.1,.1,1)
    self.textshadow:SetString(STRINGS.UI.MAINSCREEN.STEAM)

    self.label = self:AddChild(Text(BUTTONFONT, 37))
    self.label:SetRegionSize( 300, 50 )
    self.label:SetPosition( -125, 58, 0 ) 
    self.label:SetColour(1,1,1,1)
    self.label:SetString(STRINGS.UI.MAINSCREEN.STEAM)

    self.text = self:AddChild(Text(BUTTONFONT, 37))
    self.text:SetRegionSize( 300, 50 )
    self.text:SetPosition( -60, 58, 0 )
    

    self:StartUpdating()
end)

function OnlineStatus:OnUpdate()
    if TheFrontEnd:GetIsOfflineMode() then
        self.labelshadow:Hide()
        self.label:Hide()
        self.text:SetString(STRINGS.UI.MAINSCREEN.STEAM_OFFLINE)
        self.textshadow:SetString(STRINGS.UI.MAINSCREEN.STEAM_OFFLINE)
        self.text:SetColour(242/255, 99/255, 99/255, 255/255)
    else
        self.online = TheSim:IsSteamLoggedOn()
        self.labelshadow:Show()
        self.label:Show()
        if self.online then
            self.text:SetString(STRINGS.UI.MAINSCREEN.STEAM_ONLINE)
            self.textshadow:SetString(STRINGS.UI.MAINSCREEN.STEAM_ONLINE)
            self.text:SetColour(59/255, 242/255, 99/255, 255/255)
        else
            self.text:SetString(STRINGS.UI.MAINSCREEN.STEAM_OFFLINE)
            self.textshadow:SetString(STRINGS.UI.MAINSCREEN.STEAM_OFFLINE)
            self.text:SetColour(242/255, 99/255, 99/255, 255/255)
        end
    end
end

return OnlineStatus