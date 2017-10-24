local ClothingExplorerPanel = require "widgets/redux/clothingexplorerpanel"
local Image = require "widgets/image"
local Puppet = require "widgets/skinspuppet"
local Screen = require "widgets/screen"
local Subscreener = require "screens/redux/subscreener"
local Text = require "widgets/text"
local Widget = require "widgets/widget"

local TEMPLATES = require("widgets/redux/templates")

local WardrobeScreen = Class(Screen, function(self, user_profile, character)
	Screen._ctor(self, "WardrobeScreen")
	self.user_profile = user_profile
    self.currentcharacter = character

    self:_DoInit()

	self.default_focus = self.subscreener.menu

    ----------------------------------------------------------
	-- Prepare for viewing

    self.subscreener:OnMenuButtonSelected("base")
end)

function WardrobeScreen:_DoInit()
    self.root = self:AddChild(TEMPLATES.ScreenRoot())
    self.bg = self.root:AddChild(TEMPLATES.DarkMenuBackground())	

    self.title = self.root:AddChild(TEMPLATES.ScreenTitle(STRINGS.UI.WARDROBESCREEN.TITLE, ""))

    self.doodad_count = self.root:AddChild(TEMPLATES.DoodadCounter(TheInventory:GetCurrencyAmount()))
	self.doodad_count:SetPosition(-540, 195)
	self.doodad_count:SetScale(0.5)

    self.puppet_root = self.root:AddChild(Widget("puppet_root"))
    self.puppet_root:SetPosition(-100, -190)

    self.heroname = self.puppet_root:AddChild(Image())
    self.heroname:SetScale(.28)
    self.heroname:SetPosition(0, 460)

    self.heroportrait = self.puppet_root:AddChild(Image())
    self.heroportrait:SetScale(.4)
    self.heroportrait:SetPosition(-130, 160)

    self.puppet = self.puppet_root:AddChild(Puppet())
    self.puppet:SetPosition(0, 50)
    self.puppet:SetScale(4)
    self.puppet:SetClickable(false)

    self.characterquote = self.puppet_root:AddChild(Text(CHATFONT, 21))
    self.characterquote:SetHAlign(ANCHOR_MIDDLE)
    self.characterquote:SetVAlign(ANCHOR_TOP)
    self.characterquote:SetPosition(0,-20)
    self.characterquote:SetRegionSize(300, 60)
    self.characterquote:EnableWordWrap(true)

    -- Can't load skins until above widgets exist. Can't create
    -- ClothingExplorerPanel until skins are loaded.
	self:_LoadSavedSkins()

    local reader = function(item_key)
        return table.contains(self.selected_skins, item_key)
    end
    local writer_builder = function(item_type)
        return function(item_data)
            self:_SelectSkin(item_type, item_data.item_key, item_data.is_active, item_data.is_owned)
        end
    end
    self.subscreener = Subscreener(self,
        self._MakeMenu,
        {
            -- Menu items
            base = self.root:AddChild(ClothingExplorerPanel(self, self.user_profile, "base", reader, writer_builder("base"))),
            body = self.root:AddChild(ClothingExplorerPanel(self, self.user_profile, "body", reader, writer_builder("body"))),
            hand = self.root:AddChild(ClothingExplorerPanel(self, self.user_profile, "hand", reader, writer_builder("hand"))),
            legs = self.root:AddChild(ClothingExplorerPanel(self, self.user_profile, "legs", reader, writer_builder("legs"))),
            feet = self.root:AddChild(ClothingExplorerPanel(self, self.user_profile, "feet", reader, writer_builder("feet"))),
        })

    if not TheInput:ControllerAttached() then
        self.back_button = self.root:AddChild(TEMPLATES.BackButton(
                function()
                    self:_CloseScreen()
                end,
                STRINGS.UI.WARDROBESCREEN.ACCEPT
            ))

        self.reset_current = self.root:AddChild(TEMPLATES.StandardButton(
                function()
                    self:_LoadSavedSkins()
                end,
                STRINGS.UI.WARDROBESCREEN.RESET,
                {180,45}
            ))
        self.reset_current:SetPosition(-100, -314)
        self:_CheckDirty()
    end
end

function WardrobeScreen:_MakeMenu(subscreener)
    self.tooltip = self.root:AddChild(TEMPLATES.ScreenTooltip())

    local button_base = subscreener:MenuButton(STRINGS.UI.WARDROBESCREEN.BASE, "base", STRINGS.UI.WARDROBESCREEN.TOOLTIP_BASE, self.tooltip)
    local button_body = subscreener:MenuButton(STRINGS.UI.WARDROBESCREEN.BODY, "body", STRINGS.UI.WARDROBESCREEN.TOOLTIP_BODY, self.tooltip)
    local button_hand = subscreener:MenuButton(STRINGS.UI.WARDROBESCREEN.HAND, "hand", STRINGS.UI.WARDROBESCREEN.TOOLTIP_HAND, self.tooltip)
    local button_legs = subscreener:MenuButton(STRINGS.UI.WARDROBESCREEN.LEGS, "legs", STRINGS.UI.WARDROBESCREEN.TOOLTIP_LEGS, self.tooltip)
    local button_feet = subscreener:MenuButton(STRINGS.UI.WARDROBESCREEN.FEET, "feet", STRINGS.UI.WARDROBESCREEN.TOOLTIP_FEET, self.tooltip)

    local menu_items = {
        {widget = button_feet },
        {widget = button_legs },
        {widget = button_hand },
        {widget = button_body },
        {widget = button_base },
    }

    return self.root:AddChild(TEMPLATES.StandardMenu(menu_items, 38, nil, nil, true))
