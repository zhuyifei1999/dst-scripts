local Screen = require "widgets/screen"
local AnimButton = require "widgets/animbutton"
local Spinner = require "widgets/spinner"
local ImageButton = require "widgets/imagebutton"
local TextButton = require "widgets/textbutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local NumericSpinner = require "widgets/numericspinner"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local Menu = require "widgets/menu"
local PopupDialogScreen = require "screens/popupdialog"
local BigPopupDialogScreen = require "screens/bigpopupdialog"
local ModConfigurationScreen = require "screens/modconfigurationscreen"

local ScrollableList = require "widgets/scrollablelist"
local OnlineStatus = require "widgets/onlinestatus"

local text_font = DEFAULTFONT--NUMBERFONT

local display_rows = 5

local DISABLE = 0
local ENABLE = 1
    
local mid_col = RESOLUTION_X*.07
local left_col = -RESOLUTION_X*.3
local right_col = RESOLUTION_X*.37

local screen_fade_time = .25

local ModsScreen = Class(Screen, function(self)
    Widget._ctor(self, "ModsScreen")

	-- save current mod index before user configuration
	KnownModIndex:CacheSaveData()
	-- get the latest mod info
	KnownModIndex:UpdateModInfo()

	self.modnames = KnownModIndex:GetModNames()
	local function alphasort(moda, modb)
		if not moda then return false end
		if not modb then return true end
		return string.lower(KnownModIndex:GetModFancyName(moda)) < string.lower(KnownModIndex:GetModFancyName(modb))
	end
	table.sort(self.modnames, alphasort)

	self.infoprefabs = {}

    self.bg = self:AddChild(Image("images/bg_plain.xml", "bg.tex"))
    TintBackground(self.bg)

    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
    
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	self.option_offset = 0
    self.optionspanel = self.root:AddChild(Menu(nil, -98, false))
    self.optionspanel:SetPosition(left_col,0,0)
    self.optionspanelbg = self.optionspanel:AddChild(Image("images/fepanels_dst.xml", "tall_panel.tex"))

    -- mod details panel
	self:CreateDetailPanel()
    
	self.mainmenu = self.root:AddChild(Menu(nil, 0, true))
    self.mainmenu:SetPosition(mid_col, 0, 0)
	self.applybutton = self.mainmenu:AddItem(STRINGS.UI.MODSSCREEN.APPLY, function() self:Apply() end, Vector3(110,-287,0), "large")
	self.cancelbutton = self.mainmenu:AddItem(STRINGS.UI.MODSSCREEN.BACK, function() self:Cancel() end, Vector3(-90,-285,0))
	self.modconfigbutton = self.mainmenu:AddItem(STRINGS.UI.MODSSCREEN.CONFIGUREMOD, function() self:ConfigureSelectedMod() end, Vector3(10, -135, 0))
	self.modconfigbutton:SetScale(.85)
	self.modconfigable = false
	self.mainmenu:MoveToFront()

	self.cleanallbutton = self.optionspanel:AddChild(ImageButton())
    self.cleanallbutton:SetText(STRINGS.UI.MODSSCREEN.CLEANALL)
    self.cleanallbutton:SetPosition(Vector3(0,305,0))
    self.cleanallbutton:SetScale(.85)
    self.cleanallbutton:SetOnClick(function() self:CleanAllButton() end)
    
	self.onlinestatus = self.root:AddChild(OnlineStatus())
    self.onlinestatus:SetHAnchor(ANCHOR_RIGHT)
    self.onlinestatus:SetVAnchor(ANCHOR_BOTTOM)  
	
	-- top mods panel
	self:CreateTopModsPanel()

	---- Workshop blinker

	--self.workshopupdatenote = self.optionspanel:AddChild(Text(TITLEFONT, 40))
	--self.workshopupdatenote:SetHAlign(ANCHOR_MIDDLE)
	--self.workshopupdatenote:SetPosition(0, 0, 0)
	--self.workshopupdatenote:SetString("Updating Steam Workshop Info...")
	--self.workshopupdatenote:Hide()

	self:StartWorkshopUpdate()

	self.default_focus = self.options_scroll_list
	self:DoFocusHookups()

    if self.cancelbutton then self.cancelbutton:MoveToFront() end
    if self.applybutton then self.applybutton:MoveToFront() end
end)

function ModsScreen:OnBecomeActive()
    ModsScreen._base.OnBecomeActive(self)
	self.mainmenu:Enable()
	if TheInput:ControllerAttached() then
		if self.options_scroll_list then
			self.options_scroll_list:SetFocus()
		elseif self.modlinks and self.modlinks[1] then
			self.modlinks[1]:SetFocus()
		end
	else
		self.mainmenu:SetFocus()    
	end
end

function ModsScreen:GenerateRandomPicks(num, numrange)
	local picks = {}

	while #picks < num do
		local num = math.random(1, numrange)
		if not table.contains(picks, num) then
			table.insert(picks, num)
		end
	end
	return picks
end

