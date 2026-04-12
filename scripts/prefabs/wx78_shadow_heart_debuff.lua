local function expire(inst)
    if inst.components.debuff then
        inst.components.debuff:Stop()
    end
end

local function buff_OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)

    inst:ListenForEvent("death", function()
        expire(inst)
    end, target)
end

local function buff_OnExtended(inst)
    if inst.expiretask ~= nil then
        inst.expiretask:Cancel()
        inst.expiretask = nil
    end
    inst.expiretask = inst:DoTaskInTime(TUNING.SKILLS.WX78.SHADOWHEART_DEBUFF_TIME, expire)
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
    inst:AddTag("CLASSIFIED")

    inst.persists = false

    local debuff = inst:AddComponent("debuff")
    debuff:SetAttachedFn(buff_OnAttached)
    debuff:SetExtendedFn(buff_OnExtended)

    buff_OnExtended(inst)

    return inst
end

return Prefab("wx78_shadow_heart_debuff", fn)