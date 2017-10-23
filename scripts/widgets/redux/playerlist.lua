local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local PlayerBadge = require "widgets/playerbadge"

local TEMPLATES = require "widgets/redux/templates"

local VOICE_MUTE_COLOUR = { 242 / 255, 99 / 255, 99 / 255, 255 / 255 }
local VOICE_ACTIVE_COLOUR = { 99 / 255, 242 / 255, 99 / 255, 255 / 255 }
local VOICE_IDLE_COLOUR = { 1, 1, 1, 1 }

local PlayerInfoListing_width = 220
local PlayerInfoListing_height = 37

local function GetCharacterPrefab(data)
	if data == nil then
		return ""
	end
	
	if data.prefab and data.prefab ~= "" then
		return data.prefab
	end
	
	if data.lobbycharacter and data.lobbycharacter ~= "" then
		return data.lobbycharacter
	end
	
	return ""
end

local PlayerInfoListing = Class(Widget, function(self, player, nextWidgets)
    Widget._ctor(self, "PlayerInfoListing")
    self:DoInit(player, nextWidgets)
end)

function PlayerInfoListing:doButtonFocusHookups(nextWidgets)
    local rightFocusMoveSet = false

    if self.mute:IsVisible() then
        self.mute:SetFocusChangeDir(MOVE_LEFT, self.viewprofile)
        self.mute:SetFocusChangeDir(MOVE_RIGHT, nextWidgets.right)
        self.mute:SetFocusChangeDir(MOVE_DOWN, nextWidgets.down)
        rightFocusMoveSet = true
        self.focus_forward = self.mute
    end

    if self.viewprofile:IsVisible() then
        if self.mute:IsVisible() then 
            self.viewprofile:SetFocusChangeDir(MOVE_RIGHT, self.mute)
        else
            self.viewprofile:SetFocusChangeDir(MOVE_RIGHT, nextWidgets.right)
        end
        rightFocusMoveSet = true

        self.focus_forward:SetFocusChangeDir(MOVE_DOWN, nextWidgets.down)
        self.focus_forward = self.viewprofile
    end

    if not rightFocusMoveSet then
        self:SetFocusChangeDir(MOVE_RIGHT, nextWidgets.right)
    end

    self:SetFocusChangeDir(MOVE_DOWN, nextWidgets.down)
end

