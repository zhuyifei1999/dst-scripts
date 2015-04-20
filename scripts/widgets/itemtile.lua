require("constants")
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

local ItemTile = Class(Widget, function(self, invitem)
    Widget._ctor(self, "ItemTile")
    self.item = invitem

    --These flags are used by the client to control animation behaviour while
    --stacksize is being tampered with locally to preview inventory actions so
    --that when the next server sync is received, you won't see a double pop
    --on the item tile scaling
    self.isactivetile = false
    self.ispreviewing = false
    self.ismoving = false
    self.ignore_stacksize_anim = nil

	-- NOT SURE WAHT YOU WANT HERE
	if invitem.replica.inventoryitem == nil then
		print("NO INVENTORY ITEM COMPONENT"..tostring(invitem.prefab), invitem)
		return
	end
	
	self.bg = self:AddChild(Image())
	self.bg:SetTexture(HUD_ATLAS, "inv_slot_spoiled.tex")
	self.bg:Hide()
	self.bg:SetClickable(false)
	self.basescale = 1
	
	self.spoilage = self:AddChild(UIAnim())
    self.spoilage:GetAnimState():SetBank("spoiled_meter")
    self.spoilage:GetAnimState():SetBuild("spoiled_meter")
    self.spoilage:Hide()
    self.spoilage:SetClickable(false)

    self.wetness = self:AddChild(UIAnim())
    self.wetness:GetAnimState():SetBank("wet_meter")
    self.wetness:GetAnimState():SetBuild("wet_meter")
    self.wetness:GetAnimState():PlayAnimation("idle")
    self.wetness:Hide()
    self.wetness:SetClickable(false)

    self.image = self:AddChild(Image(invitem.replica.inventoryitem:GetAtlas(), invitem.replica.inventoryitem:GetImage()))
    --self.image:SetClickable(false)

    if self.item.prefab == "spoiled_food" or self:HasSpoilage() then
		self.bg:Show( )
	end
	
	if self:HasSpoilage() then
		self.spoilage:Show()
	end

    if self.item:GetIsWet() then
        self.wetness:Show()
    end

    self.inst:ListenForEvent("imagechange", function(invitem) 
        self.image:SetTexture(invitem.replica.inventoryitem:GetAtlas(), invitem.replica.inventoryitem:GetImage())
    end, invitem)

    self.inst:ListenForEvent("stacksizechange",
            function(invitem, data)
                if invitem.replica.stackable ~= nil then
                    if self.ignore_stacksize_anim then
                        self:SetQuantity(data.stacksize)
					elseif data.src_pos ~= nil then
						local dest_pos = self:GetWorldPosition()
						local im = Image(invitem.replica.inventoryitem:GetAtlas(), invitem.replica.inventoryitem:GetImage())
						im:MoveTo(Vector3(TheSim:GetScreenPos(data.src_pos:Get())), dest_pos, .3, function()
                            self.ismoving = false
							self:SetQuantity(data.stacksize)
							self:ScaleTo(self.basescale * 2, self.basescale, .25)
							im:Kill()
                        end)
                        self.ismoving = true
                    elseif not self.ispreviewing then
                        self:SetQuantity(data.stacksize)
                        self:ScaleTo(self.basescale * 2, self.basescale, .25)
					end
                end
            end, invitem)

    self.inst:ListenForEvent("percentusedchange",
            function(invitem, data)
                self:SetPercent(data.percent)
            end, invitem)

    self.inst:ListenForEvent("perishchange",
            function(invitem, data)
                if self:HasSpoilage() then
                    self:SetPerishPercent(data.percent)
				elseif invitem:HasTag("fresh") or invitem:HasTag("stale") or invitem:HasTag("spoiled") then
                    self:SetPercent(data.percent)
				end
            end, invitem)

    if not TheWorld.ismastersim then
        self.inst:ListenForEvent("stacksizepreview",
            function(invitem, data)
                if data.activecontainer ~= nil and
                    self.parent ~= nil and
                    self.parent.container ~= nil and
                    self.parent.container.inst == data.activecontainer and
                    data.activestacksize ~= nil then
                    self:SetQuantity(data.activestacksize)
                    if data.animateactivestacksize then
                        self:ScaleTo(self.basescale * 2, self.basescale, .25)
                    end
                    self.ispreviewing = true
                elseif self.isactivetile and
                    data.activecontainer == nil and
                    data.activestacksize ~= nil then
                    self:SetQuantity(data.activestacksize)
                    if data.animateactivestacksize then
                        self:ScaleTo(self.basescale * 2, self.basescale, .25)
                    end
                    self.ispreviewing = true
                elseif data.stacksize ~= nil then
                    self:SetQuantity(data.stacksize)
                    if data.animatestacksize then
                        self:ScaleTo(self.basescale * 2, self.basescale, .25)
                    end
                    self.ispreviewing = true
                end
            end, invitem)
    end

    self.inst:ListenForEvent("wetnesschange", function(sender, wet)
        if wet then
            if ThePlayer.replica.inventory:GetActiveItem() ~= invitem then
                self.wetness:Show()
            end
        else
            self.wetness:Hide()
        end
    end, invitem)

    self:Refresh()
end)

