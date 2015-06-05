--NOTE - RampingSpawner must be hooked into a brain properly to function! Look @ Dragonfly. 

local RampingSpawner = Class(function(self, inst)
    self.inst = inst

    self.spawn_prefab = "lavae"
    self.spawns = {}
    self.num_spawns = 0

    self.current_wave = 0
    self.wave_num = 0
    self.min_wave = 4
    self.max_wave = 10
    self.waves_to_max = 6
    self.wave_time = 30

    self.spawning_on = false
    self.SpawnTask = nil
end)

function RampingSpawner:OnRemoveFromEntity()
    if self.SpawnTask ~= nil then
        self.SpawnTask:Cancel()
        self.SpawnTask = nil
    end
    self:Reset()
end

function RampingSpawner:StopTrackingSpawn(spawn)
    if self.spawns[spawn] then
        self.inst:RemoveEventCallback("death", spawn.rampingspawner_ondeathfn, spawn)
        self.inst:RemoveEventCallback("onremove", spawn.rampingspawner_onremovefn, spawn)
        self.rampingspawner_ondeathfn = nil
        self.rampingspawner_onremovefn = nil
        self.spawns[spawn] = nil
        self.num_spawns = self.num_spawns - 1
    end
end

function RampingSpawner:OnSpawnDeath(spawn)
    self:StopTrackingSpawn(spawn)
    self.inst:PushEvent("rampingspawner_death", { remaining_spawns = self.num_spawns })
end

function RampingSpawner:TrackSpawn(spawn)
    if not self.spawns[spawn] then
        spawn.rampingspawner_ondeathfn = function() self:OnSpawnDeath(spawn) end
        spawn.rampingspawner_onremovefn = function() self:StopTrackingSpawn(spawn) end
        self.inst:ListenForEvent("death", spawn.rampingspawner_ondeathfn, spawn)
        self.inst:ListenForEvent("onremove", spawn.rampingspawner_onremovefn, spawn)
        self.spawns[spawn] = true
        self.num_spawns = self.num_spawns + 1
    end
end

function RampingSpawner:GetCurrentWave()
    return self.current_wave
end

function RampingSpawner:GetWaveSize()
    return math.floor(Lerp(self.min_wave, self.max_wave, self.wave_num/self.waves_to_max))
end

function RampingSpawner:DoWave()
    self.wave_num = self.wave_num + 1
    self.current_wave = self.current_wave + self:GetWaveSize()
end

function RampingSpawner:GetSpawnPos()
    if self.getspawnposfn then
        return self.getspawnposfn(self.inst)
    end
    return self.inst:GetPosition()
end

function RampingSpawner:GetSpawnRot()
    if self.getspawnrotfn then
        return self.getspawnrotfn(self.inst)
    end
    return self.inst.Transform:GetRotation()
end

function RampingSpawner:SpawnEntity()
    local spawn = SpawnPrefab(self.spawn_prefab)
    
    self:TrackSpawn(spawn)

    spawn.Transform:SetPosition(self:GetSpawnPos():Get())
    spawn.Transform:SetRotation(self:GetSpawnRot())
    self.current_wave = self.current_wave - 1
    self.inst:PushEvent("rampingspawner_spawn", { newent = spawn })
    
    if self:GetCurrentWave() <= 0 and self:IsActive() then
        if self.SpawnTask ~= nil then
            self.SpawnTask:Cancel()
        end
        self.SpawnTask = self.inst:DoTaskInTime(self.wave_time, function() self:DoWave() end)
    end
end

function RampingSpawner:IsActive()
    return self.spawning_on
end

function RampingSpawner:Start()
    if self:IsActive() then return end
    self:DoWave()
    self.spawning_on = true

    if self.onstartfn then
        self.onstartfn(self.inst)
    end

end

function RampingSpawner:Stop()
    if not self:IsActive() then return end

    self.spawning_on = false
    if self.SpawnTask ~= nil then
        self.SpawnTask:Cancel()
        self.SpawnTask = nil
    end

    if self.onstopfn then
        self.onstopfn(self.inst)
    end
end

function RampingSpawner:Reset()
    self.current_wave = 0
    for k,v in pairs(self.spawns) do
        self:StopTrackingSpawn(k)
    end
end

function RampingSpawner:OnSave()
    local data = {}
    local refs = {}

    for k,v in pairs(self.spawns) do
        if not data.spawns then
            data.spawns = {k.GUID}
        else
            table.insert(data.spawns, k.GUID)
        end
        table.insert(refs, k.GUID)
    end

    data.current_wave = self.current_wave
    data.wave_num = self.wave_num
    data.spawning_on = self.spawning_on

    return data, refs
end

function RampingSpawner:OnLoad(data)
    self.current_wave = data.current_wave
    self.wave_num = data.wave_num

    if data.spawning_on then
        self:Start()
    end
end

function RampingSpawner:LoadPostPass(ents, data)
    if data.spawns then
        for k,v in pairs(data.spawns) do
            local spawn = ents[v]
            if spawn then
                spawn = spawn.entity
                self:TrackSpawn(spawn)
            end
        end
    end
end

return RampingSpawner
