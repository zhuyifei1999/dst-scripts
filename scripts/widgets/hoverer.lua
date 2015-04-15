local Text = require "widgets/text"
local Widget = require "widgets/widget"

local YOFFSETUP = -80
local YOFFSETDOWN = -50
local XOFFSET = 10

local SHOW_DELAY = 0 --10

local HoverText = Class(Widget, function(self, owner)
    Widget._ctor(self, "HoverText")
    self.owner = owner
    self.isFE = false
    self:SetClickable(false)
    --self:MakeNonClickable()
    self.text = self:AddChild(Text(UIFONT, 30))
    self.text:SetPosition(0, 40, 0)
    self.secondarytext = self:AddChild(Text(UIFONT, 30))
    self.secondarytext:SetPosition(0, -30, 0)
    self:FollowMouseConstrained()
    self:StartUpdating()
    self.lastStr = "";
    self.strFrames = 0;
end)

function HoverText:OnUpdate()
        
    local using_mouse = self.owner.components and self.owner.components.playercontroller:UsingMouse()        
    
    if using_mouse ~= self.shown then
        if using_mouse then
            self:Show()
        else
            self:Hide()
        end
    end
    
    if not self.shown then 
        return 
    end
    
    local str = nil
    if self.isFE == false then 
        str = self.owner.HUD.controls:GetTooltip() or self.owner.components.playercontroller:GetHoverTextOverride()
    else
        str = self.owner:GetTooltip()
    end

    local secondarystr = nil
 
    local lmb = nil
    if not str and self.isFE == false and self.owner:IsActionsVisible() then

        lmb = self.owner.components.playercontroller:GetLeftMouseAction()
        if lmb then
            
            str = lmb:GetActionString()
            
            if lmb.target and lmb.invobject == nil and lmb.target ~= lmb.doer then
                local name = lmb.target:GetDisplayName() or (lmb.target.components.named and lmb.target.components.named.name)
                
                
                if name then
                    local adjective = lmb.target:GetAdjective()
                    
                    if adjective then
                        str = str.. " " .. adjective .. " " .. name
                    else
                        str = str.. " " .. name
                    end
                    
                    if lmb.target.replica.stackable ~= nil and lmb.target.replica.stackable:IsStack() then
                        str = str .. " x" .. tostring(lmb.target.replica.stackable:StackSize())
                    end
                    if lmb.target.components.inspectable and lmb.target.components.inspectable.recordview and lmb.target.prefab then
                        ProfileStatsSet(lmb.target.prefab .. "_seen", true)
                    end
                end
            end
        end
        local rmb = self.owner.components.playercontroller:GetRightMouseAction()
        if rmb then
            secondarystr = STRINGS.RMB .. ": " .. rmb:GetActionString()
        end
    end

    if str then
	if self.str ~= self.lastStr then
--print("new string")
	    self.lastStr = self.str
    	    self.strFrames = SHOW_DELAY

        else
	    self.strFrames = self.strFrames - 1
            if self.strFrames <= 0 then
                if lmb and lmb.target and lmb.target:HasTag("player") then
                    self.text:SetColour(unpack(lmb.target.playercolour))
                else
                    self.text:SetColour(1,1,1,1)
                end
                self.text:SetString(str)
                self.text:Show()
            end
        end
    else
        self.text:Hide()
    end
    if secondarystr then
        self.secondarytext:SetString(secondarystr)
        self.secondarytext:Show()
    else
        self.secondarytext:Hide()
    end

    local changed = (self.str ~= str) or (self.secondarystr ~= secondarystr)
    self.str = str
    self.secondarystr = secondarystr
    if changed then
        local pos = TheInput:GetScreenPosition()
        self:UpdatePosition(pos.x, pos.y)
    end
end

function HoverText:UpdatePosition(x,y)
    local scale = self:GetScale()
    
    local scr_w, scr_h = TheSim:GetScreenSize()

    local w = 0
    local h = 0

    if self.text and self.str then
        local w0, h0 = self.text:GetRegionSize()
        w = math.max(w, w0)
        h = math.max(h, h0)
    end
    if self.secondarytext and self.secondarystr then
        local w1, h1 = self.secondarytext:GetRegionSize()
        w = math.max(w, w1)
        h = math.max(h, h1)
    end

    w = w*scale.x
    h = h*scale.y
    
    x = math.max(x, w/2 + XOFFSET)
    x = math.min(x, scr_w - w/2 - XOFFSET)

    y = math.max(y, h/2 + YOFFSETDOWN*scale.y)
    y = math.min(y, scr_h - h/2 - YOFFSETUP*scale.y)

    self:SetPosition(x,y,0)
end

function HoverText:FollowMouseConstrained()
    if not self.followhandler then
        self.followhandler = TheInput:AddMoveHandler(function(x,y) self:UpdatePosition(x,y) end)
        local pos = TheInput:GetScreenPosition()
        self:UpdatePosition(pos.x, pos.y)
    end
end

return HoverText