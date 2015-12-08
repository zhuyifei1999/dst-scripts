local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/templates"
require "os"

local PopupDialogScreen = require "screens/popupdialog"
local EmailSignupScreen = require "screens/emailsignupscreen"
local MovieDialog = require "screens/moviedialog"
local Countdown = require "widgets/countdown"
local MultiplayerMainScreen = require "screens/multiplayermainscreen"

local NoAuthenticationPopupDialogScreen = require "screens/noauthenticationpopupdialogscreen"
local NetworkLoginPopup = require "screens/networkloginpopup"

local OnlineStatus = require "widgets/onlinestatus"

--local UnopenedItemPopup = require "screens/unopeneditempopup"
local ROGItemPopup = require "screens/rogitempopup"

local rcol = RESOLUTION_X/2 -200
local lcol = -RESOLUTION_X/2 + 280
local title_x = 20
local title_y = 10
local subtitle_offset_x = 20
local subtitle_offset_y = -260

local bottom_offset = 60

local menuX = lcol+10
local menuY = -215

local DEBUG_MODE = BRANCH == "dev"

local MainScreen = Class(Screen, function(self, profile)
	Screen._ctor(self, "MainScreen")
    self.profile = profile
	self.log = true
    self.targetversion = -1
	self:DoInit() 
    self.default_focus = self.play_button
    self.music_playing = false
end)


