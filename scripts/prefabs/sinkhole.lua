local assets =
{
	Asset("ANIM", "anim/blocker.zip"),
}

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
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    
    MakeObstaclePhysics(inst, 1)

    inst.MiniMapEntity:SetIcon("basalt.png")

    inst.animname = "block1"
    inst.AnimState:SetBank("blocker")
    inst.AnimState:SetBuild("blocker")
    inst.AnimState:PlayAnimation(inst.animname)

    MakeSnowCoveredPristine(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "BASALT"
    MakeSnowCovered(inst)
    return inst
end
   
return Prefab("forest/objects/sinkhole", fn, assets)