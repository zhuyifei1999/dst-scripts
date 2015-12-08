local Widget = require "widgets/widget"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"

local scroll_per_click = 1
local scroll_per_page = 5

local button_repeat_time = .15

local arrow_button_size = 40

local DRAG_SCROLL_X_THRESHOLD = 150

-- ScrollableList expects a table of pre-constructed items to be handed in as the "items" param OR
-- for the "items" table to be a normalized table of data where each table entry is the data that will be handed as the parameters to the supplied function for "updatefn"
local ScrollableList = Class(Widget, function(self, items, listwidth, listheight, itemheight, itempadding, updatefn, widgetstoupdate, widgetXOffset, always_show_static, starting_offset, yInit)
    Widget._ctor(self, "ScrollBar")
    self.height = listheight
    self.width = listwidth
    self.bg = self:AddChild(Image("images/ui.xml", "blank.tex")) -- so that we have focus whenever the mouse is over this thing
    self.bg:ScaleToSize(self.width, self.height)
    self.items = {}
    self.item_height = itemheight or 40
    self.item_padding = itempadding or 10
    self.x_offset = widgetXOffset or 0
    self.yInitial = yInit or 0
    self.always_show_static_widgets = always_show_static or false
    self.focused_index = 1
    self.focus_children = true

    self.items = items
    if updatefn and widgetstoupdate then
    	self.updatefn = updatefn
    	self.static_widgets = widgetstoupdate
    else
	    for i,v in pairs(self.items) do
	    	self:AddChild(v)
	    end
	end

    self:RecalculateStepSize()

	self.view_offset = starting_offset or 0

	-- self.widget_bg = self:AddChild(Image("images/ui.xml", "1percent_clickbox.tex"))
	-- self.widget_bg:SetTint(1,1,1,0)
	-- self.widget_bg:ScaleToSize(self.width, self.height)

	self.up_button = self:AddChild(ImageButton("images/ui.xml", "arrow_scrollbar_up.tex", "arrow_scrollbar_up.tex", "arrow_scrollbar_up.tex", nil, nil, {1,1}, {0,0}))
	-- self.up_button:SetScale(.4)
    self.up_button:SetPosition(self.width/2, self.height/2-10, 0)
    self.up_button:SetWhileDown( function() 
    	if not self.last_up_button_time or GetTime() - self.last_up_button_time > button_repeat_time then
    		self.last_up_button_time = GetTime()
    		self:Scroll(-scroll_per_click, true) 
    	end
    end)
    self.up_button:SetOnClick( function()
    	self.last_up_button_time = nil
    end)
    -- self.up_button:StartUpdating()

	self.down_button = self:AddChild(ImageButton("images/ui.xml", "arrow_scrollbar_down.tex", "arrow_scrollbar_down.tex", "arrow_scrollbar_down.tex", nil, nil, {1,1}, {0,0}))
	-- self.down_button:SetScale(.4)
    self.down_button:SetPosition(self.width/2, -self.height/2+10, 0)
    self.down_button:SetWhileDown( function() 
    	if not self.last_down_button_time or GetTime() - self.last_down_button_time > button_repeat_time then
    		self.last_down_button_time = GetTime()
    		self:Scroll(scroll_per_click, true) 
    	end
    end)
    self.down_button:SetOnClick( function()
    	self.last_down_button_time = nil
    end)
    -- self.down_button:StartUpdating()

    self.scroll_bar_line = self:AddChild(Image("images/ui.xml", "scrollbarline.tex"))
    self.scroll_bar_line:ScaleToSize( 11, self.height - arrow_button_size - 20)
    self.scroll_bar_line:SetPosition(self.width/2, 0)

    self.scroll_bar = self:AddChild(ImageButton("images/ui.xml", "1percent_clickbox.tex", "1percent_clickbox.tex", "1percent_clickbox.tex", nil, nil, {1,1}, {0,0}))
	self.scroll_bar.image:ScaleToSize( 32, self.height - arrow_button_size - 20)
	self.scroll_bar.image:SetTint(1,1,1,0)
	self.scroll_bar.scale_on_focus = false
	self.scroll_bar.move_on_click = false
	self.scroll_bar:SetPosition(self.width/2, 0)
	self.scroll_bar:SetOnDown( function() 
		self.page_jump = true
	end)
	self.scroll_bar:SetOnClick( function() 
		if self.position_marker and self.page_jump then
			local marker = self.position_marker:GetWorldPosition()
			if TheFrontEnd.lasty >= marker.y then
				self:Scroll(-scroll_per_page, true)
			else
				self:Scroll(scroll_per_page, true)
			end
			self.page_jump = false
		end
	end )

	self.position_marker = self:AddChild(ImageButton("images/ui.xml", "scrollbarbox.tex", "scrollbarbox.tex", "scrollbarbox.tex", nil, nil, {1,1}, {0,0}))
	self.position_marker.scale_on_focus = false
	self.position_marker.move_on_click = false
	self.position_marker:SetPosition(self.width/2, self.height/2 - arrow_button_size, 0)
	self.position_marker:SetOnDown( function() 
		self.do_dragging = true
		self.y_adjustment = 0
	end)
    self.position_marker:SetWhileDown( function() 
    	if self.do_dragging then
	    	TheFrontEnd:LockFocus(true)
	    	self.dragging = true
	    	self:DoDragScroll() 
	    end
    end)
    self.position_marker.OnLoseFocus = function()
    	TheFrontEnd:LockFocus(false)
    	self.dragging = false
    	self.do_dragging = false
    	self.y_adjustment = 0
    	self:MoveMarkerToNearestStep() 
    end
    self.position_marker:SetOnClick( function() 
    	TheFrontEnd:LockFocus(false)
    	self.dragging = false
    	self.do_dragging = false
    	self.y_adjustment = 0
    	self:MoveMarkerToNearestStep() 
    end)

    --self.position_marker:MoveToBack()
    self.scroll_bar_line:MoveToBack()

    self:DoFocusHookups()

    self:RefreshView()
end)

