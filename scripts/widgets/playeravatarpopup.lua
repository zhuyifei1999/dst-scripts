--local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Puppet = require "widgets/skinspuppet"
local TEMPLATES = require "widgets/templates"

local EQUIPSLOT_IDS = {}
local slot = 0
for k, v in pairs(EQUIPSLOTS) do
    slot = slot + 1
    EQUIPSLOT_IDS[v] = slot
end
slot = nil

local PlayerAvatarPopup = Class(Widget, function(self, owner, player_name, data, show_net_profile)
    Widget._ctor(self, "PlayerAvatarPopupScreen")

    self.owner = owner
    self.player_name = nil
    self.userid = nil
    self.target = nil
    self.started = false
    self.settled = false

    self.proot = self:AddChild(Widget("ROOT"))

    self:SetPlayer(player_name, data, show_net_profile)
    self:Start()
end)

function PlayerAvatarPopup:SetPlayer(player_name, data, show_net_profile)
    local character = data.prefab or data.character or "wilson"
    if character == "" then 
        character = "notselected"
    elseif not softresolvefilepath("bigportraits/"..character..".xml") then 
        -- TODO: insert correct art for unknown mod character here
        character = "unknownmod"
    end

    self.player_name = player_name
    self.userid = data.userid
    self.target = data.inst

    self.frame = self.proot:AddChild(TEMPLATES.CurlyWindow(100, 520, .6, .6, 39, -25))
    self.frame:SetPosition(0, 20)

    self.frame_bg = self.frame:AddChild(Image("images/serverbrowser.xml", "side_panel.tex"))
    self.frame_bg:SetScale(-.87, 0.8)
    self.frame_bg:SetPosition(5, 5)

    if character ~= "notselected" then 
        local left_column = -80
        local right_column = 80

        --title 
        self.title = self.proot:AddChild(Text(TALKINGFONT, 30))
        self.title:SetPosition(5, 115, 0)
        self.title:SetTruncatedString(player_name, 200, 18, true)
        if data.colour then 
            self.title:SetColour(unpack(data.colour))
        else 
            self.title:SetColour(1, 1, 1, 1)
        end
        self.title:SetRegionSize(200, 50)

        local build = character
        if build == "unknownmod" then 
            build = "mod_player_build"
        end

       
        self.puppet = self.proot:AddChild(Puppet())
        self.puppet:SetPosition( 0, 155)
        self.puppet:SetSkins(build, data.base_skin, {data.body_skin, data.hand_skin, data.legs_skin}) 
        self.puppet:SetScale(1.5)

        self.shadow = self.proot:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
        self.shadow:SetPosition(0, 150)
        self.shadow:SetScale(.2)

        if data.playerage then 
            self.age = self.proot:AddChild(Text(NEWFONT, 25))
            self.age:SetPosition(0, 87, 0)
            self.age:SetString(STRINGS.UI.LOBBYSCREEN.DAYSSURVIVED.." "..data.playerage)
            self.age:SetColour(0,0,0,1)
        end

      
        local body_offset = 40
        if not TUNING.SKINS_BASE_ENABLED then 
            body_offset = -20
        end

        if TUNING.SKINS_BASE_ENABLED then 
            self.base_image = self.proot:AddChild(self:GetSkinWidgetForSlot("base", data.base_skin or character.."_none")) 
            self.base_image:SetPosition(right_column, 160)
        end
        
        self.body_image = self.proot:AddChild(self:GetSkinWidgetForSlot("body", data.body_skin or "none"))
        self.body_image:SetPosition(right_column, body_offset)
       
        self.hand_image = self.proot:AddChild(self:GetSkinWidgetForSlot("hand", data.hand_skin or "none"))
        self.hand_image:SetPosition(right_column, body_offset-100)
        
        self.legs_image = self.proot:AddChild(self:GetSkinWidgetForSlot("legs", data.legs_skin or "none"))
        self.legs_image:SetPosition(right_column, body_offset-200)
       
      
        --[[if character == "unknownmod" then 
            self.heroportrait = self.proot:AddChild(Image("bigportraits/unknownmod.xml", "unknownmod.tex" )) 
        else 
            self.heroportrait = self.proot:AddChild(Image("bigportraits/"..character..".xml", character.."_none.tex" )) -- TODO: get correct character skin here
        end
        self.heroportrait:SetPosition(right_column + 15, body_offset - 335)
        self.heroportrait:SetScale(.36)
        ]]

        local equip_offset = -20

        self.head_equip_image = self.proot:AddChild(self:GetEquipWidgetForSlot(EQUIPSLOTS.HEAD, data.equip))
        self.head_equip_image:SetPosition(left_column, equip_offset)

        self.hand_equip_image = self.proot:AddChild(self:GetEquipWidgetForSlot(EQUIPSLOTS.HANDS, data.equip))
        self.hand_equip_image:SetPosition(left_column, equip_offset-100)

        self.body_equip_image = self.proot:AddChild(self:GetEquipWidgetForSlot(EQUIPSLOTS.BODY, data.equip))
        self.body_equip_image:SetPosition(left_column, equip_offset-200)

        if show_net_profile and TheNet:IsNetIDPlatformValid(data.netid) then 
            self.netprofilebutton = self.proot:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "steam.tex", "", false, false, function() if data.netid ~= nil then TheNet:ViewNetProfile(data.netid) end end ))
            self.netprofilebutton:SetScale(.5)
            self.netprofilebutton:SetPosition(right_column+50,115,0)
        end
    else
        self.proot:SetPosition(10, 0)
        self.bg = self.proot:AddChild(TEMPLATES.CenterPanel(nil, nil, true))
        self.bg:SetScale(.3, .6)

        self.title = self.proot:AddChild(Text(TALKINGFONT, 30))
        self.title:SetPosition(0, 75, 0)
        self.title:SetTruncatedString(player_name, 200, 18, true)
        if data.colour then 
            self.title:SetColour(unpack(data.colour))
        else 
            self.title:SetColour(1, 1, 1, 1)
        end
        self.title:SetRegionSize(200, 50)

        self.text = self.proot:AddChild(Text(UIFONT, 25, STRINGS.UI.PLAYER_AVATAR.CHOOSING))
        self.text:SetColour(unpack(data.colour))

        if show_net_profile and TheNet:IsNetIDPlatformValid(data.netid) then 
            self.netprofilebutton = self.proot:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "steam.tex", "", false, false, function() if data.netid ~= nil then TheNet:ViewNetProfile(data.netid) end end ))
            self.netprofilebutton:SetScale(.5)
            self.netprofilebutton:SetPosition(0,-75,0)
        end
    end

