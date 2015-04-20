local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"

-------------------------------------------------------------------------------------------------------

local GameVersion = Class(Widget, function(self)
    Widget._ctor(self, "GameVersion")

    self.targetversion = -1
    
    self.button = self:AddChild(ImageButton( "images/ui.xml", "button_long.tex", "button_long_over.tex", "button_long_disabled.tex" ))
	self.button:SetPosition( 0, 0, 0 )
    self.button:SetText(STRINGS.UI.MAINSCREEN.VERSION_MOREINFO)
    self.button:SetOnClick( function() VisitURL("http://forums.kleientertainment.com/forum/86-check-for-latest-steam-build/") end )
    self.button:SetScale(0.6)

    self.spinner = self:AddChild(UIAnim())
    self.spinner:GetAnimState():SetBank("researchlab")
    self.spinner:GetAnimState():SetBuild("researchlab")
    self.spinner:GetAnimState():PlayAnimation("proximity_loop", true)
    self.spinner:SetPosition(75, -12, 0)
    self.spinner:SetScale(0.08, 0.08)

    self.spinner:Hide()

    self.textshadow = self:AddChild(Text(BUTTONFONT, 24))
    self.textshadow:SetRegionSize( 500, 50 )
    self.textshadow:SetPosition( 2, -2, 0 )
    self.textshadow:SetColour(.1,.1,.1,1)
    self.textshadow:SetString("")

    self.text = self:AddChild(Text(UIFONT, 24))
    self.text:SetRegionSize( 500, 50 )
    self.text:SetPosition( 0, 0, 0 )

    self.button:Hide()

    self:StartUpdating()
end)

function GameVersion:SetTargetGameVersion(ver)
    self.targetversion = ver
end

function GameVersion:OnUpdate()
    if self.targetversion == -1 then
        local str = STRINGS.UI.MAINSCREEN.VERSION_CHECKING
        self.text:SetString(str)
        self.textshadow:SetString(str)

        self.text:Show()
        self.textshadow:Show()

        self.button:Hide()

        self.spinner:Show()
    elseif self.targetversion == -2 then
        local str = STRINGS.UI.MAINSCREEN.VERSION_ERROR
        self.text:SetString(str)
        self.textshadow:SetString(str)

        self.text:Show()
        self.textshadow:Show()

        self.button:Hide()

        self.spinner:Hide()
    elseif tonumber(APP_VERSION) < self.targetversion then
        local str = STRINGS.UI.MAINSCREEN.VERSION_NOTUPTODATE

        self.text:Hide()
        self.textshadow:Hide()

        self.button.text:SetColour(142/255, 0/255, 0/255, 255/255)
        self.button.text:SetString(str)

        self.button:Show()

        self.spinner:Hide()
    else
        local str = STRINGS.UI.MAINSCREEN.VERSION_UPTODATE
        self.text:SetColour(59/255, 242/255, 99/255, 255/255)
        self.text:SetString(str)
        self.textshadow:SetString(str)

        self.text:Show()
        self.textshadow:Show()

        self.button:Hide()

        self.spinner:Hide()
    end
end

return GameVersion
