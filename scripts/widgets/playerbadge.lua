local Image = require "widgets/image"
local Widget = require "widgets/widget"

local DEFAULT_ATLAS = "images/avatars.xml"
local DEFAULT_AVATAR = "avatar_unknown.tex"

local PlayerBadge = Class(Widget, function(self, prefab, colour, ishost, userflags)
    Widget._ctor(self, "PlayerBadge")
    self.isFE = false
    self:SetClickable(false)

    self.root = self:AddChild(Widget("root"))
    -- self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.icon = self.root:AddChild(Widget("target"))
    self.icon:SetScale(.8)

    self.is_mod_character = false
    if not table.contains(DST_CHARACTERLIST, prefab) and not table.contains(MODCHARACTERLIST, prefab) then
        self.prefabname = ""
    else
        self.prefabname = prefab
        if table.contains(MODCHARACTERLIST, prefab) then
			self.is_mod_character = true
		end
    end
    self.ishost = ishost
    self.userflags = userflags

    self.headbg = self.icon:AddChild(Image(DEFAULT_ATLAS, self:GetBG()))
    self.head = self.icon:AddChild(Image( self:GetAvatarAtlas(), self:GetAvatar(), DEFAULT_AVATAR ))
    self.headframe = self.icon:AddChild(Image(DEFAULT_ATLAS, "avatar_frame_white.tex"))
    self.headframe:SetTint(unpack(colour))
end)

function PlayerBadge:Set(prefab, colour, userflags)
    self.headframe:SetTint(unpack(colour))

	local dirty = false
    if self.prefabname ~= prefab then
		self.is_mod_character = false
        if not table.contains(DST_CHARACTERLIST, prefab) and not table.contains(MODCHARACTERLIST, prefab) then
            self.prefabname = ""
        else
            self.prefabname = prefab
			if table.contains(MODCHARACTERLIST, prefab) then
				self.is_mod_character = true
			end
        end
        dirty = true
    end
    if self.userflags ~= userflags then
        self.userflags = userflags
        dirty = true
    end
    if dirty then
        self.headbg:SetTexture(DEFAULT_ATLAS, self:GetBG())
        self.head:SetTexture( self:GetAvatarAtlas(), self:GetAvatar(), DEFAULT_AVATAR )
    end
end

function PlayerBadge:IsGhost()
    return checkbit(self.userflags, USERFLAGS.IS_GHOST)
end

function PlayerBadge:IsAFK()
    return checkbit(self.userflags, USERFLAGS.IS_AFK)
end

function PlayerBadge:IsCharacterState1()
    return checkbit(self.userflags, USERFLAGS.CHARACTER_STATE_1)
end

function PlayerBadge:IsCharacterState2()
    return checkbit(self.userflags, USERFLAGS.CHARACTER_STATE_2)
end
    
function PlayerBadge:GetBG()
    if self.ishost and self.prefabname == "" then
        return "avatar_bg.tex"
    elseif self:IsAFK() then
        return "avatar_bg.tex"
    elseif self:IsGhost() then
        return "avatar_ghost_bg.tex"
    else
        return "avatar_bg.tex"
    end
end

function PlayerBadge:GetAvatarAtlas()
	if self.is_mod_character and not self:IsAFK() then
		local location = MOD_AVATAR_LOCATIONS["Default"]
		if MOD_AVATAR_LOCATIONS[self.prefabname] ~= nil then
			location = MOD_AVATAR_LOCATIONS[self.prefabname]
		end
		
		local starting = "avatar_"
		if self:IsGhost() then
			starting = starting .. "ghost_"
		end
		
		local ending = ""
		if self:IsCharacterState1() then
			ending = "_1"
		end		
		if self:IsCharacterState2() then
			ending = "_2"
		end
		
		return location .. starting .. self.prefabname .. ending .. ".xml"
	end
	return DEFAULT_ATLAS
end

function PlayerBadge:GetAvatar()
	if self.is_mod_character and not self:IsAFK() then
		local starting = "avatar_"
		if self:IsGhost() then
			starting = starting .. "ghost_"
		end
		
		local ending = ""
		if self:IsCharacterState1() then
			ending = "_1"
		end		
		if self:IsCharacterState2() then
			ending = "_2"
		end
		
		return starting .. self.prefabname .. ending .. ".tex"
	end

    if self.ishost and self.prefabname == "" then
        return "avatar_server.tex"
    elseif self:IsAFK() then
        return "avatar_afk.tex"
    elseif self:IsGhost() then
        return "avatar_ghost_"..(self.prefabname ~= "" and self.prefabname or "unknown")..".tex"
    else
        return "avatar_"..(self.prefabname ~= "" and self.prefabname or "unknown")..".tex"
    end
end

return PlayerBadge