local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local SkinsPuppet = require "widgets/skinspuppet"
local TEMPLATES = require "widgets/templates"

local REFRESH_INTERVAL = .5

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
    self.time_to_refresh = REFRESH_INTERVAL

    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetPosition(335, 0)

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

    self.currentcharacter = character
    self.player_name = player_name
    self.userid = data.userid
    self.target = data.inst

    self.frame = self.proot:AddChild(TEMPLATES.CurlyWindow(130, 520, .6, .6, 39, -25))
    self.frame:SetPosition(0, 20)

    self.frame_bg = self.frame:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
    self.frame_bg:SetScale(.51, .73)
    self.frame_bg:SetPosition(5, 10)

    if character ~= "notselected" then 
        local left_column = -94
        local right_column = 94

        --title
        self.title = self.proot:AddChild(Text(TALKINGFONT, 32))
        self.title:SetPosition(left_column+15, 280, 0)
        self.title:SetTruncatedString(player_name, 200, 35, true)

        if data.playerage ~= nil then
            self.age = self.proot:AddChild(Text(BUTTONFONT, 25))
            self.age:SetPosition(left_column+12, 60, 0)
            self.age:SetColour(0, 0, 0, 1)
        end

        self.puppet = self.proot:AddChild(SkinsPuppet())
        self.puppet:SetPosition(left_column+10, 95)
        self.puppet:SetScale(1.8)

        self.shadow = self.proot:AddChild(Image("images/frontscreen.xml", "char_shadow.tex"))
        self.shadow:SetPosition(left_column+8, 90)
        self.shadow:SetScale(.35)

        local portrait_height = 170
        self.portrait = self.proot:AddChild(Image())
        self.portrait:SetScale(.37)
        self.portrait:SetPosition(right_column, portrait_height)

        if softresolvefilepath("images/names_"..character..".xml") then
            self.character_name = self.proot:AddChild(Image("images/names_"..character..".xml", character..".tex"))
            self.character_name:SetScale(.15)
            self.character_name:SetPosition(right_column + 5, portrait_height + 115)
        end

        local widget_height = 75
        local body_offset = 10
        local line_offset = body_offset + 37
        local line_scale = 1.05

        self.horizontal_line1 = self.proot:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
        self.horizontal_line1:SetScale(line_scale, .25)
        self.horizontal_line1:SetPosition(7, line_offset)

        self.vertical_line = self.proot:AddChild(Image("images/ui.xml", "line_vertical_5.tex"))
        self.vertical_line:SetScale(.5, .46)
        self.vertical_line:SetPosition(5, -105)

        self.body_image = self.proot:AddChild(self:CreateSkinWidgetForSlot())
        self.body_image:SetPosition(left_column, body_offset)
        self:UpdateSkinWidgetForSlot(self.body_image, "body", data.body_skin or "none")

        self.horizontal_line2 = self.proot:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
        self.horizontal_line2:SetScale(line_scale, .25)
        self.horizontal_line2:SetPosition(7, line_offset-widget_height)

        self.hand_image = self.proot:AddChild(self:CreateSkinWidgetForSlot())
        self.hand_image:SetPosition(left_column, body_offset-widget_height)
        self:UpdateSkinWidgetForSlot(self.hand_image, "hand", data.hand_skin or "none")

        self.horizontal_line3 = self.proot:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
        self.horizontal_line3:SetScale(line_scale, .25)
        self.horizontal_line3:SetPosition(7, line_offset-2*widget_height)

        self.legs_image = self.proot:AddChild(self:CreateSkinWidgetForSlot())
        self.legs_image:SetPosition(left_column, body_offset-2*widget_height)
        self:UpdateSkinWidgetForSlot(self.legs_image, "legs", data.legs_skin or "none")

        self.horizontal_line4 = self.proot:AddChild(Image("images/ui.xml", "line_horizontal_6.tex"))
        self.horizontal_line4:SetScale(line_scale, .25)
        self.horizontal_line4:SetPosition(7, line_offset-3*widget_height)

        self.feet_image = self.proot:AddChild(self:CreateSkinWidgetForSlot())
        self.feet_image:SetPosition(left_column, body_offset-3*widget_height)
        self:UpdateSkinWidgetForSlot(self.feet_image, "feet", data.feet_skin or "none")

        --[[if character == "unknownmod" then 
            self.heroportrait = self.proot:AddChild(Image("bigportraits/unknownmod.xml", "unknownmod.tex" ))
        else 
            self.heroportrait = self.proot:AddChild(Image("bigportraits/"..character..".xml", character.."_none.tex" )) -- TODO: get correct character skin here
        end
        self.heroportrait:SetPosition(right_column + 15, body_offset - 335)
        self.heroportrait:SetScale(.36)
        ]]

        local equip_offset = 10

        self.base_image = self.proot:AddChild(self:CreateSkinWidgetForSlot())
        self.base_image:SetPosition(right_column, equip_offset)
        self:UpdateSkinWidgetForSlot(self.base_image, "base", data.base_skin or character.."_none")

        self.head_equip_image = self.proot:AddChild(self:CreateEquipWidgetForSlot())
        self.head_equip_image:SetPosition(right_column, equip_offset-widget_height)
        self:UpdateEquipWidgetForSlot(self.head_equip_image, EQUIPSLOTS.HEAD, data.equip)

        self.hand_equip_image = self.proot:AddChild(self:CreateEquipWidgetForSlot())
        self.hand_equip_image:SetPosition(right_column, equip_offset-2*widget_height)
        self:UpdateEquipWidgetForSlot(self.hand_equip_image, EQUIPSLOTS.HANDS, data.equip)

        self.body_equip_image = self.proot:AddChild(self:CreateEquipWidgetForSlot())
        self.body_equip_image:SetPosition(right_column, equip_offset-3*widget_height)
        self:UpdateEquipWidgetForSlot(self.body_equip_image, EQUIPSLOTS.BODY, data.equip)

        if show_net_profile and TheNet:IsNetIDPlatformValid(data.netid) then
            self.netprofilebutton = self.proot:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "steam.tex", "", false, false, function() if data.netid ~= nil then TheNet:ViewNetProfile(data.netid) end end ))
            self.netprofilebutton:SetScale(.5)
            self.netprofilebutton:SetPosition(left_column-60,62,0)
        end
    else
        self.proot:SetPosition(10, 0)
        self.bg = self.proot:AddChild(TEMPLATES.CenterPanel(nil, nil, true))
        self.bg:SetScale(.3, .6)

        self.title = self.proot:AddChild(Text(TALKINGFONT, 30))
        self.title:SetPosition(0, 75, 0)
        self.title:SetTruncatedString(player_name, 200, 35, true)

        self.text = self.proot:AddChild(Text(UIFONT, 25, STRINGS.UI.PLAYER_AVATAR.CHOOSING))
        self.text:SetColour(unpack(data.colour))

        if show_net_profile and TheNet:IsNetIDPlatformValid(data.netid) then
            self.netprofilebutton = self.proot:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "steam.tex", "", false, false, function() if data.netid ~= nil then TheNet:ViewNetProfile(data.netid) end end ))
            self.netprofilebutton:SetScale(.5)
            self.netprofilebutton:SetPosition(0,-75,0)
        end
    end

    if not TheInput:ControllerAttached() then
        self.close_button = self.proot:AddChild(TEMPLATES.SmallButton(STRINGS.UI.PLAYER_AVATAR.CLOSE, 26, .5, function() self:Close() end))
        self.close_button:SetPosition(0, -269)
    end

    self:UpdateData(data)
