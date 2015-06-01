local Screen = require "widgets/screen"
local MAX_HUD_SCALE = 1.25

local MapWidget = require("widgets/mapwidget")
local Widget = require "widgets/widget"
local MapControls = require "widgets/mapcontrols"
local HudCompass = require "widgets/hudcompass"

local MapScreen = Class(Screen, function(self, owner)
    self.owner = owner
	Screen._ctor(self, "MapScreen")
	self.minimap = self:AddChild(MapWidget(self.owner))    
	
	self.bottomright_root = self:AddChild(Widget("br_root"))

    self.bottomright_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.bottomright_root:SetHAnchor(ANCHOR_RIGHT)
    self.bottomright_root:SetVAnchor(ANCHOR_BOTTOM)
    self.bottomright_root:SetMaxPropUpscale(MAX_HUD_SCALE)
	self.bottomright_root = self.bottomright_root:AddChild(Widget("br_scale_root"))
	

	local scale = TheFrontEnd:GetHUDScale()
    self.bottomright_root:SetScale(scale)

    if not TheInput:ControllerAttached() then
	    self.mapcontrols = self.bottomright_root:AddChild(MapControls())
	    self.mapcontrols:SetPosition(-60,70,0)
	    self.mapcontrols.pauseBtn:Hide()
    end	    

    self.hudcompass = self.bottomright_root:AddChild(HudCompass(self.owner, false))
    self.hudcompass:SetPosition(-160,70,0)

	self.repeat_time = 0

end)

function MapScreen:OnBecomeInactive()
    MapScreen._base.OnBecomeInactive(self)

    if TheWorld.minimap.MiniMap:IsVisible() then
        TheWorld.minimap.MiniMap:ToggleVisibility()
    end
    --V2C: Don't set pause in multiplayer, all it does is change the
    --     audio settings, which we don't want to do now
    --SetPause(false)
end

function MapScreen:OnBecomeActive()
    MapScreen._base.OnBecomeActive(self)

    if not TheWorld.minimap.MiniMap:IsVisible() then
        TheWorld.minimap.MiniMap:ToggleVisibility()
    end
    self.minimap:UpdateTexture()
    --V2C: Don't set pause in multiplayer, all it does is change the
    --     audio settings, which we don't want to do now
    --SetPause(true)
end

function MapScreen:OnUpdate(dt)
	local s = -100 -- now per second, not per repeat
	
	if TheInput:IsControlPressed(CONTROL_MOVE_LEFT) then
		self.minimap:Offset( -s * dt, 0 )
	elseif TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)then
		self.minimap:Offset( s * dt, 0 )
	end
	
	if TheInput:IsControlPressed(CONTROL_MOVE_DOWN)then
		self.minimap:Offset( 0, -s * dt )
	elseif TheInput:IsControlPressed(CONTROL_MOVE_UP)then
		self.minimap:Offset( 0, s * dt)
	end

	if self.repeat_time <= 0 then
		if TheInput:IsControlPressed(CONTROL_MAP_ZOOM_IN ) then
			self.minimap:OnZoomIn()
		elseif TheInput:IsControlPressed(CONTROL_MAP_ZOOM_OUT ) then
			self.minimap:OnZoomOut()
		end
		
		self.repeat_time = .025
		
	else
		self.repeat_time = self.repeat_time - dt
	end
end

function MapScreen:OnControl(control, down)
	if MapScreen._base.OnControl(self, control, down) then return true end

	if not down and (control == CONTROL_MAP or control == CONTROL_CANCEL) then
		TheFrontEnd:PopScreen()
		return true
	end


	if not down then return false end
	if not self.shown then return false end
	
	if control == CONTROL_ROTATE_LEFT and ThePlayer and ThePlayer.components.playercontroller then
		ThePlayer.components.playercontroller:RotLeft()
	elseif control == CONTROL_ROTATE_RIGHT and ThePlayer and ThePlayer.components.playercontroller then
		ThePlayer.components.playercontroller:RotRight()
	elseif control == CONTROL_MAP_ZOOM_IN then
		self.minimap:OnZoomIn()
		self.repeat_time = .025
	elseif control == CONTROL_MAP_ZOOM_OUT then
		self.minimap:OnZoomOut()
		self.repeat_time = .025
	else
		return false
	end
	return true

end


function MapScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}
    
   	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_ROTATE_LEFT) .. " " .. STRINGS.UI.HELP.ROTATE_LEFT)
   	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_ROTATE_RIGHT) .. " " .. STRINGS.UI.HELP.ROTATE_RIGHT)
   	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_MAP_ZOOM_IN) .. " " .. STRINGS.UI.HELP.ZOOM_IN)
   	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_MAP_ZOOM_OUT) .. " " .. STRINGS.UI.HELP.ZOOM_OUT)
	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    return table.concat(t, "  ")
end

return MapScreen
