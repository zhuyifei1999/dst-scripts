local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local LobbyChatQueue = require "widgets/lobbychatqueue"
local PlayerBadge = require "widgets/playerbadge"
local ScrollableList = require "widgets/scrollablelist"
local TEMPLATES = require "widgets/templates"



local function doButtonFocusHookups(playerListing, nextWidgets)
		
	local rightFocusMoveSet = false

	if playerListing.mute:IsVisible() then
		playerListing.mute:SetFocusChangeDir(MOVE_LEFT, playerListing.viewprofile)
		playerListing.mute:SetFocusChangeDir(MOVE_RIGHT, nextWidgets.right)
		playerListing.mute:SetFocusChangeDir(MOVE_DOWN, nextWidgets.down)
		rightFocusMoveSet = true
		playerListing.focus_forward = playerListing.mute
	end

	if playerListing.viewprofile:IsVisible() then
		if playerListing.mute:IsVisible() then 
			playerListing.viewprofile:SetFocusChangeDir(MOVE_RIGHT, playerListing.mute)
		else
			playerListing.viewprofile:SetFocusChangeDir(MOVE_RIGHT, nextWidgets.right)
		end
		rightFocusMoveSet = true

		playerListing.focus_forward:SetFocusChangeDir(MOVE_DOWN, nextWidgets.down)
		playerListing.focus_forward = playerListing.viewprofile
	end

	if not rightFocusMoveSet then 
		playerListing:SetFocusChangeDir(MOVE_RIGHT, nextWidgets.right)
	end

	playerListing:SetFocusChangeDir(MOVE_DOWN, nextWidgets.down)
end



local function listingConstructor(v, i, parent, nextWidgets)

	local playerListing =  parent:AddChild(Widget("playerListing"))
	playerListing:SetPosition(5,0)

	local empty = v == nil
	if v then
		empty = #v > 0
	end

    local displayName = not empty and v.name or ""

	playerListing.userid = not empty and v.userid or nil

	local nudge_x = -5
	local name_badge_nudge_x = 15

    playerListing.bg = playerListing:AddChild(Image("images/ui.xml", "blank.tex"))
    playerListing.bg:SetPosition(15+nudge_x+name_badge_nudge_x, 0)
    playerListing.bg:ScaleToSize(196,48)
    playerListing.bg:SetTint(1, 1, 1, (i % 2) == 0 and .85 or .5)
	if empty then
		playerListing.bg:Hide()
	end

	playerListing.highlight = playerListing:AddChild(Image("images/scoreboard.xml", "row_short_goldoutline.tex"))
    playerListing.highlight:SetPosition(8+nudge_x+name_badge_nudge_x, 0)
    playerListing.highlight:ScaleToSize(183,50)
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
	playerListing.characterBadge:SetPosition(-77+nudge_x+name_badge_nudge_x,0,0)

	playerListing.adminBadge = playerListing:AddChild(ImageButton("images/avatars.xml", "avatar_admin.tex", "avatar_admin.tex", "avatar_admin.tex", nil, nil, {1,1}, {0,0}))
	playerListing.adminBadge:Disable()
	playerListing.adminBadge:SetPosition(-89+nudge_x+name_badge_nudge_x,-10,0)	
	playerListing.adminBadge.image:SetScale(.18)
	playerListing.adminBadge.scale_on_focus = false
    playerListing.adminBadge:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.ADMIN, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
	if empty or not v.admin then
    	playerListing.adminBadge:Hide()
	end

	local colours = nil --GetAvailablePlayerColours()

    playerListing.name = playerListing:AddChild(Text(TALKINGFONT, 24))
    playerListing.name._align =
    {
        maxwidth = 100,
        maxchars = 22,
        x = -52 + nudge_x+name_badge_nudge_x,
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
			if v.netid ~= nil then
				TheNet:ViewNetProfile(v.netid)
			end
		end)

	if empty or v.userid == owner or not TheNet:IsNetIDPlatformValid(v.netid) then
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

	doButtonFocusHookups(playerListing, nextWidgets)

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
			if data.netid ~= nil then
				TheNet:ViewNetProfile(data.netid)
			end
		end)

	if empty or data.userid == owner or not TheNet:IsNetIDPlatformValid(data.netid) then
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


