local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local TextButton = require "widgets/textbutton"
local Button = require "widgets/button"
local ServerAdminScreen = require "screens/serveradminscreen"

local Text = require "widgets/text"
local Image = require "widgets/image"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"

local TextEdit = require "widgets/textedit"

local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"

local Widget = require "widgets/widget"
local Levels = require "map/levels"

local CustomizationScreen = require "screens/customizationscreen"
local PopupDialogScreen = require "screens/popupdialog"

local OnlineStatus = require "widgets/onlinestatus"

local ScrollableList = require "widgets/scrollablelist"

require("constants")
require("tuning")

local filters_per_page = 6

local font_size = 35
if JapaneseOnPS4() then
    font_size = 35 * 0.75;
end

local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"]]
local VALID_PASSWORD_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local STRING_MAX_LENGTH = 254 -- http://tools.ietf.org/html/rfc5321#section-4.5.3.1
local SERVER_NAME_MAX_LENGTH = 80

local screen_fade_time = .25


local ServerCreationScreen = Class(Screen, function(self, customoptions, slotdata, cb)
    Widget._ctor(self, "ServerCreationScreen")
    	
    self.bg = self:AddChild(Image("images/bg_plain.xml", "bg.tex"))
    TintBackground(self.bg)

    self.customoptions = customoptions
    self.cb = cb

    local left_col = -RESOLUTION_X*.05 - 285
    local right_col = RESOLUTION_X*.40 - 230
	
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.scaleroot = self:AddChild(Widget("scaleroot"))
    self.scaleroot:SetVAnchor(ANCHOR_MIDDLE)
    self.scaleroot:SetHAnchor(ANCHOR_MIDDLE)
    self.scaleroot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.root = self.scaleroot:AddChild(Widget("root"))
    self.root:SetScale(.9)
    self.root:SetPosition(0,10,0)

    self.load_panel_bg = self.root:AddChild(Image("images/fepanels_dst.xml", "tall_panel.tex"))
    self.load_panel_bg:SetScale(1,.97)
    self.load_panel_bg:SetPosition(left_col,-5)

    self.detail_panel_bg = self.root:AddChild(Image( "images/fepanels_dst.xml", "tall_panel.tex" ))
    self.detail_panel_bg:SetPosition(right_col,0)    
    self.detail_panel_bg:SetScale(1.55,1)

    self.fg = self.scaleroot:AddChild(Image("images/fg_trees.xml", "trees.tex"))
    self.fg:SetVRegPoint(ANCHOR_MIDDLE)
    self.fg:SetHRegPoint(ANCHOR_MIDDLE)
    self.fg:SetVAnchor(ANCHOR_MIDDLE)
    self.fg:SetHAnchor(ANCHOR_MIDDLE)
    self.fg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.clickroot = self.scaleroot:AddChild(Widget("clickroot"))
    self.clickroot:SetScale(.9)
    self.clickroot:SetPosition(0,10,0)

    self.RoG = false

    self.saveslot = SaveGameIndex:GetLastUsedSlot()

    self.slotdata = slotdata or {}

    self.load_panel = self.clickroot:AddChild(Widget("loadpanel"))
    self.load_panel:SetPosition(left_col, 0)

    self.detail_panel = self.clickroot:AddChild( Widget("detailpanel") )
    self.detail_panel:SetPosition(right_col, 0)

    self:MakeDetailPanel(left_col, right_col)
    self:MakeButtons()

    if self.saveslot < 0 or SaveGameIndex:IsSlotEmpty(self.saveslot) then
        for k = 1, NUM_DST_SAVE_SLOTS do
            if SaveGameIndex:IsSlotEmpty(k) then
                self.saveslot = k
                break
            end
        end
    end

    self.onlinestatus = self.fg:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)

    self.refresh_load_panel = false

    self:RefreshLoadTiles()    

    self.default_focus = self.load_slots_menu

    self:DoFocusHookUps()

    self:OnClickTile(self.saveslot, true)
    self:Enable()
end)

function ServerCreationScreen:OnBecomeActive()
    ServerCreationScreen._base.OnBecomeActive(self)
    self:Enable()
end

function ServerCreationScreen:OnBecomeInactive()
    ServerCreationScreen._base.OnBecomeInactive(self)
end

function ServerCreationScreen:OnDestroy()
	self._base.OnDestroy(self)
end

function ServerCreationScreen:DeleteSlot(slot)
    local menu_items = 
    {
        -- ENTER
        {
            text=STRINGS.UI.SERVERCREATIONSCREEN.DELETE, 
            cb = function()
                -- EnableAllMenuDLC() 
                TheFrontEnd:PopScreen()
                
                SaveGameIndex:DeleteSlot(slot, function() 
                    self.load_slots_menu.items[slot].text:SetString(STRINGS.UI.SERVERCREATIONSCREEN.NEWGAME)
                    self.load_slots_menu.items[slot].text:SetPosition(0,0,0)
                    self.load_slots_menu.items[slot].portraitbg:Hide()
                    self.load_slots_menu.items[slot].portrait:Hide()
                    self:UpdatePanels(slot)
                end)

                self:RefreshLoadTiles()    
                self:OnClickTile(self.saveslot, true)
                self:Enable()
            end
        },
        -- ESC
        {
            text=STRINGS.UI.SERVERCREATIONSCREEN.CANCEL, 
            cb = function() 
                TheFrontEnd:PopScreen() 
            end
        },
    }

    TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.DELETE.." "..STRINGS.UI.SERVERCREATIONSCREEN.SLOT.." "..slot, STRINGS.UI.SERVERCREATIONSCREEN.SURE, menu_items ) )
end

