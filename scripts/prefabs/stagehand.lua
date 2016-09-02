local assets =
{
    Asset("ANIM", "anim/stagehand.zip"),
}

local prefabs =
{
    "nightmarefuel",
    "petals",
    "marble",
}

SetSharedLootTable('stagehand_creature',
{
    {'nightmarefuel', 1.0},
    {'nightmarefuel', 0.5},
    {'marble', .5},
    {'petals', 1},
})


local function getstatus(inst)
    return (inst.sg:HasStateTag("hiding") and "HIDING")
		or "AWAKE"
end
local function CanStandUp(inst)
	-- if not in light or off screen, then it can stand up and walk around
	return (not inst.LightWatcher:IsInLight()) or (not inst:IsNearPlayer(30))
end


local brain = require( "brains/stagehandbrain")

local function MakeStagehand(name)

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
	    inst.entity:AddLightWatcher()

        inst.Transform:SetFourFaced()

        MakeObstaclePhysics(inst, 1)
         
        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("monster")
        inst:AddTag("shadow")
        inst:AddTag("notraptrigger")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

		inst.CharacterPhyscisMass = 150

	    MakeSmallBurnable(inst, nil, nil, false)
	    MakeSmallPropagator(inst)
		MakeHauntableWork(inst)

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(6)
		--inst.components.workable:SetOnFinishCallback(onhammered)
		--inst.components.workable:SetOnWorkCallback(onhit)

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        inst.components.locomotor.walkspeed = TUNING.TERRORBEAK_SPEED
        --inst.sounds = sounds

		inst.CanStandUp = CanStandUp

        inst:SetStateGraph("SGstagehand")
        inst:SetBrain(brain)

	    inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable('stagehand_creature')

		inst.is_awake = false

        --inst:AddComponent("knownlocations")

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeStagehand("stagehand")
