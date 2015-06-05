require "prefabutil"
local assets =
{
Asset("ANIM", "anim/acorn.zip"),
}

local prefabs = 
{
    "acorn_sapling",
    "acorn_cooked",
    "spoiled_food",
}

local function plant(inst, growtime)
    local sapling = SpawnPrefab("acorn_sapling")
    sapling:StartGrowing()
    sapling.Transform:SetPosition(inst.Transform:GetWorldPosition())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
    inst:Remove()
end

local function ondeploy (inst, pt)
    inst = inst.components.stackable:Get()
    inst.Transform:SetPosition(pt:Get() )
    local timeToGrow = GetRandomWithVariance(TUNING.ACORN_GROWTIME.base, TUNING.ACORN_GROWTIME.random)
    plant(inst, timeToGrow)	

    -- Pacify a nearby monster tree
    local ent = FindEntity(inst, TUNING.DECID_MONSTER_ACORN_CHILL_RADIUS, nil, {"birchnut", "monster"}, {"stump", "burnt", "FX", "NOCLICK","DECOR","INLIMBO"})
    if ent then
        if ent.monster_start_task ~= nil then
            ent.monster_start_task:Cancel()
            ent.monster_start_task = nil
        end
        if ent.monster and not ent:HasTag("fire") and not ent:HasTag("stump") and not ent:HasTag("burnt") then
            if not ent.monster_stop_task then
                ent.monster_stop_task = ent:DoTaskInTime(math.random(0,3), function(ent) 
                    ent:StopMonster() 
                    ent.monster_stop_task = nil
                end)
            end
        end
    end
end

local function OnLoad(inst, data)
    if data and data.growtime then
        plant(inst, data.growtime)
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    inst.entity:AddNetwork()

    inst.AnimState:SetBank("acorn")
    inst.AnimState:SetBuild("acorn")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("icebox_valid")
    inst:AddTag("cattoy")
 	inst:AddTag("show_spoilage")

    --cookable (from cookable component) added to pristine state for optimization
    inst:AddTag("cookable")

 	MakeDragonflyBait(inst, 3)

    inst.entity:SetPristine()

 	if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("cookable")
    inst.components.cookable.product = "acorn_cooked"

    inst:AddComponent("tradable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_PRESERVED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"
   
    inst:AddComponent("edible")
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.foodtype = "RAW"

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
    
	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    
    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = ondeploy

    MakeHauntableLaunchAndIgnite(inst)
    
    inst.OnLoad = OnLoad

    return inst
end

local function cooked()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("acorn")
    inst.AnimState:SetBuild("acorn")
    inst.AnimState:PlayAnimation("cooked")

    inst.entity:SetPristine()

 	if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.healthvalue = TUNING.HEALING_TINY
    inst.components.edible.foodtype = "SEEDS"

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
    
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab( "common/inventory/acorn", fn, assets, prefabs),
       Prefab("common/inventory/acorn_cooked", cooked, assets),
	   MakePlacer( "common/acorn_placer", "acorn", "acorn", "idle_planted" ) 


