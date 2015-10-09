local Screen = require "widgets/screen"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local PlayerBadge = require "widgets/playerbadge"
local ScrollableList = require "widgets/scrollablelist"
local LobbyChatQueue = require "widgets/lobbychatqueue"
local Spinner = require "widgets/spinner"
local DressupPanel = require "widgets/dressuppanel"

local PopupDialogScreen = require "screens/popupdialog"

local TEMPLATES = require "widgets/templates"

local clothing = require "clothing"

require("util")
require("networking")

local DEBUG_MODE = BRANCH == "dev"

local REFRESH_INTERVAL = .5

local function StartGame(this)
	if this.startbutton then 
		this.startbutton:Disable()
	end

	if this.dressup then 
		this.dressup:OnClose()
	end

	if this.cb and this.dressup then
		local skins = this.dressup:GetSkinsForGameStart()
		--print("Starting game, character is ", this.currentcharacter or "nil", this.dressup.currentcharacter or "nil")
		this.cb(this.dressup.currentcharacter, skins.base, skins.body, skins.hand, skins.legs) --parameters are base_prefab, skin_base, clothing_body, clothing_hand, then clothing_legs
	end
end



local LobbyScreen = Class(Screen, function(self, profile, cb, no_backbutton, default_character, days_survived)
	Screen._ctor(self, "LobbyScreen")
    self.profile = profile
	self.log = true
    self.issoundplaying = false

    self.no_cancel = no_backbutton
    
    self.currentcharacter = nil
    self.numPlayers = 0
    self.time_to_refresh = REFRESH_INTERVAL
    self.active_tab = "players"

    if days_survived then
    	self.days_survived = math.floor(days_survived)
    else
    	self.days_survived = -1
    end

    self.anim_bg = self:AddChild(Image("images/bg_spiral_anim.xml", "spiral_bg.tex"))
    self.anim_bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.anim_bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.anim_bg:SetVAnchor(ANCHOR_MIDDLE)
    self.anim_bg:SetHAnchor(ANCHOR_MIDDLE)
    self.anim_bg:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.anim_bg:SetTint(FRONTEND_PORTAL_COLOUR[1], FRONTEND_PORTAL_COLOUR[2], FRONTEND_PORTAL_COLOUR[3], FRONTEND_PORTAL_COLOUR[4])

    self.anim_root = self:AddChild(Widget("root"))
    self.anim_root:SetVAnchor(ANCHOR_MIDDLE)
    self.anim_root:SetHAnchor(ANCHOR_MIDDLE)
    self.anim_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

   	self.anim = self.anim_root:AddChild(UIAnim())
    self.anim:GetAnimState():SetBuild("spiral_bg")
    self.anim:GetAnimState():SetBank("spiral_bg")
    self.anim:GetAnimState():PlayAnimation("idle_loop", true)
    self.anim:GetAnimState():SetMultColour(FRONTEND_PORTAL_COLOUR[1], FRONTEND_PORTAL_COLOUR[2], FRONTEND_PORTAL_COLOUR[3], FRONTEND_PORTAL_COLOUR[4])

    self.anim_ol = self:AddChild(Image("images/bg_spiral_anim_overlay.xml", "spiral_ol.tex"))
    self.anim_ol:SetVRegPoint(ANCHOR_MIDDLE)
    self.anim_ol:SetHRegPoint(ANCHOR_MIDDLE)
    self.anim_ol:SetVAnchor(ANCHOR_MIDDLE)
    self.anim_ol:SetHAnchor(ANCHOR_MIDDLE)
    self.anim_ol:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.anim_ol:SetTint(FRONTEND_PORTAL_COLOUR[1], FRONTEND_PORTAL_COLOUR[2], FRONTEND_PORTAL_COLOUR[3], FRONTEND_PORTAL_COLOUR[4])

    self.vignette = self:AddChild(TEMPLATES.BackgroundVignette())
    self.vignette:SetTint(1,1,1,.8)

    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.fixed_root = self.root:AddChild(Widget("root"))
    self.fixed_root:SetPosition(-RESOLUTION_X/2, -RESOLUTION_Y/2, 0)

    if self.days_survived >= 0 then
	    self.dayssurvivedwidget = self.root:AddChild(Text(UIFONT, 30, STRINGS.UI.LOBBYSCREEN.DAYSSURVIVED.." "..self.days_survived))
	    self.dayssurvivedwidget:SetHAlign(ANCHOR_LEFT)
	    self.dayssurvivedwidget:SetVAlign(ANCHOR_TOP)
	    local w = self.dayssurvivedwidget:GetRegionSize()
	    self.dayssurvivedwidget:SetPosition(-RESOLUTION_X/2 + w/2 + 80, -RESOLUTION_Y/2 + 80, 0)
	end

    self.heroportrait = self.fixed_root:AddChild(Image())
    self.heroportrait:SetScale(.9)
    self.heroportrait:SetPosition(RESOLUTION_X/2, RESOLUTION_Y-300)
    

    local adjust = 16

   	self:BuildCharacterDetailsBoxAndPanels()
   	--self.dressup:GetClothingOptions()
 	

 	self.players_button:MoveToFront()
	self.chat_button:MoveToFront() 
  
    if not TheInput:ControllerAttached() then
		self.startbutton = self.fixed_root:AddChild(TEMPLATES.Button(STRINGS.UI.LOBBYSCREEN.SELECT, function() StartGame(self) end))
		self.startbutton:SetPosition(RESOLUTION_X - 245, 60, 0)

		self.randomcharbutton = self.fixed_root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "random.tex", STRINGS.UI.LOBBYSCREEN.RANDOMCHAR, false, false, function()
				self:SelectRandomCharacter()
			end))
		self.randomcharbutton:SetPosition( RESOLUTION_X/2 - 15, 25, 0)
		self.randomcharbutton:SetScale(.8, .8, .8)

		if not no_backbutton then
			self.startbutton:SetPosition( RESOLUTION_X - 245, 60, 0)
			self.backbutton = self.root:AddChild(TEMPLATES.BackButton(function() self:DoConfirmQuit() end, 
																		STRINGS.UI.LOBBYSCREEN.DISCONNECT,
																		{x=38, y=0}, --text offset
																		{x=1, y=-1})) --drop shadow offset from text
		end
	end

    self:BuildCharactersList(cb, default_character)
    
    self.default_focus = self.scroll_list
    self:DoFocusHookups()
