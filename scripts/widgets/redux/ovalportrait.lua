local Image = require "widgets/image"
local Text = require "widgets/text"
local Widget = require "widgets/widget"

require("characterutil")
require("stringutil")

-- Big marquee name, oval portrait, small name, title, and description. Good
-- for character selection-type screens.
local OvalPortrait = Class(Widget, function(self, character, description_getter_fn)
	Widget._ctor(self, "OvalPortrait")

    self.description_getter_fn = description_getter_fn or function(name) return GetCharacterDescription(name) end

    self.portrait_root = self:AddChild(self:_BuildCharacterDetails())
    if character then
        self:SetPortrait(character)
    end
end)

function OvalPortrait:_BuildCharacterDetails()
    local portrait_root = Widget("portrait_root")

    -- Everything is anchored around heroportrait.
    self.heroportrait = portrait_root:AddChild(Image())
    self.heroportrait:SetPosition(0, -20)
    self.heroportrait:SetScale(.43)

    self.heroname = portrait_root:AddChild(Image())
    self.heroname:SetScale(.28)
    self.heroname:SetPosition(0, 160)

    self.character_text = portrait_root:AddChild(Widget("character details"))
    self.character_text:SetPosition(0, -170)

    --self.charactername = self.character_text:AddChild(Text(TITLEFONT, 42))
    --self.charactername:SetHAlign(ANCHOR_MIDDLE)
    --self.charactername:SetRegionSize(300, 70)
    --self.charactername:SetColour(GOLD)

    self.charactertitle = self.character_text:AddChild(Text(HEADERFONT, 25))
    self.charactertitle:SetHAlign(ANCHOR_MIDDLE)
    self.charactertitle:SetPosition(7, -40) 
    self.charactertitle:SetRegionSize(300, 50)
    self.charactertitle:SetColour(UICOLOURS.GOLD_SELECTED)

    self.characterdetails = self.character_text:AddChild(Text(CHATFONT, 21))
    self.characterdetails:SetHAlign(ANCHOR_MIDDLE)
    self.characterdetails:SetVAlign(ANCHOR_TOP)
    self.characterdetails:SetPosition(7, -130)
    self.characterdetails:SetRegionSize(280, 130)
    self.characterdetails:EnableWordWrap(true)
    self.characterdetails:SetColour(UICOLOURS.GREY)

	if TheNet:GetServerGameMode() == "lavaarena" then 
	    self.character_text:SetPosition(0, -150)

		self.la_health = self.character_text:AddChild(Text(HEADERFONT, 28))
		self.la_health:SetHAlign(ANCHOR_LEFT)
		self.la_health:SetRegionSize(300, 30)
		self.la_health:SetColour(UICOLOURS.WHITE)
		self.la_health:SetPosition(15, -210)

        self.la_difficulty= self.character_text:AddChild(Text(HEADERFONT, 20))
		self.la_difficulty:SetHAlign(ANCHOR_LEFT)
		self.la_difficulty:SetRegionSize(300, 30)
		self.la_difficulty:SetColour(UICOLOURS.EGGSHELL)
		self.la_difficulty:SetPosition(15, -235)
        
		self.la_items = self.character_text:AddChild(Text(HEADERFONT, 20))
		self.la_items:SetVAlign(ANCHOR_TOP)
		self.la_items:SetHAlign(ANCHOR_LEFT)
		self.la_items:SetRegionSize(300, 70)
		self.la_items:SetColour(UICOLOURS.EGGSHELL)
        self.la_items:EnableWordWrap(true)
		self.la_items:SetPosition(15, -280)
		
	end
	

    return portrait_root
end

function OvalPortrait:SetPortrait(herocharacter)
    assert(herocharacter)

    self.currentcharacter = herocharacter

    local found_name = SetHeroNameTexture_Gold(self.heroname, herocharacter)
    if found_name then 
        self.heroname:Show()
    else
        self.heroname:Hide()
    end

    SetOvalPortraitTexture(self.heroportrait, herocharacter)

    if self.charactername then
        self.charactername:SetString(STRINGS.CHARACTER_NAMES[herocharacter] or "")
    end
    if self.charactertitle then
        self.charactertitle:SetString(STRINGS.CHARACTER_TITLES[herocharacter] or "")
    end
    if self.characterquote then
        self.characterquote:SetString(STRINGS.CHARACTER_QUOTES[herocharacter] or "")
    end
    if self.characterdetails then
        self.characterdetails:SetString(self.description_getter_fn(herocharacter) or "")
    end
    
    if self.la_health then
		if TUNING.LAVAARENA_STARTING_HEALTH[string.upper(herocharacter)] ~= nil then
			self.la_health:SetString(STRINGS.UI.PORTRAIT.HP .. " : " .. TUNING.LAVAARENA_STARTING_HEALTH[string.upper(herocharacter)])
		else
			self.la_health:SetString("")
		end
	end
	
    if self.la_items then
		local hero_items = TUNING.LAVAARENA_STARTING_ITEMS[string.upper(herocharacter)]
		if hero_items ~= nil then
			local item1 = STRINGS.NAMES[string.upper(hero_items[1])]
			local item2 = STRINGS.NAMES[string.upper(hero_items[2])]
			self.la_items:SetString(STRINGS.UI.PORTRAIT.ITEMS .. " : " ..  item1 .. ", " .. item2)
		else
			self.la_items:SetString("")
		end
	end
	
	if self.la_difficulty then
		local dif = TUNING.LAVAARENA_SURVIVOR_DIFFICULTY[string.upper(herocharacter)]
		if dif ~= nil then
			self.la_difficulty:SetString(STRINGS.UI.PORTRAIT.DIFFICULTY .. " : " .. tostring((dif == 1 and "+") or (dif == 2 and "++") or "+++"))
		else
			self.la_difficulty:SetString("")
		end
	end
	
end

return OvalPortrait