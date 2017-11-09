require "strings"
require "emoji_items"

local Text = require "widgets/text"
local Widget = require "widgets/widget"


local function GetAllowedEmojiNames(userid)
    local has_ownership = nil
    if TheWorld.ismastersim then
        has_ownership = function(item_type) return TheInventory:CheckClientOwnership(userid, item_type) end
    elseif userid == TheNet:GetUserID() then
        has_ownership = function(item_type) return TheInventory:CheckOwnership(item_type) end
    else
        return {}
    end

    local emoji_translator = {}
    local allowed_emoji = {}
    for item_type,emoji in pairs(EMOJI_ITEMS) do
        if has_ownership(item_type) then
            emoji_translator[emoji.input_name] = emoji.data.utf8_str
            table.insert(allowed_emoji, emoji.input_name)
        end
    end
    return allowed_emoji, emoji_translator
end

-- See util/textcompleter.lua
local function GetSuggestionDataForTextCompleter(userid)
    local words, emoji_translator = GetAllowedEmojiNames(userid)
    local suggestion_data = {
        -- Empty prefix. Can be inserted anywhere.
        prefixes = { "" },
        words = words,
        delimiters = { ":" },
    }
    return suggestion_data, emoji_translator
end



-- Create a special Text-like widget for displaying emoji names and their utf8
-- representation. Seeing the image that we'll insert makes the autocomplete
-- much more meaningful.
--
-- Must maintain the Text interface used by TextCompleter (it treats us as a
-- Text widget).
local EmojiSuggestText = Class(Widget, function(self, emoji_translator, font, size, bg_colour)
    Widget._ctor(self, "EmojiSuggestText")

    self.emoji_translator = emoji_translator
    self.emoji_width = 50
    self.emoji_padding = 10

    -- Only apply a background if we were provided a colour.
    if bg_colour then
        self.bg_image = self:AddChild(Image("images/global.xml", "square.tex"))
        self.bg_image:SetTint(unpack(bg_colour))
        self.bg_image:SetPosition(0, 0)
        self.bg_image:SetBlendMode(BLENDMODE.Premultiplied)
    end

    self.emoji_name = self:AddChild(Text(font, size, ""))
    self.emoji_name:SetHAlign(ANCHOR_RIGHT)

    self.emoji_utf8 = self:AddChild(Text(font, size, ""))
    self.emoji_utf8:SetHAlign(ANCHOR_LEFT)

    -- Ensure we apply our visibility setup in child widgets.
    self:SetString("")
end)

function EmojiSuggestText:SetString(str)
    self.emoji_name:SetString(str)

    local utf8_str = str
    local bg_alpha = 0
    if str and str:len() > 0 then
        utf8_str = self.emoji_translator[str]
        bg_alpha = 0.95
    end

    self.emoji_utf8:SetString(utf8_str)
    if self.bg_image then
        self.bg_image:SetFadeAlpha(bg_alpha)
    end
end

function EmojiSuggestText:GetString()
    return self.emoji_name:GetString()
end

function EmojiSuggestText:SetHAlign(anchor)
    return self.emoji_name:SetHAlign(anchor)
end

function EmojiSuggestText:SetColour(r,g,b,a)
    self.emoji_name:SetColour(r,g,b,a)
    self.emoji_utf8:SetColour(r,g,b,a)
end

function EmojiSuggestText:SetRegionSize(width, height)
    -- Positions are relative to centre of parent and we're setting our centre.

    -- Use all space unused by utf8.
    local padding_sections = 3
    local name_width = width - self.emoji_width - self.emoji_padding * padding_sections
    self.emoji_name:SetRegionSize(name_width, height)
    -- Insert padding before left edge.
    self.emoji_name:SetPosition(-width/2 + self.emoji_padding + name_width/2, 0)

    -- Take the same height as parent.
    self.emoji_utf8:SetRegionSize(self.emoji_width, height)
    -- Insert padding before right edge.
    self.emoji_utf8:SetPosition(width/2 - self.emoji_width / 2 - self.emoji_padding, 0)

    if self.bg_image then
        self.bg_image:SetSize(width, height)
    end
end


return {
    GetSuggestionDataForTextCompleter = GetSuggestionDataForTextCompleter,
    EmojiSuggestText = EmojiSuggestText,
}
