local assets =
{
    Asset("ANIM", "anim/lava_tile.zip"),
	Asset("MINIMAP_IMAGE", "pond_lava"),
}

local prefabs =
{
    "lava_pond_rock",
}

local rock_assets =
{
    Asset("ANIM", "anim/scorched_rock.zip"),
}

local rocktypes =
{
    "",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
}

local function makerock(rocktype)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("scorched_rock")
        inst.AnimState:SetBuild("scorched_rock")
        inst.AnimState:PlayAnimation("idle"..rocktype)

        inst.name = STRINGS.NAMES.LAVA_POND_ROCK

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        return inst
    end
    return Prefab("lava_pond_rock"..rocktype, fn, rock_assets)
end

local function SpawnRocks(inst)
    inst.task = nil
    if inst.rocks == nil then
        inst.rocks = {}
        for i = 1, math.random(2, 4) do
            local theta = math.random() * 2 * PI
            table.insert(inst.rocks,
            {
                rocktype = rocktypes[math.random(#rocktypes)],
                offset =
                {
                    math.sin(theta) * 2.1 + math.random() * .3,
                    0,
                    math.cos(theta) * 2.1 + math.random() * .3,
                },
            })
        end
    end
    for i, v in ipairs(inst.rocks) do
        if type(v.rocktype) == "string" and type(v.offset) == "table" and #v.offset == 3 then
            local rock = SpawnPrefab("lava_pond_rock"..v.rocktype)
            if rock ~= nil then
                rock.entity:SetParent(inst.entity)
                rock.Transform:SetPosition(unpack(v.offset))
                rock.persists = false
            end
        end
    end
end

local function OnSave(inst, data)
    data.rocks = inst.rocks
end

local function OnLoad(inst, data)
    if data ~= nil and data.rocks ~= nil and inst.rocks == nil and inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
        inst.rocks = data.rocks
        SpawnRocks(inst)
    end
end

local function OnCollide(inst, other)
    if other ~= nil and other:IsValid() and inst:IsValid() and other.components.burnable ~= nil then
        other.components.burnable:Ignite(true, inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeSmallObstaclePhysics(inst, 1.95)

    inst.AnimState:SetBuild("lava_tile")
    inst.AnimState:SetBank("lava_tile")
    inst.AnimState:PlayAnimation("bubble_lava", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("pond_lava.png")

    inst:AddTag("lava")

    --cooker (from cooker component) added to pristine state for optimization
    inst:AddTag("cooker")

    inst.Light:Enable(true)
    inst.Light:SetRadius(1.5)
    inst.Light:SetFalloff(0.66)
    inst.Light:SetIntensity(0.66)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)

    inst.no_wet_prefix = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("inspectable")
    inst:AddComponent("heater")
    inst.components.heater.heat = 500

    inst:AddComponent("propagator")
    inst.components.propagator.damages = true
    inst.components.propagator.propagaterange = 5
    inst.components.propagator.damagerange = 5
    inst.components.propagator:StartSpreading()

    inst:AddComponent("cooker")

    inst.rocks = nil
    inst.task = inst:DoTaskInTime(0, SpawnRocks)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local prefabs = { Prefab("lava_pond", fn, assets, prefabs) }
for i, v in ipairs(rocktypes) do
    table.insert(prefabs, makerock(v))
end
return unpack(prefabs)