function ServerCreationScreen:OnConfigureButton()
    local function onSet(options, dlc)
        if options and self.editable_customoptions then
            self.customoptions = options
        end
    end

    -- Don't care about RoG for now
    -- if self.prevworldcustom ~= self.RoG and IsDLCInstalled(REIGN_OF_GIANTS) then
    --     local prev = self.prevcustomoptions
    --     self.prevcustomoptions = self.customoptions
    --     self.customoptions = prev
    --     package.loaded["map/customise"] = nil
    -- end
    -- self.prevworldcustom = self.RoG

    -- Clean up the preset setting since we're going back to customization screen, not to worldgen
    if self.customoptions and self.customoptions.actualpreset then
        self.customoptions.preset = self.customoptions.actualpreset
        self.customoptions.actualpreset = nil
    end
    -- Clean up the tweak table since we're going back to customization screen, not to worldgen
    if self.customoptions then
        self.customoptions.presetdata = nil
    end

    local resume_customoptions = nil
    self.editable_customoptions = true
    if self.saveslot > 0 and not SaveGameIndex:IsSlotEmpty(self.saveslot) then
        resume_customoptions = SaveGameIndex:GetSlotGenOptions(self.saveslot)
        self.editable_customoptions = false
    end

    self:Disable()
    TheFrontEnd:Fade(false, screen_fade_time, function()
        TheFrontEnd:PushScreen(CustomizationScreen(Profile, onSet, resume_customoptions or self.customoptions, self.RoG,  self.editable_customoptions))
        TheFrontEnd:Fade(true, screen_fade_time)
    end)
end


function BuildTagsStringHosting(creationScreen)
    if TheNet:IsDedicated() then return nil end
    
    local tagsTable = {}

    table.insert(tagsTable, creationScreen.game_mode.spinner:GetSelectedData())
    
    if creationScreen.pvp.spinner:GetSelectedData() then
        table.insert(tagsTable, "pvp")
    end
    
    if creationScreen.friends_only.spinner:GetSelectedData() then
        table.insert(tagsTable, "friendsonly")
    end
    
    return BuildTagsStringCommon(tagsTable)
end

function ServerCreationScreen:Create()
    local function onsaved()    
        StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = self.saveslot})
    end
    local function GetEnabledDLCs()
        local dlc = {REIGN_OF_GIANTS = self.RoG}
        return dlc
    end
    local function GetModTags()
		local mod_tags = KnownModIndex:GetEnabledModTags()
		local mod_tags_string = ""
		for i,mod_tag in pairs( mod_tags ) do
			mod_tags_string = mod_tags_string..", "..mod_tag
		end
		mod_tags_string = string.sub( mod_tags_string, 3 ) --remove preceeding ", "
		return mod_tags_string
    end
    local function BuildTagsString(tagsString)
        if not tagsString then tagsString = "" end
        tagsString = tagsString..self.game_mode.spinner:GetSelectedData()
        if self.pvp.spinner:GetSelectedData() then
            if string.len(tagsString) > 0 then
                tagsString = tagsString..", "
            end
            tagsString = tagsString.."pvp"
        end
        if self.friends_only.spinner:GetSelectedData() then
            if string.len(tagsString) > 0 then
                tagsString = tagsString..", "
            end
            tagsString = tagsString.."friendsonly"
        end
        if string.len(tagsString) > 0 then
            tagsString = tagsString..", "
        end

        tagsString = tagsString..GetModTags()
        
        if string.sub(tagsString,string.len(tagsString)-1,string.len(tagsString)) == ", " then
            tagsString = string.sub(tagsString,1,string.len(tagsString)-2)
        end
        return tagsString
    end

	local function onCreate()
		-- Check that the player has selected a spot
		if self.saveslot < 0 then
			-- If not, look for the first empty one
			local emptySlot = nil
			for k = 1, NUM_DST_SAVE_SLOTS do
				if SaveGameIndex:IsSlotEmpty(k) then
					emptySlot = k
					break
				end
			end

			-- If we found an empty slot, make that our save slot and call Create() again
			if emptySlot then
				self.saveslot = emptySlot
				self:Create()
			else -- Otherwise, show dialog informing that they must either load a game or delete a game
				local popup = PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.FULLSLOTSTITLE, STRINGS.UI.SERVERCREATIONSCREEN.FULLSLOTSBODY,
					{
						{text=STRINGS.UI.SERVERCREATIONSCREEN.OK, cb = function()
							TheFrontEnd:PopScreen() 
						end},
					})
				TheFrontEnd:PushScreen( popup )
			end
		else
			self.server_name.textbox:SetEditing(false)
			self.server_pw.textbox:SetEditing(false)
			self.server_desc.textbox:SetEditing(false)
			TheNet:SetDefaultServerName(self.server_name.textbox:GetString())
			TheNet:SetDefaultServerPassword(self.server_pw.textbox:GetLineEditString())
			TheNet:SetDefaultServerDescription(self.server_desc.textbox:GetString())
			TheNet:SetDefaultGameMode(self.game_mode.spinner:GetSelectedData())
			TheNet:SetDefaultMaxPlayers(self.max_players.spinner:GetSelectedData())
			TheNet:SetDefaultPvpSetting(self.pvp.spinner:GetSelectedData())
			TheNet:SetFriendsOnlyServer(self.friends_only.spinner:GetSelectedData())
			
            -- Collect the tags we want and set the tags string
            local tags = BuildTagsStringHosting(self)
            TheNet:SetServerTags(tags)

			local start_in_online_mode = self.online_mode.spinner:GetSelectedData()
            if TheFrontEnd:GetIsOfflineMode() then
                start_in_online_mode = false
            end
			local server_started = TheNet:StartServer( start_in_online_mode )
			if server_started == true then
				self:Disable()
				DisableAllDLC()
				local serverdata = 
				{
					name = self.server_name.textbox:GetString(),
					password = self.server_pw.textbox:GetLineEditString(),
					description = self.server_desc.textbox:GetString(),
					game_mode = self.game_mode.spinner:GetSelectedData(),
					maxplayers = self.max_players.spinner:GetSelectedData(),
					pvp = self.pvp.spinner:GetSelectedData(),
					friends_only = self.friends_only.spinner:GetSelectedData(),
					online_mode = self.online_mode.spinner:GetSelectedData(), 
				}
				TheFrontEnd:Fade(false, screen_fade_time, function() 
					if SaveGameIndex:IsSlotEmpty(self.saveslot) then
						SaveGameIndex:StartSurvivalMode(self.saveslot, self.customoptions, serverdata, onsaved) 
					else
						SaveGameIndex:UpdateServerData(self.saveslot, serverdata, onsaved)
					end
				end )
			end
		end
	end
		
	if not self.online_mode.spinner:GetSelectedData() then
	    local offline_mode_body = ""
	    if not SaveGameIndex:IsSlotEmpty(self.saveslot) then
	        offline_mode_body = STRINGS.UI.SERVERCREATIONSCREEN.OFFLINEMODEBODYRESUME
	    else
	        -- new game
	        offline_mode_body = STRINGS.UI.SERVERCREATIONSCREEN.OFFLINEMODEBODYCREATE
	    end
	    
		local confirm_offline_popup = PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.OFFLINEMODETITLE, offline_mode_body,
		{
			{text=STRINGS.UI.SERVERCREATIONSCREEN.OK, cb = onCreate},
			{text=STRINGS.UI.SERVERCREATIONSCREEN.CANCEL, cb = function()
				TheFrontEnd:PopScreen() 
			end}
		})
		TheFrontEnd:PushScreen(confirm_offline_popup)
	else
		if not TheNet:IsOnlineMode() or TheFrontEnd:GetIsOfflineMode() then
			local online_only_popup = PopupDialogScreen(STRINGS.UI.SERVERCREATIONSCREEN.ONLINEONYTITLE, STRINGS.UI.SERVERCREATIONSCREEN.ONLINEONLYBODY,
			{
				{text=STRINGS.UI.SERVERCREATIONSCREEN.OK, cb = function()
					TheFrontEnd:PopScreen() 
				end}
			})
			TheFrontEnd:PushScreen(online_only_popup)
		else
			onCreate()
		end
	end
