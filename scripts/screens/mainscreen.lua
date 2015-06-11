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
local BigPopupDialogScreen = require "screens/bigpopupdialog"
local MovieDialog = require "screens/moviedialog"
local Countdown = require "widgets/countdown"

local ControlsScreen = require "screens/controlsscreen"
local OptionsScreen = require "screens/optionsscreen"
local ServerListingScreen = require "screens/serverlistingscreen"
local MorgueScreen = require "screens/morguescreen"
local RoGUpgrade = require "widgets/rogupgrade"

local NoAuthenticationPopupDialogScreen = require "screens/noauthenticationpopupdialogscreen"
local NetworkLoginPopup = require "screens/networkloginpopup"

--local OnlineStatus = require "widgets/onlinestatus"
local GameVersion = require "widgets/gameversion"

local rcol = RESOLUTION_X/2 -200
local lcol = -RESOLUTION_X/2 +200

local bottom_offset = 60

local menuX = rcol-30
local menuY = -40

local screen_fade_time = .25

SHOW_DST_DEBUG_HOST_JOIN = false
if BRANCH == "dev" then
	SHOW_DST_DEBUG_HOST_JOIN = true
end

local MainScreen = Class(Screen, function(self, profile)
	Screen._ctor(self, "MainScreen")
    self.profile = profile
	self.log = true
	self:AddEventHandler("onsetplayerid", function(...) self:OnSetPlayerID(...) end)
	self:DoInit() 
	self.menu.reverse = true
	self.default_focus = self.menu
    self.music_playing = false
end)


