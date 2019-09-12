local assets =
{
	Asset("ANIM", "anim/salt_pillar.zip"),
	Asset("ANIM", "anim/salt_pillar2.zip"),
	Asset("ANIM", "anim/salt_pillar3.zip"),
}

local prefabs =
{
    "saltrock",
}

SetSharedLootTable("saltstack",
{
    {"rocks",     1.00},
    {"rocks",     0.50},
    {"saltrock",  1.00},
    {"saltrock",  1.00},
    {"saltrock",  1.00},
    {"saltrock",  0.50},
})


local function updateart(inst)
    local workleft = inst.components.workable.workleft
	inst.AnimState:PlayAnimation(
		(workleft > 6 and "full") or
		(workleft > 3 and "med") or "low"
	)
end

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
        updateart(inst)
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

local function SetupStack(inst, stackid)
    if inst.stackid == nil then
        inst.stackid = stackid or math.random(1, 3)
    end

    if inst.stackid == 3 then
		inst.AnimState:SetBuild("salt_pillar3")
		inst.AnimState:SetBank("salt_pillar3")

        inst.components.floater:SetVerticalOffset(0.2)
        inst.components.floater:SetScale(0.52)
        inst.components.floater:SetSize("large")
    elseif inst.stackid == 2 then
		inst.AnimState:SetBuild("salt_pillar2")
		inst.AnimState:SetBank("salt_pillar2")

        inst.components.floater:SetVerticalOffset(0.2)
        inst.components.floater:SetScale(0.54)
        inst.components.floater:SetSize("large")
    else
		inst.AnimState:SetBuild("salt_pillar")
		inst.AnimState:SetBank("salt_pillar")

        inst.components.floater:SetVerticalOffset(0.2)
        inst.components.floater:SetScale(0.6)
        inst.components.floater:SetSize("large")
	end

    updateart(inst)
end

local function onsave(inst, data)
    data.stackid = inst.stackid
end

local function onload(inst, data)
	if data ~= nil then
		SetupStack(inst, data.stackid or nil)
		updateart(inst)
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("saltstack.png")

    inst:SetPhysicsRadiusOverride(2.35)

    MakeWaterObstaclePhysics(inst, 0.80, 2, 1.25)

    inst:AddTag("ignorewalkableplatforms")

    inst.AnimState:SetBank("salt_pillar")
    inst.AnimState:SetBuild("salt_pillar")

	inst.AnimState:PlayAnimation("full")

    MakeInventoryFloatable(inst, "med", nil, 0.85)
    inst.components.floater.bob_percent = 0

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0, function(inst)
        SetupStack(inst)
        inst.components.floater:OnLandedServer()
    end)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("saltstack")
    inst.components.lootdropper.max_speed = 2
    inst.components.lootdropper.min_speed = 0.3
    inst.components.lootdropper.y_speed = 14
    inst.components.lootdropper.y_speed_variance = 4
    inst.components.lootdropper.spawn_loot_inside_prefab = true

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.SEASTACK_MINE)
    inst.components.workable:SetOnWorkCallback(OnWork)
	inst.components.workable.savestate = true
	inst.components.workable:SetOnLoadFn(updateart)


	--

    inst:AddComponent("inspectable")

    inst:ListenForEvent("on_collide", OnCollide)

    --------SaveLoad
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

local function spawnerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("CLASSIFIED")

    return inst
end

return Prefab("saltstack", fn, assets, prefabs)