end

function ServerCreationScreen:Cancel()
    self:Disable()
    self.server_name.textbox:SetEditing(false)
    self.server_pw.textbox:SetEditing(false)
    self.server_desc.textbox:SetEditing(false)
    TheFrontEnd:Fade(false, screen_fade_time, function()
        if self.cb then
            self.cb(self.customoptions, self.slotdata)
        end
        TheFrontEnd:PopScreen()
        TheFrontEnd:Fade(true, screen_fade_time)
    end)
end

function ServerCreationScreen:UpdatePanels(slotnum, prevslot)
    -- No save data
    if slotnum < 0 or SaveGameIndex:IsSlotEmpty(slotnum) then
        if not TheInput:ControllerAttached() then
            self.blacklist_button:Disable()
            self.blacklist_button.text:SetSize(36)
            self.configure_world_button:SetText(STRINGS.UI.SERVERCREATIONSCREEN.WORLD)
            self.delete_button:Disable()
            self.create_button:SetText(STRINGS.UI.SERVERCREATIONSCREEN.CREATE)
            self.create_button:Enable()
        end

        -- no slot, so hide all the details and set all the text boxes back to their defaults
        if prevslot and prevslot > 0 then
            -- Remember what was typed/set
            self.slotdata[prevslot] =
            {
                pvp = self.pvp.spinner:GetSelectedData(),
                game_mode = self.game_mode.spinner:GetSelectedData(),
                friends_only = self.friends_only.spinner:GetSelectedData(),
                online_mode = self.online_mode.spinner:GetSelectedData(),-- and TheNet:IsOnlineMode(),
                max_players = self.max_players.spinner:GetSelectedData(),
                server_name = self.server_name.textbox:GetString(),
                server_pw = self.server_pw.textbox:GetLineEditString(),
                server_desc = self.server_desc.textbox:GetString(),
            }
            -- Duplicate prevslot's data into our new slot if it was also a blank slot
            if SaveGameIndex:IsSlotEmpty(prevslot) then
                self.slotdata[slotnum] =
                {
                    pvp = self.pvp.spinner:GetSelectedData(),
                    game_mode = self.game_mode.spinner:GetSelectedData(),
                    friends_only = self.friends_only.spinner:GetSelectedData(),
                    online_mode = self.online_mode.spinner:GetSelectedData(),-- and TheNet:IsOnlineMode(),
                    max_players = self.max_players.spinner:GetSelectedData(),
                    server_name = self.server_name.textbox:GetString(),
                    server_pw = self.server_pw.textbox:GetLineEditString(),
                    server_desc = self.server_desc.textbox:GetString(),
                }
            end
        end
        local pvp = false
        if self.slotdata[prevslot] ~= nil and self.slotdata[prevslot].pvp ~= nil then
            pvp = self.slotdata[prevslot].pvp
        else
            pvp = TheNet:GetDefaultPvpSetting()
        end
        local online = true
        if self.slotdata[prevslot] ~= nil and self.slotdata[prevslot].online_mode ~= nil then
            online = self.slotdata[prevslot].online_mode and not TheFrontEnd:GetIsOfflineMode()
        else
            online = TheNet:IsOnlineMode() and not TheFrontEnd:GetIsOfflineMode()
        end 
        self.pvp.spinner:SetSelected(pvp)
        self.game_mode.spinner:SetSelected(self.slotdata[prevslot] and self.slotdata[prevslot].game_mode or TheNet:GetDefaultGameMode())
        self.game_mode.spinner:SetHoverText(STRINGS.UI.SERVERCREATIONSCREEN[string.upper(self.game_mode.spinner:GetSelectedData()).."_TOOLTIP"])
        self.friends_only.spinner:SetSelected(self.slotdata[prevslot] and self.slotdata[prevslot].friends_only or TheNet:GetFriendsOnlyServer())
        self.online_mode.spinner:SetSelected(online)
        self.max_players.spinner:SetSelected(self.slotdata[prevslot] and self.slotdata[prevslot].max_players or TheNet:GetDefaultMaxPlayers())
        self.server_name.textbox:SetString(self.slotdata[prevslot] and self.slotdata[prevslot].server_name or TheNet:GetDefaultServerName())
        self.server_pw.textbox:SetString(self.slotdata[prevslot] and self.slotdata[prevslot].server_pw or TheNet:GetDefaultServerPassword())
        self.server_desc.textbox:SetString(self.slotdata[prevslot] and self.slotdata[prevslot].server_desc or TheNet:GetDefaultServerDescription())
        self.server_day:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERDAY_NEW)

		if TheNet:IsOnlineMode() and not TheFrontEnd:GetIsOfflineMode() then
			self.online_mode.spinner:Enable()
            self.friends_only.spinner:Enable()
		end

        self.game_mode.spinner:Enable()
		
    else -- Save data
        if prevslot and prevslot > 0 then
            -- remember what was typed/set
            self.slotdata[prevslot] =
            {
                pvp = self.pvp.spinner:GetSelectedData(),
                game_mode = self.game_mode.spinner:GetSelectedData(),
                friends_only = self.friends_only.spinner:GetSelectedData(),
                online_mode = self.online_mode.spinner:GetSelectedData(),
                max_players = self.max_players.spinner:GetSelectedData(),
                server_name = self.server_name.textbox:GetString(),
                server_pw = self.server_pw.textbox:GetLineEditString(),
                server_desc = self.server_desc.textbox:GetString(),
            }
        end

        if not TheInput:ControllerAttached() then
            self.blacklist_button:Enable()
            self.blacklist_button.text:SetSize(40)
            self.delete_button:Enable()
            self.create_button:SetText(STRINGS.UI.SERVERCREATIONSCREEN.RESUME)
            self.configure_world_button:SetText(STRINGS.UI.SERVERCREATIONSCREEN.VIEWWORLD)
        end

        self.server_day:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERDAY.." "..(SaveGameIndex:GetSlotDay(slotnum) or STRINGS.UI.SERVERLISTINGSCREEN.UNKNOWN))
        -- world = 1, -- world (i.e. teleportato) doesn't exist yet, but leaving this here as a reminder
        -- waiting on hooks for char details
        
        local server_data = SaveGameIndex:GetSlotServerData(slotnum)
        if server_data ~= nil then
            local pvp = false
            if self.slotdata[slotnum] ~= nil and self.slotdata[slotnum].pvp ~= nil then
                pvp = self.slotdata[slotnum].pvp
            else
                pvp = server_data.pvp
            end
            local online = true
            if self.slotdata[slotnum] ~= nil and self.slotdata[slotnum].online_mode ~= nil then
                online = self.slotdata[slotnum].online_mode
            else
                online = server_data.online_mode
            end 
            self.game_mode.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].game_mode or (server_data.game_mode ~= nil and server_data.game_mode or DEFAULT_GAME_MODE ))
            self.game_mode.spinner:SetHoverText(STRINGS.UI.SERVERCREATIONSCREEN[string.upper(self.game_mode.spinner:GetSelectedData()).."_TOOLTIP"])
            self.pvp.spinner:SetSelected(pvp)
            self.friends_only.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].friends_only or server_data.friends_only)
            self.online_mode.spinner:SetSelected(online)
            self.max_players.spinner:SetSelected(self.slotdata[slotnum] and self.slotdata[slotnum].max_players or server_data.maxplayers)
            self.server_name.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_name or server_data.name)
            self.server_pw.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_pw or server_data.password)
            self.server_desc.textbox:SetString(self.slotdata[slotnum] and self.slotdata[slotnum].server_desc or server_data.description)
        end
		
		-- No editing online or game mode for servers that have already been created
		self.online_mode.spinner:Disable()
        self.game_mode.spinner:Disable()
        if self.online_mode.spinner:GetSelectedData() == false then
            self.friends_only.spinner:Disable()
        else
            self.friends_only.spinner:Enable()
        end
    end
    