function MainScreen:DoInit( )
	STATS_ENABLE = true
	TheFrontEnd:GetGraphicsOptions():DisableStencil()
	TheFrontEnd:GetGraphicsOptions():DisableLightMapComponent()
	
	TheInputProxy:SetCursorVisible(true)

	if PLATFORM == "NACL" then	
		TheSim:RequestPlayerID()
	end

	-- Make sure that DLC starts as on every time
	EnableAllMenuDLC()

	local r = math.random()
    if r < .25 then
        self.bg = self:AddChild(Image("images/bg_rog_logo_1.xml", "bg.tex"))
    elseif r < .5 then
        self.bg = self:AddChild(Image("images/bg_rog_logo_2.xml", "bg.tex"))
    elseif r < .75 then
        self.bg = self:AddChild(Image("images/bg_rog_logo_3.xml", "bg.tex"))
    else
        self.bg = self:AddChild(Image("images/bg_rog_logo_4.xml", "bg.tex"))
    end
	-- TintBackground(self.bg)
    self.bg:SetTint(.85,.85,.85,1)

    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
    
    self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    if not IsDLCInstalled(REIGN_OF_GIANTS) and (TheSim:GetSteamAppID() == DONT_STARVE_APPID or PLATFORM == "PS4") then
	 	self.RoGUpgrade = self.fixed_root:AddChild(RoGUpgrade())
	    self.RoGUpgrade:SetScale(.9)
	    self.RoGUpgrade:SetPosition(-435, -185, 0)
	end

	--RIGHT COLUMN

    self.right_col = self.fixed_root:AddChild(Widget("right"))
	self.right_col:SetPosition(rcol, 0)
	
	--LEFT COLUMN
    
    self.left_col = self.fixed_root:AddChild(Widget("left"))
	self.left_col:SetPosition(lcol, 0)

	self.motd = self.left_col:AddChild(Widget("motd"))
	self.motd:SetScale(.9,.9,.9)
	self.motd:SetPosition(20, RESOLUTION_Y/2-320, 0)
	--self.motd:Hide()
	self.motdbg = self.motd:AddChild( Image( "images/fepanels_dst.xml", "motd_panel.tex" ) )
	-- self.motdbg:SetScale(.75*.9,.75,.75)
	self.motd.motdtitle = self.motdbg:AddChild(Text(UIFONT, 43))
    self.motd.motdtitle:SetPosition(0, 150, 0)
	self.motd.motdtitle:SetRegionSize( 350, 60)
	self.motd.motdtitle:SetString(STRINGS.UI.MAINSCREEN.MOTDTITLE)

	self.motd.motdtext = self.motd:AddChild(Text(UIFONT, 32))
    self.motd.motdtext:SetHAlign(ANCHOR_MIDDLE)
    self.motd.motdtext:SetVAlign(ANCHOR_MIDDLE)
    self.motd.motdtext:SetPosition(0, 40, 0)
	self.motd.motdtext:SetRegionSize( 250, 160)
	self.motd.motdtext:SetString(STRINGS.UI.MAINSCREEN.MOTD)
	
	self.fixed_root:AddChild(Widget("left"))
	self.left_col:SetPosition(lcol, 0) 
    
	self.countdown = self.fixed_root:AddChild(Countdown())
    self.countdown:SetScale(1)
    self.countdown:SetPosition(-575, -330, 0)

    local puppet_scale = .6
    self.wilson = self.left_col:AddChild(UIAnim())
    self.wilson:GetAnimState():SetBank("corner_dude")
    self.wilson:GetAnimState():SetBuild(MAINSCREEN_CHAR_1)
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
    self.wilson:GetAnimState():SetPercent("idle", 0)
    self.inst:DoTaskInTime(math.random()*1.5, function() self.wilson:GetAnimState():PlayAnimation("idle", true) end)
    self.wilson:SetPosition(-20,-330,0)
    self.wilson.inst.UITransform:SetScale(puppet_scale-.12,puppet_scale-.12,puppet_scale-.12)

	self.wilson2 = self.left_col:AddChild(UIAnim())
    self.wilson2:GetAnimState():SetBank("corner_dude")
    self.wilson2:GetAnimState():SetBuild(MAINSCREEN_CHAR_2)
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
    self.wilson2:SetPosition(100,-350,0)
    self.wilson2.inst.UITransform:SetScale(puppet_scale,puppet_scale,puppet_scale)

    self.countdown:Hide()
    self.wilson:Hide()
    self.wilson2:Hide()

    self.fg = self.fixed_root:AddChild(Image("images/fg_trees.xml", "trees.tex"))
	self.fg:SetVRegPoint(ANCHOR_MIDDLE)
    self.fg:SetHRegPoint(ANCHOR_MIDDLE)
    self.fg:SetVAnchor(ANCHOR_MIDDLE)
    self.fg:SetHAnchor(ANCHOR_MIDDLE)
    self.fg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.updatenameshadow = self.fg:AddChild(Text(BUTTONFONT, 37))
    self.updatenameshadow:SetVAnchor(ANCHOR_BOTTOM)
    self.updatenameshadow:SetHAnchor(ANCHOR_MIDDLE)
    self.updatenameshadow:SetPosition(38,55,0)
    self.updatenameshadow:SetColour(.1,.1,.1,1)

    self.updatename = self.fg:AddChild(Text(BUTTONFONT, 37))
    self.updatename:SetVAnchor(ANCHOR_BOTTOM)
    self.updatename:SetHAnchor(ANCHOR_MIDDLE)
    self.updatename:SetPosition(35,58,0)
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

    self.motd.button = self.fixed_root:AddChild(ImageButton())
	self.motd.button:SetPosition(lcol+20,RESOLUTION_Y/2-320-60)
    self.motd.button:SetScale(.8*.9)
    self.motd.button:SetText(STRINGS.UI.MAINSCREEN.MOTDBUTTON)
    self.motd.button:SetOnClick( function() VisitURL("http://forums.kleientertainment.com/index.php?/topic/28171-halloween-mod-challenge/") end )
	self.motd.motdtext:EnableWordWrap(true)  

    self.menu = self.fixed_root:AddChild(Menu(nil, 74))
	self.menu:SetPosition(menuX, menuY, 0)
	self.menu:SetScale(.8)

	local submenuitems = 
	{
		{text = STRINGS.UI.MAINSCREEN.NOTIFY, cb = function() self:EmailSignup() end},
		{text=STRINGS.UI.MAINSCREEN.FORUM, cb= function() self:Forums() end}
	}
	self.submenu = self.fixed_root:AddChild(Menu(submenuitems, 70))
	self.submenu:SetPosition(menuX, menuY-210, 0)
	self.submenu:SetScale(.6)

	local function KickOffScreecherMod()
		KnownModIndex:Enable("screecher")
		KnownModIndex:Save()
		TheSim:Quit()
	end

	local PopupDialogScreen = require("screens/popupdialog")
	local ImageButton = require("widgets/imagebutton")
	-- self.promo = self.left_col:AddChild(ImageButton("images/fepanels.xml", "kickstarter_menu_button.tex", "kickstarter_menu_mouseover.tex"))
	-- self.promo:Hide()
	-- self.promo:SetPosition(-15, 165, 0)
	-- local scale = 1.0
	-- self.promo:SetScale(scale, scale, scale)
	-- --
	-- self.promo:SetOnClick( function() 
	-- 	VisitURL("http://www.kickstarter.com/projects/731983185/dont-starve-chester-plush")
	-- end)

	if PLATFORM == "NACL" then

		self.playerid = self.fixed_root:AddChild(Text(NUMBERFONT, 35))
		self.playerid:SetPosition(RESOLUTION_X/2 -400, RESOLUTION_Y/2 -60, 0)    
		self.playerid:SetRegionSize( 600, 50)
		self.playerid:SetHAlign(ANCHOR_RIGHT)

		
		self.purchasebutton = self.right_col:AddChild(ImageButton("images/ui.xml", "special_button.tex", "special_button_over.tex"))
		self.purchasebutton:SetScale(.5,.5,.5)
		self.purchasebutton:SetPosition(0,200,0)
		self.purchasebutton:SetFont(BUTTONFONT)
		self.purchasebutton:SetTextSize(80)

		if not IsGamePurchased() then
			self.purchasebutton:SetOnClick( function() self:Buy() end)
			self.purchasebutton:SetText( STRINGS.UI.MAINSCREEN.BUYNOW )
		else
			self.purchasebutton:SetOnClick( function() self:SendGift() end)
			self.purchasebutton:SetText( STRINGS.UI.MAINSCREEN.GIFT )
		end	
	end