end

function WardrobeScreen:_CloseScreen()
    self:_SaveLoadout()

    TheFrontEnd:FadeBack()
end

function WardrobeScreen:_ValidateSkins()
    for key,item_key in pairs(self.selected_skins) do
        if not TheInventory:CheckOwnership(self.selected_skins[key])
            or (key ~= "base" and not IsValidClothing(self.selected_skins[key]))
            then
            self.selected_skins[key] = nil
        end
    end
    if not self.selected_skins.base
        or self.selected_skins.base == self.currentcharacter
        or self.selected_skins.base == ""
        then
        self.selected_skins.base = self.currentcharacter.."_none"
    end
end
			
function WardrobeScreen:_SaveLoadout()
    self:_ValidateSkins()
    self.user_profile:SetSkinsForCharacter(self.currentcharacter, self.selected_skins.base, self.selected_skins)
end

function WardrobeScreen:_LoadSavedSkins()
	local saved_base = self.user_profile:GetBaseForCharacter(self.currentcharacter)
	if not saved_base or saved_base == "" then -- checking == "" is for legacy profiles
		saved_base = self.currentcharacter.."_none"
	end
    self.selected_skins = self.user_profile:GetSkinsForCharacter(self.currentcharacter, saved_base)

    self.selected_skins.base = saved_base
    self.preview_skins = shallowcopy(self.selected_skins)

    -- Creating the subscreens requires skins to be loaded, so we might not
    -- have subscreener yet.
    if self.subscreener then
        for key,item in pairs(self.preview_skins) do
            self.subscreener.sub_screens[key]:RefreshInventory()
        end
    end

    self:_ApplySkins(self.preview_skins)
end

function WardrobeScreen:_CheckDirty()
    if not self.reset_current then
        return
    end

    local saved_base = self.user_profile:GetBaseForCharacter(self.currentcharacter)
    if not saved_base or saved_base == "" then -- checking == "" is for legacy profiles
        saved_base = self.currentcharacter.."_none"
    end
    local saved_skins = self.user_profile:GetSkinsForCharacter(self.currentcharacter, saved_base)

    local dirty = false
    for key,item_key in pairs(self.selected_skins) do
        if saved_skins[key] ~= self.selected_skins[key] then
            dirty = true
        end
    end

    if dirty then
        self.reset_current:Enable()
    else
        self.reset_current:Disable()
    end
end

function WardrobeScreen:_SelectSkin(item_type, item_key, is_selected, is_owned)
    if is_selected or not is_owned then
        --selecting the item or previewing an item
        self.preview_skins[item_type] = item_key
    else
        --deselecting an item
        self.preview_skins[item_type] = nil
    end

    if is_owned then
        if is_selected then
            self.selected_skins[item_type] = item_key
        else
            self.selected_skins[item_type] = nil
        end
    end
    self:_ApplySkins(self.preview_skins)
end

function WardrobeScreen:_ApplySkins(skins)
    self:_ValidateSkins()
    local skin_base = skins.base or self.currentcharacter.."_none"
    self.puppet:SetSkins(self.currentcharacter, skin_base, skins)
	self:_SetPortrait()
    self:_CheckDirty()
end

function WardrobeScreen:_SetPortrait()
	local herocharacter = self.currentcharacter
	local skin = self.preview_skins.base

    local found_name = SetHeroNameTexture_Gold(self.heroname, herocharacter)
    if found_name then 
        self.heroname:Show()
    else
        self.heroname:Hide()
    end

    if skin then
        SetSkinnedOvalPortraitTexture(self.heroportrait, herocharacter, skin)
    else
        SetOvalPortraitTexture(self.heroportrait, herocharacter)
    end

    self.characterquote:SetString(STRINGS.SKIN_QUOTES[skin] or STRINGS.CHARACTER_QUOTES[herocharacter] or "")
end

function WardrobeScreen:RefreshInventory(animateDoodad)
    self.doodad_count:SetCount(TheInventory:GetCurrencyAmount(),animateDoodad)
end

function WardrobeScreen:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.WARDROBESCREEN.ACCEPT)
    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1 ) .. " " .. STRINGS.UI.WARDROBESCREEN.RESET)

	return table.concat(t, "  ")
end

function WardrobeScreen:OnControl(control, down)
	if WardrobeScreen._base.OnControl(self, control, down) then return true end

    if not down and control == CONTROL_CANCEL then
        self:_CloseScreen()
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        return true

    elseif not down and control == CONTROL_MENU_MISC_1 then
        self:_LoadSavedSkins()
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        return true
    end
end

function WardrobeScreen:OnUpdate(dt)
    WardrobeScreen._base.OnUpdate(self, dt)

    self.puppet:EmoteUpdate(dt)
end

return WardrobeScreen