end

function ServerCreationScreen:OnControl(control, down)
    if ServerCreationScreen._base.OnControl(self, control, down) then return true end

    -- Force these damn things to gobble controls if they're editing (stupid missing focus/hover distinction)
    if self.server_name.textbox and self.server_name.textbox.editing or (TheInput:ControllerAttached() and self.server_name.focus) then
        self.server_name.textbox:OnControl(control, down)
        return true
    elseif self.server_pw.textbox and self.server_pw.textbox.editing or (TheInput:ControllerAttached() and self.server_pw.focus) then
        self.server_pw.textbox:OnControl(control, down)
        return true
    elseif self.server_desc.textbox and self.server_desc.textbox.editing or (TheInput:ControllerAttached() and self.server_desc.focus)  then
        self.server_desc.textbox:OnControl(control, down)
        return true
    end

    if not down then
        if control == CONTROL_CANCEL then 
            self:Cancel()
        else
            if self.saveslot < 0 or SaveGameIndex:IsSlotEmpty(self.saveslot) then
                if control == CONTROL_MENU_MISC_1 then
                    self:OnConfigureButton()
                elseif control == CONTROL_PAUSE and TheInput:ControllerAttached() then
                    self:Create()
                else
                    return false
                end
            else
                if control == CONTROL_MAP and TheInput:ControllerAttached() then
                    self:DeleteSlot(self.saveslot)
                elseif control == CONTROL_MENU_MISC_2 then
                    self:ShowServerAdmin()
                elseif control == CONTROL_MENU_MISC_1 then
                    self:OnConfigureButton()
                elseif control == CONTROL_PAUSE and TheInput:ControllerAttached() then
                    self:Create()
                else
                    return false
                end
            end
        end

        return true
    end
end

function ServerCreationScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    if self.saveslot < 0 or SaveGameIndex:IsSlotEmpty(self.saveslot) then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1) .. " " .. STRINGS.UI.SERVERCREATIONSCREEN.WORLD)
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.SERVERCREATIONSCREEN.CREATE)
    else
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MAP) .. " " .. STRINGS.UI.SERVERCREATIONSCREEN.DELETE_SLOT)
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_2) .. " " .. STRINGS.UI.SERVERCREATIONSCREEN.ADMIN)
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1) .. " " .. STRINGS.UI.SERVERCREATIONSCREEN.VIEWWORLD)
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.SERVERCREATIONSCREEN.RESUME)
    end

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    return table.concat(t, "  ")
end

local function MakeImgButton(parent, xPos, yPos, text, onclick, large)
    if not parent or not xPos or not yPos or not text or not onclick then return end

    local btn
    if large then
        btn = parent:AddChild(ImageButton("images/ui.xml", "button_large.tex", "button_large_over.tex", "button_large_disabled.tex", "button_large_onclick.tex"))
    else
        btn = parent:AddChild(ImageButton())
    end
    btn:SetPosition(xPos, yPos)
    btn:SetText(text)
    btn.text:SetColour(0,0,0,1)
    btn:SetFont(BUTTONFONT)
    btn:SetTextSize(40)
    btn:SetOnClick(onclick)

    return btn
end

function ServerCreationScreen:RefreshLoadTiles()

    if self.load_slots_menu then
        self.load_slots_menu:Kill()
    end
    
    self.load_slots_menu = self.load_panel:AddChild(Menu(nil, -88, false))
    self.load_slots_menu:SetPosition( 0, 195, 0)
    if TheInput:ControllerAttached() then
        self.load_slots_menu:SetPosition( 0, 175, 0)
    end

    for k = 1, NUM_DST_SAVE_SLOTS do
        local tile = self:MakeSaveTile(k)
        self.load_slots_menu:AddCustomItem(tile)
    end
end

function ServerCreationScreen:MakeSaveTile(slotnum)
    local widget = Widget("savetile")
    widget.base = widget:AddChild(Widget("base"))
    
    local isempty = SaveGameIndex:IsSlotEmpty(slotnum)

    --SaveGameIndex:LoadSlotCharacter is not cheap! Use it in FE only.
    --V2C: This comment is here as a warning to future copy&pasters - __-"
    local character = SaveGameIndex:LoadSlotCharacter(slotnum)
    local atlas = "images/saveslot_portraits"
    if character ~= nil then
        if not table.contains(GetActiveCharacterList(), character) then
            character = "random"
        elseif table.contains(MODCHARACTERLIST, character) then
            atlas = atlas.."/"..character
        end
        atlas = atlas..".xml"
    end

    widget.bg = widget.base:AddChild(UIAnim())
    widget.bg:GetAnimState():SetBuild("savetile")
    widget.bg:GetAnimState():SetBank("savetile")
    widget.bg:GetAnimState():PlayAnimation("anim")
    widget.bg:GetAnimState():SetMultColour(.5, .5, .5, 1)

    widget.portraitbg = widget.base:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
    widget.portraitbg:SetScale(.65, .65, 1)
    widget.portraitbg:SetPosition(-100, 0, 0)
    widget.portraitbg:SetClickable(false)   

    widget.portrait = widget.base:AddChild(Image())
    widget.portrait:SetClickable(false)
    if character ~= nil and not isempty then
        widget.portrait:SetTexture(atlas, character..".tex")
    else
        widget.portraitbg:Hide()
    end

    widget.portrait:SetScale(.65, .65, 1)
    widget.portrait:SetPosition(-100, 0, 0)

    widget.text = widget.base:AddChild(Text(BUTTONFONT, 36))
    widget.text:SetColour(0, 0, 0, 1)

    if isempty then -- No data
        widget.text:SetString(STRINGS.UI.SERVERCREATIONSCREEN.NEWGAME)
        widget.text:SetPosition(0, -2, 0)
    else -- We have data, show the relevant bit of info
        local servername = SaveGameIndex:GetSlotServerData(slotnum).name or ""
        if character == nil then
            widget.text:SetPosition(0, -2, 0)
            widget.text:SetTruncatedString(servername, 300, 60)
        else
            widget.text:SetPosition(50, -2, 0)
            widget.text:SetTruncatedString(servername, 200, 40)
        end
    end

    widget.text:SetVAlign(ANCHOR_MIDDLE)

    widget.bg:SetScale(1,.9,1)

    widget.OnGainFocus = function(self)
        Widget.OnGainFocus(self)
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
        widget.bg:SetScale(1.05,.95,1)
        widget.bg:GetAnimState():PlayAnimation("over")
    end

    local screen = self
    widget.OnLoseFocus = function(self)
        Widget.OnLoseFocus(self)
        widget.base:SetPosition(0,0,0)
        widget.bg:SetScale(1,.9,1)
        if screen.saveslot ~= slotnum then
            widget.bg:GetAnimState():PlayAnimation("anim")
        end
    end

    widget.OnControl = function(self, control, down)
        if control == CONTROL_ACCEPT then
            if down then 
                widget.base:SetPosition(0,-3,0)
            else
                widget.base:SetPosition(0,0,0) 
                screen:OnClickTile(slotnum)
            end
            return true
        end
    end

    widget.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.SERVERCREATIONSCREEN.SELECT_SLOT)   
        return table.concat(t, "  ")
    end

    return widget
end

function ServerCreationScreen:OnClickTile(slotnum, silent)
    local lastslot = self.saveslot
    self.saveslot = slotnum
    if not silent then
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")   
    end
    for k = 1, NUM_DST_SAVE_SLOTS do
        if k == slotnum then
            self.load_slots_menu.items[k].bg:GetAnimState():PlayAnimation("over")
            self.load_slots_menu.items[k].bg:GetAnimState():SetMultColour(0,0,0,1)
            self.load_slots_menu.items[k]:SetFocus()
        else
            self.load_slots_menu.items[k].bg:GetAnimState():PlayAnimation("anim")
            self.load_slots_menu.items[k].bg:GetAnimState():SetMultColour(.5,.5,.5,1)
        end
    end
    self:UpdatePanels(slotnum, lastslot)