--[[
    self.onlinestatus = self.fg:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)    
]]

    self.gameversion = self.fg:AddChild(GameVersion())
    self.gameversion:SetHAnchor(ANCHOR_MIDDLE)
    self.gameversion:SetVAnchor(ANCHOR_BOTTOM)
    self.gameversion:SetPosition( 35, 18, 0 )

	if PLATFORM ~= "NACL" then
		self:UpdateMOTD()
		self:UpdateCurrentVersion()
		self:UpdateCountdown()
	end

	self.filter_settings = nil

	--focus moving
	self.motd.button:SetFocusChangeDir(MOVE_RIGHT, self.menu)
	self.menu:SetFocusChangeDir(MOVE_LEFT, self.motd.button)
	self.submenu:SetFocusChangeDir(MOVE_LEFT, self.motd.button)

	self.menu:SetFocusChangeDir(MOVE_DOWN, self.submenu, -1)
	self.submenu:SetFocusChangeDir(MOVE_UP, self.menu, 1)
	
	KnownModIndex:ClearAllTempModFlags() --clear all old temp mod flags when the game starts incase someone killed the process before disconnecting
	
	self:MainMenu()
	self.menu:SetFocus()
end

function MainScreen:OnSetPlayerID(playerid)
	if self.playerid then
		self.playerid:SetString(STRINGS.UI.MAINSCREEN.GREETING.. " "..playerid)
	end
end

function MainScreen:OnControl(control, down)
	if MainScreen._base.OnControl(self, control, down) then return true end
	
	if not down and control == CONTROL_CANCEL then
		if not self.mainmenu then
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			self:MainMenu()
			return true
		end
	end
end

function MainScreen:OnRawKey( key, down )
end

-- NACL MENU OPTIONS
function MainScreen:Buy()
	TheSim:SendJSMessage("MainScreen:Buy")
	TheFrontEnd:GetSound():KillSound("FEMusic")
end

function MainScreen:EnterKey()
	TheSim:SendJSMessage("MainScreen:EnterKey")
end

