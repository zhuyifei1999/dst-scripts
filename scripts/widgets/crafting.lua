local TileBG = require "widgets/tilebg"
local InventorySlot = require "widgets/invslot"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TabGroup = require "widgets/tabgroup"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local CraftSlots = require "widgets/craftslots"

require "widgets/widgetutil"

local Crafting = Class(Widget, function(self, owner, num_slots)
    Widget._ctor(self, "Crafting")
    
	self.owner = owner

    self.bg = self:AddChild(TileBG(HUD_ATLAS, "craft_slotbg.tex"))

    --slots
    self.num_slots = num_slots
    self.craftslots = CraftSlots(num_slots, owner)
    self:AddChild(self.craftslots)

    --buttons
    self.downbutton = self:AddChild(ImageButton(HUD_ATLAS, "craft_end_normal.tex", "craft_end_normal_mouseover.tex", "craft_end_normal_disabled.tex"))
    self.upbutton = self:AddChild(ImageButton(HUD_ATLAS, "craft_end_normal.tex", "craft_end_normal_mouseover.tex", "craft_end_normal_disabled.tex"))
    self.downbutton:SetOnClick(function() self:ScrollDown() end)
    self.upbutton:SetOnClick(function() self:ScrollUp() end)

	-- start slightly scrolled down
    self.idx = -1
    self.scrolldir = true

    self:UpdateRecipes()
end)

function Crafting:SetOrientation(horizontal)
    self.horizontal = horizontal
    self.bg.horizontal = horizontal
    if horizontal then
        self.bg.sepim = "craft_sep_h.tex"
    else
        self.bg.sepim = "craft_sep.tex"
    end

    self.bg:SetNumTiles(self.num_slots)
    local slot_w, slot_h = self.bg:GetSlotSize()
    local w, h = self.bg:GetSize()
    
    for k = 1, #self.craftslots.slots do
        local slotpos = self.bg:GetSlotPos(k)
        self.craftslots.slots[k]:SetPosition( slotpos.x,slotpos.y,slotpos.z )
    end

    local but_w, but_h = self.downbutton:GetSize()

    if horizontal then
        self.downbutton:SetRotation(90)
        self.downbutton:SetPosition(-self.bg.length/2 - but_w/2 + slot_w/2,0,0)
        self.upbutton:SetRotation(-90)
        self.upbutton:SetPosition(self.bg.length/2 + but_w/2 - slot_w/2,0,0)
    else
        self.upbutton:SetPosition(0, - self.bg.length/2 - but_h/2 + slot_h/2,0)
        self.downbutton:SetScale(Vector3(1, -1, 1))
        self.downbutton:SetPosition(0, self.bg.length/2 + but_h/2 - slot_h/2,0)
    end
end

function Crafting:SetFilter(filter)
    local new_filter = filter ~= self.filter
    self.filter = filter
    
    if new_filter then 
        self:UpdateRecipes()
    end
end

function Crafting:Close(fn)
    self.open = false
    self:Disable() 
    self.craftslots:CloseAll()
    self:MoveTo(self.in_pos, self.out_pos, .33, function() self:Hide() if fn then fn() end end)
end

function Crafting:Open(fn)
	self.open = true
	self:Enable() 
    self:MoveTo(self.out_pos, self.in_pos, .33, fn)
    self:Show() 
end

local function SortByKey(a, b)
    return a.sortkey < b.sortkey
end

function Crafting:UpdateRecipes()
    self.craftslots:Clear()
    if self.owner ~= nil and self.owner.replica.builder ~= nil then

        self.valid_recipes = {}

        for k, v in pairs(AllRecipes) do
            if IsRecipeValid(v.name) and
                (self.filter == nil or self.filter(v.name)) and
                (self.owner.replica.builder:KnowsRecipe(v.name) or ShouldHintRecipe(v.level, self.owner.replica.builder:GetTechTrees())) then
                table.insert(self.valid_recipes, v)
            end
        end
        table.sort(self.valid_recipes, SortByKey)

        local shown_num = 0

        local num = math.min(self.num_slots, #self.valid_recipes)

		if self.idx > #self.valid_recipes - (self.num_slots - 1) then
			self.idx = #self.valid_recipes - (self.num_slots - 1)
		end 

        if self.idx < -1 then
            self.idx = -1
        end

        for k = 1, num + 1 do
            local slot = self.craftslots.slots[k]
            if slot ~= nil then
                local recipe = self.valid_recipes[self.idx + k]
                if recipe ~= nil and (self.filter == nil or self.filter(recipe.name)) then
                    slot:SetRecipe(recipe.name)
                    shown_num = shown_num + 1
                end
            end
        end

        if self.idx >= 0 then
        	self.downbutton:Enable()
        else
        	self.downbutton:Disable()
        end

        if #self.valid_recipes < self.idx + self.num_slots then  
        	self.upbutton:Disable()
        else
        	self.upbutton:Enable()
        end
    end
end

function Crafting:ScrollUp()
	if not IsPaused() then
        self.idx = self.idx + 1
		self:UpdateRecipes()
		
		TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/craft_up")
	end
end

function Crafting:ScrollDown()
	if not IsPaused() then
		self.idx = self.idx - 1
		self:UpdateRecipes()
		TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/craft_down")
	end
end

return Crafting
