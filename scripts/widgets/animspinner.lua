require "fonts"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local ThreeSlice = require "widgets/threeslice"
local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"

-------------------------------------------------
-- AnimSpinner is based on Spinner.
-----------------
-- To use AnimSpinner, call the constructor just as you would for Spinner.
-- Then call SetAnim with a build filel, anim bank name, animation name, and symbol to be overridden. 
-- If it is a skin, then you must pass a final parameter with the value true.
-- eg, spinner_group.spinner:SetAnim("frames_comp", "fr", "icon", "SWAP_ICON", true)
-- 
-- Each item in the options list must have a build name and a symbol name instead of the image value used previously.
-- eg
-- table.insert(skin_options,  
--			{
--				text = text_name or STRINGS.SKIN_NAMES["missing"], 
--				data = nil,
--				build = image_name,
--				symbol = "SWAP_ICON",
--			})
-------------------------------------------------------

local spinner_images = {
	arrow_normal = "spin_arrow.tex",
	arrow_over = "spin_arrow_over.tex",
	arrow_disabled = "spin_arrow_disabled.tex",
	arrow_down = "spin_arrow_down.tex",
	bg_middle = "spinner_short.tex",
	bg_middle_focus = "spinner_short_focus.tex",
	bg_middle_changing = "spinner_short_changing.tex",
	bg_end = "spinner_end.tex",
	bg_end_focus = "spinner_end_focus.tex",
	bg_end_changing = "spinner_end_changing.tex",
}

local spinner_lean_images = {
	arrow_left_normal = "arrow2_left.tex",
	arrow_left_over = "arrow2_left_over.tex",
	arrow_left_disabled = "arrow_left_disabled.tex",
	arrow_left_down = "arrow2_left_down.tex",
	arrow_right_normal = "arrow2_right.tex",
	arrow_right_over = "arrow2_right_over.tex",
	arrow_right_disabled = "arrow_right_disabled.tex",
	arrow_right_down = "arrow2_right_down.tex",
	bg_middle = "blank.tex",
	bg_middle_focus = "spinner_focus.tex",
	bg_middle_changing = "blank.tex",
	bg_end = "blank.tex",
	bg_end_focus = "blank.tex",
	bg_end_changing = "blank.tex",
}

local spinner_atlas = "images/ui.xml"
local spinfont = { font = BUTTONFONT, size = 30 }
local spinfontlean = { font = NEWFONT, size = 30 }
local default_width = 150
local default_height = 40

local AnimSpinner = Class(Widget, function( self, options, width, height, textinfo, editable, atlas, textures, lean, textwidth, textheight)
    Widget._ctor(self, "AnimSpinner")

    
    self.width = width or default_width
    self.height = height or default_height

    self.lean = lean

    self.atlas = atlas or spinner_atlas
    if self.lean then
        self.textures = textures or spinner_lean_images
        self.textinfo = textinfo or spinfontlean
    else
        self.textures = textures or spinner_images
        self.textinfo = textinfo or spinfont
    end

    self.editable = editable or false
    self.options = options
    self.selectedIndex = 1
    self.textsize = {width = textwidth or self.width, height = textheight or self.height}

    self.arrow_scale = 1

    self.textcolour = { 1, 1, 1, 1 }

    if self.lean then
    	self.background = self:AddChild( Image(self.atlas, self.textures.bg_middle_focus) )
    	self.background:ScaleToSize(self.width, self.height)
    	self.background:SetTint(1,1,1,0)
    	self.leftimage = self:AddChild( ImageButton(self.atlas, self.textures.arrow_left_normal, self.textures.arrow_left_over, self.textures.arrow_left_disabled, self.textures.arrow_left_down, nil,{1,1}, {0,0}) )
    	self.rightimage = self:AddChild( ImageButton(self.atlas, self.textures.arrow_right_normal, self.textures.arrow_right_over, self.textures.arrow_right_disabled, self.textures.arrow_right_down, nil,{1,1}, {0,0}) )
    else
    	self.background = self:AddChild(ThreeSlice(self.atlas, self.textures.bg_end, self.textures.bg_middle))
    	self.background:Flow(self.width, self.height, true)
	    self.leftimage = self:AddChild( ImageButton(self.atlas, self.textures.arrow_normal, self.textures.arrow_over, self.textures.arrow_disabled, self.textures.arrow_down, nil,{1,1}, {0,0}) )
    	self.rightimage = self:AddChild( ImageButton(self.atlas, self.textures.arrow_normal, self.textures.arrow_over, self.textures.arrow_disabled, self.textures.arrow_down, nil,{1,1}, {0,0}) )
	end
    self.leftimage.silent = true
    self.rightimage.silent = true

    self.arrow_scale = 1 -- used in other methods to get the actual arrow size
    local arrow_width, arrow_height = self.leftimage:GetSize()
    self.arrow_scale = self.height / arrow_height
    self.leftimage:SetScale( self.arrow_scale, self.arrow_scale, 1 )
    self.rightimage:SetScale( self.arrow_scale, self.arrow_scale, 1 )

	self.fganim = self:AddChild( UIAnim() )

	if editable then
	    self.text = self:AddChild( TextEdit( self.textinfo.font, self.textinfo.size ) )
	else
	    self.text = self:AddChild( Text( self.textinfo.font, self.textinfo.size ) )
	end
	if self.lean then
		self.text:SetPosition(2,0)
	end

	if self.lean then
		self:SetTextColour(1,1,1,1)
	end

	if self.lean then
		self.text:SetRegionSize( self.textsize.width, self.textsize.height )
	end
    self.text:Show()

	self.updating = false

	self:Layout()
	self:SetSelectedIndex(1)

	self.changing = false
	self.leftimage:SetOnClick(function() self:Prev(true) end)
	self.rightimage:SetOnClick(function() self:Next(true) end)
end)