function MainScreen:SendGift()
	TheSim:SendJSMessage("MainScreen:Gift")
	TheFrontEnd:GetSound():KillSound("FEMusic")
end

function MainScreen:ProductKeys()
	TheSim:SendJSMessage("MainScreen:ProductKeys")
end

function MainScreen:Rate()
	TheSim:SendJSMessage("MainScreen:Rate")
end

function MainScreen:Logout()
	TheSim:SendJSMessage("MainScreen:Logout")
end

-- MULTIPLAYER PLAY
function MainScreen:OnPlayMultiplayerButton( push_listings_screen )	

    local account_manager = TheFrontEnd:GetAccountManager()
	
    local function cb(filters, customoptions, slotdata)
	    self.filter_settings = filters
	    Profile:SaveFilters(self.filter_settings)
	    self.customoptions = customoptions
	    self.slotdata = slotdata
    end
	
    local function GoToServerListingScreen( show_lan )
    	if not self.filter_settings then
    		self.filter_settings = Profile:GetSavedFilters()
    	end

        if self.filter_settings and #self.filter_settings > 0 then
            for i,v in pairs(self.filter_settings) do
				if v.name == "SHOWLAN" then
					v.data = show_lan
				end
			end
        else
            self.filter_settings = {}
            table.insert(self.filter_settings, {name = "SHOWLAN", data=show_lan} )   
        end
		
		TheFrontEnd:SetOfflineMode(show_lan)
		if push_listings_screen then
            local function session_mapping_cb(data)
                TheFrontEnd:PushScreen(ServerListingScreen(self.filter_settings, cb, self.customoptions, self.slotdata, show_lan, data))
                TheFrontEnd:Fade(true, screen_fade_time * 1.5)
            end
            if not TheNet:DeserializeAllLocalUserSessions(session_mapping_cb) then
                session_mapping_cb()
            end
        else
            TheFrontEnd:Fade(true, screen_fade_time * 1.5)
		end
    end
    	
    local function onCancel()
        self.menu:Enable()
    end
    	
    local function onLogin(forceOffline)
	    local account_manager = TheFrontEnd:GetAccountManager()
	    local is_banned = (account_manager:IsBanned() == true)
	    local failed_email = account_manager:MustValidateEmail()
	    local must_upgrade = account_manager:MustUpgradeClient()
	    local communication_succeeded = account_manager:CommunicationSucceeded()
        if is_banned then -- We are banned
        	TheFrontEnd:PopScreen()
	        TheNet:NotifyAuthenticationFailure()
            OnNetworkDisconnect( "E_BANNED", true)
        -- We are on a deprecated version of the game
        elseif must_upgrade then
        	TheFrontEnd:PopScreen()
        	TheNet:NotifyAuthenticationFailure()
        	OnNetworkDisconnect( "E_UPGRADE", true)
        elseif ( account_manager:HasAuthToken() and communication_succeeded ) or forceOffline then
        	if not push_listings_screen then 
        		TheFrontEnd:PopScreen()
        	end
			
        	TheFrontEnd:Fade(false, screen_fade_time*1.5, function()
		    	if push_listings_screen then 
		    		TheFrontEnd:PopScreen()
		    	end
	            GoToServerListingScreen(forceOffline or false )
	        end)
        elseif not communication_succeeded then  -- We could not communicate with our auth server or steam is down
            --print ( "failed_communication" )
            TheFrontEnd:PopScreen()
            local confirm = PopupDialogScreen( STRINGS.UI.MAINSCREEN.OFFLINEMODE,STRINGS.UI.MAINSCREEN.OFFLINEMODEDESC,
								{
								  	{text=STRINGS.UI.MAINSCREEN.PLAYOFFLINE, cb = function() 
								  		TheFrontEnd:Fade(false, screen_fade_time*1.5, function()
								  			TheFrontEnd:PopScreen()
								  			GoToServerListingScreen(true) 
								  		end)
								  	end },
								  	{text=STRINGS.UI.MAINSCREEN.CANCELOFFLINE,   cb = function() 
								  		onCancel() 
								  		TheFrontEnd:PopScreen() 
								  	end}  
								})
            TheFrontEnd:PushScreen(confirm)
            TheNet:NotifyAuthenticationFailure()
        else -- We haven't created an account yet
	    	TheFrontEnd:PopScreen()
            TheFrontEnd:PushScreen(NoAuthenticationPopupDialogScreen(true, failed_email))
			TheNet:NotifyAuthenticationFailure()
        end
    end
	
	if TheSim:IsSteamLoggedOn() or account_manager:HasAuthToken() then
		if TheSim:GetUserHasLicenseForApp(DONT_STARVE_TOGETHER_APPID) then
			account_manager:SteamLogin( "Client Login" )
			TheFrontEnd:PushScreen(NetworkLoginPopup(onLogin, onCancel)) 
		else
			TheNet:NotifyAuthenticationFailure()
			OnNetworkDisconnect( "APP_OWNERSHIP_CHECK_FAILED", false, false )
		end
	else			
		-- Set lan mode
		TheNet:NotifyAuthenticationFailure()
		local confirm = PopupDialogScreen( STRINGS.UI.MAINSCREEN.STEAMOFFLINEMODE,STRINGS.UI.MAINSCREEN.STEAMOFFLINEMODEDESC, 
						{
						 {text=STRINGS.UI.MAINSCREEN.PLAYOFFLINE, cb = function() TheFrontEnd:PopScreen() GoToServerListingScreen(true) end },
						 {text=STRINGS.UI.MAINSCREEN.CANCELOFFLINE,  cb = function() TheFrontEnd:Fade(true, screen_fade_time) onCancel() TheFrontEnd:PopScreen() end}  
						})
		TheFrontEnd:PushScreen(confirm)
	end
	
	self.menu:Disable()	
