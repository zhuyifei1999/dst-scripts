local feather_assets =
{
    Asset("ANIM", "anim/fan.zip"),
}

local function OnUse(inst, target, cooling, radius)
    local coolingAmount = cooling
    local pos = target:GetPosition()
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, radius, nil, {"FX", "NOCLICK","DECOR","INLIMBO"}, {"smolder", "fire", "player"})
    for i,v in pairs(ents) do
        if v.components.burnable then 
            -- Extinguish smoldering/fire and reset the propagator to a heat of .2
            v.components.burnable:Extinguish(true, 0) 
        end
        if v.components.temperature then
            -- cool off yourself and any other nearby players
            v.components.temperature:DoDelta(coolingAmount)
        end
    end
end

local function OnUseFeather(inst, target)
    OnUse(inst, target, TUNING.FEATHERFAN_COOLING, TUNING.FEATHERFAN_RADIUS)
end

local function common_fn(bank, build)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("fan")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("fan")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.FAN, 1)

    MakeHauntableLaunch(inst)

    return inst
end

local function feather_fn()
    local inst = common_fn("fan", "fan")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.fan:SetOnUseFn(OnUseFeather)

    inst.components.finiteuses:SetMaxUses(TUNING.FEATHERFAN_USES)
    inst.components.finiteuses:SetUses(TUNING.FEATHERFAN_USES)

    return inst
end

return Prefab("featherfan", feather_fn, feather_assets)
