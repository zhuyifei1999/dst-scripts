local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"


local SCROLL_REPEAT_TIME = .15
local MOUSE_SCROLL_REPEAT_TIME = 0

-------------------------------------------------------------------------------------------------------

-- This is based on ScrollableList. Like Scrollable list, it takes a pre-built list of static widgets and a list of data to update those widgets with.
-- Unlike Scrollable list, it always updates all the widgets at once (page by page) instead of one row at a time.

-- Items should be a list of data items to pass to updatefn
-- widgetstoupdate should be a static set of widgets that get updated by updatefn
-- Itemheight and itempadding are used to place the widgets (note: for a grid, each widget should be one row in the grid)
local PagedList = Class(Widget, function(self, itemwidth, itemheight, itempadding, updatefn, widgetstoupdate)
    Widget._ctor(self, "PagedList")
  
    self.item_height = itemheight or 40
    self.item_padding = itempadding or 10
    self.always_show_static_widgets = true
    self.focused_index = 1
    self.focus_children = true

    self.static_widgets = widgetstoupdate

    self.num_rows = #widgetstoupdate
    self.height = (self.item_height + self.item_padding) * self.num_rows
    self.width =  itemwidth

    self.items_per_page = self.num_rows

    if updatefn and widgetstoupdate then
    	self.updatefn = updatefn
    	self.static_widgets = widgetstoupdate
    else
	    assert("PagedList requires static widgets and an update function")
	end

	self.page_number = 1

   	self.repeat_time = (TheInput:ControllerAttached() and SCROLL_REPEAT_TIME) or MOUSE_SCROLL_REPEAT_TIME

    -- set the positions of the static_widgets
    -- (the list is built from the top down)
    local offset = 0
	for i = 1, self.num_rows do 
		self.static_widgets[i]:SetPosition(0, offset)
		offset = offset - (self.item_height + self.item_padding)
	end
	
	
	self.left_button = self:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_L.tex", "DSTMenu_PlayerLobby_arrow_paperHL_L.tex", nil, nil, nil, {1,1}, {0,0}))
	self.left_button:SetPosition(-80, offset + .5*self.height - .5*self.item_padding + .5*self.item_height, 0)
	self.left_button:SetScale(.55)
	self.left_button:SetOnClick( function()
		self:ChangePage(-1)
	end)

	self.right_button = self:AddChild(ImageButton("images/lobbyscreen.xml", "DSTMenu_PlayerLobby_arrow_paper_R.tex", "DSTMenu_PlayerLobby_arrow_paperHL_R.tex", nil, nil, nil, {1,1}, {0,0}))
	self.right_button:SetPosition(self.width+78, offset + .5*self.height + .5*self.item_height - .5*self.item_padding, 0) --- self.item_padding/2, 0)
	self.right_button:SetScale(.55)
	self.right_button:SetOnClick( function()
		self:ChangePage(1)
	end)
		

	--self.default_focus = self.static_widgets[1]
	self:SetItemsData(nil) --initialize with no data
	
	self:DoFocusHookups()
	
    self:StartUpdating()
end)

