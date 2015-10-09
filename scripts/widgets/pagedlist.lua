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
		self.left_button = self:AddChild(ImageButton("images/ui.xml", "arrow2_left.tex", "arrow2_left.tex", "arrow2_left.tex", nil, nil, {1,1}, {0,0}))
	    self.left_button:SetPosition(-50, offset + self.item_padding + self.item_height/2, 0)
	    self.left_button:SetScale(.33)

	    self.left_button:SetOnClick( function()
	    	self:ChangePage(-1)
	    end)
	  
		self.right_button = self:AddChild(ImageButton("images/ui.xml", "arrow2_right.tex", "arrow2_right.tex", "arrow2_right.tex", nil, nil, {1,1}, {0,0}))
	    self.right_button:SetPosition(self.width+50, offset + self.item_padding + self.item_height/2, 0)
	    self.right_button:SetScale(.33)
	    self.right_button:SetOnClick( function()
	    	self:ChangePage(1)
	    end)
	end

	--self:DoFocusHookups()

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
		else
			self.right_button:Show()
		end
	end

	if self.left_button then 
		if self.page_number == 1 then
			self.left_button:Hide()
		else
			self.left_button:Show()
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

end

return PagedList