function AnimSpinner:OnFocusMove(dir, down)
	if AnimSpinner._base.OnFocusMove(self,dir,down) then return true end

	if self.changing and down then
		if dir == MOVE_LEFT then
			self:Prev()
			return true
		elseif dir == MOVE_RIGHT then
			self:Next()
			return true
		else
			self.changing = false
			self:UpdateBG()
		end
	end
	
end

function AnimSpinner:OnGainFocus()
	AnimSpinner._base.OnGainFocus(self)
	self:UpdateBG()
end

function AnimSpinner:GetHelpText()
	local controller_id = TheInput:GetControllerID()

	local t = {}
	if self.leftimage.enabled then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PREVVALUE, false, false) .. " " .. STRINGS.UI.HELP.PREVVALUE)
	end

	if self.rightimage.enabled then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_NEXTVALUE, false, false) .. " " .. STRINGS.UI.HELP.NEXTVALUE)
	end
	
	return table.concat(t, "  ")
end

-- This function allows display of hint text next to the arrow buttons 
-- TODO: only tested with XBOX one controller. Test with other controller types to make sure there's room for the symbols.
function AnimSpinner:AddControllerHints()
	local w = self.rightimage:GetSize() * self.arrow_scale

	self.left_hint = self:AddChild( Text( BODYTEXTFONT, 26 ) )
	self.left_hint:SetString(TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PREVVALUE))
	self.left_hint:SetPosition( -self.width/2 + w/2 + 32, 0, 0 )

	self.right_hint = self:AddChild( Text( BODYTEXTFONT, 26 ) )
	self.right_hint:SetString(TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_NEXTVALUE))
	self.right_hint:SetPosition( self.width/2 - w/2 - 27, 0, 0 )
	

	self.hints_enabled = true
end


function AnimSpinner:OnLoseFocus()
	AnimSpinner._base.OnLoseFocus(self)
	self.changing = false
	self:UpdateBG()
end

function AnimSpinner:OnControl(control, down)
	if AnimSpinner._base.OnControl(self, control, down) then return true end

	if down then
		if control == CONTROL_PREVVALUE then
			self:Prev()
			return true
		elseif control == CONTROL_NEXTVALUE then
			self:Next()
			return true
		end
	end

	--[[if not down and control == CONTROL_ACCEPT then
		if self.changing then
			self.changing = false
			self:UpdateBG()
		else
			self.changing = true
			self:UpdateBG()
			self.saved_idx = self:GetSelectedIndex()
		end
		return true
	end

	if not down and control == CONTROL_CANCEL then
		if self.changing then
			self.changing = false
			self:UpdateBG()
			if self.saved_idx then
				self:SetSelectedIndex(self.saved_idx)
				self.saved_idx = nil
			end
			return true
		end
	end--]]


