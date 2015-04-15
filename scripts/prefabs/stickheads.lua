local pig_assets =
{
	Asset("ANIM", "anim/pig_head.zip")
}

local merm_assets =
{
	Asset("ANIM", "anim/merm_head.zip")
}

local pig_prefabs =
{
	"flies",
	"pigskin",
	"twigs",
}

local merm_prefabs =
{
	"flies",
	"spoiled_food",
	"twigs",
}

local function OnFinish(inst)
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst.components.lootdropper:DropLoot()
	inst:Remove()
end

local function OnWorked(inst) 
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle_asleep")
end

local function create_common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("lootdropper")

	inst:AddComponent("inspectable")

	inst.flies = inst:SpawnChild("flies")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnWorkCallback(OnWorked)
	inst.components.workable.onfinish = OnFinish

	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_MEDIUM
	inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
		if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
			if inst.components.workable and inst.components.workable.workleft > 0 then
                inst.components.workable:WorkedBy(haunter, 1)
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
				return true
			end
		else
			inst.AnimState:PlayAnimation("wake")
			inst.AnimState:PushAnimation("idle_awake")
			inst:DoTaskInTime(4, function(inst) 
				inst.AnimState:PlayAnimation("sleep")
				inst.AnimState:PushAnimation("idle_asleep")
			end)
			inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
			return true
		end
		return false
	end)

	return inst
end

local function create_pighead()
	local inst = create_common()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.AnimState:SetBank("pig_head")
	inst.AnimState:SetBuild("pig_head")
    inst.AnimState:PlayAnimation("idle_asleep")

	inst.components.lootdropper:SetLoot({"pigskin", "pigskin", "twigs", "twigs"})

	return inst
end

local function create_mermhead()
	local inst = create_common()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.AnimState:SetBank("merm_head")
	inst.AnimState:SetBuild("merm_head")
    inst.AnimState:PlayAnimation("idle_asleep")

	inst.components.lootdropper:SetLoot({"spoiled_food", "spoiled_food", "twigs", "twigs"})

	return inst
end

return Prefab("forest/objects/pighead", create_pighead, pig_assets, pig_prefabs),
	   Prefab("forest/objects/mermhead", create_mermhead, merm_assets, merm_prefabs)