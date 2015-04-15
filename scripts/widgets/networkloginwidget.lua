local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local NetworkLoginWidget = Class(Widget, function(self)
	Widget._ctor(self, "NetworkLoginWidget")
	self.initialized = false
	
	self:StartUpdating()
end)

function NetworkLoginWidget:OnUpdate(dt)
	
	if self.initialized == false then
		local local_message_widget_bg = self:AddChild( Image() )
		local_message_widget_bg:SetTexture( "images/ui.xml", "black.tex" )
		local_message_widget_bg:SetPosition( 100, 60)
		local_message_widget_bg:ScaleToSize( 140, 40)
		local_message_widget_bg:SetTint(1,1,1,0.5)

		local local_message_widget = self:AddChild(Text(UIFONT, 33))
		local_message_widget:SetPosition(115, 60)
		-- local_message_widget:SetRegionSize( 130, 44 )
		local_message_widget:SetHAlign(ANCHOR_LEFT)
		local_message_widget:SetVAlign(ANCHOR_BOTTOM)
		local_message_widget:SetString(STRINGS.UI.NOTIFICATION.LOGIN)
	
		self.message_widget = local_message_widget
		self.message_widget_bg = local_message_widget_bg
	    self.time = 0
	    self.progress = 0
		self.initialized = true	    
	end
	
	local account_manager = TheFrontEnd:GetAccountManager()
	local has_token = account_manager:HasAuthToken()
	local isWaiting = account_manager:IsWaitingForResponse() 
	if not has_token or isWaiting then
		self:Show()
	    self.time = self.time + dt
	    if self.time > 0.75 then
	        self.progress = self.progress + 1
	        if self.progress > 3 then
	            self.progress = 1
	        end
    	    
	        local text = STRINGS.UI.NOTIFICATION.LOGIN
	        for k = 1, self.progress, 1 do
	            text = text .. "."
	        end
            self.message_widget:SetString(text)
	        self.time = 0
	    end
	else	
	    self:Hide()
	    self:StopUpdating()
	end
		
end

return NetworkLoginWidget
