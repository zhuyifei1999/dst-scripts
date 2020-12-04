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

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onburnt(inst)
    inst.components.pickable.canbepicked = false
    inst.components.pickable.caninteractwith = false

    inst.components.trader.enabled = false

    inst.components.activatable.inactive = false
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

local function updatecompostlayers(inst)
    clearcompostlayers(inst)

    local composted_layers = inst.components.pickable.canbepicked and inst.components.pickable.numtoharvest ~= nil and inst.components.pickable.numtoharvest or 0
    local non_composted_layers = math.floor(((inst.components.compostingbin.greens or 0) + (inst.components.compostingbin.browns or 0)) / 2)

    local layers_filled = 0
    if composted_layers > 0 then
        for i=1,composted_layers do
            layers_filled = layers_filled + 1
            inst.AnimState:Show("compost"..layers_filled.."_3")
        end
    end
    if non_composted_layers > 0 then
        for i=1,non_composted_layers do
            layers_filled = layers_filled + 1
            inst.AnimState:Show("compost"..layers_filled.."_1")
        end
    end
end

local function resetcompostturned(inst)
    if not inst:HasTag("burnt") then
        inst.components.activatable.inactive = true
    end
end

local function setcompostturned(inst, loading)
    if not loading and inst.components.timer:TimerExists("composting") then
        inst.components.timer:SetTimeLeft("composting", inst.components.timer:GetTimeLeft("composting") * TUNING.COMPOSTINGBIN_TURN_COMPOST_DURATION_MULTIPLIER)
        inst.components.compostingbin.current_composting_time = inst.components.compostingbin.current_composting_time * TUNING.COMPOSTINGBIN_TURN_COMPOST_DURATION_MULTIPLIER
    end

    inst.components.activatable.inactive = false
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if not inst.AnimState:IsCurrentAnimation("spin") and not inst.AnimState:IsCurrentAnimation("place") then
            inst.AnimState:PlayAnimation("hit")
            if inst.components.timer:TimerExists("composting") then
                inst.AnimState:PushAnimation("working", true)
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
    inst.components.compostingbin.fertilizer_count = 0

    updatecompostlayers(inst)
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
    inst.AnimState:PlayAnimation("working", true)
    inst.SoundEmitter:PlaySound(sounds.loop, "lp")
end

local function onstopcomposting(inst)
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:KillSound("lp")
end

local function GetVerb()
    return "TURN"
end

local function onsetfertilizercount(inst, count)
    resetcompostturned(inst)

    if count > 0 then
        SetPickable(inst, true, count)

        if not POPULATING then
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("poopcloud").Transform:SetPosition(x, y + 2.5, z)
        end
    else
        SetPickable(inst, false)
    end
end

local function getstatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    end

    if inst.components.compostingbin:GetMaterialTotal() > 0 then
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
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound(sounds.place)
end

local function OnActivate(inst)
    setcompostturned(inst)

    inst.AnimState:PlayAnimation("spin")
    inst.SoundEmitter:PlaySound(sounds.spin)
    if inst.components.timer:TimerExists("composting") then
        inst.AnimState:PushAnimation("working", true)
    else
        inst.AnimState:PushAnimation("idle", false)
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

    if not inst:HasTag("burnt") and not inst.components.activatable.inactive then
        data.turned = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    else
        updatecompostlayers(inst)

        if inst.components.compostingbin:IsComposting() then
            onstartcomposting(inst)
        end

        if data.turned then
            setcompostturned(inst, true)
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

    inst.GetActivateVerb = GetVerb

    clearcompostlayers(inst)

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
    inst.components.compostingbin.onrefreshfn = updatecompostlayers
    inst.components.compostingbin.onsetfertilizercountfn = onsetfertilizercount
    inst.components.compostingbin.composting_time_min = TUNING.COMPOSTINGBIN_COMPOSTING_TIME_MIN
    inst.components.compostingbin.composting_time_max = TUNING.COMPOSTINGBIN_COMPOSTING_TIME_MAX

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.standingaction = true

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(accepttest)
    inst.components.trader.onaccept = onaccept
    -- Item is explicitly removed in onaccept instead, otherwise it is removed before the callback where composting values are checked
    inst.components.trader.deleteitemonaccept = false

    inst:AddComponent("pickable")
    inst.components.pickable.caninteractwith = false
    inst.components.pickable.onpickedfn = OnPicked
    inst.components.pickable.product = "compost"

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

    MakeMediumBurnable(inst, nil, nil, true)
    MakeSmallPropagator(inst)

    inst:ListenForEvent("onburnt", onburnt)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("compostingbin", fn, assets, prefabs),
    MakePlacer("compostingbin_placer", "compostingbin", "compostingbin", "idle")
