local assets =
{
    Asset("ANIM", "anim/leif_idol.zip"),
}

local prefabs = {
    "leif",
}

local LEIF_MUST_TAGS = { "leif" }

local LEIFTARGET_MUST_TAGS = { "tree" }
local LEIFTARGET_ONEOF_TAGS = { "evergreens", "birchnut" }
local LEIFTARGET_CANT_TAGS = { "leif", "fire", "stump", "burnt", "monster", "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function CanTransformIntoLeifTest(inst, target)
    return
        target:HasTag("evergreens")
        and (
                not target.noleif and
                target.components.growable ~= nil and
                target.components.growable.stage <= 3
            )
        or
            (
                target.leaf_state ~= "barren" and
                not target.monster and
                target.monster_start_task == nil and
                target.monster_stop_task == nil and
                target.domonsterstop_task == nil
            )
end

local function DelayedStartMonster(inst)
    inst.monster_start_task = nil
    inst:StartMonster()
end

local function WakeUpLeif(ent)
    ent.components.sleeper:WakeUp()
end

local function WakeUpNearbyLeifs(inst, x, y, z, doer)
    local ents = TheSim:FindEntities(x, y, z, TUNING.LEIF_REAWAKEN_RADIUS, LEIF_MUST_TAGS)

    for i, v in ipairs(ents) do
        if v.components.sleeper ~= nil and v.components.sleeper:IsAsleep() then
            v:DoTaskInTime(math.random(), WakeUpLeif)
        end

        v.components.combat:SuggestTarget(doer)
    end

    return ents
end

local function SpawnNewLeifs(inst, x, y, z, doer)
    local num_spawns = TUNING.LEIF_IDOL_NUM_SPAWNS

    local ents = TheSim:FindEntities(x, y, z, TUNING.LEIF_IDOL_SPAWN_RADIUS, LEIFTARGET_MUST_TAGS, LEIFTARGET_CANT_TAGS, LEIFTARGET_ONEOF_TAGS)

    for i, ent in ipairs(ents) do
        if inst:CanTransformIntoLeifTest(ent) then
            if ent.TransformIntoLeif ~= nil then
                ent:TransformIntoLeif(doer)
                num_spawns = num_spawns - 1

            elseif ent.StartMonster ~= nil then
                ent.monster_start_task = ent:DoTaskInTime(math.random(1, 4), DelayedStartMonster)
                num_spawns = num_spawns - 1
            end

            if num_spawns <= 0 then
                break
            end
        end
    end

    return ents, num_spawns
end

local function IsValidDoer(doer)
    return EntityScript.is_instance(doer) and doer.components.combat ~= nil and doer or nil
end

local function OnIgnite(inst, source, _doer)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/livinglog_burn")

    local x, y, z = inst.Transform:GetWorldPosition()

    local doer = IsValidDoer(source) or IsValidDoer(_doer)

    if doer ~= nil then
        -- Tell any nearby leifs to wake up.
        inst:WakeUpNearbyLeifs(x, y, z, doer)
        
        -- Spawn new ones.
        inst:SpawnNewLeifs(x, y, z, doer)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("leif_idol")
    inst.AnimState:SetBuild("leif_idol")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "small", .2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    -- Mod support
    inst.WakeUpNearbyLeifs = WakeUpNearbyLeifs
    inst.SpawnNewLeifs = SpawnNewLeifs
    inst.CanTransformIntoLeifTest = CanTransformIntoLeifTest

    MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)

    inst.components.burnable:SetOnIgniteFn(OnIgnite)

    MakeHauntableLaunchAndIgnite(inst)

    return inst
end

return Prefab("leif_idol", fn, assets, prefabs)
