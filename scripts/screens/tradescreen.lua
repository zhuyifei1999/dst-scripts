local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/templates"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local AnimButton = require "widgets/animbutton"
local Text = require "widgets/text"
local SkinCollector = require "widgets/skincollector"
local ItemSelector = require "widgets/itemselector"
local ItemImage = require "widgets/itemimage"
local ImagePopupDialogScreen = require "screens/imagepopupdialog"
local PopupDialogScreen = require "screens/popupdialog"
local easing = require "easing"

require("skinsfiltersutils")
require("skinstradeutils")

local DOMINO_DELAY = .3
local MAX_TRADE_ITEMS = 9

local FRAMES_Y = -50

local DEBUG_MODE = BRANCH == "dev"

function GetJoystickAnim(angle)

	if angle > 0 then 

		if angle < math.pi/8 then 
			return "3"
		elseif angle < 3*math.pi/8 then
			return "1:30"
		elseif angle < 5*math.pi/8 then 
			return "12"
		elseif angle < 7*math.pi/8 then 
			return "10:30"
		elseif angle < 9*math.pi/8 then 
			return "9"
		elseif angle < 11*math.pi/8 then 
			return "7:30"
		elseif angle < 13*math.pi/8 then 
			return "6"
		elseif angle < 15*math.pi/8 then 
			return "4:30"
		else
			return "3" 
		end

	else
		if angle > -1*math.pi/8 then 
			return "3"
		elseif angle > -3*math.pi/8 then
			return "4:30"
		elseif angle > -5*math.pi/8 then 
			return "6"
		elseif angle > -7*math.pi/8 then 
			return "7:30"
		elseif angle > -9*math.pi/8 then 
			return "9"
		elseif angle > -11*math.pi/8 then 
			return "10:30"
		elseif angle > -13*math.pi/8 then 
			return "12"
		elseif angle > -15*math.pi/8 then 
			return "1:30"
		else
			return "3" 
		end

	end

end

local function FindFirstEmptySlot(selections)
	local first = nil
	for i=1,MAX_TRADE_ITEMS do
		if selections[i] == nil then
			first = i
			break
		end
	end
	return first
end

local function FindLastFullSlot(selections)
	local last = nil
	for i=MAX_TRADE_ITEMS,1,-1 do
		if selections[i] ~= nil then
			last = i
			break
		end
	end
	return last
end

local ItemEndMove = function(owner, i)
	owner.moving_items_list[i] = nil 
	--print("Item ", i, " finished moving")
	if next(owner.moving_items_list) == nil then 
		--print("All items finished moving, clearing moving items list")
		owner.popup:EnableInput()
	end
end

local ItemsInUse = function( selected_items, moving_items_list )
	local items_in_use = {}
	for i,item in pairs( selected_items ) do
		items_in_use[i] = item
	end
	if moving_items_list then
		for _,moving_item in pairs( moving_items_list ) do
			assert( items_in_use[moving_item.target_slot_index] == nil )
			items_in_use[moving_item.target_slot_index] = moving_item.item 
		end
	end
	return items_in_use
end




local TradeScreen = Class(Screen, function(self, profile, screen)
	Screen._ctor(self, "TradeScreen")

	--print("Is offline?", TheNet:IsOnlineMode() or "nil", TheFrontEnd:GetIsOfflineMode() or "nil")

	self.profile = profile
	self:DoInit() 
	self.prevScreen = screen
end)


