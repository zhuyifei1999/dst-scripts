require "prefabutil"
local assets =
{
    Asset("ANIM", "anim/pinecone.zip"),
}

local function plant(inst, growtime)
    local sapling = SpawnPrefab("pinecone_sapling")
    sapling:StartGrowing()
    sapling.Transform:SetPosition(inst.Transform:GetWorldPosition())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
    inst:Remove()
end

local function ondeploy(inst, pt)
    inst = inst.components.stackable:Get()
    inst.Physics:Teleport(pt:Get())
    local timeToGrow = GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base, TUNING.PINECONE_GROWTIME.random)
    plant(inst, timeToGrow)

    --tell any nearby leifs to chill out
    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, TUNING.LEIF_PINECONE_CHILL_RADIUS, {"leif"})

    local played_sound = false
    for k,v in pairs(ents) do
        local chill_chance = TUNING.LEIF_PINECONE_CHILL_CHANCE_FAR
        if distsq(pt, Vector3(v.Transform:GetWorldPosition())) < TUNING.LEIF_PINECONE_CHILL_CLOSE_RADIUS*TUNING.LEIF_PINECONE_CHILL_CLOSE_RADIUS then
            chill_chance = TUNING.LEIF_PINECONE_CHILL_CHANCE_CLOSE
        end

        if math.random() < chill_chance then
            if v.components.sleeper then
                v.components.sleeper:GoToSleep(1000)
            end
        else
            if not played_sound then
                v.SoundEmitter:PlaySound("dontstarve/creatures/leif/taunt_VO")
                played_sound = true
            end
        end
    end
end

local function OnLoad(inst, data)
    dumptable(data)
    if data and data.growtime then
        plant(inst, data.growtime)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("pinecone")
    inst.AnimState:SetBuild("pinecone")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("cattoy")
    MakeDragonflyBait(inst, 3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.WOOD
    inst.components.edible.woodiness = 2

    inst:AddComponent("tradable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunchAndIgnite(inst)

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = ondeploy

    -- This is left in for "save file upgrading", June 3 2015. We can remove it after some time.
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("common/inventory/pinecone", fn, assets),
    MakePlacer("common/pinecone_placer", "pinecone", "pinecone", "idle_planted")
