local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
require "os"

local WorldGenScreen = require "screens/worldgenscreen"
local PopupDialogScreen = require "screens/popupdialog"
local PlayerHud = require "screens/playerhud"
local EmailSignupScreen = require "screens/emailsignupscreen"
local CreditsScreen = require "screens/creditsscreen"
local ModsScreen = require "screens/modsscreen"
local Countdown = require "widgets/countdown"

local OptionsScreen = require "screens/optionsscreen"
local MorgueScreen = require "screens/morguescreen"
local ServerListingScreen = require "screens/serverlistingscreen"
local ServerCreationScreen = require "screens/servercreationscreen"
local SkinsScreen = require "screens/skinsscreen"

local TEMPLATES = require "widgets/templates"

local OnlineStatus = require "widgets/onlinestatus"

local rcol = RESOLUTION_X/2 -200
local lcol = -RESOLUTION_X/2 +200

local bottom_offset = 60

local titleX = lcol-35
local menuX = lcol-30
local menuY = -240 -- Use -265 when the "game wizard" option is added

SHOW_DST_DEBUG_HOST_JOIN = false
SHOW_DEBUG_UNLOCK_RESET = false
if BRANCH == "dev" then
	SHOW_DST_DEBUG_HOST_JOIN = true
    SHOW_DEBUG_UNLOCK_RESET = true
end

local MultiplayerMainScreen = Class(Screen, function(self, prev_screen, profile, offline, session_data)
	Screen._ctor(self, "MultiplayerMainScreen")
    self.profile = profile
    self.offline = offline
    self.session_data = session_data
	self.log = true
    self.prev_screen = prev_screen
	self:DoInit()
	self.default_focus = self.menu
end)