function TradeScreen:DoInit()
	STATS_ENABLE = true
	TheFrontEnd:GetGraphicsOptions():DisableStencil()
	TheFrontEnd:GetGraphicsOptions():DisableLightMapComponent()
	
	TheInputProxy:SetCursorVisible(true)

	-- FIXED ROOT
    self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.panel_bg = self.fixed_root:AddChild(TEMPLATES.NoPortalBackground())
    self.menu_bg = self.fixed_root:AddChild(TEMPLATES.LeftGradient())

    if not TheInput:ControllerAttached() then 
    	self.exit_button = self.fixed_root:AddChild(TEMPLATES.BackButton(function() self:Quit() end)) 

    	self.exit_button:SetPosition(-RESOLUTION_X*.415, -RESOLUTION_Y*.505 + BACK_BUTTON_Y )
  	end

  	self.market_button = self.fixed_root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "steam.tex", "", false, false, 
    											function() VisitURL("https://steamcommunity.com/market/search?appid=322330") end  
    										))

  	self.market_button:SetPosition(RESOLUTION_X*.45, -RESOLUTION_Y*.505 + BACK_BUTTON_Y)


  	-- Hanging sign
    self.sign_bg = self.fixed_root:AddChild(Image("images/tradescreen.xml", "hanging_sign_brackets.tex"))
    self.sign_bg:SetScale(.7, .7, .7)
    self.sign_bg:SetPosition(-425, 17)
    self.sign_bg:SetClickable(false)
  	
  	-- Add the claw machine
  	self.claw_machine_bg = self.fixed_root:AddChild(UIAnim())
  	self.claw_machine_bg:GetAnimState():SetBuild("swapshoppe_bg")
    self.claw_machine_bg:GetAnimState():SetBank("shop_bg")
    self.claw_machine_bg:SetScale(.62)
    self.claw_machine_bg:SetPosition(0, 65)
  	
  	self.claw_machine = self.fixed_root:AddChild(UIAnim())
  	self.claw_machine:GetAnimState():SetBuild("swapshoppe")
    self.claw_machine:GetAnimState():SetBank("shop")
    self.claw_machine:SetScale(.62)
    self.claw_machine:SetPosition(0, 65)
    
	self:PlayMachineAnim("idle_empty", true)

    -- Title (Trade Inn sign)
  	self.title = self.fixed_root:AddChild(Image("images/tradescreen_overflow.xml", "TradeInnSign.tex"))
  	self.title:SetScale(.66)
  	self.title:SetPosition(0, 305)

  	-- joystick 
    self.joystick = self.claw_machine:AddChild(UIAnim())
  	self.joystick:GetAnimState():SetBuild("joystick")
    self.joystick:GetAnimState():SetBank("joystick")
    self.joystick:GetAnimState():PlayAnimation("idle", true) -- possible anims are idle, 6, 7:30, 9, 10:30, 12, 1:30, 3, 4:30
    

    -- Add an invisible button to catch mouse events.
    -- On click, the skin collector will talk about the joystick.
    -- On mouseover, the joystick starts following the mouse.
    self.joystick.button = self.joystick:AddChild(TEMPLATES.InvisibleButton(50, 50, 
    											function() self.innkeeper:Say(STRINGS.UI.TRADESCREEN.SKIN_COLLECTOR_SPEECH.JOYSTICK) end, 
    											function() if not self.joystick_started then self:StartJoystick() end end ))

    local jx = 5
    local jy = -550
    self.joystick:SetPosition(jx, jy)

   
    self.item_name = self.fixed_root:AddChild(Text(UIFONT, 45))
    self.item_name:SetHAlign(ANCHOR_MIDDLE)
    self.item_name:SetPosition(0, 165, 0)
    self.item_name:SetColour(1, 1, 1, 1)
	self.item_name:Hide()    


    -- reset button bg
    self.resetbtn = self.claw_machine:AddChild(TEMPLATES.AnimTextButton("button", 
    											{idle = "idle_red", over = "up_red", disabled = "down_red"},
    											1, 
    											function() 
    												self:Reset()
    											end,
    											STRINGS.UI.TRADESCREEN.RESET, 
    											45))
    self.resetbtn:SetPosition(-200, -540)

    -- trade button bg
    self.tradebtn = self.claw_machine:AddChild(TEMPLATES.AnimTextButton("button", 
    											{idle = "idle_green", over = "up_green", disabled = "down_green"},
    											1, 
    											function() 
    												self:Trade()
    											end,
    											STRINGS.UI.TRADESCREEN.TRADE, 
    											45))
    self.tradebtn:SetPosition(208, -540)

  
	--Machine tiles
	self.frames_container = self.claw_machine_bg:AddChild(Widget("frames_container"))
	self.frames_single = {}
	for i=1,MAX_TRADE_ITEMS do
		self.frames_single[i] = self.frames_container:AddChild(ItemImage(self, nil, nil, 0, 0, function() self:RemoveSelectedItem(i) end ))
		self.frames_single[i]:DisableSelecting()
	end	
	self.frames_positions = {}
	for x = 1,3 do
		for y = 0,2 do
			local index = x + y*3
			self.frames_positions[index] = { x = (x-2) * 90, y = (y-1) * -90, z = 0}
		end
	end
	self:ResetTiles()

    self.selected_items = {}
	self.last_added_item_index = nil
	
	self.moving_items_list = {}

    -- Create the inventory list
    local recipes = GetRecipeMatches(self.selected_items)
	self.filters = GetFilters(recipes)

	self:RefreshUIState()

    -- Skin collector
  	self.innkeeper = self.fixed_root:AddChild(SkinCollector( self.popup:GetNumFilteredItems() )) --this needs to happen after RefreshUIState was called so that we have the filtered list 
    self.innkeeper:SetPosition(410, -390)
    self.innkeeper:Appear()
    
	self.machine_in_use = false
	self.flush_items = false
	self.trade_started = false
	self.accept_waiting = false

	self.warning_timeout = 0
	
	self.default_focus = self.popup.list_widgets[1]	

	self:RefreshUIState()
end


