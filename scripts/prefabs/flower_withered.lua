local assets =
{
    Asset("ANIM", "anim/withered_flowers.zip"),
}

local names = {"wf1","wf2","wf3"}

local function onpickedfn(inst, picker)
    inst:Remove()
end

local function onsave(inst, data)
    data.anim = inst.animname
end

local function onload(inst, data)
    if data and data.anim then
        inst.animname = data.anim
        inst.AnimState:PlayAnimation(inst.animname)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeDragonflyBait(inst, 1)

    inst.AnimState:SetBank("withered_flowers")
    inst.AnimState:SetBuild("withered_flowers")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.animname = names[math.random(#names)]
    inst.AnimState:PlayAnimation(inst.animname)

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("cutgrass", 10)
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.quickpick = true
    inst.components.pickable.wildfirestarter = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    --------SaveLoad
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("common/objects/flower_withered", fn, assets)
