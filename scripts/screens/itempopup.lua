local Screen = require "widgets/screen"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Menu = require "widgets/menu"
local UIAnim = require "widgets/uianim"
local Puppet = require "widgets/skinspuppet"


local ItemPopUp = Class(Screen, function(self, items)
	Screen._ctor(self, "ItemPopUp")

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
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

	--throw up the background
    self.bg = self.proot:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
	self.bg:SetScale(.9,.65,.9)
	
	--title	
    self.title = self.proot:AddChild(Text(BUTTONFONT, 55))
    self.title:SetPosition(0, 185, 0)
    self.title:SetString("TITLE")
    self.title:SetColour(0,0,0,1)

	--Item name
    self.skin_name = self.proot:AddChild(Text(BUTTONFONT, 45))
    self.skin_name:SetPosition(-75, 65, 0)
    self.skin_name:SetString("ITEM_NAME")
    self.skin_name:EnableWordWrap(true)    
    self.skin_name:SetRegionSize(300, 200)
    self.skin_name:SetColour(0,0,0,1)
	
    -- Item Description
    self.skin_description = self.proot:AddChild(Text(BUTTONFONT, 35))
    self.skin_description:SetPosition(-75, -50, 0)
    self.skin_description:SetString("ITEM_DESCRIPTION")
    self.skin_description:EnableWordWrap(true)    
    self.skin_description:SetRegionSize(300, 200)
    self.skin_description:SetColour(0,0,0,1)
    
    -- Puppet used to show off the character skins
    local clothing_puppet_scale = 2.06
    self.clothing_puppet = self.proot:AddChild(Puppet())
    self.clothing_puppet:SetPosition(180,-80,0)
    self.clothing_puppet.inst.UITransform:SetScale(clothing_puppet_scale, clothing_puppet_scale, clothing_puppet_scale)

    -- Used to show off the item skins
    local item_scale = .75
    self.paper_item = self.proot:AddChild(UIAnim())
    self.paper_item:SetPosition(180,-60,0)
    self.paper_item.inst.UITransform:SetScale(item_scale, item_scale, item_scale)

    -- Fancy reveal FX
    local spawn_portal_scale = .5
    self.spawn_portal = self.proot:AddChild(UIAnim())
    self.spawn_portal:GetAnimState():SetBuild("puff_spawning")
    self.spawn_portal:GetAnimState():SetBank("spawn_fx")
    self.spawn_portal:SetPosition(180,-50,0)
    self.spawn_portal.inst.UITransform:SetScale(spawn_portal_scale, spawn_portal_scale, spawn_portal_scale) 

	--creates the menu itself
	local button_w = 200
	local space_between = 20
	local spacing = button_w + space_between
    local spacing = 200
    local buttons = {{text = STRINGS.UI.ITEM_SCREEN.OK_BUTTON, cb = function() TheFrontEnd:PopScreen(self) end}}
	self.menu = self.proot:AddChild(Menu(buttons, spacing, true))
	self.menu:SetPosition(-(spacing*(#buttons-1))/2, -185, 0) 

    self.items = items
    self.revealed_items = {}
    self.current_item = 1
    self:SetItemDisplay(self.current_item)

    if self.items and #self.items > 1 then
        local arrowscale = 0.66
        self.rightbutton = self.proot:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
        self.rightbutton:SetPosition(295, 0, 0)
        self.rightbutton:SetOnClick(function() self:ScrollItemList(1) self:EvaulateArrows() end)
        self.rightbutton:SetScale(arrowscale,arrowscale,arrowscale)

        self.leftbutton = self.proot:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
        self.leftbutton:SetPosition(-295, 0, 0)
        self.leftbutton:SetScale(-arrowscale,arrowscale,arrowscale)
        self.leftbutton:SetOnClick(function() self:ScrollItemList(-1) self:EvaulateArrows() end)

        self:EvaulateArrows()
    end

    self.default_focus = self.menu
end)

local anims = 
{
    scratch = .5,
    hungry = .5,
    eat = .5,
    eatquick = .33,
    wave1 = .1,
    wave2 = .1,
    wave3 = .1,
    wave4 = .1,
    happycheer = .1,
    sad = .1,
    angry = .1,
    annoyed = .1,
    bonesaw = .05,
    facepalm = .1,  
}

function ItemPopUp:OnControl(control, down)
    if ItemPopUp._base.OnControl(self,control, down) then 
        return true 
    end
end

function ItemPopUp:OnUpdate(dt)
    self.time_to_anim = self.time_to_anim and self.time_to_anim - dt or 5 +math.random()*5
    -- Selects a random animation for the puppet to play
    if self.time_to_anim < 0 then
		if self.clothing_puppet and self.clothing_puppet:IsVisible() then
			self.clothing_puppet.animstate:PushAnimation(weighted_random_choice(anims))     
			self.clothing_puppet.animstate:PushAnimation("idle", true)
		end
        self.time_to_anim = 2 + math.random()*3
    end
end

function ItemPopUp:ScrollItemList(dir)
    local item_count = #self.items
    if dir < 0 then
        if self.current_item == 1 then
            self.current_item = item_count
        else
            self.current_item = self.current_item - 1
        end
        self:SetItemDisplay(self.current_item)
        return true
    elseif dir > 0 then
        if self.current_item == item_count then
            self.current_item = 1
        else
            self.current_item = self.current_item + 1
        end
        self:SetItemDisplay(self.current_item)
        return true
    end
    return false
end

function ItemPopUp:EvaulateArrows()
    if self.current_item == 1 then
        self.leftbutton:Hide()
    else
        self.leftbutton:Show()
    end

    if self.current_item == #self.items then
        self.rightbutton:Hide()
    else
        self.rightbutton:Show()
    end
end

-- Sets the item display info before revealing it
function ItemPopUp:SetItemDisplay(idx)
    if not self.items or #self.items < 1 then return end

    self.paper_item:Hide()
    self.clothing_puppet:Hide()

    local skin_name = self.items[idx]
    local is_clothing = false
    local skin_data
    
    -- Full skins are included inside the prefabs directory
    -- Clothing skins are contained in the clothing.lua file and can be accessed through a constant
    if CLOTHING[skin_name] == nil then
		skin_data = Prefabs[skin_name]
	else
		skin_data = CLOTHING[skin_name]
		is_clothing = true
	end
	
    local item_name = STRINGS.SKIN_NAMES[skin_name]
    local item_description = STRINGS.SKIN_DESCRIPTIONS[skin_name]
    
    -- Fallback for development, just in case the name or description doesn't yet exist.
    -- This can be removed before shipping
    if item_name == nil then
		item_name = skin_name
	end
    
    if item_description == nil then
		item_description = "Description for " .. item_name
	end

    local character = true

    -- Sets the puppet for clothing
	if is_clothing then
		local skin_names_table = { skin_name }
		self.clothing_puppet:SetSkins(ThePlayer.prefab, ThePlayer.prefab, skin_names_table)
        self.clothing_puppet:Show()

    -- Sets the puppet for a full skin
    elseif skin_data.skins then
        self.clothing_puppet:SetSkins(skin_data.base_prefab, skin_data.skins.normal_skin, {})
        self.clothing_puppet:Show()

    -- Sets the item
    elseif skin_data.ui_preview then
        print(string.format("Setting up paper_item with bank: %s and build: %s for skin %s", skin_data.ui_preview.bank, skin_data.ui_preview.build, skin_name))
        self.paper_item:GetAnimState():SetBuild(skin_data.ui_preview.build)
        
        -- TODO: remove this once we have the proper banks set up
        if skin_data.base_prefab == "backpack" then
            self.paper_item:GetAnimState():SetBank("backpack1")--skin_data.ui_preview.bank)
        else
             self.paper_item:GetAnimState():SetBank(skin_data.ui_preview.bank)
        end

        self.paper_item:Show()
        character = false
    end

    -- Sets the strings and descriptions
	if not is_clothing then
		local name_string = (character and STRINGS.CHARACTER_NAMES[skin_data.base_prefab]) or STRINGS.NAMES[string.upper(skin_data.base_prefab)]
	    self.title:SetString(string.format(STRINGS.UI.ITEM_SCREEN.NEW_SKIN, name_string))
	else
		self.title:SetString(STRINGS.UI.ITEM_SCREEN.NEW_CLOTHING_SKIN)
	end
	
    self.skin_name:SetString(string.format("%s", item_name))
    self.skin_description:SetString(string.format("%s", item_description))

    self:RevealItem(idx, character, item_name)
end

-- Handles the presentation stuff
function ItemPopUp:RevealItem(idx, character, item_name)
    if self.revealed_items[idx] then return end

    self.revealed_items[idx] = true
    self.clothing_puppet:Hide()
    self.paper_item:Hide()

    self.spawn_portal:GetAnimState():PlayAnimation("medium") -- Fancy FX

    -- Character revealing
    if character then
		self.clothing_puppet.inst:DoTaskInTime(FRAMES * 12, function() 
			self.clothing_puppet:Show()
			self.clothing_puppet.animstate:PlayAnimation("wave"..math.random(1,3))
			self.clothing_puppet.animstate:PushAnimation("idle")
			self.time_to_anim = 2 + math.random()*3
		end)
    else -- Item Revealing
        self.paper_item.inst:DoTaskInTime(FRAMES * 12, function() 
            self.paper_item:Show()
            self.paper_item:GetAnimState():PlayAnimation("anim") 
            --TODO: Ugh, the items don't all have the same base anim. Usually "idle" or "anim". Need to unify.
        end)
    end

    TheNet:Announce (string.format (STRINGS.UI.NOTIFICATION.NEW_SKIN_ANNOUNCEMENT, ThePlayer:GetDisplayName(), item_name))

end

return ItemPopUp