--[[function TradeScreen:DoFocusHookups()
	for i=1,MAX_TRADE_ITEMS do 
		if i+1 <= MAX_TRADE_ITEMS and math.fmod(i, 3) ~= 0 then
			self.frames_single[i]:SetFocusChangeDir(MOVE_RIGHT, self.frames_single[i+1])
		end

		if i-1 > 0 and math.fmod(i, 3) ~= 1 then 
			self.frames_single[i]:SetFocusChangeDir(MOVE_LEFT, self.frames_single[i-1])
		end

		if i-3 > 0 then 
			self.frames_single[i]:SetFocusChangeDir(MOVE_UP, self.frames_single[i-3])
		end

		if i+3 <= MAX_TRADE_ITEMS then 
			self.frames_single[i]:SetFocusChangeDir(MOVE_DOWN, self.frames_single[i+3])
		end
	end
end]]

function TradeScreen:StartJoystick()
	self.joystick_started = true

	if not self.joystickmover then 
		self.joystickmover = TheInput:AddMoveHandler(function(mx,my)

			local jpos = self.joystick:GetWorldPosition()
			local xdiff = mx - jpos.x
			local ydiff = my - jpos.y

			local angle = math.atan2(ydiff, xdiff)
			local anim = GetJoystickAnim(angle)
			self.joystick:GetAnimState():PlayAnimation(anim, true)
		end)
	end
end

function TradeScreen:PlayMachineAnim( name, loop )
	self.claw_machine:GetAnimState():PlayAnimation(name, loop)
	self.claw_machine_bg:GetAnimState():PlayAnimation(name, loop)
end
function TradeScreen:PushMachineAnim( name, loop )
	self.claw_machine:GetAnimState():PushAnimation(name, loop)
	self.claw_machine_bg:GetAnimState():PushAnimation(name, loop)
end

function TradeScreen:CancelPendingMoves()
	for k,v in pairs(self.moving_items_list) do 
		v:Kill()
	end
	self.moving_items_list = {}
end

function TradeScreen:Reset()
	
	self.item_name:Hide()
	
	-- stop the joystick so we can restart it
	if self.joystickmover then 
		self.joystickmover:Remove()
		self.joystickmover = nil
	end

	self.joystick:GetAnimState():PlayAnimation("idle", true)

	self.item_name_displayed = nil

	self.innkeeper:ClearSpeech()

	TheFrontEnd:GetSound():KillSound("idle_sound")

	-- Kill sound tasks just in case something gets out of sequence somehow
	if self.skin_in_task then
		self.skin_in_task:Cancel()
		self.skin_in_task = nil
	end

	if self.idle_sound_task then
		self.idle_sound_task:Cancel()
		self.idle_sound_task = nil
	end

	if self.claw_machine:GetAnimState():IsCurrentAnimation("skin_in") or 
		self.claw_machine:GetAnimState():IsCurrentAnimation("idle_skin") then
		
		self:PlayMachineAnim("skin_off", false)
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/swapshoppe/skin_off")

		self.reset_started = true
	else
		if not self.claw_machine:GetAnimState():IsCurrentAnimation("skin_off") then --if we're playing "skin_off", we'll reset in OnUpdate
			self:FinishReset(true)
		end
	end
end

function TradeScreen:FinishReset(move_items)
	self.claw_machine:GetAnimState():OverrideSkinSymbol("SWAP_ICON", "shoppe_frames", "")
	self.claw_machine:GetAnimState():OverrideSymbol("SWAP_frameBG", "frame_BG", "")
	self:PlayMachineAnim("idle_empty", true)
	
	self:DisableTiles()

	if move_items then 
		self:CancelPendingMoves()
		
		local reset_moves_started = false
		for i=1,MAX_TRADE_ITEMS do 
			if self.frames_single[i].name then
				reset_moves_started = true
				self.moving_items_list[i] = TEMPLATES.MovingItem( self.frames_single[i].name,
														self.frames_single[i].type,
														i,
														self.frames_single[i]:GetWorldPosition(),
														self.popup.page_list.right_button:GetWorldPosition(),
														.65 * self.fixed_root:GetScale().x, 
														.5 * self.fixed_root:GetScale().x )
				self.moving_items_list[i].Move(function() ItemEndMove(self, i) end) -- EnableTiles() is done inside ItemEndMove if all items are done moving
			end
		end
		if not reset_moves_started then --nothing to reset, so we need to re-enable the tiles
			self:EnableTiles()
		end
	else
		self:EnableTiles() -- this case hits if we are accepting an item instead of taking stuff out of the machine
	end
	
	self:ResetTiles()
	
	if self.joystick_started then 
		self:StartJoystick()
	end

	-- Clear all clothing data
	self.selected_items = {}

	self.reset_started = false
	self.machine_in_use = false
	self.accept_waiting = false
	
	self.popup.page_list:SetPage(1)
	
	self.last_added_item_index = nil
	
	self:RefreshUIState()
end

function TradeScreen:EnableTiles()
	--print("Enabling tiles", debugstack())
	self.popup:EnableInput()
	self:EnableMachineTiles()
