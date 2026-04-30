local ClockworkTracker = Class(function(self, inst)
	self.inst = inst
	self.ents =
	{
		rook = { num = 0, ents = {} },
		knight = { num = 0, ents = {} },
		bishop = { num = 0, ents = {} },
	}

	self.bonus = SourceModifierList(inst, 0, SourceModifierList.additive)
	--bonus slots are shared between types, but are distributed evenly.
	--e.g. if you have 2 bonus slots, then you can have 2 extra, but not the same type.

	self._onclockworkremoved = function(ent) self:RemoveClockwork(ent) end
	self._onclockworkleaderchanged = function(ent, data)
		if (data and data.new) ~= self.inst then
			self:RemoveClockwork(ent)
		end
	end
end)

function ClockworkTracker:OnRemoveFromEntity()
	for chesstype, v in pairs(self.ents) do
		for ent in pairs(v.ents) do
			self.inst:RemoveEventCallback("onremove", self._onclockworkremoved, ent)
			self.inst:RemoveEventCallback("leaderchanged", self._onclockworkleaderchanged, ent)
		end
	end
end

function ClockworkTracker:GetChessType(ent)
	for chesstype in pairs(self.ents) do
		if ent:HasTag(chesstype) then
			return chesstype
		end
	end
end

function ClockworkTracker:OverrideMaxFollowersForType(chesstype, max)
	local v = self.ents[chesstype]
	if v and v.max ~= max then
		local oldmax = self:GetMaxForType(chesstype)
		v.max = max
		local newmax = self:GetMaxForType(chesstype)
		if newmax < oldmax then
			self:RevalidateFollowers()
		end
		if max == nil then
			self:TryRemoveComponentIfClear()
		end
	end
end

function ClockworkTracker:SetBonus(source, bonus, key)
	local oldbonus = self.bonus:Get()
	self.bonus:SetModifier(source, bonus, key)
	if self.bonus:Get() < oldbonus then
		self:RevalidateFollowers()
	end
	if (bonus or 0) == 0 then
		self:TryRemoveComponentIfClear()
	end
end

function ClockworkTracker:GetCountForType(chesstype)
	local v = self.ents[chesstype]
	return v and v.num or 0
end

function ClockworkTracker:GetMaxForType(chesstype)
	if IsSpecialEventActive(SPECIAL_EVENTS.YOTH) and chesstype == "knight" then
		return math.huge
	end
	local v = self.ents[chesstype]
	return v and (v.max or (self.inst:HasTag("chessfriend") and TUNING.CLOCKWORK_MAX_FOLLOWING_CHESSFRIEND or TUNING.CLOCKWORK_MAX_FOLLOWING)) or 0
end

function ClockworkTracker:GetBonusForType(chesstype)
	if self.ents[chesstype] == nil then
		return 0
	elseif IsSpecialEventActive(SPECIAL_EVENTS.YOTH) then
		return chesstype == "knight" and 0 or math.ceil(self.bonus:Get() / 2)
	end
	return math.ceil(self.bonus:Get() / 3)
end

function ClockworkTracker:CanAddClockwork(ent)
	local chesstype = self:GetChessType(ent)
	local count = self:GetCountForType(chesstype)
	local max = self:GetMaxForType(chesstype)
	if count < max then
		return true
	elseif count < max + self:GetBonusForType(chesstype) then
		--see if we've used up all our bonus slots yet
		local bonuscount = 0
		for chesstype, v in pairs(self.ents) do
			max = self:GetMaxForType(chesstype)
			if v.num > max then
				bonuscount = bonuscount + v.num - max
				if bonuscount >= self.bonus:Get() then
					return false
				end 
			end
		end
		return true
	end
	return false
end

function ClockworkTracker:AddClockwork(ent)
	local chesstype = self:GetChessType(ent)
	if chesstype then
		local v = self.ents[chesstype]
		if v.ents[ent] == nil then
			v.ents[ent] = true
			v.num = v.num + 1
			self.inst:ListenForEvent("onremove", self._onclockworkremoved, ent)
			self.inst:ListenForEvent("leaderchanged", self._onclockworkleaderchanged, ent)
		end
	end
end

function ClockworkTracker:RemoveClockwork(ent)
	local chesstype = self:GetChessType(ent)
	if chesstype then
		local v = self.ents[chesstype]
		if v.ents[ent] then
			v.ents[ent] = nil
			v.num = v.num - 1
			self.inst:RemoveEventCallback("onremove", self._onclockworkremoved, ent)
			self.inst:RemoveEventCallback("leaderchanged", self._onclockworkleaderchanged, ent)

			if v.num <= 0 then
				self:TryRemoveComponentIfClear()
			end
		end
	end
end

function ClockworkTracker:RevalidateFollowers()
	local bonusremaining = self.bonus:Get()
	local order = { "bishop", "rook", "knight" }
	for _, chesstype in ipairs(order) do
		local v = self.ents[chesstype]
		local max = self:GetMaxForType(chesstype)
		if v.num > max then
			local bonusmax = max + math.min(bonusremaining, self:GetBonusForType(chesstype))
			for i = bonusmax + 1, v.num do
				local ent = next(v.ents)
				if ent and ent.components.follower then
					ent.components.follower:SetLeader(nil)
				end
			end
			--NOTE: new v.num AFTER removals
			bonusremaining = bonusremaining - (v.num - max)
		end
	end
end

function ClockworkTracker:TryRemoveComponentIfClear()
	if self.bonus:HasAnyModifiers() then
		return false
	end

	for chesstype, v in pairs(self.ents) do
		if v.num > 0 or v.max then
			return false
		end
	end

	self.inst:RemoveComponent("clockworktracker")
	return true
end

return ClockworkTracker
