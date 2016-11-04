local function OnTick(inst, target)
    target.components.health:DoDelta(TUNING.JELLYBEAN_TICK_VALUE, nil, "jellybean")
end

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst:DoPeriodicTask(TUNING.JELLYBEAN_TICK_RATE, OnTick, nil, target)
end

local function OnTimerDone(inst, data)
    if data.name == "regenover" then
        inst.components.debuff:Stop()
    end
end

local function OnExtend(inst)
    inst.components.timer:StopTimer("regenover")
    inst.components.timer:StartTimer("regenover", TUNING.JELLYBEAN_DURATION)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(inst.Remove)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("regenover", TUNING.JELLYBEAN_DURATION)
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("extend", OnExtend)

    return inst
end

return Prefab("healthregenbuff", fn)
