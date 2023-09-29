-- DO NOT change their order.
local MUTATIONS_NAMES =
{
    "mutatedwarg",
    "mutatedbearger",
    "mutateddeerclops",
}

local MUTATIONS = table.invert(MUTATIONS_NAMES)

local MUTATIONS_EXTENDED_DESTROYTIME = 15

local LunarRiftMutationsManager = Class(function(self, inst)
    assert(TheWorld.ismastersim, "Lunar Rift Mutations Manager should not exist on client!")

    self.inst = inst

    self._MUTATIONS_NAMES = MUTATIONS_NAMES -- Mods.
    self._MUTATIONS = MUTATIONS -- Mods.

    self:RefreshDefeatedMutationsTable()
end)

function LunarRiftMutationsManager:RefreshDefeatedMutationsTable()
    self.wagstaff = nil

    self.defeated_mutations = {}

    self.num_mutations = #MUTATIONS_NAMES
end

function LunarRiftMutationsManager:IsWagstaffSpawned()
    return self.wagstaff ~= nil and self.wagstaff:IsValid() and not self.wagstaff.erodingout
end

function LunarRiftMutationsManager:GetNumDefeatedMutations()
    return #self.defeated_mutations
end

function LunarRiftMutationsManager:HasDefeatedAllMutations()
    return self:GetNumDefeatedMutations() >= self.num_mutations
end

function LunarRiftMutationsManager:_CanCorpseMutate(ent)
    return
        TheWorld.components.riftspawner ~= nil and
        TheWorld.components.riftspawner:IsLunarPortalActive() and
        (ent.components.burnable == nil or not ent.components.burnable:IsBurning())
end

function LunarRiftMutationsManager:TryMutate(ent, corpseprefab)
    if self:_CanCorpseMutate(ent) then
        local rot = ent:GetRotation()

        local corpse = ReplacePrefab(ent, corpseprefab)

        corpse.Transform:SetRotation(rot)
        corpse.AnimState:MakeFacingDirty() -- Not needed for clients.

        return corpse -- Mods.
    end
end

function LunarRiftMutationsManager:HasDefeatedThisMutation(prefab)
    if MUTATIONS[prefab] == nil then
        return false
    end

    return table.contains(self.defeated_mutations, MUTATIONS[prefab])
end

function LunarRiftMutationsManager:SetMutationDefeated(ent)
    local prefab = ent.prefab

    if MUTATIONS[prefab] ~= nil and not table.contains(self.defeated_mutations, MUTATIONS[prefab]) then
        table.insert(self.defeated_mutations, MUTATIONS[prefab])

        if self:IsWagstaffSpawned() then
            self.wagstaff:TalkAboutMutatedCreature(true)
        else
            ent.components.health.destroytime = MUTATIONS_EXTENDED_DESTROYTIME
            self:TriggerWagstaffAppearance(ent)
        end
    end
end

function LunarRiftMutationsManager:TriggerWagstaffAppearance(ent)
    local pos = ent:GetPosition()
    local offset = FindWalkableOffset(pos, math.random()*TWOPI, 8, 12, false, false, nil, false, true)

    if offset ~= nil then
        pos = pos + offset
    end

    self.wagstaff = SpawnPrefab("wagstaff_npc_mutations")

    if self:IsWagstaffSpawned() then
        self.wagstaff.Transform:SetPosition(pos:Get())
        self.wagstaff:TalkAboutMutatedCreature()
    end
end

function LunarRiftMutationsManager:OnSave()
    local data = {
        defeated_mutations = shallowcopy(self.defeated_mutations),
    }

    return next(data.defeated_mutations) and data or nil
end

function LunarRiftMutationsManager:OnLoad(data)
    if not data then return end

    if data.defeated_mutations ~= nil then
        self.defeated_mutations = data.defeated_mutations
    end
end

function LunarRiftMutationsManager:GetDebugString()
    local defeated = {}

    for _, i in ipairs(self.defeated_mutations) do
        table.insert(defeated, MUTATIONS_NAMES[i])
    end

    return string.format(
        "Mutations Defeated: %d/%d   [ %s ]",
        self:GetNumDefeatedMutations(),
        self.num_mutations,
        table.concat(defeated, ", ")
    )
end

return LunarRiftMutationsManager
