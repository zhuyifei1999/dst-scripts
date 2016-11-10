local assets =
{
    Asset("ANIM", "anim/honey_trail.zip"),
}

local prefabs =
{
    "honeytraildebuff",
}

local function OnUpdate(inst, x, y, z, rad)
    local ents = TheSim:FindEntities(x, y, z, rad, { "locomotor", "debuffable" }, { "flying", "playerghost", "INLIMBO" })
    for i, v in ipairs(ents) do
        if not (v.components.health ~= nil and v.components.health:IsDead()) then
            local other = v.components.debuffable:GetDebuff("honeytraildebuff")
            if other ~= nil then
                other:PushEvent("extend")
            else
                v.components.debuffable:AddDebuff("honeytraildebuff", "honeytraildebuff")
            end
        end
    end
end

local function OnStartFade(inst)
    inst.AnimState:PlayAnimation(inst.trailname.."_pst")
    inst.task:Cancel()
end

local function OnAnimOver(inst)
    if inst.AnimState:IsCurrentAnimation(inst.trailname.."_pre") then
        inst.AnimState:PlayAnimation(inst.trailname)
        inst:DoTaskInTime(inst.duration, OnStartFade)
    elseif inst.AnimState:IsCurrentAnimation(inst.trailname.."_pst") then
        inst:Remove()
    end
end

local function SetVariation(inst, rand, scale, duration)
    if inst.trailname == nil then
        inst.Transform:SetScale(scale, scale, scale)

        inst.trailname = "trail"..tostring(rand)
        inst.duration = duration
        inst.AnimState:PlayAnimation(inst.trailname.."_pre")
        inst:ListenForEvent("animover", OnAnimOver)

        local x, y, z = inst.Transform:GetWorldPosition()
        inst.task:Cancel()
        inst.task = inst:DoPeriodicTask(FRAMES, OnUpdate, nil, x, y, z, scale)
        OnUpdate(inst, x, y, z, scale)
    end
end

--------------------------------------------------------------------------

local function OnAttached(inst, target)
    inst.target = target
    inst.entity:SetParent(target.entity)
    if target.components.locomotor ~= nil then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "honeytraildebuff", TUNING.BEEQUEEN_HONEYTRAIL_SPEED_PENALTY)
    end
end

local function OnDebuffOver(inst)
    inst.components.debuff:Stop()
end

local function OnExtend(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(2 * FRAMES, OnDebuffOver)
end

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("honey_trail")
    inst.AnimState:SetBuild("honey_trail")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetVariation = SetVariation

    inst.persists = false
    inst.task = inst:DoTaskInTime(0, inst.Remove)

    return inst
end

local function debuff_fn(inst)
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(inst.Remove)

    inst:ListenForEvent("extend", OnExtend)
    OnExtend(inst)

    return inst
end

return Prefab("honey_trail", fn, assets, prefabs),
    Prefab("honeytraildebuff", debuff_fn)