function MultiplayerMainScreen:DoInit()
    -- Inherited from MainScreen
    self.portal_root = self:AddChild(Widget("portal_root"))
    self:TransferPortalOwnership(self.prev_screen, self)

    self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--RIGHT COLUMN
    self.right_col = self.fixed_root:AddChild(Widget("right"))
	self.right_col:SetPosition(rcol, 0)

	--LEFT COLUMN
    self.left_col = self.fixed_root:AddChild(Widget("left"))
	self.left_col:SetPosition(lcol, 0)

	self.motd = self.right_col:AddChild(Widget("motd"))
	self.motd:SetScale(.9,.9,.9)
	self.motd:SetPosition(-30, RESOLUTION_Y/2-250, 0)
	self.motdbg = self.motd:AddChild( TEMPLATES.CurlyWindow(0, 153, .56, 1, 67, -42))
    self.motdbg:SetPosition(-8, -30)
    self.motdbg.fill = self.motd:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tiny.tex"))
    self.motdbg.fill:SetScale(-.405, -.7)
    self.motdbg.fill:SetPosition(-3, -18)
	self.motd.motdtitle = self.motd:AddChild(Text(BUTTONFONT, 43))
    self.motd.motdtitle:SetColour(0,0,0,1)
    self.motd.motdtitle:SetPosition(0, 70, 0)
	self.motd.motdtitle:SetRegionSize( 350, 60)
	self.motd.motdtitle:SetString(STRINGS.UI.MAINSCREEN.MOTDTITLE)

	self.motd.motdtext = self.motd:AddChild(Text(BUTTONFONT, 32))
    self.motd.motdtext:SetColour(0,0,0,1)
    self.motd.motdtext:SetHAlign(ANCHOR_MIDDLE)
    self.motd.motdtext:SetVAlign(ANCHOR_MIDDLE)
    self.motd.motdtext:SetPosition(0, -40, 0)
	self.motd.motdtext:SetRegionSize(240, 260)
	self.motd.motdtext:SetString(STRINGS.UI.MAINSCREEN.MOTD)
	
	self.motd.motdimage = self.motd:AddChild(ImageButton( "images/global.xml", "square.tex", "square.tex", "square.tex" ))
    self.motd.motdimage:SetPosition(-2, -15, 0)
    self.motd.motdimage:SetFocusScale(1, 1, 1)
    self.motd.motdimage:Hide()
    
    local gainfocusfn = self.motd.motdimage.OnGainFocus
    self.motd.motdimage.OnGainFocus =
		function()
    		gainfocusfn(self.motd.motdimage)
			self.motd:SetScale(0.93,0.93,0.93)
		end
    local losefocusfn = self.motd.motdimage.OnLoseFocus
	self.motd.motdimage.OnLoseFocus =
		function()
    		losefocusfn(self.motd.motdimage)
			self.motd:SetScale(.9,.9,.9)
		end
	self.motd.motdimage:SetOnClick(
		function()
			self.motd.button.onclick()
		end)

    self.motd.button = self.motd:AddChild(ImageButton())
	self.motd.button:SetPosition(0,-160)
    self.motd.button:SetScale(.8*.9)
    self.motd.button:SetText(STRINGS.UI.MAINSCREEN.MOTDBUTTON)
    self.motd.button:SetOnClick( function() VisitURL("http://store.kleientertainment.com/") end )
	self.motd.motdtext:EnableWordWrap(true)  
	
	self.fixed_root:AddChild(Widget("left"))
	self.left_col:SetPosition(lcol, 0) 
    
	self.countdown = self.fixed_root:AddChild(Countdown())
    self.countdown:SetScale(1)
    self.countdown:SetPosition(-575, -330, 0)

    local char1_x = 95
    local char1_y = -260
    local puppet_scale_1 = .52
    local shadow1_x = -3
    local shadow1_y = -5
    local shadow1_scale = .25

    local char2_x = -30
    local char2_y = -275
    local puppet_scale_2 = .6
    local shadow2_x = -3
    local shadow2_y = -5
    local shadow2_scale = .35

    self.shadow1 = self.fg.character_root:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
    self.shadow1:SetPosition(char1_x+shadow1_x,char1_y+shadow1_y)
    self.shadow1:SetScale(shadow1_scale)
    self.shadow2 = self.fg.character_root:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
    self.shadow2:SetPosition(char2_x+shadow2_x,char2_y+shadow2_y)
    self.shadow2:SetScale(shadow2_scale)

    self.wilson = self.fg.character_root:AddChild(UIAnim())
    self.wilson:GetAnimState():SetBank("corner_dude")
    self.wilson:GetAnimState():SetBuild(MAINSCREEN_CHAR_1)
    if BASE_TORSO_TUCK[MAINSCREEN_CHAR_1] then
		--tuck torso into pelvis
		self.wilson:GetAnimState():OverrideSkinSymbol("torso", MAINSCREEN_CHAR_1, "torso_pelvis" )
		self.wilson:GetAnimState():OverrideSkinSymbol("torso_pelvis", MAINSCREEN_CHAR_1, "torso" )
    end
    self.wilson:GetAnimState():SetMultColour(unpack(FRONTEND_CHARACTER_FAR_COLOUR))
    if MAINSCREEN_TOOL_1 == "swap_staffs" then
    	self.wilson:GetAnimState():OverrideSymbol("swap_object", MAINSCREEN_TOOL_1, "redstaff")
    else
    	self.wilson:GetAnimState():OverrideSymbol("swap_object", MAINSCREEN_TOOL_1, MAINSCREEN_TOOL_1)
    end
    self.wilson:GetAnimState():Show("ARM_carry")
    self.wilson:GetAnimState():Hide("ARM_normal")
    if MAINSCREEN_TORSO_1 ~= "" then
    	if MAINSCREEN_TORSO_1 == "torso_amulets" then
    		if math.random() <= .5 then
    			self.wilson:GetAnimState():OverrideSymbol("swap_body", MAINSCREEN_TORSO_1, "purpleamulet")
    		else
    			self.wilson:GetAnimState():OverrideSymbol("swap_body", MAINSCREEN_TORSO_1, "blueamulet")
    		end
    	else
    		self.wilson:GetAnimState():OverrideSymbol("swap_body", MAINSCREEN_TORSO_1, "swap_body")
    	end
    end
    if MAINSCREEN_HAT_1 ~= "" then
    	self.wilson:GetAnimState():OverrideSymbol("swap_hat", MAINSCREEN_HAT_1, "swap_hat")
        self.wilson:GetAnimState():Show("HAT")
        self.wilson:GetAnimState():Show("HAT_HAIR")
        self.wilson:GetAnimState():Hide("HAIR_NOHAT")
        self.wilson:GetAnimState():Hide("HAIR")
		self.wilson:GetAnimState():Hide("HEAD")
		self.wilson:GetAnimState():Show("HEAD_HAT")
    end
    self.wilson:GetAnimState():PlayAnimation("idle", true)
    self.wilson:GetAnimState():SetTime(math.random()*1.5)
    self.wilson:SetPosition(char1_x,char1_y,0)
    self.wilson.inst.UITransform:SetScale(puppet_scale_1,puppet_scale_1,puppet_scale_1)

	self.wilson2 = self.fg.character_root:AddChild(UIAnim())
    self.wilson2:GetAnimState():SetBank("corner_dude")
    self.wilson2:GetAnimState():SetBuild(MAINSCREEN_CHAR_2)
    if BASE_TORSO_TUCK[MAINSCREEN_CHAR_2] then
		--tuck torso into pelvis
		self.wilson2:GetAnimState():OverrideSkinSymbol("torso", MAINSCREEN_CHAR_2, "torso_pelvis" )
		self.wilson2:GetAnimState():OverrideSkinSymbol("torso_pelvis", MAINSCREEN_CHAR_2, "torso" )
    end
    self.wilson2:GetAnimState():SetMultColour(unpack(FRONTEND_CHARACTER_CLOSE_COLOUR))
	if MAINSCREEN_TOOL_2 == "swap_staffs" then
    	self.wilson2:GetAnimState():OverrideSymbol("swap_object", MAINSCREEN_TOOL_2, "redstaff")
    else
    	self.wilson2:GetAnimState():OverrideSymbol("swap_object", MAINSCREEN_TOOL_2, MAINSCREEN_TOOL_2)
    end
    self.wilson2:GetAnimState():Show("ARM_carry")
    self.wilson2:GetAnimState():Hide("ARM_normal")
    if MAINSCREEN_TORSO_2 ~= "" then
    	if MAINSCREEN_TORSO_2 == "torso_amulets" then
    		if math.random() <= .5 then
    			self.wilson2:GetAnimState():OverrideSymbol("swap_body", MAINSCREEN_TORSO_2, "purpleamulet")
    		else
    			self.wilson2:GetAnimState():OverrideSymbol("swap_body", MAINSCREEN_TORSO_2, "blueamulet")
    		end
    	else
    		self.wilson2:GetAnimState():OverrideSymbol("swap_body", MAINSCREEN_TORSO_2, "swap_body")
    	end
    end
    if MAINSCREEN_HAT_2 ~= "" then
    	self.wilson2:GetAnimState():OverrideSymbol("swap_hat", MAINSCREEN_HAT_2, "swap_hat")
        self.wilson2:GetAnimState():Show("HAT")
        self.wilson2:GetAnimState():Show("HAT_HAIR")
        self.wilson2:GetAnimState():Hide("HAIR_NOHAT")
        self.wilson2:GetAnimState():Hide("HAIR")
		self.wilson2:GetAnimState():Hide("HEAD")
		self.wilson2:GetAnimState():Show("HEAD_HAT")
    end
    self.wilson2:GetAnimState():PlayAnimation("idle", true)
    self.wilson2:SetPosition(char2_x,char2_y,0)
    self.wilson2.inst.UITransform:SetScale(-puppet_scale_2,puppet_scale_2,puppet_scale_2)

    self.countdown:Hide()
    self.wilson:Hide()
    self.wilson2:Hide()
    self.shadow1:Hide()
    self.shadow2:Hide()

    self.menu_bg = self.fixed_root:AddChild(TEMPLATES.LeftGradient())

    self.title = self.fixed_root:AddChild(Image("images/frontscreen.xml", "title.tex"))
    self.title:SetScale(.32)
    self.title:SetPosition(titleX, 165)
    self.title:SetTint(unpack(FRONTEND_TITLE_COLOUR))

    self.updatenameshadow = self.fixed_root:AddChild(Text(BUTTONFONT, 27))
    self.updatenameshadow:SetPosition(38,-(RESOLUTION_Y*.5)+52,0)
    self.updatenameshadow:SetColour(.1,.1,.1,1)

    self.updatename = self.fixed_root:AddChild(Text(BUTTONFONT, 27))
    self.updatename:SetPosition(36,-(RESOLUTION_Y*.5)+54,0)
    self.updatename:SetColour(1,1,1,1)
    local suffix = ""
    if BRANCH == "dev" then
		suffix = " (internal v"..APP_VERSION..")"
    elseif BRANCH == "staging" then
		suffix = " (preview v"..APP_VERSION..")"
    else
        suffix = " (v"..APP_VERSION..")"
    end
    self.updatename:SetString(STRINGS.UI.MAINSCREEN.DST_UPDATENAME .. suffix)
    self.updatenameshadow:SetString(STRINGS.UI.MAINSCREEN.DST_UPDATENAME .. suffix)
    if TheInput:ControllerAttached() then
        self.updatenameshadow:SetPosition(38,-(RESOLUTION_Y*.5)+54,0)
        self.updatename:SetPosition(36,-(RESOLUTION_Y*.5)+56,0)
    end

    self:MakeMainMenu()
	self:MakeSubMenu()

    self.onlinestatus = self.fg:AddChild(OnlineStatus())

	self:UpdateMOTD()
	--self:UpdateCountdown()
    --V2C: Show puppets because we're skipping UpdateCountdown
    self.wilson:Show()
    self.wilson2:Show()
    self.shadow1:Show()
    self.shadow2:Show()
    ----------------------------------------------------------

	self.filter_settings = nil

	--focus moving
    if self.debug_menu then 
        self.motd.button:SetFocusChangeDir(MOVE_LEFT, self.menu, -1)
        self.motd.button:SetFocusChangeDir(MOVE_DOWN, self.submenu)
        self.menu:SetFocusChangeDir(MOVE_RIGHT, self.motd.button)
        self.submenu:SetFocusChangeDir(MOVE_LEFT, self.menu, -1)
        self.submenu:SetFocusChangeDir(MOVE_UP, self.motd.button)

        self.debug_menu:SetFocusChangeDir(MOVE_DOWN, self.menu, -1)
        self.debug_menu:SetFocusChangeDir(MOVE_LEFT, self.menu, -1)
        self.menu:SetFocusChangeDir(MOVE_LEFT, self.debug_menu)
    else
    	self.motd.button:SetFocusChangeDir(MOVE_LEFT, self.menu, -1)
        self.motd.button:SetFocusChangeDir(MOVE_DOWN, self.submenu)
    	self.menu:SetFocusChangeDir(MOVE_RIGHT, self.motd.button)
    	self.submenu:SetFocusChangeDir(MOVE_LEFT, self.menu, -1)
        self.submenu:SetFocusChangeDir(MOVE_UP, self.motd.button)
    end

	self.menu:SetFocus(#self.menu.items)
end

function MultiplayerMainScreen:OnShow()
    self._base:OnShow()
    self.fg.character_root:SetCanFadeAlpha(false)
    self.fg.character_root:Show()
end

function MultiplayerMainScreen:OnHide()
    self._base:OnHide()
    self.fg.character_root:SetCanFadeAlpha(true)
    self.fg.character_root:Hide()
end

function MultiplayerMainScreen:TransferPortalOwnership(src, dest)
    --src and dest are Screens
    local bg_root = dest.portal_root or dest
    local fg_root = dest.portal_root or dest
    dest.bg = bg_root:AddChild(src.bg)
    dest.fg = fg_root:AddChild(src.fg)
end

function MultiplayerMainScreen:OnDestroy()
    self:OnHide()
    self.fg.character_root:KillAllChildren()
    self:TransferPortalOwnership(self, self.prev_screen)
    self._base.OnDestroy(self)
end

function MultiplayerMainScreen:OnRawKey(key, down)
end

function MultiplayerMainScreen:OnCreateServerButton()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
    self.menu:Disable()
    self.leaving = true
    TheFrontEnd:Fade(FADE_OUT, SCREEN_FADE_TIME, function()
        TheFrontEnd:PushScreen(ServerCreationScreen(self))
        TheFrontEnd:Fade(FADE_IN, SCREEN_FADE_TIME)
        self:Hide()
    end)
end

function MultiplayerMainScreen:OnGameWizardButton()
    -- needs implementation...
end

function MultiplayerMainScreen:OnSkinsButton()
	self.last_focus_widget = TheFrontEnd:GetFocusWidget()
    self.menu:Disable()
    self.leaving = true
    TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
        TheFrontEnd:PushScreen(SkinsScreen(Profile))
        TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
        self:Hide()
    end)
