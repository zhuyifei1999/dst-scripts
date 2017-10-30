local Widget = require "widgets/widget"

local Text = Class(Widget, function(self, font, size, text, colour)
    Widget._ctor(self, "Text")

    self.inst.entity:AddTextWidget()

    self.inst.TextWidget:SetFont(font)
    self.font = font
    self.inst.TextWidget:SetSize(size)
    self.size = size

    self:SetColour(colour or { 1, 1, 1, 1 })

    if text ~= nil then
        self:SetString(text)
    end
end)

function Text:__tostring()
    return string.format("%s - %s", self.name, self.string or "")
end

function Text:DebugDraw_AddSection(dbui)
    Text._base.DebugDraw_AddSection(self, dbui)

    local changed, text = dbui.InputText("string", self:GetString())
    if changed then
        self:SetString(text)
    end

    local changed, size = dbui.DragInt("font size", self.size, 1, 10, 150, "%.f")
    if changed then
        self:SetSize(size)
    end
    local changed, r,g,b,a = dbui.ColorEdit4("colour", unpack(self.colour))
    if changed then
        self:SetColour(r, g, b, a)
    end

    local current_font_idx = 1
    local available_fonts = {}
    for i,font in ipairs(FONTS) do
        table.insert(available_fonts, font.alias)
        if font.alias == self.font then
            current_font_idx = i
        end
    end
    local changed, font_idx = dbui.ListBox("font", available_fonts, current_font_idx, 3)
    if changed then
        self:SetFont(available_fonts[font_idx])
    end
end

function Text:SetColour(r, g, b, a)
    self.colour = type(r) == "number" and { r, g, b, a } or r
    self.inst.TextWidget:SetColour(unpack(self.colour))
end

function Text:GetColour()
    return { unpack(self.colour) }
end

function Text:SetHorizontalSqueeze(squeeze)
    self.inst.TextWidget:SetHorizontalSqueeze(squeeze)
end

function Text:SetFadeAlpha(a, skipChildren)
    if not self.can_fade_alpha then return end
    
    self.inst.TextWidget:SetColour(self.colour[1], self.colour[2], self.colour[3], self.colour[4] * a)
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
    str = str ~= nil and str:match("^[^\n\v\f\r]*") or ""
    if #str > 0 then
        if type(ellipses) ~= "string" then
            ellipses = ellipses and "..." or ""
        end
        if maxchars ~= nil and str:utf8len() > maxchars then
            str = str:utf8sub(1, maxchars)
            self.inst.TextWidget:SetString(str..ellipses)
        else
            self.inst.TextWidget:SetString(str)
        end
        if maxwidth ~= nil then
            while self.inst.TextWidget:GetRegionSize() > maxwidth do
                str = str:utf8sub(1, -2)
                self.inst.TextWidget:SetString(str..ellipses)
            end
        end
    else
        self.inst.TextWidget:SetString("")
    end
end

local function IsWhiteSpace(charcode)
    -- 32: space
    --  9: \t
    return charcode == 32 or charcode == 9
end

local function IsNewLine(charcode)
    -- 10: \n
    -- 11: \v
    -- 12: \f
    -- 13: \r
    return charcode >= 10 and charcode <= 13
end

-- maxwidth can be a single number or an array of numbers if maxwidth is different per line
function Text:SetMultilineTruncatedString(str, maxlines, maxwidth, maxcharsperline, ellipses)
    if str == nil or #str <= 0 then
        self.inst.TextWidget:SetString("")
        return
    end
    local tempmaxwidth = type(maxwidth) == "table" and maxwidth[1] or maxwidth
    if maxlines <= 1 then
        self:SetTruncatedString(str, tempmaxwidth, maxcharsperline, ellipses)
    else
        self:SetTruncatedString(str, tempmaxwidth, maxcharsperline, false)
        local line = self:GetString()
        if #line < #str then
            if IsNewLine(str:byte(#line + 1)) then
                str = str:sub(#line + 2)
            elseif not IsWhiteSpace(str:byte(#line + 1)) then
                for i = #line, 1, -1 do
                    if IsWhiteSpace(line:byte(i)) then
                        line = line:sub(1, i)
                        break
                    end
                end
                str = str:sub(#line + 1)
            else
                str = str:sub(#line + 2)
                while #str > 0 and IsWhiteSpace(str:byte(1)) do
                    str = str:sub(2)
                end
            end
            if #str > 0 then
                if type(maxwidth) == "table" then
                    if #maxwidth > 2 then
                        tempmaxwidth = {}
                        for i = 2, #maxwidth do
                            table.insert(tempmaxwidth, maxwidth[i])
                        end
                    elseif #maxwidth == 2 then
                        tempmaxwidth = maxwidth[2]
                    end
                end
                self:SetMultilineTruncatedString(str, maxlines - 1, tempmaxwidth, maxcharsperline, ellipses)
                self.inst.TextWidget:SetString(line.."\n"..(self.inst.TextWidget:GetString() or ""))
            end
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

function Text:EnableWhitespaceWrap(enable)
    self.inst.TextWidget:EnableWhitespaceWrap(enable)
end

return Text