function PlayerInfoListing:DoInit(v, nextWidgets)
    local empty = v == nil or next(v) == nil

    self.userid = not empty and v.userid or nil

    local nudge_x = -5
    local name_badge_nudge_x = 15
    -- Widget contents are centred under root.
    local x = -PlayerInfoListing_width/2 + nudge_x+name_badge_nudge_x

    self.bg = self:AddChild(Image("images/ui.xml", "blank.tex"))
    self.bg:ScaleToSize(PlayerInfoListing_width, PlayerInfoListing_height)
    if empty then
        self.bg:Hide()
    end

    -- TODO(dbriscoe): Need new outline/background
    self.highlight = self:AddChild(Image("images/scoreboard.xml", "row_short_goldoutline.tex"))
    self.highlight:SetPosition(123-PlayerInfoListing_width/2, 0)
    self.highlight:ScaleToSize(215,50)
    self.highlight:Hide()

    self.characterBadge = nil
    if empty then
        self.characterBadge = self:AddChild(PlayerBadge("", DEFAULT_PLAYER_COLOUR, false, 0))
        self.characterBadge:Hide()
    else
        --print("player data is ")
        --dumptable(v)
        self.characterBadge = self:AddChild(PlayerBadge(GetCharacterPrefab(v), v.colour or DEFAULT_PLAYER_COLOUR, v.performance ~= nil, v.userflags or 0))
    end
    self.characterBadge:SetScale(.45)
    self.characterBadge:SetPosition(x+nudge_x+name_badge_nudge_x,0,0)

    self.adminBadge = self:AddChild(ImageButton("images/avatars.xml", "avatar_admin.tex"))
    self.adminBadge:Disable()
    self.adminBadge:SetPosition(x-12+nudge_x+name_badge_nudge_x,-10,0)  
    self.adminBadge.image:SetScale(.18)
    self.adminBadge.scale_on_focus = false
    self.adminBadge:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.ADMIN, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
    if empty or not v.admin then
        self.adminBadge:Hide()
    end
    x = x + 30

    self.name = self:AddChild(Text(TALKINGFONT, 24))
    self.name._align =
    {
        maxwidth = 119,
        maxchars = 22,
        x = x + nudge_x+name_badge_nudge_x,
        y = -2.5,
    }
    self.name.SetDisplayNameFromData = function(self, data, playerlist)
        local displayName = ""
        if data then
            displayName = data.name
            if playerlist then
                displayName = playerlist:GetDisplayName(data)
            end
        end
        self:SetTruncatedString(displayName, self._align.maxwidth, self._align.maxchars, true)
        local w, h = self:GetRegionSize()
        self:SetPosition(self._align.x + w * .5, self._align.y, 0)
    end
    self.name:SetDisplayNameFromData(v)
    x = x + 141

    -- Randomize only for testing
    local colours = nil --GetAvailablePlayerColours()
    if colours then
        self.name:SetColour(unpack(colours[math.random(#colours)])) 
    else
        self.name:SetColour(unpack(not empty and v.colour or DEFAULT_PLAYER_COLOUR))
    end

    local owner = TheNet:GetUserID()
    local scale = 0.234
    
    self.viewprofile = self:AddChild(ImageButton("images/scoreboard.xml", "addfriend.tex"))
    self.viewprofile:SetPosition(x+nudge_x,0,0)
    self.viewprofile:SetNormalScale(scale)
    self.viewprofile:SetFocusScale(scale * 1.1)
    self.viewprofile:SetFocusSound("dontstarve/HUD/click_mouseover")
    self.viewprofile:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.VIEWPROFILE, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
    self.viewprofile:SetOnClick(
        function()
            -- Can't do this here because HUD doesn't exist yet. TODO: add the playeravatarpopup to frontend, or wrap it in a screen.
            --ThePlayer.HUD:OpenPlayerAvatarPopup(displayName, v, true)
            if v.netid ~= nil then
                TheNet:ViewNetProfile(v.netid)
            end
        end)
    if empty or v.userid == owner or not TheNet:IsNetIDPlatformValid(v.netid) then
        self.viewprofile:Hide()
    end
    x = x + 25

    self.isMuted = v.muted == true

    self.mute = self:AddChild(ImageButton("images/scoreboard.xml", "chat.tex"))
    self.mute:SetPosition(x+nudge_x,0,0)
    self.mute:SetNormalScale(scale)
    self.mute:SetFocusScale(scale * 1.1)
    self.mute:SetFocusSound("dontstarve/HUD/click_mouseover")
    self.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE, { font = NEWFONT_OUTLINE, size = 24, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
    self.mute.image.inst.OnUpdateVoice = function(inst)
        inst.widget:SetTint(unpack(self.userid ~= nil and TheNet:IsVoiceActive(self.userid) and VOICE_ACTIVE_COLOUR or VOICE_IDLE_COLOUR))
    end
    self.mute.image.inst.SetMuted = function(inst, muted)
        if muted then
            inst.widget:SetTint(unpack(VOICE_MUTE_COLOUR))
            if inst._task ~= nil then
                inst._task:Cancel()
                inst._task = nil
            end
        else
            inst:OnUpdateVoice()
            if inst._task == nil then
                inst._task = inst:DoPeriodicTask(1, inst.OnUpdateVoice)
            end
        end
    end
    self.mute.image.inst.DisableMute = function(inst)
        inst.widget:SetTint(unpack(VOICE_IDLE_COLOUR))
        if inst._task ~= nil then
            inst._task:Cancel()
            inst._task = nil
        end
    end
    local gainfocusfn = self.mute.OnGainFocus
    self.mute:SetOnClick(
        function()
            if self.userid ~= nil then
                self.isMuted = not self.isMuted
                TheNet:SetPlayerMuted(self.userid, self.isMuted)
                if self.isMuted then
                    self.mute.image_focus = "mute.tex"
                    self.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
                    self.mute:SetTextures("images/scoreboard.xml", "mute.tex") 
                    self.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
                else
                    self.mute.image_focus = "chat.tex"
                    self.mute.image:SetTexture("images/scoreboard.xml", "chat.tex")
                    self.mute:SetTextures("images/scoreboard.xml", "chat.tex") 
                    self.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE)
                end
                self.mute.image.inst:SetMuted(self.isMuted)
            end
        end)

    if self.isMuted then
        self.mute.image_focus = "mute.tex"
        self.mute.image:SetTexture("images/scoreboard.xml", "mute.tex") 
        self.mute:SetTextures("images/scoreboard.xml", "mute.tex") 
        self.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
    end
    self.mute.image.inst:SetMuted(self.isMuted)

    if empty or v.userid == owner then
        self.mute:Hide()
        self.mute.image.inst:DisableMute()
    end
    x = x + 25

    self.OnGainFocus = function()
        -- self.name:SetSize(26)
        if not empty then
            self.highlight:Show()
        end
    end
    self.OnLoseFocus = function()
        -- self.name:SetSize(21)
        self.highlight:Hide()
    end

    self:doButtonFocusHookups(nextWidgets)
end

local function UpdatePlayerListing(context, widget, data, index)
    local empty = data == nil or next(data) == nil

    widget.userid = not empty and data.userid or nil

    if empty then
        widget.bg:Hide()
    else
        widget.bg:Show()
    end

    if empty then
        widget.characterBadge:Hide()
    else
        widget.characterBadge:Set(GetCharacterPrefab(data), data.colour or DEFAULT_PLAYER_COLOUR, data.performance ~= nil, data.userflags or 0)
        widget.characterBadge:Show()
    end

    if not empty and data.admin then
        widget.adminBadge:Show()
    else
        widget.adminBadge:Hide()
    end

    widget.name:SetColour(unpack(not empty and data.colour or DEFAULT_PLAYER_COLOUR))
    widget.name:SetDisplayNameFromData(data, context.playerlist)

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

    if not empty then
        widget.isMuted = data.muted == true
        if widget.isMuted then
            widget.mute.image_focus = "mute.tex"
            widget.mute.image:SetTexture("images/scoreboard.xml", "mute.tex")
            widget.mute:SetTextures("images/scoreboard.xml", "mute.tex")  
            widget.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.UNMUTE)
        else
            widget.mute.image_focus = "chat.tex"
            widget.mute.image:SetTexture("images/scoreboard.xml", "chat.tex")
            widget.mute:SetTextures("images/scoreboard.xml", "chat.tex") 
            widget.mute:SetHoverText(STRINGS.UI.PLAYERSTATUSSCREEN.MUTE)
        end
    end

    if empty or data.userid == owner then
        widget.mute:Hide()
        widget.mute.image.inst:DisableMute()
    else
        widget.mute:Show()
        widget.mute.image.inst:SetMuted(widget.isMuted)
    end
end

--------------------------------------------------------------------------
--  A list of players for the lobby screen
--
local PlayerList = Class(Widget, function(self, owner, nextWidgets)
    self.owner = owner
    Widget._ctor(self, "PlayerList")

    self.proot = self:AddChild(Widget("ROOT"))

    self:BuildPlayerList(nil, nextWidgets)

    self.focus_forward = self.scroll_list
end)

--For ease of overriding in mods
function PlayerList:GetDisplayName(clientrecord)
    return clientrecord.name or ""
end

function PlayerList:BuildPlayerList(players, nextWidgets)
    if not self.player_list then 
        self.player_list = self.proot:AddChild(Widget("player_list"))
        self.player_list:SetPosition(190, 680)
    end

    if not self.title_banner then
        self.title_banner = self.player_list:AddChild(Image("images/global_redux.xml", "player_list_banner.tex"))
        self.title_banner:SetScale(.7)
        self.title_banner:SetPosition(-15, 0)
        
        local sub_banner = self.title_banner:AddChild(Image("images/global_redux.xml", "player_list_banner.tex"))
        sub_banner:SetScale(-1)
        sub_banner:SetPosition(0, -410)
    end

    if not self.title then
        self.title = self.title_banner:AddChild(Text(HEADERFONT, 35, STRINGS.UI.LOBBYSCREEN.PLAYERLIST, UICOLOURS.HIGHLIGHT_GOLD))
        self.title:SetRegionSize(200, 50)
        self.title:SetPosition(-100, 10)
        self.title:SetHAlign(ANCHOR_LEFT)
    end

    if not self.players_number then
        self.players_number = self.title_banner:AddChild(Text(HEADERFONT, 35, "x/y", UICOLOURS.HIGHLIGHT_GOLD))
        self.players_number:SetPosition(50, 10) 
        self.players_number:SetRegionSize(300, 50)
        self.players_number:SetHAlign(ANCHOR_RIGHT)
    end

    if players == nil then
        players = self:GetPlayerTable()
    end

    local maxPlayers = TheNet:GetServerMaxPlayers()
    self.players_number:SetString(subfmt(STRINGS.UI.LOBBYSCREEN.NUM_PLAYERS_FMT, {num = #players, max = tostring(maxPlayers or "?")}))

    if not self.scroll_list then
        local function ScrollWidgetsCtor(context, index)
            return PlayerInfoListing(players[index] or {}, nextWidgets)
        end

        local tooltip_pad = 50
        self.scroll_list = self.player_list:AddChild(TEMPLATES.ScrollingGrid(
                players,
                {
                    context = {playerlist = self},
                    widget_width  = PlayerInfoListing_width + tooltip_pad,
                    widget_height = PlayerInfoListing_height,
                    num_visible_rows = 6,
                    num_columns      = 1,
                    item_ctor_fn = ScrollWidgetsCtor,
                    apply_fn = UpdatePlayerListing,
                    scrollbar_offset = 0, -- see tooltip_pad
                    peek_percent = 0.5, -- safe because empty widgets are hidden
                }
            ))
        self.scroll_list:SetPosition(-127+PlayerInfoListing_width/2, -150)
    else
        self.scroll_list:SetItemsData(players)
    end
end

function PlayerList:GetPlayerTable()
    local ClientObjs = TheNet:GetClientTable()
    if ClientObjs == nil then
        return {}
    elseif TheNet:GetServerIsClientHosted() then
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

function PlayerList:Refresh(next_widgets)
    local players = self:GetPlayerTable()
    self.scroll_list:SetItemsData(players)
    
    local maxPlayers = TheNet:GetServerMaxPlayers()
    self.players_number:SetString(subfmt(STRINGS.UI.LOBBYSCREEN.NUM_PLAYERS_FMT, {num = #players, max = tostring(maxPlayers or "?")}))
end

return PlayerList
