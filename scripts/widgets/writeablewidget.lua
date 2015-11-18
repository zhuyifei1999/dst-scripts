local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"

local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"<>]]
--local VALID_CHARS = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,[]@!()'*+-/?{}\""
local STRING_MAX_LENGTH = 100 -- http://tools.ietf.org/html/rfc5321#section-4.5.3.1

local function onaccept(inst, doer, widget)
    if not widget.isopen then
        return
    end
    -- print("OnAccept",inst,doer,widget)

    --strip leading/trailing whitespace
    local msg = widget:GetText()
    local processed_msg = msg:match("^%s*(.-%S)%s*$") or ""
    if msg ~= processed_msg or #msg <= 0 then
        widget.edit_text:SetString(processed_msg)
        widget.edit_text:SetEditing(true)
        return
    end

    local writeable = inst.replica.writeable
    if writeable ~= nil then
        writeable:Write(doer, msg)
    end

    if widget.config.acceptbtn.cb ~= nil then
        widget.config.acceptbtn.cb(inst, doer, widget)
    end

    doer.HUD:CloseWriteableWidget()
end

local function onmiddle(inst, doer, widget)
    if not widget.isopen then
        return
    end
    --print("OnMiddle",inst,doer,widget)

    widget.config.middlebtn.cb(inst, doer, widget)
end

local function oncancel(inst, doer, widget)
    if not widget.isopen then
        return
    end
    --print("OnCancel",inst,doer,widget)

    local writeable = inst.replica.writeable
    if writeable ~= nil then
        writeable:Write(doer, nil)
    end

    if widget.config.cancelbtn.cb ~= nil then
        widget.config.cancelbtn.cb(inst, doer, widget)
    end

    doer.HUD:CloseWriteableWidget()
end


