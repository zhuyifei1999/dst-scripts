require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/compostingbin.zip"),
    Asset("MINIMAP_IMAGE", "compostingbin"),
}

local prefabs =
{
    "collapse_small",
    "compost",
    "poopcloud",
}

local DONT_ACCEPT_FOODTYPES =
{
    [FOODTYPE.ELEMENTAL] = true,
    [FOODTYPE.GEARS] = true,
    [FOODTYPE.INSECT] = true,
    [FOODTYPE.BURNT] = true,
}

local sounds =
{
    place = "farming/common/farm/compost/place",
    loop = "farming/common/farm/compost/LP",
    spin = "farming/common/farm/compost/spin",
}

local WETDRYBALANCE_TO_INDEX =
{
    DRY = 1,
    BALANCED = 2,
    WET = 3,
}

local DURATION_MULTIPLIER =
{
    FAST = 0.7,
    MEDIUM = 0.85,
    SLOW = 1,
}

local MAX_COMPOST_ON_GROUND = 4

local function dropharvestablecompost(inst)
    for i = 1, inst.components.pickable.numtoharvest do
        inst.components.lootdropper:FlingItem(SpawnPrefab(inst.components.pickable.product))
    end
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    
    dropharvestablecompost(inst)
    
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function updategroundcompostlayers(inst)
    local num = inst.components.pickable.numtoharvest
    if num ~= nil and num > 0 then
        num = math.min(num, MAX_COMPOST_ON_GROUND)
        local count = 0

        for i = 1, num do
            inst.AnimState:Show("ground_compost"..i)
            count = count + 1
        end

        if count < MAX_COMPOST_ON_GROUND then
            for i = count + 1, MAX_COMPOST_ON_GROUND do
                inst.AnimState:Hide("ground_compost"..i)
            end
        end
    else
        for i = 1, MAX_COMPOST_ON_GROUND do
            inst.AnimState:Hide("ground_compost"..i)
        end
    end
end

local function clearcompostlayers(inst)
    inst.AnimState:Hide("compost1_1")
    inst.AnimState:Hide("compost1_2")
    inst.AnimState:Hide("compost1_3")
    inst.AnimState:Hide("compost2_1")
    inst.AnimState:Hide("compost2_2")
    inst.AnimState:Hide("compost2_3")
    inst.AnimState:Hide("compost3_1")
    inst.AnimState:Hide("compost3_2")
    inst.AnimState:Hide("compost3_3")
end

local function cleargroundcompostlayers(inst)
    inst.AnimState:Hide("ground_compost1")
    inst.AnimState:Hide("ground_compost2")
    inst.AnimState:Hide("ground_compost3")
    inst.AnimState:Hide("ground_compost4")
end

local function onburnt(inst)
    inst.components.timer:StopTimer("composting")

    dropharvestablecompost(inst)

    inst.components.pickable.numtoharvest = 0
    updategroundcompostlayers(inst)

    inst.components.pickable.canbepicked = false
    inst.components.pickable.caninteractwith = false

    inst.components.compostingbin.greens = 0
    inst.components.compostingbin.browns = 0

    inst.components.trader.enabled = false
    
    inst.SoundEmitter:KillSound("lp")
end

local function getwetdrybalance(inst)
    if inst.components.compostingbin.greens_ratio == nil then
        return nil
    end

    if inst.components.compostingbin.greens_ratio < 0.35 then
        return "DRY"
    elseif inst.components.compostingbin.greens_ratio > 0.65 then
        return "WET"
    else
        return "BALANCED"
    end
end

local function updatecompostlayers(inst)
    clearcompostlayers(inst)

    local non_composted_layers = math.floor(((inst.components.compostingbin.greens or 0) + (inst.components.compostingbin.browns or 0)) / 2)
    if non_composted_layers > 0 then
        local wetdrybalance_index = WETDRYBALANCE_TO_INDEX[getwetdrybalance(inst) or "BALANCED"]
        for i = 1, non_composted_layers do
            inst.AnimState:Show("compost"..i.."_"..wetdrybalance_index)
        end
    end
end

local function onrefresh(inst, cycle_completed)
    if cycle_completed then
        inst:DoTaskInTime(19*FRAMES, updatecompostlayers)
    else
        updatecompostlayers(inst)
    end
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if not inst.AnimState:IsCurrentAnimation("spin") and not inst.AnimState:IsCurrentAnimation("place") then
            inst.AnimState:PlayAnimation("hit")
            if inst.components.timer:TimerExists("composting") then
                inst.AnimState:PushAnimation("working_nospin", false)
            else
                inst.AnimState:PushAnimation("idle", false)
            end
        end
    end
end

local function SetPickable(inst, pickable, num)
    inst.components.pickable.canbepicked = pickable
    inst.components.pickable.caninteractwith = pickable
    inst.components.pickable.numtoharvest = num
end

local function OnPicked(inst)
    inst.components.pickable.numtoharvest = 0

    updatecompostlayers(inst)
    updategroundcompostlayers(inst)

    inst.AnimState:PlayAnimation("use")
end

local function accepttest(inst, item, giver)
    if inst.components.compostingbin:IsFull() or inst.AnimState:IsCurrentAnimation("spin") then
        return false
    end

    return item.components.forcecompostable ~= nil
        or (item.components.edible ~= nil and not DONT_ACCEPT_FOODTYPES[item.components.edible.foodtype])
end

