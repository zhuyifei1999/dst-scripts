local assets =
{
	--Asset("ANIM", "anim/arrow_indicator.zip"),
}

local prefabs = 
{
    "lightninggoat",
}

local function CanSpawn(inst)
    return inst.components.herd and not inst.components.herd:IsFull()
end

local function OnSpawned(inst, newent)
    if inst.components.herd then
        inst.components.herd:AddMember(newent)
    end
end

local function OnEmpty(inst)
    inst:Remove()
end
   
local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	
    inst:AddTag("herd")

    -- Herds are non-networked.
    
    inst:AddComponent("herd")
    inst.components.herd:SetMemberTag("lightninggoat")
    inst.components.herd:SetGatherRange(40)
    inst.components.herd:SetUpdateRange(20)
    inst.components.herd:SetOnEmptyFn(OnEmpty)
    
    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetRandomTimes(TUNING.LIGHTNING_GOAT_MATING_SEASON_BABYDELAY, TUNING.LIGHTNING_GOAT_MATING_SEASON_BABYDELAY_VARIANCE)
    inst.components.periodicspawner:SetPrefab("lightninggoat")
    inst.components.periodicspawner:SetOnSpawnFn(OnSpawned)
    inst.components.periodicspawner:SetSpawnTestFn(CanSpawn)
    inst.components.periodicspawner:SetDensityInRange(20, 6)
    inst.components.periodicspawner:SetOnlySpawnOffscreen(true)
    inst.components.periodicspawner:Start()

    
    return inst
end

return Prefab( "lightninggoatherd", fn, assets, prefabs) 
