local assets =
{
    Asset("ANIM", "anim/lava_tile.zip"),
}

local rock_assets =
{
    Asset("ANIM", "anim/scorched_rock.zip"),
}

local NUM_ROCK_TYPES = 7

local function makerock(rocktype)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("scorched_rock")
        inst.AnimState:SetBuild("scorched_rock")
        inst.AnimState:PlayAnimation("idle"..rocktype)

        if rocktype:len() > 0 then
            inst:SetPrefabNameOverride("lava_pond_rock")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

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
            local rocktype = math.random(NUM_ROCK_TYPES)
            table.insert(inst.rocks,
            {
                rocktype = rocktype > 1 and tostring(rocktype) or "",
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
    if other ~= nil and
        other:IsValid() and
        inst:IsValid() and
        other.components.burnable ~= nil and
        other.components.fueled == nil then
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

    inst.MiniMapEntity:SetIcon("lava_pond.png")

    inst:AddTag("lava")
    inst:AddTag("antlion_sinkhole_blocker")

    --cooker (from cooker component) added to pristine state for optimization
    inst:AddTag("cooker")

    inst.Light:Enable(true)
    inst.Light:SetRadius(1.5)
    inst.Light:SetFalloff(0.66)
    inst.Light:SetIntensity(0.66)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)

    inst.no_wet_prefix = true

    inst:SetDeployExtraSpacing(2)

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

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local ret = { makerock("") }
local prefabs = { "lava_pond_rock" }
for i = 2, NUM_ROCK_TYPES do
    table.insert(ret, makerock(tostring(i)))
    table.insert(prefabs, "lava_pond_rock"..tostring(i))
end
table.insert(ret, Prefab("lava_pond", fn, assets, prefabs))
prefabs = nil
return unpack(ret)
