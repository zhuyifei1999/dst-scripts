local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local TEMPLATES = require "widgets/templates"
require "os"

local klei_tz = 28800--The time zone offset for vancouver

local CountdownBeta = Class(Widget, function(self, owner)
	Widget._ctor(self, "Countdown")
	self.owner = owner

	local mode = 5

	if mode == 1 then
		self.bg = self:AddChild( TEMPLATES.CurlyWindow(0, 153, .56, 1, 67, -42))
		self.bg:SetPosition(-8, 0)

--		self.daysuntilanim = self:AddChild(UIAnim())
--		self.daysuntilanim:GetAnimState():SetBuild("build_status")
--		self.daysuntilanim:GetAnimState():SetBank("build_status")
--		self.daysuntilanim:SetPosition(0, 0, 0)

		--self.image = self:AddChild(ImageButton( "images/global.xml", "square.tex", "square.tex", "square.tex" ))
		self.image = self:AddChild(ImageButton( "images/servericons.xml", "playstyle_coop.tex", "playstyle_coop.tex", "playstyle_coop.tex" ))
		self.image:SetScale(.9)
		self.image:SetPosition(-2, 8, 0)
		self.image:SetFocusScale(1, 1, 1)
		self.image:SetClickable(false)
		--self.image:Hide()

		self.daysuntiltext = self:AddChild(Text(NUMBERFONT, 35))
		self.daysuntiltext:SetPosition(0, 120, 0)
		self.daysuntiltext:SetRegionSize( 240, 50 )
		self.daysuntiltext:SetClickable(false)

		local add_button = false
		if add_button then
			self.button = self:AddChild(ImageButton())
			self.button:SetPosition(0,-130)
			self.button:SetScale(.8*.9)
			self.button:SetText(STRINGS.UI.MAINSCREEN.MOTDBUTTON)

			self.image:SetClickable(true)
			self.image:SetOnGainFocus( function() self.button:OnGainFocus() end )
			self.image:SetOnLoseFocus( function() self.button:OnLoseFocus() end )
			self.image:SetOnClick( function() self.button.onclick() end )

			self.focus_forward = self.button
			self.default_focus = self.button
		end
	elseif mode == 2 then

		self.bg = self:AddChild( TEMPLATES.CurlyWindow(0, 0, .56, .56, 67*.56, -42*.56))
		self.bg:SetPosition(-8, 0)

		self.daysuntiltext = self:AddChild(Text(NUMBERFONT, 35))
		self.daysuntiltext:SetPosition(0, 5, 0)
		self.daysuntiltext:SetRegionSize( 240, 50 )
		self.daysuntiltext:SetClickable(false)

	elseif mode == 3 then

		self.daysuntilanim = self:AddChild(UIAnim())
		self.daysuntilanim:GetAnimState():SetBuild("build_status")
		self.daysuntilanim:GetAnimState():SetBank("build_status")
		self.daysuntilanim:SetPosition(0, 0, 0)
		self.daysuntilanim:SetScale(-1, 1, 1)
		self.daysuntilanim:GetAnimState():PlayAnimation("about", true)

		self.daysuntiltext = self:AddChild(Text(NUMBERFONT, 35))
		self.daysuntiltext:SetPosition(30, -80, 0)
		self.daysuntiltext:SetRegionSize( 240, 50 )
		self.daysuntiltext:SetClickable(false)

	elseif mode == 4 then
	--scribble_black
		self.bg = self:AddChild( Image("images/frontend.xml", "scribble_black.tex") )
		self.bg:SetPosition(0, 2)
		self.bg:SetScale(1.25, 1.1, 1)

		self.daysuntiltext = self:AddChild(Text(NUMBERFONT, 35))
		self.daysuntiltext:SetPosition(0, 5, 0)
		self.daysuntiltext:SetRegionSize( 240, 50 )
		self.daysuntiltext:SetClickable(false)
	elseif mode == 5 then
		self.image = self:AddChild(Image("images/frontend.xml", "silhouette_beta_1.tex"))
		self.image:SetScale(-1, 1, 1)
		self.image:SetPosition(0, 90, 0)
		self.image:SetClickable(false)

		local lableroot = self:AddChild(Widget("LableRoot"))
		lableroot:SetPosition(0, -85)

		self.bg = lableroot:AddChild( Image("images/frontend.xml", "scribble_black.tex") )
		self.bg:SetPosition(0, -2)
		self.bg:SetScale(1.25, 1.6, 1)

		self.title = lableroot:AddChild(Text(NUMBERFONT, 35))
		self.title:SetPosition(0, 18, 0)
		self.title:SetRegionSize( 240, 50 )
		self.title:SetClickable(false)
		self.title:SetString(STRINGS.UI.MAINSCREEN.BETA_LABEL)

		self.daysuntiltext = lableroot:AddChild(Text(NUMBERFONT, 30))
		self.daysuntiltext:SetPosition(0, -18, 0)
		self.daysuntiltext:SetRegionSize( 240, 50 )
		self.daysuntiltext:SetClickable(false)


	end


end)

local function get_timezone()
  local now = os.time()
  return os.difftime(now, os.time(os.date("!*t", now)))
end

function CountdownBeta:SetCountdownDate(date)
	if not date or type(date) ~= "table" then
		self.daysuntiltext:SetString(STRINGS.UI.MAINSCREEN.BETA_LABEL)
		return
	end

	local now = os.time() - get_timezone()
	local update_time = os.time(date) - klei_tz
	local build_time = TheSim:GetBuildDate()

	local days_until 		= ((((update_time - now) / 60) / 60) / 24)
	local days_since 		= ((((now - build_time) / 60) / 60) / 24)
	local build_update_diff = ((((build_time - update_time) / 60) / 60) / 24)

	print( "SetCountdownDate:", days_until, days_since, build_update_diff)

	if not days_until and not days_since then return end
	if days_until and days_since then
		if days_until >= 1 then
			self.days_until_string = string.format(STRINGS.UI.MAINSCREEN.NEXTUPDATEDAYS, math.ceil(days_until)) 
			--self.daysuntilanim:GetAnimState():PlayAnimation("about", true)
		elseif days_until < 1 and days_until >= -1 and build_update_diff < 0 then
			self.days_until_string = string.format(STRINGS.UI.MAINSCREEN.NEXTBUILDIMMINENT)
			--self.daysuntilanim:GetAnimState():PlayAnimation("coming", true)
		else
			self.days_until_string = string.format(STRINGS.UI.MAINSCREEN.NEXTBUILDIMMINENT)
			--self.days_until_string = string.format(STRINGS.UI.MAINSCREEN.FRESHBUILD)
			--self.daysuntilanim:GetAnimState():PlayAnimation("fresh", true)
		end

		self.daysuntiltext:SetString(self.days_until_string)
	end
end

return CountdownBeta