function ModsScreen:OnStatsQueried( result, isSuccessful, resultCode )	
	print( "### OnStatsQueried ###" )
	print( dumptable(result) )
	print( isSuccessful )
	print( resultCode )
	
	if TheFrontEnd.screenstack[#TheFrontEnd.screenstack] ~= self then
		return
	end

	if not result or not isSuccessful or string.len(result) <= 1 then return end

	local status, jsonresult = pcall( function() return json.decode(result) end )

	if not jsonresult or not status then return end

	local randomPicks = self:GenerateRandomPicks(#self.modlinks, 20)

	for i = 1, #self.modlinks do
		local title = jsonresult["modnames"][randomPicks[i]]
		if title then 
			local url = jsonresult["modlinks"][title]
			title = string.gsub(title, "(ws%-)", "")
			if string.len(title) > 25 then
				title = string.sub(title, 0, 25).."..."
			end
			self.modlinks[i]:SetText(title)
			if url then
				self.modlinks[i]:SetOnClick(function() VisitURL(url) end)
			end
		end
	end

	local title, url = next(jsonresult["modfeature"])
	if title and url then
		title = string.gsub(title, "(ws%-)", "")
		self.featuredbutton:SetText(title)
		self.featuredbutton:SetOnClick(function() VisitURL(url) end)
	end
end

function ModsScreen:CreateTopModsPanel()

	--Top Mods Stuff--
	self.topmods = self.root:AddChild(Widget("topmods"))
    self.topmods:SetPosition(right_col,0,0)

	self.topmodsbg = self.topmods:AddChild( Image( "images/fepanels.xml", "panel_topmods.tex" ) )
	self.topmodsbg:SetScale(1,.8,1)
	self.topmodsbg:SetPosition(0,65)

    self.morebutton = self.topmods:AddChild(ImageButton())
    self.morebutton:SetText(STRINGS.UI.MODSSCREEN.MOREMODS)
    self.morebutton:SetPosition(Vector3(0,305,0))
    self.morebutton:SetScale(.85)
    self.morebutton:SetOnClick(function() self:MoreWorkshopMods() end)

    self.title = self.topmods:AddChild(Text(TITLEFONT, 40))
    self.title:SetPosition(Vector3(0,225,0))
    self.title:SetString(STRINGS.UI.MODSSCREEN.TOPMODS)

	self.modlinks = {}
	
	local yoffset = 170
	for i = 1, 5 do
		local modlink = self.topmods:AddChild(TextButton("images/ui.xml", "blank.tex","blank.tex","blank.tex","blank.tex"))
	    modlink:SetPosition(Vector3(0,yoffset,0))
	    modlink:SetText(STRINGS.UI.MODSSCREEN.LOADING.."...")
	    modlink:SetFont(BUTTONFONT)
    	modlink:SetTextColour(0.9,0.8,0.6,1)
		modlink:SetTextFocusColour(1,1,1,1)
		modlink:SetHelpTextMessage(STRINGS.UI.MODSSCREEN.MODPAGE)
	    table.insert(self.modlinks, modlink)
	    yoffset = yoffset - 45
	end 
    
	self.featuredtitle = self.topmods:AddChild(Text(TITLEFONT, 40))
    self.featuredtitle:SetPosition(Vector3(0,-70,0))
    self.featuredtitle:SetString(STRINGS.UI.MODSSCREEN.FEATUREDMOD)
    
	self.featuredbutton = self.topmods:AddChild(TextButton("images/ui.xml", "blank.tex","blank.tex","blank.tex","blank.tex"))
    self.featuredbutton:SetPosition(Vector3(0,-130,0))
    self.featuredbutton:SetText(STRINGS.UI.MODSSCREEN.LOADING.."...")
	self.featuredbutton:SetFont(BUTTONFONT)
	self.featuredbutton:SetTextColour(0.9,0.8,0.6,1)
	self.featuredbutton:SetTextFocusColour(1,1,1,1)
	self.featuredbutton:SetHelpTextMessage(STRINGS.UI.MODSSCREEN.MODPAGE)
end

function ModsScreen:HideConfigButton()
	self.modconfigable = false

	if self.modconfigbutton then self.modconfigbutton:Hide() end

	self:DoFocusHookups()
end

function ModsScreen:ShowConfigButton()
	self.modconfigable = true

	if not TheInput:ControllerAttached() then
		if self.modconfigbutton then self.modconfigbutton:Show() end
	end

	self:DoFocusHookups()
end

function ModsScreen:CreateDetailPanel()
	if self.detailpanel then
		self.detailpanel:KillAllChildren()		
	end

	self.detailpanel = self.root:AddChild(Widget("detailpanel"))
    self.detailpanel:SetPosition(mid_col,90,0)

    if not self.detailpanelbg then
	    self.detailpanelbg = self.root:AddChild(Image("images/fepanels_dst.xml", "tall_panel.tex"))
	    self.detailpanelbg:SetPosition(mid_col,90,0)
	    self.detailpanelbg:SetScale(1,.7,1)
	end

	if #self.modnames > 0 then
		self.detailimage = self.detailpanel:AddChild(Image("images/ui.xml", "portrait_bg.tex"))
		self.detailimage:SetSize(102, 102)
		--self.detailimage:SetScale(0.8,0.8,0.8)
		self.detailimage:SetPosition(-130,127,0)

		self.detailtitle = self.detailpanel:AddChild(Text(BUTTONFONT, 40))
		self.detailtitle:SetHAlign(ANCHOR_LEFT)
		self.detailtitle:SetPosition(70, 155, 0)
		self.detailtitle:SetRegionSize( 270, 70 )
		self.detailtitle:SetColour(0,0,0,1)

		--self.detailversion = self.detailpanel:addchild(text(titlefont, 20))
		--self.detailversion:setvalign(anchor_top)
		--self.detailversion:sethalign(anchor_left)
		--self.detailversion:setposition(200, 100, 0)
		--self.detailversion:setregionsize( 180, 70 )

		self.detailauthor = self.detailpanel:AddChild(Text(BUTTONFONT, 30))
		self.detailauthor:SetColour(0,0,0,1)
		--self.detailauthor:SetColour(0.9,0.8,0.6,1) -- link colour
		self.detailauthor:SetHAlign(ANCHOR_LEFT)
		self.detailauthor:SetPosition(70, 113, 0)
		self.detailauthor:SetRegionSize( 270, 70 )
		self.detailauthor:EnableWordWrap(true)

		self.detailcompatibility = self.detailpanel:AddChild(Text(BUTTONFONT, 25))
		self.detailcompatibility:SetColour(0,0,0,1)
		self.detailcompatibility:SetHAlign(ANCHOR_LEFT)
		self.detailcompatibility:SetPosition(70, 83, 0)
		self.detailcompatibility:SetRegionSize( 270, 70 )
		

		self.detaildesc = self.detailpanel:AddChild(Text(BUTTONFONT, 25))
		self.detaildesc:SetColour(0,0,0,1)
		self.detaildesc:SetPosition(6, -8, 0)
		self.detaildesc:SetRegionSize( 352, 165 )
		self.detaildesc:EnableWordWrap(true)

		self.detailwarning = self.detailpanel:AddChild(Text(BUTTONFONT, 33))
		self.detailwarning:SetColour(0.9,0,0,1)
		self.detailwarning:SetPosition(5, -160, 0)
		self.detailwarning:SetRegionSize( 600, 107 )
		self.detailwarning:EnableWordWrap(true)
		
		self.modlinkbutton = self.detailpanel:AddChild(TextButton("images/ui.xml", "blank.tex","blank.tex","blank.tex","blank.tex" ))
		self.modlinkbutton:SetPosition(5, -119, 0)
		self.modlinkbutton:SetText(STRINGS.UI.MODSSCREEN.MODLINK)
		self.modlinkbutton:SetFont(BODYTEXTFONT)
		self.modlinkbutton:SetTextSize(30)
		self.modlinkbutton:SetColour(149/255, 191/255, 242/255, 1)
		self.modlinkbutton:SetTextFocusColour(1,1,1,1)
		self.modlinkbutton:SetOnClick( function() self:ModLinkCurrent() end )
		
		--local enableoptions = {{text="Disabled", data=DISABLE},{text="Enabled",data=ENABLE}}
		--self.enablespinner = self.detailpanel:AddChild(Spinner(enableoptions, 200, 60))
		--self.enablespinner:SetTextColour(0,0,0,1)
		--self.enablespinner:SetPosition(-100, -150, 0)
		--self.enablespinner.OnChanged = function( _, data )
			--self:EnableCurrent(data)
		--end

	else
		self.detaildesc = self.detailpanel:AddChild(Text(BUTTONFONT, 25))
		self.detaildesc:SetString(STRINGS.UI.MODSSCREEN.NO_MODS)
		self.detaildesc:SetColour(0,0,0,1)
		self.detaildesc:SetPosition(6, -8, 0)
		self.detaildesc:SetRegionSize( 352, 165 )
		self.detaildesc:EnableWordWrap(true)

		self.modlinkbutton = self.detailpanel:AddChild(TextButton("images/ui.xml", "blank.tex","blank.tex","blank.tex","blank.tex" ))
		self.modlinkbutton:SetPosition(5, -119, 0)
		self.modlinkbutton:SetFont(BODYTEXTFONT)
		self.modlinkbutton:SetTextSize(30)
		self.modlinkbutton:SetColour(149/255, 191/255, 242/255, 1)
		self.modlinkbutton:SetTextFocusColour(1,1,1,1)
		self.modlinkbutton:SetText(STRINGS.UI.MODSSCREEN.NO_MODS_LINK)
		self.modlinkbutton:SetOnClick( function() self:MoreWorkshopMods() end )--self:MoreMods() end )
		
		self:HideConfigButton()
	end

end

-- Not currently used, for testing only.
local function OnUpdateWorkshopModsComplete(success, msg)
	print("OnUpdateWorkshopModsComplete", success, msg)

	local status = TheSim:GetWorkshopUpdateStatus()
	for k,v in pairs(status) do
		print("-", k, v)
	end
end


function ModsScreen:StartWorkshopUpdate()
	if TheSim:UpdateWorkshopMods( function() self:WorkshopUpdateComplete() end ) then
		self.updatetask = scheduler:ExecutePeriodic(0, self.ShowWorkshopStatus, nil, 0, "workshopupdate", self )
	else
		self:WorkshopUpdateComplete()
	end
end

function ModsScreen:WorkshopUpdateComplete(status, message) --bool, string
	
	self.workshop_update_completed = true
	
	if self.updatetask then
		self.updatetask:Cancel()
		self.updatetask = nil
	end
	if self.workshopupdatenote then
		TheFrontEnd:PopScreen()
		self.workshopupdatenote = nil
	end

	KnownModIndex:UpdateModInfo()
	self.modnames = KnownModIndex:GetModNames()
	local function alphasort(moda, modb)
		if not moda then return false end
		if not modb then return true end
		return string.lower(KnownModIndex:GetModFancyName(moda)) < string.lower(KnownModIndex:GetModFancyName(modb))
	end
	table.sort(self.modnames, alphasort)

	self:ReloadModInfoPrefabs()

	self:CreateDetailPanel()

	if #self.modnames > 0 then
		self:ShowModDetails(1)
	end

	-- Now that we're up to date, build widgets for all the mods
	self.optionwidgets = {}
	for i,v in ipairs(self.modnames) do
	
		local idx = i

		local modname = v
		local modinfo = KnownModIndex:GetModInfo(modname)
		
		local opt = Widget("option")
		opt:SetScale(.9,1)

		opt.idx = idx
		
		opt.bg = opt:AddChild(UIAnim())
		opt.bg:GetAnimState():SetBuild("savetile")
		opt.bg:GetAnimState():SetBank("savetile")
		opt.bg:GetAnimState():PlayAnimation("anim")
		opt.bg:GetAnimState():SetMultColour(.3,.3,.3,1)

		opt.checkbox = opt:AddChild(Image("images/ui.xml", "button_checkbox1.tex"))
		opt.checkbox:SetPosition(-140, 0, 0)

		opt.image = opt:AddChild(Image("images/ui.xml", "portrait_bg.tex"))
		--opt.image:SetScale(imscale,imscale,imscale)
		opt.image:SetPosition(-80,0,0)
		if modinfo and modinfo.icon and modinfo.icon_atlas then
			opt.image:SetTexture("../mods/"..modname.."/"..modinfo.icon_atlas, modinfo.icon)
		end
		opt.image:SetSize(76,76)

		opt.name = opt:AddChild(Text(BUTTONFONT, 35))
		opt.name:SetVAlign(ANCHOR_MIDDLE)
		opt.name:SetHAlign(ANCHOR_LEFT)
		opt.name:SetString(modname)
		if modinfo and modinfo.name then
			opt.name:SetString(modinfo.name)
		end
		opt.name:SetPosition(65, 8, 0)
		opt.name:SetRegionSize( 200, 50 )

		opt.status = opt:AddChild(Text(BODYTEXTFONT, 25))
		opt.status:SetVAlign(ANCHOR_MIDDLE)
		opt.status:SetHAlign(ANCHOR_LEFT)
		opt.status:SetString(modname)
		local modStatus = self:GetBestModStatus(modname)
		if modStatus == "WORKING_NORMALLY" then
			opt.status:SetString(STRINGS.UI.MODSSCREEN.STATUS.WORKING_NORMALLY)
		elseif modStatus == "WILL_ENABLE" then
			opt.status:SetString(STRINGS.UI.MODSSCREEN.STATUS.WILL_ENABLE)
		elseif modStatus == "WILL_DISABLE" then
			opt.status:SetColour(.6,.6,.6,1)
			opt.status:SetString(STRINGS.UI.MODSSCREEN.STATUS.WILL_DISABLE)
		elseif modStatus == "DISABLED_ERROR" then
			opt.status:SetColour(242/255, 99/255, 99/255, 1)--0.9,0.3,0.3,1)
			opt.status:SetString(STRINGS.UI.MODSSCREEN.STATUS.DISABLED_ERROR)
		elseif modStatus == "DISABLED_OLD" then
			opt.status:SetColour(208/255, 120/255, 86/255, 1)--0.8,0.8,0.3,1)
			opt.status:SetString(STRINGS.UI.MODSSCREEN.STATUS.DISABLED_OLD)
		elseif modStatus == "DISABLED_MANUAL" then
			opt.status:SetColour(.6,.6,.6,1)
			opt.status:SetString(STRINGS.UI.MODSSCREEN.STATUS.DISABLED_MANUAL)
		end
		opt.status:SetPosition(68, -22, 0)
		opt.status:SetRegionSize( 200, 50 )

		--jcheng: no compatability flags yet for DST
		--[[
		opt.RoGcompatible = opt:AddChild(Image("images/ui.xml", "rog_off.tex"))
		if modinfo and modinfo.reign_of_giants_compatible then
			if modinfo.reign_of_giants_compatibility_specified == false then
				opt.RoGcompatible:SetTexture("images/ui.xml", "rog_unknown.tex")
			else
				opt.RoGcompatible:SetTexture("images/ui.xml", "rog_on.tex")
			end
		end
		opt.RoGcompatible:SetClickable(false)
		opt.RoGcompatible:SetScale(.35,.33,1)
		opt.RoGcompatible:SetPosition(144, -21, 0)

		opt.DScompatible = opt:AddChild(Image("images/ui.xml", "ds_off.tex"))
		if modinfo and modinfo.dont_starve_compatible then
			if modinfo.dont_starve_compatibility_specified == false then
				opt.DScompatible:SetTexture("images/ui.xml", "ds_unknown.tex")
			else
				opt.DScompatible:SetTexture("images/ui.xml", "ds_on.tex")
			end
		end
		opt.DScompatible:SetClickable(false)
		opt.DScompatible:SetScale(.35,.33,1)
		opt.DScompatible:SetPosition(100, -21, 0)
		
		opt.DSTcompatible = opt:AddChild(Image("images/ui.xml", "ds_off.tex"))
		print( modinfo.mod_name, modinfo.dst_compatibility_specified )
		if modinfo and modinfo.dst_compatible then
			if modinfo.dst_compatibility_specified == false then
				opt.DSTcompatible:SetTexture("images/ui.xml", "ds_unknown.tex")
			else
				opt.DSTcompatible:SetTexture("images/ui.xml", "ds_on.tex")
			end
		end
		opt.DSTcompatible:SetClickable(false)
		opt.DSTcompatible:SetScale(.35,.33,1)
		opt.DSTcompatible:SetPosition(188, -21, 0)]]
		

		if KnownModIndex:IsModEnabled(modname) then
			opt.image:SetTint(1,1,1,1)
			opt.checkbox:SetTexture("images/ui.xml", "button_checkbox2.tex")
			opt.checkbox:SetTint(1,1,1,1)
			opt.name:SetColour(0,0,0,1)
			--opt.RoGcompatible:SetTint(1,1,1,1)
			--opt.DScompatible:SetTint(1,1,1,1)
		else
			opt.image:SetTint(1.0,0.5,0.5,1)
			opt.checkbox:SetTexture("images/ui.xml", "button_checkbox1.tex")
			opt.checkbox:SetTint(1.0,0.5,0.5,1)
			opt.name:SetColour(.4,.4,.4,1)
			--opt.RoGcompatible:SetTint(1.0,0.5,0.5,1)
			--opt.DScompatible:SetTint(1.0,0.5,0.5,1)
		end
		
		local spacing = 105
		
		
		opt.OnGainFocus =
			function()
				TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
				self:ShowModDetails(idx)
				opt:SetScale(.95,1.05,1)
				opt.bg:GetAnimState():PlayAnimation("over")
			end

		opt.OnLoseFocus =
			function()
				opt:SetScale(.9,1,1)
				opt.bg:GetAnimState():PlayAnimation("anim")
			end
			
		opt.OnControl =
			function(_, control, down) 
				if Widget.OnControl(opt, control, down) then return true end

				if not down then 
					if control == CONTROL_ACCEPT and (not TheInput:ControllerAttached() or TheFrontEnd.tracking_mouse) then
						self:EnableCurrent()
						return true
					elseif control == CONTROL_INSPECT and TheInput:ControllerAttached() then	
						self:ConfigureSelectedMod()
						return true
					elseif control == CONTROL_CONTROLLER_ATTACK then
						self:EnableCurrent()
						return true
					elseif control == CONTROL_PAUSE and TheInput:ControllerAttached() then
						self:ModLinkCurrent()
						return true
					end
				end
			end
		
		table.insert(self.optionwidgets, opt)
	end

	-- And make a scrollable list!
	self.options_scroll_list = self.optionspanel:AddChild(ScrollableList(self.optionwidgets, 190, 470, 100, 3))
	self.options_scroll_list:SetPosition(75,-5)

	self:DoFocusHookups()
	self.options_scroll_list:SetFocus()
	
	--Now that we're done the workshop update, update the top mods
	--#srosen disable top mods query until Paul's done his side
	local linkpref = (PLATFORM == "WIN32_STEAM" and "external") or "klei"
	TheSim:QueryStats( '{ "req":"modrank", "field":"Session.Loads.Mods.list", "fieldop":"unwind", "linkpref":"'..linkpref..'", "limit": 20}', 
		function(result, isSuccessful, resultCode) self:OnStatsQueried(result, isSuccessful, resultCode) end)

