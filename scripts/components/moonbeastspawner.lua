local MoonBeastSpawner = Class(function(self, inst)
    self.inst = inst

    self.started = false
    self.range = 30
    self.period = 3
    self.maxspawns = 6
    self.task = nil
end)

local MOONBEASTS =
{
    "moonhound",
    "moonpig",
}

local function DoSpawn(inst, self)
    local map = TheWorld.Map
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, self.range, nil, { "INLIMBO" }, { "moonbeast", "gargoyle" })

    if inst:IsAsleep() then
        for i, v in ipairs(ents) do
            if v.components.combat ~= nil and math.random() < .25 then
                inst.components.workable:WorkedBy(v, 1)
                if not self.started then
                    return
                end
            end
        end
    end

    local maxwavespawn = math.random(2)
    for i = #ents + 1, self.maxspawns do
        local angle = math.random() * 2 * PI
        local x1 = x + self.range * math.cos(angle)
        local z1 = z + self.range * math.sin(angle)
        if map:IsPassableAtPoint(x1, 0, z1) then
            local creature = SpawnPrefab(MOONBEASTS[math.random(#MOONBEASTS)])
            creature.components.entitytracker:TrackEntity("moonbase", inst)
            creature.Transform:SetPosition(x1, 0, z1)
            if maxwavespawn > 1 then
                maxwavespawn = maxwavespawn - 1
            else
                return
            end
        end
    end
end

function MoonBeastSpawner:Start()
    if not self.started then
        self.started = true

        local x, y, z = self.inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, self.range, { "gargoyle" })
        for i, v in ipairs(ents) do
            v:Reanimate(self.inst)
        end

        self.task = self.inst:DoPeriodicTask(self.period, DoSpawn, nil, self)
    end
end

function MoonBeastSpawner:Stop()
    if self.started then
        self.started = false
        self.task:Cancel()
        self.task = nil
    end
end

MoonBeastSpawner.OnRemoveFromEntity = MoonBeastSpawner.Stop

return MoonBeastSpawner
