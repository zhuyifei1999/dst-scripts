local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local ThreeSlice = require "widgets/threeslice"
local ControllerVoteScreen = require "screens/controllervotescreen"

VOTE_DIALOG_X_OFFSET = 350
VOTE_ROOT_SCALE = 0.75
local VoteDialog = Class(Widget, function(self)
    Widget._ctor(self, "VoteDialog")

    self.root = self:AddChild(Widget("root"))
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_TOP)
    self.root:SetScale(VOTE_ROOT_SCALE, VOTE_ROOT_SCALE, 1)
    
    self.bg = self.root:AddChild(ThreeSlice("images/ui.xml", "votewindow_top.tex", "votewindow_middle.tex", "votewindow_bottom.tex"))
    self.bg:SetScale(1, 1, 1)
    self.bg:SetPosition(0, 0)
    
    self.title = self.root:AddChild(Text(BUTTONFONT, 35))
    self.title:SetColour(0, 0, 0, 1)
    self.title:EnableWordWrap(true)
    self.title:SetRegionSize( 195, 95 ) --set to fit the votewindow_top.tex resolution
        
    self.left_bar = self.root:AddChild(Image("images/ui.xml", "scrollbarline.tex"))
    self.left_bar:SetPosition(-75, 200)
    self.left_bar:SetTint(0, 0, 0, 1)
    self.left_bar:SetScale(1.5,1,1)
    self.left_bar:MoveToBack()
    
    self.right_bar = self.root:AddChild(Image("images/ui.xml", "scrollbarline.tex"))
    self.right_bar:SetPosition(75, 200)
    self.right_bar:SetTint(0, 0, 0, 1)
    self.right_bar:SetScale(-1.5,1,1)
    self.right_bar:MoveToBack()
    
    self.options_root = self.root:AddChild(Widget("root"))

	self:Hide()
    
    self.inst:ListenForEvent("showvotedialog", function() self:ShowDialog() end, TheWorld)
    self.inst:ListenForEvent("hidevotedialog", function() self:HideDialog() end, TheWorld)
    self.inst:ListenForEvent("vote_screen_closed", function() self:ControllerVoteClosed() end, TheWorld)

	if TheWorld.net.components.voter:GetShowDialog() then
		self:ShowDialog()
	end
end)

DROP_SPEED = -400
DROP_ACCEL = 750
UP_ACCEL = 2000
BOUNCE_ABSORB = 0.25
SETTLE_SPEED = 25
function VoteDialog:OnUpdate(dt)
    if self.started then
		if not self.settled then
			self.current_speed = self.current_speed - DROP_ACCEL * dt
			self.current_root_y_pos = self.current_root_y_pos + self.current_speed * dt
			if self.current_root_y_pos < self.target_root_y_pos then
				self.current_speed = -self.current_speed * BOUNCE_ABSORB
				if self.current_speed < SETTLE_SPEED then
					self.settled = true
				end
				self.current_root_y_pos = self.target_root_y_pos
			end
			self.root:SetPosition(Vector3(VOTE_DIALOG_X_OFFSET, self.current_root_y_pos, 0))
		end
	elseif self.current_root_y_pos < self.start_root_y_pos then
		self.current_speed = self.current_speed + UP_ACCEL * dt
		self.current_root_y_pos = self.current_root_y_pos + self.current_speed * dt
		self.root:SetPosition(Vector3(VOTE_DIALOG_X_OFFSET, self.current_root_y_pos, 0))
    else
		self:StopUpdating()
		self:Hide()
    end

	if not self.showing_controller_prompt then
		local option_data = TheWorld.net.components.voter:GetOptionData()
  		for option_index = 1,option_data.num_options,1 do
			local option = option_data.options[option_index]
			local vote_end_str = ""
			if option.vote_count > 0 then
				vote_end_str = " ("..tostring(option.vote_count)..")"
			end
			self.labels_desc[option_index]:SetString(option.description .. vote_end_str )
		end
	end
	self.timer:SetString("Time Remaining: " .. string.format("%d",TheWorld.net.components.voter:GetTimer()).."s" )
	
	if self.started and self.showing_controller_prompt and not self.showing_controller_screen then
		if TheInput:IsControlPressed(CONTROL_INSPECT) then
			self.reset_hold_time = self.reset_hold_time + dt
			if self.reset_hold_time > 2 then
				self:ShowControllerDialog()
			end
		else
			self.reset_hold_time = 0
		end
	end
end

function VoteDialog:ControllerVoteClosed()
	self.showing_controller_screen = false
end

function VoteDialog:EnableButtons(enable, selected_index)
	if not enable then
		self.buttons[selected_index]:SetTextures( "images/ui.xml", "checkbox_on.tex", "checkbox_on_disabled.tex", "checkbox_on_disabled.tex", "checkbox_on.tex" )
	end
	for _,button in pairs(self.buttons) do
		if enable then
			button:Show()
		else
			button:Disable()
		end
	end
end

function VoteDialog:ShowControllerDialog()
	self.showing_controller_screen = true
	
	--push new controller screen
    TheFrontEnd:PushScreen(ControllerVoteScreen())