end

function ModsScreen:DoFocusHookups()

	if self.featuredbutton then
		if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
			self.featuredbutton:SetControl(CONTROL_PAUSE)
		else
			self.featuredbutton:SetControl(CONTROL_ACCEPT)
		end
	end

	if self.modlinks then
		for i = 1, 5 do
			if self.modlinks[i+1] ~= nil then
				self.modlinks[i]:SetFocusChangeDir(MOVE_DOWN, self.modlinks[i+1])
			else
				self.modlinks[i]:SetFocusChangeDir(MOVE_DOWN, self.featuredbutton)
			end

			if self.modlinks[i-1] ~= nil then
				self.modlinks[i]:SetFocusChangeDir(MOVE_UP, self.modlinks[i-1])
			else
				self.modlinks[i]:SetFocusChangeDir(MOVE_UP, self.morebutton)
			end

			if self.modlinks[i] ~= nil then
				if TheInput:ControllerAttached() then
					self.modlinks[i]:SetFocusChangeDir(MOVE_LEFT, self.options_scroll_list)
				else
					if self.modconfigable then
						self.modlinks[i]:SetFocusChangeDir(MOVE_LEFT, self.modconfigbutton)
					else
						self.modlinks[i]:SetFocusChangeDir(MOVE_LEFT, self.applybutton)
					end
				end

				if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
					self.modlinks[i]:SetControl(CONTROL_PAUSE)
				else
					self.modlinks[i]:SetControl(CONTROL_ACCEPT)
				end
			end
		end
	end

	if TheInput:ControllerAttached() then
		if self.applybutton then self.applybutton:Kill() self.applybutton = nil end
		if self.cancelbutton then self.cancelbutton:Kill() self.cancelbutton = nil end
		if self.modconfigbutton then self.modconfigbutton:Kill() self.modconfigbutton = nil end
		if self.morebutton then self.morebutton:Kill() self.morebutton = nil end
		if self.cleanallbutton then self.cleanallbutton:Kill() self.cleanallbutton = nil end

		if self.options_scroll_list then self.options_scroll_list:SetFocusChangeDir(MOVE_RIGHT, self.modlinks[1]) end

		if self.featuredbutton then self.featuredbutton:SetFocusChangeDir(MOVE_UP, self.modlinks[5]) end
		if self.featuredbutton then self.featuredbutton:SetFocusChangeDir(MOVE_LEFT, self.options_scroll_list) end

	else
        if self.applybutton then
    		self.applybutton:SetFocusChangeDir(MOVE_RIGHT, self.morebutton)
    		self.applybutton:SetFocusChangeDir(MOVE_LEFT, self.cancelbutton)
        end

        if self.cancelbutton then
    		self.cancelbutton:SetFocusChangeDir(MOVE_RIGHT, self.applybutton)
    		self.cancelbutton:SetFocusChangeDir(MOVE_LEFT, self.options_scroll_list)
        end

		if self.morebutton then self.morebutton:SetFocusChangeDir(MOVE_DOWN, self.modlinks[1]) end

        if self.modconfigbutton then
    		self.modconfigbutton:SetFocusChangeDir(MOVE_LEFT, self.optionspanel)
    		self.modconfigbutton:SetFocusChangeDir(MOVE_RIGHT, self.morebutton)
    		self.modconfigbutton:SetFocusChangeDir(MOVE_DOWN, self.applybutton)
        end

		if self.featuredbutton then self.featuredbutton:SetFocusChangeDir(MOVE_UP, self.modlinks[5]) end

		if self.options_scroll_list then self.options_scroll_list:SetFocusChangeDir(MOVE_RIGHT, self.cancelbutton) end

		if self.modconfigable then
			if self.featuredbutton then self.featuredbutton:SetFocusChangeDir(MOVE_LEFT, self.modconfigbutton) end
			if self.morebutton then self.morebutton:SetFocusChangeDir(MOVE_LEFT, self.modconfigbutton) end
		else
			if self.featuredbutton then self.featuredbutton:SetFocusChangeDir(MOVE_LEFT, self.applybutton) end
			if self.morebutton then self.morebutton:SetFocusChangeDir(MOVE_LEFT, self.applybutton) end
		end
	end

	-- Rebuild focus dirs when we show the config btn
	if self.modconfigable then
		if self.applybutton then self.applybutton:SetFocusChangeDir(MOVE_UP, self.modconfigbutton) end
		if self.cancelbutton then self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.modconfigbutton) end
		if self.modconfigbutton then self.modconfigbutton:SetFocusChangeDir(MOVE_LEFT, self.options_scroll_list) end
		if self.modconfigbutton then self.modconfigbutton:SetFocusChangeDir(MOVE_RIGHT, self.morebutton) end
		if self.modconfigbutton then self.modconfigbutton:SetFocusChangeDir(MOVE_DOWN, self.applybutton) end
	else -- Clear out controller focus directions when we hide the config btn
		if self.applybutton then self.applybutton:SetFocusChangeDir(MOVE_UP, nil) end
		if self.cancelbutton then self.cancelbutton:SetFocusChangeDir(MOVE_UP, nil) end
		if self.modconfigbutton then self.modconfigbutton:ClearFocusDirs() end
	end
