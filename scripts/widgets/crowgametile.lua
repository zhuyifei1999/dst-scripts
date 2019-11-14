local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"

local image_scale = .6

local CrowGameTile = Class(Widget, function(self, screen, index, mover)
    Widget._ctor(self, "CrowGameTile")

    self.screen = screen
    self.index = index
	self.exploded = false

    self.tile = self:AddChild(UIAnim())
    self.tile:GetAnimState():SetBuild("crowgametile")
    self.tile:GetAnimState():SetBank("crowgametile")
	self.tile:GetAnimState():PlayAnimation("icon", true)
	if mover then
		self.tile:GetAnimState():Hide("frame")
		self.tile:Disable()
	end
	
    self.tile:SetScale(image_scale)
    
    self:ClearTile()
end)

function CrowGameTile:ClearTile()
	self.tile_type = ""
	self.tile:GetAnimState():ClearAllOverrideSymbols()
end

function CrowGameTile:SetTileTypeUnHidden(tile_type)
	self.tile_type = tile_type
	self:UnhideTileType()
end

function CrowGameTile:SetTileTypeHidden(tile_type)
	self.tile_type = tile_type
	self.tile:GetAnimState():ClearAllOverrideSymbols()
end

function CrowGameTile:UnhideTileType()
	self.tile:GetAnimState():OverrideSkinSymbol("SWAP_ICON", self.tile_type, "SWAP_ICON")
end

function CrowGameTile:OnGainFocus()
	self._base:OnGainFocus()

	if self.tile and self:IsEnabled() then 
		self:Embiggen()
		self.tile:GetAnimState():PlayAnimation("hover", true)
	end
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
end

function CrowGameTile:OnLoseFocus()
	self._base:OnLoseFocus()

	if self.tile and not self.clicked then 
		self:Shrink()
	end

	self.tile:GetAnimState():PlayAnimation("icon", true)
end

function CrowGameTile:OnEnable()
	self._base.OnEnable(self)
    if self.focus then
        self:OnGainFocus()
    else
        self:OnLoseFocus()
    end
end

function CrowGameTile:OnDisable()
	self._base.OnDisable(self)
	self:OnLoseFocus()
end


function CrowGameTile:Embiggen()
	self.tile:SetScale(image_scale * 1.10)
end

function CrowGameTile:Shrink()
	self.tile:SetScale(image_scale)
end

-- Toggle clicked/unclicked
function CrowGameTile:OnControl(control, down)
	if control == CONTROL_ACCEPT then
        if not self.clicked then
			if self:IsEnabled() then
        		if not down then
        			if self.clickFn then
		       			self.clickFn(self.index) 
		       		end
        		end
        		
				return true
			end
        end
	end
end

function CrowGameTile:Select()
	self:Embiggen()
	self.clicked = true
end

function CrowGameTile:Unselect()
	self:Shrink()
    self.clicked = false
end

return CrowGameTile

