local assets =
{
	Asset("ANIM", "anim/statue_maxwell.zip"),
}

local prefabs =
{
	"marble",
}

SetSharedLootTable('statue_maxwell',
{
    { 'marble', 1.00 },
    { 'marble', 1.00 },
    { 'marble', 0.33 },
})

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	inst:AddTag("maxwell")

	MakeObstaclePhysics(inst, 0.66)

    inst.MiniMapEntity:SetIcon("statue.png")

    inst.AnimState:SetBank("statue_maxwell")
    inst.AnimState:SetBuild("statue_maxwell")
    inst.AnimState:PlayAnimation("idle_full")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('statue_maxwell')

	inst:AddComponent("inspectable")
	inst:AddComponent("workable")
	--TODO: Custom variables for mining speed/cost
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
	inst.components.workable:SetOnWorkCallback(          
		function(inst, worker, workleft)
	        local pt = Point(inst.Transform:GetWorldPosition())
	        if workleft <= 0 then
				inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
	            inst.components.lootdropper:DropLoot(pt)
	            inst:Remove()
	        else	            
	            if workleft < TUNING.MARBLEPILLAR_MINE*(1/3) then
	                inst.AnimState:PlayAnimation("hit_low")
	                inst.AnimState:PushAnimation("idle_low")
	            elseif workleft < TUNING.MARBLEPILLAR_MINE*(2/3) then
	                inst.AnimState:PlayAnimation("hit_med")
	                inst.AnimState:PushAnimation("idle_med")
	            else
	                inst.AnimState:PlayAnimation("hit_full")
	                inst.AnimState:PushAnimation("idle_full")
	            end
	        end
	    end)

	MakeHauntableWork(inst)

	return inst
end

return Prefab("forest/objects/statuemaxwell", fn, assets, prefabs)