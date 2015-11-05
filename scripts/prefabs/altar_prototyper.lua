require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/crafting_table.zip"),
	Asset("MINIMAP_IMAGE", "tab_crafting_table"),
}

local prefabs =
{
    "tentacle_pillar_arm",
    "armormarble",
    "armor_sanity",
    "armorsnurtleshell",
    "resurrectionstatue",
    "icestaff",
    "firestaff",
    "telestaff",
    "thulecite",
    "orangestaff",
    "greenstaff",
    "yellowstaff",
    "amulet",
    "blueamulet",
    "purpleamulet",
    "orangeamulet",
    "greenamulet",
    "yellowamulet",
    "redgem",
    "bluegem",
    "orangegem",
    "greengem",
    "purplegem",
    "stafflight",
    "monkey",
    "bat",
    "spider_hider",
    "spider_spitter",
    "gears",
    "crawlingnightmare",
    "nightmarebeak",
    "collapse_small",
}

for k = 1, NUM_TRINKETS do
    table.insert(prefabs, "trinket_"..tostring(k))
end

SetSharedLootTable("ancient_altar",
{
    {'thulecite',       1.00},
    {'thulecite',       1.00},
    {'nightmarefuel',   0.50},
    {'trinket_6',       0.50},
    {'rocks',           0.50},
})

local spawns =
{
    armormarble         = 0.5,
    armor_sanity        = 0.5,
    armorsnurtleshell   = 0.5,
    resurrectionstatue  = 1,
    icestaff            = 1,
    firestaff           = 1,
    telestaff           = 1,
    thulecite           = 1,
    orangestaff         = 1,
    greenstaff          = 1,
    yellowstaff         = 1,
    amulet              = 1,
    blueamulet          = 1,
    purpleamulet        = 1,
    orangeamulet        = 1,
    greenamulet         = 1,
    yellowamulet        = 1,
    redgem              = 5,
    bluegem             = 5,
    orangegem           = 5,
    greengem            = 5,
    purplegem           = 5,
    health_plus         = 10,
    health_minus        = 10,
    stafflight          = 15,
    monkey              = 100,
    bat                 = 100,
    spider_hider        = 100,
    spider_spitter      = 100,
    trinket             = 100,
    gears               = 100,
    crawlingnightmare   = 110,
    nightmarebeak       = 110,
}

local actions =
{
    tentacle_pillar_arm = { amt = 6, var = 1, sanity = -TUNING.SANITY_TINY, radius = 3 },
    monkey              = { amt = 3, var = 1, },
    bat                 = { amt = 5, },
    trinket             = { amt = 4, },
    spider_hider        = { amt = 2, },
    spider_spitter      = { amt = 2, },
    stafflight          = { amt = 1, },
}

local function PlayerSpawnCritter(player, critter, pos)
    TheWorld:PushEvent("ms_sendlightningstrike", pos)
    SpawnPrefab("collapse_small").Transform:SetPosition(pos:Get())
    local spawn = SpawnPrefab(critter)
    if spawn ~= nil then
        spawn.Transform:SetPosition(pos:Get())
        if spawn.components.combat ~= nil then
            spawn.components.combat:SetTarget(player)
        end
    end
end

local function SpawnCritter(critter, pos, player)
    player:DoTaskInTime(GetRandomWithVariance(1, 0.8), PlayerSpawnCritter, critter, pos)
end

local function SpawnAt(inst, prefab)
    local pos = inst:GetPosition()
    local offset, check_angle, deflected = FindWalkableOffset(pos, math.random() * 2 * PI, 4 , 8, true, false) -- try to avoid walls
    if offset ~= nil then
        return SpawnPrefab(prefab).Transform:SetPosition((pos + offset):Get())
    end
end

local function DoRandomThing(inst, pos, count, target)
    count = count or 1
    pos = pos or inst:GetPosition()

    for doit = 1, count do
        local item = weighted_random_choice(spawns)

        local doaction = actions[item]

        local amt = doaction ~= nil and doaction.amt or 1
        local sanity = doaction ~= nil and doaction.sanity or 0
        local health = doaction ~= nil and doaction.health or 0
        local func = doaction ~= nil and doaction.callback or nil
        local radius = doaction ~= nil and doaction.radius or 4

        local player = target

        if doaction ~= nil and doaction.var ~= nil then
            amt = math.max(0, GetRandomWithVariance(amt, doaction.var))
        end

        if amt == 0 and func ~= nil then
            func(inst, item, doaction)
        end

        for i = 1, amt do
            local offset, check_angle, deflected = FindWalkableOffset(pos, math.random() * 2 * PI, radius , 8, true, false) -- try to avoid walls
            if offset ~= nil then
                if func ~= nil then
                    func(inst, item, doaction)
                elseif item == "trinket" then
                    SpawnCritter("trinket_"..tostring(math.random(NUM_TRINKETS)), pos + offset, player)
                else
                    SpawnCritter(item, pos + offset, player)
                end
            end
        end
    end
end

local function turnlightoff(inst, light)
    inst.SoundEmitter:KillSound("idlesound")
    if light ~= nil then
        light:Enable(false)
    end
end


local function common_fn(anim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.8, 1.2)

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("tab_crafting_table.png")

    inst.AnimState:SetBank("crafting_table")
    inst.AnimState:SetBuild("crafting_table")
    inst.AnimState:PlayAnimation(anim)

    inst.Light:Enable(false)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(1, 1, 1)

    inst:AddTag("altar")
    inst:AddTag("structure")
    inst:AddTag("stone")

    --prototyper (from prototyper component) added to pristine state for optimization
    inst:AddTag("prototyper")

    inst:SetPrefabNameOverride("ancient_altar")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._activecount = 0

    inst:AddComponent("inspectable")

    inst:AddComponent("prototyper")

    inst:AddComponent("lighttweener")

    inst:AddComponent("workable")

    MakeHauntableWork(inst)

    return inst
