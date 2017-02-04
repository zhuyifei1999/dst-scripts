local assets =
{
    Asset("ANIM", "anim/townportal.zip"),
    Asset("MINIMAP_IMAGE", "townportalactive"),
}

local prefabs =
{
    "collapse_small",
    "globalmapicon",
}

local function OnStartChanneling(inst, channeler)
    inst.AnimState:PlayAnimation("turn_on")
    inst.AnimState:PushAnimation("idle_on_loop")
    inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/idle", "active")
    TheWorld:PushEvent("townportalactivated", inst)

    inst.MiniMapEntity:SetIcon("townportalactive.png")
    inst.MiniMapEntity:SetPriority(20)

    if inst.icon ~= nil then
        inst.icon.MiniMapEntity:SetIcon("townportalactive.png")
        inst.icon.MiniMapEntity:SetPriority(20)
        inst.icon.MiniMapEntity:SetDrawOverFogOfWar(true)
    end

    inst.channeler = channeler.components.sanity ~= nil and channeler or nil
    if inst.channeler ~= nil then
        inst.channeler.components.sanity:DoDelta(-TUNING.SANITY_MED)
        inst.channeler.components.sanity.externalmodifiers:SetModifier(inst, -TUNING.DAPPERNESS_SUPERHUGE)
    end
end

local function OnStopChanneling(inst, aborted)
    TheWorld:PushEvent("townportaldeactivated")

    inst.MiniMapEntity:SetIcon("townportal.png")
    inst.MiniMapEntity:SetPriority(0)

    if inst.icon ~= nil then
        inst.icon.MiniMapEntity:SetIcon("townportal.png")
        inst.icon.MiniMapEntity:SetPriority(0)
    end

    if inst.channeler ~= nil and inst.channeler:IsValid() and inst.channeler.components.sanity ~= nil then
        inst.channeler.components.sanity.externalmodifiers:RemoveModifier(inst)
    end
end

local function OnLinkTownPortals(inst, other)
    inst.components.teleporter:Target(other)
    if inst.components.channelable:IsChanneling() then
        inst.components.channelable:StopChanneling(true)
    else
        inst.components.channelable:SetEnabled(other == nil)
    end

    if other ~= nil then
        inst.AnimState:PlayAnimation("turn_on")
        inst.AnimState:PushAnimation("idle_on_loop")
        inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/idle", "active")
    else
        inst.AnimState:PlayAnimation("turn_off")
        inst.AnimState:PushAnimation("idle_off")
        inst.SoundEmitter:KillSound("active")
    end
end

local function OnStartTeleporting(inst, doer)
    if doer:HasTag("player") then
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
        if doer.components.sanity ~= nil then
            doer.components.sanity:DoDelta(-TUNING.SANITY_HUGE)
        end
    end
end

local function OnExitingTeleporter(inst, obj)
    if obj ~= nil and obj:HasTag("player") then
        obj:DoTaskInTime(1, obj.PushEvent, "townportalteleport") -- for wisecracker
    end
end

local function onhammered(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst)
    if inst.components.channelable:IsChanneling() then
        inst.components.channelable:StopChanneling(true)
        inst.AnimState:PlayAnimation("hit_on")
    else
        if inst.components.teleporter.targetTeleporter ~= nil then
            TheWorld:PushEvent("townportaldeactivated")
            inst.AnimState:PlayAnimation("hit_on")
        else
            inst.AnimState:PlayAnimation("hit_off")
        end
    end
    inst.AnimState:PushAnimation("idle_off")
end

local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/craft")
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_off")

    if inst.components.teleporter.targetTeleporter ~= nil then
        inst.AnimState:PushAnimation("turn_on", false)
        inst.AnimState:PushAnimation("idle_on_loop")
        inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/idle", "active")
    end
end

local function init(inst)
    if inst.icon == nil then
        inst.icon = SpawnPrefab("globalmapicon")
        inst.icon:TrackEntity(inst)
    end
end

local function GetStatus(inst)
    return (inst.components.channelable:IsChanneling() or
            inst.components.teleporter:IsActive())
        and "ACTIVE"
        or nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("townportal.png")
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    MakeObstaclePhysics(inst, .1)

    inst.AnimState:SetBank("townportal")
    inst.AnimState:SetBuild("townportal")
    inst.AnimState:PlayAnimation("idle_off", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("structure")
    inst:AddTag("townportal")
    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------
    MakeHauntableWork(inst)
    MakeSnowCovered(inst)

    -------------------------
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChanneling, OnStopChanneling)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnStartTeleporting
    inst.components.teleporter.offset = 1
    inst.components.teleporter.saveenabled = false
    inst.components.teleporter.travelcameratime = 2.9
    inst.components.teleporter.travelarrivetime = 2.8

    --inst:ListenForEvent("starttravelsound", StartTravelSound) -- triggered by player stategraph
    inst:ListenForEvent("doneteleporting", OnExitingTeleporter)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    -----------------------------
    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("linktownportals", OnLinkTownPortals)

    TheWorld:PushEvent("ms_registertownportal", inst)

    inst:DoTaskInTime(0, init)

    return inst
end

local function townportalsandcoffin_fx()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBuild("player_townportal")
    inst.AnimState:SetBank("wilson")
    inst.AnimState:PlayAnimation("townportal_enter_pst")

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/together/teleport_sand/out")

    inst.persists = false

    inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + .5, inst.Remove)

    return inst
end

return Prefab("townportal", fn, assets, prefabs),
    MakePlacer("townportal_placer", "townportal", "townportal", "idle"),
    Prefab("townportalsandcoffin_fx", townportalsandcoffin_fx, assets)