end

function ModsScreen:ShowWorkshopStatus()

	if self.workshop_update_completed then
		if self.updatetask then
			self.updatetask:Cancel()
			self.updatetask = nil
		end
		return
	end
	
	if not self.workshopupdatenote then
		self.workshopupdatenote = PopupDialogScreen( STRINGS.UI.MODSSCREEN.WORKSHOP.UPDATE_TITLE, "", {  })
		TheFrontEnd:PushScreen( self.workshopupdatenote )
	end

	local status = TheSim:GetWorkshopUpdateStatus()
	local statetext = ""
	if status.state == "list" then
		statetext = STRINGS.UI.MODSSCREEN.WORKSHOP.STATE_LIST
	elseif status.state == "details" then
		statetext = STRINGS.UI.MODSSCREEN.WORKSHOP.STATE_DETAILS
	elseif status.state == "download" then
		local progressstring = ""
		if status.progress == 0 then
			progressstring = STRINGS.UI.MODSSCREEN.WORKSHOP.STATE_DOWNLOAD_0
		else
			progressstring = string.format( STRINGS.UI.MODSSCREEN.WORKSHOP.STATE_DOWNLOAD_PERCENT , string.match( tostring(status.progress*100), "^%d*"))
		end
		statetext = STRINGS.UI.MODSSCREEN.WORKSHOP.STATE_DOWNLOAD .."\n".. progressstring
	end
	self.workshopupdatenote.text:SetString(statetext)
