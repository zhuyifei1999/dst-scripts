require "util"
local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local PlayerBadge = require "widgets/playerbadge"
local PopupDialogScreen = require "screens/popupdialog"
local ScrollableList = require "widgets/scrollablelist"

local BAN_ENABLED = true

local list_spacing = 82.5

local PERF_HOST_SCALE = { 1, 1, 1 }
local PERF_HOST_UNKNOWN = "host_indicator.tex"
local PERF_HOST_LEVELS =
{
    "host_indicator3.tex", --GOOD
    "host_indicator2.tex", --OK
    "host_indicator1.tex", --BAD
}

local PERF_CLIENT_SCALE = { .9, .9, .9 }
local PERF_CLIENT_UNKNOWN = "performance_indicator.tex"
local PERF_CLIENT_LEVELS =
{
    "performance_indicator3.tex", --GOOD
    "performance_indicator2.tex", --OK
    "performance_indicator1.tex", --BAD
}

local REFRESH_INTERVAL = .5

local PlayerStatusScreen = Class(Screen, function(self, owner)
    Screen._ctor(self, "PlayerStatusScreen")
    self.owner = owner
    self.default_focus = self.scroll_list
    self.time_to_refresh = REFRESH_INTERVAL
end)

function PlayerStatusScreen:OnBecomeActive()
	PlayerStatusScreen._base.OnBecomeActive(self)
	self:DoInit()
	self.time_to_refresh = REFRESH_INTERVAL
	self.scroll_list:SetFocus()
end

function PlayerStatusScreen:OnDestroy()
    --Overridden so we do part of Widget:Kill()
    --but keeps the screen around hidden
    self:StopFollowMouse()
    self:Hide()
end

function PlayerStatusScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_TOGGLE_PLAYER_STATUS) .. " " .. STRINGS.UI.HELP.BACK)
	
	if self.server_group ~= "" then
		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_2) .. " " .. STRINGS.UI.HELP.VIEWGROUP)
	end
	
    return table.concat(t, "  ")
end

function PlayerStatusScreen:OnControl(control, down)
    if not self:IsVisible() then
        return false
    elseif PlayerStatusScreen._base.OnControl(self, control, down) then
        return true
    elseif control == CONTROL_OPEN_DEBUG_MENU then
        --jcheng: don't allow debug menu stuff going on right now
        return true
    elseif not down then
        if (control == CONTROL_SHOW_PLAYER_STATUS
            or (control == CONTROL_TOGGLE_PLAYER_STATUS and
                not TheInput:IsControlPressed(CONTROL_SHOW_PLAYER_STATUS))) then
            self:Close()
            return true
        elseif control == CONTROL_MENU_MISC_2 and self.server_group ~= "" then
            TheNet:ViewNetProfile(self.server_group)
            return true
        end
    end
end

function PlayerStatusScreen:OnRawKey(key, down)
	if not self:IsVisible() then
		return false
	end

	if PlayerStatusScreen._base.OnRawKey(self, key, down) then return true end
	
	if down then return end
	
	return true
end

function PlayerStatusScreen:Close()
	TheInput:EnableDebugToggle(true)
	TheFrontEnd:PopScreen(self)
end

