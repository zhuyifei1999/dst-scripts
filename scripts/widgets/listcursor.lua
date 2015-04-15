local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Button = require "widgets/button"
local Image = require "widgets/image"

local ListCursor = Class(Button, function(self, atlas, normal, focus, disabled)
    Button._ctor(self, "ListCursor")

    self.selectedimage = self:AddChild(Image("images/serverbrowser.xml", "textwidget.tex"))
    self.selectedimage:SetTint(1,1,1,0)
    self.selectedimage:SetScale(.98,.97)
    self.selectedimage:SetPosition(0,1)
    self.highlight = self:AddChild(Image("images/serverbrowser.xml", "textwidget_over.tex"))
    self.highlight:SetTint(1,1,1,0)
end)


function ListCursor:OnGainFocus()
	ListCursor._base.OnGainFocus(self)

    self.highlight:SetTint(1,1,1,1)
end

function ListCursor:OnLoseFocus()
	ListCursor._base.OnLoseFocus(self)

    self.highlight:SetTint(1,1,1,0)
end

function ListCursor:OnControl(control, down)
    
    if Button._base.OnControl(self, control, down) then return true end

    if not self:IsEnabled() or not self.focus then return end
    
    if control == CONTROL_ACCEPT then
        if down then
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            self.down = true
            if self.ondown then
                self.ondown()
            end
        else
            if self.down then
                self.down = false
                if self.onclick then
                    self.onclick()
                end
            end
        end
        
        return true
    end

end

function ListCursor:SetSelected(selected)
    if selected then
        self.selected = true
        self.selectedimage:SetTint(1,1,1,1)
    else
        self.selectedimage:SetTint(1,1,1,0)
        self.selected = false
    end
end

function ListCursor:Enable()
	ListCursor._base.Enable(self)
end

function ListCursor:Disable()
	ListCursor._base.Disable(self)
end

function ListCursor:GetSize()
    return self.image:GetSize()
end

return ListCursor