function PagedList:SetItemsData(items)
	self.items = items or {}
   	self.num_pages = math.max(1, math.ceil(#self.items/self.items_per_page))   	
 	self:ChangePage(0)
end

function PagedList:OnUpdate(dt)
	if self.repeat_time > -.01 then
        self.repeat_time = self.repeat_time - dt
    end
end

function PagedList:ChangePage(dir)
	if dir > 0 then 
		self.page_number = self.page_number + 1
	elseif dir < 0 then 
		self.page_number = self.page_number - 1
	end

	if self.page_number < 1 then 
		self.page_number = 1
	end

	if self.page_number > self.num_pages then 
		self.page_number = self.num_pages
	end

	self:RefreshView()
end

function PagedList:SetPage(page)
	if page and page > 0 and page <= self.num_pages then 
		self.page_number = page
	end

	self:RefreshView()
end

function PagedList:EvaluateArrows()
	--show both then hide them if needed
	self.left_button:Show()
	self.left_button:Enable()
	self.right_button:Show()
	self.right_button:Enable()
			
	--if no pages, hide both, otherwise just hide the one at the ends
	if self.num_pages < 2 then
		self.left_button:Hide()
		self.left_button:Disable()
		self.right_button:Hide()
		self.right_button:Disable()
	else
		if self.page_number == self.num_pages then
			self.right_button:Hide()
			self.right_button:Disable()
		elseif self.page_number == 1 then
			self.left_button:Hide()
			self.left_button:Disable()
		end
	end
end

function PagedList:RefreshView()
	-- figure out which set of data we're using
	local start_index = ((self.page_number - 1) * self.items_per_page)

	-- call updatefn for each 
	for i = 1, self.num_rows do 
		if self.items[start_index + i] then 
			self.updatefn(self.static_widgets[i], self.items[start_index + i], start_index + i)
			self.static_widgets[i]:Show()
		else
			self.updatefn(self.static_widgets[i], {})
			self.static_widgets[i]:Show()
		end
	end

	self:EvaluateArrows()

	self.focused_widget = self:GetFocusedWidget() or nil
	if self.focused_widget and TheInput:ControllerAttached() then 
		self.focused_widget:SetFocus()
		if self.focused_widget.ForceFocus then 
			self.focused_widget:ForceFocus()
		end
	end
end

function PagedList:OnControl(control, down)
	--print("PagedList got control", control, down)

	if PagedList._base.OnControl(self, control, down) then return true end
end

function PagedList:GetHelpText()
	local controller_id = TheInput:GetControllerID()

	local t = {}
	if self.left_button and self.left_button:IsEnabled() then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PREVVALUE, false, false) .. " " .. STRINGS.UI.HELP.PREVPAGE)
	end

	if self.right_button and self.right_button:IsEnabled() then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_NEXTVALUE, false, false) .. " " .. STRINGS.UI.HELP.NEXTPAGE)
	end
	
	return table.concat(t, "  ")
end


function PagedList:DoFocusHookups()
    
    for k,v in ipairs(self.static_widgets) do

        if k > 1 then
            self.static_widgets[k]:SetFocusChangeDir(MOVE_UP, self.static_widgets[k-1])
        end

        if k < #self.static_widgets then
            self.static_widgets[k]:SetFocusChangeDir(MOVE_DOWN, self.static_widgets[k+1])
        end
    end

end

function PagedList:GetFocusedWidget()
	self.focused_index = 1
	for i,v in ipairs(self.static_widgets) do
		if v.focus then
			self.focused_index = i
			break
		end
	
	end

	return self.static_widgets[self.focused_index]
end

function PagedList:OnFocusMove(dir, down)
	--print("**** PagedList got focus move", dir, down)
	if PagedList._base.OnFocusMove(self,dir,down) then return true end

	if down then
		self:GetFocusedWidget() -- sets the focused_index

		if dir == MOVE_UP and self.focused_index > 1 then
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
			self.static_widgets[self.focused_index -1]:SetFocus()
			self.focused_index = self.focused_index - 1
			return true
		elseif dir == MOVE_DOWN and self.focused_index < #self.static_widgets then
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
			self.static_widgets[self.focused_index + 1]:SetFocus()
			self.focused_index = self.focused_index + 1
			return true
		end
	end

end

function PagedList:ForceFocus()
	self.focused_index = 1
	self.focused_widget = self.static_widgets[1] or nil
	if self.focused_widget and TheInput:ControllerAttached() then 
		self.focused_widget:SetFocus()
		if self.focused_widget.ForceFocus then 
			self.focused_widget:ForceFocus()
		end
	end
end

--[[function PagedList:OnGainFocus()
	print(self, "****PageList OnGainFocus", debugstack())
end

function PagedList:OnLoseFocus()
	print(self, "****PageList OnLoseFocus")
end]]

return PagedList

