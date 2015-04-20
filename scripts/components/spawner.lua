-- spawner in unique from childspawner in that it manages a single persistant entity 
-- (eg. a specific named pigman with a specific hat)
-- whereas childspawner creates and destroys one or more generic entities as they enter 
-- and leave the spawner (eg. spiders). it can manage more than one, but can not maintain
-- individual properties of each entity

local function OnReleaseChild(inst)
    local self = inst.components.spawner
    if self ~= nil then
        self.task = nil
        if not self.spawnoffscreen or inst:IsAsleep() then
            self:ReleaseChild()
        end
    end
end

local function OnEntitySleep(inst)
    local self = inst.components.spawner
    if self ~= nil and self.spawnoffscreen and self.nextspawntime ~= nil and GetTime() > self.nextspawntime then
        self:ReleaseChild()
    end
end

local Spawner = Class(function(self, inst)
    self.inst = inst
    self.child = nil
    self.delay = 0
    self.onoccupied = nil
    self.onvacate = nil
    self.spawnsleft = nil
    self.spawnoffscreen = false
    
    self.task = nil
    self.nextspawntime = nil
end)

function Spawner:GetDebugString()
    local str = "child: "..tostring(self.child)
    if self:IsOccupied() then
        str = str.." occupied"
    end
    if self.task ~= nil then
        if self.nextspawntime ~= nil then
            str = str..string.format(" spawn in %2.2fs", self.nextspawntime - GetTime())
        end
        if self.nextretrytime ~= nil then
            str = str..string.format(" queued spawn, checking in %2.2fs", self.nextretrytime - GetTime())
        end
    end
    if self.spawnsleft ~= nil then
        str = str.." left: "..tostring(self.spawnsleft)
    end
    return str
end

function Spawner:SetOnOccupiedFn(fn)
    self.onoccupied = fn
end

function Spawner:SetOnVacateFn(fn)
    self.onvacate = fn
end

function Spawner:SetOnlySpawnOffscreen(offscreen)
    if self.spawnoffscreen ~= offscreen then
        self.spawnoffscreen = offscreen
        if offscreen then
            self.inst:ListenForEvent("entitysleep", OnEntitySleep)
        else
            self.inst:RemoveEventCallback("entitysleep", OnEntitySleep)
        end
    end
end

function Spawner:Configure(childname, delay, startdelay)
    self.childname = childname
    self.delay = delay
    
    self:SpawnWithDelay(startdelay or 0)
end

function Spawner:SpawnWithDelay(delay)
    delay = math.max(0, delay)
    self.nextspawntime = GetTime() + delay
    if self.task ~= nil then
        self.task:Cancel()
    end
    self.task = self.inst:DoTaskInTime(delay, OnReleaseChild)
    return self.task
end

function Spawner:IsSpawnPending()
    return self.task ~= nil
end

function Spawner:SetQueueSpawning(queued, retryperiod)
    if queued then
        self.queue_spawn = true
        self.retryperiod = retryperiod
    else
        self.queue_spawn = false
        self.retryperiod = nil
        self.nextretrytime = nil
    end
end

function Spawner:CancelSpawning()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
        self.nextspawntime = nil
    end
end

function Spawner:OnSave()
    local data = {}

    if self.child ~= nil and self:IsOccupied() then
        data.child = self.child:GetSaveRecord()
    elseif self.child ~= nil and self.child.components.health ~= nil and not self.child.components.health:IsDead() then
        data.childid = self.child.GUID
    elseif self.nextspawntime then
        data.startdelay = self.nextspawntime - GetTime()
    end

    data.spawnsleft = self.spawnsleft

    local refs = data.childid ~= nil and { data.childid } or nil
    return data, refs
end

function Spawner:OnLoad(data, newents)
    self:CancelSpawning()

    if data.child ~= nil then
        local child = SpawnSaveRecord(data.child, newents)
        if child ~= nil then
            self:TakeOwnership(child)
            self:GoHome(child)
        end
    end
    if data.startdelay ~= nil then
        self:SpawnWithDelay(data.startdelay)
    end

    --[[
    if data.spawnsleft ~= nil then
		self.spawnsleft = data.spawnsleft
		if data.spawnsleft == 0 and self.onoutofspawns ~= nil then
			self.onoutofspawns(self.inst)
		end
    end
    --]]