end

function ModsScreen:OnControl(control, down)
	if ModsScreen._base.OnControl(self, control, down) then return true end
	
	if not down then 
		if control == CONTROL_CANCEL then 
			self:Cancel()
			return true 
		elseif control == CONTROL_CONTROLLER_ACTION then
			self:Apply()
			return true
		elseif control == CONTROL_MENU_MISC_4 and TheInput:ControllerAttached() then
			self:MoreWorkshopMods()
			return true
		elseif control == CONTROL_MAP and TheInput:ControllerAttached() then
			self:CleanAllButton()
			return true
		end
	end

end

function ModsScreen:GetBestModStatus(modname)
	local modinfo = KnownModIndex:GetModInfo(modname)
	if KnownModIndex:IsModEnabled(modname) then
		if KnownModIndex:WasModEnabled(modname) then
			return "WORKING_NORMALLY"
		else
			return "WILL_ENABLE"
		end
	else
		if KnownModIndex:WasModEnabled(modname) then
			return "WILL_DISABLE"
		else
			if KnownModIndex:GetModInfo(modname).failed or KnownModIndex:IsModKnownBad(modname) then
				return "DISABLED_ERROR"
			elseif KnownModIndex:GetModInfo(modname).old then
				return "DISABLED_OLD"
			else
				return "DISABLED_MANUAL"
			end
		end
	end
