local PopupDialogScreen = require "screens/popupdialog"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

local ScrollableList = require "widgets/scrollablelist"

local SnapshotTab = Class(Widget, function(self, cb)
    Widget._ctor(self, "SnapshotTab")
  
    self.snapshot_page = self:AddChild(Widget("snapshot_page"))

    self.left_line = self.snapshot_page:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
    self.left_line:SetScale(1, .6)
    self.left_line:SetPosition(-530, 5, 0)

    self.save_slot = -1
    self.cb = cb
    
    self.snapshots = nil
    self.slotsnaps = {}
    self:ListSnapshots()

    self:MakeSnapshotsMenu()

    self.default_focus = self.snapshot_scroll_list
    self.focus_forward = self.snapshot_scroll_list
end)

function SnapshotTab:RefreshSnapshots()
    if self.snapshots == nil then
        return
    end
    local widgets_per_view = self.snapshot_scroll_list.widgets_per_view
    local has_scrollbar = #self.snapshots > widgets_per_view
    if not has_scrollbar and #self.snapshots < widgets_per_view then
        for i = widgets_per_view - #self.snapshots, 1, -1 do
            table.insert(self.snapshots, { empty = true })
        end
    end
    self.snapshot_scroll_list:SetList(self.snapshots)
    self.snapshot_scroll_list:SetPosition(has_scrollbar and -77 or -57, 0, 0)
end