end

function TradeScreen:EnableMachineTiles()
	for i=1,MAX_TRADE_ITEMS do
		self.frames_single[i]:Enable()
	end
end

function TradeScreen:DisableTiles()
	self.popup:DisableInput()
	self:DisableMachineTiles()
end

function TradeScreen:DisableMachineTiles()
	for i=1,MAX_TRADE_ITEMS do
		self.frames_single[i]:Disable()
	end
end

function TradeScreen:OnBecomeActive()
	--print("**** Activate TradeScreen ****")
	Screen.OnBecomeActive(self)

	if self.joystick_started then 
		self:StartJoystick()
	end

	self.item_name:Hide()

	self:RefreshUIState()
end

local function widget_already_processed(name, widget_list)
	for i=1,#widget_list do 
		if widget_list[i].name == name then 
			return true
		end
	end

	return false
end

function TradeScreen:Trade(done_warning)

	if not done_warning then 
		local warn_table = {}
		for i=1,MAX_TRADE_ITEMS do 
			if not widget_already_processed(self.frames_single[i].name, warn_table) and self.popup:NumItemsLikeThis(self.frames_single[i].name) == 0 then  
				local widg = Widget("item"..i)

				widg.name = self.frames_single[i].name

		        widg.frame = widg:AddChild(UIAnim())
		        widg.frame:GetAnimState():SetBuild("frames_comp") -- use the animation file as the build, then override it
		        widg.frame:GetAnimState():AddOverrideBuild("frame_skins") -- file name
		        widg.frame:GetAnimState():SetBank("fr") -- top level symbol from frames_comp

		        local rarity = GetRarityForItem(self.frames_single[i].type, self.frames_single[i].name)

		        widg.frame:GetAnimState():OverrideSkinSymbol("SWAP_ICON",  GetBuildForItem(self.frames_single[i].type, self.frames_single[i].name), "SWAP_ICON")
		        widg.frame:GetAnimState():OverrideSymbol("SWAP_frameBG", "frame_BG", rarity)

		        widg.frame:GetAnimState():PlayAnimation("icon", true)
		        widg.frame:GetAnimState():Hide("NEW")

		        widg:SetScale(.5)
				table.insert(warn_table, widg)
			end
		end

		if next(warn_table) then
			local str = #warn_table > 1 and STRINGS.UI.TRADESCREEN.WARNING or STRINGS.UI.TRADESCREEN.WARNING_SINGLE
			self.warning_popup = ImagePopupDialogScreen(STRINGS.UI.TRADESCREEN.CHECK, 
					warn_table,
					60, -- widget width
					5, -- spacing between widgets
					str, 
					{ {text=STRINGS.UI.TRADESCREEN.OK, cb = function() TheFrontEnd:PopScreen() 
																	self:Trade(true) 
															end, controller_control=CONTROL_ACCEPT} , 
					  {text=STRINGS.UI.TRADESCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end, controller_control=CONTROL_CANCEL }
					}) 
				TheFrontEnd:PushScreen(self.warning_popup)
			return
		end
	end

	self.trade_started = true
	self.machine_in_use = true
	
	
	
	self:PlayMachineAnim("claw_in", false)
	self.joystick:GetAnimState():PlayAnimation("idle", true)
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/swapshoppe/claw_in")

	self.innkeeper:Say(STRINGS.UI.TRADESCREEN.SKIN_COLLECTOR_SPEECH.TRADE)
	
	--hide all the hover text
	for i=1,MAX_TRADE_ITEMS do
		self.frames_single[i]:ClearHoverText()
	end

	self:DisableTiles()
	self.tradebtn:Disable()
	self.resetbtn:Disable()

	local recipes = GetRecipeMatches(self.selected_items)
	local name = TRADE_RECIPES[recipes[1]].name

	-- TODO: stop hard-coding the rarity to the next one up. We should really read it out of the recipes file.
	local rarity = GetRarityForItem(self.frames_single[1].type, self.frames_single[1].name)
	self.expected_rarity = GetNextRarity(rarity)

	--print("Using trade rule", name)

	local items_array = {}
	for i=1,MAX_TRADE_ITEMS do 
		table.insert(items_array, self.selected_items[i].item_id)
	end

	self.queued_item = nil
	
	--For Testing
	--self.queued_item = "backpack_camping_orange_carrot"
	
	TheItems:SwapItems(name,
		items_array,
		function(success, msg, item_type) print("Item swap completed", success, msg, item_type) 
			if success then
				self.queued_item = item_type
			else
				local server_error = PopupDialogScreen(STRINGS.UI.TRADESCREEN.SERVER_ERROR_TITLE, STRINGS.UI.TRADESCREEN.SERVER_ERROR_BODY,
					{
						{text=STRINGS.UI.TRADESCREEN.OK, cb = 
							function()
								print("ERROR: Failed to contact the item server.", msg )
								SimReset()
							end}
					}
				)
				TheFrontEnd:PushScreen( server_error )
			end
		end
	)
	
	self.selected_items = {}