end

function ModsScreen:ShowModDetails(idx)
	self.currentmod = idx

	local modname = self.modnames[idx]
	local modinfo = KnownModIndex:GetModInfo(modname)

	if modinfo.icon and modinfo.icon_atlas then
		self.detailimage:SetTexture("../mods/"..modname.."/"..modinfo.icon_atlas, modinfo.icon)
		self.detailimage:SetSize(102, 102)
	else
		self.detailimage:SetTexture("images/ui.xml", "portrait_bg.tex")
		self.detailimage:SetSize(102, 102)
	end
	if modinfo.name then
		self.detailtitle:SetString(modinfo.name)
	else
		self.detailtitle:SetString(modname)
	end
	if modinfo.version then
		--self.detailversion:setstring( string.format(strings.ui.modsscreen.version, modinfo.version))
	else
		--self.detailversion:setstring( string.format(strings.ui.modsscreen.version, 0))
	end
	if modinfo.author then
		self.detailauthor:SetString( string.format(STRINGS.UI.MODSSCREEN.AUTHORBY, modinfo.author))
	else
		self.detailauthor:SetString( string.format(STRINGS.UI.MODSSCREEN.AUTHORBY, "unknown"))
	end
	if modinfo.description then
		self.detaildesc:SetString(modinfo.description)
	else
		self.detaildesc:SetString("")
	end

	if (modinfo.forumthread and modinfo.forumthread ~= "") or string.sub(modname, 1, 9) == "workshop-" then
		self.modlinkbutton:SetText(STRINGS.UI.MODSSCREEN.MODLINK)
	else
		self.modlinkbutton:SetText(STRINGS.UI.MODSSCREEN.MODLINKGENERIC)
	end

	--jcheng: no compat stuff right now
	--[[
	if modinfo.dont_starve_compatible and modinfo.reign_of_giants_compatible then
		if modinfo.dont_starve_compatibility_specified == false and modinfo.reign_of_giants_compatibility_specified == false then
			self.detailcompatibility:SetString(STRINGS.UI.MODSSCREEN.COMPATIBILITY_UNKNOWN)
		else
			self.detailcompatibility:SetString(STRINGS.UI.MODSSCREEN.COMPATIBILITY_ALL)
		end
	else
		if modinfo.dont_starve_compatible and not modinfo.reign_of_giants_compatible then
			self.detailcompatibility:SetString(STRINGS.UI.MODSSCREEN.COMPATIBILITY_DS_ONLY)
		elseif not modinfo.dont_starve_compatible and modinfo.reign_of_giants_compatible then
			self.detailcompatibility:SetString(STRINGS.UI.MODSSCREEN.COMPATIBILITY_ROG_ONLY)
		else
			self.detailcompatibility:SetString(STRINGS.UI.MODSSCREEN.COMPATIBILITY_NONE)
		end
	end
	]]
	
	if modinfo.dst_compatible then
		if modinfo.dst_compatibility_specified == false then
			self.detailcompatibility:SetString(STRINGS.UI.MODSSCREEN.COMPATIBILITY_UNKNOWN)	
		else
			self.detailcompatibility:SetString(STRINGS.UI.MODSSCREEN.COMPATIBILITY_DST)	
		end
	else
		self.detailcompatibility:SetString(STRINGS.UI.MODSSCREEN.COMPATIBILITY_NONE)
	end

	if KnownModIndex:HasModConfigurationOptions(modname) then
		self:ShowConfigButton()
	else
		self:HideConfigButton()
	end

	self.detailwarning:SetColour(0,0,0,1)
	self.detailwarning:SetFont(BUTTONFONT)
	local modStatus = self:GetBestModStatus(modname)
	if self.optionwidgets then 
		self.optionwidgets[idx].status:SetColour(1,1,1,1)
	end
	if modStatus == "WORKING_NORMALLY" then
		--self.enablespinner:SetSelected(ENABLE)
		self.detailwarning:SetString(STRINGS.UI.MODSSCREEN.WORKING_NORMALLY)
		if self.optionwidgets then 
			self.optionwidgets[idx].status:SetString(STRINGS.UI.MODSSCREEN.STATUS.WORKING_NORMALLY) 
		end
	elseif modStatus == "WILL_ENABLE" then
		--self.enablespinner:SetSelected(ENABLE)
		self.detailwarning:SetString(STRINGS.UI.MODSSCREEN.WILL_ENABLE)
		if self.optionwidgets then 
			self.optionwidgets[idx].status:SetString(STRINGS.UI.MODSSCREEN.STATUS.WILL_ENABLE) 
		end
	elseif modStatus == "WILL_DISABLE" then
		--self.enablespinner:SetSelected(DISABLE)
		self.detailwarning:SetString(STRINGS.UI.MODSSCREEN.WILL_DISABLE)
		if self.optionwidgets then 
			self.optionwidgets[idx].status:SetColour(.6,.6,.6,1)
			self.optionwidgets[idx].status:SetString(STRINGS.UI.MODSSCREEN.STATUS.WILL_DISABLE)
		end
	elseif modStatus == "DISABLED_ERROR" then
		--self.enablespinner:SetSelected(DISABLE)
		self.detailwarning:SetFont(TITLEFONT)
		self.detailwarning:SetColour(242/255, 99/255, 99/255, 1)--0.9,0.3,0.3,1)
		self.detailwarning:SetString(STRINGS.UI.MODSSCREEN.DISABLED_ERROR)
		if self.optionwidgets then 
			self.optionwidgets[idx].status:SetColour(242/255, 99/255, 99/255, 1)--0.9,0.3,0.3,1)
			self.optionwidgets[idx].status:SetString(STRINGS.UI.MODSSCREEN.STATUS.DISABLED_ERROR)
		end
	elseif modStatus == "DISABLED_OLD" then
		--self.enablespinner:SetSelected(DISABLE)
		self.detailwarning:SetFont(TITLEFONT)
		self.detailwarning:SetColour(208/255, 120/255, 86/255, 1)--0.8,0.8,0.3,1)
		self.detailwarning:SetString(STRINGS.UI.MODSSCREEN.DISABLED_OLD)
		if self.optionwidgets then 
			self.optionwidgets[idx].status:SetColour(208/255, 120/255, 86/255, 1)--0.8,0.8,0.3,1)
			self.optionwidgets[idx].status:SetString(STRINGS.UI.MODSSCREEN.STATUS.DISABLED_OLD)
		end
	elseif modStatus == "DISABLED_MANUAL" then
		--self.enablespinner:SetSelected(DISABLE)
		self.detailwarning:SetString(STRINGS.UI.MODSSCREEN.DISABLED_MANUAL)
		if self.optionwidgets then 
			self.optionwidgets[idx].status:SetColour(.6,.6,.6,1)
			self.optionwidgets[idx].status:SetString(STRINGS.UI.MODSSCREEN.STATUS.DISABLED_MANUAL)
		end
	end

	if self.optionwidgets and KnownModIndex:IsModEnabled(modname) then
		self.optionwidgets[idx].image:SetTint(1,1,1,1)
		self.optionwidgets[idx].checkbox:SetTexture("images/ui.xml", "button_checkbox2.tex")
		self.optionwidgets[idx].checkbox:SetTint(1,1,1,1)
		self.optionwidgets[idx].name:SetColour(0,0,0,1)
		--self.optionwidgets[idx].RoGcompatible:SetTint(1,1,1,1)
		--self.optionwidgets[idx].DScompatible:SetTint(1,1,1,1)
	elseif self.optionwidgets then
		self.optionwidgets[idx].image:SetTint(1.0,0.5,0.5,1)
		self.optionwidgets[idx].checkbox:SetTexture("images/ui.xml", "button_checkbox1.tex")
		self.optionwidgets[idx].checkbox:SetTint(1.0,0.5,0.5,1)
		self.optionwidgets[idx].name:SetColour(.4,.4,.4,1)
		--self.optionwidgets[idx].RoGcompatible:SetTint(1.0,0.5,0.5,1)
		--self.optionwidgets[idx].DScompatible:SetTint(1.0,0.5,0.5,1)
	end
