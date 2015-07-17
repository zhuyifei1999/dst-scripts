local Screen = require "widgets/screen"
local Button = require "widgets/button"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local ThreeSlice = require "widgets/threeslice"

local ControllerVoteScreen = Class(Screen, function(self)
	Screen._ctor(self, "ControllerVoteScreen")

	--darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)
    

	local option_data = TheWorld.net.components.voter:GetOptionData()

	self.controller_bg = self:AddChild(ThreeSlice("images/ui.xml", "votewindow_top.tex", "votewindow_middle.tex", "votewindow_bottom.tex"))
	self.controller_bg:SetScale(1.2, 1.2, 1.2)
	self.controller_bg:SetPosition(0, 0)
	self.controller_bg:SetHAnchor(ANCHOR_MIDDLE)
	self.controller_bg:SetVAnchor(ANCHOR_MIDDLE)
	self.controller_bg:ManualFlow(option_data.num_options)
	self.controller_bg:Show()
	    
    local fill_dist = option_data.num_options * self.controller_bg.filler_size
	 	
	self.controller_title = self.controller_bg:AddChild(Text(BUTTONFONT, 35))
	self.controller_title:SetColour(0, 0, 0, 1)
	self.controller_title:EnableWordWrap(true)
	self.controller_title:SetRegionSize( 195, 95 ) --set to fit the votewindow_top.tex resolution
	self.controller_title:SetPosition(0, self.controller_bg.start_cap_size*0.38 + (self.controller_bg.filler_size * option_data.num_options)/2, 0)
	self.controller_title:SetString( option_data.title )
		
		
	self.buttons = {}
	self.labels_count = {}
	self.labels_desc = {}
	for option_index = 1,option_data.num_options,1 do
		local option = option_data.options[option_index]

		self.labels_desc[option_index] = self.controller_bg:AddChild(Text(BUTTONFONT, 35)) 
		self.labels_desc[option_index]:SetPosition(-14,fill_dist/2 - self.controller_bg.filler_size*(option_index-1+.5)-2,0 )
		self.labels_desc[option_index]:SetString(option.description)
		self.labels_desc[option_index]:SetColour(0, 0, 0, 1)
		self.labels_desc[option_index]:SetScale(.8)
		
		self.buttons[option_index] = self.controller_bg:AddChild(ImageButton("images/ui.xml", "checkbox_off.tex", "checkbox_off_highlight.tex", "checkbox_off_disabled.tex", "checkbox_off.tex", nil, {1,1}, {0,0}))
		self.buttons[option_index]:SetFont(BUTTONFONT)
		local closure_index = option_index
		self.buttons[option_index]:SetOnClick(function() self:EnableButtons(false, closure_index) TheWorld.net.components.voter:ReceivedVote( ThePlayer, closure_index ) end)
		self.buttons[option_index]:SetText("")
		self.buttons[option_index]:SetPosition(75,fill_dist/2 - self.controller_bg.filler_size*(option_index-1+.5) - 5,0 )
		self.buttons[option_index]:SetScale(1.2)
	end
	
	for option_index = 1,option_data.num_options,1 do
		if option_index == 1 then
			self.buttons[1]:SetFocusChangeDir(MOVE_UP, self.buttons[option_data.num_options])
			self.buttons[1]:SetFocusChangeDir(MOVE_DOWN, self.buttons[2])
		elseif option_index == option_data.num_options then
			self.buttons[option_data.num_options]:SetFocusChangeDir(MOVE_UP, self.buttons[option_data.num_options-1])
			self.buttons[option_data.num_options]:SetFocusChangeDir(MOVE_DOWN, self.buttons[1])
		else
			self.buttons[option_index]:SetFocusChangeDir(MOVE_UP, self.buttons[option_index-1])
			self.buttons[option_index]:SetFocusChangeDir(MOVE_DOWN, self.buttons[option_index+1])
		end
	end
	
	self:EnableButtons(true)
	
	self.timer = self.controller_bg:AddChild(Text(BUTTONFONT, 35))
	self.timer:SetColour(0, 0, 0, 1)
	self.timer:SetPosition(0, -self.controller_bg.end_cap_size * 0.42 -(self.controller_bg.filler_size * option_data.num_options)/2, 0)
	self.timer:SetString("time")
	
	
	self.default_focus = self.buttons[1]
	self.buttons[1]:SetFocus()
	
    self.inst:ListenForEvent("hidevotedialog", function() self:Close() end, TheWorld)
    self:StartUpdating()
end)

function ControllerVoteScreen:EnableButtons(enable, selected_index)
	if not enable then
		self.buttons[selected_index]:SetTextures( "images/ui.xml", "checkbox_on.tex", "checkbox_on_disabled.tex", "checkbox_on_disabled.tex", "checkbox_on.tex" )
		TheWorld:PushEvent("hidevotedialog")
		self:Close()
	end
	for _,button in pairs(self.buttons) do
		if enable then
			button:Show()
		else
			button:Disable()
		end
	end
end

function ControllerVoteScreen:OnUpdate(dt)
	local option_data = TheWorld.net.components.voter:GetOptionData()
    
	for option_index = 1,option_data.num_options,1 do
		local option = option_data.options[option_index]
		local vote_end_str = ""
		if option.vote_count > 0 then
			vote_end_str = " ("..tostring(option.vote_count)..")"
		end
		self.labels_desc[option_index]:SetString(option.description .. vote_end_str )
	end
	self.timer:SetString("Time Remaining: " .. string.format("%d",TheWorld.net.components.voter:GetTimer()).."s" )
end

function ControllerVoteScreen:OnControl(control, down)
    if ControllerVoteScreen._base.OnControl(self,control, down) then return true end
    
    if control == CONTROL_CANCEL and not down then
		--self.buttons[#self.buttons].cb()
		self:Close()
		return true
    end
end


function ControllerVoteScreen:Close()
	TheWorld:PushEvent("vote_screen_closed")
	TheFrontEnd:PopScreen(self)
end

function ControllerVoteScreen:GetHelpText()
	local controller_id = TheInput:GetControllerID()
	local t = {}
	if #self.buttons > 1 and self.buttons[#self.buttons] then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
    end
	return table.concat(t, "  ")
end

return ControllerVoteScreen