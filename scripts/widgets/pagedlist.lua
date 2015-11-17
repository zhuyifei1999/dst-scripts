local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"

-------------------------------------------------------------------------------------------------------

-- This is based on ScrollableList. Like Scrollable list, it takes a pre-built list of static widgets and a list of data to update those widgets with.
-- Unlike Scrollable list, it always updates all the widgets at once (page by page) instead of one row at a time.

-- Items should be a list of data items to pass to updatefn
-- widgetstoupdate should be a static set of widgets that get updated by updatefn
-- Itemheight and itempadding are used to place the widgets (note: for a grid, each widget should be one row in the grid)
local PagedList = Class(Widget, function(self, items, itemwidth, itemheight, itempadding, updatefn, widgetstoupdate, evaluateArrows)
    Widget._ctor(self, "ScrollBar")
  
    self.items = {}
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

    self.bg = self:AddChild(Image("images/ui.xml", "blank.tex")) -- so that we have focus whenever the mouse is over this thing
    self.bg:ScaleToSize(self.width, self.height) -- TODO: fix this
   
    self.items = items
    if updatefn and widgetstoupdate then
    	self.updatefn = updatefn
    	self.static_widgets = widgetstoupdate
    else
	    assert("PagedList requires static widgets and an update function")
	end

	self.page_number = 1
   	self.num_pages = math.max(1, math.ceil(#self.items/self.items_per_page))

   	self.evaluate_arrows = evaluateArrows

    -- set the positions of the static_widgets
    -- (the list is built from the top down)
    local offset = 0
	for i = 1, self.num_rows do 
		self.static_widgets[i]:SetPosition(0, offset)
		offset = offset - (self.item_height + self.item_padding)
	end

	if self.num_pages > 1 then 
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
	end

	self:DoFocusHookups()

    self:RefreshView()
end)

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

function PagedList:EvaluateArrows()
	if not self.evaluate_arrows then return end

	-- Buttons aren't created if there's only one page, so check that they exist 
	-- before accessing them.
	if self.right_button then 
		if self.page_number == self.num_pages then
			self.right_button:Hide()
			self.right_button:Disable()
		else
			self.right_button:Show()
			self.right_button:Enable()
		end
	end

	if self.left_button then 
		if self.page_number == 1 then
			self.left_button:Hide()
			self.left_button:Disable()
		else
			self.left_button:Show()
			self.left_button:Enable()
		end
	end
end

function PagedList:RefreshView()

	-- figure out which set of data we're using
	local start_index = ((self.page_number - 1) * self.items_per_page)

	
	-- call updatefn for each 
	for i = 1, self.num_rows do 
		if self.items[start_index + i] then 
			self.updatefn(self.static_widgets[i], self.items[start_index + i])
			self.static_widgets[i]:Show()
		else
			self.updatefn(self.static_widgets[i], {})
			self.static_widgets[i]:Show()
		end
	end

	self:EvaluateArrows()

	self.focused_widget = self:GetFocusedWidget() or nil
	if self.focused_widget then 
		self.focused_widget:ClearFocus()
		self.focused_widget:SetFocus()
	end

end

function PagedList:OnControl(control, down)
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

        if k < #self.items then
            self.static_widgets[k]:SetFocusChangeDir(MOVE_DOWN, self.static_widgets[k+1])
        end
    end

end

function PagedList:GetFocusedWidget()
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


return PagedList