end

function ModsScreen:OnConfirmEnableCurrent(data, restart)
	local modname = self.modnames[self.currentmod]
	if data == DISABLE then
		KnownModIndex:Disable(modname)
	elseif data == ENABLE then
		KnownModIndex:Enable(modname)
	else
		if KnownModIndex:IsModEnabled(modname) then
			KnownModIndex:Disable(modname)
		else
			KnownModIndex:Enable(modname)
		end
	end
	
	--show the auto-download warning for non-workshop mods
	local modinfo = KnownModIndex:GetModInfo(modname)
	if KnownModIndex:IsModEnabled(modname) and modinfo.all_clients_require_mod then
		local workshop_prefix = "workshop-"
		if string.sub( modname, 0, string.len(workshop_prefix) ) ~= workshop_prefix then
			TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MODSSCREEN.MOD_WARNING_TITLE, STRINGS.UI.MODSSCREEN.MOD_WARNING, 
			{
				{text=STRINGS.UI.MODSSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end }
			}))
		end
	end
	
	--Warn about incompatible mods being enabled
	if KnownModIndex:IsModEnabled(modname) and (not modinfo.dst_compatible or modinfo.dst_compatibility_specified == false) then
		TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MODSSCREEN.MOD_WARNING_TITLE, STRINGS.UI.MODSSCREEN.DST_COMPAT_WARNING, 
		{
			{text=STRINGS.UI.MODSSCREEN.OK, cb = function() TheFrontEnd:PopScreen() end }
		}))
	end

	self:ShowModDetails(self.currentmod)

	if restart then
		KnownModIndex:Save()
		TheSim:Quit()
	end
end

function ModsScreen:EnableCurrent(data)
	local modname = self.modnames[self.currentmod]
	local modinfo = KnownModIndex:GetModInfo(modname)
	
	if modinfo.restart_required then
		print("RESTART REQUIRED")
		TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.MODSSCREEN.RESTART_TITLE, STRINGS.UI.MODSSCREEN.RESTART_REQUIRED, 
		{
			{text=STRINGS.UI.MODSSCREEN.RESTART, cb = function() self:OnConfirmEnableCurrent(data, true) end },
			{text=STRINGS.UI.MODSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end}
		}))
	else
		self:OnConfirmEnableCurrent(data, false)
	end
end

function ModsScreen:ModLinkCurrent()
	local modname = self.modnames[self.currentmod]
	local thread = KnownModIndex:GetModInfo(modname).forumthread
	
	local url = ""
	if thread and thread ~= "" then
		url = "http://forums.kleientertainment.com/index.php?%s"
		url = string.format(url, KnownModIndex:GetModInfo(modname).forumthread)
	else
		if string.sub(modname, 1, 9) == "workshop-" then
			url = "http://steamcommunity.com/sharedfiles/filedetails/?id="..string.sub(modname, 10)
		else
			url = "http://forums.kleientertainment.com/forum/79-dont-starve-together-beta-mods-and-tools/"
		end
	end
	VisitURL(url)