function MainScreen:DoInit( )
	TheFrontEnd:GetGraphicsOptions():DisableStencil()
	TheFrontEnd:GetGraphicsOptions():DisableLightMapComponent()
	
	TheInputProxy:SetCursorVisible(true)

	-- BG
	self.bg = self:AddChild(TEMPLATES.AnimatedPortalBackground())	
   
    -- FG
    self.fg = self:AddChild(TEMPLATES.AnimatedPortalForeground())
	
	-- FIXED ROOT
    self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
 
	--LEFT COLUMN
    self.left_col = self.fixed_root:AddChild(Widget("left"))
	self.left_col:SetPosition(lcol-100, 0)

    self.title = self.fixed_root:AddChild(Image("images/frontscreen.xml", "title.tex"))
    self.title:SetScale(.65)
    self.title:SetPosition(title_x, title_y-5)
    self.title:SetTint(FRONTEND_TITLE_COLOUR[1], FRONTEND_TITLE_COLOUR[2], FRONTEND_TITLE_COLOUR[3], FRONTEND_TITLE_COLOUR[4])

    self.presents_image = self.fixed_root:AddChild(Image("images/frontscreen.xml", "kleipresents.tex"))
    self.presents_image:SetPosition(title_x+subtitle_offset_x-30, title_y-subtitle_offset_y+30, 0)
    self.presents_image:SetScale(.7)
    self.presents_image:SetTint(FRONTEND_TITLE_COLOUR[1], FRONTEND_TITLE_COLOUR[2], FRONTEND_TITLE_COLOUR[3], FRONTEND_TITLE_COLOUR[4])    

    self.legalese_image = self.fixed_root:AddChild(Image("images/frontscreen.xml", "legalese.tex"))
    self.legalese_image:SetPosition(title_x+subtitle_offset_x, title_y+subtitle_offset_y-50, 0)
    self.legalese_image:SetScale(.7)
    self.legalese_image:SetTint(FRONTEND_TITLE_COLOUR[1], FRONTEND_TITLE_COLOUR[2], FRONTEND_TITLE_COLOUR[3], FRONTEND_TITLE_COLOUR[4])    
    
	self.countdown = self.fixed_root:AddChild(Countdown())
    self.countdown:SetScale(1)
    self.countdown:SetPosition(-575, -330, 0)
    self.countdown:Hide()
    
    --RIGHT COLUMN
    self.right_col = self.fixed_root:AddChild(Widget("right"))
    self.right_col:SetPosition(rcol, 0)

    self.play_button = self.fixed_root:AddChild(ImageButton("images/frontscreen.xml", "play_highlight.tex", nil, nil, nil, nil, {1,1}, {0,0}))--"highlight.tex", "highlight_hover.tex"))
    self.play_button.bg = self.play_button:AddChild(Image("images/frontscreen.xml", "play_highlight_hover.tex"))
    self.play_button.bg:SetScale(.69, .53)
    self.play_button.bg:MoveToBack()
    self.play_button.bg:Hide()
    self.play_button.image:SetPosition(0,3)
    self.play_button.bg:SetPosition(0,3)
    self.play_button:SetPosition(-RESOLUTION_X*.35, 0)
    self.play_button:SetTextColour(1, 1, 1, 1)
    self.play_button:SetTextFocusColour(1, 1, 1, 1)
    self.play_button:SetTextDisabledColour({1,1,1,1})
    self.play_button:SetNormalScale(.65, .5)
    self.play_button:SetFocusScale(.7, .55)
    self.play_button:SetTextSize(55)
    self.play_button:SetFont(TITLEFONT)
    self.play_button:SetDisabledFont(TITLEFONT)
    self.play_button:SetText(STRINGS.UI.MAINSCREEN.PLAY, true, {2,-3})
    local playgainfocusfn = self.play_button.OnGainFocus
    local playlosefocusfn = self.play_button.OnLoseFocus
    self.play_button.OnGainFocus = function()
        playgainfocusfn(self.play_button)
        self.play_button:SetTextSize(58)
        self.play_button.image:SetTint(1,1,1,1)
        self.play_button.bg:Show()
    end
    self.play_button.OnLoseFocus = function()
        playlosefocusfn(self.play_button)
        self.play_button:SetTextSize(55)
        self.play_button.image:SetTint(1,1,1,.6)
        self.play_button.bg:Hide()
    end
    self.play_button:SetOnClick(function()
    	self.play_button:Disable()
        self:OnLoginButton(true)
    end)

    self.exit_button = self.fixed_root:AddChild(ImageButton("images/frontscreen.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex", nil, nil, nil, {1,1}, {0,0}))
    self.exit_button:SetPosition(-RESOLUTION_X*.4, -RESOLUTION_Y*.5 + BACK_BUTTON_Y)
    self.exit_button.image:SetPosition(-53, 2)
    self.exit_button.image:SetScale(.7)
    self.exit_button:SetTextColour(GOLD[1], GOLD[2], GOLD[3], GOLD[4])
    self.exit_button:SetTextFocusColour(1,1,1,1)
    self.exit_button:SetText(STRINGS.UI.MAINSCREEN.QUIT, true, {2,-2})
    self.exit_button:SetFont(TITLEFONT)
    self.exit_button:SetDisabledFont(TITLEFONT)
    self.exit_button:SetTextDisabledColour({GOLD[1], GOLD[2], GOLD[3], GOLD[4]})
    self.exit_button.bg = self.exit_button:AddChild(Image("images/ui.xml", "blank.tex"))
    local w,h = self.exit_button.text:GetRegionSize()
    self.exit_button.bg:ScaleToSize(w+15, h+15)
    local exitgainfocusfn = self.exit_button.OnGainFocus
    local exitlosefocusfn = self.exit_button.OnLoseFocus
    self.exit_button.OnGainFocus = function()
        exitgainfocusfn(self.exit_button)
        self.exit_button:SetScale(1.05)
    end
    self.exit_button.OnLoseFocus = function()
        exitlosefocusfn(self.exit_button)
        self.exit_button:SetScale(1)
    end
    self.exit_button:SetOnClick(function()
        self:Quit()
    end)

    if TheInput:ControllerAttached() then
        self.legalese_image:SetPosition(title_x+subtitle_offset_x, title_y+subtitle_offset_y-50+20, 0)
        self.exit_button:SetPosition(-RESOLUTION_X*.4, -RESOLUTION_Y*.5 + BACK_BUTTON_Y+25)
    end

    self.onlinestatus = self.fixed_root:AddChild(OnlineStatus())

	-- self:UpdateMOTD()
	self:UpdateCurrentVersion()
	--self:UpdateCountdown()

	self.filter_settings = nil

	--focus moving
    self.play_button:SetFocusChangeDir(MOVE_DOWN, self.exit_button)
    self.exit_button:SetFocusChangeDir(MOVE_UP, self.play_button)
	
	self:MakeDebugButtons()
    self.play_button:SetFocus()