local WriteableWidget = Class(Screen, function(self, owner, writeable, config)
    Screen._ctor(self, "SignWriter")

    self.owner = owner
    self.writeable = writeable
    self.config = config

    self.isopen = false

    local scale = .6
    self:SetScale(scale,scale,scale)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    -- secretly this thing is a modal Screen, it just LOOKS like a widget
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0,0,0,0)
    self.black.OnMouseButton = function() oncancel(self.writeable, self.owner, self) end
   
    self.bganim = self:AddChild(UIAnim())
    self.bganim:SetScale(1,1,1)
    self.bgimage = self:AddChild(Image())
    self.bganim:SetScale(1,1,1)

    --self.title = self:AddChild(Text(BUTTONFONT, 50))
    --self.title:SetPosition(0, 70, 0)
    --self.title:SetColour(0,0,0,1)
    --self.title:SetString(self.config.prompt)

    --self.edit_text_bg = self:AddChild( Image() )
    --self.edit_text_bg:SetTexture( "images/textboxes.xml", "textbox_long.tex" )
    --self.edit_text_bg:SetPosition( 0, 5, 0 )
    --self.edit_text_bg:ScaleToSize( 480, 50 )
    
    self.edit_text = self:AddChild( TextEdit( BUTTONFONT, 50, "" ) )
    self.edit_text:SetColour(0,0,0,1)
    self.edit_text:SetForceEdit(true)
    self.edit_text:SetPosition( 0, 50, 0 )
    self.edit_text:SetRegionSize( 440, 190 )
    self.edit_text:SetHAlign(ANCHOR_LEFT)
    --self.edit_text:SetFocusedImage(self.edit_text_bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex")
    self.edit_text:SetTextLengthLimit(STRING_MAX_LENGTH)
    self.edit_text:SetCharacterFilter(VALID_CHARS)
    self.edit_text:EnableWordWrap(true)
    self.edit_text:EnableScrollEditWindow(false)

    self.buttons = {}
    table.insert(self.buttons, { text = config.cancelbtn.text, cb = function() oncancel(self.writeable, self.owner, self) end, control = config.cancelbtn.control })
    if config.middlebtn ~= nil then
        table.insert(self.buttons, { text = config.middlebtn.text, cb = function() onmiddle(self.writeable, self.owner, self) end, control = config.middlebtn.control })
    end
    table.insert(self.buttons, { text = config.acceptbtn.text, cb = function() onaccept(self.writeable, self.owner, self) end, control = config.acceptbtn.control })

    for i, v in ipairs(self.buttons) do
        if v.control ~= nil then
            self.edit_text:SetPassControlToScreen(v.control, true)
        end
    end

    local menuoffset = config.menuoffset or Vector3(0, 0, 0)
    if TheInput:ControllerAttached() then
        local spacing = 150
        self.menu = self:AddChild(Menu(self.buttons, spacing, true, "none"))
        self.menu:SetTextSize(40)
        local w = self.menu:AutoSpaceByText(15)
        self.menu:SetPosition(menuoffset.x - .5 * w, menuoffset.y, menuoffset.z)
    else
        local spacing = 110
        self.menu = self:AddChild(Menu(self.buttons, spacing, true, "small"))
        self.menu:SetTextSize(35)
        self.menu:SetPosition(menuoffset.x - .5 * spacing * (#self.buttons - 1), menuoffset.y, menuoffset.z)
    end

    local defaulttext = ""
    if self.config.defaulttext ~= nil then
        if type(self.config.defaulttext) == "string" then
            defaulttext = self.config.defaulttext
        elseif type(self.config.defaulttext) == "function" then
            defaulttext = self.config.defaulttext(self.writeable, self.owner)
        end
    end

    self:OverrideText( defaulttext )
    self.edit_text:OnControl(CONTROL_ACCEPT, false)
    --self.edit_text.OnTextEntered = function() onaccept(self.writeable, self.owner, self) end
	self.edit_text:SetHelpTextApply("")
	self.edit_text:SetHelpTextCancel("")
	self.edit_text:SetHelpTextEdit("")
    self.default_focus = self.edit_text

    if config.bgatlas ~= nil and config.bgimage ~= nil then
        self.bgimage:SetTexture(config.bgatlas, config.bgimage)
    end

    if config.animbank ~= nil then
        self.bganim:GetAnimState():SetBank(config.animbank)
    end

    if config.animbuild ~= nil then
        self.bganim:GetAnimState():SetBuild(config.animbuild)
    end

    if config.pos ~= nil then
        self:SetPosition(config.pos)
    else
        self:SetPosition(0, 150, 0)
    end

    --if config.buttoninfo ~= nil then
        --if doer ~= nil and doer.components.playeractionpicker ~= nil then
            --doer.components.playeractionpicker:RegisterContainer(container)
        --end
    --end

    self.isopen = true
    self:Show()

    if self.bgimage.texture then
        self.bgimage:Show()
    else
        self.bganim:GetAnimState():PlayAnimation("open")
    end
end)

function WriteableWidget:Close()
    if self.isopen then
        --if self.container ~= nil then
            --if self.owner ~= nil and self.owner.components.playeractionpicker ~= nil then
                --self.owner.components.playeractionpicker:UnregisterContainer(self.container)
            --end
        --end

        self.writeable = nil

        if self.bgimage.texture then
            self.bgimage:Hide()
        else
            self.bganim:GetAnimState():PlayAnimation("close")
        end

        self.black:Kill()
        --self.title:Kill()
        self.edit_text:SetEditing(false)
        self.edit_text:Kill()
        --self.edit_text_bg:Kill()
        self.menu:Kill()

        self.isopen = false

        self.inst:DoTaskInTime(.3, function() TheFrontEnd:PopScreen(self) end)
    end
end

function WriteableWidget:OverrideText(text)
    self.edit_text:SetString(text)
    self.edit_text:SetFocus()
end

function WriteableWidget:GetText()
    return self.edit_text:GetString()
end

function WriteableWidget:SetValidChars(chars)
    self.edit_text:SetCharacterFilter(chars)
end

function WriteableWidget:OnControl(control, down)

    if WriteableWidget._base.OnControl(self,control, down) then return true end

    -- gjans: This makes it so that if the text box loses focus and you click
    -- on the bg, it presses accept. Kind of weird behaviour. I'm guessing
    -- something like it is needed for controllers, but it's not exaaaactly
    -- this.
    --if control == CONTROL_ACCEPT and not down then
        --if #self.buttons >= 1 and self.buttons[#self.buttons] then
            --self.buttons[#self.buttons].cb()
            --return true
        --end
    --end

    if not down then
        for i, v in ipairs(self.buttons) do
            if control == v.control and v.cb ~= nil then
                v.cb()
                return true
            end
        end
    end
end

return WriteableWidget