function SnapshotTab:MakeSnapshotsMenu()
    local use_legacy_client_hosting = TheSim:IsLegacyClientHosting()

    local function MakeSnapshotTile(data, index, parent)
        local widget = parent:AddChild(Widget("option"))
        widget:SetScale(.8)
        widget.clickoffset = Vector3(0,-3,0)

        widget.white_bg = widget:AddChild(Image("images/ui.xml", "single_option_bg_large.tex"))
        widget.white_bg:SetScale(.63, .9)

        widget.state_bg = widget:AddChild(Image("images/ui.xml", "single_option_bg_large_gold.tex"))
        widget.state_bg:SetScale(.63, .9)
        widget.state_bg:Hide()

        widget.portraitroot = widget:AddChild(Widget("portrait"))
        widget.portraitroot.bg = widget.portraitroot:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
        widget.portraitroot.bg:SetClickable(false)
        widget.portraitroot.image = widget.portraitroot:AddChild(Image())
        widget.portraitroot.image:SetClickable(false)
        widget.portraitroot:SetScale(.65, .65, 1)
        widget.portraitroot:SetPosition(-100, 0, 0)

        widget.day = widget:AddChild(Text(NEWFONT, 35))
        widget.day:SetColour(0, 0, 0, 1)
        widget.day:SetString(STRINGS.UI.SERVERADMINSCREEN.EMPTY_SLOT)
        widget.day:SetPosition(0, 0, 0)
        widget.day:SetHAlign(ANCHOR_MIDDLE)
        widget.day:SetVAlign(ANCHOR_MIDDLE)

        widget.season = widget:AddChild(Text(NEWFONT, 28))
        widget.season:SetColour(0, 0, 0, 1)
        widget.season:SetString("")
        widget.season:SetPosition(0, 18, 0)
        widget.season:SetHAlign(ANCHOR_MIDDLE)
        widget.season:SetVAlign(ANCHOR_MIDDLE)

        widget.OnGainFocus = function(self)
            if not widget:IsEnabled() then return end
            Widget.OnGainFocus(self)
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            widget.state_bg:Show()
        end

        local screen = self
        widget.OnLoseFocus = function(self)
            if not widget:IsEnabled() then return end
            Widget.OnLoseFocus(self)
            widget.state_bg:Hide()
        end

        widget.clickoffset = Vector3(0,-3,0)
        widget.OnControl = function(self, control, down)
            if not widget:IsEnabled() then return false end
            if widget.empty then return false end

            if control == CONTROL_ACCEPT then
                if down then 
                    widget.o_pos = widget:GetLocalPosition()
                    widget:SetPosition(widget.o_pos + widget.clickoffset)
                else
                    if widget.o_pos then 
                        widget:SetPosition(widget.o_pos) 
                        widget.o_pos = nil
                    end
                    screen:OnClickSnapshot(index)
                end
                return true
            end
        end

        widget.GetHelpText = function(self)
            local controller_id = TheInput:GetControllerID()
            local t = {}
            if not widget.empty then
                table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT).." "..STRINGS.UI.SERVERADMINSCREEN.RESTORE_SNAPSHOT)
            end
            return table.concat(t, "  ")
        end

        if data ~= nil and not data.empty then
            local character, atlas
            if TheSim:IsLegacyClientHosting() then
                character = data.character or ""
                atlas = "images/saveslot_portraits"
                if not table.contains(DST_CHARACTERLIST, character) then
                    if table.contains(MODCHARACTERLIST, character) then
                        atlas = atlas.."/"..character
                    else
                        character = #character > 0 and "mod" or "unknown"
                    end
                end
                atlas = atlas..".xml"
            end

            if character ~= nil then
                widget.portraitroot.image:SetTexture(atlas, character..".tex")
            else
                widget.portraitroot:Hide()
            end

            local day_text = STRINGS.UI.SERVERADMINSCREEN.DAY.." "..tostring(data.world_day or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_DAY)
            widget.day:SetString(day_text)
            if not use_legacy_client_hosting and data.world_season ~= nil then
                widget.season:SetString(data.world_season)
                widget.day:SetPosition(0, -15, 0)
            else
                widget.season:Hide()
                widget.day:SetPosition(character ~= nil and 40 or 0, 0, 0)
            end
            widget.empty = false
        else
            widget.portraitroot:Hide()
            widget.season:Hide()

            widget.empty = true
        end

        return widget
    end

    local function UpdateSnapshot(widget, data, index)
        if data ~= nil and not data.empty then
            local character, atlas
            if TheSim:IsLegacyClientHosting() then
                character = data.character or ""
                atlas = "images/saveslot_portraits"
                if not table.contains(DST_CHARACTERLIST, character) then
                    if table.contains(MODCHARACTERLIST, character) then
                        atlas = atlas.."/"..character
                    else
                        character = #character > 0 and "mod" or "unknown"
                    end
                end
                atlas = atlas..".xml"
            end

            if character ~= nil then
                widget.portraitroot.image:SetTexture(atlas, character..".tex")
                widget.portraitroot:Show()
            else
                widget.portraitroot:Hide()
            end
            
            local day_text = STRINGS.UI.SERVERADMINSCREEN.DAY.." "..tostring(data.world_day or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_DAY)
            widget.day:SetString(day_text)
            if not use_legacy_client_hosting and data.world_season ~= nil then
                widget.season:SetString(data.world_season)
                widget.season:Show()
                widget.day:SetPosition(0, -15, 0)
            else
                widget.season:Hide()
                widget.day:SetPosition(character ~= nil and 40 or 0, 0, 0)
            end
            widget.empty = false
        else
            widget.day:SetString(STRINGS.UI.SERVERADMINSCREEN.EMPTY_SLOT)
            widget.day:SetPosition(0, 0, 0)
            widget.season:SetString("")
            widget.season:Hide()
            widget.portraitroot:Hide()
            widget.empty = true
        end
    end

    self.snapshot_page_scroll_root = self.snapshot_page:AddChild(Widget("scroll_root"))
    self.snapshot_page_scroll_root:SetPosition(-40,0)

    self.snapshot_page_row_root = self.snapshot_page:AddChild(Widget("row_root"))
    self.snapshot_page_row_root:SetPosition(-40,0)

    self.snapshot_widgets = {}
    for i=1,5 do
        table.insert(self.snapshot_widgets, MakeSnapshotTile(self.snapshots[i], i, self.snapshot_page_row_root))
    end

    self.snapshot_scroll_list = self.snapshot_page_scroll_root:AddChild(ScrollableList(self.snapshots, 183, 450, 70, 3, UpdateSnapshot, self.snapshot_widgets, nil, nil, nil, -15))
    self.snapshot_scroll_list:SetPosition(-152, 0)
    self.snapshot_scroll_list:LayOutStaticWidgets(-55)
    self:RefreshSnapshots()
end

function SnapshotTab:OnClickSnapshot(snapshot_num)

    if not self.snapshots[snapshot_num] then return end
    
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")   
    
    local day_text = STRINGS.UI.SERVERADMINSCREEN.DAY.." "..tostring(self.snapshots[snapshot_num].world_day or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_DAY)
    local header = string.format(STRINGS.UI.SERVERADMINSCREEN.RESTORE_SNAPSHOT_HEADER, day_text)
    local popup = PopupDialogScreen(header, STRINGS.UI.SERVERADMINSCREEN.RESTORE_SNAPSHOT_BODY, 
        {{text=STRINGS.UI.SERVERADMINSCREEN.YES, cb = function()    
            local function onSaved()
                self:ListSnapshots(true)
                self:RefreshSnapshots()
                if self.cb then
                    self.cb()
                end
                TheFrontEnd:PopScreen()
            end
            local truncate_to_id = self.snapshots[snapshot_num].snapshot_id
            if truncate_to_id ~= nil and truncate_to_id > 0 then
                if TheSim:IsLegacyClientHosting() then
                    TheNet:TruncateSnapshots(self.session_id, truncate_to_id)
                else
                    TheNet:TruncateSnapshotsInClusterSlot(self.save_slot, "Master", self.session_id, truncate_to_id)
                    --slaves will auto-truncate to synchornize at startup
                end
            end
            SaveGameIndex:SetSlotDay(self.save_slot, self.snapshots[snapshot_num].world_day or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_DAY)
            SaveGameIndex:Save(onSaved)
        end},
        {text=STRINGS.UI.SERVERADMINSCREEN.NO, cb = function() TheFrontEnd:PopScreen() end}  })
    TheFrontEnd:PushScreen(popup)   
    