end

local function complete_onturnon(inst)
    inst.AnimState:PlayAnimation("proximity_loop", true)
    if not inst.SoundEmitter:PlayingSound("idlesound") then
        inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_LP", "idlesound")
    end
    inst.Light:Enable(true)
    inst.components.lighttweener:StartTween(inst.Light, 3, nil, nil, nil, 0.5)
end

local function complete_onturnoff(inst)
    inst.AnimState:PushAnimation("idle_full")
    inst.components.lighttweener:StartTween(inst.Light, 0, nil, nil, nil, 1, turnlightoff)
end

local function complete_doonact(inst)
    if inst._activecount > 1 then
        inst._activecount = inst._activecount - 1
    else
        inst._activecount = 0
        inst.SoundEmitter:KillSound("sound")
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_3_ding")
end

local function complete_onactivate(inst)
    inst.AnimState:PlayAnimation("use")
    inst.AnimState:PushAnimation("proximity_loop", true)

    inst._activecount = inst._activecount + 1

    if not inst.SoundEmitter:PlayingSound("sound") then
        inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_craft", "sound")
    end

    inst:DoTaskInTime(1.5, complete_doonact)
end

local function complete_onhammered(inst, worker)
    local pos = inst:GetPosition()
    local broken = SpawnPrefab("ancient_altar_broken")
    broken.Transform:SetPosition(pos:Get())
    broken.components.workable:SetWorkLeft(TUNING.ANCIENT_ALTAR_BROKEN_WORK)
    TheWorld:PushEvent("ms_sendlightningstrike", pos)
    SpawnPrefab("collapse_small").Transform:SetPosition(pos:Get())
    DoRandomThing(inst, pos, nil, worker)
    inst:Remove()
end

local function complete_fn()
    local inst = common_fn("idle_full")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.ANCIENTALTAR_HIGH

    inst.components.prototyper.onturnon = complete_onturnon
    inst.components.prototyper.onturnoff = complete_onturnoff
    inst.components.prototyper.onactivate = complete_onactivate

    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(TUNING.ANCIENT_ALTAR_COMPLETE_WORK)
    inst.components.workable:SetMaxWork(TUNING.ANCIENT_ALTAR_COMPLETE_WORK)
    inst.components.workable:SetOnFinishCallback(complete_onhammered)

    return inst
end

local function broken_onturnon(inst)
    if not inst.SoundEmitter:PlayingSound("idlesound") then
        inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_LP", "idlesound")
    end
    inst.Light:Enable(true)
    inst.components.lighttweener:StartTween(inst.Light, 3, nil, nil, nil, 0.5)
end

local function broken_onturnoff(inst)
    inst.components.lighttweener:StartTween(inst.Light, 0, nil, nil, nil, 1, turnlightoff)
end

local function broken_doonact(inst)
    if inst._activecount > 1 then
        inst._activecount = inst._activecount - 1
    else
        inst._activecount = 0
        inst.SoundEmitter:KillSound("sound")
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_3_ding")
    SpawnPrefab("sanity_lower").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function broken_onactivate(inst)
    inst.AnimState:PlayAnimation("hit_broken")
    inst.AnimState:PushAnimation("idle_broken")

    inst._activecount = inst._activecount + 1

    if not inst.SoundEmitter:PlayingSound("sound") then
        inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_craft", "sound")
    end

    inst:DoTaskInTime(1.5, broken_doonact)
end

local function broken_onrepaired(inst, doer, repair_item)
    if inst.components.workable.workleft < inst.components.workable.maxwork then
        inst.AnimState:PlayAnimation("hit_broken")
        inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_repair")
    else
        local pos = inst:GetPosition()
        local altar = SpawnPrefab("ancient_altar")
        altar.Transform:SetPosition(pos:Get())
        altar.SoundEmitter:PlaySound("dontstarve/common/ancienttable_activate")
        SpawnPrefab("collapse_big").Transform:SetPosition(pos:Get())
        TheWorld:PushEvent("ms_sendlightningstrike", pos)
        inst:Remove()
    end
end

local function broken_onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()

    local pos = inst:GetPosition()
    TheWorld:PushEvent("ms_sendlightningstrike", pos)
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(pos:Get())
    fx:SetMaterial("stone")
    --##TODO: Random magic thing here.
    DoRandomThing(inst, pos, nil, worker)

    inst:Remove()
end

local function broken_onworked(inst, worker, workleft)
    inst.AnimState:PlayAnimation("hit_broken")
    --##TODO: Random magic thing here.
    local pos = inst:GetPosition()
    DoRandomThing(inst, pos, nil, worker)
end

local function broken_fn()
    local inst = common_fn("idle_broken")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = MATERIALS.THULECITE
    inst.components.repairable.onrepaired = broken_onrepaired

    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.ANCIENTALTAR_LOW

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("ancient_altar")

    inst.components.prototyper.onturnon = broken_onturnon
    inst.components.prototyper.onturnoff = broken_onturnoff
    inst.components.prototyper.onactivate = broken_onactivate

    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetMaxWork(TUNING.ANCIENT_ALTAR_BROKEN_WORK+1) -- the last point repairs it to a full altar
    inst.components.workable:SetOnFinishCallback(broken_onhammered)
    inst.components.workable:SetOnWorkCallback(broken_onworked)
    inst.components.workable.savestate = true

    return inst
end

return Prefab("ancient_altar", complete_fn, assets, prefabs),
Prefab("ancient_altar_broken", broken_fn, assets, prefabs)
