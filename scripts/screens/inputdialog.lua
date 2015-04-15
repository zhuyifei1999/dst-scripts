local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local TextEdit = require "widgets/textedit"

local VALID_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local STRING_MAX_LENGTH = 254 -- http://tools.ietf.org/html/rfc5321#section-4.5.3.1

local InputDialogString = ""

local InputDialogScreen = Class(Screen, function(self, title, buttons)
	Screen._ctor(self, "InputDialogScreen")

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
    self.bg = self.proot:AddChild(Image("images/fepanels_dst.xml", "small_panel.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
	self.bg:SetScale(1.2,1.2,1.2)
	
	if #buttons >2 then
		self.bg:SetScale(2,1.2,1.2)
	end
	
	--title	
    self.title = self.proot:AddChild(Text(BUTTONFONT, 50))
    self.title:SetPosition(0, 70, 0)
    self.title:SetColour(0,0,0,1)
    self.title:SetString(title)

    self.edit_text_bg = self.proot:AddChild( Image() )
    self.edit_text_bg:SetTexture( "images/textboxes.xml", "textbox_long.tex" )
    self.edit_text_bg:SetPosition( 0, 5, 0 )
    self.edit_text_bg:ScaleToSize( 500, 40 )
	
	self.edit_text = self.proot:AddChild( TextEdit( BODYTEXTFONT, 25, "" ) )
	self.edit_text:SetPosition( 0, 5, 0 )
	self.edit_text:SetRegionSize( 450, 40 )
	self.edit_text:SetHAlign(ANCHOR_LEFT)
	self.edit_text:SetFocusedImage( self.edit_text_bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex" )
	self.edit_text:SetTextLengthLimit( STRING_MAX_LENGTH )
	self.edit_text:SetCharacterFilter( VALID_CHARS )
	self.edit_text:SetAllowClipboardPaste( true )
	
    local spacing = 200

	self.menu = self.proot:AddChild(Menu(buttons, spacing, true))
	self.menu:SetPosition(-(spacing*(#buttons-1))/2, -70, 0) 
	self.buttons = buttons
	self.default_focus = self.edit_text
end)

function InputDialogScreen:GetText()
	return InputDialogString
end

function InputDialogScreen:GetActualString()
	return self.edit_text and self.edit_text:GetLineEditString() or ""
end

function InputDialogScreen:SetValidChars(chars)
	VALID_CHARS = chars
	self.edit_text:SetCharacterFilter(VALID_CHARS)
end

function InputDialogScreen:SetTitleTextSize(size)
	self.title:SetSize(size)
end

function InputDialogScreen:SetButtonTextSize(size)
	self.menu:SetTextSize(size)
end

function InputDialogScreen:OnControl(control, down)

	if self.edit_text ~= nil then
		InputDialogString = self.edit_text:GetString()
	end

    if InputDialogScreen._base.OnControl(self,control, down) then return true end

    if self.edit_text and self.edit_text.editing then
        self.edit_text:OnControl(control, down)
       	return true
    end
    
    if control == CONTROL_CANCEL and not down then    
        if #self.buttons > 1 and self.buttons[#self.buttons] then
            self.buttons[#self.buttons].cb()
            return true
        end
    end
end

function InputDialogScreen:Close()
	TheFrontEnd:PopScreen(self)
end

function InputDialogScreen:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
	if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)	
    end
	return table.concat(t, "  ")
end

return InputDialogScreen