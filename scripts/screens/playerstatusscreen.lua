require "util"
local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local PlayerBadge = require "widgets/playerbadge"
local PopupDialogScreen = require "screens/popupdialog"
local ScrollableList = require "widgets/scrollablelist"

local PlayerStatusScreen = Class(Screen, function(self, owner)
	Screen._ctor(self, "PlayerStatusScreen")
	self.owner = owner
	self:DoInit()
end)

local BAN_ENABLED = true

local list_spacing = 82.5

local RED = {242/255, 99/255, 99/255, 255/255}
local YELLOW = {222/255, 222/255, 99/255, 255/255}
local GREEN = {59/255, 242/255, 99/255, 255/255}

local GREEN_THRESHOLD = 100
local YELLOW_THRESHOLD = 300

local HOST_GREEN_THRESHOLD = 50 --game loop cycles/s
local HOST_YELLOW_THRESHOLD = 30 --game loop cycles/s

local REFRESH_INTERVAL = .5

function PlayerStatusScreen:OnBecomeActive()
	PlayerStatusScreen._base.OnBecomeActive(self)
	self:DoInit()
	self.time_to_refresh = REFRESH_INTERVAL
	self:StartUpdating()
end

function PlayerStatusScreen:OnBecomeInactive()
	PlayerStatusScreen._base.OnBecomeInactive(self)
end

function PlayerStatusScreen:OnDestroy()
    --Overridden so we do part of Widget:Kill()
    --but keeps the screen around hidden
    self:StopUpdating()
    self:StopFollowMouse()
    self:Hide()
end

function PlayerStatusScreen:OnControl(control, down)
    if not self:IsVisible() then
        return false
    elseif PlayerStatusScreen._base.OnControl(self, control, down) then
        return true
    elseif control == CONTROL_OPEN_DEBUG_MENU then
        --jcheng: don't allow debug menu stuff going on right now
        return true
    elseif not down
        and (control == CONTROL_SHOW_PLAYER_STATUS
            or (control == CONTROL_TOGGLE_PLAYER_STATUS and
                not TheInput:IsControlPressed(CONTROL_SHOW_PLAYER_STATUS))) then
        self:Close()
        return true
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
	self.time_to_refresh = self.time_to_refresh - dt

	if self.time_to_refresh <= 0 then
		local ClientObjs = TheNet:GetClientTable()

		if ClientObjs and #ClientObjs ~= self.numPlayers then
			-- We've either added or removed a player
			-- Kill everything and re-init
			self:DoInit()
		else
			if self.servertitle and self.serverage and self.serverage ~= TheWorld.state.cycles + 1 then
				local modeStr = STRINGS.UI.PLAYERSTATUSSCREEN[string.upper(TheNet:GetServerGameMode())] ~= nil and " ("..STRINGS.UI.PLAYERSTATUSSCREEN[string.upper(TheNet:GetServerGameMode())]..")" or ""
				local servName = string.len(TheNet:GetServerName()) > 32 and string.sub(TheNet:GetServerName(),1,32).."..." or TheNet:GetServerName()
				self.serverage = TheWorld.state.cycles + 1
				self.servertitle:SetString(servName.." - "..STRINGS.UI.PLAYERSTATUSSCREEN.WORLD.." "..STRINGS.UI.PLAYERSTATUSSCREEN.AGE_PREFIX..self.serverage..modeStr)
			end

			if self.scroll_list then
                local Voting = TheWorld.net.components.voting
				for i,v in pairs(self.scroll_list.constructed_widgets) do
					if ClientObjs then
						for j,k in ipairs(ClientObjs) do
							if v.userid == k.userid and v.ishost == (k.performance ~= nil) then
                                v.name:SetString(self:GetDisplayName(k))

		                        v.characterBadge:Set(k.prefab or "", k.colour or DEFAULT_PLAYER_COLOUR, k.userflags or 0)

		                        if v.characterBadge:IsAFK() then
		                            v.age:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.AFK)
		                        else
		                            local agestring = k.playerage ~= nil and k.playerage > 0 and (STRINGS.UI.PLAYERSTATUSSCREEN.AGE_PREFIX..tostring(k.playerage)) or ""
		                            v.age:SetString(agestring)
		                        end

		                        if v.kick ~= nil and v.kick.timerlabel ~= nil then
		                            if Voting:VoteInProgress(v.userid) then
		                         	    v.kick.timerlabel:SetString(Voting:TimeRemainingInVote(v.userid))
		                         	    v.kick.timerlabel:Show()
		                            else
		                         	    v.kick.timerlabel:Hide()
		                            end
		                        end

		                        if k.ping ~= nil then
		    						v.pingVal = k.ping
		    						v.ping:SetString(v.pingVal)
		    						if v.pingVal <= GREEN_THRESHOLD then
		    				            v.ping:SetColour(GREEN)
		    				        elseif v.pingVal <= YELLOW_THRESHOLD then
		    				            v.ping:SetColour(YELLOW)
		    				        else
		    				            v.ping:SetColour(RED)
		    				        end
		                        elseif k.performance ~= nil then
		                            v.pingVal = k.performance
		                            if v.pingVal >= HOST_GREEN_THRESHOLD then
		                                v.ping:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.GOODHOST)
		                                v.ping:SetColour(GREEN)
		                            elseif v.pingVal >= HOST_YELLOW_THRESHOLD then
		                                v.ping:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.OKHOST)
		                                v.ping:SetColour(YELLOW)
		                            else
		                                v.ping:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.BADHOST)
		                                v.ping:SetColour(RED)
		                            end
		                        else
		                            v.pingVal = 0
		                            v.ping:SetString("")
		                        end
						    end
					    end
					end
				end
			end
		end
		self.time_to_refresh = REFRESH_INTERVAL
	end