end

-- MORGUE
function MainScreen:OnMorgueButton()
	self.menu:Disable()
	TheFrontEnd:Fade(false, screen_fade_time, function()
		TheFrontEnd:PushScreen(MorgueScreen())
		TheFrontEnd:Fade(true, screen_fade_time)
	end)
end

-- SUBSCREENS

function MainScreen:Settings()
	self.menu:Disable()
	TheFrontEnd:Fade(false, screen_fade_time, function()
		TheFrontEnd:PushScreen(OptionsScreen(false))
		TheFrontEnd:Fade(true, screen_fade_time)
	end)
end

function MainScreen:OnControlsButton()
	self.menu:Disable()
	TheFrontEnd:Fade(false, screen_fade_time, function()
		TheFrontEnd:PushScreen(ControlsScreen())
		TheFrontEnd:Fade(true, screen_fade_time)
	end)
end

function MainScreen:EmailSignup()
	TheFrontEnd:PushScreen(EmailSignupScreen())
end

function MainScreen:Forums()
	VisitURL("http://forums.kleientertainment.com/forum/73-dont-starve-together-beta/")
end

function MainScreen:Quit()
	TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MAINSCREEN.ASKQUIT, STRINGS.UI.MAINSCREEN.ASKQUITDESC, {{text=STRINGS.UI.MAINSCREEN.YES, cb = function() RequestShutdown() end },{text=STRINGS.UI.MAINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  }))
end

function MainScreen:OnExitButton()
	if PLATFORM == "NACL" then
		self:Logout()
	else
		self:Quit()
	end
end
function MainScreen:Refresh()
	self:MainMenu()
	TheFrontEnd:GetSound():PlaySound("dontstarve/music/music_FE","FEMusic")
end

