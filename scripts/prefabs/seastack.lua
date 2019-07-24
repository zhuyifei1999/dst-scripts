local assets =
{
    Asset("ANIM", "anim/water_rock_01.zip"),
    Asset("MINIMAP_IMAGE", "seastack"),
}

local prefabs =
{
    
}

SetSharedLootTable( 'seastack',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
})

local function OnWork(inst, worker, workleft)
    if workleft <= 0 then
        local pt = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pt:Get())

        local loot_dropper = inst.components.lootdropper
        --local boat_physics = worker.components.boatphysics

        inst:SetPhysicsRadiusOverride(nil)

        --if boat_physics ~= nil then
    --        loot_dropper.min_speed = 3
    --        loot_dropper.max_speed = 5.5
    --        loot_dropper:SetFlingTarget(worker:GetPosition(), 20)
        --end

        loot_dropper:DropLoot(pt)

        inst:Remove()
    else
        inst.AnimState:PlayAnimation(
            (workleft > 6 and "1_full") or
            (workleft > 3 and "1_med") or "1_low"
        )
    end
end

local function OnCollide(inst, data)
    local boat_physics = data.other.components.boatphysics
    if boat_physics ~= nil then
        local damage_scale = 0.5
        local hit_velocity = math.floor(math.abs(boat_physics:GetVelocity() * data.hit_dot_velocity) * damage_scale / boat_physics.max_velocity + 0.5)
        inst.components.workable:WorkedBy(data.other, hit_velocity * TUNING.SEASTACK_MINE)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("seastack.png")

    inst:SetPhysicsRadiusOverride(2.35)

    MakeWaterObstaclePhysics(inst, 0.80, 2, 1.25)

    inst.Transform:SetFourFaced()
    inst:AddTag("ignorewalkableplatforms")

    inst.AnimState:SetBank("water_rock01")
    inst.AnimState:SetBuild("water_rock_01")
    inst.AnimState:PlayAnimation("1_full")

    MakeInventoryFloatable(inst, "med", nil, 0.85)
    inst.components.floater.bob_percent = 0

    inst.entity:SetPristine()    

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function(inst)
        inst.components.floater:OnLandedServer()
    end)

    inst:AddComponent("lootdropper")     
    inst.components.lootdropper:SetChanceLootTable('seastack')
    inst.components.lootdropper.max_speed = 2
    inst.components.lootdropper.min_speed = 0.3
    inst.components.lootdropper.y_speed = 14
    inst.components.lootdropper.y_speed_variance = 4
    inst.components.lootdropper.spawn_loot_inside_prefab = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.SEASTACK_MINE)
    inst.components.workable:SetOnWorkCallback(OnWork)    

    inst:AddComponent("inspectable")

    inst:ListenForEvent("on_collide", OnCollide)

    return inst
end

return Prefab("seastack", fn, assets, prefabs)