end

function MultiplayerMainScreen:OnBrowseServersButton()
    local function cb(filters)
	    self.filter_settings = filters
	    Profile:SaveFilters(self.filter_settings)
    end

	if not self.filter_settings then
		self.filter_settings = Profile:GetSavedFilters()
	end

    if self.filter_settings and #self.filter_settings > 0 then
        for i,v in pairs(self.filter_settings) do
			if v.name == "SHOWLAN" then
				v.data = self.offline
			end
		end
    else
        self.filter_settings = {}
        table.insert(self.filter_settings, {name = "SHOWLAN", data=self.offline} )   
    end
	
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
    self.menu:Disable()
    self.leaving = true
    TheFrontEnd:Fade(FADE_OUT, SCREEN_FADE_TIME, function()
        TheFrontEnd:PushScreen(ServerListingScreen(self, self.filter_settings, cb, self.offline, self.session_data))
        TheFrontEnd:Fade(FADE_IN, SCREEN_FADE_TIME)
        self:Hide()
    end)
end

-- MORGUE
function MultiplayerMainScreen:OnHistoryButton()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
	self.menu:Disable()
	TheFrontEnd:Fade(FADE_OUT, SCREEN_FADE_TIME, function()
		TheFrontEnd:PushScreen(MorgueScreen(self))
		TheFrontEnd:Fade(FADE_IN, SCREEN_FADE_TIME)
        self:Hide()
	end)