function MainScreen:ShowMenu(menu_items, posX, posY)
	self.mainmenu = false
	self.menu:Clear()
	
	for k = #menu_items, 1, -1  do
		local v = menu_items[k]
		if v.text == STRINGS.UI.MAINSCREEN.PLAY or v.text == STRINGS.UI.MAINSCREEN.BACK then
			self.menu:AddItem(v.text, v.cb, v.offset, "large", v.textsize)
			self.menu.items[#self.menu.items]:SetScale(1.1,1.2)
			local pos = self.menu.items[#self.menu.items]:GetPosition()
			self.menu.items[#self.menu.items]:SetPosition(pos.x+3,pos.y)
			if v.text == STRINGS.UI.MAINSCREEN.BACK then
				self.menu.items[#self.menu.items]:SetPosition(pos.x+3,pos.y-5)
				self.menu.items[#self.menu.items]:SetScale(.95,1)
			end
		elseif v.text == STRINGS.UI.MAINSCREEN.BUYDONTSTARVEMAIN then
			self.menu:AddItem(v.text, v.cb, v.offset, "long", v.textsize)
			self.menu.items[#self.menu.items]:SetScale(1,1.2)
		else
			self.menu:AddItem(v.text, v.cb, v.offset, nil, v.textsize)
		end
	end

	if posX and posY then
		self.menu:SetPosition(posX, posY, 0)
	end

	self.menu:SetFocus()
	self.menu:Enable()
end

function MainScreen:DoOptionsMenu()

	local menu_items = {}



	if PLATFORM == "NACL" then
		table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.ACCOUNTINFO, cb= function() self:ProductKeys() end})
		if IsGamePurchased() then
			table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.ENTERKEY, cb= function() self:EnterKey() end})
		end
	end
	
	table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.SETTINGS, cb= function() self:Settings() end})
	table.insert(menu_items, {text=STRINGS.UI.MAINSCREEN.CONTROLS, cb= function() self:OnControlsButton() end})
	
	table.insert(menu_items, {text=STRINGS.UI.MAINSCREEN.CREDITS, cb= function() self:OnCreditsButton() end})
	
	if PLATFORM == "WIN32_STEAM" then
		table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.MOREGAMES, cb= function() VisitURL("http://store.steampowered.com/search/?developer=Klei%20Entertainment") end})
	end
	
	if BRANCH == "dev" then
		table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.CHEATS, cb= function() self:CheatMenu() end})
	end
	
	--if PLATFORM == "WIN32_STEAM" or PLATFORM == "WIN32" then
	--	table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.BROADCASTING, cb= function() self:BroadcastingMenu() end})
	--end
		
	table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.BACK, cb= function() self:MainMenu() end})
	if not TheSim:GetUserHasLicenseForApp(DONT_STARVE_APPID) then
		self:ShowMenu(menu_items, menuX, menuY-11)
	else
		self:ShowMenu(menu_items, menuX, menuY-30)
	end
end

function MainScreen:OnModsButton()
	self.menu:Disable()
	TheFrontEnd:Fade(false, screen_fade_time, function()
		TheFrontEnd:PushScreen(ModsScreen())
		TheFrontEnd:Fade(true, screen_fade_time)
	end)
end


function MainScreen:ResetProfile()
	TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MAINSCREEN.RESETPROFILE, STRINGS.UI.MAINSCREEN.SURE, {{text=STRINGS.UI.MAINSCREEN.YES, cb = function() self.profile:Reset() TheFrontEnd:PopScreen() end},{text=STRINGS.UI.MAINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  }))
end

function MainScreen:UnlockEverything()
	TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MAINSCREEN.UNLOCKEVERYTHING, STRINGS.UI.MAINSCREEN.SURE, {{text=STRINGS.UI.MAINSCREEN.YES, cb = function() self.profile:UnlockEverything() TheFrontEnd:PopScreen() end},{text=STRINGS.UI.MAINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  }))
end

function MainScreen:OnCreditsButton()
	TheFrontEnd:GetSound():KillSound("FEMusic")
	self.menu:Disable()
	TheFrontEnd:Fade(false, screen_fade_time, function()
		TheFrontEnd:PushScreen( CreditsScreen() )
		TheFrontEnd:Fade(true, screen_fade_time)
	end)
end
	

function MainScreen:CheatMenu()
	local menu_items = {}
	table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.UNLOCKEVERYTHING, cb= function() self:UnlockEverything() end})
	table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.RESETPROFILE, cb= function() self:ResetProfile() end})
	table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.BACK, cb= function() self:DoOptionsMenu() end})
	self:ShowMenu(menu_items, menuX, menuY-30)
end

