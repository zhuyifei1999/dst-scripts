local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local WardrobePopupScreen = require "screens/wardrobepopup"
local TEMPLATES = require "widgets/templates"

local CharacterSelectScreen = Class(Screen, function(self, profile, character)
	Screen._ctor(self, "CharacterSelectScreen")

	
	--darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	
    
	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    --self.proot:SetPosition(-13,12,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.root = self.proot:AddChild(Widget("root"))
    self.root:SetPosition(-RESOLUTION_X/2, -RESOLUTION_Y/2, 0)


    self.panel = self.root:AddChild(TEMPLATES.CurlyWindow(10, 450, .8, .9, 60, -36))
    self.panel:SetPosition(RESOLUTION_X/2,RESOLUTION_Y/2-10)

    self.panel_bg = self.panel:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
	self.panel_bg:SetScale(.49, .68)
	self.panel_bg:SetPosition(7, 12)

    self:BuildCharactersList(character)
    self:SetPortrait(character)

	self.closebutton = self.proot:AddChild(TEMPLATES.SmallButton(STRINGS.UI.PLAYER_AVATAR.CLOSE, 26, .5, function() self:Close() end))
	self.closebutton:SetPosition(-80, -240)

	self.selectbutton = self.proot:AddChild(TEMPLATES.SmallButton(STRINGS.UI.SKINSSCREEN.SELECT, 26, .5, function() self:Close() TheFrontEnd:PushScreen(WardrobePopupScreen(nil, profile, self.herocharacter or character, true)) end))
	self.selectbutton:SetPosition(100, -240)

end)

function CharacterSelectScreen:OnControl(control, down)
    if CharacterSelectScreen._base.OnControl(self,control, down) then return true end
    
    --[[if control == CONTROL_CANCEL and not down then    
        if #self.buttons > 1 and self.buttons[#self.buttons] then
            self.buttons[#self.buttons].cb()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            return true
        end
    end]]
end


function CharacterSelectScreen:WrapIndex(index)
	local new_index = index
	if new_index < 1 then 
		new_index = #self.characters + new_index
	end
	
	if new_index > #self.characters then 
		new_index = new_index - #self.characters
	end	
	return new_index
end

function CharacterSelectScreen:BuildCharactersList(default_character)
	
	self.heroportrait = self.panel:AddChild(Image())
    self.heroportrait:SetScale(.7)
    self.heroportrait:SetPosition(15, 5)
    
	self.leftportrait = self.panel:AddChild(ImageButton( "bigportraits/wilson.xml", "wilson_none.tex" ))
    self.leftportrait:SetScale(.4)
    self.leftportrait:SetPosition(-275, -60)
    self.leftportrait.focus_scale = {1.05,1.05,1.05}
    self.leftportrait:SetOnClick( function()
   										self.characterIdx = self:WrapIndex( self.characterIdx - 1 )
   										self:SetPortrait()
   									end)
    
	self.rightportrait = self.panel:AddChild(ImageButton( "bigportraits/wilson.xml", "wilson_none.tex" ))
    self.rightportrait:SetScale(.4)
    self.rightportrait:SetPosition(300, -60)
    self.rightportrait.focus_scale = {1.05,1.05,1.05}
    self.rightportrait:SetOnClick( function()
   										self.characterIdx = self:WrapIndex( self.characterIdx + 1 )
   										self:SetPortrait()
   									end)
    

    --self.portrait_shadow = self.panel:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
	--self.portrait_shadow:SetPosition(0, -110)
	--self.portrait_shadow:SetScale(1.2)


	self.characters = ExceptionArrays(GetActiveCharacterList(), MODCHARACTEREXCEPTIONS_DST)
	
	self.characterIdx = 1

    self.left_arrow = self.panel:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_L.tex", "DSTMenu_PlayerLobby_arrow_paperHL_L.tex", nil, nil, nil, {1,1}, {0,0}))
    self.left_arrow:SetScale(.35)
   	self.left_arrow:SetPosition(-385, -60)
   	self.left_arrow:SetOnClick( function()
   									self.characterIdx = self:WrapIndex( self.characterIdx - 1 )
   									self:SetPortrait()
   								end)

   	self.right_arrow = self.panel:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_R.tex", "DSTMenu_PlayerLobby_arrow_paperHL_R.tex", nil, nil, nil, {1,1}, {0,0}))
   	self.right_arrow:SetScale(.35)
   	self.right_arrow:SetPosition(400, -60)
   	self.right_arrow:SetOnClick( function()
   									self.characterIdx = self:WrapIndex( self.characterIdx + 1 )
   									self:SetPortrait()
   								end)

   	if TheInput:ControllerAttached() then 
   		self.left_arrow:SetClickable(false)
   		self.right_arrow:SetClickable(false)
   	end

   	self.title = self.panel:AddChild(Text(BUTTONFONT, 36, STRINGS.UI.SKINSSCREEN.PICK, BLACK))
	self.title:SetPosition(10, 245)


end

function CharacterSelectScreen:SetPortrait()
	local herocharacter = self.characters[self.characterIdx]
	local leftcharacter = self.characters[self:WrapIndex( self.characterIdx - 1 )]
	local rightcharacter = self.characters[self:WrapIndex( self.characterIdx + 1 )]

	if herocharacter ~= nil then
		
		local skin = "_none"

		-- get correct skin here if bases are enabled
		self.heroportrait:SetTexture("bigportraits/" .. herocharacter..".xml", herocharacter .. skin .. ".tex", herocharacter .. ".tex")
		self.leftportrait:SetTextures("bigportraits/" .. leftcharacter..".xml", leftcharacter .. skin .. ".tex")
		self.rightportrait:SetTextures("bigportraits/" .. rightcharacter..".xml", rightcharacter .. skin .. ".tex")
		
		self.herocharacter = herocharacter
	end
end


function CharacterSelectScreen:Close()
	
	TheFrontEnd:PopScreen(self)
end

function CharacterSelectScreen:GetHelpText()
	--[[local controller_id = TheInput:GetControllerID()
	local t = {}
	if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)	
    end
	return table.concat(t, "  ")
	]]
end

return CharacterSelectScreen