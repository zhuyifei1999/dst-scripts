local assets =
{
    Asset("ANIM", "anim/statue_ruins_small.zip"),
    Asset("ANIM", "anim/statue_ruins_small_gem.zip"),
    Asset("ANIM", "anim/statue_ruins.zip"),
    Asset("ANIM", "anim/statue_ruins_gem.zip"),
	Asset("MINIMAP_IMAGE", "statue_ruins"),
}

local prefabs =
{
    "marble",
    "greengem",
    "redgem",
    "bluegem",
    "yellowgem",
    "orangegem",
    "purplegem",
    "nightmarefuel",
    "collapse_small",
    "thulecite",
}

local gemlist =
{
    "greengem",
    "redgem",
    "bluegem",
    "yellowgem",
    "orangegem",
    "purplegem",
}

SetSharedLootTable('statue_ruins_no_gem',
{
    {'thulecite',     1.00},
    {'nightmarefuel', 1.00},
    {'thulecite',     0.05},
})

local MAX_LIGHT_ON_FRAME = 15
local MAX_LIGHT_OFF_FRAME = 30

local function OnUpdateLight(inst, dframes)
    local frame = inst._lightframe:value() + dframes
    if frame >= inst._lightmaxframe then
        inst._lightframe:set_local(inst._lightmaxframe)
        inst._lighttask:Cancel()
        inst._lighttask = nil
    else
        inst._lightframe:set_local(frame)
    end

    local k = frame / inst._lightmaxframe
    inst.Light:SetRadius(inst._lightradius1:value() * k + inst._lightradius0:value() * (1 - k))

    if TheWorld.ismastersim then
        inst.Light:Enable(inst._lightradius1:value() > 0 or frame < inst._lightmaxframe)
    end
end

local function OnLightDirty(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, 1)
    end
    inst._lightmaxframe = inst._lightradius1:value() > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME
    OnUpdateLight(inst, 0)
end

local function DoFx(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition_2")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 2, 1)
    end
    fx = SpawnPrefab("statue_transition")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 1.5, 1)
    end
end

local function fade_to(inst, rad)
    rad = rad or 0
    if inst._lightradius1:value() ~= rad then
        local k = inst._lightframe:value() / inst._lightmaxframe
        local radius = inst._lightradius1:value() * k + inst._lightradius0:value() * (1 - k)
        local minradius0 = math.min(inst._lightradius0:value(), inst._lightradius1:value())
        local maxradius0 = math.max(inst._lightradius0:value(), inst._lightradius1:value())
        if radius > rad then
            inst._lightradius0:set(radius > minradius0 and maxradius0 or minradius0)
        else
            inst._lightradius0:set(radius < maxradius0 and minradius0 or maxradius0)
        end
        local maxframe = rad > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME
        inst._lightradius1:set(rad)
        inst._lightframe:set(math.max(0, math.floor((radius - inst._lightradius0:value()) / (rad - inst._lightradius0:value()) * maxframe + .5)))
        OnLightDirty(inst)
    end
end

local function ShowState(inst, phase, fromwork)
    if inst.fading then
        return
    end

    local suffix = ""
    local workleft = inst.components.workable.workleft

    if inst.small and not inst.SoundEmitter:PlayingSound("hoverloop") then
        inst.SoundEmitter:PlaySound("dontstarve/common/floating_statue_hum", "hoverloop")
    end
    if inst.gemmed then
        inst.AnimState:OverrideSymbol("swap_gem", inst.small and "statue_ruins_small_gem" or "statue_ruins_gem", inst.gemmed)
    end

    if phase ~= nil then
        if phase == "warn" then
            fade_to(inst, 2)
        elseif phase == "wild" then
            suffix = "_night"
            fade_to(inst, 4)
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
            DoFx(inst)
        elseif phase == "dawn" then
            fade_to(inst, 2)
            inst.AnimState:ClearBloomEffectHandle()
            DoFx(inst)
        elseif phase == "calm" then
            fade_to(inst, 0)
        end
    elseif fromwork then
        -- we don't actually have hit animations, we just play the animation
    end

    inst.AnimState:PlayAnimation(
        ((workleft < TUNING.MARBLEPILLAR_MINE / 3 and "hit_low") or
        (workleft < TUNING.MARBLEPILLAR_MINE * 2 / 3 and "hit_med") or
        "idle_full")..suffix,
        true
    )
