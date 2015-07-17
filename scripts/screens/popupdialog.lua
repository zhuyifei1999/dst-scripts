local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/templates"

local PopupDialogScreen = Class(Screen, function(self, title, text, buttons, scale_bg, spacing_override)
	Screen._ctor(self, "PopupDialogScreen")

	--darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	
    
	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--throw up the background
    self.bg = self.proot:AddChild(TEMPLATES.CurlyWindow(130, 150, 1, 1, 68, -40))
    self.bg.fill = self.proot:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
    self.bg.fill:SetScale(.92, .68)
    self.bg.fill:SetPosition(8, 12)
	
	--title	
    self.title = self.proot:AddChild(Text(BUTTONFONT, 50))
    self.title:SetPosition(5, 88, 0)
    self.title:SetString(title)
    self.title:SetColour(0,0,0,1)

	--text
    self.text = self.proot:AddChild(Text(NEWFONT, 28))

    self.text:SetPosition(5, -15, 0)
    self.text:SetString(text)
    self.text:SetColour(0,0,0,1)
    self.text:EnableWordWrap(true)
    self.text:SetRegionSize(500, 160)
    self.text:SetVAlign(ANCHOR_MIDDLE)
  
    local spacing = spacing_override or 200

	self.menu = self.proot:AddChild(Menu(buttons, spacing, true))
	self.menu:SetPosition(-(spacing*(#buttons-1))/2, -127, 0) 
    for i,v in pairs(self.menu.items) do
        v:SetScale(.7)
    end
	self.buttons = buttons
	self.default_focus = self.menu
end)

function PopupDialogScreen:SetTitleTextSize(size)
	self.title:SetSize(size)
end

function PopupDialogScreen:SetButtonTextSize(size)
	self.menu:SetTextSize(size)
end

function PopupDialogScreen:OnControl(control, down)
    if PopupDialogScreen._base.OnControl(self,control, down) then return true end
    
    if control == CONTROL_CANCEL and not down then    
        if #self.buttons > 1 and self.buttons[#self.buttons] then
            self.buttons[#self.buttons].cb()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            return true
        end
    end
end


function PopupDialogScreen:Close()
	TheFrontEnd:PopScreen(self)
end

function PopupDialogScreen:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
	if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)	
    end
	return table.concat(t, "  ")
end

return PopupDialogScreen