end

function PlayerAvatarPopup:UpdateData(data)
    if self.title ~= nil then
        if data.colour ~= nil then
            self.title:SetColour(unpack(data.colour))
        else
            self.title:SetColour(1, 1, 1, 1)
        end
    end

    if self.age ~= nil and data.playerage ~= nil then
        self.age:SetString(STRINGS.UI.PLAYER_AVATAR.AGE_SURVIVED.." "..data.playerage.." "..(data.playerage == 1 and STRINGS.UI.PLAYER_AVATAR.AGE_DAY or STRINGS.UI.PLAYER_AVATAR.AGE_DAYS))
    end

    if self.puppet ~= nil then
        local build = self.currentcharacter == "unknownmod" and "mod_player_build" or self.currentcharacter
        local clothing =
        {
            body = data.body_skin,
            hand = data.hand_skin,
            legs = data.legs_skin,
            feet = data.feet_skin,
        }
        self.puppet:SetSkins(build, data.base_skin, clothing)
    end

    if self.portrait ~= nil then
        if data.base_skin ~= nil then
            if softresolvefilepath("bigportraits/"..data.base_skin..".xml") then
                self.portrait:SetTexture("bigportraits/"..data.base_skin..".xml", data.base_skin.."_oval.tex", self.currentcharacter.."_none.tex")
                self.portrait:SetPosition(94, 170)
            else
                -- Shouldn't actually be possible:
                self.portrait:SetTexture("bigportraits/"..self.currentcharacter..".xml", self.currentcharacter..".tex")
                self.portrait:SetPosition(94, 180)
            end
        elseif softresolvefilepath("bigportraits/"..self.currentcharacter.."_none.xml") then 
            self.portrait:SetTexture("bigportraits/"..self.currentcharacter.."_none.xml", self.currentcharacter.."_none_oval.tex")
            self.portrait:SetPosition(94, 170)
        else
            self.portrait:SetTexture("bigportraits/"..self.currentcharacter..".xml", self.currentcharacter..".tex")
            self.portrait:SetPosition(94, 180)
        end
    end

    if self.body_image ~= nil then
        self:UpdateSkinWidgetForSlot(self.body_image, "body", data.body_skin or "none")
    end
    if self.hand_image ~= nil then
        self:UpdateSkinWidgetForSlot(self.hand_image, "hand", data.hand_skin or "none")
    end
    if self.legs_image ~= nil then
        self:UpdateSkinWidgetForSlot(self.legs_image, "legs", data.legs_skin or "none")
    end
    if self.feet_image ~= nil then
        self:UpdateSkinWidgetForSlot(self.feet_image, "feet", data.feet_skin or "none")
    end
    if self.base_image ~= nil then
        self:UpdateSkinWidgetForSlot(self.base_image, "base", data.base_skin or self.currentcharacter.."_none")
    end

    if self.head_equip_image ~= nil then
        self:UpdateEquipWidgetForSlot(self.head_equip_image, EQUIPSLOTS.HEAD, data.equip)
    end
    if self.hand_equip_image ~= nil then
        self:UpdateEquipWidgetForSlot(self.hand_equip_image, EQUIPSLOTS.HANDS, data.equip)
    end
    if self.body_equip_image ~= nil then
        self:UpdateEquipWidgetForSlot(self.body_equip_image, EQUIPSLOTS.BODY, data.equip)
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
    elseif not self.started then
        return
    elseif self.time_to_refresh > dt then
        self.time_to_refresh = self.time_to_refresh - dt
    else
        self.time_to_refresh = REFRESH_INTERVAL
        local client_obj = TheNet:GetClientTableForUser(self.userid)
        if client_obj ~= nil then
            self:UpdateData(client_obj)
        end
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