end

-- SUBSCREENS

function MultiplayerMainScreen:Settings()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
	self.menu:Disable()
	TheFrontEnd:Fade(FADE_OUT, SCREEN_FADE_TIME, function()
		TheFrontEnd:PushScreen(OptionsScreen(self))
		TheFrontEnd:Fade(FADE_IN, SCREEN_FADE_TIME)
        self:Hide()
	end)
end

function MultiplayerMainScreen:EmailSignup()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
	TheFrontEnd:PushScreen(EmailSignupScreen())
end

function MultiplayerMainScreen:Forums()
	VisitURL("http://forums.kleientertainment.com/forum/73-dont-starve-together-beta/")
end
 
function MultiplayerMainScreen:Quit()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
	TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MAINSCREEN.ASKQUIT, STRINGS.UI.MAINSCREEN.ASKQUITDESC, {{text=STRINGS.UI.MAINSCREEN.YES, cb = function() RequestShutdown() end },{text=STRINGS.UI.MAINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  }))
end

function MultiplayerMainScreen:OnModsButton()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
	self.menu:Disable()
    if self.debug_menu then self.debug_menu:Disable() end
	TheFrontEnd:Fade(FADE_OUT, SCREEN_FADE_TIME, function()
		TheFrontEnd:PushScreen(ModsScreen(self))
		TheFrontEnd:Fade(FADE_IN, SCREEN_FADE_TIME)
        self:Hide()
	end)
end

function MultiplayerMainScreen:ResetProfile()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
	TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MAINSCREEN.RESETPROFILE, STRINGS.UI.MAINSCREEN.SURE, {{text=STRINGS.UI.MAINSCREEN.YES, cb = function() self.profile:Reset() TheFrontEnd:PopScreen() end},{text=STRINGS.UI.MAINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  }))
end

function MultiplayerMainScreen:UnlockEverything()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
	TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MAINSCREEN.UNLOCKEVERYTHING, STRINGS.UI.MAINSCREEN.SURE, {{text=STRINGS.UI.MAINSCREEN.YES, cb = function() self.profile:UnlockEverything() TheFrontEnd:PopScreen() end},{text=STRINGS.UI.MAINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  }))
end

function MultiplayerMainScreen:OnCreditsButton()
    self.last_focus_widget = TheFrontEnd:GetFocusWidget()
	TheFrontEnd:GetSound():KillSound("FEMusic")
	self.menu:Disable()
    if self.debug_menu then self.debug_menu:Disable() end
	TheFrontEnd:Fade(FADE_OUT, SCREEN_FADE_TIME, function()
		TheFrontEnd:PushScreen(CreditsScreen())
		TheFrontEnd:Fade(FADE_IN, SCREEN_FADE_TIME)
        self:Hide()
	end)
end

