local Widget = require "widgets/widget"
local Image = require "widgets/image"


require "constants"


local OPPOSITEALIGN = {
    [ANCHOR_LEFT] = ANCHOR_RIGHT,
    [ANCHOR_RIGHT] = ANCHOR_LEFT,
    [ANCHOR_MIDDLE] = ANCHOR_MIDDLE,
    [ANCHOR_BOTTOM] = ANCHOR_TOP,
    [ANCHOR_TOP] = ANCHOR_BOTTOM,
}

local function CreateSubElement(self, atlas, tex, halign, valign, resizew, resizeh, offsetX, offsetY)
    if tex == nil then
        return
    end
    local element = self:AddChild(Image(atlas, tex))
    element:SetHRegPoint(OPPOSITEALIGN[halign])
    element:SetVRegPoint(OPPOSITEALIGN[valign])

    element.offsetX = offsetX or 0
    element.offsetY = offsetY or 0

    element.halign = halign
    element.valign = valign

    if resizew ~= nil then
        element.resizew = resizew
    else
        element.resizew = halign == ANCHOR_MIDDLE
    end
    if resizeh ~= nil then
        element.resizeh = resizeh
    else
        element.resizeh = valign == ANCHOR_MIDDLE
    end
    return element
end

local NineSlice = Class(Widget, function(self, atlas, top_left, top_center, top_right,
                                                        mid_left, mid_center, mid_right,
                                                        bottom_left, bottom_center, bottom_right)
    Widget._ctor(self, "NineSlice")

    self.atlas = atlas

    -- The mid_center element is treated as the actual "widget" for sizing and alignment, the other
    -- elements are "stuck on" to it.
    if mid_center ~= nil then
        self.mid_center = self:AddChild(Image(atlas, mid_center))
    else
        self.mid_center = self:AddChild(Widget())
    end

    self.elements = {
        CreateSubElement(self, atlas, top_left, ANCHOR_LEFT, ANCHOR_TOP),
        CreateSubElement(self, atlas, top_center, ANCHOR_MIDDLE, ANCHOR_TOP),
        CreateSubElement(self, atlas, top_right, ANCHOR_RIGHT, ANCHOR_TOP),

        CreateSubElement(self, atlas, mid_left, ANCHOR_LEFT, ANCHOR_MIDDLE),
        CreateSubElement(self, atlas, mid_right, ANCHOR_RIGHT, ANCHOR_MIDDLE),

        CreateSubElement(self, atlas, bottom_left, ANCHOR_LEFT, ANCHOR_BOTTOM),
        CreateSubElement(self, atlas, bottom_center, ANCHOR_MIDDLE, ANCHOR_BOTTOM),
        CreateSubElement(self, atlas, bottom_right, ANCHOR_RIGHT, ANCHOR_BOTTOM),
    }

    if self.mid_center ~= nil then
        self:SetSize(self.mid_center:GetSize())
    else
        self:SetSize(100,100)
    end
end)

local function ResizeSubElement(element, w, h)
    if element == nil then
        return
    end
    
    local origw, origh = element:GetSize()
    element:SetSize(element.resizew and w or origw, element.resizeh and h or origh)
end

local function RepositionSubElement(element, w, h)
    if element == nil then
        return
    end
    local xpos = 0
    local ypos = 0
    if element.halign == ANCHOR_LEFT then
        xpos = -w/2 + (element.offsetX or 0)
    elseif element.halign == ANCHOR_MIDDLE then
        xpos = element.offsetX or 0
    elseif element.halign == ANCHOR_RIGHT then
        xpos = w/2 + (element.offsetX or 0)
    end
    if element.valign == ANCHOR_BOTTOM then
        ypos = -h/2 + (element.offsetY or 0)
    elseif element.valign == ANCHOR_MIDDLE then
        ypos = element.offsetY or 0
    elseif element.valign == ANCHOR_TOP then
        ypos = h/2 + (element.offsetY or 0)
    end
    element:SetPosition(xpos, ypos, 0)
end

function RescaleSubElement(element, w, h)
	if element == nil then
        return
    end
    
    --local origw, origh = element:GetSize()
    element:SetScale(not element.resizew and w or 1, not element.resizeh and h or 1)
end

function NineSlice:SetScale(w,h)
	--self.mid_center:SetSize(w, h)
    for i,element in ipairs(self.elements) do
        RescaleSubElement(element, w, h)
        --RepositionSubElement(element, w, h)
    end
end

function NineSlice:SetSize(w, h)
    self.mid_center:SetSize(w, h)
    for i,element in ipairs(self.elements) do
        ResizeSubElement(element, w, h)
        RepositionSubElement(element, w, h)
    end
end

function NineSlice:AddCrown(image, hanchor, vanchor, offsetX, offsetY)
    table.insert(self.elements, CreateSubElement(self, self.atlas, image, hanchor, vanchor, false, false, offsetX, offsetY))
end

return NineSlice
