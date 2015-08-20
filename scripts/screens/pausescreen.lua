local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local PopupDialogScreen = require "screens/popupdialog"
local TEMPLATES = require "widgets/templates"
local OptionsScreen = nil
if PLATFORM == "PS4" then
    OptionsScreen = require "screens/optionsscreen_ps4"
else
    OptionsScreen = require "screens/optionsscreen"
end

local PauseScreen = Class(Screen, function(self)
	Screen._ctor(self, "PauseScreen")

	self.active = true
	SetPause(true,"pause")
	
	--darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	

	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--throw up the background
	self.bg = self.proot:AddChild(TEMPLATES.CurlyWindow(70, 50, 1, 1, 68, -40))
    self.bg.fill = self.proot:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
	self.bg.fill:SetScale(.82, .4)
	self.bg.fill:SetPosition(8, 12)
	
	--title	
    self.title = self.proot:AddChild(Text(BUTTONFONT, 50))
    self.title:SetPosition(5, 35, 0)
    self.title:SetString(STRINGS.UI.PAUSEMENU.DST_TITLE)
    self.title:SetColour(0,0,0,1)

	--create the menu itself
	local player = ThePlayer
	local can_save = player and player:IsValid() and player.components.health and not player.components.health:IsDead() and IsGamePurchased()
	local button_w = 160
	
	local quit_button_text = STRINGS.UI.PAUSEMENU.DISCONNECT
	
	--[[
	--jcheng: disable afk for now
	local buttons = {}
    table.insert(buttons, {text=STRINGS.UI.PAUSEMENU.OPTIONS, cb=function() TheFrontEnd:PushScreen( OptionsScreen(true))	end })

    local buttons2 = {}
    table.insert(buttons2, {text=STRINGS.UI.PAUSEMENU.CONTINUE, cb=function() self:unpause() end })
    table.insert(buttons2, {text=STRINGS.UI.PAUSEMENU.AFK, cb=function() self:goafk() end})
    table.insert(buttons2, {text=quit_button_text, cb=function() self:doconfirmquit() end})
    
	self.menu = self.proot:AddChild(Menu(buttons2, button_w, true)) 
	self.menu:SetPosition(-(button_w*(#buttons2-1))/2, 0, 0) 

	self.afk_menu = self.proot:AddChild(Menu(buttons, button_w, true)) 
	self.afk_menu:SetPosition(-(button_w*(#buttons-1))/2, -75, 0) 
	]]

	local buttons = {}
	table.insert(buttons, {text=STRINGS.UI.PAUSEMENU.CONTINUE, cb=function() self:unpause() end })
	table.insert(buttons, {text=STRINGS.UI.PAUSEMENU.OPTIONS, cb=function() 
    	TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
			TheFrontEnd:PushScreen(OptionsScreen(true))	
			TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
            --Ensure last_focus is the options button since mouse can
            --unfocus this button during the screen change, resulting
            --in controllers having no focus when toggled on from the
            --options screen
            self.last_focus = self.menu.items[2]
		end)
    end })
    table.insert(buttons, {text=quit_button_text, cb=function() self:doconfirmquit()	end})
    
	self.menu = self.proot:AddChild(Menu(buttons, button_w, true))
	self.menu:SetPosition(10-(button_w*(#buttons-1))/2, -25, 0) 
	for i,v in pairs(self.menu.items) do
		v:SetScale(.7)
	end

    if JapaneseOnPS4() then
		self.menu:SetTextSize(30)
		--self.afk_menu:SetTextSize(30)
	end

	TheInputProxy:SetCursorVisible(true)
	self.default_focus = self.menu
end)

function PauseScreen:unpause()
	TheFrontEnd:PopScreen(self)
	if not self.was_paused then 
		SetPause(false) 
	end 

	TheWorld:PushEvent("continuefrompause")
end

--[[
function PauseScreen:goafk()
	self:unpause()

	local player = ThePlayer
	if player.components.combat and player.components.combat:IsInDanger() then
		--it's too dangerous to afk
		player.components.talker:Say(GetString(player, "ANNOUNCE_NODANGERAFK"))
		return
	end	

	player.replica.afk:PrepareForAFK()
end
]]

function PauseScreen:doconfirmquit()	
 	self.active = false

	local function doquit()
		self.parent:Disable()
		self.menu:Disable()
		--self.afk_menu:Disable()

		DoRestart(true)
	end

	if TheNet:GetIsServer() then
		local confirm = PopupDialogScreen(STRINGS.UI.PAUSEMENU.HOSTQUITTITLE, STRINGS.UI.PAUSEMENU.HOSTQUITBODY, {{text=STRINGS.UI.PAUSEMENU.YES, cb = doquit},{text=STRINGS.UI.PAUSEMENU.NO, cb = function() TheFrontEnd:PopScreen() end}  })
		if JapaneseOnPS4() then
			confirm:SetTitleTextSize(40)
			confirm:SetButtonTextSize(30)
		end
		TheFrontEnd:PushScreen(confirm)
	else
		local confirm = PopupDialogScreen(STRINGS.UI.PAUSEMENU.CLIENTQUITTITLE, STRINGS.UI.PAUSEMENU.CLIENTQUITBODY, {{text=STRINGS.UI.PAUSEMENU.YES, cb = doquit},{text=STRINGS.UI.PAUSEMENU.NO, cb = function() TheFrontEnd:PopScreen() end}  })
		if JapaneseOnPS4() then
			confirm:SetTitleTextSize(40)
			confirm:SetButtonTextSize(30)
		end
		TheFrontEnd:PushScreen(confirm)
	end
end

function PauseScreen:OnControl(control, down)
	if PauseScreen._base.OnControl(self,control, down) then return true end

	if (control == CONTROL_PAUSE or control == CONTROL_CANCEL) and not down then	
		self.active = false
		TheFrontEnd:PopScreen() 
		SetPause(false)
		TheWorld:PushEvent("continuefrompause")
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		return true
	end

end

function PauseScreen:OnUpdate(dt)
	if self.active then
		SetPause(true)
	end
end

function PauseScreen:OnBecomeActive()
	PauseScreen._base.OnBecomeActive(self)
	-- Hide the topfade, it'll obscure the pause menu if paused during fade. Fade-out will re-enable it
	TheFrontEnd:HideTopFade()
end

return PauseScreen