end

function ServerCreationScreen:MakeDetailPanel(left_col, right_col)
    local label_width = 200
    local label_height = 50
    local label_offset = 275
    local edit_width = 500
    local edit_bg_padding = 60

    local serv_name_height = 150
    local desc_height = 60
    local pw_height = 0
    local spinners_height = -60
    local spinners_spacing = -62.5
    local space_between = 17

    local textbox_font_ratio = .8

    local right_edge = 500

    -- All Pages

    self.server_day = self.detail_panel:AddChild(Text(BUTTONFONT, 55))
    self.server_day:SetColour(0,0,0,1)
    self.server_day:SetPosition((edit_width * .5) - label_offset + space_between + 15, serv_name_height + 75)

    --#srosen need to make the width of these text boxes more dynamic based on the width of the string (for loc)
    self.server_name = Widget("name")
    self.server_name.label = self.server_name:AddChild(Text(BUTTONFONT, 35))
    self.server_name.label:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERNAME)
    self.server_name.label:SetHAlign(ANCHOR_LEFT)
    self.server_name.label:SetPosition(-240,0)
    self.server_name.label:SetColour(0,0,0,1)
    local w,h = self.server_name.label:GetRegionSize()
    self.server_name.textbox_bg = self.server_name.label:AddChild( Image("images/textboxes.xml", "textbox_long.tex") )
    self.server_name.textbox_bg:ScaleToSize(edit_width - w + space_between, label_height )
    self.server_name.textbox_bg:SetPosition( edit_width - 240, 0, 0)
    self.server_name.textbox = self.server_name.label:AddChild(TextEdit( BODYTEXTFONT, font_size*textbox_font_ratio, TheNet:GetDefaultServerName() ) )
    self.server_name.textbox:SetForceEdit(true)
    self.server_name.textbox:SetPosition(edit_width - 225 - space_between/2-5, 0, 0)
    self.server_name.textbox:SetRegionSize( edit_width - w - space_between-10, label_height )
    self.server_name.textbox:SetHAlign(ANCHOR_LEFT)
    self.server_name.textbox:SetFocusedImage( self.server_name.textbox_bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex" )
    self.server_name.textbox:SetTextLengthLimit( SERVER_NAME_MAX_LENGTH )
    self.server_name.textbox:SetCharacterFilter( VALID_CHARS )
    
    local screen = self
    self.server_name.OnGainFocus = function(self)
        Widget.OnGainFocus(self)
        screen.server_name.textbox:OnGainFocus()
    end
    self.server_name.OnLoseFocus = function(self)
        Widget.OnLoseFocus(self)
        screen.server_name.textbox:OnLoseFocus()
    end
    self.server_name.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        if not screen.server_name.textbox.editing and not screen.server_name.textbox.focus then
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.HELP.CHANGE_TEXT)   
        end
        return table.concat(t, "  ")
    end

    self.server_pw = Widget("pw")
    self.server_pw.label = self.server_pw:AddChild(Text(BUTTONFONT, 35))
    self.server_pw.label:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERPASSWORD)
    self.server_pw.label:SetHAlign(ANCHOR_LEFT)
    self.server_pw.label:SetPosition(-225,0)
    self.server_pw.label:SetColour(0,0,0,1)
    local w,h = self.server_pw.label:GetRegionSize()
    self.server_pw.textbox_bg = self.server_pw.label:AddChild( Image("images/textboxes.xml", "textbox_long.tex") )
    self.server_pw.textbox_bg:ScaleToSize(edit_width - w + space_between, label_height )
    self.server_pw.textbox_bg:SetPosition( edit_width - 240, 0, 0)
    self.server_pw.textbox = self.server_pw.label:AddChild(TextEdit( BODYTEXTFONT, font_size*textbox_font_ratio, TheNet:GetDefaultServerName() ) )
    self.server_pw.textbox:SetForceEdit(true)
    self.server_pw.textbox:SetPosition(edit_width - 225 - space_between/2-5, 0, 0)
    self.server_pw.textbox:SetRegionSize( edit_width - w - space_between-10, label_height )
    self.server_pw.textbox:SetHAlign(ANCHOR_LEFT)
    self.server_pw.textbox:SetFocusedImage( self.server_pw.textbox_bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex" )
    self.server_pw.textbox:SetTextLengthLimit( STRING_MAX_LENGTH )
    self.server_pw.textbox:SetCharacterFilter( VALID_PASSWORD_CHARS )
    
    if not Profile:GetShowPasswordEnabled() then
        self.server_pw.textbox:SetPassword(true)
    end
    self.server_pw.OnGainFocus = function(self)
        Widget.OnGainFocus(self)
        screen.server_pw.textbox:OnGainFocus()
    end
    self.server_pw.OnLoseFocus = function(self)
        Widget.OnLoseFocus(self)
        screen.server_pw.textbox:OnLoseFocus()
    end
    self.server_pw.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        if not screen.server_pw.textbox.editing and not screen.server_pw.textbox.focus then
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.HELP.CHANGE_TEXT)   
        end
        return table.concat(t, "  ")
    end

    self.server_desc = Widget("desc")
    self.server_desc.label = self.server_desc:AddChild(Text(BUTTONFONT, 35))
    self.server_desc.label:SetString(STRINGS.UI.SERVERCREATIONSCREEN.SERVERDESC)
    self.server_desc.label:SetHAlign(ANCHOR_LEFT)
    self.server_desc.label:SetPosition(-218,0)
    self.server_desc.label:SetColour(0,0,0,1)
    local w,h = self.server_desc.label:GetRegionSize()
    self.server_desc.textbox_bg = self.server_desc.label:AddChild( Image("images/textboxes.xml", "textbox_long.tex") )
    self.server_desc.textbox_bg:ScaleToSize(edit_width - w + space_between, label_height )
    self.server_desc.textbox_bg:SetPosition( edit_width - 240, 0, 0)
    self.server_desc.textbox = self.server_desc.label:AddChild(TextEdit( BODYTEXTFONT, font_size*textbox_font_ratio, TheNet:GetDefaultServerName() ) )
    self.server_desc.textbox:SetForceEdit(true)
    self.server_desc.textbox:SetPosition(edit_width - 225 - space_between/2-5, 0, 0)
    self.server_desc.textbox:SetRegionSize( edit_width - w - space_between-10, label_height )
    self.server_desc.textbox:SetHAlign(ANCHOR_LEFT)
    self.server_desc.textbox:SetFocusedImage( self.server_desc.textbox_bg, "images/textboxes.xml", "textbox_long_over.tex", "textbox_long.tex" )
    self.server_desc.textbox:SetTextLengthLimit( STRING_MAX_LENGTH )
    self.server_desc.textbox:SetCharacterFilter( VALID_CHARS )
    
    self.server_desc.OnGainFocus = function(self)
        Widget.OnGainFocus(self)
        screen.server_desc.textbox:OnGainFocus()
    end
    self.server_desc.OnLoseFocus = function(self)
        Widget.OnLoseFocus(self)
        screen.server_desc.textbox:OnLoseFocus()
    end
    self.server_desc.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        if not screen.server_desc.textbox.editing and not screen.server_desc.textbox.focus then
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT, false, false ) .. " " .. STRINGS.UI.HELP.CHANGE_TEXT)   
        end
        return table.concat(t, "  ")
    end

    self.server_name.textbox:SetOnTabGoToTextEditWidget(function()
        if self.server_pw.textbox:IsVisible() then
            return self.server_pw.textbox
        elseif self.server_desc.textbox:IsVisible() then
            return self.server_desc.textbox
        else
            return nil
        end        
    end)
    self.server_pw.textbox:SetOnTabGoToTextEditWidget(function()
        if self.server_desc.textbox:IsVisible() then
            return self.server_desc.textbox
        elseif self.server_name.textbox:IsVisible() then
            return self.server_name.textbox
        else
            return nil
        end  
    end)
    self.server_desc.textbox:SetOnTabGoToTextEditWidget(function()
        if self.server_name.textbox:IsVisible() then
            return self.server_name.textbox
        elseif self.server_pw.textbox:IsVisible() then
            return self.server_pw.textbox
        else
            return nil
        end  
    end)

    local label_x = 10
    local spinner_x = 95

    self.game_mode = Widget( "SpinnerGroup" )   
    self.game_mode.label = self.game_mode:AddChild( Text( BUTTONFONT, 35, STRINGS.UI.SERVERCREATIONSCREEN.GAMEMODE) )
    self.game_mode.label:SetPosition( -self.game_mode.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.game_mode.label:SetHAlign( ANCHOR_RIGHT )
    self.game_mode.label:SetColour(0,0,0,1)
    self.game_mode.spinner = self.game_mode:AddChild(Spinner( GetGameModesSpinnerData(), nil,nil,nil,nil,nil,nil, true))
    self.game_mode.spinner:SetPosition( spinner_x, 0, 0 )
    self.game_mode.spinner:SetTextColour(0,0,0,1)
    self.game_mode.focus_forward = self.game_mode.spinner
    self.game_mode.spinner:SetOnChangedFn(function()
        self.game_mode.spinner:SetHoverText(STRINGS.UI.SERVERCREATIONSCREEN[string.upper(self.game_mode.spinner:GetSelectedData()).."_TOOLTIP"])
    end)
    self.game_mode.spinner:SetHoverText(STRINGS.UI.SERVERCREATIONSCREEN[string.upper(self.game_mode.spinner:GetSelectedData()).."_TOOLTIP"])

    self.max_players = Widget( "SpinnerGroup" )
    self.max_players.label = self.max_players:AddChild( Text( BUTTONFONT, 35, STRINGS.UI.SERVERCREATIONSCREEN.MAXPLAYERS) )
    self.max_players.label:SetPosition( -self.max_players.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.max_players.label:SetHAlign( ANCHOR_RIGHT )
    self.max_players.label:SetColour(0,0,0,1)
    local numplayer_options = {}
    for i=2, TUNING.MAX_SERVER_SIZE do
        table.insert(numplayer_options,{text=i, data=i})
    end
    self.max_players.spinner = self.max_players:AddChild(Spinner(numplayer_options, nil,nil,nil,nil,nil,nil, true))
    self.max_players.spinner:SetPosition( spinner_x, 0, 0 )
    self.max_players.spinner:SetTextColour(0,0,0,1)
    self.max_players.focus_forward = self.max_players.spinner
    self.max_players.spinner:SetSelected(TheNet:GetDefaultMaxPlayers())

    self.pvp = Widget( "SpinnerGroup" )
    self.pvp.label = self.pvp:AddChild( Text( BUTTONFONT, 35, STRINGS.UI.SERVERCREATIONSCREEN.PVP) )
    self.pvp.label:SetPosition( -self.pvp.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.pvp.label:SetHAlign( ANCHOR_RIGHT )
    self.pvp.label:SetColour(0,0,0,1)
    self.pvp.spinner = self.pvp:AddChild(Spinner({{ text = STRINGS.UI.SERVERLISTINGSCREEN.ON, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.OFF, data = false }}, nil,nil,nil,nil,nil,nil, true))
    self.pvp.spinner:SetPosition( spinner_x, 0, 0 )
    self.pvp.spinner:SetTextColour(0,0,0,1)
    self.pvp.focus_forward = self.pvp.spinner

    self.friends_only = Widget( "SpinnerGroup" )
    self.friends_only.label = self.friends_only:AddChild( Text( BUTTONFONT, 35, STRINGS.UI.SERVERCREATIONSCREEN.FRIENDSONLY) )
    self.friends_only.label:SetPosition( -self.friends_only.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.friends_only.label:SetHAlign( ANCHOR_RIGHT )
    self.friends_only.label:SetColour(0,0,0,1)
    self.friends_only.spinner = self.friends_only:AddChild(Spinner({{ text = STRINGS.UI.SERVERLISTINGSCREEN.OFF, data = false }, { text = STRINGS.UI.SERVERLISTINGSCREEN.ON, data = true  }}, nil,nil,nil,nil,nil,nil, true))
    self.friends_only.spinner:SetPosition( spinner_x, 0, 0 )
    self.friends_only.spinner:SetTextColour(0,0,0,1)
    self.friends_only.focus_forward = self.friends_only.spinner
    
    self.online_mode = Widget( "SpinnerGroup" )
    self.online_mode.label = self.online_mode:AddChild( Text( BUTTONFONT, 35, STRINGS.UI.SERVERCREATIONSCREEN.SERVERTYPE) )
    self.online_mode.label:SetPosition( -self.online_mode.label:GetRegionSize()/2 + label_x, 0, 0 )
    self.online_mode.label:SetHAlign( ANCHOR_RIGHT )
    self.online_mode.label:SetColour(0,0,0,1)
    self.online_mode.spinner = self.online_mode:AddChild(Spinner({{ text = STRINGS.UI.SERVERLISTINGSCREEN.ONLINE, data = true }, { text = STRINGS.UI.SERVERLISTINGSCREEN.LAN, data = false  }}, nil,nil,nil,nil,nil,nil, true))
    self.online_mode.spinner:SetPosition( spinner_x, 0, 0 )
    self.online_mode.spinner:SetTextColour(0,0,0,1)
    self.online_mode.focus_forward = self.online_mode.spinner
    self.online_mode.spinner:SetOnChangedFn(function()
        if self.online_mode.spinner:GetSelectedData() == false then
            self.friendssetting = self.friends_only.spinner:GetSelectedData()
            self.friends_only.spinner:SetSelected(false)
            self.friends_only.spinner:Disable()
        else
            self.friends_only.spinner:SetSelected(self.friendssetting)
            self.friends_only.spinner:Enable()
        end
    end)
    
    if not TheNet:IsOnlineMode() or TheFrontEnd:GetIsOfflineMode() then
		self.online_mode.spinner:Disable()
        self.online_mode.spinner:SetSelected(false)
        self.friends_only.spinner:Disable()
        self.friends_only.spinner:SetSelected(false)
    end

    self.page_widgets = 
    {
        self.server_name,
        self.server_pw,
        self.server_desc,
        self.game_mode,
        self.pvp,
        self.max_players,
        self.friends_only,
        self.online_mode,
    }
    self.scroll_list = self.detail_panel:AddChild(ScrollableList(self.page_widgets, 270, 360, 45, 10))
    -- It's gross & inconsistent but don't show the shoulder button scroll prompts on the screen:
    -- the scrollable list is small, and we're low on space for button prompts
    self.scroll_list.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}
        return table.concat(t, "  ")
    end
    self.scroll_list:SetPosition(120,0)
end

function ServerCreationScreen:MakeButtons()
    if not TheInput:ControllerAttached() then
        self.cancel_button = MakeImgButton(self.load_panel, -95, -250, STRINGS.UI.SERVERCREATIONSCREEN.BACK, function() self:Cancel() end)
        
        self.create_button = MakeImgButton(self.load_panel, 85, -253, STRINGS.UI.SERVERCREATIONSCREEN.CREATE, function() self:Create() end, true)
        self.create_button.text:SetPosition(1,0)

        self.blacklist_button = MakeImgButton(self.load_panel, 100, 300, STRINGS.UI.SERVERCREATIONSCREEN.ADMIN, function() self:ShowServerAdmin() end)

        self.delete_button = MakeImgButton(self.detail_panel, 115, -250, STRINGS.UI.SERVERCREATIONSCREEN.DELETE_SLOT, function() self:DeleteSlot(self.saveslot) end)

        self.configure_world_button = MakeImgButton(self.detail_panel, -90, -250, STRINGS.UI.SERVERCREATIONSCREEN.WORLD, function() self:OnConfigureButton() end)

        self.manage_account = MakeImgButton(self.load_panel, -100, 300, STRINGS.UI.SERVERCREATIONSCREEN.MANAGE_ACCOUNT, 
                       function() VisitURL(TheFrontEnd:GetAccountManager():GetViewAccountURL(), true ) end)
    else
        self.manage_account = MakeImgButton(self.load_panel, 0, 300, STRINGS.UI.SERVERCREATIONSCREEN.MANAGE_ACCOUNT, 
                       function() VisitURL(TheFrontEnd:GetAccountManager():GetViewAccountURL(), true ) end)
    end

    -- If we don't have a steam token, disable
    if not TheFrontEnd:GetAccountManager():HasSteamTicket() then
        self.manage_account:Disable()
    end
    
    self:UpdatePanels(self.saveslot)
end

function ServerCreationScreen:DoFocusHookUps()
    if not TheInput:ControllerAttached() then

    else
        self.manage_account:SetFocusChangeDir(MOVE_DOWN, self.load_slots_menu)
        self.load_slots_menu:SetFocusChangeDir(MOVE_UP, self.manage_account)
        self.load_slots_menu:SetFocusChangeDir(MOVE_RIGHT, self.scroll_list)
        self.manage_account:SetFocusChangeDir(MOVE_RIGHT, self.scroll_list)
        self.scroll_list:SetFocusChangeDir(MOVE_LEFT, self.load_slots_menu)
    end
end

function ServerCreationScreen:ShowServerAdmin()
    local function cb(restored_snapshot)
        if restored_snapshot then
            self:RefreshLoadTiles()    
            self:OnClickTile(self.saveslot, true)
        end
    end

	self:Disable()
	TheFrontEnd:Fade(false, screen_fade_time, function()
		TheFrontEnd:PushScreen(ServerAdminScreen(self.saveslot, false, cb))
		TheFrontEnd:Fade(true, screen_fade_time)
	end)
end


return ServerCreationScreen
