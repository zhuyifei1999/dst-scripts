local assets =
{
    Asset("ANIM", "anim/staff_purple_base_ground.zip"),
}

local prefabs =
{
    "gemsocket",
    "collapse_small",
}

local function teleport_target(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        if v.DestroyGemFn ~= nil then
            v.DestroyGemFn(v)
        end
    end
end

local function validteleporttarget(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        if v.components.pickable ~= nil and not v.components.pickable.caninteractwith then
            return false
        end
    end
    return true
end

local function getstatus(inst)
    return validteleporttarget(inst) and "VALID" or "GEMS"
end

local telebase_parts =
{
    { part = "gemsocket", x = -1.6, z = -1.6 },
    { part = "gemsocket", x =  2.7, z = -0.8 },
    { part = "gemsocket", x = -0.8, z =  2.7 },
}

local function removesockets(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        v:Remove()
    end
end

local function ondestroyed(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        if v.components.pickable ~= nil and v.components.pickable.caninteractwith then
            inst.components.lootdropper:AddChanceLoot("purplegem", 1)   
        end
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        if v.components.pickable ~= nil and v.components.pickable.caninteractwith then
            v.AnimState:PlayAnimation("hit_full")
            v.AnimState:PushAnimation("idle_full_loop")
        else
            v.AnimState:PlayAnimation("hit_empty")
            v.AnimState:PushAnimation("idle_empty")
        end
    end
end

local function OnGemChange(inst)
    if validteleporttarget(inst) then
        for k, v in pairs(inst.components.objectspawner.objects) do
            v.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end
    else
        for k, v in pairs(inst.components.objectspawner.objects) do
            v.AnimState:ClearBloomEffectHandle()
        end
    end
end

local function NewObject(inst, obj)
    local function OnGemChangeProxy()
        OnGemChange(inst)
    end

    inst:ListenForEvent("trade", OnGemChangeProxy, obj)
    inst:ListenForEvent("picked", OnGemChangeProxy, obj)

    OnGemChange(inst)
end

local function RevealPart(v)
    v:Show()
    v.AnimState:PlayAnimation("place")
    v.AnimState:PushAnimation("idle_empty")
end

local function OnBuilt(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for k, v in pairs(telebase_parts) do
        local part = inst.components.objectspawner:SpawnObject(v.part)
        part.Transform:SetPosition(x + v.x, 0, z + v.z)
    end

    for k, v in pairs(inst.components.objectspawner.objects) do
        v:Hide()
        v:DoTaskInTime(math.random() * 0.5, RevealPart)
    end
end

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.MiniMapEntity:SetIcon("telebase.png")

    inst:AddTag("telebase")

    inst.AnimState:SetBuild("staff_purple_base_ground")
    inst.AnimState:SetBank("staff_purple_base_ground")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.Transform:SetRotation(45)

    inst.onteleto = teleport_target
    inst.canteleto = validteleporttarget

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(onhit)
    inst.components.workable:SetOnFinishCallback(ondestroyed)

    MakeHauntableWork(inst)

    inst:AddComponent("lootdropper")

    inst:AddComponent("objectspawner")
    inst.components.objectspawner.onnewobjectfn = NewObject

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:ListenForEvent("onremove", removesockets)

    return inst
end

return Prefab("telebase", commonfn, assets, prefabs),
    MakePlacer("telebase_placer", "staff_purple_base_ground", "staff_purple_base_ground", "idle")