end

function Spawner:TakeOwnership(child)
    if self.child ~= child then
        self.inst:ListenForEvent("ontrapped", function() self:OnChildKilled(child) end, child)
        self.inst:ListenForEvent("death", function() self:OnChildKilled(child) end, child)
        if child.components.knownlocations ~= nil then
            child.components.knownlocations:RememberLocation("home", self.inst:GetPosition())
        end
        self.child = child
    end
    if child.components.homeseeker == nil then
        child:AddComponent("homeseeker")
    end
    child.components.homeseeker:SetHome(self.inst)
end

function Spawner:LoadPostPass(newents, savedata)
    if savedata.childid ~= nil then
        local child = newents[savedata.childid]
        if child ~= nil then
            child = child.entity
            self:TakeOwnership(child)
        end
    end
end

function Spawner:IsOccupied()
    return self.child ~= nil and self.child.parent == self.inst
end

function Spawner:ReleaseChild()
    if self.spawnsleft ~= nil and self.spawnsleft == 0 then
        return
    end

    self:CancelSpawning()

    -- We want to release child, but are we set to queue the spawn right now?
    if self.queue_spawn and self.retryperiod ~= nil then
        self.task = self.inst:DoTaskInTime(self.retryperiod, OnReleaseChild)
        self.nextretrytime = GetTime() + self.retryperiod
    -- If not, go for it!
    else
        if self.child == nil then
            local childname = self.childfn ~= nil and self.childfn(self.inst) or self.childname
            local child = SpawnPrefab(childname)
            if child ~= nil then            
                self:TakeOwnership(child)
                self:GoHome(child)
            end
        end

        if self:IsOccupied() then
            self.inst:RemoveChild(self.child)
            self.child:ReturnToScene()

            local rad = 0.5
                + (self.inst.Physics ~= nil and self.inst.Physics:GetRadius() or 0)
                + (self.child.Physics ~= nil and self.child.Physics:GetRadius() or 0)

            local pos = self.inst:GetPosition()
            local start_angle = math.random() * 2 * PI

            local offset = FindWalkableOffset(pos, start_angle, rad, 8, false)
            if offset == nil then
                -- well it's gotta go somewhere!
                --print(self.inst, "Spawner:ReleaseChild() no good place to spawn child: ", self.child)
                pos.x = pos.x + rad * math.cos(start_angle)
                pos.z = pos.z - rad * math.sin(start_angle)
            else
                --print(self.inst, "Spawner:ReleaseChild() safe spawn of: ", self.child)
                pos = pos + offset
            end

            self:TakeOwnership(self.child)
            if self.child.Physics ~= nil then
                self.child.Physics:Teleport(pos:Get())
            else
                self.child.Transform:SetPosition(pos:Get())
            end

            if self.onvacate ~= nil then
                self.onvacate(self.inst, self.child)
            end
            return true
        end
    end
end

function Spawner:GoHome(child)
    if self.child == child and not self:IsOccupied() then
        self.inst:AddChild(child)
        child:RemoveFromScene()

        if child.components.locomotor ~= nil then
            child.components.locomotor:Stop()
        end

        if child.components.burnable ~= nil and child.components.burnable:IsBurning() then
            child.components.burnable:Extinguish()
        end

        --if child.components.health ~= nil and child.components.health:IsHurt() then
        --end

        if child.components.homeseeker ~= nil then
            child:RemoveComponent("homeseeker")
        end

        if self.onoccupied ~= nil then
            self.onoccupied(self.inst, child)
        end

        return true
    end
end

function Spawner:OnChildKilled(child)
    if self.spawnsleft ~= nil and self.spawnsleft > 0 then
        self.spawnsleft = self.spawnsleft - 1
        if self.spawnsleft == 0 and self.onoutofspawns ~= nil then
            self.onoutofspawns(self.inst)
        end
    end

    if (self.spawnsleft == nil or self.spawnsleft > 0) and not self:IsOccupied() then
        self.child = nil
        self:SpawnWithDelay(self.delay)
    end
end

return Spawner