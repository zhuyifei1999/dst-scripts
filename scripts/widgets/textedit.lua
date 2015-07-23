local Widget = require "widgets/widget"
local Text = require "widgets/text"

local TextEdit = Class(Text, function(self, font, size, text, colour)
    Text._ctor(self, font, size, text, colour)

    self.inst.entity:AddTextEditWidget()
    self:SetString(text)
    self.editing = false
    self:SetEditing(false)
    self.validrawkeys = {}
    self.force_edit = false
    self.pass_controls_to_screen = {}

    self.idle_text_color = {0,0,0,1}
    self.edit_text_color = {0,0,0,1}--{1,1,1,1}

    self.idle_tint = {1,1,1,1}
    self.hover_tint = {1,1,1,1}
    self.selected_tint = {1,1,1,1}

    self:SetColour(self.idle_text_color[1], self.idle_text_color[2], self.idle_text_color[3], self.idle_text_color[4])

    --Default cursor colour is WHITE { 1, 1, 1, 1 }
    self:SetEditCursorColour(0,0,0,1) 
end)

function TextEdit:SetForceEdit(force)
    self.force_edit = force
end

function TextEdit:SetString(str)
	if self.inst and self.inst.TextEditWidget then
		self.inst.TextEditWidget:SetString(str or "")
	end
end

function TextEdit:SetEditing(editing)
	if editing and not self.editing then
        self.editing = true

		self:SetFocus()
		-- Guarantee that we're highlighted
		self:DoSelectedImage()
		TheInput:EnableDebugToggle(false)
		--#srosen this is where we should push whatever text input widget we have for controllers
		-- we probably don't want to set the focus and whatnot here if controller attached: 
		-- it screws with textboxes that are child widgets in scroll lists (and on the lobby screen)
		-- instead, we should go into "edit mode" by pushing a modal screen, rather than giving this thing focus and gobbling input
		if TheInput:ControllerAttached() then

		end

		if self.edit_text_color then
			self:SetColour(self.edit_text_color[1], self.edit_text_color[2], self.edit_text_color[3], self.edit_text_color[4])
		end

        if self.force_edit then
            TheFrontEnd:SetForceProcessTextInput(true, self)
        end
	elseif not editing and self.editing then
        self.editing = false

		if self.focus then
			self:DoHoverImage()
		else
			self:DoIdleImage()
		end

		if self.idle_text_color then
			self:SetColour(self.idle_text_color[1], self.idle_text_color[2], self.idle_text_color[3], self.idle_text_color[4])
		end

        if self.force_edit then
            TheFrontEnd:SetForceProcessTextInput(false, self)
        end
	end

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
			self.inst.TextEditWidget:OnKeyDown(key)
		else
			if key == KEY_ENTER then
				self:OnProcess()
				return true
			elseif key == KEY_TAB and self.nextTextEditWidget then
				local nextWidg = self.nextTextEditWidget
				if type(self.nextTextEditWidget) == "function" then
					nextWidg = self.nextTextEditWidget()
				end
				if nextWidg and (type(nextWidg) == "table" and nextWidg.inst.TextEditWidget) then
					self:SetEditing(false)
					nextWidg:SetEditing(true)
				end
				-- self.nextTextEditWidget:OnControl(CONTROL_ACCEPT, false)
			else
				self.inst.TextEditWidget:OnKeyUp(key)
			end
		end

		if self.OnTextInputted then
			self.OnTextInputted()
		end
	end
	
	if self.validrawkeys[key] then return false end
	return true --gobble this up, or we will engage debug keys!
end

function TextEdit:SetPassControlToScreen(control, pass)
	self.pass_controls_to_screen[control] = pass or nil
end

function TextEdit:OnControl(control, down)
    if TextEdit._base.OnControl(self, control, down) then return true end

    --gobble up extra controls
    if self.editing and (control ~= CONTROL_CANCEL and control ~= CONTROL_OPEN_DEBUG_CONSOLE and control ~= CONTROL_ACCEPT) then
        return not self.pass_controls_to_screen[control]
    end

    if self.editing and not down and control == CONTROL_CANCEL then
        self:SetEditing(false)
        TheInput:EnableDebugToggle(true)
        return not self.pass_controls_to_screen[control]
    end

    if not down and control == CONTROL_ACCEPT then
        self:SetEditing(true)
        return not self.pass_controls_to_screen[control]
    end
end

function TextEdit:OnDestroy()
    Self:SetEditing(false)
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
	if self.focusedtex then
		self.focusimage:SetTexture(self.atlas, self.focusedtex)
		self.focusimage:SetTint(self.hover_tint[1],self.hover_tint[2],self.hover_tint[3],self.hover_tint[4])
	end
end

function TextEdit:DoSelectedImage()
	if self.activetex then
		self.focusimage:SetTexture(self.atlas, self.activetex)
		self.focusimage:SetTint(self.selected_tint[1],self.selected_tint[2],self.selected_tint[3],self.selected_tint[4])
	end
end

function TextEdit:DoIdleImage()
	if self.unfocusedtex then
		self.focusimage:SetTexture(self.atlas, self.unfocusedtex)
		self.focusimage:SetTint(self.idle_tint[1],self.idle_tint[2],self.idle_tint[3],self.idle_tint[4])
	end
end

function TextEdit:SetFocusedImage(widget, atlas, unfocused, hovered, active)
	self.focusimage = widget
	self.atlas = atlas
	self.focusedtex = hovered
	self.unfocusedtex = unfocused
	self.activetex = active

	if self.focusedtex and self.unfocusedtex and self.activetex then
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

function TextEdit:SetIdleTextColour(r,g,b,a)
    if type(r) == "number" then
        self.idle_text_color = {r, g, b, a}
    else
        self.idle_text_color = r
    end
    if not self.editing then
    	self:SetColour(self.idle_text_color[1], self.idle_text_color[2], self.idle_text_color[3], self.idle_text_color[4])
    end
end

function TextEdit:SetEditTextColour(r,g,b,a)
    if type(r) == "number" then
        self.edit_text_color = {r, g, b, a}
    else
        self.edit_text_color = r
    end
    if self.editing then
    	self:SetColour(self.edit_text_color[1], self.edit_text_color[2], self.edit_text_color[3], self.edit_text_color[4])
    end
end

function TextEdit:SetEditCursorColour(r,g,b,a)
    if type(r) == "number" then
        self.inst.TextWidget:SetEditCursorColour(r, g, b, a)
    else
        self.inst.TextWidget:SetEditCursorColour(unpack(r))
    end
end

-- function Text:SetFadeAlpha(a, doChildren)
-- 	if not self.can_fade_alpha then return end
	
--     self:SetColour(self.colour[1], self.colour[2], self.colour[3], self.colour[4] * a)
--     Widget.SetFadeAlpha( self, a, doChildren )
-- end

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

function TextEdit:EnableScrollEditWindow(enable)
    self.inst.TextEditWidget:EnableScrollEditWindow(enable)
end

return TextEdit