end

function ModsScreen:MoreMods()
	VisitURL("http://forums.kleientertainment.com/files/")
end

function ModsScreen:MoreWorkshopMods()
	VisitURL("http://steamcommunity.com/app/322330/workshop/")
end


function ModsScreen:Cancel()
	KnownModIndex:RestoreCachedSaveData()
	self.mainmenu:Disable()
	TheFrontEnd:Fade(false, screen_fade_time, function()
		self:UnloadModInfoPrefabs(self.infoprefabs)
		TheFrontEnd:PopScreen()
		TheFrontEnd:Fade(true, screen_fade_time)
	end)
end

function ModsScreen:Apply()
	KnownModIndex:Save()
	self.mainmenu:Disable()
	TheFrontEnd:Fade(false, screen_fade_time, function()
		self:UnloadModInfoPrefabs(self.infoprefabs)
		ForceAssetReset()
		SimReset()
	end)
end

function ModsScreen:ConfigureSelectedMod()
	if self.modconfigable then
		local modname = self.modnames[self.currentmod]
		local modinfo = KnownModIndex:GetModInfo(modname)
		self.mainmenu:Disable()
		TheFrontEnd:Fade(false, screen_fade_time, function()
			TheFrontEnd:PushScreen(ModConfigurationScreen(modname))
			TheFrontEnd:Fade(true, screen_fade_time)
		end)
	end
end

function ModsScreen:LoadModInfoPrefabs(prefabtable)
	for i,modname in ipairs(KnownModIndex:GetModNames()) do
		local info = KnownModIndex:GetModInfo(modname)
		if info.icon_atlas and info.icon then
			local atlaspath = "../mods/"..modname.."/"..info.icon_atlas
			local iconpath = string.gsub(atlaspath, "/[^/]*$", "") .. "/"..info.icon
			if softresolvefilepath(atlaspath) and softresolvefilepath(iconpath) then
				local modinfoassets = {
					Asset("ATLAS", atlaspath),
					Asset("IMAGE", iconpath),
				}
				local prefab = Prefab("modbaseprefabs/MODSCREEN_"..modname, nil, modinfoassets, nil)
				RegisterPrefabs( prefab )
				table.insert(prefabtable, prefab.name)
			else
				-- This prevents malformed icon paths from crashing the game.
				print(string.format("WARNING: icon paths for mod %s are not valid. Got icon_atlas=\"%s\" and icon=\"%s\".\nPlease ensure that these point to valid files in your mod folder, or else comment out those lines from your modinfo.lua.", ModInfoname(modname), info.icon_atlas, info.icon))
				info.icon_atlas = nil
				info.icon = nil
			end
		end
	end

	print("Loading Mod Info Prefabs")
	TheSim:LoadPrefabs( prefabtable )
end

function ModsScreen:UnloadModInfoPrefabs(prefabtable)
	print("Unloading Mod Info Prefabs")
	TheSim:UnloadPrefabs( prefabtable )
	for k,v in pairs(prefabtable) do
		prefabtable[k] = nil
	end
end

function ModsScreen:ReloadModInfoPrefabs()
	print("Reloading Mod Info Prefabs")
	-- load before unload -- this prevents the refcounts of prefabs from going 1,
	-- 0, 1 (which triggers a resource unload and crashes). Instead we load first,
	-- so the refcount goes 1, 2, 1 for existing prefabs so everything stays the
	-- same.
	local oldprefabs = self.infoprefabs
	local newprefabs = {}
	self:LoadModInfoPrefabs(newprefabs)
	self:UnloadModInfoPrefabs(oldprefabs)
	self.infoprefabs = newprefabs
end

function ModsScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
    

    -- table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLBACK) .. " " .. STRINGS.UI.HELP.SCROLLBACK)
    -- table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLFWD) .. " " .. STRINGS.UI.HELP.SCROLLFWD)
    
    --table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_FOCUS_LEFT) .. " " .. STRINGS.UI.HELP.NEXTCHARACTER)
    --table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_FOCUS_RIGHT) .. " " .. STRINGS.UI.HELP.PREVCHARACTER)

    local isModWidget = (TheFrontEnd:GetFocusWidget() and TheFrontEnd:GetFocusWidget().parent and table.contains(self.optionwidgets, TheFrontEnd:GetFocusWidget().parent)) or table.contains(self.optionwidgets, TheFrontEnd:GetFocusWidget())
    if isModWidget then
    	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.MODSSCREEN.MODPAGE)
    	if self.modconfigable then
	    	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_INSPECT) .. " " .. STRINGS.UI.HELP.CONFIGURE)
	    end
   		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1) .. " " .. STRINGS.UI.HELP.TOGGLE)
   	end

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_4) .. " " .. STRINGS.UI.MODSSCREEN.MOREMODS)

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MAP) .. " " .. STRINGS.UI.MODSSCREEN.CLEANALL)

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ACTION) .. " " .. STRINGS.UI.HELP.APPLY)  

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
    
    return table.concat(t, "  ")
end

function ModsScreen:CleanAllButton()
	local mod_warning = BigPopupDialogScreen(STRINGS.UI.MODSSCREEN.CLEANALL_TITLE, STRINGS.UI.MODSSCREEN.CLEANALL_BODY,
		{
			{text=STRINGS.UI.SERVERLISTINGSCREEN.OK, cb = 
				function()
					TheSim:CleanAllMods()
										
					KnownModIndex:DisableAllMods()
					KnownModIndex:Save()

					self.options_scroll_list:Clear()
					TheFrontEnd:PopScreen()
					
					self.mainmenu:Disable()
					TheFrontEnd:Fade(false, screen_fade_time, function()
						
						self:UnloadModInfoPrefabs(self.infoprefabs)
						ForceAssetReset()
						SimReset( {reset_action = RESET_ACTION.MODS_SCREEN_PUSH} )
					end)
				end},
			{text=STRINGS.UI.SERVERLISTINGSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end}
		}
	)
	TheFrontEnd:PushScreen( mod_warning )
end

return ModsScreen
