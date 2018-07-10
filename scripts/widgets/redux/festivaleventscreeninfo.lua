local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local TEMPLATES = require "widgets/redux/templates"

local FestivalEventScreenInfo = Class(Widget, function(self)
	Widget._ctor(self, "FestivalEventScreenInfo")

	local image = self:AddChild(Image("images/quagmire_frontend.xml", "gorge_tournament_info.tex"))
	image:SetScale(0.7, 0.7)
	image:SetPosition(0, 0)
	image:SetClickable(false)

	self.button = self:AddChild(TEMPLATES.StandardButton(function() VisitURL("https://forums.kleientertainment.com/topic/93336-the-gorge-tournament-has-begun/") end, STRINGS.UI.MODSSCREEN.MODLINK_MOREINFO))
	self.button:SetScale(0.5, 0.5)
	self.button:SetPosition(0, -110)

	if self.button ~= nil then 
		self.focus_forward = self.button
	end
end)

return FestivalEventScreenInfo