end)

function LobbyScreen:OnBecomeActive()
    self._base.OnBecomeActive(self)
    self:StartLobbyMusic()
end

function LobbyScreen:OnDestroy()
    self:StopLobbyMusic()
    self._base.OnDestroy(self)
end

function LobbyScreen:StartLobbyMusic()
    if not self.issoundplaying then
        self.issoundplaying = true
        TheMixer:SetLevel("master", 1)
        TheMixer:PushMix("lobby")
        TheFrontEnd:GetSound():KillSound("FEMusic")
        TheFrontEnd:GetSound():PlaySound("dontstarve/together_FE/DST_theme_portaled", "PortalMusic")
        TheFrontEnd:GetSound():PlaySound("dontstarve/together_FE/portal_swirl", "PortalSFX")
    end
end

function LobbyScreen:StopLobbyMusic()
    if self.issoundplaying then
        self.issoundplaying = false
        TheFrontEnd:GetSound():KillSound("PortalMusic")
        TheFrontEnd:GetSound():KillSound("PortalSFX")
        TheMixer:PopMix("lobby")
    end
end


-- TEST DATA
local TestObjs = {
	{
		userid = "OU_76561197968176071",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "Baymax",
		admin = true,
		performance = 60,
		steamid = 76561197968176073,
		prefab = "wilson",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176072",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "Wall-e",
		admin = false,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "wx78",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176073",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "this is a really long long long long name",
		admin = false,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "willow",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176074",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "R. Daneel Olivaw",
		admin = false,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "wendy",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176075",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "Johnny 5",
		admin = false,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "wx78",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176076",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "Terminator",
		admin = true,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "wx78",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176077",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "Eve",
		admin = false,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "wx78",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176078",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "Mo",
		admin = false,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "wx78",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176079",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "R. Giskard",
		admin = false,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "wx78",
		colour = {.8,.3,.2,1},
	},
	{
		userid = "OU_76561197968176070",
		friend = false,
		playerage = 2,
		userflags = 0,
		name = "Doggie",
		admin = false,
		performance = nil,
		steamid = 76561197968176073,
		prefab = "wx78",
		colour = {.8,.3,.2,1},
	},
}


local function doButtonFocusHookups(playerListing)
		
	if playerListing.mute:IsVisible() then
		-- TODO: right should jump over to the dressup window once we enable it
		playerListing.mute:SetFocusChangeDir(MOVE_LEFT, playerListing.viewprofile)
		playerListing.focus_forward = playerListing.mute
	end

	if playerListing.viewprofile:IsVisible() then
		playerListing.viewprofile:SetFocusChangeDir(MOVE_RIGHT, playerListing.mute)
		playerListing.focus_forward = playerListing.viewprofile
	end
end