--------------------------------------------------------------------------
--	A list of players for the lobby screen
--
local PlayerList = Class(Widget, function(self, owner, nextWidgets)
	self.owner = owner
	Widget._ctor(self, "PlayerList")

	self.proot = self:AddChild(Widget("ROOT"))
    
    self:BuildPlayerList(nil, nextWidgets)

    self.focus_forward = self.scroll_list
end)


function PlayerList:BuildPlayerList(players, nextWidgets)
	if not self.player_list then 
		self.player_list = self.proot:AddChild(Widget("player_list"))
    	self.player_list:SetPosition(75,RESOLUTION_Y-185,0)
    end

    if not self.title then 
    	self.title = self.player_list:AddChild(Text( UIFONT, 35, STRINGS.UI.LOBBYSCREEN.PLAYERLIST, GOLD))
    	self.title:SetPosition(-20, 162)
    end

    if not self.bg then 
    	self.bg = self.player_list:AddChild(Image("images/lobbyscreen.xml", "playerlobby_whitebg_chat.tex"))
    	self.bg:SetScale(.785, .46)
    	self.bg:SetTint(1,1,1,.65)
    	self.bg:SetPosition(60, 18)
    end

    if not self.upper_horizontal_line then 
	    self.upper_horizontal_line = self.player_list:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
	    self.upper_horizontal_line:SetScale(.66, .2)
	    self.upper_horizontal_line:SetPosition(57, 115, 0)
	end

	if not self.right_line then 
		self.right_line = self.player_list:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
		self.right_line:SetScale(.5, .3)
		self.right_line:SetPosition(170, 18)
	end

	if not self.left_line then 
		self.left_line = self.player_list:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
		self.left_line:SetScale(.5, .3)
		self.left_line:SetPosition(-55, 18)
	end

	if not self.lower_horizontal_line then 
	    self.lower_horizontal_line = self.player_list:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
	    self.lower_horizontal_line:SetScale(.66, .2)
	    self.lower_horizontal_line:SetPosition(57, -75, 0)
	end

	if not self.players_number then 
	    self.players_number = self.player_list:AddChild(Text(NEWFONT, 20, "x/y"))
	    self.players_number:SetPosition(73, 100) 
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
		self.list_root:SetPosition(90, 5)

		self.row_root = self.player_list:AddChild(Widget("row_root"))
		self.row_root:SetPosition(90, 35)

		self.player_widgets = {}
		for i=1,4 do
			table.insert(self.player_widgets, listingConstructor(players[i] or {}, i, self.row_root, nextWidgets))
		end

		self.scroll_list = self.list_root:AddChild(ScrollableList(players, 125, 130, 30, 7, UpdatePlayerListing, self.player_widgets, 7, nil, nil, -15, .8))
		self.scroll_list:LayOutStaticWidgets(-15)
		self.scroll_list:SetPosition(0,0)
	else
		self.scroll_list:SetList(players)
	end

end


local testdata = {
		{
			name = "Harry",
			userid = 0123456,
			prefab = "wilson"
		},
		{
			name = "Ginny",
			userid = 0123456,
			prefab = "willow",
		},
		{
			name = "Ron",
			userid = 8900876,
			prefab = "woodie"
		},
		{
			name = "Hermione",
			userid = 4950980709,
			prefab = "wickerbottom"
		},
		{
			name = "Luna",
			userid = 23456909090,
			prefab = "wendy",
		},
		{
			name = "Hagrid",
			userid = 1234253452,
			prefab = "wolfgang",
		},
		{
			name = "Dumbledore",
			userid = 0293845032948,
			prefab = "wes"
		},
	}

function PlayerList:GetPlayerTable()
	-- Testing
	
	--return testdata
	

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



return PlayerList