function MultiplayerMainScreen:OnHostButton()
	SaveGameIndex:LoadServerEnabledModsFromSlot()
	KnownModIndex:Save()
	local start_in_online_mode = false
	local server_started = TheNet:StartServer(start_in_online_mode)
	if server_started == true then
        DisableAllDLC()
		StartNextInstance({reset_action = RESET_ACTION.LOAD_SLOT, save_slot=SaveGameIndex:GetCurrentSaveSlot()})
	end
end

function MultiplayerMainScreen:OnJoinButton()
	local start_worked = TheNet:StartClient(DEFAULT_JOIN_IP)
	if start_worked then
        DisableAllDLC()
	end
	ShowLoading()
end

function MultiplayerMainScreen:MakeMainMenu()
	local menu_items = {}

    local function MakeMainMenuButton(text, onclick, tooltip)
        local btn = Button()
        btn:SetFont(BUTTONFONT)
        btn:SetDisabledFont(BUTTONFONT)
        btn:SetTextColour(unpack(GOLD))
        btn:SetTextFocusColour(1, 1, 1, 1)
        btn:SetText(text, true)
        btn.text:SetRegionSize(180,40)
        btn.text:SetHAlign(ANCHOR_LEFT)
        btn.text_shadow:SetRegionSize(180,40)
        btn.text_shadow:SetHAlign(ANCHOR_LEFT)
        btn:SetTextSize(35)
        
        btn.image = btn:AddChild(Image("images/frontscreen.xml", "highlight_hover.tex"))
        btn.image:MoveToBack()
        btn.image:SetScale(.6)
        btn.image:SetPosition(-20,3)
        btn.image:SetClickable(false)
        btn.image:Hide()

        btn.bg = btn:AddChild(Image("images/ui.xml", "blank.tex"))
        local w,h = btn.text:GetRegionSize()
        btn.bg:ScaleToSize(200, h+15)

        btn.OnGainFocus = function()
            if btn.text then btn.text:SetColour(btn.textfocuscolour[1],btn.textfocuscolour[2],btn.textfocuscolour[3],btn.textfocuscolour[4]) end
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            btn.image:Show()
            self.tooltip:SetString(tooltip)
            self.tooltip_shadow:SetString(tooltip)
        end
        
        btn.OnLoseFocus = function()
            if btn:IsEnabled() and not btn.selected then
                btn.text:SetColour(btn.textcolour)
            end
            if btn.o_pos then
                btn:SetPosition(btn.o_pos)
            end
            btn.down = false

            btn.image:Hide()
            if not self.menu.focus then
                self.tooltip:SetString("")
                self.tooltip_shadow:SetString("")
            end
        end
        btn:SetOnClick(onclick)
        -- btn:SetScale(.75)

        return btn
    end
	
    local browse_button = MakeMainMenuButton(STRINGS.UI.MAINSCREEN.BROWSE, function() self:OnBrowseServersButton() end, STRINGS.UI.MAINSCREEN.TOOLTIP_BROWSE)
    local host_button = MakeMainMenuButton(STRINGS.UI.MAINSCREEN.CREATE, function() self:OnCreateServerButton() end, STRINGS.UI.MAINSCREEN.TOOLTIP_HOST)
    --local wizard_button = MakeMainMenuButton(STRINGS.UI.MAINSCREEN.GAMEWIZARD, function() self:OnGameWizardButton() end, STRINGS.UI.MAINSCREEN.TOOLTIP_WIZARD)
    local skins_button = MakeMainMenuButton(STRINGS.UI.MAINSCREEN.SKINS, function() self:OnSkinsButton() end, STRINGS.UI.MAINSCREEN.TOOLTIP_SKINS)
    local history_button = MakeMainMenuButton(STRINGS.UI.MORGUESCREEN.HISTORY, function() self:OnHistoryButton() end, STRINGS.UI.MAINSCREEN.TOOLTIP_HISTORY)
    local options_button = MakeMainMenuButton(STRINGS.UI.MAINSCREEN.OPTIONS, function() self:Settings() end, STRINGS.UI.MAINSCREEN.TOOLTIP_OPTIONS)
    local quit_button = MakeMainMenuButton(STRINGS.UI.MAINSCREEN.QUIT, function() self:Quit() end, STRINGS.UI.MAINSCREEN.TOOLTIP_QUIT)

    if MODS_ENABLED then
        local mods_button = MakeMainMenuButton(STRINGS.UI.MAINSCREEN.MODS, function() self:OnModsButton() end, STRINGS.UI.MAINSCREEN.TOOLTIP_MODS)
        menu_items = {
            {widget = quit_button},
            {widget = mods_button},
            {widget = history_button},
            {widget = options_button},
            --{widget = wizard_button},   
            {widget = skins_button},        
            {widget = host_button},
            {widget = browse_button},
        }
    else
        menu_items = {
            {widget = quit_button},
            {widget = history_button},
            {widget = options_button},
            --{widget = wizard_button},
            {widget = skins_button},
            {widget = host_button},
            {widget = browse_button},
        }
    end

    --if PLATFORM == "WIN32_STEAM" or PLATFORM == "WIN32" then
    --  table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.BROADCASTING, cb= function() self:BroadcastingMenu() end})
    --end
    self.menu = self.fixed_root:AddChild(Menu(menu_items, 43, nil, nil, true))
    self.menu:SetPosition(menuX, menuY)

    self.tooltip_shadow = self.fixed_root:AddChild(Text(NEWFONT, 30))
    self.tooltip = self.fixed_root:AddChild(Text(NEWFONT, 30))
    self.tooltip_shadow:SetHAlign(ANCHOR_LEFT)
    self.tooltip_shadow:SetRegionSize(800,45)
    self.tooltip:SetHAlign(ANCHOR_LEFT)
    self.tooltip:SetRegionSize(800,45)
    self.tooltip_shadow:SetColour(.1,.1,.1,1)
    local tooltipX = menuX+310
    self.tooltip:SetPosition(tooltipX, -(RESOLUTION_Y*.5)+57, 0)
    self.tooltip_shadow:SetPosition(tooltipX+2, -(RESOLUTION_Y * .5) + 57-2, 0)

    -- For Debugging/Testing
    local debug_menu_items = {}

    if SHOW_DEBUG_UNLOCK_RESET then
        table.insert( debug_menu_items, {text=STRINGS.UI.MAINSCREEN.RESETPROFILE, cb= function() self:ResetProfile() end})
        table.insert( debug_menu_items, {text=STRINGS.UI.MAINSCREEN.UNLOCKEVERYTHING, cb= function() self:UnlockEverything() end})
    end

    if SHOW_DST_DEBUG_HOST_JOIN then
        table.insert( debug_menu_items, {text=STRINGS.UI.MAINSCREEN.JOIN, cb= function() self:OnJoinButton() end})
        table.insert( debug_menu_items, {text=STRINGS.UI.MAINSCREEN.HOST, cb= function() self:OnHostButton() end})
    end

    if #debug_menu_items > 0 then
        self.debug_menu = self.fixed_root:AddChild(Menu(debug_menu_items, 74))
        self.debug_menu:SetPosition(menuX+230, 120, 0)
        self.debug_menu:SetScale(.8)
        self.debug_menu.reverse = true
    end
