require "prefabutil"
local assets =
{
    Asset("ANIM", "anim/pinecone.zip"),
    Asset("ANIM", "anim/twiggy_nut.zip"),
}

local prefabs =
{
    "pinecone_sapling",
    "twiggy_nut_sapling",
}

local function plant(inst, growtime)
    local spawn_item = "pinecone_sapling"
    if inst._spawn_prefab then
        spawn_item = inst._spawn_prefab
    end
    local sapling = SpawnPrefab(spawn_item)
    sapling:StartGrowing()
    sapling.Transform:SetPosition(inst.Transform:GetWorldPosition())
    sapling.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
    inst:Remove()
end

local function ondeploy(inst, pt, deployer)
    inst = inst.components.stackable:Get()
    inst.Physics:Teleport(pt:Get())
    local timeToGrow = GetRandomWithVariance(TUNING.PINECONE_GROWTIME.base, TUNING.PINECONE_GROWTIME.random)
    plant(inst, timeToGrow)

    --tell any nearby leifs to chill out
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, TUNING.LEIF_PINECONE_CHILL_RADIUS, { "leif" })

    local played_sound = false
    for i, v in ipairs(ents) do
        local chill_chance =
            v:GetDistanceSqToPoint(pt:Get()) < TUNING.LEIF_PINECONE_CHILL_CLOSE_RADIUS * TUNING.LEIF_PINECONE_CHILL_CLOSE_RADIUS and
            TUNING.LEIF_PINECONE_CHILL_CHANCE_CLOSE or
            TUNING.LEIF_PINECONE_CHILL_CHANCE_FAR

        if math.random() < chill_chance then
            if v.components.sleeper ~= nil then
                v.components.sleeper:GoToSleep(1000)
            end
        elseif not played_sound then
            v.SoundEmitter:PlaySound("dontstarve/creatures/leif/taunt_VO")
            played_sound = true
        end
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.growtime ~= nil then
        plant(inst, data.growtime)
    end
end

local cones = {}

local function addcone(name, spawn_prefab, bank, build, anim)
    local function fn()
        local inst = CreateEntity()

        inst._spawn_prefab = spawn_prefab

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("cattoy")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

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

    table.insert(cones, Prefab(name, fn, assets, prefabs))
    table.insert(cones, MakePlacer(name.."_placer", bank, build, anim))
end

addcone("pinecone", "pinecone_sapling", "pinecone", "pinecone", "idle_planted")
addcone("twiggy_nut", "twiggy_nut_sapling", "twiggy_nut", "twiggy_nut", "idle_planted")

return unpack(cones)