local function onaccept(inst, giver, item)
    if item == nil or not item:IsValid() then
        return
    end

    local greens, browns = 0, 0

    if item.components.forcecompostable ~= nil then
        if item.components.forcecompostable.green then
            greens = 1
        elseif item.components.forcecompostable.brown then
            browns = 1
        end
    else
        if item.components.edible ~= nil then
            if item.components.edible.foodtype == FOODTYPE.ROUGHAGE or item.components.edible.foodtype == FOODTYPE.WOOD then
                browns = 1
            else
                greens = 1
            end
        end
    end

    item:Remove()

    if greens > 0 or browns > 0 then
        inst.components.compostingbin:AddMaterials(greens, browns)
    end
end

local function onstartcomposting(inst)
    inst.AnimState:PlayAnimation("working", false)
    -- inst.SoundEmitter:PlaySound(sounds.spin)
    inst.SoundEmitter:PlaySound(sounds.loop, "lp")
end

local function onstopcomposting(inst)
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:KillSound("lp")
end

local function getstatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    end
    
    if inst.components.timer:TimerExists("composting") then
        return getwetdrybalance(inst)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound(sounds.place)
end

local function ontimerdone(inst, data)
    if data ~= nil and data.name == "composting" then
        if inst.components.pickable.numtoharvest >= MAX_COMPOST_ON_GROUND then
            inst.AnimState:PlayAnimation("use")
            updategroundcompostlayers(inst)
        else
            inst.AnimState:PlayAnimation("drop")
            if inst.components.compostingbin:GetMaterialTotal() >= 2 then
                inst.AnimState:PushAnimation("working_nospin", false)
            else
                inst.AnimState:PushAnimation("idle", false)
            end
            inst:DoTaskInTime(22*FRAMES, updategroundcompostlayers)
        end
    end
end

local function onfinishcycle(inst)
    if inst.components.pickable.numtoharvest >= MAX_COMPOST_ON_GROUND then
        inst.components.lootdropper:FlingItem(SpawnPrefab(inst.components.pickable.product))
    else
        inst.components.pickable.numtoharvest = inst.components.pickable.numtoharvest + 1
        SetPickable(inst, true, inst.components.pickable.numtoharvest)
    end
end

local function calcdurationmult(inst)
    local num_materials = inst.components.compostingbin:GetMaterialTotal()
    return (num_materials >= 6 and DURATION_MULTIPLIER.FAST)
        or (num_materials >= 4 and DURATION_MULTIPLIER.MEDIUM)
        or DURATION_MULTIPLIER.SLOW
end

local function animqueueover(inst)
    if inst.components.timer:TimerExists("composting") then
        inst.AnimState:PlayAnimation("working", false)
        -- inst.SoundEmitter:PlaySound(sounds.spin)

        local materialcount = inst.components.compostingbin:GetMaterialTotal()
        if materialcount < 5 then
            inst.AnimState:PushAnimation("working_nospin", false)
            if materialcount < 3 then
                inst.AnimState:PushAnimation("working_nospin", false)
            end
        end
    end
end

local function OnEntitySleep(inst)
    if inst.components.timer:TimerExists("composting") then
        inst.SoundEmitter:KillSound("lp")
    end
end

local function OnEntityWake(inst)
    if inst.components.timer:TimerExists("composting") then
        inst.SoundEmitter:PlaySound(sounds.loop, "lp")
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end

    if inst.components.pickable.numtoharvest > 0 then
        -- This isn't saved on the pickable component
        data.numtoharvest = inst.components.pickable.numtoharvest
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
        onburnt(inst)
    else
        if data ~= nil and data.numtoharvest ~= nil and data.numtoharvest > 0 then
            inst.components.pickable.numtoharvest = data.numtoharvest
        end

        updatecompostlayers(inst)
        updategroundcompostlayers(inst)

        if inst.components.compostingbin:IsComposting() then
            onstartcomposting(inst)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("compostingbin.png")

    inst:AddTag("structure")

    inst.AnimState:SetBank("compostingbin")
    inst.AnimState:SetBuild("compostingbin")
    inst.AnimState:PlayAnimation("idle")

    clearcompostlayers(inst)
    cleargroundcompostlayers(inst)

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("timer")
    inst:AddComponent("compostingbin")
    inst.components.compostingbin.onstartcompostingfn = onstartcomposting
    inst.components.compostingbin.onstopcompostingfn = onstopcomposting
    inst.components.compostingbin.onrefreshfn = onrefresh
    inst.components.compostingbin.finishcyclefn = onfinishcycle
    inst.components.compostingbin.calcdurationmultfn = calcdurationmult
    inst.components.compostingbin.composting_time_min = TUNING.COMPOSTINGBIN_COMPOSTING_TIME_MIN
    inst.components.compostingbin.composting_time_max = TUNING.COMPOSTINGBIN_COMPOSTING_TIME_MAX

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(accepttest)
    inst.components.trader.onaccept = onaccept
    -- Item is explicitly removed in onaccept instead, otherwise it is removed before the callback where composting values are checked
    inst.components.trader.deleteitemonaccept = false

    inst:AddComponent("pickable")
    inst.components.pickable.caninteractwith = false
    inst.components.pickable.onpickedfn = OnPicked
    inst.components.pickable.product = "compost"
    inst.components.pickable.numtoharvest = 0

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    MakeSnowCovered(inst)
    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("timerdone", ontimerdone)

    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst:ListenForEvent("onburnt", onburnt)
    inst:ListenForEvent("animqueueover", animqueueover)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("compostingbin", fn, assets, prefabs),
    MakePlacer("compostingbin_placer", "compostingbin", "compostingbin", "idle")