end

function AnimSpinner:UpdateBG()
	if self.changing then 
		if self.lean then
			self.background:SetTint(1,1,1,1)
		else
			self.background:SetImages(self.atlas, self.textures.bg_end_changing, self.textures.bg_middle_changing)
		end
	elseif self.focus then
		if self.lean then
			self.background:SetTint(1,1,1,1)
		else
			self.background:SetImages(self.atlas, self.textures.bg_end_focus, self.textures.bg_middle_focus)
		end
	else
		if self.lean then
			self.background:SetTint(1,1,1,0)
		else
			self.background:SetImages(self.atlas, self.textures.bg_end, self.textures.bg_middle)
		end
	end
end

function AnimSpinner:SetTextColour(r,g,b,a)
	self.textcolour = { r, g, b, a }
	self.text:SetColour( r, g, b, a )
end

-- To use an anim spinner, call SetAnim with the bank, animation name, 
-- and the symbol name that will be overridden.
--
-- new_anim is the animation state that includes the new indicator, but is optional.
function AnimSpinner:SetAnim(build, bank, anim, old_symbol, skin, new_anim)
	self.fganim:GetAnimState():SetBuild(build)
	self.fganim:GetAnimState():SetBank(bank)
	self.fganim:GetAnimState():PlayAnimation(anim)

	self.old_symbol = old_symbol
	self.bank = bank
	self.anim = anim
	self.skin = skin 
	self.new_anim = new_anim
end

function AnimSpinner:Enable()
	self._base.Enable(self)
	self.text:SetColour( self.textcolour )
	self:UpdateState()
end

function AnimSpinner:Disable()
	self._base.Disable(self)
	-- self.text:SetColour(.7,.7,.7,1)
	self.text:SetColour(.5,.5,.5,1)
	self.leftimage:Disable()
	self.rightimage:Disable()

	if self.hints_enabled then 
		self.left_hint:Hide()
		self.right_hint:Hide()
	end
end

function AnimSpinner:SetFont(font)
	self.text:SetFont(font)
end

function AnimSpinner:SetOnClick( fn )
    self.onclick = fn
end

function AnimSpinner:SetTextSize(sz)
	self.text:SetSize(sz)
end

function AnimSpinner:GetWidth()
	return self.width
end

function AnimSpinner:Layout()
	local w = self.rightimage:GetSize() * self.arrow_scale
	self.rightimage:SetPosition( self.width/2 - w/2, 0, 0 )
	self.leftimage:SetPosition( -self.width/2 + w/2, 0, 0 )
end

function AnimSpinner:SetTextHAlign( align )
    self.text:SetHAlign( align )
end

function AnimSpinner:SetTextVAlign( align )
    self.text:SetVAlign( align )
end

function AnimSpinner:Next(noclicksound)
	local oldSelection = self.selectedIndex
	local newSelection = oldSelection
	if self.enabled then
		if self.enableWrap then
			newSelection = self.selectedIndex + 1
			if newSelection > self:MaxIndex() then
				newSelection = self:MinIndex()
			end
		else
			newSelection = math.min( newSelection + 1, self:MaxIndex() )
		end
	end
	if newSelection ~= oldSelection then
		if not noclicksound then
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		end
		self:OnNext()
		self:SetSelectedIndex(newSelection)
		--self:Changed()
	else
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_negative")
	end
end

function AnimSpinner:Prev(noclicksound)
	local oldSelection = self.selectedIndex
	local newSelection = oldSelection
	if self.enabled then
		if self.enableWrap then
			newSelection = self.selectedIndex - 1
			if newSelection < self:MinIndex() then
				newSelection = self:MaxIndex()
			end
		else
			newSelection = math.max( self.selectedIndex - 1, self:MinIndex() )
		end
	end
	if newSelection ~= oldSelection then
		if not noclicksound then
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		end
		self:OnPrev()
		self:SetSelectedIndex(newSelection)
		--self:Changed()
	else
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_negative")
	end
end

function AnimSpinner:GetSelected()
	return self.options[ self.selectedIndex ]
end