function ScrollableList:OnControl(control, down, force)
    if ScrollableList._base.OnControl(self, control, down) then return true end

    if down and ((self.focus and self.scroll_bar:IsVisible()) or force) then
        if control == CONTROL_SCROLLBACK then
            if self:Scroll(-scroll_per_click, true) then
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            end
            return true
        elseif control == CONTROL_SCROLLFWD then
            if self:Scroll(scroll_per_click, true) then
                TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
            end
            return true
        end
    end
end

function ScrollableList:Scroll(amt, movemarker)
    local prev = self.view_offset

    -- Do Scroll on list
    self.view_offset = self.view_offset + amt
    if self.view_offset < 0 or self.max_step <= 0 then
        self.view_offset = 0
    elseif self.view_offset > self.max_step then
        self.view_offset = self.max_step
    end

    local didScrolling = self.view_offset ~= prev

    -- Move the marker
    if movemarker then
        local marker = self.position_marker:GetPosition()
        local newY = (self.height/2 - arrow_button_size) - (self.view_offset * self.step_size)
        if newY < -self.height/2 + arrow_button_size then
            newY = -self.height/2 + arrow_button_size
        elseif newY > self.height/2 - arrow_button_size then
            newY = self.height/2 - arrow_button_size
        end
        self.position_marker:SetPosition(marker.x, newY)
    end

    -- Refresh the view
    self:RefreshView()

    if self.onscrollcb ~= nil then
        self.onscrollcb()
    end
    return didScrolling
end