end

function SnapshotTab:ListSnapshots(force)
    if not force and self.slotsnaps[self.save_slot] then
        self.snapshots = deepcopy(self.slotsnaps[self.save_slot])
        return
    end

    self.snapshots = {}
    if self.save_slot ~= nil and self.session_id ~= nil then
        --V2C: TODO: update ListSnapshots to support cluster folders
        local snapshot_infos, has_more = TheNet:ListSnapshots(self.save_slot, self.session_id, self.online_mode, 10)
        for i, v in ipairs(snapshot_infos) do
            if v.snapshot_id ~= nil then
                local info = { snapshot_id = v.snapshot_id }
                if v.world_file ~= nil then
                    local function onreadworldfile(success, str)
                        if success and str ~= nil and #str > 0 then
                            local success, savedata = RunInSandbox(str)
                            if success and savedata ~= nil and GetTableSize(savedata) > 0 then
                                local worlddata = savedata.world_network ~= nil and savedata.world_network.persistdata or nil
                                if worlddata ~= nil then
                                    if worlddata.clock ~= nil then
                                        info.world_day = (worlddata.clock.cycles or 0) + 1
                                    end

                                    if worlddata.seasons ~= nil and worlddata.seasons.season ~= nil then
                                        info.world_season = STRINGS.UI.SERVERLISTINGSCREEN.SEASONS[string.upper(worlddata.seasons.season)]
                                        if info.world_season ~= nil and
                                            worlddata.seasons.elapseddaysinseason ~= nil and
                                            worlddata.seasons.remainingdaysinseason ~= nil then
                                            if worlddata.seasons.remainingdaysinseason * 3 <= worlddata.seasons.elapseddaysinseason then
                                                info.world_season = STRINGS.UI.SERVERLISTINGSCREEN.LATE_SEASON_1..info.world_season..STRINGS.UI.SERVERLISTINGSCREEN.LATE_SEASON_2
                                            elseif worlddata.seasons.elapseddaysinseason * 3 <= worlddata.seasons.remainingdaysinseason then
                                                info.world_season = STRINGS.UI.SERVERLISTINGSCREEN.EARLY_SEASON_1..info.world_season..STRINGS.UI.SERVERLISTINGSCREEN.EARLY_SEASON_2
                                            end
                                        end
                                    end
                                else
                                    info.world_day = 1
                                end
                            end
                        end
                    end
                    if TheSim:IsLegacyClientHosting() then
                        TheSim:GetPersistentString(v.world_file, onreadworldfile)
                    else
                        TheSim:GetPersistentStringInClusterSlot(self.save_slot, "Master", v.world_file, onreadworldfile)
                    end
                end
                if v.user_file ~= nil and TheSim:IsLegacyClientHosting() then
                    TheSim:GetPersistentString(v.user_file,
                        function(success, str)
                            if success and str ~= nil and #str > 0 then
                                local success, savedata = RunInSandbox(str)
                                if success and savedata ~= nil and GetTableSize(savedata) > 0 then
                                    info.character = savedata.prefab
                                end
                            end
                        end)
                end
                table.insert(self.snapshots, info)
            end
        end
    end

    -- Remove the first element in the table, since that's our current save
    table.remove(self.snapshots, 1)
end

function SnapshotTab:SetSaveSlot(save_slot, prev_slot, fromDelete)
    if not fromDelete and (save_slot == self.save_slot or save_slot == prev_slot or not save_slot or not prev_slot) then return end

    self.save_slot = save_slot

    if not SaveGameIndex:IsSlotEmpty(save_slot) and prev_slot and prev_slot > 0 then
        -- remember snapshots
        self.slotsnaps[prev_slot] = deepcopy(self.snapshots)
    end

    self.session_id = SaveGameIndex:GetClusterSlotSession(save_slot)
    self.online_mode = SaveGameIndex:GetSlotServerData(save_slot).online_mode ~= false

    self:ListSnapshots()
    self:RefreshSnapshots()
end

return SnapshotTab
