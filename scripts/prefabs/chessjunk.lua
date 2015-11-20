require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/chessmonster_ruins.zip"),
}

local prefabs =
{
    "bishop",
    "rook",
    "knight",
    "gears",
    "redgem",
    "greengem",
    "yellowgem",
    "purplegem",
    "orangegem",
    "collapse_small",
}

SetSharedLootTable("chess_junk",
{
    {'trinket_6',      1.00},
    {'trinket_6',      0.55},
    {'trinket_1',      0.25},
    {'gears',          0.25},
    {'redgem',         0.25},
    {"greengem" ,      0.05},
    {"yellowgem",      0.05},
    {"purplegem",      0.05},
    {"orangegem",      0.05},
    {"thulecite",      0.01},
})

local MAXHITS = 6

local function SpawnScion(inst, friendly, causedbyplayer)
    local player = causedbyplayer or inst:GetNearestPlayer()

    local spawn =
        (inst.style == 1 and (math.random() < .5 and "bishop_nightmare" or "knight_nightmare")) or
        (inst.style == 2 and (math.random() < .3 and "rook_nightmare" or "knight_nightmare")) or
        (math.random() < .3 and "rook_nightmare" or "bishop_nightmare")

    SpawnAt("maxwell_smoke", inst)

    local it = SpawnAt(spawn, inst)
    if it ~= nil and player ~= nil then
        if not friendly and it.components.combat ~= nil then
            it.components.combat:SetTarget(player)
        elseif it.components.follower ~= nil then
            player:PushEvent("makefriend")
            it.components.follower:SetLeader(player)
        end
    end
end

local function OnPlayerRepaired(player, inst)
    inst.components.lootdropper:AddChanceLoot("gears", 0.1)
    if TheWorld:HasTag("cave") and TheWorld.topology.level_number == 2 then  -- ruins
        inst.components.lootdropper:AddChanceLoot("thulecite", 0.05)
    end
    inst.components.lootdropper:DropLoot()
    SpawnScion(inst, true, player)
    inst:Remove()
end

local function OnRepaired(inst, doer)
    if inst.components.workable.workleft < MAXHITS then
        inst.SoundEmitter:PlaySound("dontstarve/common/chesspile_repair")
        inst.AnimState:PlayAnimation("hit"..inst.style)
        inst.AnimState:PushAnimation("idle"..inst.style)
    else
        inst.AnimState:PlayAnimation("hit"..inst.style)
        inst.AnimState:PushAnimation("hit"..inst.style)
        inst.SoundEmitter:PlaySound("dontstarve/common/chesspile_ressurect")
        inst.components.lootdropper:DropLoot()
        doer:DoTaskInTime(0.7, OnPlayerRepaired, inst)
    end
end

local function OnHammered(inst, worker)
    local fx = SpawnAt("collapse_small", inst)
    inst.components.lootdropper:DropLoot()
    if math.random() <= .1 then
        TheWorld:PushEvent("ms_sendlightningstrike", Vector3(inst.Transform:GetWorldPosition()))
        SpawnScion(inst, false, worker)
    else
        fx:SetMaterial("metal")
    end
    inst:Remove()
end

local function OnHit(inst, worker, workLeft)
    inst.AnimState:PlayAnimation("hit"..inst.style)
    inst.AnimState:PushAnimation("idle"..inst.style)
    inst.SoundEmitter:PlaySound("dontstarve/common/lightningrod")
end

local function BasePile(style)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.2)

    inst:AddTag("chess")
    inst:AddTag("mech")

    inst.MiniMapEntity:SetIcon("chessjunk.png")

    inst.style = style

    inst.AnimState:SetBank("chessmonster_ruins")
    inst.AnimState:SetBuild("chessmonster_ruins")
    inst.AnimState:PlayAnimation("idle"..inst.style)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("chess_junk")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(MAXHITS/2)
    inst.components.workable:SetMaxWork(MAXHITS)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = MATERIALS.GEARS
    inst.components.repairable.onrepaired = OnRepaired

    MakeHauntableWork(inst)

    return inst
end

local function Junk(style)
    return function()
        return BasePile(style)
    end
end

return Prefab("common/objects/chessjunk1", Junk(1), assets, prefabs),
    Prefab("common/objects/chessjunk2", Junk(2), assets, prefabs),
    Prefab("common/objects/chessjunk3", Junk(3), assets, prefabs)
