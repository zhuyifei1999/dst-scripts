local assets =
{
    Asset("ANIM", "anim/koalefant_tracks.zip"),
}

local function OnSave(inst, data)
    --print("animal_track - OnSave")

    data.direction = inst.Transform:GetRotation()
    --print("    direction", data.direction)
end
        
local function OnLoad(inst, data)
    --print("animal_track - OnLoad")

    if data and data.direction then
        --print("    direction", data.direction)
        inst.Transform:SetRotation(data.direction)
    end
end

local function create(sim)
    --print("animal_track - create")
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddTag("track")
    
    inst.AnimState:SetBank("track")
    inst.AnimState:SetBuild("koalefant_tracks")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder( 3 )
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:PlayAnimation("idle")

    --inst.Transform:SetRotation(math.random(360))
    
    inst:AddComponent("inspectable")

    inst:StartThread(
        function ()
            Sleep(30)
            fadeout(inst, 15) 
            inst:Remove() 
        end 
    )

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    -- inst:DoTaskInTime(10, fadeout, 5)
    -- inst:ListenForEvent("fadecomplete", inst.Remove)

    --inst.persists = false
    return inst
end

return Prefab("forest/objects/animal_track", create, assets)