local assets =
{
	Asset("ANIM", "anim/carrot.zip"),
}

local prefabs =
{
	"carrot",
}

local function fn()
    --Carrot you eat is defined in veggies.lua
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("carrot")
    inst.AnimState:SetBuild("carrot")
    inst.AnimState:PlayAnimation("planted")
    inst.AnimState:SetRayTestOnBB(true)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("carrot", 10)
	inst.components.pickable.onpickedfn = inst.Remove

    inst.components.pickable.quickpick = true
    
	MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("common/inventory/carrot_planted", fn, assets)