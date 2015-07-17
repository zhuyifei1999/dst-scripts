local Widget = require "widgets/widget"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Spinner = require "widgets/spinner"
local Text = require "widgets/text"
local Button = require "widgets/button"

local Menu = Class(Widget, function(self, menuitems, offset, horizontal, style, wrap)
    Widget._ctor(self, "MENU")
    self.offset = offset
    self.style = style
    self.items = {}
    self.horizontal = horizontal
    self.wrap_focus = wrap

    if menuitems ~= nil then
        self.controller_id = TheInput:ControllerAttached() and TheInput:GetControllerID() or nil
        for k,v in ipairs(menuitems) do
            if v.widget then
                self:AddCustomItem(v.widget, v.offset)
            else
                self:AddItem(v.text, v.cb, v.offset, v.style, nil, v.control)
            end
        end
    end
end)

function Menu:Clear()
    for k,v in pairs(self.items) do
        v:Kill()
    end
    self.items = {}
end

function Menu:GetNumberOfItems()
    return #self.items
end

function Menu:SetFocus(index)
    index = index or (self.reverse and -1 or 1)
    if index < 0 then
        index = index + #self.items +1 
    end

    if self.items[index] then
        self.items[index]:SetFocus()
    end
end

function Menu:SetTextSize(size)
    self.textSize = size
    if self.items ~= nil then
        for i, v in ipairs(self.items) do
            v:SetTextSize(size)
            if v.prompt ~= nil then
                v.prompt:SetSize(size)
                if v.prompt_shadow ~= nil then
                    v.prompt_shadow:SetSize(size)
                end
            end
        end
    end
end

function Menu:DoFocusHookups()
    local fwd = self.horizontal and ( self.offset > 0 and MOVE_RIGHT or MOVE_LEFT) or (self.offset > 0 and MOVE_UP or MOVE_DOWN)
    local back = self.horizontal and ( self.offset > 0 and MOVE_LEFT or MOVE_RIGHT) or (self.offset > 0 and MOVE_DOWN or MOVE_UP)

    for k,v in ipairs(self.items) do
        if k > 1 then
            self.items[k]:SetFocusChangeDir(back, self.items[k-1])
        end

        if k < #self.items then
            self.items[k]:SetFocusChangeDir(fwd, self.items[k+1])
        end
    end

    --[[if #self.items > 1 then
        self.items[1]:SetFocusChangeDir(back, self.items[#self.items])
        self.items[#self.items]:SetFocusChangeDir(fwd, self.items[1])
    end--]]
end

function Menu:SetVRegPoint(valign)
    local pos = Vector3(0,0,0) -- ANCHOR_TOP
    if valign == ANCHOR_MIDDLE then
        pos = Vector3(0, (#self.items-1)*-0.5, 0)
    elseif valign == ANCHOR_BOTTOM then
        pos = Vector3(0, (#self.items-1)*-1, 0)
    end

    for i,v in ipairs(self.items) do
        self.items[i]:SetVAlign(valign)
        self.items[i]:SetPosition(pos)
        pos.y = pos.y + self.offset
    end
end

function Menu:SetHRegPoint(halign)
    local pos = Vector3(0,0,0) -- ANCHOR_LEFT
    if halign == ANCHOR_MIDDLE then
        pos = Vector3(self.offset*(#self.items-1)*-0.5, 0, 0)
    elseif halign == ANCHOR_RIGHT then
        pos = Vector3(self.offset*(#self.items-1)*-1, 0, 0)
    end

    for i,v in ipairs(self.items) do
        local width, height = self.items[i].image:GetSize()
        self.items[i]:SetPosition(pos)
        --if halign == ANCHOR_MIDDLE then
            --local b_pos = pos + Vector3(-width*0.5, 0, 0)
            --self.items[i]:SetPosition(b_pos)
        --elseif halign == ANCHOR_RIGHT then
            --local b_pos = pos + Vector3(-width, 0, 0)
            --self.items[i]:SetPosition(b_pos)
        --else
            --self.items[i]:SetPosition(pos)
        --end
        pos.x = pos.x + self.offset
    end
end

function Menu:AddCustomItem(widget, offset)
    local pos = Vector3(0,0,0)
    if self.horizontal then
        pos.x = pos.x + self.offset * #self.items
    else
        pos.y = pos.y + self.offset * #self.items
    end
    if offset then
        pos = pos + offset
    end
    self:AddChild(widget)
    widget:SetPosition(pos)
    table.insert(self.items, widget)
    self:DoFocusHookups()
    return widget
end

function Menu:AddItem(text, cb, offset, style, size, control)
    local pos = Vector3(0,0,0)

    if self.horizontal then
        pos.x = pos.x + self.offset * #self.items
    else
        pos.y = pos.y + self.offset * #self.items
    end

    if offset then
        pos = pos + offset
    end 

    if style == nil then
        style = self.style
    end

    local button
    if style == "small" then
        button = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex", nil, nil, {1,1}, {0,0}))
        button.image:SetScale(1.1)
        button.text:SetPosition(2,-2)
        button:SetFont(BUTTONFONT)
    elseif style == "none" then
        button = self:AddChild(Button())
        button:SetFont(BUTTONFONT)
    else
        button = self:AddChild(ImageButton())
        button:SetFont(NEWFONT)
    end
    button:SetPosition(pos)
    button.text:SetColour(0,0,0,1)
    button:SetOnClick(cb)
    if size == nil then
        size = self.textSize
            or (JapaneseOnPS4() and 40 * .8)
            or 40
    end
    button:SetTextSize(size)

    if control ~= nil and self.controller_id ~= nil then
        button.prompt_shadow = button:AddChild(Text(UIFONT, size))
        button.prompt = button:AddChild(Text(UIFONT, size))
        local str = TheInput:GetLocalizedControl(self.controller_id, control).." "..text
        button.prompt:SetString(str)
        button.prompt_shadow:SetString(str)
        button.prompt_shadow:SetColour(0, 0, 0, 1)
    else
        button:SetText(text)
    end

    table.insert(self.items, button)

    self:DoFocusHookups()
    return button
end

function Menu:AutoSpaceByText(spacing)
    local x = 0
    for i, v in ipairs(self.items) do
        local w, h = 0, 0
        if #v.text:GetString() > 0 then
            w, h = v.text:GetRegionSize()
        end
        if v.prompt ~= nil and #v.prompt:GetString() > 0 then
            local w1, h1 = v.prompt:GetRegionSize()
            if w1 > w then
                w = w1
            end
            if h1 > h then
                h = h1
            end
        end
        local len = self.horizontal and w or h
        x = x + len * .5

        local pos = v:GetPosition()
        pos[self.horizontal and "x" or "y"] = x
        v:SetPosition(pos:Get())

        x = x + len * .5 + spacing
    end
    return math.max(0, x - spacing)
end

function Menu:EditItem(num, text, cb)

    if self.items[num] then
        local i = self.items[num]

        if text then
            i:SetText(text)
        end

        if cb then
            i:SetOnClick(cb)
        end

    end

end

return Menu
