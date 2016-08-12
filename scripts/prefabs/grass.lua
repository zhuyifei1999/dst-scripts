local assets =
{
    Asset("ANIM", "anim/grass.zip"),
    Asset("ANIM", "anim/grass1.zip"),
    Asset("ANIM", "anim/grass_diseased_build.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "cutgrass",
    "dug_grass",
    "disease_puff",
    "diseaseflies",
    "spoiled_food",
}

local function SpawnDiseasePuff(inst)
    SpawnPrefab("disease_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function dig_up(inst, worker)
    if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
        local withered = inst.components.witherable ~= nil and inst.components.witherable:IsWithered()
        local diseased = inst.components.diseaseable ~= nil and inst.components.diseaseable:IsDiseased()

        if diseased then
            SpawnDiseasePuff(inst)
        elseif inst.components.diseaseable ~= nil and inst.components.diseaseable:IsBecomingDiseased() then
            SpawnDiseasePuff(inst)
            if worker ~= nil then
                worker:PushEvent("digdiseasing")
            end
        end

        if inst.components.pickable:CanBePicked() then
            inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product)
        end

        inst.components.lootdropper:SpawnLootPrefab(
            (withered or diseased) and
            "cutgrass" or
            "dug_grass"
        )
    end
    inst:Remove()
end

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function makeemptyfn(inst)
    if not POPULATING and
        (   inst.components.witherable ~= nil and
            inst.components.witherable:IsWithered() or
            inst.AnimState:IsCurrentAnimation("idle_dead")
        ) then
        inst.AnimState:PlayAnimation("dead_to_empty")
        inst.AnimState:PushAnimation("picked", false)
    else
        inst.AnimState:PlayAnimation("picked")
    end
end

local function makebarrenfn(inst, wasempty)
    if not POPULATING and
        (   inst.components.witherable ~= nil and
            inst.components.witherable:IsWithered()
        ) then
        inst.AnimState:PlayAnimation(wasempty and "empty_to_dead" or "full_to_dead")
        inst.AnimState:PushAnimation("idle_dead", false)
    else
        inst.AnimState:PlayAnimation("idle_dead")
    end
end

local function onpickedfn(inst, picker)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
    inst.AnimState:PlayAnimation("picking")

    if inst.components.diseaseable ~= nil then
        if inst.components.diseaseable:IsDiseased() then
            SpawnDiseasePuff(inst)
        elseif inst.components.diseaseable:IsBecomingDiseased() then
            SpawnDiseasePuff(inst)
            if picker ~= nil then
                picker:PushEvent("pickdiseasing")
            end
        end
    end

    if inst.components.pickable:IsBarren() then
        inst.AnimState:PushAnimation("empty_to_dead")
        inst.AnimState:PushAnimation("idle_dead", false)
    else
        inst.AnimState:PushAnimation("picked", false)
    end
end

local function SetDiseaseBuild(inst)
    inst.AnimState:SetBuild("grass_diseased_build")
end

local function ondiseasedfn(inst)
    inst.components.pickable:ChangeProduct("spoiled_food")
    if POPULATING then
        SetDiseaseBuild(inst)
    elseif inst.components.pickable:CanBePicked() then
        inst.AnimState:PlayAnimation("rustle")
        inst.AnimState:PushAnimation("idle", true)
        SpawnDiseasePuff(inst)
        inst:DoTaskInTime(4 * FRAMES, SetDiseaseBuild)
    else
        if inst.components.witherable ~= nil and
            inst.components.witherable:IsWithered() or
            inst.components.pickable:IsBarren() then
            inst.AnimState:PlayAnimation("rustle_dead")
            inst.AnimState:PushAnimation("idle_dead", false)
        else
            inst.AnimState:PlayAnimation("rustle_empty")
            inst.AnimState:PushAnimation("picked", false)
        end
        inst:DoTaskInTime(2 * FRAMES, SpawnDiseasePuff)
        inst:DoTaskInTime(6 * FRAMES, SetDiseaseBuild)
    end
end

local function makediseaseable(inst)
    if inst.components.diseaseable == nil then
        inst:AddComponent("diseaseable")
        inst.components.diseaseable:SetDiseasedFn(ondiseasedfn)
    end
end

local function ontransplantfn(inst)
    inst.components.pickable:MakeBarren()
    makediseaseable(inst)
    inst.components.diseaseable:RestartNearbySpread()
end

local function OnPreLoad(inst, data)
    if data ~= nil and (data.pickable ~= nil and data.pickable.transplanted or data.diseaseable ~= nil) then
        makediseaseable(inst)
    end
end

local function grass(name, stage)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon("grass.png")
        
        inst.AnimState:SetBank("grass")
        inst.AnimState:SetBuild("grass1")
        inst.AnimState:PlayAnimation("idle", true)

        inst:AddTag("renewable")

        inst:AddTag("disease_check_grass")

        --witherable (from witherable component) added to pristine state for optimization
        inst:AddTag("witherable")

        MakeDragonflyBait(inst, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.AnimState:SetTime(math.random() * 2)
        local color = 0.75 + math.random() * 0.25
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst:AddComponent("pickable")
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

        inst.components.pickable:SetUp("cutgrass", TUNING.GRASS_REGROW_TIME)
        inst.components.pickable.onregenfn = onregenfn
        inst.components.pickable.onpickedfn = onpickedfn
        inst.components.pickable.makeemptyfn = makeemptyfn
        inst.components.pickable.makebarrenfn = makebarrenfn
        inst.components.pickable.max_cycles = 20
        inst.components.pickable.cycles_left = 20
        inst.components.pickable.ontransplantfn = ontransplantfn

        inst:AddComponent("witherable")

        if stage == 1 then
            inst.components.pickable:MakeBarren()
        end

        inst:AddComponent("lootdropper")
        inst:AddComponent("inspectable")

        --inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(dig_up)
        inst.components.workable:SetWorkLeft(1)

        ---------------------

        MakeMediumBurnable(inst)
        MakeSmallPropagator(inst)
        MakeNoGrowInWinter(inst)
        MakeHauntableIgnite(inst)
        ---------------------

        inst.OnPreLoad = OnPreLoad
        inst.MakeDiseaseable = makediseaseable

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return grass("grass", 0),
    grass("depleted_grass", 1)
