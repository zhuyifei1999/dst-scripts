local assets =
{
    Asset("ANIM", "anim/stagehand.zip"),
}

local prefabs =
{
    "endtable_blueprint",
}

SetSharedLootTable('stagehand_creature',
{
    {'endtable_blueprint', 1.0},
})

local function onworked(inst, worker)
	-- make sure it never runs out of work to do
	inst.components.workable:SetWorkLeft(TUNING.STAGEHAND_HITS_TO_GIVEUP)
end

local function getstatus(inst)
    return (inst.sg:HasStateTag("hiding") and "HIDING")
		or "AWAKE"
end

local function CanStandUp(inst)
	-- if not in light or off screen (off screen is so it doesnt get stuck forever on things like firefly/pighouse light), then it can stand up and walk around
	return (not inst.LightWatcher:IsInLight()) or (TheWorld.state.isnight and (not TheWorld.state.isfullmoon) and not inst:IsNearPlayer(30))
end


local function ChangePhysics(inst, is_standing)
	local phys = inst.Physics

	if is_standing then
		inst:RemoveTag("blocker")

		phys:SetMass(100)
		phys:SetFriction(0)
		phys:SetDamping(5)
		phys:SetCollisionGroup(COLLISION.CHARACTERS)
		phys:ClearCollisionMask()
		phys:CollidesWith(COLLISION.WORLD)
	else
		inst:AddTag("blocker")
	    
		local phys = inst.entity:AddPhysics()
		phys:SetMass(0) 
		phys:SetCollisionGroup(COLLISION.OBSTACLES)
		phys:ClearCollisionMask()
	end

	phys:CollidesWith(COLLISION.ITEMS)
	phys:CollidesWith(COLLISION.OBSTACLES)
	phys:CollidesWith(COLLISION.SMALLOBSTACLES)
	phys:CollidesWith(COLLISION.CHARACTERS)
	phys:CollidesWith(COLLISION.GIANTS)
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

        local phys = inst.entity:AddPhysics()
        phys:SetCapsule(0.5, 1)
		phys:SetFriction(0)
		phys:SetDamping(5)
        ChangePhysics(inst, false)
        
        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("notraptrigger")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

	    MakeSmallBurnable(inst, nil, nil, false, "swap_fire")
	    MakeSmallPropagator(inst)
		MakeHauntableWork(inst)

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(TUNING.STAGEHAND_HITS_TO_GIVEUP)
		--inst.components.workable:SetOnFinishCallback(onhammered)
		inst.components.workable:SetOnWorkCallback(onworked)

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        inst.components.locomotor.walkspeed = 8
        --inst.sounds = sounds

		inst.CanStandUp = CanStandUp
		inst.ChangePhysics = ChangePhysics

        inst:SetStateGraph("SGstagehand")
        inst:SetBrain(brain)

	    inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable('stagehand_creature')

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeStagehand("stagehand")