end

local function OnWorked(inst, worked, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:KillSound("hoverloop")
        inst.components.lootdropper:DropLoot(inst:GetPosition())
        local fx = SpawnAt("collapse_small", inst)
        fx:SetMaterial("rock")

        if TheWorld.state.isnightmarewild then
            if math.random() <= 0.3 then
                if math.random() <= 0.5 then
                    SpawnAt("crawlingnightmare", inst)
                else
                    SpawnAt("nightmarebeak", inst)
                end
            end
        end

        inst:Remove()
    else
        ShowState(inst, nil, true)
    end
end

local function OnPhaseChanged(inst, phase, instant)
    if instant then
        ShowState(inst, phase)
    else
        inst:DoTaskInTime(math.random() * 2, ShowState, phase)
    end
end

local function onsave(inst, data)
    data.gem = inst.gemmed
end

local function onload(inst, data)
    if data and data.gem then
        inst.gemmed = data.gem
    end
end

local function commonfn(small)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.66)

    if small then
        inst.AnimState:SetBank("statue_ruins_small")
        inst.AnimState:SetBuild("statue_ruins_small")
    else
        inst.AnimState:SetBank("statue_ruins")
        inst.AnimState:SetBuild("statue_ruins")
    end

    inst.MiniMapEntity:SetIcon("statue_ruins.png")

    inst:AddTag("cavedweller")
    inst:AddTag("structure")
    inst:AddTag("statue")

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.9)
    inst.Light:SetFalloff(.9)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst._lightframe = net_smallbyte(inst.GUID, "ruins_statue._lightframe", "lightdirty")
    inst._lightradius0 = net_tinybyte(inst.GUID, "ruins_statue._lightradius0", "lightdirty")
    inst._lightradius1 = net_tinybyte(inst.GUID, "ruins_statue._lightradius1", "lightdirty")
    inst._lightmaxframe = MAX_LIGHT_OFF_FRAME
    inst._lightframe:set(inst._lightmaxframe)
    inst._lighttask = nil

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", OnLightDirty)

        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst.small = small

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "ANCIENT_STATUE"
    inst:AddComponent("named")
    inst.components.named:SetName(STRINGS.NAMES["ANCIENT_STATUE"])

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
    inst.components.workable:SetOnWorkCallback(OnWorked)

    inst:AddComponent("fader")

    inst:AddComponent("lootdropper")

    inst:WatchWorldState("nightmarephase", OnPhaseChanged)
    inst:DoTaskInTime(0, function()
        OnPhaseChanged(inst, TheWorld.state.nightmarephase, true)
    end)

    MakeHauntableWork(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

local function gem(small)
    local inst = commonfn(small)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.gemmed = GetRandomItem(gemlist)

    inst.AnimState:OverrideSymbol("swap_gem", small and "statue_ruins_small_gem" or "statue_ruins_gem", inst.gemmed)

    inst.components.lootdropper:SetLoot({ "thulecite", inst.gemmed })
    inst.components.lootdropper:AddChanceLoot("thulecite", 0.05)

    return inst
end

local function nogem(small)
    local inst = commonfn(small)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('statue_ruins_no_gem')

    return inst
end

return Prefab("ruins_statue_head", function() return gem(true) end, assets, prefabs),
    Prefab("ruins_statue_head_nogem", function() return nogem(true) end, assets, prefabs),
    Prefab("ruins_statue_mage", function() return gem() end, assets, prefabs),
    Prefab("ruins_statue_mage_nogem", function() return nogem() end, assets, prefabs)