function ScrollableList:RefreshView(movemarker)
	local showing = false
	local nextYPos = self.height/2 - (arrow_button_size * .5) + self.yInitial

	local numShown = 0
	for i,v in ipairs(self.items) do
		if i < self.view_offset+1 then
			showing = false
		elseif i == self.view_offset+1 then
			showing = true
		end

		if showing then
			if self.updatefn and self.static_widgets then
				if self.static_widgets[i - self.view_offset] then
					-- if i - self.view_offset > #self.static_widgets then break end -- just in case we get into a bad spot
					self.updatefn(self.static_widgets[i - self.view_offset], v, i)
					self.static_widgets[i - self.view_offset]:SetPosition(-self.width/2 + self.x_offset, nextYPos)
				end
			else
				v:SetPosition(-self.width/2 + self.x_offset, nextYPos)
				v:Show()
			end
			numShown = numShown + 1

			nextYPos = nextYPos - self.item_height - self.item_padding

			-- Make sure we can actually fit another widget below us
			if numShown >= self.widgets_per_view then
				showing = false
			end
		else
			if not self.updatefn and not self.static_widgets then
				if v.focus then
					if i < self.view_offset+1 then
						self.items[self.view_offset+1]:SetFocus()
						self.focused_index = self.view_offset+1
					elseif i > self.view_offset+self.widgets_per_view then
						self.items[self.view_offset+self.widgets_per_view]:SetFocus()
						self.focused_index = self.view_offset+self.widgets_per_view
					end
				end
				v:Hide()
			elseif self.updatefn and self.static_widgets then --#srosen controller scrolling is a little wonky here: focus is getting placed on weird things (update & constructed)
				if self.focused_index < self.view_offset+1 then
					self.focused_index = self.view_offset+1
				elseif self.focused_index > self.view_offset+self.widgets_per_view then
					self.focused_index = self.view_offset+self.widgets_per_view
				end
			end
		end
	end

	if self.static_widgets and #self.items < #self.static_widgets and not self.always_show_static_widgets then
		for i,v in ipairs(self.static_widgets) do
			if i <= #self.items then
				v:Show()
			else
				v:Hide()
			end
		end
	elseif self.static_widgets and #self.items < #self.static_widgets and self.always_show_static_widgets then
		for i,v in ipairs(self.static_widgets) do
			if i <= #self.items then
				self.updatefn(v, self.items[i])
			else
				self.updatefn(v, nil)
			end
		end
	elseif self.static_widgets and #self.items >= #self.static_widgets then
		for i,v in ipairs(self.static_widgets) do
			v:Show()
		end
	end

	if #self.items <= self.widgets_per_view then
		self.up_button:Hide()
		self.down_button:Hide()
		self.position_marker:Hide()
		self.scroll_bar:Hide()
		self.scroll_bar_line:Hide()
	else
		self.up_button:Show()
		self.down_button:Show()
		self.position_marker:Show()
		self.scroll_bar:Show()
		self.scroll_bar_line:Show()
	end

	-- Move the marker
	if movemarker then
		local marker = self.position_marker:GetPosition()
		local newY = (self.height/2 - arrow_button_size) - (self.view_offset * self.step_size)
		if newY < -self.height/2 + arrow_button_size then
			newY = -self.height/2 + arrow_button_size
		elseif newY > self.height/2 - arrow_button_size then
			newY = self.height/2 - arrow_button_size
		end
		self.position_marker:SetPosition(marker.x, newY)
	end
end

-- skip fixup is for when there's a widget that is already adding the scroll list help text and control stuff for the update style (i.e. ListCursor)
-- focus children should be false when it's just an information list (i.e. the morgue) and there's nothing interactable in the list
-- if set to false, then we keep the focus on the scroll list so that it can handle the scroll input properly
function ScrollableList:LayOutStaticWidgets(yInitial, skipFixUp, focusChildren)
	if self.static_widgets then
		local showing = false
		self.yInitial = yInitial or 0
		local nextYPos = self.height/2 - (arrow_button_size * .5) + self.yInitial

		local numShown = 0
		for i,v in ipairs(self.static_widgets) do					
			v:SetPosition(-self.width/2 + self.x_offset, nextYPos)
			nextYPos = nextYPos - self.item_height - self.item_padding

			if not skipFixUp then
				local helptextFn = v.GetHelpText
				v.GetHelpText = function()
					local controller_id = TheInput:GetControllerID()
				    local t = {}
				    if self.scroll_bar and self.scroll_bar:IsVisible() then
				        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLBACK, false, false).."/"..TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLFWD, false, false).. " " .. STRINGS.UI.HELP.SCROLL)   
				    end
					if helptextFn then 
						table.insert(t, helptextFn())
					end
				    return table.concat(t, "  ")
				end

				local gainfocusFn = v.OnGainFocus
				v.OnGainFocus = function()
					gainfocusFn(v)
					self.focused_index = i
				end

				v:SetParentScrollList(self)
			end
		end

		if focusChildren ~= nil then
			self.focus_children = focusChildren
		end
	end
end

function ScrollableList:GetNearestStep()
	local marker = self.position_marker:GetPosition()
  	return math.floor((marker.y / self.step_size) + 0.5)
end