function MainScreen:OnHostButton()
	local start_in_online_mode = false
	local server_started = TheNet:StartServer(start_in_online_mode)
	if server_started == true then
        DisableAllDLC()
		StartNextInstance({reset_action = RESET_ACTION.LOAD_SLOT, save_slot=SaveGameIndex:GetCurrentSaveSlot()})
	end
end

function MainScreen:OnJoinButton()
	local start_worked = TheNet:StartClient(DEFAULT_JOIN_IP)
	if start_worked then
        DisableAllDLC()
	end
	ShowLoading()
	TheFrontEnd:Fade(false, 1)
end

function MainScreen:MainMenu()
	
	local menu_items = {}
	
	-- For Debugging/Testing
	if SHOW_DST_DEBUG_HOST_JOIN then
		table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.HOST, cb= function() self:OnHostButton() end, offset = Vector3(0,40,0)})
		table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.JOIN, cb= function() self:OnJoinButton() end, offset = Vector3(0,40,0)})
	end
	
	-- Simple menu for test
	--table.insert( menu_items, {text="Multiplayer", cb= function() TheFrontEnd:PushScreen( ServerListingScreen(true) ) end, offset = Vector3(0,20,0)})	
	--table.insert( menu_items, {text="LAN", cb= function() TheFrontEnd:PushScreen( ServerListingScreen(false) ) end, offset = Vector3(0,20,0)})	
	-- End debugging
	table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.PLAY, cb= function() self:OnPlayMultiplayerButton( true ) end, offset = Vector3(0,10,0)})
			

	if MODS_ENABLED then
		table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.MODS, cb= function() self:OnModsButton() end})
	end

	table.insert(menu_items, {text=STRINGS.UI.MORGUESCREEN.HISTORY, cb= function() self:OnMorgueButton() end})

	table.insert(menu_items, {text=STRINGS.UI.MAINSCREEN.OPTIONS, cb= function() self:DoOptionsMenu() end})
	
	
	if PLATFORM == "NACL" then
		table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.LOGOUT, cb= function() self:OnExitButton() end})
	else
		table.insert( menu_items, {text=STRINGS.UI.MAINSCREEN.EXIT, cb= function() self:OnExitButton() end})
	end

	-- Playing DST Beta SKU and don't own DS, upsell DS
	if not TheSim:GetUserHasLicenseForApp(DONT_STARVE_APPID) then
		table.insert(menu_items, {text=STRINGS.UI.MAINSCREEN.BUYDONTSTARVEMAIN, 
								  cb= function() VisitURL("http://store.steampowered.com/app/219740/") end, 
								  offset = Vector3(0,-45,0), 
								  textsize = 35})
		self:ShowMenu(menu_items, menuX, menuY-70)
	else
		self:ShowMenu(menu_items, menuX, menuY-30)
	end
	self.mainmenu = true
end

function MainScreen:OnBecomeActive()
    MainScreen._base.OnBecomeActive(self)
    TheFrontEnd:SetOfflineMode(false)
	self.menu:Enable()
	self.menu:SetFocus()
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
	wave4 = .1,
	happycheer = .1,
	sad = .1,
	angry = .1,
	annoyed = .1,
	bonesaw = .05,
	facepalm = .1,	
}

function MainScreen:OnUpdate(dt)
	if PLATFORM == "PS4" and TheSim:ShouldPlayIntroMovie() then
		TheFrontEnd:PushScreen( MovieDialog("movies/forbidden_knowledge.mp4", function() TheFrontEnd:GetSound():PlaySound("dontstarve/music/music_FE","FEMusic") end ) )
        self.music_playing = true
	elseif not self.music_playing then
        TheFrontEnd:GetSound():PlaySound("dontstarve/music/music_FE","FEMusic")
        self.music_playing = true
    end	
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
end

function MainScreen:SetCurrentVersion(str)
	local status, version = pcall( function() return json.decode(str) end )
	local most_recent_cl = -2 
	if status and version then
		if version.main and table.getn(version.main) > 0 then
			for idx,changelist in ipairs(version.main) do
				if tonumber(changelist) > most_recent_cl then
					most_recent_cl = tonumber(changelist)
				end
			end
			self.currentversion = most_recent_cl
		end
	end
	self.gameversion:SetTargetGameVersion(most_recent_cl)
