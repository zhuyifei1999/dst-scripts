local Grid = require "widgets/grid"
local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"
local NineSlice = require "widgets/nineslice"
local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

require "skinsutils"

local columns = 3
local bg_frame_w = 675
local bg_frame_h_offset = -30
local bg_frame_initial_y = 220
local COLUMN_WIDTH = 250
local COLUMN_HEIGHT = 70

local ANIM_TIMING = {
    open      = { pause_for_server = (139-110) * FRAMES },
    skin_next = { icon_hidden      = (255-234) * FRAMES },
}

local RARITY_SOUND = {
    Common          = "dontstarve/HUD/Together_HUD/collectionscreen/music/1_lootbox_common",
    Classy          = "dontstarve/HUD/Together_HUD/collectionscreen/music/2_lootbox_classy",
    Spiffy          = "dontstarve/HUD/Together_HUD/collectionscreen/music/3_lootbox_spiffy",
    Distinguished   = "dontstarve/HUD/Together_HUD/collectionscreen/music/4_lootbox_distinguished",
    Elegant         = "dontstarve/HUD/Together_HUD/collectionscreen/music/5_lootbox_elegant",
}


local TRANSITION_DURATION = 0.3

--possible states for self.ui_state
--[[
INTRO
PENDING_OPEN
WAIT_ON_ITEMS
BUNDLE_OPENING
WAIT_ON_NEXT
BUNDLE_CLOSING
OUTRO
]]

local PP_ON_TINT = {r=.6,g=.6,b=.6,a=1}
local PP_OFF_TINT = {r=1,g=1,b=1,a=0}