local function listingConstructor(v, i, parent)

	local playerListing =  parent:AddChild(Widget("playerListing"))
	playerListing:SetPosition(5,0)

	local empty = v == nil
	if v then
		empty = #v > 0
	end

    local displayName = not empty and v.name or ""

	playerListing.userid = not empty and v.userid or nil

	local nudge_x = -5

    playerListing.bg = playerListing:AddChild(Image("images/scoreboard.xml", "row_short.tex"))
    playerListing.bg:SetPosition(15+nudge_x, 0)
    playerListing.bg:ScaleToSize(196,48)
    playerListing.bg:SetTint(1, 1, 1, (i % 2) == 0 and .85 or .5)
	if empty then
		playerListing.bg:Hide()
	end

	playerListing.highlight = playerListing:AddChild(Image("images/scoreboard.xml", "row_short_goldoutline.tex"))
    playerListing.highlight:SetPosition(15+nudge_x, 0)
    playerListing.highlight:ScaleToSize(198,50)
	playerListing.highlight:Hide()

	playerListing.characterBadge = nil
	if empty then
		playerListing.characterBadge = playerListing:AddChild(PlayerBadge("", DEFAULT_PLAYER_COLOUR, false, 0))
		playerListing.characterBadge:Hide()
	else
		--print("player data is ")
		--dumptable(v)
		playerListing.characterBadge = playerListing:AddChild(PlayerBadge(v.prefab or "", v.colour or DEFAULT_PLAYER_COLOUR, v.performance ~= nil, v.userflags or 0))
	end
	playerListing.characterBadge:SetScale(.45)
	playerListing.characterBadge:SetPosition(-77+nudge_x,0,0)

	playerListing.adminBadge = playerListing:AddChild(ImageButton("images/avatars.xml", "avatar_admin.tex", "avatar_admin.tex", "avatar_admin.tex", nil, nil, {1,1}, {0,0}))
	playerListing.adminBadge:Disable()
	playerListing.adminBadge:SetPosition(-89+nudge_x,-10,0)	
	playerListing.adminBadge.image:SetScale(.18)
	playerListing.adminBadge.scale_on_focus = false
    playerListing.adminBadge:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.ADMIN, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
	if empty or not v.admin then
    	playerListing.adminBadge:Hide()
	end

	local colours = nil --GetAvailablePlayerColours()

    playerListing.name = playerListing:AddChild(Text(TALKINGFONT, 25))
    playerListing.name._align =
    {
        maxwidth = 100,
        maxchars = 22,
        x = -52 + nudge_x,
        y = -2.5,
    }
    playerListing.name:SetTruncatedString(displayName, playerListing.name._align.maxwidth, playerListing.name._align.maxchars, true)
    local w, h = playerListing.name:GetRegionSize()
    playerListing.name:SetPosition(playerListing.name._align.x + w * .5, playerListing.name._align.y, 0)

	-- Testing only
	if colours then 
		playerListing.name:SetColour(unpack(colours[math.random(#colours)])) 
	else
		playerListing.name:SetColour(unpack(not empty and v.colour or DEFAULT_PLAYER_COLOUR))
	end

	local owner = TheNet:GetUserID()
	local profile_scale = .6
	
	playerListing.viewprofile = playerListing:AddChild(ImageButton("images/scoreboard.xml", "addfriend.tex", "addfriend.tex", "addfriend.tex", "addfriend.tex", nil, {1,1}, {0,0}))
	playerListing.viewprofile:SetPosition(60+nudge_x,0,0)
	playerListing.viewprofile.scale_on_focus = false
	playerListing.viewprofile.image:SetScale(profile_scale)
	playerListing.viewprofile:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VIEWPROFILE, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
	local gainfocusfn = playerListing.viewprofile.OnGainFocus
	playerListing.viewprofile.OnGainFocus =
    function()
    	gainfocusfn(playerListing.viewprofile)
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
        playerListing.viewprofile.image:SetScale(profile_scale + profile_scale*.05)
    end
    local losefocusfn = playerListing.viewprofile.OnLoseFocus
	playerListing.viewprofile.OnLoseFocus =
    function()
    	losefocusfn(playerListing.viewprofile)
        playerListing.viewprofile.image:SetScale(profile_scale)
    end
	playerListing.viewprofile:SetOnClick(
		function()
			-- Can't do this here because HUD doesn't exist yet. TODO: add the playeravatarpopup to frontend, or wrap it in a screen.
			--ThePlayer.HUD:OpenPlayerAvatarPopup(displayName, v, true)
			if v.steamid then
				TheNet:ViewSteamProfile(v.steamid)
			end
		end)

	if empty or v.userid == owner then
		playerListing.viewprofile:Hide()
	end

	local mute_scale = .6
	playerListing.isMuted = TheFrontEnd.mutedPlayers ~= nil and TheFrontEnd.mutedPlayers[v.userid] and TheFrontEnd.mutedPlayers[v.userid] == true

	playerListing.mute = playerListing:AddChild(ImageButton("images/scoreboard.xml", "chat.tex", "chat.tex", "chat.tex", "chat.tex", nil, {1,1}, {0,0}))
	playerListing.mute:SetPosition(85+nudge_x,0,0)
	playerListing.mute.image:SetScale(mute_scale)
	playerListing.mute.scale_on_focus = false
	playerListing.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
	local gainfocusfn = playerListing.mute.OnGainFocus
	playerListing.mute.OnGainFocus =
        function()
        	gainfocusfn(playerListing.mute)
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            playerListing.mute.image:SetScale(mute_scale + .05)
        end
    local losefocusfn = playerListing.mute.OnLoseFocus
    playerListing.mute.OnLoseFocus =
        function()
        	losefocusfn(playerListing.mute)
            playerListing.mute.image:SetScale(mute_scale)
        end
    playerListing.mute:SetOnClick(
    	function()
    		if v.userid then
	    		playerListing.isMuted = not playerListing.isMuted
	    		if playerListing.isMuted then
	                if TheFrontEnd.mutedPlayers == nil then
	                    TheFrontEnd.mutedPlayers = { [v.userid] = true }
	                else
	                    TheFrontEnd.mutedPlayers[v.userid] = true
	                end
	    			playerListing.mute.image_focus = "mute.tex"
		        	playerListing.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
		        	playerListing.mute:SetTextures("images/scoreboard.xml", "mute.tex") 
		        	playerListing.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
		        	playerListing.mute.image:SetTint(242/255, 99/255, 99/255, 255/255)
	    		else
	                if TheFrontEnd.mutedPlayers ~= nil then
	                    TheFrontEnd.mutedPlayers[v.userid] = nil
	                    if next(TheFrontEnd.mutedPlayers) == nil then
	                        TheFrontEnd.mutedPlayers = nil
	                    end
	                end
	    			playerListing.mute.image_focus = "chat.tex"
		        	playerListing.mute.image:SetTexture("images/scoreboard.xml", "chat.tex")
		        	playerListing.mute:SetTextures("images/scoreboard.xml", "chat.tex") 
		        	playerListing.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE)
		        	playerListing.mute.image:SetTint(1,1,1,1)
	    		end
	    	end
    	end)
	
	if playerListing.isMuted then
		playerListing.mute.image_focus = "mute.tex"
    	playerListing.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
    	playerListing.mute:SetTextures("images/scoreboard.xml", "mute.tex") 
    	playerListing.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
    	playerListing.mute.image:SetTint(242/255, 99/255, 99/255, 255/255)
	end

	if empty or v.userid == owner then
		playerListing.mute:Hide()
	end

	playerListing.OnGainFocus = function()
		-- playerListing.name:SetSize(26)
		if not empty then
			playerListing.highlight:Show()
		end
	end
	playerListing.OnLoseFocus = function()
		-- playerListing.name:SetSize(21)
		playerListing.highlight:Hide()
	end

	doButtonFocusHookups(playerListing)

	return playerListing
end

local function UpdatePlayerListing(widget, data, index)
	local empty = data == nil
	if data then
		empty = #data > 0
	end

    local displayName = not empty and data.name or ""

	widget.userid = not empty and data.userid or nil

	if empty then
		widget.bg:Hide()
	else
		widget.bg:Show()
	end

	if empty then
		widget.characterBadge:Hide()
	else
		widget.characterBadge:Set(data.prefab or "", data.colour or DEFAULT_PLAYER_COLOUR, data.performance ~= nil, data.userflags or 0)
		widget.characterBadge:Show()
	end

	if not empty and data.admin then
		widget.adminBadge:Show()
	else
    	widget.adminBadge:Hide()
	end

	local colours = nil --GetAvailablePlayerColours()

	-- Testing only
	if colours then 
		widget.name:SetColour(unpack(colours[math.random(#colours)])) 
	else
		widget.name:SetColour(unpack(not empty and data.colour or DEFAULT_PLAYER_COLOUR))
	end
    widget.name:SetTruncatedString(displayName, widget.name._align.maxwidth, widget.name._align.maxchars, true)
    local w, h = widget.name:GetRegionSize()
    widget.name:SetPosition(widget.name._align.x + w * .5, widget.name._align.y, 0)

	local owner = TheNet:GetUserID()
	
	widget.viewprofile:SetOnClick(
		function()
			-- Can't do this here because HUD doesn't exist yet. TODO: add the playeravatarpopup to frontend, or wrap it in a screen.
			--ThePlayer.HUD:OpenPlayerAvatarPopup(displayName, data, true)
			if data.steamid then
				TheNet:ViewSteamProfile(data.steamid)
			end
		end)

	if empty or data.userid == owner then
		widget.viewprofile:Hide()
	else
		widget.viewprofile:Show()
	end

	widget.isMuted = TheFrontEnd.mutedPlayers ~= nil and TheFrontEnd.mutedPlayers[data.userid] and TheFrontEnd.mutedPlayers[data.userid] == true

    widget.mute:SetOnClick(
    	function()
    		if data.userid then
	    		widget.isMuted = not widget.isMuted
	    		if widget.isMuted then
	                if TheFrontEnd.mutedPlayers == nil then
	                    TheFrontEnd.mutedPlayers = { [data.userid] = true }
	                else
	                    TheFrontEnd.mutedPlayers[data.userid] = true
	                end
	    			widget.mute.image_focus = "mute.tex"
		        	widget.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
		        	widget.mute:SetTextures("images/scoreboard.xml", "mute.tex") 
		        	widget.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
		        	widget.mute.image:SetTint(242/255, 99/255, 99/255, 255/255)
	    		else
	                if TheFrontEnd.mutedPlayers ~= nil then
	                    TheFrontEnd.mutedPlayers[data.userid] = nil
	                    if next(TheFrontEnd.mutedPlayers) == nil then
	                        TheFrontEnd.mutedPlayers = nil
	                    end
	                end
	    			widget.mute.image_focus = "chat.tex"
		        	widget.mute.image:SetTexture("images/scoreboard.xml", "chat.tex")
		        	widget.mute:SetTextures("images/scoreboard.xml", "chat.tex") 
		        	widget.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE)
		        	widget.mute.image:SetTint(1,1,1,1)
	    		end
	    	end
    	end)
	
	if widget.isMuted then
		widget.mute.image_focus = "mute.tex"
    	widget.mute.image:SetTexture("images/scoreboard.xml", "mute.tex")
    	widget.mute:SetTextures("images/scoreboard.xml", "mute.tex")  
    	widget.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
    	widget.mute.image:SetTint(242/255, 99/255, 99/255, 255/255)
	else
		widget.mute.image_focus = "chat.tex"
    	widget.mute.image:SetTexture("images/scoreboard.xml", "chat.tex")
    	widget.mute:SetTextures("images/scoreboard.xml", "chat.tex") 
    	widget.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE)
    	widget.mute.image:SetTint(1,1,1,1)
	end

	if empty or data.userid == owner then
		widget.mute:Hide()
	end
end

function LobbyScreen:BuildPlayerList(players)
	if not self.player_list then 
		self.player_list = self.fixed_root:AddChild(Widget("player_list"))
    	self.player_list:SetPosition(190,RESOLUTION_Y-280,0)
    end

    if not self.upper_horizontal_line then 
	    self.upper_horizontal_line = self.player_list:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
	    self.upper_horizontal_line:SetScale(.7)
	    self.upper_horizontal_line:SetPosition(41, 115, 0)
	end

	if not self.players_number then 
	    self.players_number = self.player_list:AddChild(Text(NEWFONT, 20, "x/y"))
	    self.players_number:SetPosition(73, 128) 
	    self.players_number:SetRegionSize(100,20)
	    self.players_number:SetHAlign(ANCHOR_RIGHT)
	    self.players_number:SetColour(0, 0, 0, 1)
	end

    if players == nil then
        players = self:GetPlayerTable()
    end

	self.numPlayers = #players
	local maxPlayers = TheNet:GetServerMaxPlayers()
	self.players_number:SetString(self.numPlayers.."/"..(maxPlayers or "?"))

	if not self.scroll_list then
		self.list_root = self.player_list:AddChild(Widget("list_root"))
		self.list_root:SetPosition(90, -40)

		self.row_root = self.player_list:AddChild(Widget("row_root"))
		self.row_root:SetPosition(90, -40)

		self.player_widgets = {}
		for i=1,9 do
			table.insert(self.player_widgets, listingConstructor(players[i] or {}, i, self.row_root))
		end

		self.scroll_list = self.list_root:AddChild(ScrollableList(players, 125, 330, 30, 7, UpdatePlayerListing, self.player_widgets, nil, nil, nil, -15))
		self.scroll_list:LayOutStaticWidgets(-15)
		self.scroll_list:SetPosition(-10,-18)
	else
		self.scroll_list:SetList(players)
	end

	if not TheInput:ControllerAttached() then 
		self.invite_button = self.player_list:AddChild(TEMPLATES.Button(STRINGS.UI.LOBBYSCREEN.INVITE, function() TheNet:ViewSteamFriends() end))
		self.invite_button:SetPosition(45, -258)
		self.invite_button:SetScale(.7)
	end
end

function LobbyScreen:BuildTabbedWindow()
	self.tabbed_frame = self.fixed_root:AddChild(TEMPLATES.CurlyWindow(10, 400, .6, .6, 40, -25))
    self.tabbed_frame:SetPosition(215,RESOLUTION_Y-310,0)

	self.tabbed_bg = self.tabbed_frame:AddChild(Image("images/serverbrowser.xml", "side_panel.tex"))
	self.tabbed_bg:SetScale(.66, .56)
	self.tabbed_bg:SetPosition(2, -15)

	self.players_button = self.tabbed_frame:AddChild(TEMPLATES.TabButton(-58, 193, STRINGS.UI.LOBBYSCREEN.PLAYERLIST, function() self:ToggleShowPlayers(true) end, "large"))
	self.chat_button = self.tabbed_frame:AddChild(TEMPLATES.TabButton(71, 193, STRINGS.UI.LOBBYSCREEN.CHAT, function() self:ToggleShowPlayers(false) end, "large"))
	self.message_indicator = self.chat_button:AddChild(Image("images/frontend.xml", "circle_red.tex"))
	self.message_indicator:SetScale(.53)
	self.message_indicator:SetPosition(45, 10)
	self.message_indicator:SetClickable(false)
	self.message_indicator.count = self.message_indicator:AddChild(Text(BUTTONFONT, 30, ""))
    self.message_indicator.count:SetColour(0,0,0,1)
    self.message_indicator.count:SetPosition(2,0)
	self.unread_count = 0
	self.message_indicator:Hide()
	
	self:BuildPlayerList()
	self:BuildChatWindow()

	self:ToggleShowPlayers(true)
end

function LobbyScreen:ToggleShowPlayers(val)
	if val then 
		self.active_tab = "players"
		self.player_list:Show()
		self.chat_pane:Hide()
		self.players_button:Disable()
		self.chat_button:Enable()

		self.scroll_list:SetFocus()
	else
		self.active_tab = "chat"
		self.player_list:Hide()
		self.chat_pane:Show()
		self.chat_button:Disable()
		self.players_button:Enable()
		self.chatqueue:SetFocus()
		self.chatqueue:ScrollToEnd()
		self:UpdateMessageIndicator()
        self.chatbox.textbox:SetEditing(true)
	end

	self:DoFocusHookups()
end

function LobbyScreen:UpdateMessageIndicator()
	if self.active_tab ~= "chat" then
		self.unread_count = self.unread_count + 1
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/chat_receive")
		self.message_indicator:Show()
		self.message_indicator.count:SetString(self.unread_count)
	else
		self.unread_count = 0
		self.message_indicator:Hide()
	end
end

local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"<>]]

function LobbyScreen:MakeTextEntryBox(parent)
	local chatbox = parent:AddChild(Widget("chatbox"))
    chatbox.bg = chatbox:AddChild( Image("images/textboxes.xml", "textbox2_small_grey.tex") )
    local box_size = 210
    local box_y = 25
    local nudgex = 60
    local nudgey = -20
    chatbox.bg:ScaleToSize( box_size, box_y + 10 )
    chatbox.textbox = chatbox:AddChild(TextEdit( NEWFONT, 20, nil, {0,0,0,1} ) )
    chatbox.textbox:SetForceEdit(true)
    chatbox.bg:SetPosition((box_size * .5) - 100 + 25 + nudgex, 8 + nudgey, 0)
    chatbox.textbox:SetPosition((box_size * .5) - 100 + 26 + nudgex, 8 + nudgey, 0)
    chatbox.textbox:SetRegionSize( box_size - 23, box_y )
    chatbox.textbox:SetHAlign(ANCHOR_LEFT)
    chatbox.textbox:SetVAlign(ANCHOR_MIDDLE)
    chatbox.textbox:SetFocusedImage( chatbox.bg, "images/textboxes.xml", "textbox2_small_grey.tex", "textbox2_small_gold.tex", "textbox2_small_gold_greyfill.tex" )
    chatbox.textbox:SetTextLengthLimit( 200 )
    chatbox.textbox:SetCharacterFilter( VALID_CHARS )
    chatbox.textbox:EnableWordWrap(false)
    chatbox.textbox:EnableScrollEditWindow(true)
    chatbox.gobutton = chatbox:AddChild(ImageButton("images/lobbyscreen.xml", "button_send.tex", "button_send_over.tex", "button_send_down.tex", "button_send_down.tex", "button_send_down.tex", {1,1}, {0,0}))
    chatbox.gobutton:SetPosition(box_size - 59 + nudgex, 8 + nudgey)
    chatbox.gobutton:SetScale(.13)
    chatbox.gobutton.image:SetTint(.6,.6,.6,1)
    chatbox.textbox.OnTextEntered = function()
        TheNet:Say(self.chatbox.textbox:GetString(), false)
        self.chatbox.textbox:SetString("")
        self.chatbox.textbox:SetEditing(true)
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/chat_send")
    end
    chatbox.gobutton:SetOnClick( function() self.chatbox.textbox:OnTextEntered() end )

    chatbox:SetPosition(-64, -202)
    self.chatbox = chatbox
end

function LobbyScreen:BuildChatWindow()
	self.chat_pane = self.fixed_root:AddChild(Widget("chat_pane"))

    self.upper_horizontal_line = self.chat_pane:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
    self.upper_horizontal_line:SetScale(.7)
    self.upper_horizontal_line:SetPosition(41, 137, 0)

    self.lower_horizontal_line = self.chat_pane:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
    self.lower_horizontal_line:SetScale(.72)
    self.lower_horizontal_line:SetPosition(38, -189, 0)

    -- self.left_vertical_line = self.chat_pane:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    -- self.left_vertical_line:SetScale(.45, .41)
    -- self.left_vertical_line:SetPosition(-70, -34, 0)

    -- self.right_vertical_line = self.chat_pane:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    -- self.right_vertical_line:SetScale(.45, .41)
    -- self.right_vertical_line:SetPosition(130, -34, 0)

    self:MakeTextEntryBox(self.chat_pane)

    self.chatqueue = self.chat_pane:AddChild(LobbyChatQueue(TheNet:GetUserID(), self.chatbox.textbox, function() self:UpdateMessageIndicator() end))
    self.chatqueue:SetPosition(32,2) 

	self.chat_pane:SetPosition(190,RESOLUTION_Y-280,0)
end

function LobbyScreen:BuildCharacterDetailsBoxAndPanels()
	self.character_details = self.fixed_root:AddChild(Widget("character_details"))

	self.biobox = self.fixed_root:AddChild(Image("images/lobbybannerbottom.xml", "banner_bottom.tex"))
	self.biobox:SetScale(.67)

	-- Note: these windows must be built in between the two banner sections or the banner won't 
	-- layer properly.
	self:BuildTabbedWindow()
    --self:BuildDressupWindow()
    self.dressup = self.fixed_root:AddChild(DressupPanel(self, self.profile, function() self:SetPortraitImage(1) end, function() self:SetPortraitImage(-1) end))

	self.banner_front = self.fixed_root:AddChild(Image("images/lobbybannertop.xml", "banner_top.tex"))
	self.banner_front:SetScale(.67, .72)
	self.banner_front:SetClickable(false)

	self.banner_frontleft = self.fixed_root:AddChild(Image("images/lobbybannertop.xml", "banner_topleft.tex"))
	self.banner_frontleft:SetScale(.67)
	self.banner_frontleft:SetClickable(false)

	self.banner_frontright = self.fixed_root:AddChild(Image("images/lobbybannertop.xml", "banner_topright.tex"))
	self.banner_frontright:SetScale(.67)
	self.banner_frontright:SetClickable(false)

 
    self.biobox:SetPosition(RESOLUTION_X/2 - 20, RESOLUTION_Y/2 - 8)
    self.banner_front:SetPosition(RESOLUTION_X/2 - 20, RESOLUTION_Y/2 - 223)
    
    self.banner_frontleft:SetPosition(RESOLUTION_X/2 - 570, RESOLUTION_Y/2 + 27)
    self.banner_frontright:SetPosition(RESOLUTION_X/2 + 535, RESOLUTION_Y/2 - 74)

    self.banner_front:SetClickable(false)
    self.banner_frontleft:SetClickable(false)
    self.banner_frontright:SetClickable(false)
  
    self.charactername = self.character_details:AddChild(Text(TALKINGFONT, 35))
    self.charactername:SetHAlign(ANCHOR_MIDDLE)
    self.charactername:SetPosition(203, 15) 
	self.charactername:SetRegionSize( 500, 70 )
	self.charactername:SetColour(PORTAL_TEXT_COLOUR[1], PORTAL_TEXT_COLOUR[2], PORTAL_TEXT_COLOUR[3], PORTAL_TEXT_COLOUR[4])

    self.characterquote = self.character_details:AddChild(Text(NEWFONT_OUTLINE, 25))
    self.characterquote:SetHAlign(ANCHOR_MIDDLE)
    self.characterquote:SetVAlign(ANCHOR_TOP)
    self.characterquote:SetPosition(203, -32) 
	self.characterquote:SetRegionSize( 500, 60 )
	self.characterquote:EnableWordWrap( true )
	self.characterquote:SetString( "" )
	self.characterquote:SetColour(PORTAL_TEXT_COLOUR[1], PORTAL_TEXT_COLOUR[2], PORTAL_TEXT_COLOUR[3], PORTAL_TEXT_COLOUR[4])

    self.characterdetails = self.character_details:AddChild(Text(NEWFONT_OUTLINE, 26))
    self.characterdetails:SetHAlign(ANCHOR_MIDDLE)
    self.characterdetails:SetVAlign(ANCHOR_TOP)
    self.characterdetails:SetPosition(203, -89) 
	self.characterdetails:SetRegionSize( 600, 120 )
	self.characterdetails:EnableWordWrap( true )
	self.characterdetails:SetString( "" )
	self.characterdetails:SetColour(GOLD[1], GOLD[2], GOLD[3], GOLD[4])

	self.character_details:SetPosition(RESOLUTION_X/2 - 220,RESOLUTION_Y/2 - 200)
	self.character_details:MoveToFront()
end

function LobbyScreen:BuildCharactersList(cb, default_character)
	self.character_scroll_list = self.fixed_root:AddChild(Widget("character_scroll_list"))

	self.characters = ExceptionArrays(GetActiveCharacterList(), MODCHARACTEREXCEPTIONS_DST)
	table.insert(self.characters, "random")

    self.left_arrow = self.fixed_root:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_L.tex", "DSTMenu_PlayerLobby_arrow_paperHL_L.tex", nil, nil, nil, {1,1}, {0,0}))
    self.left_arrow:SetScale(.7)
   	self.left_arrow:SetPosition(RESOLUTION_X/2 - 205, RESOLUTION_Y/2+55)
   	self.left_arrow:SetOnClick( function() self:OnClickPortrait(1) end)

   	self.right_arrow = self.fixed_root:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_R.tex", "DSTMenu_PlayerLobby_arrow_paperHL_R.tex", nil, nil, nil, {1,1}, {0,0}))
   	self.right_arrow:SetScale(.7)
   	self.right_arrow:SetPosition(RESOLUTION_X/2 + 183, RESOLUTION_Y/2+55)
   	self.right_arrow:SetOnClick( function() self:OnClickPortrait(2) end)

   	if TheInput:ControllerAttached() then 
   		self.left_arrow:SetClickable(false)
   		self.right_arrow:SetClickable(false)
   	end

	
    self:SetOffset(-1)
    self:SelectPortrait(1)
    self.cb = function(char, skin_base, clothing_body, clothing_hand, clothing_legs)
        self:StopLobbyMusic()
    	cb(char, skin_base, clothing_body, clothing_hand, clothing_legs)
    end
    
    self:SelectCharacter(default_character)
    self.character_scroll_list:SetScale(.7, .7, 1)
    self.character_scroll_list:SetPosition(189, 150)
end

function LobbyScreen:OnClickPortrait(portrait)
	if portrait == 1 then 
		self:SelectAndScroll(-1)
	elseif portrait == 2 then 
		self:SelectAndScroll(1)
	else 
		print("Unknown portrait number", portrait or "nil", debugstack())
	end
end

function LobbyScreen:SelectCharacter(character)
	for k,v in ipairs(self.characters) do
		if v == character then
			self:SetOffset(k-1)
			self:SelectPortrait(1)
		end
	end
end

function LobbyScreen:SelectRandomCharacter()
	for k,v in ipairs(self.characters) do
		if v == "random" then
			self:SetOffset(k-2)
			self:SelectPortrait(1)
		end
	end
end

function LobbyScreen:Scroll(scroll)
	self:SetOffset( self.offset + scroll )
end

function LobbyScreen:SelectAndScroll(dir)
	if dir < 0 then
		self:SetOffset( self.offset - 1 )
		self:SelectPortrait(1)
		return true
	elseif dir > 0 then
		self:SetOffset( self.offset + 1 )
		self:SelectPortrait(2)
		return true
	end
	return false
end

function LobbyScreen:GetCharacterIdxForPortrait()
	local idx = 1

	idx = self.offset + 1

	if idx > #self.characters then 
		idx = idx - #self.characters
	end

	return idx
end


function LobbyScreen:SetOffset(offset)
	self.offset = offset

	-- Loop the offsets instead of using negative values
	if self.offset < 0 then 
		self.offset = #self.characters + offset
	elseif self.offset > (#self.characters - 1) then 
		self.offset = offset - #self.characters
	end
end


function LobbyScreen:OnControl(control, down)
    
    if LobbyScreen._base.OnControl(self, control, down) then return true end

    if self.chatbox and ((self.chatbox.textbox and self.chatbox.textbox.editing) or (TheInput:ControllerAttached() and self.chatbox.focus and control == CONTROL_ACCEPT)) then
        self.chatbox.textbox:OnControl(control, down)
        return true
    end

    if not self.no_cancel and
    	not down and control == CONTROL_CANCEL then 
		self:DoConfirmQuit()
		return true 
    end

    if  TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse and 
    	self.can_accept and not down and control == CONTROL_PAUSE then
    	StartGame(self)
		--if self.cb then
		--	self.cb(self.currentcharacter, nil) --2nd parameter is skin
		--end
		return true
    end

    -- Use d-pad buttons for cycling players list
    -- Add trigger buttons to switch tabs
   	if not down then 
	 	if control == CONTROL_OPEN_CRAFTING or control == CONTROL_OPEN_INVENTORY then -- LT / RT
	 		if self.active_tab == "players" then
	 			self:ToggleShowPlayers(false)
	 		elseif self.active_tab == "chat" then
	 			self:ToggleShowPlayers(true)
	 		end
	 		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
	        return true 
	    elseif control == CONTROL_FOCUS_LEFT then  -- d-pad left
	    	self:Scroll(-1)
			self:SelectPortrait()
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			return true 
		elseif control == CONTROL_FOCUS_RIGHT then -- d-pad right
			self:Scroll(1)
			self:SelectPortrait()
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			return true
		elseif control == CONTROL_MENU_MISC_2 then
			self:SelectRandomCharacter()
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			return true
	    end
	end

	-- DEBUG ONLY:
	if not down and DEBUG_MODE then 
		if control == CONTROL_FOCUS_UP then 
			self.chatqueue:OnMessageReceived("OU_76561197968176071", "Eliza", "willow", 
											"alpha beta charlie delta foxtrot gamma housecat iguana jaguar koala limbo mustache norton ophelia periwinkle", 
											{.3,.8,.2,1})
		end
	end

	return false
end


function LobbyScreen:DoFocusHookups()

	-- placeholder

end


function LobbyScreen:DoConfirmQuit() 	
 	self.active = false
	
	local function doquit()
		self.dressup:OnClose()
		self.parent:Disable()
		DoRestart(true)
	end

	if TheNet:GetIsServer() then
		local confirm = PopupDialogScreen(STRINGS.UI.LOBBYSCREEN.HOSTQUITTITLE, STRINGS.UI.LOBBYSCREEN.HOSTQUITBODY, {{text=STRINGS.UI.LOBBYSCREEN.YES, cb = doquit},{text=STRINGS.UI.LOBBYSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
	    if JapaneseOnPS4() then
			confirm:SetTitleTextSize(40)
			confirm:SetButtonTextSize(30)
		end
		TheFrontEnd:PushScreen(confirm)
	else
		local confirm = PopupDialogScreen(STRINGS.UI.LOBBYSCREEN.CLIENTQUITTITLE, STRINGS.UI.LOBBYSCREEN.CLIENTQUITBODY, {{text=STRINGS.UI.LOBBYSCREEN.YES, cb = doquit},{text=STRINGS.UI.LOBBYSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
	    if JapaneseOnPS4() then
			confirm:SetTitleTextSize(40)
			confirm:SetButtonTextSize(30)
		end
		TheFrontEnd:PushScreen( confirm )
	end
end


--[[function LobbyScreen:OnFocusMove(dir, down)
	
	if down then
		if dir == MOVE_LEFT then
				self:Scroll(-1)
				self:SelectPortrait()
			return true
		elseif dir == MOVE_RIGHT then
				self:Scroll(1)	
				self:SelectPortrait()
			return true
		end
	end
end]]



-- Dir should be +1 for right and -1 for left
function LobbyScreen:SetPortraitImage(dir)

	local which = self.dressup.base_spinner and (self.dressup.base_spinner.spinner:GetSelectedIndex() + dir) or 1
	
	if self.currentcharacter ~= "random" and self.dressup.currentcharacter_skins then
		local name = self.dressup.currentcharacter_skins[which] 
		self.heroportrait:SetTexture("bigportraits/"..self.currentcharacter..".xml", name..".tex")
	else
		self.heroportrait:SetTexture("bigportraits/"..self.currentcharacter..".xml", self.currentcharacter.."_none.tex")
	end

	self.dressup:UpdatePuppet()
end

function LobbyScreen:SelectPortrait()
	local heroidx = self:GetCharacterIdxForPortrait(1) + 1
	if heroidx < 1 then 
		heroidx = #self.characters + heroidx
	elseif heroidx > #self.characters then 
		heroidx = heroidx - #self.characters
	end

	local herocharacter = self.characters[heroidx]

	if herocharacter ~= nil then
		local charlist = GetActiveCharacterList()
		table.insert(charlist, "random")
		if table.contains(charlist, herocharacter) then
			local skin = "_none"

			self.heroportrait:SetTexture("bigportraits/" .. herocharacter..".xml", herocharacter .. skin .. ".tex", herocharacter .. ".tex")
		else
			self.heroportrait:SetTexture("bigportraits/" .. herocharacter..".xml", herocharacter.. ".tex", herocharacter .. ".tex")
		end

		--print("Current character set to ", herocharacter)
		self.currentcharacter = herocharacter
		self.dressup:SetCurrentCharacter(herocharacter)
		
		if self.charactername then 
			self.charactername:SetString(STRINGS.CHARACTER_TITLES[herocharacter] or "")
		end
		if self.characterquote then 
			self.characterquote:SetString(STRINGS.CHARACTER_QUOTES[herocharacter] or "")
		end
		if self.characterdetails then 
			if herocharacter == "woodie" and TheNet:GetCountryCode() == "CA" then
				self.characterdetails:SetString(STRINGS.CHARACTER_DESCRIPTIONS[herocharacter.."_canada"] or "")
			elseif herocharacter == "woodie" and TheNet:GetCountryCode() == "US" then
				self.characterdetails:SetString(STRINGS.CHARACTER_DESCRIPTIONS[herocharacter.."_us"] or "")
			else
				self.characterdetails:SetString(STRINGS.CHARACTER_DESCRIPTIONS[herocharacter] or "")
			end

			
		end
		--self.currentcharacter_skins = self.profile:GetSkinsForPrefab(herocharacter)


		self.dressup:UpdateSpinners()
		
		self.can_accept = true
		if self.startbutton ~= nil then
			self.startbutton:Enable()
		end
	else
		-- THIS SHOULD NEVER HAPPEN IN DST
		self.can_accept = false
		self.heroportrait:SetTexture("bigportraits/locked.xml", "locked.tex")
		self.charactername:SetString(STRINGS.CHARACTER_NAMES.unknown)
		self.characterquote:SetString("")
		self.characterdetails:SetString("")
		if self.startbutton then
			self.startbutton:Disable()
		end
	end
end

function LobbyScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
    
    if not self.no_cancel then
    	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.LOBBYSCREEN.DISCONNECT)
    end
 
    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_CRAFTING) .. "/".. TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_INVENTORY) .." " .. STRINGS.UI.HELP.CHANGE_TAB)

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_2) .. " " .. STRINGS.UI.LOBBYSCREEN.RANDOMCHAR)
    
  	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_FOCUS_LEFT) .. "/" .. TheInput:GetLocalizedControl(controller_id, CONTROL_FOCUS_RIGHT) .." " .. STRINGS.UI.HELP.CHANGECHARACTER)
   
   	if self.can_accept then
   		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.LOBBYSCREEN.SELECT)
   	end
    
    return table.concat(t, "  ")
end

function LobbyScreen:GetPlayerTable()
    local ClientObjs = TheNet:GetClientTable()
    if ClientObjs == nil then
        return {}
    elseif not TheNet:GetServerIsDedicated() then
        return ClientObjs
    end

    --remove dedicate host from player list
    for i, v in ipairs(ClientObjs) do
        if v.performance ~= nil then
            table.remove(ClientObjs, i)
            break
        end
    end
    return ClientObjs
end

function LobbyScreen:OnUpdate(dt)
    if self.time_to_refresh > dt then
        self.time_to_refresh = self.time_to_refresh - dt
    else
        self.time_to_refresh = REFRESH_INTERVAL

        local players = self:GetPlayerTable()
        if #players ~= self.numPlayers then
            --rebuild if player count changed
            self:BuildPlayerList(players)
        else
            --rebuild if players changed even though count didn't change
            for i, v in ipairs(players) do
                local listitem = self.scroll_list.items[i]
                if listitem == nil or
                    v.userid ~= listitem.userid or
                    (v.performance ~= nil) ~= (listitem.performance ~= nil) then
                    self:BuildPlayerList(players)
                    return
                end
            end

            --refresh existing players
            for i, widget in ipairs(self.player_widgets) do
                for i2, data in ipairs(players) do
                    if widget.userid == data.userid and widget.characterBadge.ishost == (data.performance ~= nil) then
                        widget.characterBadge:Set(data.prefab or "", data.colour or DEFAULT_PLAYER_COLOUR, widget.characterBadge.ishost, data.userflags or 0)
                    end
                end
            end
        end
    end
end

function LobbyScreen:UpdateSpinners()
	self.dressup:UpdateSpinners()
	self:SetPortraitImage(0)
end


return LobbyScreen
