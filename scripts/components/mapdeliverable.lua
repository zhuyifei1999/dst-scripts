local MapDeliverable = Class(function(self, inst)
	self.inst = inst
	self.deliverytime = 5
	self.deliverytimefn = nil
	self.onstartdeliveryfn = nil
	self.ondeliveryprogressfn = nil
	self.onstopdeliveryfn = nil
	self.onstartmapactionfn = nil
	self.oncancelmapactionfn = nil
	self:Reset_Internal()

	self._onremovebufferedmapaction = function(bufferedmapaction)
		if self.oncancelmapactionfn then
			self.oncancelmapactionfn(self.inst, bufferedmapaction.doer)
		end
	end
end)

function MapDeliverable:Reset_Internal()
	self.origin = nil
	self.dest = nil
	self.t = nil
	self.len = nil
end

function MapDeliverable:OnRemoveEntity()
	if self.bufferedmapaction then
		self.bufferedmapaction:Remove()
		if self.oncancelmapactionfn then
			self.oncancelmapactionfn(self.inst, self.bufferedmapaction.doer)
		end
		self.bufferedmapaction = nil
	end
end

function MapDeliverable:OnRemoveFromEntity()
	self:CancelMapAction()
end

function MapDeliverable:SetDeliveryTime(t)
	self.deliverytime = t
end

function MapDeliverable:SetDeliveryTimeFn(fn)
	self.deliverytimefn = fn
end

function MapDeliverable:SetOnStartDeliveryFn(fn)
	self.onstartdeliveryfn = fn
end

function MapDeliverable:SetOnDeliveryProgressFn(fn)
	self.ondeliveryprogressfn = fn
end

function MapDeliverable:SetOnStopDeliveryFn(fn)
	self.onstopdeliveryfn = fn
end

function MapDeliverable:SetOnStartMapActionFn(fn)
	self.onstartmapactionfn = fn
end

function MapDeliverable:SetOnCancelMapActionFn(fn)
	self.oncancelmapactionfn = fn
end

function MapDeliverable:StartMapAction(doer)
	if self.bufferedmapaction then
		return false
	elseif self.onstartmapactionfn then
		local success, reason = self.onstartmapactionfn(self.inst, doer)
		if not success then
			return false, reason
		end
	end

	self.bufferedmapaction = SpawnPrefab("bufferedmapaction")
	self.inst:ListenForEvent("onremove", self._onremovebufferedmapaction, self.bufferedmapaction)
	self.bufferedmapaction:SetupMapAction(ACTIONS.MAPDELIVER_MAP, self.inst, doer)
	assert(self.inst.bufferedmapaction == self.bufferedmapaction)
	return true
end

function MapDeliverable:CancelMapAction()
	if self.bufferedmapaction then
		self.bufferedmapaction:Remove()
		assert(self.inst.bufferedmapaction ~= self.bufferedmapaction)
		self.bufferedmapaction = nil
	end
end

function MapDeliverable:IsDelivering()
	return self.t ~= nil
end

function MapDeliverable:GetProgress()
	return self.t and (self.len == 0 and 1 or self.t / self.len)
end

function MapDeliverable:SendToPoint(pt, doer)
	if self.t then
		return false --already sending in progress
	end

	if self.bufferedmapaction and not (
		self.bufferedmapaction:GetAction() == ACTIONS.MAPDELIVER_MAP and
		self.bufferedmapaction:IsDoer(doer)
	) then
		return false
	end

	if self.onstartdeliveryfn then
		local success, reason = self.onstartdeliveryfn(self.inst, pt, doer)
		if not success then
			return false, reason
		end
	end

	self:CancelMapAction()

	self.origin = self.inst:GetPosition()
	self.dest = Vector3(pt:Get()) --kinda support pt being modified via onstartdeliveryfn, but no further
	self.t = 0
	self.len = self.deliverytimefn and self.deliverytimefn(self.inst, self.dest, doer) or self.deliverytime

	self.inst:StartUpdatingComponent(self)
	self:_dbg_print(string.format("\n\tItem: <%s>\n\tStatus: \"OUT FOR DELIVERY\"\n\tSender: <%s>\n\tDestination: %s", tostring(self.inst), tostring(doer), tostring(self.dest)))
	return true
end

function MapDeliverable:OnUpdate(dt)
	self.t = math.min(self.t + dt, self.len)

	if self.ondeliveryprogressfn then
		self.ondeliveryprogressfn(self.inst, self.t, self.len, self.origin, self.dest)
	end

	if self.t and self.t >= self.len then
		local dest = self.dest
		self:Reset_Internal()
		self.inst:StopUpdatingComponent(self)

		if self.onstopdeliveryfn then
			self.onstopdeliveryfn(self.inst)
		end
		self:_dbg_print(string.format("\n\tItem: <%s>\n\tStatus: \"ARRIVED\"\n\tDestination: %s", tostring(self.inst), tostring(dest)))
	end
end

function MapDeliverable:Stop()
	if self.t then
		self:Reset_Internal()
		self.inst:StopUpdatingComponent(self)

		if self.onstopdeliveryfn then
			self.onstopdeliveryfn(self.inst)
		end
		self:_dbg_print(string.format("\n\tItem: <%s>\n\tStatus: \"STOPPED\"", tostring(self.inst)))
	end
end

local function _serialize_pos_float(f)
	f = math.floor(f * 1000 + 0.5) * 0.001
	return f ~= 0 and f or nil
end

function MapDeliverable:OnSave()
	return self.t and {
		x0 = _serialize_pos_float(self.origin.x),
		y0 = self.origin.y ~= 0 and _serialize_pos_float(self.origin.y) or nil,
		z0 = _serialize_pos_float(self.origin.z),

		x1 = _serialize_pos_float(self.dest.x),
		y1 = self.dest.y ~= 0 and _serialize_pos_float(self.dest.y) or nil,
		z1 = _serialize_pos_float(self.dest.z),

		t = math.floor(self.t + 0.5),
		len = math.floor(self.len * 10 + 0.5) * 0.1,
	}
end

function MapDeliverable:OnLoad(data)--, newents)
	if data and data.t then
		local x0, y0, z0 = data.x0 or 0, data.y0 or 0, data.z0 or 0
		local x1, y1, z1 = data.x1 or 0, data.y1 or 0, data.z1 or 0
		local len = data.len or data.t
		local t = math.min(data.t, len)
		if self.t then
			self.t = t
			self.len = len
			self.origin.x, self.origin.y, self.origin.z = x0, y0, z0
			self.dest.x, self.dest.y, self.dest.z = x1, y1, z1
		else
			local pt = Vector3(x1, y1, z1)
			if self.onstartdeliveryfn == nil or self.onstartdeliveryfn(self.inst, pt, nil) then
				self.origin = Vector3(x0, y0, z0)
				self.dest = Vector3(pt:Get()) --kinda support pt being modified via onstartdeliveryfn, but no further
				self.t = t
				self.len = len

				self.inst:StartUpdatingComponent(self)
				self:_dbg_print(string.format("\n\tItem: <%s>\n\tStatus: \"RESUMED DELIVERY\"\n\tDestination: %s", tostring(self.inst), tostring(self.dest)))
			end
		end
	end
end

function MapDeliverable:_dbg_print(...)
	print("MapDeliverable:", ...)
end

return MapDeliverable