local ItemBoxOpenerPopup = Class(Screen, function(self, parent_screen, options, open_box_fn)
    Screen._ctor(self, "ItemBoxOpenerPopup")
	
	self.parent_screen = parent_screen
    self.allow_cancel = options.allow_cancel
    self.use_bigportraits = options.use_bigportraits
    self.open_box_fn = open_box_fn

    self.center_root = self:AddChild(TEMPLATES.ScreenRoot())
    self.fg = self:AddChild(TEMPLATES.ReduxForeground())
    
    self.bg = self.center_root:AddChild(TEMPLATES.PlainBackground()) -- match MysteryBoxScreen so it looks like a fade
	self.bg.bgplate.image:SetTint(1,1,1,0)--maybe we should move this into TintTo
	self.bg.bgplate.image:TintTo(PP_OFF_TINT, PP_ON_TINT, TRANSITION_DURATION, nil)
	
    self.proot = self.center_root:AddChild(Widget("ROOT_P"))
    self.proot:SetPosition( 0, -100, 0 )

    self.bundle_root = self.proot:AddChild(Widget("bundle_root"))
        
    -- Add fancy nineslice
    --self.frame = self.bundle_root:AddChild(Image("images/frontend_redux.xml", "shop_panel.tex"))
    self.frame = self.bundle_root:AddChild(NineSlice("images/dialogcurly_9slice.xml"))
    local top = self.frame:AddCrown("crown-top-fg.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 68)
    local top_bg = self.frame:AddCrown("crown-top.tex", ANCHOR_MIDDLE, ANCHOR_TOP, 0, 44)
    top_bg:MoveToBack()
    -- Background overlaps behind and foreground overlaps in front.
    local bottom = self.frame:AddCrown("crown-bottom-fg.tex", ANCHOR_MIDDLE, ANCHOR_BOTTOM, 0, -14)
    bottom:MoveToFront()
    self.frame:SetSize(bg_frame_w,400+bg_frame_h_offset)
    self.frame:SetScale(0.7, 0.7)
    self.frame:SetPosition(0,bg_frame_initial_y)
    self.frame:Hide()

    self.opened_item_display = self.bundle_root:AddChild(Grid())
    self.opened_item_display:SetPosition(-320,210)
    self.opened_item_display:Hide()

    local summary_width = 360
    self.current_item_summary = self.bundle_root:AddChild(self:_BuildItemSummary(summary_width))
    self.current_item_summary:SetPosition(420,0)

    -- Actual animation
    self.bundle = self.bundle_root:AddChild(UIAnim())
    self.bundle:SetScale(.7)
    self.bundle:SetPosition(0, 83)
    local box_build = options.box_build or "skinevent_popup"
    self.bundle:GetAnimState():SetBuild(box_build) -- file name
    self.bundle:GetAnimState():SetBank(box_build) -- top level symbol

    if self.allow_cancel and not TheInput:ControllerAttached() then
        self.back_button = self.center_root:AddChild(TEMPLATES.BackButton(
                function() self:_TryClose() end
            ))
    end


    self.items = nil
    self.active_item_idx = 1
    
    self:AddChild(TEMPLATES.ReduxForeground())
    
    self.ui_state = "INTRO"
    self.inst:DoTaskInTime(.35, function()
		self.bundle:GetAnimState():PlayAnimation("activate")
		self.bundle:GetAnimState():PushAnimation("idle", true)

        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/mysterybox/intro")
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/mysterybox/LP","mysteryboxactive")
        self.inst:DoTaskInTime(0.5, function() TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/mysterybox/hit1") end )
    end)
end)

function ItemBoxOpenerPopup:_BuildItemSummary(summary_width)
    local current_item_summary = self:AddChild(Widget("current_item_summary"))

    current_item_summary.item_title = current_item_summary:AddChild(Text(HEADERFONT, 25))
    current_item_summary.item_title:SetColour(UICOLOURS.GOLD_SELECTED)
    current_item_summary.item_title:SetHAlign(ANCHOR_LEFT)

    current_item_summary.item_rarity = current_item_summary:AddChild(Text(HEADERFONT, 20))
    current_item_summary.item_rarity:SetPosition(0,-25)
    current_item_summary.item_rarity:SetColour(UICOLOURS.HIGHLIGHT_GOLD)
    current_item_summary.item_rarity:SetHAlign(ANCHOR_LEFT)

	current_item_summary.set_title = current_item_summary:AddChild(Text(HEADERFONT, 20))
    current_item_summary.set_title:SetPosition(0,-25)
    current_item_summary.set_title:SetColour(UICOLOURS.HIGHLIGHT_GOLD)
    current_item_summary.set_title:SetHAlign(ANCHOR_RIGHT)

    current_item_summary.description = current_item_summary:AddChild(Text(CHATFONT, 20))
    current_item_summary.description:SetPosition(0,-105)
    current_item_summary.description:SetColour(UICOLOURS.WHITE)
    current_item_summary.description:SetHAlign(ANCHOR_LEFT)
    current_item_summary.description:SetVAlign(ANCHOR_TOP)
    current_item_summary.description:EnableWordWrap(true)


    current_item_summary.item_title:SetRegionSize(summary_width, 40)
    current_item_summary.item_rarity:SetRegionSize(summary_width, 30)
    current_item_summary.set_title:SetRegionSize(summary_width, 30)
    current_item_summary.description:SetRegionSize(summary_width, 130)

    current_item_summary.UpdateSummary = function(_, item_key)
        current_item_summary.item_title:SetString(GetSkinName(item_key))
        current_item_summary.item_rarity:SetString(GetModifiedRarityStringForItem(item_key))
        current_item_summary.item_rarity:SetColour(GetColorForItem(item_key))
        current_item_summary.description:SetString(GetSkinDescription(item_key))
        current_item_summary:Show()
    end

    return current_item_summary
end

function ItemBoxOpenerPopup:OnUpdate(dt)
    --print(self.ui_state)
    
	if self.ui_state == "INTRO" and self.bundle:GetAnimState():IsCurrentAnimation("idle") then
		self.ui_state = "PENDING_OPEN"
	
	elseif self.ui_state == "WAIT_ON_ITEMS" and self.bundle:GetAnimState():GetCurrentAnimationTime() > ANIM_TIMING.open.pause_for_server then
		if self.items == nil then
			self.bundle:GetAnimState():Pause()
		else
			self.ui_state = "BUNDLE_OPENING"
			self.bundle:GetAnimState():Resume() --we might have paused it if the server was slow to respond
		end

    elseif self.ui_state == "BUNDLE_OPENING" and self.bundle:GetAnimState():IsCurrentAnimation("skin_loop") then
        self.ui_state = "WAIT_ON_NEXT"

        local item_widget = self:GetItem(self.active_item_idx)
        assert(item_widget)
        -- We use bigportaits when there's tons of items, so probably don't
        -- want to show each item either. Also the item icons won't be the
        -- bigportait.
        if not self.use_bigportraits then
            item_widget:Show()
        end

        local item_key = self.items[self.active_item_idx]
        self.current_item_summary:UpdateSummary(item_key)
        TheFrontEnd:GetSound():PlaySound( RARITY_SOUND[GetRarityForItem(item_key)] or RARITY_SOUND["spiffy"] )

    -- WAIT_ON_NEXT state is progressed by OnControl
    elseif self.ui_state == "BUNDLE_CLOSING" and self.bundle:GetAnimState():AnimDone() then
        self.ui_state = "BUNDLE_REVIEW"
        
        -- update the background size
        local rows = math.ceil(#self.items/columns)
        self.frame:SetSize(bg_frame_w, rows * COLUMN_HEIGHT + bg_frame_h_offset)
        self.frame:SetPosition(0,bg_frame_initial_y - rows*COLUMN_HEIGHT/2)
        
        self.frame:Show()
        self.opened_item_display:Show()
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/music/reveal")
    end
    
    self:EvaluateButtons()
end

function ItemBoxOpenerPopup:CanExit()
    return self.swap_task == nil
        and ((self.allow_cancel and self.ui_state == "PENDING_OPEN")
            or self.ui_state == "BUNDLE_REVIEW")
end

function ItemBoxOpenerPopup:GetItem(index)
    local row = math.ceil(index/columns)
    local col = math.fmod(index-1,columns)+1
    --print("row:"..row.." col:"..col)
    return self.opened_item_display:GetItemInSlot(col,row)
end

-- Enables or disables arrows according to our current item
function ItemBoxOpenerPopup:EvaluateButtons()
    if self.back_button then
        if self:CanExit() then
            self.back_button:Show()
        else
            self.back_button:Hide()
        end
    end
end

function ItemBoxOpenerPopup:_HasNextItem()
    return self.active_item_idx < #self.items
end

function ItemBoxOpenerPopup:_UpdateSwapIcon(index)
    local item_key = self.items[index]
    local desired_symbol = "SWAP_ICON"
    local build = GetBuildForItem(item_key)
    if self.use_bigportraits then
        local portrait = GetBigPortraitForItem(item_key)
        if portrait and portrait.build then
            build, desired_symbol = portrait.build, portrait.symbol
        end
    end
    self.bundle:GetAnimState():OverrideSkinSymbol("SWAP_ICON", build, desired_symbol)
    self.active_item_idx = index
end

-- Start the opening process. Cannot exit until contents are displayed.
function ItemBoxOpenerPopup:_OpenItemBox()
	self.ui_state = "WAIT_ON_ITEMS"
	
    self.open_box_fn(function(item_types)
        self.items = item_types

        local item_images = {}
        for i,item_key in ipairs(item_types) do
            local item_type = GetTypeForItem(item_key)
            local item_widget = TEMPLATES.ItemImageText(item_type, item_key, 150)
            table.insert(item_images, item_widget)
        end

        self.opened_item_display:FillGrid(columns, COLUMN_WIDTH, COLUMN_HEIGHT, item_images)
        self:_UpdateSwapIcon(1)
    end)
    
	self.bundle:GetAnimState():PlayAnimation("open")
	self.bundle:GetAnimState():PushAnimation("skin_loop", true)
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/mysterybox/hit2")
    self.inst:DoTaskInTime(0.5, function() TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/mysterybox/hit3") end )
end

function ItemBoxOpenerPopup:_RevealNextItem()
    -- Hide summary during item transition.
    self.current_item_summary:Hide()

    if self:_HasNextItem() then
        self.bundle:GetAnimState():PlayAnimation("skin_next")
        self.bundle:GetAnimState():PushAnimation("skin_loop", true)
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/mysterybox/hit3")

        self.swap_task = self.inst:DoTaskInTime(ANIM_TIMING.skin_next.icon_hidden, function()
            self:_UpdateSwapIcon(self.active_item_idx + 1)
            self.swap_task = nil
        end)
        self.ui_state = "BUNDLE_OPENING"
    else
        self.bundle:GetAnimState():PlayAnimation("skin_out")
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/collectionscreen/mysterybox/outro")
        self.ui_state = "BUNDLE_CLOSING"
    end
end

function ItemBoxOpenerPopup:_Close()
	self.ui_state = "OUTRO"
    self.bundle_root:Hide()

    self.bg.bgplate.image:TintTo(PP_ON_TINT, PP_OFF_TINT, TRANSITION_DURATION, function()
        TheFrontEnd:PopScreen(self)
    end)

    TheFrontEnd:GetSound():KillSound("mysteryboxactive")
end

function ItemBoxOpenerPopup:_TryClose()
    if self:CanExit() then
        self:_Close()
        return true
    end
end


function ItemBoxOpenerPopup:OnControl(control, down)
    if ItemBoxOpenerPopup._base.OnControl(self,control, down) then 
        return true 
    end

    if down then
        return false
    end
    
    if control == CONTROL_ACCEPT then
        if self.ui_state == "PENDING_OPEN" then
            self:_OpenItemBox()
            return true
        elseif self.ui_state == "BUNDLE_OPENING" then
            -- Allow users to skip to reveal, but not skip hiding current
            -- because current index isn't updated until swap_task completes.
            if self.swap_task == nil then
                self.bundle:GetAnimState():PlayAnimation("skin_loop", true)
                return true
            end
        elseif self.ui_state == "WAIT_ON_NEXT" then
            assert(self.swap_task == nil, "Swap should have finished during BUNDLE_OPENING")
            self:_RevealNextItem()
            return true
        elseif self.ui_state == "BUNDLE_REVIEW" then
            self:_TryClose()
            return true
        end

    elseif control == CONTROL_CANCEL then
        return self:_TryClose()
    end
end

function ItemBoxOpenerPopup:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    if self.ui_state == "PENDING_OPEN" then
        table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.ITEM_SCREEN.OPEN_BUTTON)
    end

    if self:CanExit() then
		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.ITEM_SCREEN.BACK)
    end
    
    return table.concat(t, "  ")
end

function ItemBoxOpenerPopup:OnBecomeActive()
    ItemBoxOpenerPopup._base.OnBecomeActive(self)
    TheFrontEnd:GetSound():SetVolume("FEMusic", 0)
end

function ItemBoxOpenerPopup:OnBecomeInactive()
    ItemBoxOpenerPopup._base.OnBecomeInactive(self)
    TheFrontEnd:GetSound():SetVolume("FEMusic", 1)
end

return ItemBoxOpenerPopup