end

function TradeScreen:FinishTrade()
	if self.queued_item ~= nil then
		self.trade_started = false
		self:GiveItem(self.queued_item)
		self.queued_item = nil
	end
end

function TradeScreen:GiveItem(item)	
	local item_type = GetTypeForItem(item)
	local name = GetBuildForItem(item_type, item)

	-- Need to store a reference to this so we can start it moving when the player clicks
	self.moving_gift_item = TEMPLATES.MovingItem(name, item_type, MAX_TRADE_ITEMS, self.claw_machine_bg:GetWorldPosition(), 
											self.popup.page_list.right_button:GetWorldPosition(), 1 * self.fixed_root:GetScale().x, .5 * self.fixed_root:GetScale().x)

	table.insert(self.moving_items_list, self.moving_gift_item)

	self.gift_name = item
	
	self.claw_machine:GetAnimState():OverrideSkinSymbol("SWAP_ICON", name, "SWAP_ICON")
	self.claw_machine:GetAnimState():OverrideSymbol("SWAP_frameBG", "frame_BG", GetRarityForItem(item_type, item))
	self:PlayMachineAnim("skin_in", false)
	self:PushMachineAnim("idle_skin", true)

	-- Delay 16 frames as specified by Dany
	self.skin_in_task = self.inst:DoTaskInTime(16*FRAMES, 
		function()
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/swapshoppe/skin_in")
		end
	)

	-- Play this one when the skin first appears (30 frames into skin_in)
	self.idle_sound_task = self.inst:DoTaskInTime(30*FRAMES, 
		function()
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/swapshoppe/skin_idle", "idle_sound")
			self:DisplayItemName(self.gift_name)
		end
	)
	
	if self.joystickmover then 
		self.joystickmover:Remove()
		self.joystickmover = nil
	end

	self.joystick:GetAnimState():PlayAnimation("idle", true)
end

function TradeScreen:DisplayItemName(gift)
	assert(not self.item_name_displayed)
	self.item_name_displayed = true

	local name_string = GetName(gift) 
	local item_type = GetTypeForItem(gift)
	local rarity = GetRarityForItem(item_type, gift)
	self.item_name:SetTruncatedString(name_string, 330, 35, true)
	self.item_name:SetColour(SKIN_RARITY_COLORS[rarity])
	self.item_name:Show()
	
	local str = STRINGS.UI.TRADESCREEN.SKIN_COLLECTOR_SPEECH.RESULT
	if rarity ~= self.expected_rarity then 
		str = STRINGS.UI.TRADESCREEN.SKIN_COLLECTOR_SPEECH.RESULT_LUCKY
	end

	self.innkeeper:Say(str, nil, name_string)

	self.expected_rarity = false
	self.accept_waiting = true
end

function TradeScreen:Quit()
	if self.joystickmover then 
		self.joystickmover:Remove()
		self.joystickmover = nil
	end

	if self.skin_in_task then
		self.skin_in_task:Cancel()
		self.skin_in_task = nil
	end

	if self.idle_sound_task then
		self.idle_sound_task:Cancel()
		self.idle_sound_task = nil
	end

	if self.exit_button then 
		self.exit_button:Disable()
	end
	self.quitting = true

	self.innkeeper:Disappear(function() 
		TheFrontEnd:GetSound():KillSound("idle_sound")
	end)

	-- kill all moving stuff
	for k,v in pairs(self.moving_items_list) do 
		v:Kill()
	end

	-- Start the fade approximately halfway through the disappear animation
	-- (which is 45 frames long)
	self.inst:DoTaskInTime(20*FRAMES, function()
		TheFrontEnd:Fade(false, SCREEN_FADE_TIME, function()
	       TheFrontEnd:PopScreen(self)
	       TheFrontEnd:Fade(true, SCREEN_FADE_TIME)
	    end)
	end)
end

function TradeScreen:RemoveSelectedItem(number)
	--print( "TradeScreen:RemoveSelectedItem", number )
	if self.machine_in_use then
		return
	end

	if self.frames_single[number].name then -- only do the move if there's actually an item there
		local start_scale = .65
		if self.frames_single[number].focus then
			start_scale = .78
		end
		local moving_item = TEMPLATES.MovingItem(self.frames_single[number].name, 
													self.frames_single[number].type,
													number,
													self.frames_single[number]:GetWorldPosition(),
													self.popup.page_list.right_button:GetWorldPosition(),
													start_scale * self.fixed_root:GetScale().x, .5 * self.fixed_root:GetScale().x)
	
		local idx = #self.moving_items_list + 1
		moving_item.Move(function() ItemEndMove(self, idx) self:RefreshUIState() end)

		--take the item out of the selected_items list and store it in the moving items list
		moving_item.item = self.selected_items[number]
		self.selected_items[number] = nil

		table.insert(self.moving_items_list, moving_item)

		self.last_added_item_index = nil
		self.frames_single[number]:SetItem(nil, nil, nil)
		
		self:RefreshUIState()
	end
