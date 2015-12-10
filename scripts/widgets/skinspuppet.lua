local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

require "components/skinner"

local emotes_to_choose = { "emoteXL_waving1", "emoteXL_waving2" } --"emoteXL_waving3" --currently broken on the shoulder during the wave
local emote_min_time = 6
local emote_max_time = 12

local change_delay_time = .5
local change_emotes = 
{
	base = { "emote_hat" },
	body = { "emote_strikepose" },
	hand = { "emote_hands" },
	legs = { "emote_strikepose", "emote_feet" },
	feet = { "emote_feet" },
}

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
    
    self.last_skins = { prefabname = "", base_skin = "", body = "", hand = "", legs = "", feet = "" }
    
    self.time_to_idle_emote = emote_max_time
    self.time_to_change_emote = -1
    self.queued_change_slot = ""
end)

function SkinsPuppet:DoIdleEmote()
	self.animstate:SetBank("wilson")
    local r = math.random(1,#emotes_to_choose)    
    self.animstate:PlayAnimation(emotes_to_choose[r], false)
end

function SkinsPuppet:DoChangeEmote()
	if self.queued_change_slot ~= "" then --queued_change_slot is empty when we first load up the puppet and the dressupanel is initializing
		self.animstate:SetBank("wilson")
		local r = math.random( 1, #change_emotes[self.queued_change_slot] )  
		self.animstate:PlayAnimation( change_emotes[self.queued_change_slot][r], false )
		self.queued_change_slot = "" --clear it out now so that we can get a new one
	end
end

function SkinsPuppet:EmoteUpdate(dt)
	if self.time_to_idle_emote > 0 then
		self.time_to_idle_emote = self.time_to_idle_emote - dt
	else
		if self.animstate:AnimDone() then
			self.time_to_idle_emote = math.random(emote_min_time, emote_max_time)
			self:DoIdleEmote()
		end
	end
		
	if self.time_to_change_emote > 0 then
		self.time_to_change_emote = self.time_to_change_emote - dt
		if self.time_to_change_emote <= 0 then
			if self.animstate:IsCurrentAnimation("idle") then
				self.time_to_idle_emote = math.random(emote_min_time, emote_max_time) --reset the idle emote as well when starting the change emote
				self:DoChangeEmote()
			else
				self.time_to_change_emote = 0.25 --ensure that we wait a little bit before trying to start the change emote, so that it doesn't play back to back with
			end
		end 
	end
		
	if self.animstate:AnimDone() then
		self.animstate:PlayAnimation("idle", true)
        self.animstate:SetBank("corner_dude")
    end
end
    
function SkinsPuppet:SetCharacter(character)
	self.animstate:SetBuild(character)
end


function SkinsPuppet:SetSkins(prefabname, base_skin, clothing_names, skip_change_emote)
	local base_skin = base_skin or prefabname
	base_skin = string.gsub(base_skin, "_none", "")	

	SetSkinMode( self.animstate, prefabname, base_skin, clothing_names )
	
	if not skip_change_emote then 
		--the logic here checking queued_change_slot and time_to_change_emote is to ensure we get the last thing to change (when dealing with multiple changes on one frame caused by the UI refreshing)
		if self.animstate:IsCurrentAnimation("idle") and (self.queued_change_slot == "" or self.time_to_change_emote < change_delay_time ) then
			if self.last_skins.prefabname ~= prefabname or self.last_skins.base_skin ~= base_skin then
				self.queued_change_slot = "base"
			end
			if self.last_skins.body ~= clothing_names.body then
				self.queued_change_slot = "body"
			end
			if self.last_skins.hand ~= clothing_names.hand then
				self.queued_change_slot = "hand"
			end
			if self.last_skins.legs ~= clothing_names.legs then
				self.queued_change_slot = "legs"
			end
			if self.last_skins.feet ~= clothing_names.feet then
				self.queued_change_slot = "feet"
			end
		end
		self.time_to_change_emote = change_delay_time
	else
		self.queued_change_slot = ""
	end
	
	self.last_skins.prefabname = prefabname
	self.last_skins.base_skin = base_skin
	self.last_skins.body = clothing_names.body
	self.last_skins.hand = clothing_names.hand
	self.last_skins.legs = clothing_names.legs
	self.last_skins.feet = clothing_names.feet
end


return SkinsPuppet