end

function PlayerStatusScreen:GetDisplayName(clientrecord)
    return clientrecord.name
end

function PlayerStatusScreen:DoInit()

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

	if not self.servertitle then
		local modeStr = GetGameModeString(TheNet:GetServerGameMode()) ~= nil and " ("..GetGameModeString(TheNet:GetServerGameMode())..")" or ""
		local servName = string.len(TheNet:GetServerName()) > 32 and string.sub(TheNet:GetServerName(),1,32).."..." or TheNet:GetServerName()
		self.serverage = TheWorld.state.cycles + 1
		self.servertitle = self.root:AddChild(Text(UIFONT,45,servName.." - "..STRINGS.UI.PLAYERSTATUSSCREEN.WORLD.." "..STRINGS.UI.PLAYERSTATUSSCREEN.AGE_PREFIX..self.serverage..modeStr))
		self.servertitle:SetPosition(0,215,0)
		self.servertitle:SetRegionSize(800,100)
		self.servertitle:SetColour(1,1,1,1)
	else
		local modeStr = GetGameModeString(TheNet:GetServerGameMode()) ~= nil and " ("..GetGameModeString(TheNet:GetServerGameMode())..")" or ""
		local servName = string.len(TheNet:GetServerName()) > 32 and string.sub(TheNet:GetServerName(),1,32).."..." or TheNet:GetServerName()
		self.serverage = TheWorld.state.cycles + 1
		self.servertitle:SetString(servName.." - "..STRINGS.UI.PLAYERSTATUSSCREEN.WORLD.." "..STRINGS.UI.PLAYERSTATUSSCREEN.AGE_PREFIX..self.serverage..modeStr)
	end

	if not self.serverdesc then
		self.serverdesc = self.root:AddChild(Text(UIFONT,30,TheNet:GetServerDescription()))
		self.serverdesc:SetPosition(0,175,0)
		self.serverdesc:SetRegionSize(800,100)
		self.serverdesc:SetColour(1,1,1,1)
	end

    local Voting = TheWorld.net.components.voting
    local ClientObjs = TheNet:GetClientTable()

	self.numPlayers = #ClientObjs

	if not self.divider then
		self.divider = self.root:AddChild(Image("images/scoreboard.xml", "white_line.tex"))
		self.divider:SetPosition(0,155)
	end

	if TheNet:GetServerDescription() == "" then
		self.servertitle:SetPosition(0,200,0)
		self.divider:SetPosition(0,160)
	end

	if TheNet:GetServerModsEnabled() and not self.servermods then
		self.servermods = self.root:AddChild(Text(UIFONT,25,STRINGS.UI.PLAYERSTATUSSCREEN.MODSLISTPRE.." "..TheNet:GetServerModsDescription()))
		self.servermods:SetPosition(0,-250,0)
		self.servermods:SetRegionSize(500,100)
		self.servermods:SetColour(1,1,1,1)
		self.bg:SetScale(.95,.95)
		self.bg:SetPosition(0,-10)
	end

	local function listingConstructor(v, i)

		local playerListing =  Widget("playerListing")
        local displayName = self:GetDisplayName(v)

		playerListing.userid = v.userid

		playerListing.characterBadge = playerListing:AddChild(PlayerBadge(v.prefab or "", v.colour or DEFAULT_PLAYER_COLOUR, v.performance ~= nil, v.userflags or 0))
		playerListing.characterBadge:SetScale(.8)
		playerListing.characterBadge:SetPosition(-328,5,0)

		if v.admin then
			playerListing.adminBadge = playerListing:AddChild(ImageButton("images/avatars.xml", "avatar_admin.tex", "avatar_admin.tex", "avatar_admin.tex"))
			playerListing.adminBadge:Disable()
			playerListing.adminBadge:SetPosition(-359,-13,0)	
			playerListing.adminBadge.image:SetScale(.3)
			playerListing.adminBadge.label = playerListing.adminBadge:AddChild(Text(UIFONT, 25, STRINGS.UI.PLAYERSTATUSSCREEN.ADMIN))
			playerListing.adminBadge.label:SetPosition(3,33,0)
			playerListing.adminBadge.label:Hide()
			playerListing.adminBadge.OnGainFocus =
	        function()
	        	playerListing.adminBadge.label:Show()
	        end
	        playerListing.adminBadge.OnLoseFocus =
	        function()
	        	playerListing.adminBadge.label:Hide()
	        end
		end

		playerListing.number = playerListing:AddChild(Text(UIFONT, 35))
		if TheNet:GetServerIsDedicated() then
			playerListing.number:SetString(i-1)
		else
			playerListing.number:SetString(i)
		end
		playerListing.number:SetPosition(-385,0,0)
		playerListing.number:SetHAlign(ANCHOR_MIDDLE)
		playerListing.number:SetColour(1,1,1,1)

		playerListing.name = playerListing:AddChild(Text(UIFONT, 35, displayName))
		playerListing.name:SetPosition(-170,0,0)
		playerListing.name:SetHAlign(ANCHOR_MIDDLE)
		playerListing.name:SetColour(unpack(v.colour))

		local agestring = v.playerage ~= nil and v.playerage > 0 and (STRINGS.UI.PLAYERSTATUSSCREEN.AGE_PREFIX..tostring(v.playerage)) or ""
		playerListing.age = playerListing:AddChild(Text(UIFONT, 35, agestring))
		playerListing.age:SetPosition(-20,0,0)
		playerListing.age:SetHAlign(ANCHOR_MIDDLE)
		
		playerListing.ishost = v.performance ~= nil
        if v.ping ~= nil then
    		playerListing.pingVal = v.ping
    		playerListing.ping = playerListing:AddChild(Text(UIFONT, 35, playerListing.pingVal))
    		if playerListing.pingVal <= GREEN_THRESHOLD then
                playerListing.ping:SetColour(GREEN)
            elseif playerListing.pingVal <= YELLOW_THRESHOLD then
                playerListing.ping:SetColour(YELLOW)
            else
                playerListing.ping:SetColour(RED)
            end
        elseif v.performance ~= nil then
            playerListing.pingVal = v.performance
            if playerListing.pingVal >= HOST_GREEN_THRESHOLD then
                playerListing.ping = playerListing:AddChild(Text(UIFONT, 35, STRINGS.UI.PLAYERSTATUSSCREEN.GOODHOST))
                playerListing.ping:SetColour(GREEN)
            elseif playerListing.pingVal >= HOST_YELLOW_THRESHOLD then
                playerListing.ping = playerListing:AddChild(Text(UIFONT, 35, STRINGS.UI.PLAYERSTATUSSCREEN.OKHOST))
                playerListing.ping:SetColour(YELLOW)
            else
                playerListing.ping = playerListing:AddChild(Text(UIFONT, 35, STRINGS.UI.PLAYERSTATUSSCREEN.BADHOST))
                playerListing.ping:SetColour(RED)
            end
        else
            playerListing.pingVal = 0
            playerListing.ping = playerListing:AddChild(Text(UIFONT, 35, ""))
        end
        playerListing.ping:SetPosition(300,0,0)
        playerListing.ping:SetHAlign(ANCHOR_MIDDLE)

        local server_has_admin = TheNet:GetServerHasPresentAdmin()
        local this_user_is_dedicated_server = ( v.performance ~= nil and TheNet:GetServerIsDedicated() )
        if v.userid ~= self.owner.userid and not this_user_is_dedicated_server then
        	playerListing.viewprofile = playerListing:AddChild(ImageButton("images/scoreboard.xml", "addfriend.tex", "addfriend.tex", "addfriend.tex", "addfriend.tex"))
			playerListing.viewprofile:SetPosition(120,3,0)
			playerListing.viewprofile.label = playerListing.viewprofile:AddChild(Text(UIFONT, 25, STRINGS.UI.PLAYERSTATUSSCREEN.VIEWPROFILE))
			playerListing.viewprofile.label:SetPosition(3,33,0)
			playerListing.viewprofile.label:Hide()

			playerListing.viewprofile.OnGainFocus =
	        function()
	        	playerListing.viewprofile.label:Show()
	            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
	            playerListing.viewprofile:SetScale(1.1)
	        end

        	playerListing.viewprofile.OnLoseFocus =
	        function()
	        	playerListing.viewprofile.label:Hide()
	            playerListing.viewprofile:SetScale(1)
	        end

			playerListing.viewprofile:SetOnClick(
				function()
					TheNet:ViewSteamProfile(v.steamid)
				end)

        	playerListing.isMuted = self.owner.mutedPlayers ~= nil and self.owner.mutedPlayers[v.userid] == true

			playerListing.mute = playerListing:AddChild(ImageButton("images/scoreboard.xml", "chat.tex", "chat.tex", "chat.tex", "chat.tex"))
			playerListing.mute:SetPosition(170,3,0)
			playerListing.mute.label = playerListing.mute:AddChild(Text(UIFONT, 25, STRINGS.UI.PLAYERSTATUSSCREEN.MUTE))
			playerListing.mute.label:SetPosition(3,33,0)
			playerListing.mute.label:Hide()

			if playerListing.isMuted then
				playerListing.mute.image_focus = "mute.tex"
	        	playerListing.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
	        	playerListing.mute.label:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
	        	playerListing.mute.label:SetPosition(1,33,0)
	        	playerListing.mute.image:SetTint(242/255, 99/255, 99/255, 255/255)
			end

			playerListing.mute.OnGainFocus =
		        function()
		        	playerListing.mute.label:Show()
		            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
		            playerListing.mute:SetScale(1.1)
		        end

	        playerListing.mute.OnLoseFocus =
		        function()
		        	playerListing.mute.label:Hide()
		            playerListing.mute:SetScale(1)
		        end

		    playerListing.mute:SetOnClick(
		    	function()
		    		playerListing.isMuted = not playerListing.isMuted
		    		if playerListing.isMuted then
                        if self.owner.mutedPlayers == nil then
                            self.owner.mutedPlayers = { [v.userid] = true }
                        else
                            self.owner.mutedPlayers[v.userid] = true
                        end
		    			playerListing.mute.image_focus = "mute.tex"
			        	playerListing.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
			        	playerListing.mute.label:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
			        	playerListing.mute.label:SetPosition(1,33,0)
			        	playerListing.mute.image:SetTint(242/255, 99/255, 99/255, 255/255)
		    		else
                        if self.owner.mutedPlayers ~= nil then
                            self.owner.mutedPlayers[v.userid] = nil
                            if next(self.owner.mutedPlayers) == nil then
                                self.owner.mutedPlayers = nil
                            end
                        end
		    			playerListing.mute.image_focus = "chat.tex"
			        	playerListing.mute.image:SetTexture("images/scoreboard.xml", "chat.tex")
			        	playerListing.mute.label:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE)
			        	playerListing.mute.label:SetPosition(3,33,0)
			        	playerListing.mute.image:SetTint(1,1,1,1)
		    		end
		    	end)
			
			local is_server_admin = TheNet:GetIsServerAdmin()
			if is_server_admin and not v.admin then
				if BAN_ENABLED then
					playerListing.viewprofile:SetPosition(70,3,0)
					playerListing.mute:SetPosition(120,3,0)
				else
					playerListing.viewprofile:SetPosition(90,3,0)
					playerListing.mute:SetPosition(140,3,0)
				end

				playerListing.kick = playerListing:AddChild(ImageButton("images/scoreboard.xml", "kickout.tex", "kickout.tex", "kickout.tex", "kickout.tex"))
				if BAN_ENABLED then
					playerListing.kick:SetPosition(170,3,0)
				else
					playerListing.kick:SetPosition(190,3,0)
				end
				playerListing.kick.label = playerListing.kick:AddChild(Text(UIFONT, 25, STRINGS.UI.PLAYERSTATUSSCREEN.KICK))
				playerListing.kick.label:SetPosition(3,33,0)
				playerListing.kick.label:Hide()

				playerListing.kick.OnGainFocus =
		        function()
		        	playerListing.kick.label:Show()
		            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
		            playerListing.kick:SetScale(1.1)
		        end

	        	playerListing.kick.OnLoseFocus =
		        function()
		        	playerListing.kick.label:Hide()
		            playerListing.kick:SetScale(1)
		        end

				playerListing.kick:SetOnClick(
					function()
						TheFrontEnd:PushScreen( 
							PopupDialogScreen(
								STRINGS.UI.PLAYERSTATUSSCREEN.KICKCONFIRM_TITLE.." "..displayName,
								STRINGS.UI.PLAYERSTATUSSCREEN.KICKCONFIRM_BODY.." "..displayName.."?",
								{ 
									{text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() TheNet:Kick(v.userid) TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end},
									{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
								}
						))
					end)

				if BAN_ENABLED then
					playerListing.ban = playerListing:AddChild(ImageButton("images/scoreboard.xml", "banhammer.tex", "banhammer.tex", "banhammer.tex", "banhammer.tex"))
					playerListing.ban:SetPosition(220,3,0)
					playerListing.ban.label = playerListing.ban:AddChild(Text(UIFONT, 25, STRINGS.UI.PLAYERSTATUSSCREEN.BAN))
					playerListing.ban.label:SetPosition(3,33,0)
					playerListing.ban.label:Hide()

					playerListing.ban.OnGainFocus =
				        function()
				        	playerListing.ban.label:Show()
				            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
				            playerListing.ban:SetScale(1.1)
				        end

		        	playerListing.ban.OnLoseFocus =
				        function()
				        	playerListing.ban.label:Hide()
				            playerListing.ban:SetScale(1)
				        end

					playerListing.ban:SetOnClick(
						function()
							TheFrontEnd:PushScreen( 
								PopupDialogScreen(
									STRINGS.UI.PLAYERSTATUSSCREEN.BANCONFIRM_TITLE.." "..displayName,
									STRINGS.UI.PLAYERSTATUSSCREEN.BANCONFIRM_BODY.." "..displayName.."?",
									{ 
										{text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() TheNet:Ban(v.userid) TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end},
										{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
									}
							))
						end)
				end
			elseif not server_has_admin then
				playerListing.viewprofile:SetPosition(90,3,0)
				playerListing.mute:SetPosition(140,5,0)

				playerListing.kick = playerListing:AddChild(ImageButton("images/scoreboard.xml", "kickout.tex", "kickout.tex", "kickout.tex", "kickout.tex"))
				playerListing.kick:SetPosition(190,3,0)
				
				playerListing.kick.label = playerListing.kick:AddChild(Text(UIFONT, 25, STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICK))
				playerListing.kick.label:SetPosition(3,33,0)
				playerListing.kick.label:Hide()

				playerListing.kick.timerlabel = playerListing.kick:AddChild(Text(UIFONT, 25, ""))
				playerListing.kick.timerlabel:SetPosition(3,-33,0)
				playerListing.kick.timerlabel:Hide()

				playerListing.kick.OnGainFocus =
		        function()
		        	if Voting:VoteInProgress(v.userid) and Voting:VoteAlreadyCast(v.userid) then
		        		playerListing.kick.label:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.ALREADYVOTED)
		        	else
		        		playerListing.kick.label:SetString(STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICK)
		        	end
		        	playerListing.kick.label:Show()
		            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
		            playerListing.kick:SetScale(1.1)
		        end

	        	playerListing.kick.OnLoseFocus =
		        function()
		        	playerListing.kick.label:Hide()
		            playerListing.kick:SetScale(1)
		        end

				playerListing.kick:SetOnClick(
					function()
						if not Voting:VoteAlreadyCast(v.userid) then
							if Voting:VoteInProgress(v.userid) then
								TheFrontEnd:PushScreen( 
									PopupDialogScreen(
										STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICKCONFIRM_TITLE.." "..displayName,
										STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICKCONFIRM_BODY.." "..displayName.."?",
										{ 
											{text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() Voting:VoteKick(v.userid) TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end},
											{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
										}
								))
							elseif Voting:CanInitiateVoteKick(v.userid) then
								TheFrontEnd:PushScreen( 
									PopupDialogScreen(
										STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICKCONFIRM_TITLE.." "..displayName,
										STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICKCONFIRM_BODY.." "..displayName.."?",
										{ 
											{text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() Voting:VoteKick(v.userid) TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end},
											{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
										}
								))
							else
								TheFrontEnd:PushScreen( 
									PopupDialogScreen(
										STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICKREPEAT_TITLE, 
										STRINGS.UI.PLAYERSTATUSSCREEN.VOTEKICKREPEAT_BODY, 
										{ 
											{text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() end}
										}
								))
							end
						end
					end)
					if not Voting:VoteKickEnabled() or not Voting:EnoughPlayersForVoteKick() then
				    playerListing.kick:Hide()
				end
			end
		end

		return playerListing
	end

	if not self.scroll_list then
		self.scroll_list = self.root:AddChild(ScrollableList(ClientObjs, 380, 370, 60, 5, listingConstructor, nil, nil, nil, nil, nil, -15))
		self.scroll_list:SetPosition(190, -35)
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
                bg:SetPosition(-170, 156 - 65 * (i - 1))
                bg:MoveToBack()
                table.insert(self.bgs, bg)
            end
        end
    end

	self:StartUpdating()
end

return PlayerStatusScreen