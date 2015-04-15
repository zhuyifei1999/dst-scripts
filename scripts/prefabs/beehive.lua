local prefabs =
{
	"bee",
	"killerbee",
    "honey",
    "honeycomb",
}

local assets =
{
    Asset("ANIM", "anim/beehive.zip"),
	Asset("SOUND", "sound/bee.fsb"),
}

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/bee/bee_hive_LP", "loop")
end

local function OnEntitySleep(inst)
	inst.SoundEmitter:KillSound("loop")
end

local function StartSpawning(inst)
	if inst.components.childspawner 
            and TheWorld.state.issummer
            and not (inst.components.freezable and inst.components.freezable:IsFrozen()) then
		inst.components.childspawner:StartSpawning()
	end
end

local function StopSpawning(inst)
	if inst.components.childspawner then
		inst.components.childspawner:StopSpawning()
	end
end

local function OnIsDay(inst, isday)
    if isday then
        StartSpawning(inst)
    else
        StopSpawning(inst)
    end
end

local function OnIgnite(inst)
    if inst.components.childspawner then
        inst.components.childspawner:ReleaseAllChildren()
        inst:RemoveComponent("childspawner")
    end
    inst.SoundEmitter:KillSound("loop")
    DefaultBurnFn(inst)
end

local function OnFreeze(inst)
    print(inst, "OnFreeze")
    inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
    inst.AnimState:PlayAnimation("frozen", true)
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")

    StopSpawning(inst)
end

local function OnThaw(inst)
    print(inst, "OnThaw")
    inst.AnimState:PlayAnimation("frozen_loop_pst", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end

local function OnUnFreeze(inst)
    print(inst, "OnUnFreeze")
    inst.AnimState:PlayAnimation("cocoon_small", true)
    inst.SoundEmitter:KillSound("thawing")
    inst.AnimState:ClearOverrideSymbol("swap_frozen")

    StartSpawning(inst)
end

local function OnKilled(inst)
    inst:RemoveComponent("childspawner")
    inst.AnimState:PlayAnimation("cocoon_dead", true)
    inst.Physics:ClearCollisionMask()
    
    inst.SoundEmitter:KillSound("loop")
    
    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
    inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
end

local function OnHit(inst, attacker, damage) 
    if inst.components.childspawner then
        inst.components.childspawner:ReleaseAllChildren(attacker, "killerbee")
    end
    if not inst.components.health:IsDead() then
        inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
        inst.AnimState:PlayAnimation("cocoon_small_hit")
        inst.AnimState:PushAnimation("cocoon_small", true)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("beehive.png")

    inst.AnimState:SetBank("beehive")
    inst.AnimState:SetBuild("beehive")
    inst.AnimState:PlayAnimation("cocoon_small", true)

    inst:AddTag("structure")
    inst:AddTag("hive")

    MakeSnowCoveredPristine(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    -------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)

    -------------------
	inst:AddComponent("childspawner")
	inst.components.childspawner.childname = "bee"
	inst.components.childspawner:SetRegenPeriod(TUNING.BEEHIVE_REGEN_TIME)
	inst.components.childspawner:SetSpawnPeriod(TUNING.BEEHIVE_RELEASE_TIME)
	inst.components.childspawner:SetMaxChildren(TUNING.BEEHIVE_BEES)
    inst.components.childspawner.emergencychildname = "bee"
    inst.components.childspawner.emergencychildrenperplayer = 1
    inst.components.childspawner:SetMaxEmergencyChildren(TUNING.BEEHIVE_EMERGENCY_BEES)
    inst.components.childspawner:SetEmergencyRadius(TUNING.BEEHIVE_EMERGENCY_RADIUS)


    if TheWorld.state.isday then
        StartSpawning(inst)
    end

    inst:WatchWorldState("isday", OnIsDay)
	
    ---------------------  
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"honey","honey","honey","honeycomb"})
    ---------------------  

    ---------------------        
    MakeLargeBurnable(inst)
    inst.components.burnable:SetOnIgniteFn(OnIgnite)
    -------------------

    ---------------------
    MakeMediumFreezableCharacter(inst)
    inst:ListenForEvent("freeze", OnFreeze)
    inst:ListenForEvent("onthaw", OnThaw)
    inst:ListenForEvent("unfreeze", OnUnFreeze)
    -------------------

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)
    inst:ListenForEvent("death", OnKilled)
    
    ---------------------
    MakeLargePropagator(inst)
    MakeSnowCovered(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if not inst.components.childspawner or not inst.components.childspawner:CanSpawn() then 
            return false 
        end

        local target = FindEntity(inst, 25, function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        nil,
        {"insect","playerghost"},
        {"character","animal","monster"}
        )

        if target and math.random() <= TUNING.HAUNT_CHANCE_HALF then
            OnHit(inst, target)
            return true
        end

        return false
    end)
    
    ---------------------
    
    inst:AddComponent("inspectable")
	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake

	return inst
end

return Prefab("forest/monsters/beehive", fn, assets, prefabs)