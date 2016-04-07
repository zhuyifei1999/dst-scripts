local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/maxwell.fsb"),
}

local prefabs =
{
    "shadow_despawn",
    "statue_transition_2",
}

local start_inv =
{
    "waxwelljournal",
    "nightmarefuel",
    "nightmarefuel",
    "nightmarefuel",
    "nightmarefuel",
    "nightmarefuel",
    "nightmarefuel",
}

local function DoEffects(pet)
    local x, y, z = pet.Transform:GetWorldPosition()
    SpawnPrefab("shadow_despawn").Transform:SetPosition(x, y, z)
    SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
end

local function KillPet(pet)
    pet.components.health:Kill()
end

local function OnSpawn(inst, pet)
    --Delayed in case we need to relocate for migration spawning
    pet:DoTaskInTime(0, DoEffects)

    if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
        inst.components.sanity:AddSanityPenalty(pet, TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)])
        inst:ListenForEvent("onremove", inst._onpetlost, pet)
    elseif pet._killtask == nil then
        pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
    end
end

local function OnDespawn(inst, pet)
    DoEffects(pet)
    pet:Remove()
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v._killtask == nil then
            v._killtask = v:DoTaskInTime(math.random(), KillPet)
        end
    end
end

local function common_postinit(inst)
    inst:AddTag("shadowmagic")

    --reader (from reader component) added to pristine state for optimization
    inst:AddTag("reader")
end

local function master_postinit(inst)
    inst:AddComponent("reader")

    inst:AddComponent("petleash")
    inst.components.petleash:SetOnSpawnFn(OnSpawn)
    inst.components.petleash:SetOnDespawnFn(OnDespawn)
    inst.components.petleash:SetMaxPets(4)

    inst.components.sanity.dapperness = TUNING.DAPPERNESS_LARGE
    inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * .5)
    inst.soundsname = "maxwell"

    inst._onpetlost = function(pet) inst.components.sanity:RemoveSanityPenalty(pet) end

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("ms_becomeghost", OnDeath)
end

return MakePlayerCharacter("waxwell", prefabs, assets, common_postinit, master_postinit, start_inv)