end

function PlayerAvatarPopup:SetTitleTextSize(size)
    self.title:SetSize(size)
end

function PlayerAvatarPopup:SetButtonTextSize(size)
    self.menu:SetTextSize(size)
end

function PlayerAvatarPopup:OnControl(control, down)
    if PlayerAvatarPopup._base.OnControl(self,control, down) then return true end

    --[[if control == CONTROL_CANCEL and not down then    
        if #self.buttons > 1 and self.buttons[#self.buttons] then
            self.buttons[#self.buttons].cb()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            return true
        end
    end]]
end

function PlayerAvatarPopup:Start()
    if not self.started then
        self.started = true
        self:StartUpdating()

        local w, h = self.frame_bg:GetSize()
        
        self.out_pos = Vector3(.5*w, 0, 0)
        self.in_pos = Vector3(-.95*w, 0, 0)

        self:MoveTo(self.out_pos, self.in_pos, .33, function() self.settled = true end)
    end
end

function PlayerAvatarPopup:Close()
    if self.started then
        self.started = false
        self.current_speed = 0

        self:StopUpdating()
        self:MoveTo(self.in_pos, self.out_pos, .33, function() self:Kill() end)
    end
end

function PlayerAvatarPopup:OnUpdate(dt)
    if self.owner.components.playercontroller == nil or
        not self.owner.components.playercontroller:IsEnabled() or
        not self.owner.HUD:IsVisible() or
        (self.target ~= nil and
        not (self.target:IsValid() and
            self.owner:IsNear(self.target, 20))) then
        self:Close()
    end
end

function PlayerAvatarPopup:GetHelpText()
    --[[local controller_id = TheInput:GetControllerID()
    local t = {}
    if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK) 
    end
    return table.concat(t, "  ")
    ]]
