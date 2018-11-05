local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Grid = require "widgets/grid"
local Spinner = require "widgets/spinner"

local TEMPLATES = require "widgets/redux/templates"

local ProgressionWidget = require "widgets/redux/lavaarena_communityprogression_panel"
local CommunityHistoryPanel = require "widgets/redux/lavaarena_communityhistory_panel"
local QuestHistoryPanel = require "widgets/redux/lavaarena_questhistory_panel"

require("util")

-------------------------------------------------------------------------------------------------------
local LavaarenaBook = Class(Widget, function(self, parent, secondary_left_menu, season)
    Widget._ctor(self, "LavaarenaBook")

    self.root = self:AddChild(Widget("root"))

	local tab_root = self.root:AddChild(Widget("tab_root"))

	local backdrop = self.root:AddChild(Image("images/lavaarena_unlocks.xml", "unlock_bg.tex"))
    backdrop:ScaleToSize(900, 550)
	backdrop:SetClickable(false)

	local base_size = .65

	local button_data = {
		{text = STRINGS.UI.LAVAARENA_SUMMARY_PANEL.TAB_TITLE, build_panel_fn = function() return ProgressionWidget(parent, FESTIVAL_EVENTS.LAVAARENA, season) end },
		{text = STRINGS.UI.LAVAARENA_COMMUNITY_UNLOCKS.TAB_TITLE, build_panel_fn = function() return CommunityHistoryPanel(parent) end},
		{text = STRINGS.UI.LAVAARENA_QUESTS_HISTORY_PANEL.TAB_TITLE, build_panel_fn = function() return QuestHistoryPanel(FESTIVAL_EVENTS.LAVAARENA, season) end},
	}

	local function MakeTab(data, index)
		local tab = ImageButton("images/lavaarena_unlocks.xml", "tab_inactive.tex", nil, nil, nil, "tab_active.tex")
		--tab:SetPosition(-260 + 240*(i-1), 285)
		tab:SetFocusScale(base_size, base_size)
		tab:SetNormalScale(base_size, base_size)
		tab:SetText(data.text)
		tab:SetTextSize(22)
		tab:SetFont(HEADERFONT)
		tab:SetTextColour(UICOLOURS.GOLD)
		tab:SetTextFocusColour(UICOLOURS.GOLD)
		tab:SetTextSelectedColour(UICOLOURS.GOLD)
		tab.text:SetPosition(0, 10)
		tab.clickoffset = Vector3(0,-5,0)
		tab:SetOnClick(function()
	        self.last_selected:Unselect()
	        self.last_selected = tab
			tab:Select()
			tab:MoveToFront()
			if self.panel ~= nil then 
				self.panel:Kill()
			end
			self.panel = self.root:AddChild(data.build_panel_fn())
			if parent ~= nil then
				self:_DoFocusHookups(parent, secondary_left_menu)
			end

			-- restore this if you want focus to be on the pannel
			--self.panel.parent_default_focus:SetFocus()
		end)
		tab._tabindex = index - 1

		return tab
	end
	
	self.tabs = {}
--[[
	table.insert(self.tabs, tab_root:AddChild(MakeTab(button_data[1], 1)))
	self.tabs[#self.tabs]:SetPosition(-280, 250)
	table.insert(self.tabs, tab_root:AddChild(MakeTab(button_data[2], 2)))
	self.tabs[#self.tabs]:SetPosition(0, 250)
	table.insert(self.tabs, tab_root:AddChild(MakeTab(button_data[3], 3)))
	self.tabs[#self.tabs]:SetPosition(280, 250)
]]
	
	table.insert(self.tabs, tab_root:AddChild(MakeTab(button_data[1], 1)))
	self.tabs[#self.tabs]:SetPosition(-150, 250)
	table.insert(self.tabs, tab_root:AddChild(MakeTab(button_data[2], 2)))
	self.tabs[#self.tabs]:SetPosition(150, 250)

	-----
	self.last_selected = self.tabs[1]
	self.last_selected:Select()	
	self.last_selected:MoveToFront()
	self.panel = self.root:AddChild(ProgressionWidget(parent, FESTIVAL_EVENTS.LAVAARENA, season))
    if parent ~= nil then
		self:_DoFocusHookups(parent, secondary_left_menu)
    end
end)

function LavaarenaBook:_DoFocusHookups(menu, secondary_left_menu)

	self.panel.parent_default_focus:SetFocusChangeDir(MOVE_LEFT, menu)
	self.focus_forward = self.panel.parent_default_focus

end

function LavaarenaBook:_DoFocusHookupsOLD(menu, secondary_left_menu)
	menu:ClearFocusDirs()
	menu:SetFocusChangeDir(MOVE_RIGHT, self.panel.parent_default_focus)
	self.panel.parent_default_focus:SetFocusChangeDir(MOVE_LEFT, menu)

	print("LavaarenaBook:_DoFocusHookups", self.panel.parent_default_focus)

	if secondary_left_menu ~= nil then
		secondary_left_menu:ClearFocusDirs()

		menu:SetFocusChangeDir(MOVE_UP, secondary_left_menu)
		secondary_left_menu:SetFocusChangeDir(MOVE_DOWN, menu)
		secondary_left_menu:SetFocusChangeDir(MOVE_RIGHT, self.panel.parent_default_focus)
	end

	for i, v in ipairs(self.tabs) do
		v:ClearFocusDirs()
		v:SetFocusChangeDir(MOVE_LEFT, self.panel.parent_default_focus)
		v:SetFocusChangeDir(MOVE_RIGHT, self.panel.parent_default_focus)
		v:SetFocusChangeDir(MOVE_UP, self.panel.parent_default_focus)
		v:SetFocusChangeDir(MOVE_DOWN, self.panel.parent_default_focus)
	end

	if self.panel.spinners ~= nil then
		for i, v in ipairs(self.panel.spinners) do
			v:SetFocusChangeDir(MOVE_LEFT, menu)
		end
	end
end

function LavaarenaBook:OnControlTabs(control, down)
	if control == CONTROL_OPEN_CRAFTING then
		local tab = self.tabs[((self.last_selected._tabindex - 1) % #self.tabs) + 1]
		if not down then
			tab.onclick()
			return true
		end
	elseif control == CONTROL_OPEN_INVENTORY then
		local tab = self.tabs[((self.last_selected._tabindex + 1) % #self.tabs) + 1]
		if not down then
			tab.onclick()
			return true
		end
	end

end

function LavaarenaBook:OnUpdate(dt)
	if self.panel ~= nil and self.panel.OnUpdate ~= nil then
		self.panel:OnUpdate(dt)
	end
end

function LavaarenaBook:OnControl(control, down)
    if LavaarenaBook._base.OnControl(self, control, down) then return true end

	return self:OnControlTabs(control, down)
end

function LavaarenaBook:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_CRAFTING).."/"..TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_INVENTORY).. " " .. STRINGS.UI.HELP.CHANGE_TAB)

    return table.concat(t, "  ")
end


return LavaarenaBook
