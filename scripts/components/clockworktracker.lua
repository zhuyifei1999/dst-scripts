local ClockworkTracker = Class(function(self, inst)
	self.inst = inst
	self.ents =
	{
		rook = { num = 0, ents = {} },
		knight = { num = 0, ents = {} },
		bishop = { num = 0, ents = {} },
	}

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
			local count = 0
			for ent in pairs(v.ents) do
				if count < newmax then
					count = count + 1
				elseif ent.components.follower then
					ent.components.follower:SetLeader(nil)
				end
			end
		end

		if max == nil then
			for chesstype, v in pairs(self.ents) do
				if v.num > 0 or v.max then
					return
				end
			end
			self.inst:RemoveComponent("clockworktracker")
		end
	end
end

function ClockworkTracker:HasOverriddenMax()
	for chesstype, v in pairs(self.ents) do
		if v.max then
			return true
		end
	end
	return false
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

function ClockworkTracker:CanAddClockwork(ent)
	local chesstype = self:GetChessType(ent)
	return self:GetCountForType(chesstype) < self:GetMaxForType(chesstype)
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

			if v.num <= 0 and not self:HasOverriddenMax() then
				self.inst:RemoveComponent("clockworktracker")
			end
		end
	end
end

return ClockworkTracker
