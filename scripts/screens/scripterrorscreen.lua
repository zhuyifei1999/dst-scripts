local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

local ScriptErrorScreen = Class(Screen, function(self, title, text, buttons, texthalign, additionaltext, textsize, timeout)
	Screen._ctor(self, "ScriptErrorScreen")

    TheInputProxy:SetCursorVisible(true)

	--darken everything behind the dialog
	self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.8)
	
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,0,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--title	
    self.title = self.root:AddChild(Text(TITLEFONT, 50))
    self.title:SetPosition(0, 170, 0)
    self.title:SetString(title)

	--text
	local defaulttextsize = 24
	if textsize then
		defaulttextsize = textsize
	end

	
    self.text = self.root:AddChild(Text(BODYTEXTFONT, defaulttextsize))
	self.text:SetVAlign(ANCHOR_TOP)

	if texthalign then
		self.text:SetHAlign(texthalign)
	end


    self.text:SetPosition(0, 40, 0)
    self.text:SetString(text)
    self.text:EnableWordWrap(true)
    self.text:SetRegionSize(480*2, 200)
    
    if additionaltext then
	    self.additionaltext = self.root:AddChild(Text(BODYTEXTFONT, 24))
		self.additionaltext:SetVAlign(ANCHOR_TOP)
	    self.additionaltext:SetPosition(0, -150, 0)
	    self.additionaltext:SetString(additionaltext)
	    self.additionaltext:EnableWordWrap(true)
	    self.additionaltext:SetRegionSize(480*2, 100)
    end

	self.version = self:AddChild(Text(BODYTEXTFONT, 20))
	--self.version:SetHRegPoint(ANCHOR_LEFT)
	--self.version:SetVRegPoint(ANCHOR_BOTTOM)
	self.version:SetHAnchor(ANCHOR_LEFT)
	self.version:SetVAnchor(ANCHOR_BOTTOM)
	self.version:SetHAlign(ANCHOR_LEFT)
	self.version:SetVAlign(ANCHOR_BOTTOM)
	self.version:SetRegionSize(200, 40)
	self.version:SetPosition(110, 30, 0)
	self.version:SetString("Rev. "..APP_VERSION.." "..PLATFORM)
	
	if PLATFORM ~= "PS4" then
	    --create the menu itself
	    local button_w = 200
	    local space_between = 20
	    local spacing = button_w + space_between
	
	    self.menu = self.root:AddChild(Menu(buttons, 200, true))
	    self.menu:SetHRegPoint(ANCHOR_MIDDLE)
	    self.menu:SetPosition(0, -250, 0)
	    self.default_focus = self.menu
	end
end)

function ScriptErrorScreen:HideAllOtherScreens()
	-- workaround, a screen may actually be sitting on top of us without being pushed to the stack
	-- in this case we want this screen to be visible at all times
	for i,v in pairs(Ents) do
		if v.widget and v.widget:is_a(Screen) and not v.widget:is_a(ScriptErrorScreen) and not TheFrontEnd:IsScreenInStack(v.widget) then
			v:Hide()
		end
	end
end

function ScriptErrorScreen:OnUpdate( dt )
	self:HideAllOtherScreens()
	if self.timeout then
		self.timeout.timeout = self.timeout.timeout - dt
		if self.timeout.timeout <= 0 then
			self.timeout.cb()
		end
	end
	return true
end

return ScriptErrorScreen
