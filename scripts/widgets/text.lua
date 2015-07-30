local Widget = require "widgets/widget"

local Text = Class(Widget, function(self, font, size, text, colour)
    Widget._ctor(self, "Text")
   
    self.inst.entity:AddTextWidget()
    
    self.inst.TextWidget:SetFont(font)
    self.font = font
    self.inst.TextWidget:SetSize(size)
    self.size = size

    self:SetColour(colour or { 1, 1, 1, 1 })

	if text then
		self:SetString( text )
	end
end)

function Text:__tostring()
    return string.format("%s - %s", self.name, self.string or "")
end


function Text:SetColour(r,g,b,a)
    if type(r) == "number" then
        self.inst.TextWidget:SetColour(r, g, b, a)
        self.colour = {r, g, b, a}
    else
        self.inst.TextWidget:SetColour(r[1], r[2], r[3], r[4])
        self.colour = r
    end
end

function Text:SetHorizontalSqueeze( squeeze )
    self.inst.TextWidget:SetHorizontalSqueeze(squeeze)
end

function Text:SetFadeAlpha(a, skipChildren)
    if not self.can_fade_alpha then return end
    
    self:SetColour(self.colour[1], self.colour[2], self.colour[3], self.colour[4] * a)
    Widget.SetFadeAlpha( self, a, skipChildren )
end

function Text:SetAlpha(a)
    self.inst.TextWidget:SetColour(1,1,1, a)
end

function Text:SetFont(font)
    self.inst.TextWidget:SetFont(font)
    self.font = font
end

function Text:SetSize(sz)
    self.inst.TextWidget:SetSize(sz)
    self.size = sz
end

function Text:SetRegionSize(w,h)
    self.inst.TextWidget:SetRegionSize(w,h)
end

function Text:GetRegionSize()
    return self.inst.TextWidget:GetRegionSize()
end

function Text:SetString(str)
    self.string = str
    self.inst.TextWidget:SetString(str or "")
end

function Text:GetString()
	--print("Text:GetString()", self.inst.TextWidget:GetString())
    return self.inst.TextWidget:GetString() or ""
end

--WARNING: This is not optimized!
-- Recommend to use only in FE menu screens.
--
-- maxwidth [optional]: max region width, only works when autosizing
-- maxchars [optional]: max chars from original string
-- ellipses [optional]: defaults to "..."
--
-- Works best specifying BOTH maxwidth AND maxchars!
--
-- How to pick non-arbitrary maxchars:
--  1) Call with only maxwidth, and a super long string of dots:
--     e.g. wdgt:SetTruncatedString(".............................", 30)
--  2) Find out how many dots were actually kept:
--     e.g. print(wdgt:GetString():len())
--  3) Use that number as an estimate for maxchars, or round up
--     a little just in case dots aren't the smallest character
function Text:SetTruncatedString(str, maxwidth, maxchars, ellipses)
    if type(ellipses) ~= "string" then
        ellipses = ellipses and "..." or ""
    end
    if maxchars ~= nil and str:len() > maxchars then
        str = str:sub(1, maxchars)
        self.inst.TextWidget:SetString(str..ellipses)
    else
        self.inst.TextWidget:SetString(str)
    end
    if maxwidth ~= nil then
        while self.inst.TextWidget:GetRegionSize() > maxwidth do
            str = str:sub(1, str:len() - 1)
            self.inst.TextWidget:SetString(str..ellipses)
        end
    end
end

function Text:SetVAlign(anchor)
    self.inst.TextWidget:SetVAnchor(anchor)
end

function Text:SetHAlign(anchor)
    self.inst.TextWidget:SetHAnchor(anchor)
end

function Text:EnableWordWrap(enable)
	self.inst.TextWidget:EnableWordWrap(enable)
end

return Text