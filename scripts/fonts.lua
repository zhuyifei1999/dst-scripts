DEFAULTFONT = "opensans"
DIALOGFONT = "opensans"
TITLEFONT = "bp100"
UIFONT = "bp50"
BUTTONFONT = "buttonfont"
NEWFONT = "spirequal"
NEWFONT_SMALL = "spirequal_small"
NEWFONT_OUTLINE = "spirequal_outline"
NEWFONT_OUTLINE_SMALL = "spirequal_outline_small"
NUMBERFONT = "stint-ucr"
TALKINGFONT = "talkingfont"
TALKINGFONT_WATHGRITHR = "talkingfont_wathgrithr"
SMALLNUMBERFONT = "stint-small"
BODYTEXTFONT = "stint-ucr"
CODEFONT = "ptmono"

require "translator"

local font_posfix = ""

if LanguageTranslator then	-- This gets called from the build pipeline too
    local lang = LanguageTranslator.defaultlang 

    -- Some languages need their own font
    local specialFontLangs = {"jp"}

    for i,v in pairs(specialFontLangs) do
        if v == lang then
            font_posfix = "__"..lang
        end
    end
end

FONTS = {
	{ filename = "fonts/talkingfont"..font_posfix..".zip", alias = "talkingfont" },
	{ filename = "fonts/talkingfont_wathgrithr.zip", alias = "talkingfont_wathgrithr" },
	{ filename = "fonts/stint-ucr50"..font_posfix..".zip", alias = "stint-ucr" },
	{ filename = "fonts/stint-ucr20"..font_posfix..".zip", alias = "stint-small" },
	{ filename = "fonts/opensans50"..font_posfix..".zip", alias = "opensans" },
	{ filename = "fonts/belisaplumilla50"..font_posfix..".zip", alias = "bp50" },
	{ filename = "fonts/belisaplumilla100"..font_posfix..".zip", alias = "bp100" },	
	{ filename = "fonts/buttonfont"..font_posfix..".zip", alias = "buttonfont" },	
	{ filename = "fonts/spirequal"..font_posfix..".zip", alias = "spirequal" },	
	{ filename = "fonts/spirequal_small"..font_posfix..".zip", alias = "spirequal_small" },	
	{ filename = "fonts/spirequal_outline"..font_posfix..".zip", alias = "spirequal_outline" },
	{ filename = "fonts/spirequal_outline_small"..font_posfix..".zip", alias = "spirequal_outline_small" },
	{ filename = "fonts/ptmono32"..font_posfix..".zip", alias = "ptmono"},
}
