local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local UIAnim = require "widgets/uianim"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Spinner = require "widgets/spinner"
local MagicSkinCollector = require "widgets/magicskincollector"
local OnlineStatus = require "widgets/onlinestatus"
local PopupDialogScreen = require "screens/popupdialog"
local ItemBoxOpenerPopup = require "screens/redux/itemboxopenerpopup"

local TEMPLATES = require("widgets/redux/templates")


local MysteryBoxScreen = Class(Screen, function(self, prev_screen, user_profile)
	Screen._ctor(self, "MysteryBoxScreen")
    self.user_profile = user_profile
	self:DoInit()

	self.default_focus = self.boxes_root
end)

function MysteryBoxScreen:DoInit()
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.bg = self.root:AddChild(TEMPLATES.PlainBackground())

    self.title = self.root:AddChild(TEMPLATES.ScreenTitle(STRINGS.UI.MYSTERYBOXSCREEN.TITLE, ""))
    self.onlinestatus = self.root:AddChild(OnlineStatus(true))
    self.userprogress = self.root:AddChild(TEMPLATES.UserProgress(function()
        -- We should have come from the PlayerSummaryScreen. Can't push the
        -- screen because we'd have a require loop and "back" navigation would
        -- be weird.
        TheFrontEnd:FadeBack()
    end))

    self.boxes_root = self:_BuildBoxesPanel()

    self.alloutofbox = self.root:AddChild(TEMPLATES.CurlyWindow(400,100, STRINGS.UI.MYSTERYBOXSCREEN.OUT_OF_BOXES_TITLE, nil, nil, STRINGS.UI.MYSTERYBOXSCREEN.OUT_OF_BOXES_BODY))
    self.alloutofbox:SetPosition(0, -20)
    
	self:UpdateMysteryBoxInfo()
	
    if not TheInput:ControllerAttached() then 
        self.back_button = self.root:AddChild(TEMPLATES.BackButton(
                function()
                    TheFrontEnd:FadeBack()
                end
            ))
    end
end

function MysteryBoxScreen:UpdateMysteryBoxInfo()
	
	--Grab all the mysteryboxes types and check counts if 0 don't add it unless it's the classic one.
	self.box_counts = GetMysteryBoxCounts()

	--always have one option in the list to display
	if self.box_counts["mysterybox_lava_4"] == nil then
		self.box_counts["mysterybox_lava_4"] = 0
	end
	
    local has_boxes = false
	local box_options = {}
    for item_type,count in pairs(self.box_counts) do
		table.insert(box_options, { text = GetSkinName(item_type), data = item_type } )
        has_boxes = has_boxes or count > 0
    end
    
	self.boxes_root.spinner:SetOptions(box_options)
	
	--refresh the current display
	local current_data = self.boxes_root.spinner:GetSelectedData()
	self.boxes_root.spinner:OnChanged( current_data )

    if has_boxes then
        self.alloutofbox:Hide()
        self.boxes_root:Show()
        self.boxes_root.open_btn:Unselect()
    else
        self.boxes_root:Hide()
        self.alloutofbox:Show()
        -- Ensure help text for button doesn't appear.
        self.boxes_root.open_btn:Select()
    end
end

