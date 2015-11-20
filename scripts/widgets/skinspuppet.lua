local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

require "components/skinner"

local SkinsPuppet = Class(Widget, function(self)
    Widget._ctor(self, "puppet")

    self.anim = self:AddChild(UIAnim())
    self.animstate = self.anim:GetAnimState()
    self.animstate:SetBank("corner_dude")
    self.animstate:SetBuild("wilson")
    self.animstate:PlayAnimation("idle", true)

    self.animstate:Hide("ARM_carry")
    self.animstate:Hide("head_hat")

    self.anim:SetScale(.25)
end)


function SkinsPuppet:SetCharacter(character)
	self.animstate:SetBuild(character)
end


function SkinsPuppet:SetSkins(prefabname, base_skin, clothing_names)
	local base_skin = base_skin or prefabname
	base_skin = string.gsub(base_skin, "_none", "")	

	SetSkinMode( self.animstate, prefabname, base_skin, clothing_names )
end


return SkinsPuppet
