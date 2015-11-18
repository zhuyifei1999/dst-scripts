local assets =
{
    Asset("ANIM", "anim/flowers.zip"),
}

local prefabs =
{
    "petals",
    "flower_evil",
    "flower_withered",
}

local DAYLIGHT_SEARCH_RANGE = 30

local names = {"f1","f2","f3","f4","f5","f6","f7","f8","f9","f10"}

local function onsave(inst, data)
    data.anim = inst.animname
end

local function onload(inst, data)
    if data and data.anim then
        inst.animname = data.anim
        inst.AnimState:PlayAnimation(inst.animname)
    end
end

local function onpickedfn(inst, picker)
    if picker and picker.components.sanity then
        picker.components.sanity:DoDelta(TUNING.SANITY_TINY)
    end

    TheWorld:PushEvent("beginregrowth", inst)

    inst:Remove()
end

local function testfortransformonload(inst)
    return TheWorld.state.isfullmoon
end

local function DieInDarkness(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,0,z, DAYLIGHT_SEARCH_RANGE, {"daylight"})
    local wither = true
    for k,v in pairs(ents) do
        if v.Light then
            local darkness_sq = v.Light:GetCalculatedRadius() * 0.7
            darkness_sq = darkness_sq * darkness_sq
            if inst:GetDistanceSqToInst(v) < darkness_sq then
                wither = false
                break
            end
        end
    end
    if wither then
        local withered = SpawnPrefab("flower_withered").Transform:SetPosition(x,y,z)
        inst:Remove()
    end
end

local function OnIsCaveDay(inst, isday)
    if isday then
        inst:DoTaskInTime(5.0 + math.random()*5.0, DieInDarkness)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("flowers")
    inst.AnimState:SetBuild("flowers")
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("flower")
    inst:AddTag("cattoy")
    MakeDragonflyBait(inst, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.animname = names[math.random(#names)]
    inst.AnimState:PlayAnimation(inst.animname)

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("petals", 10)
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.quickpick = true
    inst.components.pickable.wildfirestarter = true

    --inst:AddComponent("transformer")
    --inst.components.transformer:SetTransformWorldEvent("isfullmoon", true)
    --inst.components.transformer:SetRevertWorldEvent("isfullmoon", false)
    --inst.components.transformer:SetOnLoadCheck(testfortransformonload)
    --inst.components.transformer.transformPrefab = "flower_evil"

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    if TheWorld:HasTag("cave") then
        inst:WatchWorldState("iscaveday", OnIsCaveDay)
    end

    MakeHauntableChangePrefab(inst, "flower_evil")

    --------SaveLoad
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("forest/objects/flower", fn, assets, prefabs)
