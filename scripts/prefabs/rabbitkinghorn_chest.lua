local assets = {
    Asset("ANIM", "anim/rabbitkinghorn_chest.zip"),
}

local function OnOpen(inst)
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("open_idle", false)
    if inst.components.timer and inst.components.timer:TimerExists("despawn") then
        inst.components.timer:PauseTimer("despawn")
    end
end

local function OnClose(inst)
    inst.AnimState:PlayAnimation("close")
    inst.AnimState:PushAnimation("close_idle", false)
    if inst.components.timer and inst.components.timer:TimerExists("despawn") then
        inst.components.timer:ResumeTimer("despawn")
    end
end

local function ontimerdone(inst, data)
    if data.name == "despawn" then
        if inst:IsAsleep() then
            inst:Remove()
        else
            inst.persists = false
            inst.components.container_proxy:SetCanBeOpened(false)
            inst.AnimState:PlayAnimation("despawn")
            inst:ListenForEvent("animover", inst.Remove)
        end
    end
end

local function AttachPocketContainer(inst)
    inst.components.container_proxy:SetMaster(TheWorld:GetPocketDimensionContainer("rabbitkinghorn"))
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("rabbitkinghorn_chest")
    inst.AnimState:SetBuild("rabbitkinghorn_chest")
    inst.AnimState:PlayAnimation("spawn_pre")
    inst.AnimState:PushAnimation("close_idle", false)
    inst.AnimState:SetScale(1.3, 1.3)

    inst:AddComponent("container_proxy")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst.components.container_proxy:SetOnOpenFn(OnOpen)
    inst.components.container_proxy:SetOnCloseFn(OnClose)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)
    inst.components.timer:StartTimer("despawn", TUNING.RABBITKINGHORN_DURATION)

    inst.OnLoadPostPass = AttachPocketContainer

    if not POPULATING then
        AttachPocketContainer(inst)
    end

    return inst
end

return Prefab("rabbitkinghorn_chest", fn, assets, prefabs)
