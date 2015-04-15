local rock1_assets =
{
	Asset("ANIM", "anim/rock.zip"),
}

local rock2_assets =
{
	Asset("ANIM", "anim/rock2.zip"),
}

local rock_flintless_assets =
{
	Asset("ANIM", "anim/rock_flintless.zip"),
}

local rock_moon_assets = 
{
    Asset("ANIM", "anim/rock7.zip")
}

local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "moonrocknugget",
}    

SetSharedLootTable( 'rock1',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'nitre',  1.00},
    {'flint',  1.00},
    {'nitre',  0.25},
    {'flint',  0.60},
})

SetSharedLootTable( 'rock2',
{
    {'rocks',     	1.00},
    {'rocks',     	1.00},
    {'rocks',     	1.00},
    {'goldnugget',  1.00},
    {'flint',     	1.00},
    {'goldnugget',  0.25},
    {'flint',     	0.60},
})

SetSharedLootTable( 'rock_flintless',
{
    {'rocks',   1.0},
    {'rocks',   1.0},
    {'rocks',   1.0},
    {'rocks',  	1.0},
    {'rocks',   0.6},
})

SetSharedLootTable( 'rock_flintless_med',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 0.4},
})


SetSharedLootTable( 'rock_flintless_low',
{
    {'rocks', 1.0},
    {'rocks', 1.0},
    {'rocks', 0.2},
})

SetSharedLootTable( 'rock_moon',
{
    {'rocks',           1.00},
    {'rocks',           1.00},
    {'moonrocknugget',  1.00},
    {'flint',           1.00},
    {'moonrocknugget',  0.25},
    {'flint',           0.60},
})

local function OnWork(inst, worker, workleft)
    local pt = Point(inst.Transform:GetWorldPosition())
    if workleft <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(pt)
        inst:Remove()
    elseif workleft < TUNING.ROCKS_MINE / 3 then
        inst.AnimState:PlayAnimation("low")
    elseif workleft < TUNING.ROCKS_MINE * 2 / 3 then
        inst.AnimState:PlayAnimation("med")
    else
        inst.AnimState:PlayAnimation("full")
    end
end

local function baserock_fn(bank, build, anim, icon)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
	
	MakeObstaclePhysics(inst, 1)

    inst.MiniMapEntity:SetIcon(icon or "rock.png")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation(anim)

    MakeSnowCoveredPristine(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

	inst:AddComponent("lootdropper") 
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
	inst.components.workable:SetOnWorkCallback(OnWork)

    local color = 0.5 + math.random() * 0.5
    inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("inspectable")
	inst.components.inspectable.nameoverride = "ROCK"
	MakeSnowCovered(inst)

    MakeHauntableWork(inst)

	return inst
end

local function rock1_fn()
	local inst = baserock_fn("rock", "rock", "full")

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.lootdropper:SetChanceLootTable('rock1')

	return inst
end

local function rock2_fn()
	local inst = baserock_fn("rock2", "rock2", "full")

    if not TheWorld.ismastersim then
        return inst
    end
    
	inst.components.lootdropper:SetChanceLootTable('rock2')

	return inst
end

local function rock_flintless_fn()
	local inst = baserock_fn("rock_flintless", "rock_flintless", "full", "rock_flintless.png")

    if not TheWorld.ismastersim then
        return inst
    end
    
	inst.components.lootdropper:SetChanceLootTable('rock_flintless')

	return inst
end

local function rock_flintless_med()
	local inst = baserock_fn("rock_flintless", "rock_flintless", "med", "rock_flintless.png")

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_MED)

	inst.components.lootdropper:SetChanceLootTable('rock_flintless_med')

	return inst
end

local function rock_flintless_low()
	local inst = baserock_fn("rock_flintless", "rock_flintless", "low", "rock_flintless.png")

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.lootdropper:SetChanceLootTable('rock_flintless_low')
	inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE_LOW)

	return inst
end

local function rock_moon()
    local inst = baserock_fn("rock5", "rock7", "full")

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.components.lootdropper:SetChanceLootTable('rock_moon')

    return inst
end

return Prefab("forest/objects/rocks/rock1", rock1_fn, rock1_assets, prefabs),
        Prefab("forest/objects/rocks/rock2", rock2_fn, rock2_assets, prefabs),
        Prefab("forest/objects/rocks/rock_flintless", rock_flintless_fn, rock_flintless_assets, prefabs),
        Prefab("forest/objects/rocks/rock_flintless_med", rock_flintless_med, rock_flintless_assets, prefabs),
        Prefab("forest/objects/rocks/rock_flintless_low", rock_flintless_low, rock_flintless_assets, prefabs),
        Prefab("forest/objects/rocks/rock_moon", rock_moon, rock_moon_assets, prefabs)