local assets =
{
    Asset("ANIM", "anim/nightmare_timepiece.zip"),
}

local states =
{
    calm = function(inst)
        inst.AnimState:PlayAnimation("idle_1")
        inst.components.inventoryitem:ChangeImageName("nightmare_timepiece")        
    end,

    warn = function(inst)
        inst.AnimState:PlayAnimation("idle_3")
        inst.components.inventoryitem:ChangeImageName("nightmare_timepiece_nightmare")
    end,

    nightmare = function(inst)
        inst.AnimState:PlayAnimation("idle_3")
        inst.components.inventoryitem:ChangeImageName("nightmare_timepiece_nightmare")    
    end,

    dawn = function(inst)
        inst.AnimState:PlayAnimation("idle_1")
        inst.components.inventoryitem:ChangeImageName("nightmare_timepiece")    
    end,
}

local function GetStatus(inst)
    --[[local nclock = GetNightmareClock()
    if nclock then
        if nclock:IsNightmare() then
            local percent = nclock:GetNormEraTime()
            if percent < 0.33 then
                return "WAXING"
                --Phase just started.
            elseif percent >= 0.33 and percent < 0.66 then
                return "STEADY"
                --Phase in middle.
            else
                return "WANING"
                --Phase ending soon.
            end
        elseif nclock:IsWarn() then
            return "WARN"
        elseif nclock:IsCalm() then
            return "CALM"
        else
            return "DAWN"
        end
    end]]

    return "NOMAGIC"
end

local function phasechange(inst, data)
    local statefn = states[data.newphase]

    if statefn then
        inst.timestate = data.newphase
        inst:DoTaskInTime(math.random() * 2, statefn)
    end
end

local function onsave(inst, data)
    if inst.timestate then
        data.timestate = inst.timestate
    end
end

local function onload(inst, data)
    if data and data.timestate then
        inst.timestate = data.timestate
        states[inst.timestate](inst, true)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("nightmare_watch")
    inst.AnimState:SetBuild("nightmare_timepiece")
    inst.AnimState:PlayAnimation("idle_1")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    --[[if GetNightmareClock() then
        inst:ListenForEvent("phasechange", function(world, data) phasechange(inst, data) end, TheWorld)
        phasechange(inst, {newphase = GetNightmareClock():GetPhase()})
    end]]

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("common/inventory/nightmare_timepiece", fn, assets)