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
    self.max_slots = num_slots
    self.current_slots = num_slots
    self.craftslots = CraftSlots(num_slots, owner)
    self:AddChild(self.craftslots)

    --buttons
    self.downbutton = self:AddChild(ImageButton(HUD_ATLAS, "craft_end_normal.tex", "craft_end_normal_mouseover.tex", "craft_end_normal_disabled.tex", nil, nil, {1,1}, {0,0}))
    self.upbutton = self:AddChild(ImageButton(HUD_ATLAS, "craft_end_normal.tex", "craft_end_normal_mouseover.tex", "craft_end_normal_disabled.tex", nil, nil, {1,1}, {0,0}))
    local but_w, but_h = self.downbutton:GetSize()
    self.but_w = but_w
    self.but_h = but_h
    self.downbutton.scale_on_focus = false
    self.upbutton.scale_on_focus = false
    self.downbutton:SetOnClick(function() self:ScrollDown() end)
    self.upbutton:SetOnClick(function() self:ScrollUp() end)

    self.downconnector = self:AddChild(Image(HUD_ATLAS, "craft_sep_h.tex"))
    self.upconnector = self:AddChild(Image(HUD_ATLAS, "craft_sep_h.tex"))

    self.downendcapbg = self:AddChild(Image(HUD_ATLAS, "craft_sep.tex"))
    self.upendcapbg = self:AddChild(Image(HUD_ATLAS, "craft_sep.tex"))

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

    self.bg:SetNumTiles(self.current_slots)
    local slot_w, slot_h = self.bg:GetSlotSize()
    local w, h = self.bg:GetSize()
    
    for k = 1, #self.craftslots.slots do
        local slotpos = self.bg:GetSlotPos(k)
        self.craftslots.slots[k]:SetPosition( slotpos.x,slotpos.y,slotpos.z )
    end

    if horizontal then
        self.downbutton:SetRotation(90)
        self.upbutton:SetRotation(-90)

        self.downbutton:SetPosition(-self.bg.length/2 - self.but_w/2 + slot_w/2,0,0)
        self.upbutton:SetPosition(self.bg.length/2 + self.but_w/2 - slot_w/2,0,0)

        self.downconnector:Hide()
        self.upconnector:Hide()
        self.downendcapbg:Hide()
        self.upendcapbg:Hide()
    else
        self.downbutton:SetScale(Vector3(1, -1, 1))
        if self.valid_recipes and #self.valid_recipes <= self.max_slots then
            self.downbutton:SetPosition(0, self.bg.length/2 + self.but_h/1.35 - slot_h/2 - 23,0)
            self.upbutton:SetPosition(0, -self.bg.length/2 - self.but_h/1.35 + slot_h/2 + 23,0)

            self.downconnector:SetPosition(-68, self.bg.length/2 + self.but_h/1.5 - slot_h/2 - 23,0)
            self.upconnector:SetPosition(-68, -self.bg.length/2 - self.but_h/1.5 + slot_h/2 + 23,0)
            
            self.downendcapbg:SetPosition(0, self.bg.length/2 + self.but_h/2 - slot_h/2 - 23)
            self.upendcapbg:SetPosition(0, -self.bg.length/2 - self.but_h/2 + slot_h/2 + 23)

            self.downendcapbg:Show()
            self.upendcapbg:Show()
        else
            self.downbutton:SetPosition(0, self.bg.length/2 + self.but_h/2 - slot_h/2,0)
            self.upbutton:SetPosition(0, - self.bg.length/2 - self.but_h/2 + slot_h/2,0)

            self.downconnector:SetPosition(-68, self.bg.length/2 + self.but_h/2 - slot_h/2 - 23,0)
            self.upconnector:SetPosition(-68, - self.bg.length/2 - self.but_h/2 + slot_h/2 + 23,0)
            
            self.downendcapbg:Hide()
            self.upendcapbg:Hide()
        end
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