end

function TradeScreen:GetLastAddedItem()
	return self.last_added_item_index
end

-- AddSelectedItem is called from the ItemSelector when an item in the inventory list is clicked.
function TradeScreen:StartAddSelectedItem(item, start_pos)

	if not self.selected_items then 
		self.selected_items = {}
	end

	local items_in_use = ItemsInUse( self.selected_items, self.moving_items_list )	

	local empty_slot = FindFirstEmptySlot(items_in_use) 
	if item and item.item and empty_slot ~= nil then -- we don't add an item unless there's an empty slot

		local slot = self.frames_single[empty_slot]
		--print("Slot position is ", slot:GetPosition(), slot:GetWorldPosition())

		local moving_item = TEMPLATES.MovingItem(item.item, item.type, empty_slot,
												start_pos,
												slot:GetWorldPosition(), 
												.56 *  self.fixed_root:GetScale().x, 
												.65 *  self.fixed_root:GetScale().x)
	
		local idx = #self.moving_items_list + 1
		moving_item.Move(function() ItemEndMove(self, idx) self:AddSelectedItem(item) self:RefreshUIState() end ) -- start the item moving toward the empty slot
		moving_item.item = item
		table.insert(self.moving_items_list, moving_item)
		
		item.target_index = empty_slot
		item.count = self.popup:NumItemsLikeThis(item.item)-1 -- it will be 1 less once the call to RefreshUIState updates the popup and removes the item
		if item.count == 0 then
			item.last_item_warning = true
		end
		
		self.last_added_item_index = item
		
		self:RefreshUIState() -- rebuild list without this item
	end
end

-- This is called once the item reaches the empty slot
function TradeScreen:AddSelectedItem(item)
	if item and item.item and item.target_index then
		local rarity = GetRarityForItem(item.type, item.item)
		
		self.selected_items[item.target_index] = item
		self.frames_single[item.target_index]:SetItem( item.type, item.item, 0) --Swap item
		
		if item.count == 0 then --the count will be 0 after it is refreshed with this item removed. 
			if self.warning_timeout <= 0 then
				self.innkeeper:Say( STRINGS.UI.TRADESCREEN.SKIN_COLLECTOR_SPEECH.WARNING )
				self.warning_timeout = 8 --don't warn more than once per 8 seconds.
			end

		-- TODO: Get the rarity out of the trade_recipes instead of hard-coding it to the next rarity up.
		elseif IsTradeAllowed(self.selected_items) then 
			self.innkeeper:Say( STRINGS.UI.TRADESCREEN.SKIN_COLLECTOR_SPEECH.TRADEAVAIL )
		else
			local number_selected = 0
			for k,v in pairs(self.selected_items) do 
				if v then 
					number_selected = number_selected + 1
				end
			end

			if number_selected == 1 then 
				self.innkeeper:Say(STRINGS.UI.TRADESCREEN.SKIN_COLLECTOR_SPEECH.ADDMORE, rarity)
			end
		end
	end
end


-- Delete the popup and re-create it. Called when an item is added to the claw machine so that the list is re-filtered.
function TradeScreen:RefreshUIState()
	local items_in_use = ItemsInUse( self.selected_items, self.moving_items_list )
		
	local recipes = GetRecipeMatches(items_in_use)
	self.filters = GetFilters(recipes)
	
	if self.popup == nil then
		self.popup = self.fixed_root:AddChild(ItemSelector(self.fixed_root, self, self.profile, items_in_use, self.filters))
		self.popup:SetPosition(-420, -100)
	else
		self.popup:UpdateData(items_in_use, self.filters)
	end
	
	if IsTradeAllowed(self.selected_items) then
		self.tradebtn:Enable()
	else
		self.tradebtn:Disable()
	end
	
	if next(self.selected_items) == nil then -- No items selected.
		self.resetbtn:Disable()
		self:DisableMachineTiles()
	else
		self.resetbtn:Enable()
		self:EnableMachineTiles()
	end
		
	self:RefreshMachineTilesState() -- Do this at the end so that self.popup will be already updated.
end

