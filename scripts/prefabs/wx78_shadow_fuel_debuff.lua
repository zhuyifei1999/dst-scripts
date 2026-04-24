local BUFF_TIMER = "wx78_shadow_fuel_debuff"
local ATTACH_BUFF_DATA = {
    buff = "ANNOUNCE_WX_NIGHTMARECHARGE",
    priority = 1,
}
local DETACH_BUFF_DATA = {
    buff = "ANNOUNCE_WX_NIGHTMAREDISCHARGE",
    priority = 1,
}

local function buff_OnAttached(inst, target, followsymbol, followoffset, data)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)

    target:PushEvent("foodbuffattached", ATTACH_BUFF_DATA)

    if target.components.upgrademoduleowner ~= nil then
        target.components.upgrademoduleowner:SetOverrideFullCharge(true)
    end

    if data ~= nil and data.duration ~= nil then
        if target.components.wx78_abilitycooldowns ~= nil then -- piggy back off ability cooldowns cmp for networking
            target.components.wx78_abilitycooldowns:RestartAbilityCooldown("shadow_energy", data.duration)
        end
        inst.components.timer:StopTimer(BUFF_TIMER)
        inst.components.timer:StartTimer(BUFF_TIMER, data.duration)
    end

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function buff_OnExtended(inst, target, followsymbol, followoffset, data)
    local duration = data ~= nil and data.duration or TUNING.SKILLS.WX78.SHADOWFUEL_DEBUFF_TIME
    target:PushEvent("foodbuffattached", ATTACH_BUFF_DATA)
    inst.components.timer:StopTimer(BUFF_TIMER)
    inst.components.timer:StartTimer(BUFF_TIMER, duration)
    if target.components.wx78_abilitycooldowns ~= nil then -- piggy back off ability cooldowns cmp for networking
        target.components.wx78_abilitycooldowns:RestartAbilityCooldown("shadow_energy", data.duration)
    end
end

local function buff_OnDetached(inst, target)
    if target.components.upgrademoduleowner ~= nil then
        target.components.upgrademoduleowner:SetOverrideFullCharge(false)
    end
    if target.components.wx78_abilitycooldowns ~= nil then
        target.components.wx78_abilitycooldowns:StopAbilityCooldown("shadow_energy")
    end
    target:PushEvent("foodbuffdetached", DETACH_BUFF_DATA)
    inst:Remove()
end

local function buff_OnTimerDone(inst, data)
    if data.name == BUFF_TIMER then
        inst.components.debuff:Stop()
    end
end

local function fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()
    --[[Non-networked entity]]
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    local debuff = inst:AddComponent("debuff")
    debuff:SetAttachedFn(buff_OnAttached)
    debuff:SetExtendedFn(buff_OnExtended)
    debuff:SetDetachedFn(buff_OnDetached)

    inst:AddComponent("timer")
    inst.components.timer:StartTimer(BUFF_TIMER, TUNING.SKILLS.WX78.SHADOWFUEL_DEBUFF_TIME) -- fall back
    inst:ListenForEvent("timerdone", buff_OnTimerDone)

    return inst
end

return Prefab("wx78_shadow_fuel_debuff", fn)