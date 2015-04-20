local assets =
{
	Asset("ANIM", "anim/lava_tile.zip"),
}

local rocktypes =
{
    "idle",
    "idle2",
    "idle3",
    "idle4",
    "idle5",
    "idle6",
    "idle7",
}

local rock_assets =
{
    Asset("ANIM", "anim/scorched_rock.zip")
}

local prefabs =
{
    "lava_pond_rock",
}

local function rock_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("scorched_rock")
    inst.AnimState:SetBuild("scorched_rock")
    inst.AnimState:PlayAnimation(GetRandomItem(rocktypes))

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    return inst
end

local function SpawnRocks(inst, rockname)

    if inst.decor then
        for i,item in ipairs(inst.decor) do
            item:Remove()
        end
    end
    inst.decor = {}

    local rock_offsets = {}

    for i=1,math.random(2,4) do
        local a = math.random()*math.pi*2
        local x = math.sin(a)*2.1+math.random()*0.3
        local z = math.cos(a)*2.1+math.random()*0.3
        table.insert(rock_offsets, {x,0,z})
    end

    for k, offset in pairs( rock_offsets ) do
        local rock = SpawnPrefab( rockname )
        rock.entity:SetParent( inst.entity )
        rock.Transform:SetPosition( offset[1], offset[2], offset[3] )
        table.insert( inst.decor, rock )
        
        rock:ListenForEvent("onremove", function()
            for k,v in pairs(inst.decor) do
                if v == rock then
                    table.remove( inst.decor, k )
                    return
                end
            end
        end, rock)
    end
end

local function OnCollide(inst, other)
    if other and other.components.burnable then
        other.components.burnable:Ignite(true, inst)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeSmallObstaclePhysics(inst, 1.95)
    inst.Physics:SetCollisionCallback(OnCollide)

    inst.AnimState:SetBuild("lava_tile")
    inst.AnimState:SetBank("lava_tile")
    inst.AnimState:PlayAnimation("bubble_lava", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("pond_lava.png")

    inst:AddTag("lava")

    local light = inst.entity:AddLight()
    light:Enable(true)
    light:SetRadius(1.5)
    light:SetFalloff(0.66)
    light:SetIntensity(0.66)
    light:SetColour(235/255, 121/255, 12/255)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
    	return inst
    end

    inst:AddComponent("inspectable")
    inst.no_wet_prefab = true

    inst:AddComponent("heater")
    inst.components.heater.heat = 500

    inst:AddComponent("propagator")
    inst.components.propagator.damages = true
    inst.components.propagator.propagaterange = 5
    inst.components.propagator.damagerange = 5
    inst.components.propagator:StartSpreading()

    inst:AddComponent("cooker")

    SpawnRocks(inst, "lava_pond_rock")

    return inst
end

return Prefab("object/lava_pond", fn, assets, prefabs),
Prefab("object/lava_pond_rock", rock_fn, rock_assets)