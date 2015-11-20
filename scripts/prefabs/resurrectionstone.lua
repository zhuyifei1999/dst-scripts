local assets =
{
    Asset("ANIM", "anim/resurrection_stone.zip"),
}

local prefabs =
{
    "rocks",
    "marble",
    "nightmarefuel",
}

local function OnHaunt(inst, haunter)
    inst.components.hauntable:SetOnHauntFn()

    inst.AnimState:PlayAnimation("activate")
    inst.AnimState:PushAnimation("idle_activate", true)
    inst.AnimState:SetLayer(LAYER_WORLD)
    inst.AnimState:SetSortOrder(0)

    inst.SoundEmitter:PlaySound("dontstarve/common/resurrectionstone_activate")

    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    return true
end

local function OnActivateResurrection(inst, guy)
    TheWorld:PushEvent("ms_sendlightningstrike", inst:GetPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/resurrectionstone_break")
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    if not GetGhostEnabled(TheNet:GetServerGameMode()) then
        inst.entity:Hide()
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end

    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.ITEMS)

    inst.AnimState:SetBank("resurrection_stone")
    inst.AnimState:SetBuild("resurrection_stone")
    inst.AnimState:PlayAnimation("idle_off")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("resurrection_stone.png")

    inst:AddTag("resurrector")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "rocks", "rocks", "marble", "nightmarefuel", "marble" })

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst:ListenForEvent("activateresurrection", OnActivateResurrection)

    return inst
end

return Prefab("forest/objects/resurrectionstone", fn, assets, prefabs)