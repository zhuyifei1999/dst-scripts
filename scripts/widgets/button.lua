local Widget = require "widgets/widget"
local Text = require "widgets/text"

--base class for imagebuttons and animbuttons. 
local Button = Class(Widget, function(self)
    Widget._ctor(self, "BUTTON")

    self.font = NEWFONT
    self.fontdisabled = NEWFONT

	self.textcolour = {0,0,0,1}
	self.textfocuscolour = {0,0,0,1}
	self.textdisabledcolour = {0,0,0,1}
    self.textselectedcolour = {0,0,0,1}

    self.text = self:AddChild(Text(self.font, 40))
	self.text:SetVAlign(ANCHOR_MIDDLE)
    self.text:SetColour(self.textcolour)
    self.text:Hide()

	self.clickoffset = Vector3(0,-3,0)

	self.selected = false

	self.control = CONTROL_ACCEPT
	self.help_message = STRINGS.UI.HELP.SELECT
end)

function Button:SetControl(ctrl)
	if ctrl then
		self.control = ctrl
	end
end

function Button:OnControl(control, down)
	
	if Button._base.OnControl(self, control, down) then return true end

	if not self:IsEnabled() or not self.focus or self:IsSelected() then return end
	
	if control == self.control then

		if down then
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			self.o_pos = self:GetLocalPosition()
			self:SetPosition(self.o_pos + self.clickoffset)
			self.down = true
			if self.whiledown then
				self:StartUpdating()
			end
			if self.ondown then
				self.ondown()
			end
		else
			if self.down then
				self.down = false
				self:SetPosition(self.o_pos)
				if self.onclick then
					self.onclick()
				end
				self:StopUpdating()
			end
		end
		
		return true
	end

end

-- Will only run if the button is manually told to start updating: we don't want a bunch of unnecessarily updating widgets
function Button:OnUpdate(dt)
	if self.down then
		if self.whiledown then
			self.whiledown()
		end
	end
end

function Button:OnGainFocus()

	Button._base.OnGainFocus(self)

    if self:IsEnabled() and not self.selected and TheFrontEnd:GetFadeLevel() <= 0 then
    	if self.text then self.text:SetColour(self.textfocuscolour[1],self.textfocuscolour[2],self.textfocuscolour[3],self.textfocuscolour[4]) end
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
	end
end

function Button:OnLoseFocus()
	Button._base.OnLoseFocus(self)
	if self:IsEnabled() and not self.selected then
		self.text:SetColour(self.textcolour)
	end
	if self.o_pos then
		self:SetPosition(self.o_pos)
	end
	self.down = false
end

function Button:OnEnable()
	if not self.focus and not self.selected then
		self.text:SetColour(self.textcolour)
	    self.text:SetFont(self.font)
	end
end

function Button:OnDisable()
    self.text:SetColour(self.textdisabledcolour)
    self.text:SetFont(self.fontdisabled)
end

-- Calling "Select" on a button makes it behave as if it were disabled (i.e. won't respond to being clicked), but will still be able
-- to be focused by the mouse or controller. The original use case for this was the page navigation buttons: when you click a button 
-- to navigate to a page, you select that page and, because you're already on that page, the button for that page becomes unable to 
-- be clicked. But because fully disabling the button creates weirdness when navigating with a controller (disabled widgets can't be 
-- focused), we have this new state, Selected.
-- NB: For image buttons, you need to set the image_selected variable. Best practice is for this to be the same texture as disabled.
function Button:Select()
	self.selected = true
	self:OnSelect()
end

-- This is roughly equivalent to calling Enable after calling Disable--it cancels the Selected state. An unselected button will behave normally.
function Button:Unselect()
	self.selected = false
	self:OnUnselect()
end

-- This is roughly equivalent to OnDisable
function Button:OnSelect()
	self.text:SetColour(self.textselectedcolour)
end

-- This is roughly equivalent to OnEnable
function Button:OnUnselect()
	if self:IsEnabled() then
		if self.focus then
			if self.text then 
				self.text:SetColour(self.textfocuscolour[1],self.textfocuscolour[2],self.textfocuscolour[3],self.textfocuscolour[4]) 
			end
		else
			self:OnLoseFocus()
		end
	else
		self:OnDisable()
	end
end

function Button:IsSelected()
	return self.selected
end

function Button:SetOnClick( fn )
    self.onclick = fn
end

function Button:SetOnDown( fn )
	self.ondown = fn
end

function Button:SetWhileDown( fn )
	self.whiledown = fn
end

function Button:SetFont(font)
	self.font = font
	if self:IsEnabled() then
		self.text:SetFont(font)
		if self.text_shadow then 
			self.text_shadow:SetFont(font) 
		end
	end
end

function Button:SetDisabledFont(font)
	self.fontdisabled = font
	if not self:IsEnabled() then
		self.text:SetFont(font)
		if self.text_shadow then 
			self.text_shadow:SetFont(font) 
		end
	end
end

function Button:SetTextColour(r,g,b,a)
	if type(r) == "number" then
		self.textcolour = {r,g,b,a}
	else
		self.textcolour = r
	end

	if self:IsEnabled() and not self.focus and not self.selected then
		self.text:SetColour(self.textcolour)
	end
end

function Button:SetTextFocusColour(r,g,b,a)
	if type(r) == "number" then
		self.textfocuscolour = {r,g,b,a}
	else
		self.textfocuscolour = r
	end
	
	if self.focus and not self.selected then
		self.text:SetColour(self.textfocuscolour)
	end
end

function Button:SetTextDisabledColour(r,g,b,a)
	if type(r) == "number" then
		self.textdisabledcolour = {r,g,b,a}
	else
		self.textdisabledcolour = r
	end
	
	if not self:IsEnabled() then
		self.text:SetColour(self.textdisabledcolour)
	end
end

function Button:SetTextSelectedColour(r,g,b,a)
	if type(r) == "number" then
		self.textselectedcolour = {r,g,b,a}
	else
		self.textselectedcolour = r
	end
	
	if self.selected then
		self.text:SetColour(self.textselectedcolour)
	end
end

function Button:SetTextSize(sz)
	self.size = sz
	self.text:SetSize(sz)
	if self.text_shadow then self.text_shadow:SetSize(sz) end
end

function Button:GetText()
    return self.text:GetString()
end

function Button:SetText(msg, dropShadow, dropShadowOffset)
    if msg then
    	self.name = msg or "button"
        self.text:SetString(msg)
        self.text:Show()
        if self:IsEnabled() then
			self.text:SetColour(self.selected and self.textselectedcolour or (self.focus and self.textfocuscolour or self.textcolour))
		else
			self.text:SetColour(self.textdisabledcolour)
		end

		if dropShadow then
			self.text_shadow = self:AddChild(Text(self.font, self.size or 40))
			self.text_shadow:SetVAlign(ANCHOR_MIDDLE)
		    self.text_shadow:SetColour(.1,.1,.1,1)
		    local offset = dropShadowOffset or {-2, -2}
		    self.text_shadow:SetPosition(offset[1], offset[2])
		    self.text_shadow:SetString(msg)
		    self.text:MoveToFront()
		end
    else
        self.text:Hide()
        if self.text_shadow then self.text_shadow:Hide() end
    end
end

function Button:SetHelpTextMessage(str)
	if str then
		self.help_message = str
	end
end

function Button:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
	if not self:IsSelected() then
    	table.insert(t, TheInput:GetLocalizedControl(controller_id, self.control, false, false ) .. " " .. self.help_message)	
    end
	return table.concat(t, "  ")
end

return Button