function ItemTile:Refresh()
    self.ispreviewing = false
    self.ignore_stacksize_anim = nil

    if not self.ismoving and self.item.replica.stackable ~= nil then
        self:SetQuantity(self.item.replica.stackable:StackSize())
    end

    if not TheWorld.ismastersim and self.item.replica.inventoryitem ~= nil then
        self.item.replica.inventoryitem:DeserializeUsage()
    end

    if self.item.components.fueled ~= nil then
        self:SetPercent(self.item.components.fueled:GetPercent())
    end

    if self.item.components.finiteuses ~= nil then
        self:SetPercent(self.item.components.finiteuses:GetPercent())
    end

    if self.item.components.perishable ~= nil then
        if self:HasSpoilage() then
            self:SetPerishPercent(self.item.components.perishable:GetPercent())
        else
            self:SetPercent(self.item.components.perishable:GetPercent())
        end
    end
    
    if self.item.components.armor ~= nil then
        self:SetPercent(self.item.components.armor:GetPercent())
    end
end

function ItemTile:SetBaseScale(sc)
	self.basescale = sc
	self:SetScale(sc)
end

function ItemTile:OnControl(control, down)
    self:UpdateTooltip()
    return false
end

function ItemTile:UpdateTooltip()
	local str = self:GetDescriptionString()
	self:SetTooltip(str)
    if self.item:GetIsWet() then
        self:SetTooltipColour(unpack(WET_TEXT_COLOUR))
    else
        self:SetTooltipColour(unpack(NORMAL_TEXT_COLOUR))
    end
end

function ItemTile:GetDescriptionString()
    local str = ""
    if self.item ~= nil and self.item:IsValid() and self.item.replica.inventoryitem ~= nil then
        local adjective = self.item:GetAdjective()
        if adjective ~= nil then
            str = adjective.." "
        end
        str = str..self.item:GetDisplayName()

        local player = ThePlayer
        local actionpicker = player.components.playeractionpicker
        local active_item = player.replica.inventory:GetActiveItem()
        if active_item == nil then
            if not (self.item.replica.equippable ~= nil and self.item.replica.equippable:IsEquipped()) then
                --self.namedisp:SetHAlign(ANCHOR_LEFT)
                if TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) then
                    str = str.."\n"..STRINGS.LMB..": "..STRINGS.INSPECTMOD
                elseif TheInput:IsControlPressed(CONTROL_FORCE_TRADE) then
                    if next(player.replica.inventory:GetOpenContainers()) ~= nil then
                        str = str.."\n"..STRINGS.LMB..": "..((TheInput:IsControlPressed(CONTROL_FORCE_STACK) and self.item.replica.stackable ~= nil) and (STRINGS.STACKMOD.." "..STRINGS.TRADEMOD) or STRINGS.TRADEMOD)
                    end
                elseif TheInput:IsControlPressed(CONTROL_FORCE_STACK) and self.item.replica.stackable ~= nil then
                    str = str.."\n"..STRINGS.LMB..": "..STRINGS.STACKMOD
                end
            end

            local actions = actionpicker:GetInventoryActions(self.item)
            if #actions > 0 then
                str = str.."\n"..STRINGS.RMB..": "..actions[1]:GetActionString()
            end
        elseif active_item:IsValid() then
            if not (self.item.replica.equippable ~= nil and self.item.replica.equippable:IsEquipped()) then
                if active_item.replica.stackable ~= nil and active_item.prefab == self.item.prefab then
                    str = str.."\n"..STRINGS.LMB..": "..STRINGS.UI.HUD.PUT
                else
                    str = str.."\n"..STRINGS.LMB..": "..STRINGS.UI.HUD.SWAP
                end
            end

            local actions = actionpicker:GetUseItemActions(self.item, active_item, true)
            if #actions > 0 then
                str = str.."\n"..STRINGS.RMB..": "..actions[1]:GetActionString()
            end
        end
    end
    return str
end

function ItemTile:OnGainFocus()
    self:UpdateTooltip()
end

function ItemTile:SetQuantity(quantity)
    if not self.quantity then
        self.quantity = self:AddChild(Text(NUMBERFONT, 42))
        self.quantity:SetPosition(2,16,0)
    end
    self.quantity:SetString(tostring(quantity))
end

function ItemTile:SetPerishPercent(percent)
    self.spoilage:GetAnimState():SetPercent("anim", 1 - percent)
end

function ItemTile:SetPercent(percent)
    --if self.item.replica.stackable == nil then
        
    if not self.percent then
        self.percent = self:AddChild(Text(NUMBERFONT, 42))
        if JapaneseOnPS4() then
            self.percent:SetHorizontalSqueeze(0.7)
        end
        self.percent:SetPosition(5,-32+15,0)
    end
    local val_to_show = percent*100
    if val_to_show > 0 and val_to_show < 1 then
        val_to_show = 1
    end
	self.percent:SetString(string.format("%2.0f%%", val_to_show))
        
    --end
end

--[[
function ItemTile:CancelDrag()
    self:StopFollowMouse()
    
    if self.item.prefab == "spoiled_food" or (self.item.components.edible and self.item.components.perishable) then
		self.bg:Show( )
	end
	
	if self.item.components.perishable and self.item.components.edible then
		self.spoilage:Show()
	end
	
	self.image:SetClickable(true)

    
end
--]]

function ItemTile:StartDrag()
    --self:SetScale(1,1,1)
	if self.item.replica.inventoryitem ~= nil then -- HACK HACK: items without an inventory component won't have any of these
	    self.spoilage:Hide()
        self.wetness:Hide()
	    self.bg:Hide( )
	    self.image:SetClickable(false)
	end
end

function ItemTile:HasSpoilage()
    if self.item:HasTag("fresh") or self.item:HasTag("stale") or self.item:HasTag("spoiled") then
        if self.item:HasTag("show_spoilage") then
            return true
        end
        for k, v in pairs(FOODTYPE) do
            if self.item:HasTag("edible_"..v) then
                return true
            end
        end
    end
    return false
end

return ItemTile
