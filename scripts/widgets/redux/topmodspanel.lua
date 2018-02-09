local Grid = require "widgets/grid"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local TEMPLATES = require "widgets/redux/templates"

local HAS_FEATUREDMODS = PLATFORM ~= "WIN32_RAIL"

local function BuildModLink(region_size, button_height)
    -- Use noop function to make ListItemBackground build something that's
    -- clickable.
    local modlink = TEMPLATES.ListItemBackground(region_size, button_height, function() end)
    modlink.move_on_click = true
    modlink:SetText(STRINGS.UI.MODSSCREEN.LOADING.."...")
    modlink.text:SetRegionSize(region_size, 70)
    modlink:SetTextSize(28)
    modlink:SetFont(CHATFONT)
    modlink:SetTextColour(UICOLOURS.GOLD_CLICKABLE)
    modlink:SetTextFocusColour(UICOLOURS.GOLD_FOCUS)
    return modlink
end

local function BuildSectionTitle(text, region_size)
    local title_root = Widget("title_root")
    local title = title_root:AddChild(Text(HEADERFONT, 26))
    title:SetRegionSize(region_size, 70)
    title:SetString(text)
    title:SetColour(UICOLOURS.GOLD_SELECTED)

    local titleunderline = title_root:AddChild( Image("images/frontend_redux.xml", "achievements_divider_top.tex") )
    titleunderline:SetScale(0.4, 0.5)
    titleunderline:SetPosition(0, -20)

    return title_root
end

local TopModsPanel = Class(Widget, function(self)
    Widget._ctor(self, "TopModsPanel")

    -- These two panels are positioned carefully so they fit in
    -- ServerCreationScreen when shifted to the right.

    self.root = self:AddChild(Widget("root"))
    self.root:SetPosition(0,-60)

    self.topmods_panel = self.root:AddChild(Widget("topmods"))
    self.topmods_panel:SetPosition(-170,0)

    self.featuredmods_panel = self.root:AddChild(Widget("featuredmods"))
    self.featuredmods_panel:SetPosition(170,0)

	if PLATFORM ~= "WIN32_RAIL" then
		self.morebutton = self.root:AddChild(TEMPLATES.StandardButton(
				function() ModManager:ShowMoreMods() end,
				STRINGS.UI.MODSSCREEN.MOREMODS
			))
		self.morebutton:SetPosition(0,-170)
		self.morebutton:SetScale(.56)
	end

    local region_size = 330
    local button_height = 45

    self.toptitle = self.topmods_panel:AddChild(BuildSectionTitle(STRINGS.UI.MODSSCREEN.TOPMODS, region_size))
    self.toptitle:SetPosition(0,220)

    self.modlinks = {}

    self.modlink_grid = self.topmods_panel:AddChild(Grid())
    self.modlink_grid:SetPosition(0, 150)
    for i = 1, 5 do
        table.insert(self.modlinks, BuildModLink(region_size, button_height))
    end
    self.modlink_grid:FillGrid(1, 100, button_height, self.modlinks)

    self.featuredtitle = self.featuredmods_panel:AddChild(BuildSectionTitle(STRINGS.UI.MODSSCREEN.FEATUREDMOD, region_size))
    self.featuredtitle:SetPosition(0,220)

    self.featuredbutton = self.featuredmods_panel:AddChild(BuildModLink(region_size, button_height))
    self.featuredbutton:SetPosition(0,150)

	if PLATFORM == "WIN32_RAIL" then
		TheSim:RAILQueryTopMods( function(result, isSuccessful, resultCode) self:OnStatsQueried(result, isSuccessful, resultCode) end)
	else
		local linkpref = (PLATFORM == "WIN32_STEAM" and "external") or "klei"
		TheSim:QueryStats( '{ "req":"modrank", "field":"Session.Loads.Mods.list", "fieldop":"unwind", "linkpref":"'..linkpref..'", "limit": 20}',
			function(result, isSuccessful, resultCode) self:OnStatsQueried(result, isSuccessful, resultCode) end)
	end

    self:DoFocusHookups()
    self.topmods_panel.focus_forward = self.modlink_grid
    self.featuredmods_panel.focus_forward = self.featuredbutton
    self.focus_forward = self.modlink_grid

    if not HAS_FEATUREDMODS then
        self:_HideFeaturedMods()
    end
end)

function TopModsPanel:_HideFeaturedMods()
    self.featuredmods_panel:Hide()
    self.topmods_panel:SetPosition(0,0)
end

function TopModsPanel:GenerateRandomPicks(num, numrange)
    local picks = {}

    while #picks < num do
        local index = math.random(1, numrange)
        if not table.contains(picks, index) then
            table.insert(picks, index)
        end
    end
    return picks
end

function TopModsPanel:OnStatsQueried( result, isSuccessful, resultCode )
    if not (self.inst:IsValid()) then
        return
    end

    if not result or not isSuccessful or string.len(result) <= 1 then return end

    local status, jsonresult = pcall( function() return json.decode(result) end )

    if not jsonresult or type(jsonresult) ~= "table" or  not status or jsonresult["modnames"] == nil then return end

    local randomPicks = self:GenerateRandomPicks(#self.modlinks, #jsonresult["modnames"])
    for i = 1, #self.modlinks do
        local title = jsonresult["modnames"][randomPicks[i]]
        if title then
            local url = jsonresult["modlinks"][title]
            title = string.gsub(title, "(ws%-)", "")
            local maxchars = 25
            if string.len(title) > maxchars then
                title = string.sub(title, 0, maxchars).."..."
            end
            self.modlinks[i]:SetText(title)
            if url then
				self.modlinks[i]:SetOnClick(function() VisitURL(url) end)
            end
        end
    end

    local modfeature = jsonresult["modfeature"]
    if PLATFORM ~= "WIN32_RAIL" and modfeature then
        local title, url = next(modfeature)
        if title and url then
            title = string.gsub(title, "(ws%-)", "")
            self.featuredbutton:SetText(title)
            self.featuredbutton:SetOnClick(function() VisitURL(url) end)
        end
    else
        -- Failed to download featured mods, so hide them from view.
        self:_HideFeaturedMods()
    end
end

function TopModsPanel:DoFocusHookups()
    self.topmods_panel:SetFocusChangeDir(MOVE_RIGHT, self.featuredmods_panel)
    self.featuredmods_panel:SetFocusChangeDir(MOVE_LEFT, self.topmods_panel)

	if self.morebutton ~= nil then
		self.morebutton:SetFocusChangeDir(MOVE_UP, self.modlinks[#self.modlinks])
		self.featuredbutton:SetFocusChangeDir(MOVE_DOWN, self.morebutton)
		self.topmods_panel:SetFocusChangeDir(MOVE_DOWN, self.morebutton)
	end
end

return TopModsPanel