end

function MainScreen:OnRawKey( key, down )
end

-- MULTIPLAYER PLAY
function MainScreen:OnLoginButton( push_mp_main_screen )	

    local account_manager = TheFrontEnd:GetAccountManager()
	local hadPendingConnection = TheNet:HasPendingConnection()
	
    local function GoToMultiplayerMainMenu( offline )		
		TheFrontEnd:SetOfflineMode(offline)
		--self.bg.anim_root.portal:GetAnimState():PlayAnimation("portal_blackout", false)
		if push_mp_main_screen then
            local function session_mapping_cb(data)
                TheFrontEnd:PushScreen(MultiplayerMainScreen(self.profile, offline, data))
                TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
            end
            if not TheNet:DeserializeAllLocalUserSessions(session_mapping_cb) then
                session_mapping_cb()
            end
        else
            TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
		end
    end
    	
    local function onCancel()
        self.play_button:Enable()
        self.exit_button:Enable()
        -- self.menu:Enable()
    end

    local function checkVersion()
        if self.targetversion == -1 then
            return "waiting"
        elseif self.targetversion == -2 then
            return "error"
        elseif tonumber(APP_VERSION) < self.targetversion then
            return "old"
        else
            return "current"
        end
    end
    	
    local function onLogin(forceOffline)
	    local account_manager = TheFrontEnd:GetAccountManager()
	    local is_banned = (account_manager:IsBanned() == true)
	    local failed_email = account_manager:MustValidateEmail()
	    local must_upgrade = account_manager:MustUpgradeClient()
	    local communication_succeeded = account_manager:CommunicationSucceeded()
	    local inventory_succeeded = TheInventory:HasDownloadedInventory()
		local has_auth_token = account_manager:HasAuthToken()
		
        if is_banned then -- We are banned
        	TheFrontEnd:PopScreen()
	        TheNet:NotifyAuthenticationFailure()
            OnNetworkDisconnect( "E_BANNED", true)
        -- We are on a deprecated version of the game
        elseif must_upgrade then
        	TheFrontEnd:PopScreen()
        	TheNet:NotifyAuthenticationFailure()
        	OnNetworkDisconnect( "E_UPGRADE", true)
        elseif checkVersion() == "old" and not DEBUG_MODE then
            TheFrontEnd:PopScreen()
            local confirm = PopupDialogScreen( STRINGS.UI.MAINSCREEN.VERSION_OUT_OF_DATE_TITLE, STRINGS.UI.MAINSCREEN.VERSION_OUT_OF_DATE_BODY, 
                        {
                         {text=STRINGS.UI.MAINSCREEN.VERSION_OUT_OF_DATE_PLAY, 
                                    cb = function() 
                                        TheFrontEnd:Fade(false, SCREEN_FADE_TIME, 
                                            function()
                                                TheFrontEnd:PopScreen()
                                                GoToMultiplayerMainMenu(true) 
                                            end) 
                                    end },
                         {text=STRINGS.UI.MAINSCREEN.VERSION_OUT_OF_DATE_INSTRUCTIONS, 
                                    cb = function() 
                                        onCancel() 
                                        TheFrontEnd:PopScreen() 
                                        VisitURL("http://forums.kleientertainment.com/forum/86-check-for-latest-steam-build/") 
                                    end },
                         {text=STRINGS.UI.MAINSCREEN.VERSION_OUT_OF_DATE_CANCEL,  
                                    cb = function() 
                                        onCancel() 
                                        TheFrontEnd:PopScreen() 
                                    end}  
                        }, false, 140)
            for i,v in pairs(confirm.menu.items) do
                v.image:SetScale(.6, .7)
            end
            TheFrontEnd:PushScreen(confirm)
        elseif ( has_auth_token and communication_succeeded ) or forceOffline then
            if hadPendingConnection then
                TheFrontEnd:PopScreen()
            else
                if not push_mp_main_screen then
                    TheFrontEnd:PopScreen()
                end
            
                TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
                    if push_mp_main_screen then
                        TheFrontEnd:PopScreen()
                    end

                    GoToMultiplayerMainMenu(forceOffline or false )

                    -- In case we have given out token items that have no assets in the game
                    -- But still need to be marked as opened
                    local uo_items = TheInventory:GetUnopenedItems()
                    for _,item in pairs(uo_items) do
                        if Prefabs[string.lower(item.item_type)] == nil and CLOTHING[string.lower(item.item_type)] == nil then
                            TheInventory:SetItemOpened(item.item_id)
                        end
                    end

                    local rog_items = {}--"body_buttons_green_laurel", "body_buttons_pink_hibiscus" }

                    if #rog_items > 0 then
                        local rog_popup = ROGItemPopup(rog_items)
                        TheFrontEnd:PushScreen(rog_popup)
                    end
                    TheFrontEnd:Fade(true, SCREEN_FADE_TIME)

                end)
            end
        elseif not communication_succeeded then  -- We could not communicate with our auth server or steam is down
            print ( "failed_communication" )
            TheFrontEnd:PopScreen()
            local confirm = PopupDialogScreen( STRINGS.UI.MAINSCREEN.OFFLINEMODE,STRINGS.UI.MAINSCREEN.OFFLINEMODEDESC,
								{
								  	{text=STRINGS.UI.MAINSCREEN.PLAYOFFLINE, cb = function() 
								  		TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
								  			TheFrontEnd:PopScreen()
								  			GoToMultiplayerMainMenu(true) 
								  		end)
								  	end },
								  	{text=STRINGS.UI.MAINSCREEN.CANCELOFFLINE,   cb = function() 
								  		onCancel() 
								  		TheFrontEnd:PopScreen() 
								  	end}  
								})
            TheFrontEnd:PushScreen(confirm)
            TheNet:NotifyAuthenticationFailure()
        elseif (not inventory_succeeded and has_auth_token) then
            print ( "[Warning] Failed to download local inventory" )
        else -- We haven't created an account yet
            TheFrontEnd:PopScreen()
            TheFrontEnd:PushScreen(NoAuthenticationPopupDialogScreen(true, failed_email))
            TheNet:NotifyAuthenticationFailure()
        end
    end
	
	if TheSim:IsLoggedOn() or account_manager:HasAuthToken() then
		if TheSim:GetUserHasLicenseForApp(DONT_STARVE_TOGETHER_APPID) then
			account_manager:Login( "Client Login" )
			TheFrontEnd:PushScreen(NetworkLoginPopup(onLogin, checkVersion, onCancel, hadPendingConnection)) 
		else
			TheNet:NotifyAuthenticationFailure()
			OnNetworkDisconnect( "APP_OWNERSHIP_CHECK_FAILED", false, false )
		end
	else			
		-- Set lan mode
		TheNet:NotifyAuthenticationFailure()
		local confirm = PopupDialogScreen( STRINGS.UI.MAINSCREEN.STEAMOFFLINEMODE,STRINGS.UI.MAINSCREEN.STEAMOFFLINEMODEDESC, 
						{
						 {text=STRINGS.UI.MAINSCREEN.PLAYOFFLINE, cb = function() TheFrontEnd:PopScreen() GoToMultiplayerMainMenu(true) end },
						 {text=STRINGS.UI.MAINSCREEN.CANCELOFFLINE,  cb = function() onCancel() TheFrontEnd:PopScreen() end}  
						})
		TheFrontEnd:PushScreen(confirm)
	end
	
	-- self.menu:Disable()	
    self.play_button:Disable()
    self.exit_button:Disable()
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

