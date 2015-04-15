local Widget = require "widgets/widget"
local Text = require "widgets/text"

--base class for imagebuttons and animbuttons. 
local Button = Class(Widget, function(self)
    Widget._ctor(self, "BUTTON")

    self.text = self:AddChild(Text(BUTTONFONT, 40))
	self.text:SetVAlign(ANCHOR_MIDDLE)
    self.text:SetColour(0,0,0,1)
    self.text:SetPosition(3,0)
    self.text:Hide()

	self.textcol = {0,0,0,1}
	self.textfocuscolour = {0,0,0,1}
	self.clickoffset = Vector3(0,-3,0)

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

	if not self:IsEnabled() or not self.focus then return end
	
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

    if self:IsEnabled() and TheFrontEnd:GetFadeLevel() <= 0 then
    	if self.text then self.text:SetColour(self.textfocuscolour[1],self.textfocuscolour[2],self.textfocuscolour[3],self.textfocuscolour[4]) end
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
	end
end

function Button:OnLoseFocus()
	Button._base.OnLoseFocus(self)
	if self:IsEnabled() then
		self.text:SetColour(self.textcol)
	end
	if self.o_pos then
		self:SetPosition(self.o_pos)
	end
	self.down = false
end

function Button:SetFont(font)
	self.text:SetFont(font)
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

function Button:SetTextColour(r,g,b,a)
	self.textcol = {r,g,b,a}
	
	if not self.focus then
		self.text:SetColour(self.textcol)
	end
end

function Button:SetTextFocusColour(r,g,b,a)
	self.textfocuscolour = {r,g,b,a}
	
	if self.focus then
		self.text:SetColour(self.textfocuscolour)
	end
end

function Button:SetTextSize(sz)
	self.text:SetSize(sz)
end

function Button:GetText()
    return self.text:GetString()
end

function Button:SetText(msg)
    if msg then
    	self.name = msg or "button"
        self.text:SetString(msg)
        self.text:Show()
		self.text:SetColour(self.focus and self.textfocuscolour or self.textcol)
    else
        self.text:Hide()
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
    table.insert(t, TheInput:GetLocalizedControl(controller_id, self.control, false, false ) .. " " .. self.help_message)	
	return table.concat(t, "  ")
end

return Button