function TradeScreen:RefreshMachineTilesState()

	--check the count of items in the selector and remove any last item warning flags
	for i=1,MAX_TRADE_ITEMS do
		local item = self.selected_items[i]
		if item ~= nil and item.last_item_warning then 
			local count = self.popup:NumItemsLikeThis(item.item)
			if count > 0 then
				item.last_item_warning = nil
			else
				--also remove any duplicate last_item_warning
				for _,other_item in pairs(self.selected_items) do
					if other_item.item == item.item then
						other_item.last_item_warning = nil					
					end
				end
				item.last_item_warning = true --keep the marker on ourself
			end
		end
	end
	
	for i=1,MAX_TRADE_ITEMS do
		local item = self.selected_items[i]
		if item ~= nil then 
			local rarity = GetRarityForItem(item.type, item.item)
			local hover_text = rarity .. "\n" .. GetName(item.item)

			local y_offset = 50
			if item.last_item_warning then
				hover_text =  hover_text .. "\n" .. STRINGS.UI.TRADESCREEN.EQUIPPED
				y_offset = 60
			end
			self.frames_single[i]:Mark(item.last_item_warning)
			self.frames_single[i]:SetHoverText( hover_text, { font = NEWFONT_OUTLINE, size = 20, offset_x = 0, offset_y = y_offset, colour = {1,1,1,1}})
		else
			self.frames_single[i]:ClearHoverText()
			self.frames_single[i]:Mark(false)
		end
	end
end


function TradeScreen:StartFlushTiles()
	--print("Playing disappear and flush")
	self.flush_items = true
	self.flush_time = 0
	self.flush_tiles_moved = false
	self.flush_tiles_rot_rand = {}
	for i=1,MAX_TRADE_ITEMS do
		table.insert( self.flush_tiles_rot_rand, 20 + math.random()*(50) )
	end
	
	self:PlayMachineAnim("flush", false)
	self:PushMachineAnim("spiral_loop", true)

	-- used for timing SFX
	self.flush_sound_stage = 1
end

function TradeScreen:FlushTilesUpdate(dt)
	if self.flush_items then
		self.flush_time = self.flush_time + dt

		if self.flush_sound_stage == 1 and self.flush_time >= (2*FRAMES) then 
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/swapshoppe/flush")
			self.flush_sound_stage = 2
		elseif self.flush_sound_stage == 2 and self.flush_time >= (6*FRAMES) then 
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/swapshoppe/flush_flick")
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/Together_HUD/swapshoppe/flush_spin")
			self.flush_sound_stage = nil
		end
		
		
		--Handle the programatic animation of the tiles flushing
		local START_OFFSET = 10 * FRAMES
		if self.flush_time > START_OFFSET then
			local FLUSH_TIME = 1.5
			local CONTAINER_ROT = 500
			
			if not self.flush_tiles_moved then
				self.flush_tiles_moved = true
				for i=1,MAX_TRADE_ITEMS do
					local dest = {}
					dest.x = self.frames_positions[i].x + (math.random() - 0.5) * 60
					dest.y = self.frames_positions[i].y + (math.random() - 0.5) * 60
					dest.z = 0
					self.frames_single[i]:MoveTo( self.frames_positions[i], dest, 10*FLUSH_TIME )				
				end
			end
			
			local ft = self.flush_time - START_OFFSET
			
			local rot = easing.inQuad(ft, 0, CONTAINER_ROT, FLUSH_TIME)
			self.frames_container:SetRotation(rot)
			
			local scale = easing.inQuad(ft, 1.75, -1.75, FLUSH_TIME)
			self.frames_container:SetScale(scale)
			
			for i=1,MAX_TRADE_ITEMS do				
				local tile_rot = easing.outQuint(ft, 0, self.flush_tiles_rot_rand[i], 2*FLUSH_TIME)
				self.frames_single[i]:SetRotation(tile_rot)
				
				local tile_scale = easing.inQuad(ft, 1, -0.1, FLUSH_TIME)
				self.frames_single[i]:SetScale(tile_scale)	
			end
			
			if ft > FLUSH_TIME then
				for i=1,MAX_TRADE_ITEMS do
					self.frames_single[i]:Hide()
				end
				self.flush_items = false
			end
		end
	end
end


function TradeScreen:ResetTiles()
	for i=1,MAX_TRADE_ITEMS do
		self.frames_single[i]:Show()
		self.frames_single[i].inst.components.uianim.pos_t = nil --to stop any MoveTo in progress
		self.frames_single[i]:SetPosition( self.frames_positions[i].x, self.frames_positions[i].y, 0)
		self.frames_single[i]:SetScale( 1 )
		self.frames_single[i]:SetRotation( 0 )
		self.frames_single[i]:SetItem( nil, nil, nil )
	end
	self.frames_container:SetPosition( 5, -85, 0 )
	self.frames_container:SetRotation( 0 )
	self.frames_container:SetScale( 1.75 )
end