function AnimSpinner:GetSelectedIndex()
	return self.selectedIndex
end

function AnimSpinner:GetSelectedText()
	if self.options[self.selectedIndex] and self.options[self.selectedIndex].text then 
		return self.options[ self.selectedIndex ].text, self.options[ self.selectedIndex ].colour
	else
		return ""
	end
end

-- returns the build file to use and the symbol name within that build
function AnimSpinner:GetSelectedSymbol()
	return self.options[ self.selectedIndex ].build, self.options[ self.selectedIndex ].symbol, self.options[ self.selectedIndex ].new_indicator
end

function AnimSpinner:GetSelectedData()
	return self.options[ self.selectedIndex ].data
end

function AnimSpinner:SetSelectedIndex( idx )
	self.updating = true
	self.selectedIndex = math.max(self:MinIndex(), math.min(self:MaxIndex(), idx))
	
	local selected_text, selected_colour = self:GetSelectedText()	
	self:UpdateText( selected_text )
	if selected_colour then 
		self:SetTextColour( unpack(selected_colour) )
	else
		self:SetTextColour(0, 0, 0, 1)
	end
	
	if self.old_symbol ~= nil and self.options[ self.selectedIndex ] ~= nil then 
		local build, symbol, new_indicator = self:GetSelectedSymbol()
		if build ~= nil and symbol ~= nil then
			--print("Overriding symbol on ", self.fganim, self.fganim:GetAnimState() or nil, self.old_symbol, build, symbol)
			if self.skin then 
				self.fganim:GetAnimState():OverrideSkinSymbol(self.old_symbol, build, symbol)

				if new_indicator and self.new_anim then 
					self.fganim:GetAnimState():PlayAnimation(self.new_anim)
				end

			else
				self.fganim:GetAnimState():OverrideSymbol(self.old_symbol, build, symbol)

				if new_indicator and self.new_anim then 
					self.fganim:GetAnimState():PlayAnimation(self.new_anim)
				end
			end
		end
	end
	
	self:UpdateState()
	self.updating = false
	self:Changed() -- must be done after setting self.updating to false
end

function AnimSpinner:SetSelected( data )
	
	for k,v in pairs(self.options) do
		if v.data == data then
			self:SetSelectedIndex(k)			
			return
		end
	end
end

function AnimSpinner:UpdateText( msg )
	self.text:SetString(msg)
end

function AnimSpinner:GetText()
	return self.text:GetString()
end

function AnimSpinner:OnNext()
end

function AnimSpinner:OnPrev()
end

function AnimSpinner:Changed()
	if not self.updating then
		self:OnChanged( self:GetSelectedData() )
		self:UpdateState()
	end
end

function AnimSpinner:SetOnChangedFn(fn)
	self.onchangedfn = fn
end

function AnimSpinner:OnChanged( selected )
	if self.onchangedfn then
		self.onchangedfn(selected)
	end
end

function AnimSpinner:MinIndex()
	return 1
end

function AnimSpinner:MaxIndex()
	return #self.options
end

function AnimSpinner:SetWrapEnabled(enable)
	self.enableWrap = enable
	self:UpdateState()
end

function AnimSpinner:UpdateState()
	if self.enabled then
		self.leftimage:Enable()
		self.rightimage:Enable()

		if self.hints_enabled then 
			self.left_hint:Show()
			self.right_hint:Show()
		end

		if not self.enableWrap then
			if self.selectedIndex == self:MinIndex() then
				self.leftimage:Disable()
				if self.hints_enabled then 
					self.left_hint:Hide()
				end
			end
			if self.selectedIndex == self:MaxIndex() then
				self.rightimage:Disable()
				if self.hints_enabled then 
					self.right_hint:Hide()
				end
			end
		end
	else
		self.leftimage:Disable(
)		self.rightimage:Disable()

		if self.hints_enabled then 
			self.left_hint:Hide()
			self.right_hint:Hide()
		end
	end
end


function AnimSpinner:SetOptions( options )
	self.options = options
	if self.selectedIndex > #self.options then
		self:SetSelectedIndex( #self.options )
	else
		-- update fganim
		self:SetSelectedIndex(self.selectedIndex)
	end
	self:UpdateState()
end

return AnimSpinner
