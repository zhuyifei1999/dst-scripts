local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
require "os"

local RoGUpgrade = Class(Widget, function(self, owner)
	Widget._ctor(self, "RoGUpgrade")
	self.owner = owner

	self.button = nil
	if PLATFORM == "PS4" then
		self.button = self:AddChild(ImageButton("images/fepanels.xml", "DLCpromo_button.tex", "DLCpromo_button.tex"))
	else
		self.button = self:AddChild(ImageButton("images/fepanels.xml", "DLCpromo_button_rollover.tex", "DLCpromo_button_rollover.tex"))
	end
	self.button:SetOnClick(self.OnClick)
	MainMenuStatsAdd("seen_rog_upgrade")
	SendMainMenuStats()
end)

local steamlink = "http://store.steampowered.com/app/282470/"
local kleilink = "http://bit.ly/buy-rog"

local function GetLink()
	return PLATFORM == "WIN32_STEAM" and steamlink or kleilink
end

function RoGUpgrade:OnClick()
	--Set Metric!
	MainMenuStatsAdd("click_rog_upgrade")
	SendMainMenuStats()
	VisitURL(GetLink())
end

return RoGUpgrade