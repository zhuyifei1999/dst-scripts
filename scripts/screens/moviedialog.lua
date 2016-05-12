local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Video = require "widgets/video"

local MovieDialog = Class(Screen, function(self, movie_path, callback)
	Screen._ctor(self, "MovieDialog")
	
    self.cb = callback
	
	self.fixed_root = self:AddChild(Widget("root"))
    self.fixed_root:SetVAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetHAnchor(ANCHOR_MIDDLE)
    self.fixed_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.dark_card = self.fixed_root:AddChild(Image("images/global.xml", "square.tex"))
    self.dark_card:SetVRegPoint(ANCHOR_MIDDLE)
    self.dark_card:SetHRegPoint(ANCHOR_MIDDLE)
    self.dark_card:SetVAnchor(ANCHOR_MIDDLE)
    self.dark_card:SetHAnchor(ANCHOR_MIDDLE)
    self.dark_card:SetTint(0,0,0,1)
    self.dark_card:SetScaleMode(SCALEMODE_FILLSCREEN)
	
	self.video = self.fixed_root:AddChild(Video("video"))
	self.video:Load( movie_path )
	self.video:SetSize( RESOLUTION_X, RESOLUTION_Y )
	self.video:Play()
end)



function MovieDialog:OnUpdate( dt )
	if self.video:IsDone() then
		TheFrontEnd:PopScreen()
		TheFrontEnd:DoFadeIn(2)
        if self.cb ~= nil then
            self.cb()
        end
	end
	return true
end

function MovieDialog:OnControl(control, down)
	if down then
		if control == CONTROL_PAUSE then
			self.video:Stop()
		elseif control == CONTROL_ACTION then
			self.video:Pause()
		end
	end
end

return MovieDialog