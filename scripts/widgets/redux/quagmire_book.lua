local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Grid = require "widgets/grid"
local Spinner = require "widgets/spinner"

local TEMPLATES = require "widgets/redux/templates"

local RecipeBookWidget = require "widgets/redux/quagmire_recipebook"
local AchievementsPanel = require "widgets/redux/achievementspanel"

require("util")

local QUAGMIRE_NUM_FOOD_RECIPES = QUAGMIRE_NUM_FOOD_PREFABS + 1 -- +1 for syrup
local DISH_ATLAS = "images/quagmire_food_common_inv_images_hires.xml" --"images/quagmire_food_common_inv_images_hires.xml"

local FILTER_ANY = "any"

local function MakeDetailsLine(details_root, x, y, scale, image_override)
	local value_title_line = details_root:AddChild(Image("images/quagmire_recipebook.xml", image_override or "quagmire_recipe_line.tex"))
	value_title_line:SetScale(scale, scale)
	value_title_line:SetPosition(x, y)
end


-------------------------------------------------------------------------------------------------------
local QuagmireBook = Class(Widget, function(self, user_profile)
    Widget._ctor(self, "OnlineStatus")

    self.root = self:AddChild(Widget("root"))

	local tab_root = self.root:AddChild(Widget("tab_root"))

	local backdrop = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex"))
    backdrop:ScaleToSize(900, 550)

	local achievement_overrides = {}
	achievement_overrides.offset_y = -5
	achievement_overrides.divider_atlas = "images/quagmire_recipebook.xml"
	achievement_overrides.divider_tex = "quagmire_recipe_line_break2.tex"
	achievement_overrides.divider_h = 12
	achievement_overrides.quagmire_gridframe = true
	achievement_overrides.no_title = true
	achievement_overrides.primary_font_colour = UICOLOURS.BROWN_DARK
	achievement_overrides.scrollbar_offset = -8

	local base_size = .7

	local button_data = {
		{text = STRINGS.UI.RECIPE_BOOK.TITLE, build_panel_fn = function() return RecipeBookWidget() end }, 
		{text = STRINGS.UI.ACHIEVEMENTS.SCREENTITLE, build_panel_fn = function() return AchievementsPanel(user_profile, FESTIVAL_EVENTS.QUAGMIRE, achievement_overrides) end}
	}

	for i, v in ipairs(button_data) do
		local tab = tab_root:AddChild(ImageButton("images/quagmire_recipebook.xml", "quagmire_recipe_tab_inactive.tex", nil, nil, nil, "quagmire_recipe_tab_active.tex"))
		tab:SetPosition(-260 + 240*(i-1), 285)
		tab:SetFocusScale(base_size, base_size)
		tab:SetNormalScale(base_size, base_size)
		tab:SetText(v.text)
		tab:SetTextSize(22)
		tab:SetFont(HEADERFONT)
		tab:SetTextColour(UICOLOURS.GOLD)
		tab:SetTextFocusColour(UICOLOURS.GOLD)
		tab:SetTextSelectedColour(UICOLOURS.GOLD)
		tab.text:SetPosition(0, -2)
		tab.clickoffset = Vector3(0,5,0)
		tab:SetOnClick(function()
	        self.last_selected:Unselect()
	        self.last_selected = tab
			tab:Select()
			tab:MoveToFront()
			if self.panel ~= nil then 
				self.panel:Kill()
			end
			self.panel = self.root:AddChild(v.build_panel_fn())
		end)

		if i == 1 then
			self.last_selected = tab
		end
	end

	-----
	self.last_selected:Select()	
	self.last_selected:MoveToFront()
	self.panel = self.root:AddChild(RecipeBookWidget())


end)

return QuagmireBook