function MainScreen:OnHostButton()
	SaveGameIndex:LoadServerEnabledModsFromSlot()
	KnownModIndex:Save()
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
end

function MainScreen:MakeDebugButtons()
	-- For Debugging/Testing
	if DEBUG_MODE then
        local host_button  = self.fixed_root:AddChild(ImageButton())
        host_button:SetScale(.8)
        host_button:SetPosition(lcol-100-20, 250)
        host_button:SetText(STRINGS.UI.MAINSCREEN.HOST)
        host_button:SetOnClick( function() self:OnHostButton() end )

        local join_button  = self.fixed_root:AddChild(ImageButton())
        join_button:SetScale(.8)
        join_button:SetPosition(lcol-100+140, 250)
        join_button:SetText(STRINGS.UI.MAINSCREEN.JOIN)
        join_button:SetOnClick( function() self:OnJoinButton() end )
	end
end

function MainScreen:OnBecomeActive()
    MainScreen._base.OnBecomeActive(self)
    TheFrontEnd:SetOfflineMode(false)
    self.play_button:Enable()
    self.exit_button:Enable()
    self.play_button:SetFocus()
    self.leaving = nil
end

function MainScreen:OnUpdate(dt)
	if PLATFORM == "PS4" and TheSim:ShouldPlayIntroMovie() then
		TheFrontEnd:PushScreen( MovieDialog("movies/forbidden_knowledge.mp4", function() TheFrontEnd:GetSound():PlaySound("dontstarve/music/music_FE","FEMusic") end ) )
        self.music_playing = true
	elseif not self.music_playing then
        TheFrontEnd:GetSound():PlaySound("dontstarve/music/music_FE","FEMusic")
        TheFrontEnd:GetSound():PlaySound("dontstarve/together_FE/portal_idle","FEPortalSFX")
        self.music_playing = true
    end	

    if self.bg.anim_root.portal:GetAnimState():AnimDone() and not self.leaving then 
    	if math.random() < .33 then 
			self.bg.anim_root.portal:GetAnimState():PlayAnimation("portal_idle_eyescratch", false) 
    	else
    		self.bg.anim_root.portal:GetAnimState():PlayAnimation("portal_idle", false)
    	end
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
	self:SetTargetGameVersion(most_recent_cl)
