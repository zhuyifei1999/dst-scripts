local Wx78_DroneScoutTracker = Class(function(self, inst)
	self.inst = inst
	self.data = nil
	self.drones = {}

	self._onremovedrone = function(drone) self:StopTracking(drone) end
end)

function Wx78_DroneScoutTracker:OnRemoveEntity()
	for k in pairs(self.drones) do
		k:PushEvent("ms_dronescout_despawn", self.inst)
	end
end

function Wx78_DroneScoutTracker:SetOnStartTrackingFn(fn)
    self.onstarttrackingfn = fn
end

function Wx78_DroneScoutTracker:SetOnStopTrackingFn(fn)
    self.onstoptrackingfn = fn
end

function Wx78_DroneScoutTracker:StartTracking(drone)
	if self.drones[drone] == nil then
		self.drones[drone] = true
		self.inst:ListenForEvent("onremove", self._onremovedrone, drone)
        if self.onstarttrackingfn then
            self.onstarttrackingfn(self.inst, drone)
        end
		drone:PushEvent("ms_dronescout_tracked", self.inst)
	end
end

function Wx78_DroneScoutTracker:StopTracking(drone)
	if self.drones[drone] then
		self.drones[drone] = nil
		self.inst:RemoveEventCallback("onremove", self._onremovedrone, drone)
        if self.onstoptrackingfn then
            self.onstoptrackingfn(self.inst, drone)
        end
		drone:PushEvent("ms_dronescout_untracked", self.inst)
	end
end

function Wx78_DroneScoutTracker:ReleaseAllDrones()
	for k in pairs(self.drones) do
		self:StopTracking(k)
		k:PushEvent("ms_dronescout_despawn", self.inst)
	end
	self.data = nil
end

function Wx78_DroneScoutTracker:OnSave()
	local data

	--generate data for drones on this shard
	if next(self.drones) then
		data = {}
		for k in pairs(self.drones) do
			data[#data + 1] = k:GetSaveRecord() --returns data, refs, but we can assume we don't need the refs
		end
		data = { [TheShard:GetShardId()] = data }
	end

	--copy over data for drones on other shards
	if self.data then
		data = shallowcopy(self.data, data or {})
	end

	return data and { drones = data }
end

function Wx78_DroneScoutTracker:OnLoad(data, newents)
	if data.drones then
		local shardid = TheShard:GetShardId()
		for k, v in pairs(data.drones) do
			if k == shardid then
				for _, v1 in ipairs(v) do
					local drone = SpawnSaveRecord(v1, newents)
					if drone then
						self:StartTracking(drone)
					end
				end
			elseif self.data == nil then
				self.data = { [k] = v }
			else
				self.data[k] = v
			end
		end
	end
end

return Wx78_DroneScoutTracker
