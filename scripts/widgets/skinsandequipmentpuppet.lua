local Widget = require "widgets/widget"
local Text = require "widgets/text"
local SkinsPuppet = require "widgets/skinspuppet"

local anims =
{
	scratch = .5,
    hungry = .5,
    eat = .5,
    eatquick = .33,
    wave1 = .1,
    wave2 = .1,
    wave3 = .1,
    happycheer = .1,
    sad = .1,
    angry = .1,
    annoyed = .1,
    facepalm = .1
}

local SkinsAndEquipmentPuppet = Class(SkinsPuppet, function(self, character, colour, scale)
    SkinsPuppet._ctor(self, "SkinsAndEquipmentPuppet")

    self.character = character
    self:SetCharacter(character)

    self.anim:SetScale(unpack(scale))
    self:DoInit(colour)
end)

function SkinsAndEquipmentPuppet:DoInit(colour)

	if BASE_TORSO_TUCK[self.character] then
		--tuck torso into pelvis
		self.animstate:OverrideSkinSymbol("torso", self.character, "torso_pelvis" )
		self.animstate:OverrideSkinSymbol("torso_pelvis", self.character, "torso" )
    end

    self.animstate:SetMultColour(unpack(colour))

    self.name = self:AddChild(Text(NEWFONT, 35, "", WHITE))
    self.name:SetPosition(0, -35)
    self.name:Hide()
end

function SkinsAndEquipmentPuppet:InitSkins(player_data)

    if player_data then 
    	
    	local clothing = {}
    	clothing["body"] = player_data.body_skin
    	clothing["hand"] = player_data.hand_skin
    	clothing["legs"] = player_data.legs_skin
    	clothing["feet"] = player_data.feet_skin

    	self:SetSkins(player_data.prefab, player_data.base_skin, clothing, true)
    	self.name:SetTruncatedString(player_data.name, 200, 25, true)
    end
end

function SkinsAndEquipmentPuppet:SetTool(tool)
	if tool == "swap_staffs" then
    	self.animstate:OverrideSymbol("swap_object", tool, "redstaff")
    else
    	self.animstate:OverrideSymbol("swap_object", tool, tool)
    end
    self.animstate:Show("ARM_carry")
    self.animstate:Hide("ARM_normal")
end

function SkinsAndEquipmentPuppet:SetTorso(torso)
	if torso ~= "" then
    	if torso == "torso_amulets" then
    		if math.random() <= .5 then
    			self.animstate:OverrideSymbol("swap_body", torso, "purpleamulet")
    		else
    			self.animstate:OverrideSymbol("swap_body", torso, "blueamulet")
    		end
    	else
    		self.animstate:OverrideSymbol("swap_body", torso, "swap_body")
    	end
    end
end

function SkinsAndEquipmentPuppet:SetHat(hat)
	if hat ~= "" then
    	self.animstate:OverrideSymbol("swap_hat", hat, "swap_hat")
        self.animstate:Show("HAT")
        self.animstate:Show("HAT_HAIR")
        self.animstate:Hide("HAIR_NOHAT")
        self.animstate:Hide("HAIR")
		self.animstate:Hide("HEAD")
		self.animstate:Show("HEAD_HAT")
    end
end

function SkinsAndEquipmentPuppet:StartAnimUpdate()
	self.animstate:PlayAnimation("idle", true)
    self.animstate:SetTime(math.random()*1.5)

    self:StartUpdating()
end

-- This uses a different anim selection process than SkinsPuppet does
function SkinsAndEquipmentPuppet:OnUpdate(dt)
	self.timetonewanim = self.timetonewanim and self.timetonewanim - dt or 5 +math.random()*5

	if self.timetonewanim < 0 then
		self.animstate:PushAnimation(weighted_random_choice(anims))		
		self.animstate:PushAnimation("idle", true)		
		self.timetonewanim = 10 + math.random()*15
	end
end

function SkinsAndEquipmentPuppet:OnGainFocus()
	self.name:Show()
end

function SkinsAndEquipmentPuppet:OnLoseFocus()
	self.name:Hide()
end

return SkinsAndEquipmentPuppet
