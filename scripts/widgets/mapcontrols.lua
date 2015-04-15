local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local PauseScreen = require "screens/pausescreen"

local function OnToggleMap()
    ThePlayer.HUD.controls:ToggleMap()
end

local function OnPause()
    if not IsPaused() then
        TheFrontEnd:PushScreen(PauseScreen())
    end
end

local function OnRotLeft()
    ThePlayer.components.playercontroller:RotLeft()
end

local function OnRotRight()
    ThePlayer.components.playercontroller:RotRight()
end

--base class for imagebuttons and animbuttons. 
local MapControls = Class(Widget, function(self)
    Widget._ctor(self, "Map Controls")
    local MAPSCALE = .5
    self.minimapBtn = self:AddChild(ImageButton(HUD_ATLAS, "map_button.tex"))
    self.minimapBtn:SetScale(MAPSCALE,MAPSCALE,MAPSCALE)
    self.minimapBtn:SetOnClick(OnToggleMap)
    local controller_id = TheInput:GetControllerID()
    self.minimapBtn:SetTooltip(STRINGS.UI.HUD.MAP.."("..TheInput:GetLocalizedControl(controller_id, CONTROL_MAP)..")")

    self.pauseBtn = self:AddChild(ImageButton(HUD_ATLAS, "pause.tex"))
    self.pauseBtn:SetTooltip(STRINGS.UI.HUD.PAUSE.."("..TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL)..")")
    self.pauseBtn:SetScale(.33, .33, .33)
    self.pauseBtn:SetPosition(Point(0, -50, 0))
    self.pauseBtn:SetOnClick(OnPause)
 
    self.rotleft = self:AddChild(ImageButton(HUD_ATLAS, "turnarrow_icon.tex"))
    self.rotleft:SetPosition(-40,-40,0)
    self.rotleft:SetScale(-.7,.7,.7)
    self.rotleft:SetOnClick(OnRotLeft)
    self.rotleft:SetTooltip(STRINGS.UI.HUD.ROTLEFT.."("..TheInput:GetLocalizedControl(controller_id, CONTROL_ROTATE_LEFT)..")")

    self.rotright = self:AddChild(ImageButton(HUD_ATLAS, "turnarrow_icon.tex"))
    self.rotright:SetPosition(40,-40,0)
    self.rotright:SetScale(.7,.7,.7)
    self.rotright:SetOnClick(OnRotRight)
    self.rotright:SetTooltip(STRINGS.UI.HUD.ROTRIGHT.."("..TheInput:GetLocalizedControl(controller_id, CONTROL_ROTATE_RIGHT)..")")   

end)

return MapControls