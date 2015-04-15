local Widget = require "widgets/widget"
local Text = require "widgets/text"

--#srosen this makes it not quite match the screen: ideally we are only coloring the highlight box outside of the text field
-- which would require splitting it into two images...
local frame_color = {177/255.0,154/255.0,120/255.0, 1}

local TextEdit = Class(Text, function(self, font, size, text)
    Text._ctor(self, font, size, text)

    self.inst.entity:AddTextEditWidget()
    self:SetString(text)
    self:SetEditing(false)
    self.validrawkeys = {}
    self.pass_control_cancel_to_screen = false

end)

function TextEdit:SetString(str)
	if self.inst and self.inst.TextEditWidget then
		self.inst.TextEditWidget:SetString(str or "")
	end
end

function TextEdit:SetEditing(editing)
	if editing then
		self:SetFocus()
		-- Guarantee that we're highlighted
		self:DoSelectedImage()
		TheInput:EnableDebugToggle(false)
	else
		if self.focus then
			self:DoHoverImage()
		else
			self:DoIdleImage()
		end
	end
	self.editing = editing
	self.inst.TextWidget:ShowEditCursor(self.editing)
end

function TextEdit:OnMouseButton(button, down, x, y)
	self:SetEditing(true)
end

function TextEdit:OnTextInput(text)

	if not self.editing then return end
	if not self.shown then return end

	if self.limit then
		local str = self:GetString()
		--print("len", string.len(str), "limit", self.limit)
		if string.len(str) >= self.limit then
			return
		end
	end

	if self.validchars then
		if not string.find(self.validchars, text, 1, true) then
			return
		end
	end
	
	self.inst.TextEditWidget:OnTextInput(text)
end


function TextEdit:OnProcess()
	self:SetEditing(false)
	TheInputProxy:FlushInput()
	if self.OnTextEntered then
		self.OnTextEntered(self:GetString())
	end
end

function TextEdit:SetOnTabGoToTextEditWidget(texteditwidget)
	if texteditwidget and (type(texteditwidget) == "table" and texteditwidget.inst.TextEditWidget) or (type(texteditwidget) == "function") then
		self.nextTextEditWidget = texteditwidget
	end
end

function TextEdit:OnStopForceProcessTextInput()
	self:SetEditing(false)
end

function TextEdit:OnRawKey(key, down)
	if TextEdit._base.OnRawKey(self, key, down) then return true end
	if self.editing then
		if down then
			if key == KEY_ENTER then
				self:OnProcess()
				return true
			elseif key == KEY_TAB and self.nextTextEditWidget then
				local nextWidg = self.nextTextEditWidget
				if type(self.nextTextEditWidget) == "function" then
					nextWidg = self.nextTextEditWidget()
				end
				if nextWidg and (type(nextWidg) == "table" and nextWidg.inst.TextEditWidget) then
					TheFrontEnd:SetForceProcessTextInput(false)
					self:SetEditing(false)
					TheFrontEnd:SetForceProcessTextInput(true, nextWidg)
					nextWidg:SetEditing(true)
				end
				-- self.nextTextEditWidget:OnControl(CONTROL_ACCEPT, false)
			else
				self.inst.TextEditWidget:OnKeyDown(key)
			end
		else
			self.inst.TextEditWidget:OnKeyUp(key)
		end
	end
	
	if self.validrawkeys[key] then return false end
	return true --gobble this up, or we will engage debug keys!
end

function TextEdit:SetPassCancelToScreen(pass)
	self.pass_control_cancel_to_screen = pass
end

function TextEdit:OnControl(control, down)
	if TextEdit._base.OnControl(self, control, down) then return true end

	--gobble up extra controls
	if self.editing and (control ~= CONTROL_CANCEL and control ~= CONTROL_OPEN_DEBUG_CONSOLE and control ~= CONTROL_ACCEPT) then
		return true
	end

	if self.editing and not down and control == CONTROL_CANCEL then
		TheFrontEnd:SetForceProcessTextInput(false)
		self:SetEditing(false)
		TheInput:EnableDebugToggle(true)
		if self.pass_control_cancel_to_screen then
			return false
		else
			return true
		end
	end

	if not down and control == CONTROL_ACCEPT then
		TheFrontEnd:SetForceProcessTextInput(true, self)
		self:SetEditing(true)
		return true
	end
end

function TextEdit:OnDestroy()
	TheInput:EnableDebugToggle(true)
end

function TextEdit:OnFocusMove()
	return true
end

function TextEdit:OnGainFocus()
	Widget.OnGainFocus(self)

	if not self.editing then
		self:DoHoverImage()
	end

end

function TextEdit:OnLoseFocus()
	Widget.OnLoseFocus(self)
	
	if not self.editing then
		self:DoIdleImage()
	end
end

function TextEdit:DoHoverImage()
	if self.focusedtex and self.unfocusedtex then
		self.focusimage:SetTexture(self.atlas, self.focus and self.focusedtex or self.unfocusedtex)
		self.focusimage:SetTint(frame_color[1], frame_color[2], frame_color[3], frame_color[4])
	end
end

function TextEdit:DoSelectedImage()
	if self.focusedtex and self.unfocusedtex then
		self.focusimage:SetTexture(self.atlas, self.focus and self.focusedtex or self.unfocusedtex)
		self.focusimage:SetTint(1,1,1,1)
	end
end

function TextEdit:DoIdleImage()
	if self.focusedtex and self.unfocusedtex then
		self.focusimage:SetTexture(self.atlas, self.focus and self.focusedtex or self.unfocusedtex)
		self.focusimage:SetTint(frame_color[1], frame_color[2], frame_color[3], frame_color[4])
	end
end

function TextEdit:SetFocusedImage(widget, atlas, focused, unfocused)
	self.focusimage = widget
	self.atlas = atlas
	self.focusedtex = focused
	self.unfocusedtex = unfocused

	if self.focusedtex and self.unfocusedtex then
		self.focusimage:SetTexture(self.atlas, self.focus and self.focusedtex or self.unfocusedtex)
		if self.editing then
			self:DoSelectedImage()
		elseif self.focus then
			self:DoHoverImage()
		else
			self:DoIdleImage()
		end
	end

end

function TextEdit:SetTextLengthLimit(limit)
	self.limit = limit
end

function TextEdit:SetCharacterFilter(validchars)
	self.validchars = validchars
end

-- Unlike GetString() which returns the string stored in the displayed text widget
-- GetLineEditString will return the 'intended' string, even if the display is nulled out (for passwords)
function TextEdit:GetLineEditString()
	return self.inst.TextEditWidget:GetString()
end

function TextEdit:SetPassword(to)
	self.inst.TextEditWidget:SetPassword(to)
end

function TextEdit:SetAllowClipboardPaste(to)
	self.inst.TextEditWidget:SetAllowClipboardPaste(to)
end

function TextEdit:SetForceUpperCase(to)
	self.inst.TextEditWidget:SetForceUpperCase(to)
end

return TextEdit