function Crafting:Resize(num_recipes)
    if self.num_recipes ~= num_recipes then
        self.num_recipes = num_recipes
        self.current_slots = math.min(num_recipes, self.max_slots)
        self.craftslots:SetNumSlots(self.current_slots)
        self:SetOrientation(false)
    end

    if #self.valid_recipes <= self.max_slots then
        self.downbutton:SetTextures(HUD_ATLAS, "craft_end_short.tex", "craft_end_short.tex", "craft_end_short.tex", nil, nil, {1,1}, {0,0})-- self.downbutton:Hide()
        self.upbutton:SetTextures(HUD_ATLAS, "craft_end_short.tex", "craft_end_short.tex", "craft_end_short.tex", nil, nil, {1,1}, {0,0})-- self.upbutton:Hide()

        self.downbutton.o_pos = nil
        self.upbutton.o_pos = nil

        self.upconnector:SetScale(1.7,.7)
        self.downconnector:SetScale(1.7,.7)
    else
        self.downbutton:SetTextures(HUD_ATLAS, "craft_end_normal.tex", "craft_end_normal_mouseover.tex", "craft_end_normal_disabled.tex", nil, nil, {1,1}, {0,0})-- self.downbutton:Show()
        self.upbutton:SetTextures(HUD_ATLAS, "craft_end_normal.tex", "craft_end_normal_mouseover.tex", "craft_end_normal_disabled.tex", nil, nil, {1,1}, {0,0})-- self.upbutton:Show()

        self.upconnector:SetScale(1,1)
        self.downconnector:SetScale(1,1)
    end
end

function Crafting:UpdateIdx()
    self.use_idx = #self.valid_recipes > self.max_slots
end

function Crafting:UpdateRecipes()

    if self.owner ~= nil and self.owner.replica.builder ~= nil then

        self.valid_recipes = {}

        for k,v in pairs(AllRecipes) do
            if IsRecipeValid(v.name)
            and (self.filter == nil or self.filter(v.name)) --Has no filter or passes the filter in place
            and (self.owner.replica.builder:KnowsRecipe(v.name) --[[Knows the recipe]] or ShouldHintRecipe(v.level, self.owner.replica.builder:GetTechTrees())) --[[ Knows enough to see it]] then
                table.insert(self.valid_recipes, v)
            end
        end
        table.sort(self.valid_recipes, SortByKey)

        local shown_num = 0 --Number of recipes shown

        local num = math.min(self.max_slots, #self.valid_recipes) --How many recipe slots we're going to need

        self:Resize(num)
        self.craftslots:Clear()

        local default_idx = -1 --By default, the recipe starts in the top slot.

        self:UpdateIdx()

        self.idx = math.clamp(self.idx, default_idx, #self.valid_recipes - (self.max_slots - 1)) --Make sure our idx is in range

        for i = 1, num + 1 do --For each visible slot assign a recipe
            local slot = self.craftslots.slots[i]
            if slot ~= nil then
                local recipe = self.valid_recipes[((self.use_idx and self.idx) or 0) + i]
                if recipe then
                    slot:SetRecipe(recipe.name)
                    shown_num = shown_num + 1
                end
            end
        end

        -- #### It should be noted that downbutton goes "up" and up button goes "down"! ####

        if self.idx >= 0 and #self.valid_recipes > self.max_slots then
            self.downbutton:Enable()
        else
            self.downbutton:Disable()
        end

        if #self.valid_recipes < self.idx + self.current_slots or #self.valid_recipes <= self.max_slots then  
            self.upbutton:Disable()
        else
            self.upbutton:Enable()
        end


    end
end

function Crafting:OnControl(control, down)
    if Crafting._base.OnControl(self, control, down) then return true end

    if down and self.focus then
        if control == CONTROL_SCROLLBACK then
            self:ScrollDown()
            return true
        elseif control == CONTROL_SCROLLFWD then
            self:ScrollUp()
            return true
        end
    end
end

function Crafting:ScrollUp()
    if not IsPaused() then
        local oldidx = self.idx
        self.idx = self.idx + 1
        self:UpdateRecipes()
        if self.idx ~= oldidx then
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/craft_up")
        end
    end
end

function Crafting:ScrollDown()
    if not IsPaused() then
        local oldidx = self.idx
        self.idx = self.idx - 1
        self:UpdateRecipes()
        if self.idx ~= oldidx then
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/craft_down")
        end
    end
end

return Crafting