function ScrollableList:DoDragScroll()
	-- Near the scroll bar, keep drag-scrolling
	local marker = self.position_marker:GetWorldPosition()
	if self.dragging and math.abs(TheFrontEnd.lastx - marker.x) <= DRAG_SCROLL_X_THRESHOLD then
		local pos = self:GetWorldPosition()
		local click_y = TheFrontEnd.lasty
		local prev_step = self:GetNearestStep()
		if click_y < pos.y - self.height/2 + arrow_button_size then
			click_y = -self.height/2 + arrow_button_size
		elseif click_y > pos.y + self.height/2 - arrow_button_size then
			click_y = self.height/2 - arrow_button_size
		else
			click_y = click_y - pos.y
		end
		self.position_marker:SetPosition(self.width/2, click_y + self.y_adjustment)
		local curr_step = self:GetNearestStep()
		if curr_step ~= prev_step then
			self:Scroll(prev_step - curr_step, false)
		end
	else -- Far away from the scroll bar, revert to original pos
		local prev_step = self:GetNearestStep()
		if self.position_marker.o_pos then
			self.position_marker:SetPosition(self.position_marker.o_pos)
		end
		local curr_step = self:GetNearestStep()
		if curr_step ~= prev_step then
			self:Scroll(prev_step - curr_step, false)
		end
		self:MoveMarkerToNearestStep() 
	end
end

function ScrollableList:MoveMarkerToNearestStep()
	local y = (self.height/2 - arrow_button_size) - (self.view_offset * self.step_size)
	if y > self.height/2 - arrow_button_size then
		y = self.height/2 - arrow_button_size
	elseif y < -self.height/2 + arrow_button_size then
		y = -self.height/2 + arrow_button_size
	end
	self.position_marker:SetPosition(self.width/2, y)
end

function ScrollableList:SetScrollPerClick(amt)
	scroll_per_click = amt
end

function ScrollableList:SetScrollPerPage(amt)
	scroll_per_page = amt
end

