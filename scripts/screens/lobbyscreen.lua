local Screen = require "widgets/screen"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local PopupDialogScreen = require "screens/popupdialog"

local LobbyScreen = Class(Screen, function(self, profile, cb, no_backbutton, default_character, days_survived)
	Screen._ctor(self, "LobbyScreen")
    self.profile = profile
	self.log = true
    
    self.no_cancel = no_backbutton
    
    self.currentcharacter = nil

    if days_survived then
    	self.days_survived = math.floor(days_survived)
    else
    	self.days_survived = -1
    end

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

    self.fixed_root = self.root:AddChild(Widget("root"))
    self.fixed_root:SetPosition(-RESOLUTION_X/2, -RESOLUTION_Y/2, 0)


    if self.days_survived >= 0 then
	    self.dayssurvivedwidget = self.root:AddChild(Text(UIFONT, 30, STRINGS.UI.LOBBYSCREEN.DAYSSURVIVED.." "..self.days_survived))
	    self.dayssurvivedwidget:SetHAlign(ANCHOR_LEFT)
	    self.dayssurvivedwidget:SetVAlign(ANCHOR_TOP)
	    local w = self.dayssurvivedwidget:GetRegionSize()
	    self.dayssurvivedwidget:SetPosition(-RESOLUTION_X/2 + w/2 + 80, -RESOLUTION_Y/2 + 80, 0)
	end
    
    self.heroportait = self.fixed_root:AddChild(Image())
    --self.heroportait:SetVRegPoint(ANCHOR_BOTTOM)
    --self.heroportait:SetHRegPoint(ANCHOR_LEFT)
    self.heroportait:SetScale(.9)
    self.heroportait:SetPosition(270, 400)
    
    local adjust = 16
    
    self.biobox = self.fixed_root:AddChild(Image("images/fepanels.xml", "biobox.tex"))
    self.biobox:SetPosition(822 + adjust,RESOLUTION_Y-489+30,0)
    
    self.charactername = self.fixed_root:AddChild(Text(TITLEFONT, 60))
    self.charactername:SetHAlign(ANCHOR_MIDDLE)
    self.charactername:SetPosition(820 + adjust, RESOLUTION_Y - 400+30,0)
	self.charactername:SetRegionSize( 500, 70 )

    self.characterquote = self.fixed_root:AddChild(Text(UIFONT, 30))
    self.characterquote:SetHAlign(ANCHOR_MIDDLE)
    self.characterquote:SetVAlign(ANCHOR_TOP)
    self.characterquote:SetPosition(820 + adjust, RESOLUTION_Y - 525 + 60+30,0)
	self.characterquote:SetRegionSize( 500, 60 )
	self.characterquote:EnableWordWrap( true )
	self.characterquote:SetString( "" )

    self.characterdetails = self.fixed_root:AddChild(Text(BODYTEXTFONT, 30))
    self.characterdetails:SetHAlign(ANCHOR_LEFT)
    self.characterdetails:SetVAlign(ANCHOR_TOP)
    self.characterdetails:SetPosition(820 + adjust, RESOLUTION_Y - 525 - 30+30,0)
	self.characterdetails:SetRegionSize( 450, 120 )
	self.characterdetails:EnableWordWrap( true )
	self.characterdetails:SetString( "" )

    if not TheInput:ControllerAttached() then
		self.startbutton = self.fixed_root:AddChild(ImageButton())
		--button:SetScale(.8,.8,.8)
		self.startbutton:SetText(STRINGS.UI.LOBBYSCREEN.SELECT)
		self.startbutton:SetOnClick(
			function()
				self.startbutton:Disable()
				if self.cb then
					self.cb(self.currentcharacter, nil) --2nd parameter is skin
				end
			end)	
		self.startbutton:SetFont(BUTTONFONT)
		self.startbutton:SetTextSize(40)
		--self.startbutton.text:SetVAlign(ANCHOR_MIDDLE)
		self.startbutton.text:SetColour(0,0,0,1)
		self.startbutton:SetPosition( 820 + 90 + adjust, 75, 0)

		self.randomcharbutton = self.fixed_root:AddChild(ImageButton())
		self.randomcharbutton:SetText(STRINGS.UI.SANDBOXMENU.RANDOM)
		self.randomcharbutton:SetOnClick(
			function()
				self.randomcharbutton:Disable()
				if self.cb ~= nil then
                    local rand_char = self.characters[math.random(#self.characters)]
					self.cb(rand_char, nil) --2nd parameter is skin
				end
			end
		)
		self.randomcharbutton:SetFont(BUTTONFONT)
		self.randomcharbutton:SetTextSize(40)
		self.randomcharbutton.text:SetColour(0,0,0,1)
		self.randomcharbutton:SetPosition( 820 - 83 + adjust, 75, 0)

		if not no_backbutton then
		
			self.startbutton:SetPosition( 820 + 175+ adjust, 75, 0)
			self.randomcharbutton:SetPosition( 820 + 5 + adjust, 75, 0)

			self.backbutton = self.fixed_root:AddChild(ImageButton())
			--button:SetScale(.8,.8,.8)
			self.backbutton:SetText(STRINGS.UI.LOBBYSCREEN.DISCONNECT)
			self.backbutton:SetOnClick(function() self:DoConfirmQuit() end)
			self.backbutton:SetFont(BUTTONFONT)
			self.backbutton:SetTextSize(40)
			self.backbutton.text:SetColour(0,0,0,1)
			self.backbutton:SetPosition( 820 - 165+ adjust, 75, 0)
		end
	end
    
	self.characters = JoinArrays(ExceptionArrays(DST_CHARACTERLIST, MODCHARACTEREXCEPTIONS_DST), MODCHARACTERLIST)

	self.portrait_bgs = {}

    self.portraits = {}
    
	self.portrait_frames = {}

    for k = 1,3 do
		local ypos = 720-300+35
		local xbase = 640
		local width = 190
		local xpos = xbase + (k-1) * width

		local character_portrait = self.fixed_root:AddChild(Widget("character_portrait"))
		character_portrait:SetPosition(xpos, ypos, 0)

		local portrait_bg = character_portrait:AddChild(UIAnim())
		portrait_bg:GetAnimState():SetBuild("portrait_frame")
		portrait_bg:GetAnimState():SetBank("portrait_frame")
		portrait_bg:GetAnimState():PlayAnimation("idle")
		
		
		
		--portrait:SetVRegPoint(ANCHOR_BOTTOM)
		table.insert(self.portrait_bgs, portrait_bg)

		local portrait = character_portrait:AddChild(Image())
		portrait:SetPosition(0, 80, 0)

		table.insert(self.portraits, portrait)

		local portrait_frame = character_portrait:AddChild(Image("images/selectscreen_portraits.xml", "frame.tex"))
		portrait_frame:SetMouseOverTexture("images/selectscreen_portraits.xml", "frame_mouse_over.tex")
		portrait_frame:SetPosition(0, 80, 0)

		character_portrait.OnControl = function(_, control, down) if control == CONTROL_ACCEPT then if not down then self:OnClickPortait(k) return true end end end
		character_portrait.OnGainFocus = function() if self.portrait_idx ~= k then portrait_bg:GetAnimState():PlayAnimation("mouseover") end end
		character_portrait.OnLoseFocus = function() if self.portrait_idx ~= k then portrait_bg:GetAnimState():PlayAnimation("idle") end end
		table.insert(self.portrait_frames, portrait_frame)
    end

	self.rightbutton = self.fixed_root:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
    self.rightbutton:SetPosition(1129+10, RESOLUTION_Y-211, 0)
    self.rightbutton:SetOnClick( function() self:SelectAndScroll(1) end)

	self.leftbutton = self.fixed_root:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
    self.leftbutton:SetPosition(516+15-10, RESOLUTION_Y-211, 0)
    self.leftbutton:SetScale(-1,1,1)
    self.leftbutton:SetOnClick( function() self:SelectAndScroll(-1) end)
    
    self:SetOffset(0)
    self:SelectPortrait(1)
    self.cb = cb
    
    --TheFrontEnd:DoFadeIn(2)
    self:SelectCharacter(default_character)
end)

--[[function LobbyScreen:OnGainFocus()
    self._base.OnGainFocus(self)
    self.startbutton:Enable()
end--]]

function LobbyScreen:OnClickPortait(portrait)
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
	local character = self:GetCharacterForPortrait(portrait)
	self:SelectPortrait(portrait)
end

function LobbyScreen:SelectCharacter(character)
	for k,v in ipairs(self.characters) do
		if v == character then
			self:SetOffset(k-1)
			self:SelectPortrait(1)
		end
	end
end

function LobbyScreen:Scroll(scroll)
	--[[if self.portrait_idx then
		self.portrait_idx = self.portrait_idx - scroll
	end--]]

	self:SetOffset( self.offset + scroll )
end

function LobbyScreen:SelectAndScroll(dir)
	if dir < 0 then
		if self.portrait_idx == 1 then
			self:SetOffset( self.offset - 1 )
			self:SelectPortrait(1)
		else
			self:SelectPortrait(self.portrait_idx - 1)
		end
		return true
	elseif dir > 0 then
		if self.portrait_idx == 3 then
			self:SetOffset( self.offset + 1 )
			self:SelectPortrait(3)
		else
			self:SelectPortrait(self.portrait_idx + 1)
		end
		
		return true
	end
	return false
end

function LobbyScreen:GetCharacterForPortrait(portrait)
	local idx = (portrait-1 + self.offset) % #self.characters + 1 
	return self.characters[idx]
end

function LobbyScreen:SetOffset(offset)
	self.offset = offset
	for k = 1,3 do
		local character = self:GetCharacterForPortrait(k)

		self.portrait_bgs[k]:GetAnimState():PlayAnimation(k == self.portrait_idx and "selected" or "idle", true)

        local islocked = false
        if islocked then
            local atlas_silho = table.contains(MODCHARACTERLIST, character) and ("images/selectscreen_portraits/"..character.."_silho.xml") or "images/selectscreen_portraits.xml"
            self.portraits[k]:SetTexture(atlas_silho, character.."_silho.tex")
        else
            local atlas = table.contains(MODCHARACTERLIST, character) and ("images/selectscreen_portraits/"..character..".xml") or "images/selectscreen_portraits.xml"
            self.portraits[k]:SetTexture(atlas, character..".tex")
        end
	end	
end


function LobbyScreen:OnControl(control, down)
    
    if LobbyScreen._base.OnControl(self, control, down) then return true end

    if not self.no_cancel and
    	not down and control == CONTROL_CANCEL then 
		self:DoConfirmQuit()
		return true 
    end

    if TheInput:ControllerAttached() and
		self.can_accept and not down and control == CONTROL_ACCEPT then
		if self.cb then
			self.cb(self.currentcharacter, nil) --2nd parameter is skin
		end
		return true
    end

    if not down and control == CONTROL_MENU_MISC_2 then
        if self.cb ~= nil then
            local rand_char = self.characters[math.random(#self.characters)]
            self.cb(rand_char, nil) --2nd parameter is skin
        end
        return true
    end

    --#srosen this list isn't large enough to warrant speed-scroll (nor is it presented as the same style as things that do have it)
    --if down then 
        -- if control == CONTROL_SCROLLBACK then
        --     self:Scroll(-1)
        --     self:SelectPortrait(self.portrait_idx)
        --     TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        --     return true
        -- elseif control == CONTROL_SCROLLFWD then
        --     self:Scroll(1)
        --     self:SelectPortrait(self.portrait_idx)
        --     TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        --     return true
        -- end
    --end
end

 function LobbyScreen:DoConfirmQuit() 	
 	self.active = false
	
	local function doquit()
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

function LobbyScreen:OnFocusMove(dir, down)
	
	if down then
		if dir == MOVE_LEFT then
			if self.portrait_idx == 1 then
				self:Scroll(-1)
				self:SelectPortrait(1)
			else
				self:SelectPortrait(self.portrait_idx - 1)
			end
			return true
		elseif dir == MOVE_RIGHT then
			if self.portrait_idx == 3 then
				self:Scroll(1)	
				self:SelectPortrait(3)
			else
				self:SelectPortrait(self.portrait_idx + 1)
			end
			
			return true
		end
	end
end

function LobbyScreen:SelectPortrait(portrait)
	local character = self:GetCharacterForPortrait(portrait)

	self.portrait_idx = portrait
	for k,v in pairs(self.portrait_bgs) do
		v:GetAnimState():PlayAnimation("idle")
	end

	if self.portrait_bgs[portrait] then
		self.portrait_bgs[portrait]:GetAnimState():PlayAnimation("selected", true)
	end

	if character ~= nil then
		if table.contains(self.characters, character) then
			self.heroportait:SetTexture("bigportraits/"..character..".xml", character..".tex")
		end
		self.currentcharacter = character
		self.charactername:SetString(STRINGS.CHARACTER_TITLES[character] or "")
		self.characterquote:SetString(STRINGS.CHARACTER_QUOTES[character] or "")
		if character == "woodie" and TheNet:GetCountryCode() == "CA" then
			self.characterdetails:SetString(STRINGS.CHARACTER_DESCRIPTIONS[character.."_canada"] or "")
		else
			self.characterdetails:SetString(STRINGS.CHARACTER_DESCRIPTIONS[character] or "")
		end
		self.can_accept = true
		if self.startbutton ~= nil then
			self.startbutton:Enable()
		end
	else
		self.can_accept = false
		self.heroportait:SetTexture("bigportraits/locked.xml", "locked.tex")
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
    

    --table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PAGELEFT) .. " " .. STRINGS.UI.HELP.SCROLLBACK)
    --table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PAGERIGHT) .. " " .. STRINGS.UI.HELP.SCROLLFWD)
    
    --table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_FOCUS_LEFT) .. " " .. STRINGS.UI.HELP.NEXTCHARACTER)
    --table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_FOCUS_RIGHT) .. " " .. STRINGS.UI.HELP.PREVCHARACTER)

   	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_2) .. " " .. STRINGS.UI.HELP.RANDOM)

   	if self.can_accept then
   		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HELP.SELECT)
   	end

    if not self.no_cancel then
    	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.LOBBYSCREEN.DISCONNECT)
    end
    

    return table.concat(t, "  ")
end

function LobbyScreen:OnBecomeActive()
    TheMixer:SetLevel("master", 1)
	TheMixer:PushMix("lobby")
    self._base.OnBecomeActive(self)
end

function LobbyScreen:OnBecomeInactive()
    TheMixer:PopMix("lobby")
    self._base.OnBecomeInactive(self)
end

return LobbyScreen