end

function MainScreen:SetTargetGameVersion(ver)
    self.targetversion = ver
end

function MainScreen:OnGetMOTDImageQueryComplete( is_successful )
	if is_successful then
		self.motd.motdimage:SetTexture( "images/motd.xml", "motd.tex" )
		self.motd.motdimage:Show()
	end	
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
		--Uncomment these to test Image MOTD
		--platform_motd.image_url = "http://forums.kleientertainment.com/public/DST/motd.tex"
		--platform_motd.motd_body = ""
		
		--print("platform_motd")
		--dumptable(platform_motd)
		
		if platform_motd then
			self.motd:Show()
		    if platform_motd.motd_title and string.len(platform_motd.motd_title) > 0 and
			    	platform_motd.motd_body and string.len(platform_motd.motd_body) > 0 then

				self.motd.motdtitle:SetString(platform_motd.motd_title)
				self.motd.motdtext:SetString(platform_motd.motd_body)
				self.motd.motdimage:Hide()

			    if platform_motd.link_title and string.len(platform_motd.link_title) > 0 and
				    	platform_motd.link_url and string.len(platform_motd.link_url) > 0 then
				    self.motd.button:SetText(platform_motd.link_title)
				    self.motd.button:SetOnClick( function() VisitURL(platform_motd.link_url) end )
				else
					self.motd.button:Hide()
				end
			elseif platform_motd.motd_title and string.len(platform_motd.motd_title) > 0 and
			    	platform_motd.image_url and string.len(platform_motd.image_url) > 0 then

				self.motd.motdtitle:SetString(platform_motd.motd_title)
				self.motd.motdtext:Hide()
				
				local use_disk_file = not cache
				if use_disk_file then
					self.motd.motdimage:Hide()
				end
				TheSim:GetMOTDImage( platform_motd.image_url, use_disk_file, function(...) self:OnGetMOTDImageQueryComplete(...) end )
		    else
				self.motd:Hide()
		    end
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
		self:SetTargetGameVersion(-2)
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
	    else
			self.countdown:Hide()
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

return MainScreen