end

function MultiplayerMainScreen:MakeSubMenu()
    local submenuitems = {}

    local function MakeSubMenuButton(name, text, onclick)
        local btn = ImageButton("images/frontscreen.xml", name..".tex", nil, nil, nil, nil, {1,1}, {0,0})
        btn.image:SetPosition(0, 70)
        btn:SetTextColour(unpack(GOLD))
        btn:SetTextFocusColour(unpack(GOLD))
        btn:SetFocusScale(1.05, 1.05, 1.05)
        btn:SetNormalScale(1, 1, 1)
        btn:SetText(text)
        btn.bg = btn:AddChild(Image("images/ui.xml", "blank.tex"))
        local w,h = btn.text:GetRegionSize()
        btn.bg:ScaleToSize(w+15, h+15)
        local gainfocusfn = btn.OnGainFocus
        local losefocusfn = btn.OnLoseFocus
        btn.OnGainFocus = function()
            gainfocusfn(btn)
            btn:SetTextSize(43)
        end
        btn.OnLoseFocus = function()
            losefocusfn(btn)
            btn:SetTextSize(40)
        end
        btn:SetOnClick(onclick)
        btn:SetScale(.75)

        return btn
    end

    local credits_button = TEMPLATES.IconButton("images/button_icons.xml", "credits.tex", STRINGS.UI.MAINSCREEN.CREDITS, false, true, function() self:OnCreditsButton() end, {font=NEWFONT_OUTLINE, focus_colour={1,1,1,1}})
    local forums_button = TEMPLATES.IconButton("images/button_icons.xml", "forums.tex", STRINGS.UI.MAINSCREEN.FORUM, false, true, function() self:Forums() end, {font=NEWFONT_OUTLINE, focus_colour={1,1,1,1}})
    local newsletter_button = TEMPLATES.IconButton("images/button_icons.xml", "newsletter.tex", STRINGS.UI.MAINSCREEN.NOTIFY, false, true, function() self:EmailSignup() end, {font=NEWFONT_OUTLINE, focus_colour={1,1,1,1}})

    if PLATFORM == "WIN32_STEAM" or PLATFORM == "LINUX_STEAM" or PLATFORM == "OSX_STEAM" then

        local more_games_button = TEMPLATES.IconButton("images/button_icons.xml", "more_games.tex", STRINGS.UI.MAINSCREEN.MOREGAMES, false, true, function() VisitURL("http://store.steampowered.com/search/?developer=Klei%20Entertainment") end, {font=NEWFONT_OUTLINE, focus_colour={1,1,1,1}})

        if TheFrontEnd:GetAccountManager():HasSteamTicket() then

            local manage_account_button = TEMPLATES.IconButton("images/button_icons.xml", "profile.tex", STRINGS.UI.SERVERCREATIONSCREEN.MANAGE_ACCOUNT, false, true, function() VisitURL(TheFrontEnd:GetAccountManager():GetViewAccountURL(), true ) end, {font=NEWFONT_OUTLINE, focus_colour={1,1,1,1}})

            submenuitems = 
            {
                {widget = manage_account_button},
                {widget = credits_button},
                {widget = forums_button},
                {widget = more_games_button},
                {widget = newsletter_button},
            }
        else
            submenuitems = 
            {
                {widget = credits_button},
                {widget = forums_button},
                {widget = more_games_button},
                {widget = newsletter_button},
            }
        end
    else
        submenuitems = 
            {
                {widget = credits_button},
                {widget = forums_button},
                {widget = newsletter_button},
            }
    end

    self.submenu = self.fixed_root:AddChild(Menu(submenuitems, 90, true))
    if TheInput:ControllerAttached() then
        self.submenu:SetPosition((RESOLUTION_X*.5)-(75*#submenuitems), -(RESOLUTION_Y*.5)+80, 0)
    else
        self.submenu:SetPosition((RESOLUTION_X*.5)-(75*#submenuitems), -(RESOLUTION_Y*.5)+77, 0)
    end
    self.submenu:SetScale(.8)
end

function MultiplayerMainScreen:OnBecomeActive()
    MultiplayerMainScreen._base.OnBecomeActive(self)

    self:Show()

	self.menu:Enable()
    local found = false
    for i,v in pairs(self.menu.items) do
        if v ~= self.last_focus_widget then
            v:OnLoseFocus()
        else
            found = true
            v:SetFocus()
        end
    end

    if not found then
	   self.menu:SetFocus(#self.menu.items)
    end

    if self.debug_menu then self.debug_menu:Enable() end

    self.leaving = nil

    --start a new query everytime we go back to the mainmenu
	if TheSim:IsLoggedOn() then
		TheSim:StartWorkshopQuery()
	end

	--Do language mods assistance popup
	--[[
	local interface_lang = TheNet:GetLanguageCode()
	if interface_lang ~= "english" then
		if Profile:GetValue("language_mod_asked_"..interface_lang) ~= true then
			TheSim:QueryServer( "https://s3.amazonaws.com/ds-mod-language/dst_mod_languages.json",
			function( result, isSuccessful, resultCode )
 				if isSuccessful and string.len(result) > 1 and resultCode == 200 then
 					local status, language_mods = pcall( function() return json.decode(result) end )
					local lang_popup = language_mods[interface_lang]
					if status and lang_popup ~= nil then
						if lang_popup.collection ~= "" then
							TheFrontEnd:PushScreen(
								PopupDialogScreen( lang_popup.title, lang_popup.body,
									{
										{text=lang_popup.yes, cb = function() VisitURL("http://steamcommunity.com/workshop/filedetails/?id="..lang_popup.collection) TheFrontEnd:PopScreen() self:OnModsButton() end },
										{text=lang_popup.no, cb = function() TheFrontEnd:PopScreen() end}
									}
								)
							)
							Profile:SetValue("language_mod_asked_"..interface_lang, true)
							Profile:Save()
						end
					end
				end
			end, "GET" )
		end
	end
	]]
end

local anims =
{
	scratch = .5,
	hungry = .5,
	eat = .5,
	eatquick = .33,
	wave1 = .1,
	wave2 = .1,
	wave3 = .1,
	happycheer = .1,
	sad = .1,
	angry = .1,
	annoyed = .1,
	facepalm = .1
}

function MultiplayerMainScreen:OnUpdate(dt)
	self.timetonewanim = self.timetonewanim and self.timetonewanim - dt or 5 +math.random()*5
	self.timetonewanim2 = self.timetonewanim2 and self.timetonewanim2 - dt or 5 +math.random()*5
	if self.timetonewanim < 0 and self.wilson then
		self.wilson:GetAnimState():PushAnimation(weighted_random_choice(anims))		
		self.wilson:GetAnimState():PushAnimation("idle", true)		
		self.timetonewanim = 10 + math.random()*15
	end
	if self.timetonewanim2 < 0 and self.wilson2 then
		self.wilson2:GetAnimState():PushAnimation(weighted_random_choice(anims))		
		self.wilson2:GetAnimState():PushAnimation("idle", true)		
		self.timetonewanim2 = 10 + math.random()*15
	end

	if self.bg.anim_root.portal:GetAnimState():AnimDone() and not self.leaving then 
    	if math.random() < .33 then 
			self.bg.anim_root.portal:GetAnimState():PlayAnimation("portal_idle_eyescratch", false) 
    	else
    		self.bg.anim_root.portal:GetAnimState():PlayAnimation("portal_idle", false)
    	end
    end
end

function MultiplayerMainScreen:OnGetMOTDImageQueryComplete( is_successful )
	if is_successful then
		self.motd.motdimage:SetTextures( "images/motd.xml", "motd.tex", "motd.tex", "motd.tex", "motd.tex", "motd.tex" )
		self.motd.motdimage:Show()
	end	
end

function MultiplayerMainScreen:SetMOTD(str, cache)
	--print("MultiplayerMainScreen:SetMOTD", str, cache)

	local status, motd = pcall( function() return json.decode(str) end )
	--print("decode:", status, motd)
	if status and motd then
	    if cache then
	 		SavePersistentString("motd_image", str)
	    end

		local platform_motd = motd.dststeam
		--Uncomment these to test Image MOTD
		
		--print("platform_motd")
		--dumptable(platform_motd)
		
		if platform_motd then
		    self.motd:Show()
		    if platform_motd.motd_title and string.len(platform_motd.motd_title) > 0 and
			    	platform_motd.motd_body and string.len(platform_motd.motd_body) > 0 then
			    
			    self.motdbg.fill:Show()
			    self.motd.motdtitle:Show()
				self.motd.motdtitle:SetString(platform_motd.motd_title)
				self.motd.motdtext:Show()
				self.motd.motdtext:SetString(platform_motd.motd_body)
				self.motd.motdimage:Hide()

			    if platform_motd.link_title and string.len(platform_motd.link_title) > 0 and
				    	platform_motd.link_url and string.len(platform_motd.link_url) > 0 then
				    self.motd.button:SetText(platform_motd.link_title)
				    self.motd.button:SetOnClick( function() VisitURL(platform_motd.link_url) end )
				else
					self.motd.button:Hide()
				end
		    elseif platform_motd.image_url and string.len(platform_motd.image_url) > 0 then

			    self.motdbg.fill:Hide()
				self.motd.motdtitle:Hide()
				self.motd.motdtext:Hide()
				
				local use_disk_file = not cache
				if use_disk_file then
					self.motd.motdimage:Hide()
				end
				
				if platform_motd.link_title and string.len(platform_motd.link_title) > 0 and
				    	platform_motd.link_url and string.len(platform_motd.link_url) > 0 then
				    self.motd.button:SetText(platform_motd.link_title)
				    self.motd.button:SetOnClick( function() VisitURL(platform_motd.link_url) end )
				else
					self.motd.button:Hide()
				end
				
				TheSim:GetMOTDImage( platform_motd.image_url, use_disk_file, platform_motd.image_version or "", function(...) self:OnGetMOTDImageQueryComplete(...) end )
		    else
				self.motd:Hide()
		    end
	    else
			self.motd:Hide()
		end
	end
end

function MultiplayerMainScreen:OnMOTDQueryComplete( result, isSuccessful, resultCode )
	--print( "MultiplayerMainScreen:OnMOTDQueryComplete", result, isSuccessful, resultCode )
 	if isSuccessful and string.len(result) > 1 and resultCode == 200 then 
 		self:SetMOTD(result, true)
	end
end

function MultiplayerMainScreen:OnCachedMOTDLoad(load_success, str)
	--print("MultiplayerMainScreen:OnCachedMOTDLoad", load_success, str)
	if load_success and string.len(str) > 1 then
		self:SetMOTD(str, false)
	end
	TheSim:QueryServer( "https://d21wmy1ql1e52r.cloudfront.net/ds_image_motd.json", function(...) self:OnMOTDQueryComplete(...) end, "GET" )
	--TheSim:QueryServer( "https://s3-us-west-2.amazonaws.com/kleifiles/external/ds_image_motd.json", function(...) self:OnMOTDQueryComplete(...) end, "GET" )
end

function MultiplayerMainScreen:UpdateMOTD()
	TheSim:GetPersistentString("motd_image", function(...) self:OnCachedMOTDLoad(...) end)
end

function MultiplayerMainScreen:SetCountdown(str, cache)
	local status, ud = pcall( function() return json.decode(str) end )
	--print("decode:", status, ud)
	if status and ud then
	    if cache then
	 		SavePersistentString("updatecountdown", str)
	    end

	    local update_date = nil
		if PLATFORM == "WIN32_STEAM" or PLATFORM == "LINUX_STEAM" or PLATFORM == "OSX_STEAM" then
			if IsDLCInstalled(REIGN_OF_GIANTS) then
				update_date = {year = ud.rogsteam.update_year, day = ud.rogsteam.update_day, month = ud.rogsteam.update_month, hour = 13}
			else
				update_date = {year = ud.steam.update_year, day = ud.steam.update_day, month = ud.steam.update_month, hour = 13}
			end
		else
			if IsDLCInstalled(REIGN_OF_GIANTS) then
				update_date = {year = ud.rogstandalone.update_year, day = ud.rogstandalone.update_day, month = ud.rogstandalone.update_month, hour = 13}
			else
				update_date = {year = ud.standalone.update_year, day = ud.standalone.update_day, month = ud.standalone.update_month, hour = 13}
			end
		end

		if update_date and self.countdown:ShouldShowCountdown(update_date) then
		    self.countdown:Show()
		    self.wilson:Hide()
		    self.wilson2:Hide()
            self.shadow1:Hide()
            self.shadow2:Hide()
	    else
			self.countdown:Hide()
		    self.wilson:Show()
		    self.wilson2:Show()
            self.shadow1:Show()
            self.shadow2:Show()
		end
	end	
end

function MultiplayerMainScreen:OnCountdownQueryComplete( result, isSuccessful, resultCode )
	--print( "MultiplayerMainScreen:OnMOTDQueryComplete", result, isSuccessful, resultCode )
 	if isSuccessful and string.len(result) > 1 and resultCode == 200 then 
 		self:SetCountdown(result, true)
	end
end

function MultiplayerMainScreen:OnCachedCountdownLoad(load_success, str)
	--print("MultiplayerMainScreen:OnCachedMOTDLoad", load_success, str)
	if load_success and string.len(str) > 1 then
		self:SetCountdown(str, false)
	end
	TheSim:QueryServer( "https://s3-us-west-2.amazonaws.com/kleifiles/external/ds_update.json", function(...) self:OnCountdownQueryComplete(...) end, "GET" )
end

function MultiplayerMainScreen:UpdateCountdown()
	--print("MultiplayerMainScreen:UpdateMOTD()")
	TheSim:GetPersistentString("updatecountdown", function(...) self:OnCachedCountdownLoad(...) end)
end

return MultiplayerMainScreen