local text_column = 42
local text_width = 100
function PlayerAvatarPopup:CreateSkinWidgetForSlot()
    local image_group = Widget("image_group")

    -- text background
    --local bg = image_group:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    --bg:SetSize(150, 28)
    --bg:SetPosition(0, 0, 0)

    image_group._text = image_group:AddChild(Text(NEWFONT_OUTLINE, 22))
    image_group._text:SetPosition(text_column, 0, 0)
    image_group._text:SetHAlign(ANCHOR_LEFT)
    image_group._text:SetVAlign(ANCHOR_MIDDLE)

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

    image_group._image = image_group:AddChild(UIAnim())
    image_group._image:GetAnimState():SetBuild("frames_comp")
    image_group._image:GetAnimState():SetBank("fr")
    image_group._image:GetAnimState():Hide("frame")
    image_group._image:GetAnimState():Hide("NEW")
    image_group._image:GetAnimState():PlayAnimation("icon", true)
    image_group._image:SetScale(.7)
    image_group._image:SetPosition(-50, 0)

    return image_group
end

function PlayerAvatarPopup:UpdateSkinWidgetForSlot(image_group, slot, name)
    local rarity = GetRarityForItem(slot, name)
    image_group._text:SetColour(unpack(SKIN_RARITY_COLORS[rarity]))

    local namestr = string.match(name, "_none") and "none" or name -- This version uses "Willow" for "willow_none": string.gsub(name, "_none", "")
    image_group._text:SetMultilineTruncatedString(GetName(namestr), 2, text_width, 25, true)

    local image_name = name
    image_name = string.gsub(image_name, "_none", "")
    if not image_name or image_name == "none" then
        if slot == "body" then
            image_name = "body_default1"
        elseif slot == "hand" then
            image_name = "hand_default1"
        elseif slot == "legs" then
            image_name = "legs_default1"
        elseif slot == "feet" then
            image_name = "feet_default1"
        else
            image_name = self.currentcharacter
        end
    end
    image_group._image:GetAnimState():OverrideSkinSymbol("SWAP_ICON", image_name, "SWAP_ICON")
end

local default_images =
{
    hands = "unknown_hand.tex",
    head = "unknown_head.tex",
    body = "unknown_body.tex",
}

function PlayerAvatarPopup:CreateEquipWidgetForSlot()
    local image_group = Widget("image_group")

    -- text background
    --local bg = image_group:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
    --bg:SetSize(150, 28)
    --bg:SetPosition(0, 0, 0)

    image_group._text = image_group:AddChild(Text(NEWFONT_OUTLINE, 24))
    image_group._text:SetPosition(text_column, 0, 0)
    image_group._text:SetHAlign(ANCHOR_LEFT)
    image_group._text:SetVAlign(ANCHOR_MIDDLE)

    image_group._image = image_group:AddChild(Image())
    image_group._image:SetScale(1)
    image_group._image:SetPosition(-50, 0)

    return image_group
end

function PlayerAvatarPopup:UpdateEquipWidgetForSlot(image_group, slot, equipdata)
    local name = equipdata ~= nil and equipdata[EQUIPSLOT_IDS[slot]] or nil
    name = name ~= nil and #name > 0 and name or "none"

    local rarity = GetRarityForItem("item", name)

    image_group._text:SetColour(unpack(SKIN_RARITY_COLORS[rarity]))
    image_group._text:SetMultilineTruncatedString(GetName(name), 2, text_width, 25, true)

    local atlas = "images/inventoryimages.xml"
    local default = default_images[slot] or "trinket_5.tex"
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
    else
		if softresolvefilepath("images/inventoryimages/"..name..".xml") ~= nil then
			atlas = "images/inventoryimages/"..name..".xml"
		end
    end
    image_group._image:SetTexture(atlas, name..".tex", default)		
end

return PlayerAvatarPopup
