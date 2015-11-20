local prefabs =
{
    "sparks",
}

local function OnAttack(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("sparks").Transform:SetPosition(x, y - .5, z)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(252 / 255, 251 / 255, 237 / 255)
    inst.Light:SetFalloff(0.6)
    inst.Light:SetRadius(4)
    inst.Light:Enable(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst.OnAttack = OnAttack

    return inst
end

return Prefab("common/fx/nightstickfire", fn, nil, prefabs)