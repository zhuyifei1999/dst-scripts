local assets =
{
    Asset("ANIM", "anim/nightmare_timepiece.zip"),
}

local states =
{
    calm = {
        anim = "idle_1",
        inventory = "nightmare_timepiece",
    },
    warn = {
        anim = "idle_2",
        inventory = "nightmare_timepiece_warn",
    },
    wild = {
        anim = "idle_3",
        inventory = "nightmare_timepiece_nightmare",
    },
    dawn = {
        anim = "idle_1",
        inventory = "nightmare_timepiece",
    },
}

for k,v in pairs(states) do
    table.insert( assets, Asset("INV_IMAGE", v.inventory) )
end

local function GetStatus(inst)
    if TheWorld.state.isnightmarewild then
        local percent = TheWorld.state.nightmaretimeinphase
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
    elseif TheWorld.state.isnightmarewarn then
        return "WARN"
    elseif TheWorld.state.isnightmarecalm then
        return "CALM"
    elseif TheWorld.state.isnightmaredawn then
        return "DAWN"
    end

    return "NOMAGIC"
end

local function OnPhaseChanged(inst, phase)
    if states[phase] then
        inst.AnimState:PlayAnimation(states[phase].anim)
        inst.components.inventoryitem:ChangeImageName(states[phase].inventory)
    else
        inst.AnimState:PlayAnimation(states["calm"].anim)
        inst.components.inventoryitem:ChangeImageName(states["calm"].inventory)
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

    inst:WatchWorldState("nightmarephase", OnPhaseChanged)
    inst:DoTaskInTime(0, function()
        OnPhaseChanged(inst, TheWorld.state.nightmarephase)
    end)

    return inst
end

return Prefab("nightmare_timepiece", fn, assets)