end

function MainScreen:SetMOTD(str, cache)
	--print("MainScreen:SetMOTD", str, cache)

	local status, motd = pcall( function() return json.decode(str) end )
	--print("decode:", status, motd)
	if status and motd then
	    if cache then
	 		SavePersistentString("motd", str)
	    end

		local platform_motd = motd.dststeam
		print("platform_motd", platform_motd)
		if platform_motd then
		    if platform_motd.motd_title and string.len(platform_motd.motd_title) > 0 and
			    	platform_motd.motd_body and string.len(platform_motd.motd_body) > 0 then
				self.motd.motdtitle:SetString(platform_motd.motd_title)
				self.motd.motdtext:SetString(platform_motd.motd_body)

			    if platform_motd.link_title and string.len(platform_motd.link_title) > 0 and
				    	platform_motd.link_url and string.len(platform_motd.link_url) > 0 then
				    self.motd.button:SetText(platform_motd.link_title)
				    self.motd.button:SetOnClick( function() VisitURL(platform_motd.link_url) end )
				else
					self.motd.button:Hide()
				end
		    else
				self.motd:Hide()
		    end
		    self.motd:Show()
	    else
			self.motd:Hide()
		end
	end
end

function MainScreen:OnMOTDQueryComplete( result, isSuccessful, resultCode )
	--print( "MainScreen:OnMOTDQueryComplete", result, isSuccessful, resultCode )
 	if isSuccessful and string.len(result) > 1 and resultCode == 200 then 
 		self:SetMOTD(result, true)
	end
end

function MainScreen:OnCachedMOTDLoad(load_success, str)
	--print("MainScreen:OnCachedMOTDLoad", load_success, str)
	if load_success and string.len(str) > 1 then
		self:SetMOTD(str, false)
	end
	TheSim:QueryServer( "https://s3-us-west-2.amazonaws.com/kleifiles/external/ds_motd.json", function(...) self:OnMOTDQueryComplete(...) end, "GET" )
end

function MainScreen:OnCurrentVersionQueryComplete( result, isSuccessful, resultCode )
 	if isSuccessful and string.len(result) > 1 and resultCode == 200 then 
 		self:SetCurrentVersion(result, true)
 	else
		self.gameversion:SetTargetGameVersion(-2)
	end
end

function MainScreen:UpdateCurrentVersion()
	TheSim:QueryServer( "https://s3.amazonaws.com/dstbuilds/builds.json", function(...) self:OnCurrentVersionQueryComplete(...) end, "GET" )
end

function MainScreen:UpdateMOTD()
	TheSim:GetPersistentString("motd", function(...) self:OnCachedMOTDLoad(...) end)
end

function MainScreen:SetCountdown(str, cache)
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
	    else
			self.countdown:Hide()
		    self.wilson:Show()
		    self.wilson2:Show()
		end
	end	
end

function MainScreen:OnCountdownQueryComplete( result, isSuccessful, resultCode )
	--print( "MainScreen:OnMOTDQueryComplete", result, isSuccessful, resultCode )
 	if isSuccessful and string.len(result) > 1 and resultCode == 200 then 
 		self:SetCountdown(result, true)
	end
end

function MainScreen:OnCachedCountdownLoad(load_success, str)
	--print("MainScreen:OnCachedMOTDLoad", load_success, str)
	if load_success and string.len(str) > 1 then
		self:SetCountdown(str, false)
	end
	TheSim:QueryServer( "https://s3-us-west-2.amazonaws.com/kleifiles/external/ds_update.json", function(...) self:OnCountdownQueryComplete(...) end, "GET" )
end

function MainScreen:UpdateCountdown()
	--print("MainScreen:UpdateMOTD()")
	TheSim:GetPersistentString("updatecountdown", function(...) self:OnCachedCountdownLoad(...) end)
end

function MainScreen:GetHelpText()
	if not self.mainmenu then
	    local controller_id = TheInput:GetControllerID()
	    return TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK
	else
		return ""
	end
end

return MainScreen