end

function PlayerAvatarPopup:GetSkinWidgetForSlot(slot, name)

    local image_group = Widget("image_group")

    -- text background
    local bg = image_group:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    bg:SetSize(150, 28)
    bg:SetPosition(0, 0, 0)

    local rarity = GetRarityForItem(slot, name)
    local text = image_group:AddChild(Text(NEWFONT_OUTLINE, 24, "", SKIN_RARITY_COLORS[rarity]))
    text:SetTruncatedString(STRINGS.SKIN_NAMES[name] or STRINGS.SKIN_NAMES["missing"], 145, 12, true)
    text:SetRegionSize(130, 26)
    text:SetPosition(0, 0, 0)


    local image_name = name
    
    if not image_name or image_name == "none" then 
        if slot == "body" then 
            image_name = "body_default1"
        elseif slot == "hand" then 
            image_name = "hand_default1"
        elseif slot == "legs" then 
            image_name = "legs_default1"
        else
            image_name = "default"
        end
    end

    --[[local shadow = image_group:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
   
    if slot == "base" then 
        shadow:SetPosition(0, 18)
        shadow:SetScale(.12)
    else 
        shadow:SetPosition(0, 18)
        shadow:SetScale(.25)
        shadow:SetFadeAlpha(.70)
    end
    ]]

    local image = image_group:AddChild(UIAnim())
    image:GetAnimState():SetBuild("frames_comp") 
    image:GetAnimState():SetBank("fr")
    image:GetAnimState():OverrideSkinSymbol("SWAP_ICON", image_name, "SWAP_ICON")
    image:GetAnimState():PlayAnimation("icon", true)
    image:SetScale(.70)
    image:SetPosition(0, 50)

    return image_group

end

local default_images = 
{
    hands = "unknown_hand.tex",
    head = "unknown_head.tex",
    body = "unknown_body.tex",
}

function PlayerAvatarPopup:GetEquipWidgetForSlot(slot, equipdata)

    local image_group = Widget("image_group")

    -- text background
    local bg = image_group:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    bg:SetSize(150, 28)
    bg:SetPosition(0, 0, 0)

    local name = equipdata and equipdata[EQUIPSLOT_IDS[slot]] or nil
    name = name ~= nil and #name > 0 and name or "none"

    local rarity = GetRarityForItem("item", name)

	local text = image_group:AddChild(Text(NEWFONT_OUTLINE, 24, "", SKIN_RARITY_COLORS[rarity]))
    text:SetTruncatedString(GetName(name), 145, 12, true)
    text:SetRegionSize(130, 26)
    text:SetPosition(0, 0, 0)

    local atlas = "images/inventoryimages.xml"
    
	local default = default_images[slot] or "trinket_5.tex"
	
    --print("Looking for name ", name, slot)
    if not name or name == "none" then 
        if slot == EQUIPSLOTS.BODY then
            atlas = "images/hud.xml" 
            name = "equip_slot_body_hud"
        elseif slot == EQUIPSLOTS.HANDS then 
            atlas = "images/hud.xml" 
            name = "equip_slot_hud"
        elseif slot == EQUIPSLOTS.HEAD then 
            atlas = "images/hud.xml" 
            name = "equip_slot_head_hud"
        else
            name = "default"
        end
    end

	local image = image_group:AddChild(Image(atlas, name..".tex", default))
   
    image:SetScale(1)
    image:SetPosition(0, 50)

    return image_group

end

return PlayerAvatarPopup
