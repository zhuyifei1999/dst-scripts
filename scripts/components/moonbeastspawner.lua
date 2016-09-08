local MoonBeastSpawner = Class(function(self, inst)
    self.inst = inst

    self.started = false
    self.range = 30
    self.period = 3
    self.maxspawns = 6
    self.task = nil
end)

function MoonBeastSpawner:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

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

    if offscreenworkers ~= nil and #offscreenworkers > 0 then
        local walls = TheSim:FindEntities(pos.x, pos.y, pos.z, 10, nil, nil, { "wall", "playerskeleton" })
        for i, v in ipairs(walls) do
            if math.random(self.maxspawns * 2 + 1) <= #offscreenworkers then
                if v.components.health ~= nil and not v.components.health:IsDead() then
                    --walls
                    v.components.health:Kill()
                elseif v.components.workable ~= nil and v.components.workable:CanBeWorked() then
                    --skellies
                    v.components.workable:Destroy(inst)
                end
            end
        end
        for i, v in ipairs(offscreenworkers) do
            inst.components.workable:WorkedBy(v, 1)
            if not self.started then
                return
            end
        end
    end

    local maxwavespawn = math.random(2)
    for i = #ents + 1, self.maxspawns do
        local offset
        if inst:IsAsleep() then
            local numattempts = 3
            local minrange = 3
            for attempt = 1, numattempts do
                offset = FindWalkableOffset(pos, math.random() * 2 * PI, GetRandomMinMax(minrange, math.max(minrange, minrange + .9 * (self.range - minrange) * attempt / numattempts)), 16, false, true)
                local x1 = pos.x + offset.x
                local z1 = pos.z + offset.z
                local collisions = TheSim:FindEntities(x1, 0, z1, 4, nil, { "INLIMBO" })
                for i, v in ipairs(collisions) do
                    local r = v.Physics ~= nil and v.Physics:GetRadius() + 1 or 1
                    if v:GetDistanceSqToPoint(x1, 0, z1) < r * r then
                        offset = nil
                        break
                    end
                end
                if offset ~= nil then
                    break
                end
            end
        else
            offset = FindWalkableOffset(pos, math.random() * 2 * PI, self.range, 16, false, true)
        end
        if offset ~= nil then
            local creature = SpawnPrefab(MOONBEASTS[math.random(#MOONBEASTS)])
            creature.components.entitytracker:TrackEntity("moonbase", inst)
            creature.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
            creature:ForceFacePoint(pos)
            creature:FadeIn()
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
        if v.brain ~= nil then
            v.brain:ForcePetrify()
        end
        if v:IsAsleep() then
            v:PushEvent("moonpetrify")
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

        --Normally the brain will handle petrification after some time instead
        if self.inst:IsAsleep() then
            self:ForcePetrify()
        end
    end
end

return MoonBeastSpawner