end

function VoteDialog:ShowDialog()
    self.started = true
    self.settled = false
    self:StartUpdating()
    self:Show()
        
    self.options_root:KillAllChildren()
    
	local option_data = TheWorld.net.components.voter:GetOptionData()
    if TheInput:ControllerAttached() then
		self.bg:SetImages("images/ui.xml", "votewindow_top.tex", "votewindow_middle.tex", "votewindow_controll_bottom.tex")
		self.bg:ManualFlow(0)
		
		self.current_speed = DROP_SPEED
		self.start_root_y_pos = (self.bg.end_cap_size) * VOTE_ROOT_SCALE
		self.current_root_y_pos = self.start_root_y_pos
		self.target_root_y_pos = (-self.bg.start_cap_size) * VOTE_ROOT_SCALE - 20
		self.root:SetPosition(Vector3(VOTE_DIALOG_X_OFFSET, self.current_root_y_pos, 0))
		
		self.title:SetPosition(0, self.bg.start_cap_size*0.38, 0)
		self.title:SetString( option_data.title )
		
		self.timer = self.options_root:AddChild(Text(BUTTONFONT, 35))
		self.timer:SetColour(0, 0, 0, 1)
		
		self.instruction = self.options_root:AddChild(Text(UIFONT, 35))
		self.instruction:SetString("Hold "..TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_INSPECT).." to vote.")
		local x,y = self.instruction:GetRegionSize()
		if x > 195 then
			self.instruction:EnableWordWrap(true)
			self.instruction:SetRegionSize( 195, 95 )
			
			self.timer:SetPosition(0, -self.bg.end_cap_size * 0.12, 0)
			self.instruction:SetPosition(3, -self.bg.end_cap_size * 0.50, 0)
		else
			self.timer:SetPosition(0, -self.bg.end_cap_size * 0.2, 0)
			self.instruction:SetPosition(3, -self.bg.end_cap_size * 0.5, 0)
		end
    
		self.showing_controller_prompt = true
		self.showing_controller_screen = false
    else
		self.bg:SetImages("images/ui.xml", "votewindow_top.tex", "votewindow_middle.tex", "votewindow_bottom.tex")
		self.bg:ManualFlow(option_data.num_options)
	    
		local fill_dist = option_data.num_options * self.bg.filler_size
	    
		self.current_speed = DROP_SPEED
		self.start_root_y_pos = (fill_dist/2 + self.bg.end_cap_size) * VOTE_ROOT_SCALE
		self.current_root_y_pos = self.start_root_y_pos
		self.target_root_y_pos = (-fill_dist/2 - self.bg.start_cap_size) * VOTE_ROOT_SCALE - 20
		self.root:SetPosition(Vector3(VOTE_DIALOG_X_OFFSET, self.current_root_y_pos, 0))
	    
		self.title:SetPosition(0, self.bg.start_cap_size*0.38 + (self.bg.filler_size * option_data.num_options)/2, 0)
		self.title:SetString( option_data.title )
	    
	    
		self.buttons = {}
		self.labels_count = {}
		self.labels_desc = {}
		for option_index = 1,option_data.num_options,1 do
			local option = option_data.options[option_index]

			self.labels_desc[option_index] = self.options_root:AddChild(Text(BUTTONFONT, 35)) 
			self.labels_desc[option_index]:SetPosition(-14,fill_dist/2 - self.bg.filler_size*(option_index-1+.5)-2,0 )
			self.labels_desc[option_index]:SetString(option.description)
			self.labels_desc[option_index]:SetColour(0, 0, 0, 1)
			self.labels_desc[option_index]:SetScale(.8)
			
			self.buttons[option_index] = self.options_root:AddChild(ImageButton("images/ui.xml", "checkbox_off.tex", "checkbox_off_highlight.tex", "checkbox_off_disabled.tex", "checkbox_off.tex", nil, {1,1}, {0,0}))
			self.buttons[option_index]:SetFont(BUTTONFONT)
			local closure_index = option_index
			self.buttons[option_index]:SetOnClick(function() self:EnableButtons(false, closure_index) TheWorld.net.components.voter:ReceivedVote( ThePlayer, closure_index ) end)
			self.buttons[option_index]:SetText("")
			self.buttons[option_index]:SetPosition(75,fill_dist/2 - self.bg.filler_size*(option_index-1+.5) - 5,0 )
			self.buttons[option_index]:SetScale(1.2)
		end
		
		self:EnableButtons(true)
		
		self.timer = self.options_root:AddChild(Text(BUTTONFONT, 35))
		self.timer:SetColour(0, 0, 0, 1)
		self.timer:SetPosition(0, -self.bg.end_cap_size * 0.42 -(self.bg.filler_size * option_data.num_options)/2, 0)
		self.timer:SetString("time")
		
		self.showing_controller_screen = false
		self.showing_controller_prompt = false
	end
end

function VoteDialog:HideDialog()
    self.started = false
    self.current_speed = 0
end


return VoteDialog