function MysteryBoxScreen:_BuildBoxesPanel()
	local boxes_ss = self.root:AddChild(Widget("boxes_ss"))

    self.frame = boxes_ss:AddChild(Image("images/fepanels_redux_shop_panel.xml", "shop_panel.tex"))
    self.frame:SetScale(0.9)
    self.frame:SetPosition(0,10)
    
    boxes_ss.spinner = boxes_ss:AddChild(Spinner({}, 450, 40, {font=HEADERFONT, size=30}, nil, nil, nil, true, nil, nil))
	boxes_ss.spinner.background:Hide()
    boxes_ss.spinner:SetPosition( 0, 140, 0 )
    boxes_ss.spinner:SetTextColour( UICOLOURS.GOLD_SELECTED )
    
    boxes_ss.description_text = boxes_ss:AddChild(Text(CHATFONT, 26, "", UICOLOURS.GOLD_UNIMPORTANT ))
    boxes_ss.description_text:SetHAlign(ANCHOR_LEFT)
    boxes_ss.description_text:EnableWordWrap(true)
    boxes_ss.description_text:SetRegionSize(210, 140)
    boxes_ss.description_text:SetPosition( 100, 0 )
    
    boxes_ss.image = boxes_ss:AddChild(UIAnim())
	boxes_ss.image:GetAnimState():SetBuild("frames_comp")
	boxes_ss.image:GetAnimState():SetBank("fr")
	boxes_ss.image:GetAnimState():Hide("frame")
	boxes_ss.image:GetAnimState():Hide("NEW")
	boxes_ss.image:GetAnimState():PlayAnimation("icon")
	boxes_ss.image:SetPosition(-100, 0)
	boxes_ss.image:SetScale(1.75)
    
	boxes_ss.count_text = boxes_ss.image:AddChild(Text(HEADERFONT, 20, nil, UICOLOURS.WHITE))
    boxes_ss.count_text:SetPosition(0, -70)
    boxes_ss.count_text:SetRegionSize(90, 20)
    --boxes_ss.count_text:SetHAlign(ANCHOR_LEFT)

    boxes_ss.open_btn = boxes_ss:AddChild(TEMPLATES.StandardButton())
    boxes_ss.open_btn:SetScale(0.7)
    boxes_ss.open_btn:SetText(STRINGS.UI.MYSTERYBOXSCREEN.OPEN_BOX)
    boxes_ss.open_btn:SetPosition( 100, -120 )
    boxes_ss.open_btn:SetOnClick(function()
        local box_item_id = GetMysteryBoxItemID( boxes_ss.spinner:GetSelectedData() )
        local options = {
            allow_cancel = true,
        }
        local box_popup = ItemBoxOpenerPopup(self, options, function(success_cb)
            TheItems:OpenBox(box_item_id, function(success, item_types)
                if not success or #item_types == 0 then
                    local body_txt = (not success) and STRINGS.UI.BOX_POPUP.SERVER_ERROR_BODY or STRINGS.UI.BOX_POPUP.SERVER_NO_ITEM_BODY
                    local box_error = PopupDialogScreen(STRINGS.UI.BOX_POPUP.SERVER_ERROR_TITLE, body_txt,
                        {
                            {
                                text = STRINGS.UI.BOX_POPUP.OK,
                                cb = function()
                                    SimReset()
                                end
                            }
                        })
                    TheFrontEnd:PushScreen( box_error )
                else
                    success_cb(item_types)
                    self:UpdateMysteryBoxInfo()
                end	
            end)
		end)
		TheFrontEnd:PushScreen(box_popup)
    end)

    boxes_ss.spinner.OnChanged =
        function( _self, item_type, old )
			boxes_ss.image:GetAnimState():OverrideSkinSymbol("SWAP_ICON", GetBuildForItem(item_type), "SWAP_ICON")
			
			local item_count_str = string.format("x%d", self.box_counts[item_type])
			boxes_ss.count_text:SetString(item_count_str)

			boxes_ss.description_text:SetString(GetSkinDescription(item_type))
			
			if self.box_counts[item_type] == 0 then
				boxes_ss.open_btn:Disable()
			else
				boxes_ss.open_btn:Enable()
			end
        end	

    boxes_ss.focus_forward = boxes_ss.open_btn
    boxes_ss.spinner:SetFocusChangeDir(MOVE_DOWN, boxes_ss.open_btn)
    boxes_ss.open_btn:SetFocusChangeDir(MOVE_UP, boxes_ss.spinner)
	
	return boxes_ss
end





function MysteryBoxScreen:OnBecomeActive()
    MysteryBoxScreen._base.OnBecomeActive(self)

    if not self.shown then
        self:Show()
    end

    self.leaving = nil
end

function MysteryBoxScreen:OnControl(control, down)
    if MysteryBoxScreen._base.OnControl(self, control, down) then return true end

    if not down and control == CONTROL_CANCEL then
        TheFrontEnd:FadeBack()
        return true
    end
end

function MysteryBoxScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.SERVERLISTINGSCREEN.BACK)
    return table.concat(t, "  ")
end


function MysteryBoxScreen:OnUpdate(dt)
end


return MysteryBoxScreen