function TradeScreen:OnUpdate(dt)

	if self.reset_started and self.claw_machine:GetAnimState():IsCurrentAnimation("skin_off") and self.claw_machine:GetAnimState():AnimDone() then
		-- Wait for the skin out anim to finish and then animate the item over to the inventory
		if self.moving_gift_item and not self.moving_gift_item.moving then
			local idx = #self.moving_items_list
			--print("Skin_off is finished, ", self.moving_gift_item or "nil", idx or "nil")
	       	self.moving_gift_item.Move(function() ItemEndMove(self, idx) self:FinishReset() end)

	       	self:PlayMachineAnim("idle_empty", true)
	    end

	elseif self.claw_machine:GetAnimState():IsCurrentAnimation("claw_in") and self.claw_machine:GetAnimState():AnimDone() then 
		self:StartFlushTiles()
		
	elseif self.claw_machine:GetAnimState():IsCurrentAnimation("spiral_loop") and self.trade_started then 
		self:FinishTrade()
	end

	self:FlushTilesUpdate(dt)
	
	if self.warning_timeout > 0 then
		self.warning_timeout = self.warning_timeout - dt
	end	

	return true
end



local SCROLL_REPEAT_TIME = .15
local MOUSE_SCROLL_REPEAT_TIME = 0
local STICK_SCROLL_REPEAT_TIME = .25

function TradeScreen:OnControl(control, down)
    if TradeScreen._base.OnControl(self, control, down) then return true end

    if  TheInput:ControllerAttached() then 
	    if not down then 
	    	if control == CONTROL_CANCEL and not self.quitting then 
				self:Quit()
				return true 
			elseif control == CONTROL_MAP then 
				if self.resetbtn:IsEnabled() then
					TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
					self:Reset()
				end
				return true
			elseif control == CONTROL_PAUSE then 
				if IsTradeAllowed(self.selected_items) then
					TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
					self:Trade()
				end
				if self.accept_waiting then
					self:Reset()
				end
				return true
			elseif control == CONTROL_INSPECT then 
				VisitURL("https://steamcommunity.com/market/search?appid=322330")
				return true
			elseif control == CONTROL_MENU_MISC_1 then
				local slot_to_remove = FindLastFullSlot(self.selected_items)				
				if slot_to_remove ~= nil then
					self:RemoveSelectedItem(slot_to_remove)
					TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
				end
			end
	    end
	end

	if down then 
	 	if control == CONTROL_PREVVALUE then  -- r-stick left
	    	self:ScrollBack(control)
			return true 
		elseif control == CONTROL_NEXTVALUE then -- r-stick right
			self:ScrollFwd(control)
			return true
		elseif control == CONTROL_SCROLLBACK then
            self:ScrollBack(control)
            return true
        elseif control == CONTROL_SCROLLFWD then self:ScrollFwd(control)
            return true
       	elseif control == CONTROL_ACCEPT and self.accept_waiting then
       		self:Reset()
       	end
	end

end

function TradeScreen:ScrollBack(control)
	local page_list = self.popup.page_list
	if not page_list.repeat_time or page_list.repeat_time <= 0 then
		local pageNum = page_list.page_number
       	page_list:ChangePage(-1)
       	if page_list.page_number ~= pageNum then 
       		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
       	end
        page_list.repeat_time =
            TheInput:GetControlIsMouseWheel(control)
            and MOUSE_SCROLL_REPEAT_TIME
            or (control == CONTROL_SCROLLBACK and SCROLL_REPEAT_TIME) 
            or (control == CONTROL_PREVVALUE and STICK_SCROLL_REPEAT_TIME)
    end
end

function TradeScreen:ScrollFwd(control)
	local page_list = self.popup.page_list
	if not page_list.repeat_time or page_list.repeat_time <= 0 then
		local pageNum = page_list.page_number
        page_list:ChangePage(1)
		if page_list.page_number ~= pageNum then 
       		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
       	end
        page_list.repeat_time =
            TheInput:GetControlIsMouseWheel(control)
            and MOUSE_SCROLL_REPEAT_TIME
            or (control == CONTROL_SCROLLFWD and SCROLL_REPEAT_TIME) 
            or (control == CONTROL_NEXTVALUE and STICK_SCROLL_REPEAT_TIME)
    end
end

function TradeScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
    
    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.TRADESCREEN.BACK)
    
    table.insert(t, self.popup.page_list:GetHelpText())

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_INSPECT) .. " " .. STRINGS.UI.TRADESCREEN.MARKET)

	if self.resetbtn:IsEnabled() then
		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_MAP) .. " " .. STRINGS.UI.TRADESCREEN.RESET)
	end

    if self.tradebtn:IsEnabled() then
   		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.TRADESCREEN.TRADE)
   	end
	if self.accept_waiting then
   		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.TRADESCREEN.ACCEPT)
    end
    
    local slot_to_remove = FindLastFullSlot(self.selected_items)				
	if slot_to_remove ~= nil then
   		table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1) .. " " .. STRINGS.UI.TRADESCREEN.REMOVE_ITEM)
   	end
   
   	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.TRADESCREEN.SELECT)

    return table.concat(t, "  ")
end


return TradeScreen