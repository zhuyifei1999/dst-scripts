local assets =
{
    Asset("ANIM", "anim/compass.zip"),
}

local dirs =
{
    N=0, S=180,
    NE=45, E=90, SE=135,
    NW=-45, W=-90, SW=-135, 
}

local haunted_dirs =
{
    N=180, S=0,
    NE=-135, E=-90, SE=-45,
    NW=135, W=90, SW=45, 
}

local function GetStatus(inst, viewer)
    local heading = TheCamera:GetHeading()--inst.Transform:GetRotation() 
    local dir, closest_diff = nil, nil

    if inst.components.hauntable and inst.components.hauntable.haunted then
        for k,v in pairs(haunted_dirs) do
            local diff = math.abs(anglediff(heading, v))
            if not dir or diff < closest_diff then
                dir, closest_diff = k, diff
            end
        end
    else
        for k,v in pairs(dirs) do
            local diff = math.abs(anglediff(heading, v))
            if not dir or diff < closest_diff then
                dir, closest_diff = k, diff
            end
        end
    end
    return dir
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("compass")
    inst.AnimState:SetBuild("compass")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst:AddComponent("inspectable")
    --inst.components.inspectable.noanim = true
    inst.components.inspectable.getstatus = GetStatus

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("common/inventory/compass", fn, assets)