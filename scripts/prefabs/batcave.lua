local assets =
{
	Asset("ANIM", "anim/batcave.zip"),
}

local prefabs =
{
	"bat"
}

local function ReturnChildren(inst)
	for k,child in pairs(inst.components.childspawner.childrenoutside) do
		if child.components.homeseeker then
			child.components.homeseeker:GoHome()
		end
		child:PushEvent("gohome")
	end
end

local function onnear(inst)
	if inst.components.childspawner.childreninside >= inst.components.childspawner.maxchildren then
		inst.components.childspawner:StartSpawning()
		inst.components.childspawner:StopRegen()
	end
end

local function onfar(inst)
	ReturnChildren(inst)
	inst.components.childspawner:StopSpawning()
	inst.components.childspawner:StartRegen()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.95)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBuild("batcave")
    inst.AnimState:SetBank("batcave")
    inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddComponent("childspawner")
	inst.components.childspawner:SetRegenPeriod(60)
	inst.components.childspawner:SetSpawnPeriod(.1)
	inst.components.childspawner:SetMaxChildren(6)
	inst.components.childspawner.childname = "bat"

    inst:AddComponent("inspectable")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)
    inst.components.playerprox:SetDist(20, 40)

	return inst
end

return Prefab("cave/objects/batcave", fn, assets, prefabs)