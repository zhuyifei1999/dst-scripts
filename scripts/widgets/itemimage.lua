local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"

local image_scale = .6

local ItemImage = Class(Widget, function(self, screen, type, name, timestamp, clickFn, mouseonFn, mouseoffFn)
    Widget._ctor(self, "item-image")

    self.screen = screen
    self.type = type
    self.name = name
    self.clickFn = clickFn
    self.mouseonFn = mouseonFn
    self.mouseoffFn = mouseoffFn
   
    self.frame = self:AddChild(UIAnim())
    self.frame:GetAnimState():SetBuild("frames_comp") -- use the animation file as the build, then override it
    self.frame:GetAnimState():AddOverrideBuild("frame_skins") -- file name
    self.frame:GetAnimState():SetBank("fr") -- top level symbol from frames_comp

    self.new_tag = self.frame:AddChild(Text(BODYTEXTFONT, 20, STRINGS.UI.SKINSSCREEN.NEW))
    self.new_tag.inst.UITransform:SetRotation(43)
    self.new_tag:SetPosition(41, 34)
    self.new_tag:SetColour(WHITE)

    local collection_timestamp = self.screen.profile:GetCollectionTimestamp()
    --print(name, "Timestamp is ", timestamp, collection_timestamp)
   	if not timestamp or (timestamp > collection_timestamp) then 
    	self.frame:GetAnimState():PlayAnimation("idle_on", true)
    	self.new_tag:Show()
    else
    	self.frame:GetAnimState():PlayAnimation("icon", true)
    	self.new_tag:Hide()
    end
    self.frame:SetScale(image_scale)

    self.equipped = false

    self.equipped_marker = self.frame:AddChild(Image("images/ui.xml", "red_star.tex"))
    self.equipped_marker:SetPosition(-40, 35)
    self.equipped_marker:Hide()


    self:SetItem(type, name)

end)

function ItemImage:SetItem(type, name, timestamp)

	self.equipped_marker:Hide()

	-- Display an empty frame if there's no data
	if not type and not name then 
		self.frame:GetAnimState():ClearAllOverrideSymbols()
		self.type = nil
		self.name = nil
		self.rarity = "common"
		self.new_tag:Hide()

		-- Reset the stuff that just got cleared to an empty frame state
		self.frame:GetAnimState():SetBuild("frames_comp")
    	self.frame:GetAnimState():AddOverrideBuild("frame_skins") -- file name
		self.frame:GetAnimState():OverrideSymbol("SWAP_frameBG", "frame_BG", self.rarity)
		self.frame:GetAnimState():PlayAnimation("icon", true)
		return
	end

	if type ~= "" and type ~= "base" and name == "" then 
		name = type.."_default1"
	end

	self.type = type
	self.name = name

	self.rarity = GetRarityForItem( type, name )
	
	if type == "base" or type == "item" then 
		local skinsData = Prefabs[name]
		if skinsData and skinsData.ui_preview then 
			name = skinsData.ui_preview.build
		end
	end

	if self.frame and name ~= "" then 
		self.frame:GetAnimState():OverrideSkinSymbol("SWAP_ICON", name, "SWAP_ICON")
		self.frame:GetAnimState():OverrideSymbol("SWAP_frameBG", "frame_BG", self.rarity)
	end

	local collection_timestamp = self.screen.profile:GetCollectionTimestamp()
    --print(name, "Timestamp is ", timestamp, collection_timestamp)
   	if timestamp and (timestamp > collection_timestamp) then 
    	self.frame:GetAnimState():PlayAnimation("idle_on", true)
    	self.new_tag:Show()
    else
    	self.frame:GetAnimState():PlayAnimation("icon", true)
    	self.new_tag:Hide()
    end

	--[[if self.screen.profile:IsSkinEquipped(name, type) then 
		self.equipped_marker:Show()
	end]]

end

function ItemImage:OnGainFocus()
	self._base:OnGainFocus()

	if self.frame then 
		self:Embiggen()
	end

	if self.mouseonFn then 
		self.mouseonFn(self.type, self.name)
	end

	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
	--print(self.name, "got focus")
end

function ItemImage:OnLoseFocus()
	self._base:OnLoseFocus()

	if self.frame and not self.clicked then 
		self:Shrink()
	end

	if self.mouseoffFn then 
		self.mouseoffFn(self.type, self.name)
	end

	--print(self.name, "lost focus")
end


function ItemImage:Embiggen()
	self.frame:SetScale(image_scale * 1.2)
end

function ItemImage:Shrink()
	self.frame:SetScale(image_scale)
end

-- Toggle clicked/unclicked
function ItemImage:OnControl(control, down)
  
    -- print(self.name, "Got control", control, down, self.clicked)
    if control == CONTROL_ACCEPT then
        if not self.clicked then

        	if down and self.name then 
        		self.screen:ClearFocus()
        		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        		self:Select()
        	end

           	if self.clickFn then 
           		self.clickFn(self.type, self.name) 
           	end
       
        end
        return true
    end
end

function ItemImage:Select()
	self:Embiggen()
	self.clicked = true
end

function ItemImage:Unselect()
	--print(self.name, "unselect")
	self:Shrink()
    self.clicked = false
end

return ItemImage

