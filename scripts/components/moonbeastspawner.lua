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

local function MorphMoonBeast(old, moonbase)
    if not old.components.health:IsDead() then
        local x, y, z = old.Transform:GetWorldPosition()
        local rot = old.Transform:GetRotation()
        local oldprefab = old.prefab
        local newprefab = old:HasTag("werepig") and "moonpig" or "moonhound"
        local new = SpawnPrefab(newprefab)
        new.components.entitytracker:TrackEntity("moonbase", moonbase)
        new.Transform:SetPosition(x, y, z)
        new.Transform:SetRotation(rot)
        old:PushEvent("detachchild")
        new:PushEvent("moontransformed", { old = old })
        old.persists = false
        old.entity:Hide()
        old:DoTaskInTime(0, old.Remove)
    end
end

local function DoSpawn(inst, self)
    local pos = inst:GetPosition()
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, self.range, nil, { "INLIMBO" }, { --[["moonbeast",]] "gargoyle", "werepig", "hound" })
    local offscreenworkers = inst:IsAsleep() and {} or nil

    for i, v in ipairs(ents) do
        if not (v:HasTag("moonbeast") or v:HasTag("gargoyle")) then
            --claim regular werepigs and hounds
            if v.sg:HasStateTag("busy") then
                MorphMoonBeast(v, inst)
            elseif not v._morphmoonbeast then
                v._morphmoonbeast = true
                v:ListenForEvent("newstate", function()
                    if not v.sg:HasStateTag("busy") and v._morphmoonbeast == true then
                        v._morphmoonbeast = v:DoTaskInTime(0, MorphMoonBeast, inst)
                    end
                end)
            end
        elseif offscreenworkers ~= nil and v.components.combat ~= nil and math.random() < .25 then
            table.insert(offscreenworkers, v)
        end
    end

    if offscreenworkers ~= nil then
        for i, v in ipairs(offscreenworkers) do
            inst.components.workable:WorkedBy(v, 1)
            if not self.started then
                return
            end
        end
    end

    local maxwavespawn = math.random(2)
    for i = #ents + 1, self.maxspawns do
        local offset = FindWalkableOffset(pos, math.random() * 2 * PI, self.range, 16, false, true)
        if offset ~= nil then
            local creature = SpawnPrefab(MOONBEASTS[math.random(#MOONBEASTS)])
            creature.components.entitytracker:TrackEntity("moonbase", inst)
            creature.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
            if maxwavespawn > 1 then
                maxwavespawn = maxwavespawn - 1
            else
                return
            end
        end
    end
end

function MoonBeastSpawner:ForcePetrify()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, self.range, { "moonbeast" }, { "INLIMBO" })
    for i, v in ipairs(ents) do
        v.brain:ForcePetrify()
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