function ScrollableList:RecalculateStepSize()
	self.widgets_per_view = math.ceil(self.height / (self.item_height + self.item_padding))
	self.max_step = math.ceil(#self.items - self.widgets_per_view)
	self.step_size = (self.height - (2*arrow_button_size)) / (#self.items - self.widgets_per_view)
	if self.view_offset and self.max_step and self.view_offset > math.abs(self.max_step) then --#srosen we want to do percentage based marker movement
		if self.max_step > 0 then
			self.view_offset = self.max_step
		else
			self.view_offset = 0
		end
	end
end

function ScrollableList:SetListItemPadding(pad)
	self.item_padding = pad
	self:RecalculateStepSize()
	self:RefreshView()
end

function ScrollableList:SetListItemHeight(ht)
	self.item_height = ht
	self:RecalculateStepSize()
	self:RefreshView()
end

function ScrollableList:SetList(list, keepitems)
	if not self.updatefn and not self.static_widgets and not keepitems then
		for k,v in ipairs(self.items) do
			v:KillAllChildren()
			v:Kill()
		end

		for i,v in ipairs(list) do
	    	self:AddChild(v)
	    end
	end

	self.items = list
	
	self:Scroll(0, true) --scroll by 0 to update the position to match the new list size
	self:RecalculateStepSize()
	self:DoFocusHookups()
	self:RefreshView(true)
end

function ScrollableList:AddItem(item, before_widget)
    self:RemoveItem(item) -- don't let an item be added in two positions!

    if before_widget ~= nil then
        local index = -1
        for i,v in ipairs(self.items) do
            if v == before_widget then
                index = i
                break
            end
        end
        table.insert(self.items, index, item)
        self:AddChild(item)
    else
        table.insert(self.items, item)
        self:AddChild(item)
    end

    self:Scroll(0, true) --scroll by 0 to update the position to match the new list size
    self:RecalculateStepSize()
    self:DoFocusHookups()
    self:RefreshView(true)
end

function ScrollableList:RemoveItem(item)
    local index = -1
    for i,v in ipairs(self.items) do
        if v == item then
            index = i
            break
        end
    end

    if index > -1 then
        table.remove(self.items, index)

        self:Scroll(0, true) --scroll by 0 to update the position to match the new list size
        self:RecalculateStepSize()
        self:DoFocusHookups()
        self:RefreshView(true)
    end
end

function ScrollableList:Clear()
	if not self.updatefn and not self.static_widgets then
		for k,v in pairs(self.items) do
			v:Kill()
		end
	end
	self.items = {}
	self:RecalculateStepSize()
	self:RefreshView(true)
end

function ScrollableList:GetNumberOfItems()
	return #self.items
end

function ScrollableList:OnGainFocus()
	ScrollableList._base.OnGainFocus(self)

	local index = 1
	-- Static table of widgets that we show and hide
	if self.items and not self.updatefn and not self.static_widgets then
		for i,v in ipairs(self.items) do
			if v.focus then
				index = i
				break
			end
		end
	elseif self.updatefn and self.static_widgets then
		for i,v in ipairs(self.static_widgets) do
			if v.focus then
				index = self.view_offset+i
				break
			end
		end
	end
	self.focused_index = index
end

function ScrollableList:OnLoseFocus()
	ScrollableList._base.OnLoseFocus(self)

	self.focused_index = 1
	-- Static table of widgets that we show and hide
	if self.items and not self.updatefn and not self.static_widgets then
		for i,v in ipairs(self.items) do
			if v.focus then
				self.focused_index = i
				break
			end
		end
	elseif self.updatefn and self.static_widgets then
		for i,v in ipairs(self.static_widgets) do
			if v.focus then
				self.focused_index = self.view_offset+i
				break
			end
		end
	end
end

function ScrollableList:SetFocus()
    local index = 1
	if self.focused_index then
		index = self.focused_index
	else
		index = index or (self.reverse and self.view_offset + self.widgets_per_view or self.view_offset+1)
		if index < 0 then
			index = index + #self.items +1 
		end
	end

	if self.updatefn and self.static_widgets then
		if self.static_widgets[index] and self.static_widgets[index].SetFocus then
			if self.focus_children then 
				self.static_widgets[index]:SetFocus() 
			else
				self.bg:SetFocus()
			end
			self.focused_index = index
		end
	else
		if self.items[index] and self.items[index].SetFocus then
			self.items[index]:SetFocus()
			self.focused_index = index
		end
	end
end

function ScrollableList:DoFocusHookups()

	-- Static table of widgets that we show and hide
	if self.items and not self.updatefn and not self.static_widgets then
		for k,v in ipairs(self.items) do
			if k > 1 then
				self.items[k]:SetFocusChangeDir(MOVE_UP, self.items[k-1])
			end		
		
			if k < #self.items then
				self.items[k]:SetFocusChangeDir(MOVE_DOWN, self.items[k+1])
			end
		end
	elseif self.updatefn and self.static_widgets then
		for k,v in ipairs(self.static_widgets) do
			if k > 1 then
				self.static_widgets[k]:SetFocusChangeDir(MOVE_UP, self.static_widgets[k-1])
			end

			if k < #self.static_widgets then
				self.static_widgets[k]:SetFocusChangeDir(MOVE_DOWN, self.static_widgets[k+1])
			end
		end
	end
end

function ScrollableList:OnFocusMove(dir, down)
	if ScrollableList._base.OnFocusMove(self,dir,down) then return true end

	if down then
		-- Static table of widgets that we show and hide
		if self.items and not self.updatefn and not self.static_widgets then

			for i,v in ipairs(self.items) do
				if v.focus then
					self.focused_index = i
					break
				end
			end

			if dir == MOVE_UP and self.focused_index > 1 then
				if self.focused_index and self.focused_index <= self.view_offset+1 then
					self:Scroll(-1, true)
					TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
					self.items[self.view_offset+1]:SetFocus()
					self.focused_index = self.focused_index - 1
				end
				return true
			elseif dir == MOVE_DOWN and self.focused_index < #self.items then
				if self.focused_index and self.focused_index >= self.view_offset+self.widgets_per_view then
					self:Scroll(1, true)
					TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
					self.items[self.view_offset+self.widgets_per_view]:SetFocus()
					self.focused_index = self.focused_index + 1
				end
				return true
			end

		elseif self.updatefn and self.static_widgets then

			for i,v in ipairs(self.static_widgets) do
				if v.focus then
					self.focused_index = i
					break
				end
			end

			if dir == MOVE_UP and self.focused_index == 1 and self.view_offset > 0 then
				self:Scroll(-1, true)
				TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
				self.static_widgets[1]:SetFocus()
				self.focused_index = self.focused_index - 1 + self.view_offset
				return true
			elseif dir == MOVE_DOWN and self.focused_index == #self.static_widgets and ((self.view_offset + #self.static_widgets) < #self.items) then
				self:Scroll(1, true)
				TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
				self.static_widgets[#self.static_widgets]:SetFocus()
				self.focused_index = self.focused_index + 1 + self.view_offset
				return true
			end
		end
	end
	return false
end

function ScrollableList:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
	if self.scroll_bar and self.scroll_bar:IsVisible() then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLBACK, false, false).."/"..TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLFWD, false, false).. " " .. STRINGS.UI.HELP.SCROLL)
	end
	return table.concat(t, "  ")
end

function ScrollableList:ScrollToEnd()
	if self.scroll_bar and self.scroll_bar:IsVisible() then
		self:Scroll(self:GetNumberOfItems(), true)
	end
end

return ScrollableList