function PlayerStatusScreen:OnUpdate(dt)
    if self.time_to_refresh > dt then
        self.time_to_refresh = self.time_to_refresh - dt
    else
        self.time_to_refresh = REFRESH_INTERVAL

        local ClientObjs = TheNet:GetClientTable() or {}

        --rebuild if player count changed
        local needs_rebuild = #ClientObjs ~= self.numPlayers

        --rebuild if players changed even though count didn't change
        if not needs_rebuild and self.scroll_list ~= nil then
            for i, v in ipairs(ClientObjs) do
                local listitem = self.scroll_list.items[i]
                if listitem == nil or
                    v.userid ~= listitem.userid or
                    (v.performance ~= nil) ~= (listitem.performance ~= nil) then
                    needs_rebuild = true
                    break
                end
            end
        end

        if needs_rebuild then
            -- We've either added or removed a player
            -- Kill everything and re-init
            self:DoInit(ClientObjs)
        else
            if self.serverstate and self.serverage and self.serverage ~= TheWorld.state.cycles + 1 then
                self.serverage = TheWorld.state.cycles + 1
                local modeStr = GetGameModeString(TheNet:GetServerGameMode()) ~= nil and GetGameModeString(TheNet:GetServerGameMode()).." - " or ""
                self.serverstate:SetString(modeStr.." "..STRINGS.UI.PLAYERSTATUSSCREEN.AGE_PREFIX..self.serverage)
            end

            if self.scroll_list ~= nil then
                for i,v in pairs(self.player_widgets) do
                    for j,k in ipairs(ClientObjs) do
                        if v.userid == k.userid and v.ishost == (k.performance ~= nil) then
                            v.name:SetTruncatedString(self:GetDisplayName(k), v.name._align.maxwidth, v.name._align.maxchars, true)
                            local w, h = v.name:GetRegionSize()
                            v.name:SetPosition(v.name._align.x + w * .5, 0, 0)

                            v.characterBadge:Set(k.prefab or "", k.colour or DEFAULT_PLAYER_COLOUR, v.ishost, k.userflags or 0)

                            if v.characterBadge:IsAFK() then
                                v.age:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.AFK)
                            else
                                v.age:SetString(k.playerage ~= nil and k.playerage > 0 and (tostring(k.playerage)..(k.playerage == 1 and STRINGS.UI.PLAYERSTATUSSCREEN.AGE_DAY or STRINGS.UI.PLAYERSTATUSSCREEN.AGE_DAYS)) or "")
                            end

                            if k.performance ~= nil then
                                v.perf:SetTexture("images/scoreboard.xml", PERF_HOST_LEVELS[math.min(k.performance + 1, #PERF_HOST_LEVELS)])
                            elseif k.netscore ~= nil then
                                v.perf:SetTexture("images/scoreboard.xml", PERF_CLIENT_LEVELS[math.min(k.netscore + 1, #PERF_CLIENT_LEVELS)])
                            else
                                v.perf:SetTexture("images/scoreboard.xml", PERF_CLIENT_UNKNOWN)
                            end
                        end
                    end
                end
            end
        end
    end
end

function PlayerStatusScreen:GetDisplayName(clientrecord)
    return clientrecord.name or ""
end

function PlayerStatusScreen:DoInit(ClientObjs)

	TheInput:EnableDebugToggle(false)

	if not self.root then
		self.root = self:AddChild(Widget(""))
	    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	    self.root:SetHAnchor(ANCHOR_MIDDLE)
	    self.root:SetVAnchor(ANCHOR_MIDDLE)
	end

	if not self.bg then
		self.bg = self.root:AddChild(Image( "images/scoreboard.xml", "scoreboard_frame.tex" ))
		self.bg:SetScale(.95,.9)
	end

	local serverNameStr = TheNet:GetServerName()
	if not self.servertitle then
		self.servertitle = self.root:AddChild(Text(UIFONT,45))
		self.servertitle:SetColour(1,1,1,1)
    end
    if serverNameStr ~= "" then
        self.servertitle:SetTruncatedString(serverNameStr, 800, 100, true)
    else
        self.servertitle:SetString(serverNameStr)
	end

	if not self.serverstate then
		self.serverstate = self.root:AddChild(Text(UIFONT,30))
        self.serverstate:SetColour(1,1,1,1)
    end
    self.serverage = TheWorld.state.cycles + 1
    local modeStr = GetGameModeString(TheNet:GetServerGameMode()) ~= nil and GetGameModeString(TheNet:GetServerGameMode()).." - " or ""
    self.serverstate:SetString(modeStr.." "..STRINGS.UI.PLAYERSTATUSSCREEN.AGE_PREFIX..self.serverage)

    self.server_group = TheNet:GetServerClanID()
    if self.server_group ~= "" and not TheInput:ControllerAttached() then
        if not self.viewgroup_button then
            self.viewgroup_button = self.root:AddChild(ImageButton("images/scoreboard.xml", "clan_normal.tex", "clan_hover.tex", "clan.tex", "clan.tex", nil, {0.6,0.6}, {0,0}))
            self.viewgroup_button:SetOnClick(function() TheNet:ViewNetProfile(self.server_group) end)
            self.viewgroup_button:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.VIEWGROUP, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 48, colour = {1,1,1,1}})
        end
    end

	local Voter = TheWorld.net.components.voter
    if ClientObjs == nil then
        ClientObjs = TheNet:GetClientTable() or {}
    end
	self.numPlayers = #ClientObjs

	if not self.players_number then 
	    self.players_number = self.root:AddChild(Text(UIFONT, 25, "x/y"))
	    self.players_number:SetPosition(303,170) 
	    self.players_number:SetRegionSize(100,30)
	    self.players_number:SetHAlign(ANCHOR_RIGHT)
	    self.players_number:SetColour(1,1,1,1)
	end
    self.players_number:SetString(tostring(not TheNet:GetServerIsClientHosted() and self.numPlayers - 1 or self.numPlayers).."/"..(TheNet:GetServerMaxPlayers() or "?"))

	local serverDescStr = TheNet:GetServerDescription()
	if not self.serverdesc then
		self.serverdesc = self.root:AddChild(Text(UIFONT,30))
		self.serverdesc:SetColour(1,1,1,1)
		if serverDescStr ~= "" then
            self.serverdesc:SetTruncatedString(serverDescStr, 800, 150, true)
		else
			self.serverdesc:SetString(serverDescStr)
		end
	end

	if not self.divider then
		self.divider = self.root:AddChild(Image("images/scoreboard.xml", "white_line.tex"))
	end

	if serverDescStr == "" then
		self.servertitle:SetPosition(0,215)
		self.serverdesc:SetPosition(0,175)
        if self.viewgroup_button and not TheInput:ControllerAttached() then
            self.viewgroup_button:SetPosition(-328,200)
        end
		self.serverstate:SetPosition(0,175)
		self.divider:SetPosition(0,155)
	else
		self.servertitle:SetPosition(0,223)
		self.servertitle:SetSize(40)
		self.serverdesc:SetPosition(0,188)
		self.serverdesc:SetSize(23)
        if self.viewgroup_button and not TheInput:ControllerAttached() then
            self.viewgroup_button:SetPosition(-328,208)
        end
		self.serverstate:SetPosition(0,163)
		self.serverstate:SetSize(23)
		self.players_number:SetPosition(303,160)
		self.players_number:SetSize(20)
		self.divider:SetPosition(0,149)
	end

	if TheNet:GetServerModsEnabled() and not self.servermods then
		local modsStr = TheNet:GetServerModsDescription()
		self.servermods = self.root:AddChild(Text(UIFONT,25))
		self.servermods:SetPosition(20,-250,0)
		self.servermods:SetColour(1,1,1,1)
        self.servermods:SetTruncatedString(STRINGS.UI.PLAYERSTATUSSCREEN.MODSLISTPRE.." "..modsStr, 650, 146, true)

		self.bg:SetScale(.95,.95)
		self.bg:SetPosition(0,-10)
	end

	local function doButtonFocusHookups(playerListing)
		if playerListing.ban:IsVisible() then
			if playerListing.kick:IsVisible() then
				playerListing.ban:SetFocusChangeDir(MOVE_LEFT, playerListing.kick)
			else
				playerListing.ban:SetFocusChangeDir(MOVE_LEFT, playerListing.mute)
			end
		end

		if playerListing.kick:IsVisible() then
			if playerListing.ban:IsVisible() then
				playerListing.kick:SetFocusChangeDir(MOVE_RIGHT, playerListing.ban)
			end
			playerListing.kick:SetFocusChangeDir(MOVE_LEFT, playerListing.mute)
		end

		if playerListing.mute:IsVisible() then
			if playerListing.kick:IsVisible() then
				playerListing.mute:SetFocusChangeDir(MOVE_RIGHT, playerListing.kick)
			elseif playerListing.ban:IsVisible() then
				playerListing.mute:SetFocusChangeDir(MOVE_RIGHT, playerListing.ban)
			end
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

		local empty = v == nil
		if v then
			empty = #v > 0
		end

        local displayName = self:GetDisplayName(v)

		playerListing.userid = v.userid

		playerListing.highlight = playerListing:AddChild(Image("images/scoreboard.xml", "row_goldoutline.tex"))
	    playerListing.highlight:SetPosition(22, 5)
		playerListing.highlight:Hide()

		playerListing.characterBadge = nil
		if empty then
			playerListing.characterBadge = playerListing:AddChild(PlayerBadge("", DEFAULT_PLAYER_COLOUR, false, 0))
			playerListing.characterBadge:Hide()
		else
			playerListing.characterBadge = playerListing:AddChild(PlayerBadge(v.prefab or "", v.colour or DEFAULT_PLAYER_COLOUR, v.performance ~= nil, v.userflags or 0))
		end
		playerListing.characterBadge:SetScale(.8)
		playerListing.characterBadge:SetPosition(-328,5,0)


		playerListing.number = playerListing:AddChild(Text(UIFONT, 35))
		local visible_index = i
		if not TheNet:GetServerIsClientHosted() then
			playerListing.number:SetString(i-1)
			visible_index = i-1
            if i <= 1 then
                playerListing.number:Hide()
            end
		else
			playerListing.number:SetString(i)
		end
		playerListing.number:SetPosition(-385,0,0)
		playerListing.number:SetHAlign(ANCHOR_MIDDLE)
		playerListing.number:SetColour(1,1,1,1)
		if empty then
			playerListing.number:Hide()
		end

		playerListing.adminBadge = playerListing:AddChild(ImageButton("images/avatars.xml", "avatar_admin.tex", "avatar_admin.tex", "avatar_admin.tex", nil, nil, {1,1}, {0,0}))
		playerListing.adminBadge:Disable()
		playerListing.adminBadge:SetPosition(-359,-13,0)
		playerListing.adminBadge.image:SetScale(.3)
		playerListing.adminBadge.scale_on_focus = false
		playerListing.adminBadge:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.ADMIN, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
	    if not v.admin then
	    	playerListing.adminBadge:Hide()
		end

		playerListing.name = playerListing:AddChild(Text(UIFONT, 35, displayName))
        playerListing.name._align =
        {
            maxwidth = 215,
            maxchars = 36,
            x = -286,
        }
        playerListing.name:SetTruncatedString(displayName, playerListing.name._align.maxwidth, playerListing.name._align.maxchars, true)
        local w, h = playerListing.name:GetRegionSize()
        playerListing.name:SetPosition(playerListing.name._align.x + w * .5, 0, 0)
		playerListing.name:SetColour(unpack(v.colour or DEFAULT_PLAYER_COLOUR))

		playerListing.age = playerListing:AddChild(Text(UIFONT, 35, v.playerage ~= nil and v.playerage > 0 and (tostring(v.playerage)..(v.playerage == 1 and STRINGS.UI.PLAYERSTATUSSCREEN.AGE_DAY or STRINGS.UI.PLAYERSTATUSSCREEN.AGE_DAYS)) or ""))
		playerListing.age:SetPosition(-20,0,0)
		playerListing.age:SetHAlign(ANCHOR_MIDDLE)
		
		playerListing.ishost = v.performance ~= nil

        local perf_img
        local perf_scale
        if v.performance ~= nil then
            perf_img = PERF_HOST_LEVELS[math.min(v.performance + 1, #PERF_HOST_LEVELS)]
            perf_scale = PERF_HOST_SCALE
        else
            if v.netscore ~= nil then
                perf_img = PERF_CLIENT_LEVELS[math.min(v.netscore + 1, #PERF_CLIENT_LEVELS)]
            else
                perf_img = PERF_CLIENT_UNKNOWN
            end
            perf_scale = PERF_CLIENT_SCALE
        end
		playerListing.perf = playerListing:AddChild(Image("images/scoreboard.xml", perf_img))
        playerListing.perf:SetPosition(295, 4, 0)
        playerListing.perf:SetScale(unpack(perf_scale))

        local this_user_is_dedicated_server = empty ~= true and v.performance ~= nil and not TheNet:GetServerIsClientHosted()

    	playerListing.viewprofile = playerListing:AddChild(ImageButton("images/scoreboard.xml", "addfriend.tex", "addfriend.tex", "addfriend.tex", "addfriend.tex", nil, {1,1}, {0,0}))
		playerListing.viewprofile:SetPosition(120,3,0)
		playerListing.viewprofile:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VIEWPROFILE, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
		playerListing.viewprofile.scale_on_focus = false
		local gainfocusfn = playerListing.viewprofile.OnGainFocus
		playerListing.viewprofile.OnGainFocus =
        function()	
        	gainfocusfn(playerListing.viewprofile)
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            playerListing.viewprofile:SetScale(1.1)
        end
        local losefocusfn = playerListing.viewprofile.OnLoseFocus
    	playerListing.viewprofile.OnLoseFocus =
        function()
        	losefocusfn(playerListing.viewprofile)
            playerListing.viewprofile:SetScale(1)
        end
		playerListing.viewprofile:SetOnClick(
			function()
                TheFrontEnd:PopScreen()
                self.owner.HUD:TogglePlayerAvatarPopup(displayName, v, true)
			end)

		if empty or this_user_is_dedicated_server then
			playerListing.viewprofile:Hide()
		end

        playerListing.isMuted = TheFrontEnd.mutedPlayers ~= nil and TheFrontEnd.mutedPlayers[v.userid] and TheFrontEnd.mutedPlayers[v.userid] == true

		playerListing.mute = playerListing:AddChild(ImageButton("images/scoreboard.xml", "chat.tex", "chat.tex", "chat.tex", "chat.tex", nil, {1,1}, {0,0}))
		playerListing.mute:SetPosition(170,3,0)
		playerListing.mute.scale_on_focus = false
		playerListing.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
		local gainfocusfn = playerListing.mute.OnGainFocus
		if playerListing.isMuted then
			playerListing.mute.image_focus = "mute.tex"
        	playerListing.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
        	playerListing.mute:SetTextures("images/scoreboard.xml", "mute.tex")
        	playerListing.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
        	playerListing.mute.image:SetTint(242/255, 99/255, 99/255, 255/255)
		end
		local gainfocusfn = playerListing.mute.OnGainFocus
		playerListing.mute.OnGainFocus =
	        function()
	        	gainfocusfn(playerListing.mute)
	            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
	            playerListing.mute.image:SetScale(1.1)
	        end
	    local losefocusfn = playerListing.mute.OnLoseFocus
        playerListing.mute.OnLoseFocus =
	        function()
	        	losefocusfn(playerListing.mute)
	            playerListing.mute.image:SetScale(1)
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

		if empty or not (v.userid ~= self.owner.userid and not this_user_is_dedicated_server) then
			playerListing.mute:Hide()
		end

		local is_server_admin = TheNet:GetIsServerAdmin()

		playerListing.kick = playerListing:AddChild(ImageButton("images/scoreboard.xml", "kickout.tex", "kickout.tex", "kickout_disabled.tex", "kickout.tex", nil, {1,1}, {0,0}))
		playerListing.kick.scale_on_focus = false
		playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.KICK, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
		local gainfocusfn = playerListing.kick.OnGainFocus
		playerListing.kick.OnGainFocus =
	        function()
	        	gainfocusfn(playerListing.kick)
				if is_server_admin and not v.admin then
					playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.KICK)
				elseif Voter and Voter:IsVoteActive() then
	        		playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VOTEACTIVE)
	        	elseif Voter:IsUserSquelched(self.owner.userid) then
					playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICKSQUELCHED)				
				else
					playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICK)
				end
	            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
	            playerListing.kick.image:SetScale(1.1)
	        end
	    local losefocusfn = playerListing.kick.OnLoseFocus
    	playerListing.kick.OnLoseFocus =
	        function()
	        	losefocusfn(playerListing.kick)
	            playerListing.kick.image:SetScale(1)
	        end
		playerListing.kick:Hide()

		playerListing.ban = playerListing:AddChild(ImageButton("images/scoreboard.xml", "banhammer.tex", "banhammer.tex", "banhammer.tex", "banhammer.tex", nil, {1,1}, {0,0}))
		playerListing.ban:SetPosition(220,3,0)
		playerListing.ban.scale_on_focus = false
		playerListing.ban:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.BAN, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
		local gainfocusfn = playerListing.ban.OnGainFocus
		playerListing.ban.OnGainFocus =
	        function()
	        	gainfocusfn(playerListing.ban)
	            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
	            playerListing.ban.image:SetScale(1.1)
	        end
	    local losefocusfn = playerListing.ban.OnLoseFocus
    	playerListing.ban.OnLoseFocus =
	        function()
	        	losefocusfn(playerListing.ban)
	            playerListing.ban.image:SetScale(1)
	        end

		playerListing.ban:SetOnClick(
			function()
				if v.userid then
					TheFrontEnd:PushScreen( 
						PopupDialogScreen(
							STRINGS.UI.PLAYERSTATUSSCREEN.BANCONFIRM_TITLE.." "..displayName,
							STRINGS.UI.PLAYERSTATUSSCREEN.BANCONFIRM_BODY.." "..displayName.."?",
							{ 
								{text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() TheNet:Ban(v.userid) TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end},
								{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
							}
					))
				end
			end)
		playerListing.ban:Hide()

		if is_server_admin and not v.admin then
			if BAN_ENABLED then
				playerListing.viewprofile:SetPosition(70,3,0)
				playerListing.mute:SetPosition(120,3,0)
				playerListing.kick:SetPosition(170,3,0)
				playerListing.ban:Show()
			else
				playerListing.viewprofile:SetPosition(90,3,0)
				playerListing.mute:SetPosition(140,3,0)
				playerListing.kick:SetPosition(190,3,0)
			end
			playerListing.kick:SetOnClick(
				function()
					if v.userid then
						TheFrontEnd:PushScreen( 
							PopupDialogScreen(
								STRINGS.UI.PLAYERSTATUSSCREEN.KICKCONFIRM_TITLE.." "..displayName,
								STRINGS.UI.PLAYERSTATUSSCREEN.KICKCONFIRM_BODY.." "..displayName.."?",
								{ 
									{text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() TheNet:Kick(v.userid) TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end},
									{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
								}
						))
					end
				end)
			playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.KICK)
			playerListing.kick:Show()
		elseif Voter and Voter:IsVoteKickEnabled() and not v.admin and not empty then
			playerListing.viewprofile:SetPosition(90,3,0)
			playerListing.mute:SetPosition(140,5,0)
			playerListing.kick:SetPosition(190,3,0)
			playerListing.kick:Show()
			
			if Voter:IsUserSquelched(self.owner.userid) then
				playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICKSQUELCHED)				
			else
				playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICK)
			end

			playerListing.kick:SetOnClick(
				function()
					if Voter and not Voter:IsVoteActive() and not Voter:IsUserSquelched(self.owner.userid) then
						Voter:StartVote( self.owner, "kick", visible_index ) --ThePlayer instead of self.owner?
					end
				end)

			if empty or (not Voter) or (Voter and not Voter:IsVoteKickEnabled()) or self.owner.userid == v.userid then
			    playerListing.kick:Hide()
			elseif Voter then
				if Voter:IsVoteActive() or Voter:IsUserSquelched(self.owner.userid) then						--print("### disable kick button")
					playerListing.kick:Disable()
				else
					playerListing.kick:Enable()
				end
			end
		end

		doButtonFocusHookups(playerListing)

		playerListing.OnGainFocus = function()
			-- playerListing.name:SetSize(43)
			if not empty then
				playerListing.highlight:Show()
			end
		end
		playerListing.OnLoseFocus = function()
			-- playerListing.name:SetSize(35)
			playerListing.highlight:Hide()
		end

		return playerListing
	end

	local function UpdatePlayerListing(playerListing, v, i)

		local empty = v == nil
		if v then
			empty = #v > 0
		end

		if empty then
			playerListing:Hide()
		else
			playerListing:Show()

	        local displayName = self:GetDisplayName(v)

			playerListing.userid = v.userid

			playerListing.characterBadge:Set(v.prefab or "", v.colour or DEFAULT_PLAYER_COLOUR, v.performance ~= nil, v.userflags or 0)
			playerListing.characterBadge:Show()

		    if v.admin then
		    	playerListing.adminBadge:Show()
		    else
		    	playerListing.adminBadge:Hide()
			end
			
			local visible_index = i
			if not TheNet:GetServerIsClientHosted() then
				playerListing.number:SetString(i-1)
				visible_index = i-1
                if i > 1 then
                    playerListing.number:Show()
                else
                    playerListing.number:Hide()
                end
			else
				playerListing.number:SetString(i)
			end

			playerListing.name:SetTruncatedString(displayName, playerListing.name._align.maxwidth, playerListing.name._align.maxchars, true)
            local w, h = playerListing.name:GetRegionSize()
            playerListing.name:SetPosition(playerListing.name._align.x + w * .5, 0, 0)
			playerListing.name:SetColour(unpack(v.colour or DEFAULT_PLAYER_COLOUR))

			playerListing.age:SetString(v.playerage ~= nil and v.playerage > 0 and (tostring(v.playerage)..(v.playerage == 1 and STRINGS.UI.PLAYERSTATUSSCREEN.AGE_DAY or STRINGS.UI.PLAYERSTATUSSCREEN.AGE_DAYS)) or "")
			
			playerListing.ishost = v.performance ~= nil

            if v.performance ~= nil then
                playerListing.perf:SetTexture("images/scoreboard.xml", PERF_HOST_LEVELS[math.min(v.performance + 1, #PERF_HOST_LEVELS)])
                playerListing.perf:SetScale(unpack(PERF_HOST_SCALE))
            else
                if v.netscore ~= nil then
                    playerListing.perf:SetTexture("images/scoreboard.xml", PERF_CLIENT_LEVELS[math.min(v.netscore + 1, #PERF_CLIENT_LEVELS)])
                else
                    playerListing.perf:SetTexture("images/scoreboard.xml", PERF_CLIENT_UNKNOWN)
                end
                playerListing.perf:SetScale(unpack(PERF_CLIENT_SCALE))
            end

	        local this_user_is_dedicated_server = v.performance ~= nil and not TheNet:GetServerIsClientHosted()

			playerListing.viewprofile:SetOnClick(
				function()
                    TheFrontEnd:PopScreen()
                    self.owner.HUD:TogglePlayerAvatarPopup(displayName, v, true)
				end)

			if not this_user_is_dedicated_server then
				playerListing.viewprofile:Show()
			else
				playerListing.viewprofile:Hide()
			end

	        playerListing.isMuted = TheFrontEnd.mutedPlayers ~= nil and TheFrontEnd.mutedPlayers[v.userid] and TheFrontEnd.mutedPlayers[v.userid] == true

			if playerListing.isMuted then
				playerListing.mute.image_focus = "mute.tex"
	        	playerListing.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
	        	playerListing.mute:SetTextures("images/scoreboard.xml", "mute.tex")
	        	playerListing.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
	        	playerListing.mute.image:SetTint(242/255, 99/255, 99/255, 255/255)
			else
				playerListing.mute.image_focus = "chat.tex"
	        	playerListing.mute.image:SetTexture("images/scoreboard.xml", "chat.tex")
	        	playerListing.mute:SetTextures("images/scoreboard.xml", "chat.tex")
	        	playerListing.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE)
	        	playerListing.mute.image:SetTint(1,1,1,1)
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

			if v.userid ~= self.owner.userid and not this_user_is_dedicated_server then
				playerListing.mute:Show()
			else
				playerListing.mute:Hide()
			end

			playerListing.kick:Hide()

			playerListing.ban:SetOnClick(
				function()
					if v.userid then
						TheFrontEnd:PushScreen( 
							PopupDialogScreen(
								STRINGS.UI.PLAYERSTATUSSCREEN.BANCONFIRM_TITLE.." "..displayName,
								STRINGS.UI.PLAYERSTATUSSCREEN.BANCONFIRM_BODY.." "..displayName.."?",
								{ 
									{text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() TheNet:Ban(v.userid) TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end},
									{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
								}
						))
					end
				end)
			playerListing.ban:Hide()

			local is_server_admin = TheNet:GetIsServerAdmin()
			if is_server_admin and not v.admin then
				if BAN_ENABLED then
					playerListing.viewprofile:SetPosition(70,3,0)
					playerListing.mute:SetPosition(120,3,0)
					playerListing.kick:SetPosition(170,3,0)
					playerListing.ban:Show()
				else
					playerListing.viewprofile:SetPosition(90,3,0)
					playerListing.mute:SetPosition(140,3,0)
					playerListing.kick:SetPosition(190,3,0)
				end
				playerListing.kick:SetOnClick(
					function()
						if v.userid then
							TheFrontEnd:PushScreen( 
								PopupDialogScreen(
									STRINGS.UI.PLAYERSTATUSSCREEN.KICKCONFIRM_TITLE.." "..displayName,
									STRINGS.UI.PLAYERSTATUSSCREEN.KICKCONFIRM_BODY.." "..displayName.."?",
									{ 
										{text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() TheNet:Kick(v.userid) TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end},
										{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
									}
							))
						end
					end)
				playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.KICK)
				playerListing.kick:Show()
			elseif Voter and Voter:IsVoteKickEnabled() and not v.admin then
				playerListing.viewprofile:SetPosition(90,3,0)
				playerListing.mute:SetPosition(140,5,0)
				playerListing.kick:SetPosition(190,3,0)
				playerListing.kick:Show()
				
				playerListing.kick:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICK)

				playerListing.kick:SetOnClick(
					function()
						if Voter and not Voter:IsVoteActive() and not Voter:IsUserSquelched(self.owner.userid) then
							Voter:StartVote( self.owner, "kick", visible_index ) --ThePlayer instead of self.owner?
						end
					end)

				if not Voter or (Voter and not Voter:IsVoteKickEnabled()) or self.owner.userid == v.userid then
				    playerListing.kick:Hide()
				elseif Voter then
					if Voter:IsVoteActive() or Voter:IsUserSquelched(self.owner.userid) then						--print("### disable kick button")
						playerListing.kick:Disable()
					else
						playerListing.kick:Enable()
					end
				end
			end

			doButtonFocusHookups(playerListing)
		end
	end

	if not self.scroll_list then
		self.list_root = self.root:AddChild(Widget("list_root"))
		self.list_root:SetPosition(190, -35)

		self.row_root = self.root:AddChild(Widget("row_root"))
		self.row_root:SetPosition(190, -35)

		self.player_widgets = {}
		for i=1,6 do
			table.insert(self.player_widgets, listingConstructor(ClientObjs[i] or {}, i, self.row_root))
		end

		self.scroll_list = self.list_root:AddChild(ScrollableList(ClientObjs, 380, 370, 60, 5, UpdatePlayerListing, self.player_widgets, nil, nil, nil, -15))
		self.scroll_list:LayOutStaticWidgets(-15)
		self.scroll_list:SetPosition(0,-10)
	else
		self.scroll_list:SetList(ClientObjs)
	end

    if not self.bgs then
        self.bgs = {}
    end
    if #self.bgs > #ClientObjs then
        for i = #ClientObjs + 1, #self.bgs do
            table.remove(self.bgs):Kill()
        end
    else
        local maxbgs = math.min(self.scroll_list.widgets_per_view, #ClientObjs)
        if #self.bgs < maxbgs then
            for i = #self.bgs + 1, maxbgs do
                local bg = self.scroll_list:AddChild(Image("images/scoreboard.xml", "row.tex"))
                bg:SetTint(1, 1, 1, (i % 2) == 0 and .85 or .5)
                bg:SetPosition(-170, 165 - 65 * (i - 1))
                bg:MoveToBack()
                table.insert(self.bgs, bg)
            end
        end
    end
end

return PlayerStatusScreen
