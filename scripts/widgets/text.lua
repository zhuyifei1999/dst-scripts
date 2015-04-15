local Widget = require "widgets/widget"

local Text = Class(Widget, function(self, font, size, text)
    Widget._ctor(self, "Text")
   
    self.inst.entity:AddTextWidget()
    
    self.inst.TextWidget:SetFont(font)
    self.inst.TextWidget:SetSize(size)

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
    else
        self.inst.TextWidget:SetColour(r[1], r[2], r[3], r[4])
    end
end

function Text:SetHorizontalSqueeze( squeeze )
    self.inst.TextWidget:SetHorizontalSqueeze(squeeze)
end

function Text:SetAlpha(a)
    self.inst.TextWidget:SetColour(1,1,1, a)
end

function Text:SetFont(font)
    self.inst.TextWidget:SetFont(font)
end

function Text:SetSize(sz)
    self.inst.TextWidget:SetSize(sz)
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

function Text:SetHoverText(text)
    if text then
        if not self.hover then
            local ImageButton = require "widgets/imagebutton"
            self.hover = self:AddChild(ImageButton("images/ui.xml", "blank.tex", "blank.tex", "blank.tex"))
            self.hover.image:ScaleToSize(self:GetRegionSize())
            self.hovertext = self:AddChild(Text(BODYTEXTFONT, 28, text))
            self.hovertext:SetPosition(3,35)
            self.hovertext:MoveToFront()
            self.hovertext:Hide()
            self.hover.OnGainFocus = function()
                self.hovertext:Show()
            end
            self.hover.OnLoseFocus = function()
                self.hovertext:Hide()
            end
        else
            self.hovertext:SetString(text)
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