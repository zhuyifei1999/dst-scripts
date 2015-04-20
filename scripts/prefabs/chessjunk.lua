require "prefabutil"

local MAXHITS = 6

local function SpawnScion(inst, friendly, causedbyplayer)
	local player = causedbyplayer or inst:GetNearestPlayer()

    local spawn = ""
    if inst.style == 1 then
        spawn = (math.random()<.5 and "bishop_nightmare") or "knight_nightmare"
    elseif inst.style == 2 then
        spawn = (math.random()<.3 and "rook_nightmare") or "knight_nightmare"
    else
        spawn = (math.random()<.3 and "rook_nightmare") or "bishop_nightmare"
    end

    SpawnAt("maxwell_smoke",inst)
    local it = SpawnAt(spawn,inst)
    if it and it.components.combat and not friendly then
        it.components.combat:SetTarget(player)
    elseif it.components.follower then
        inst.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
        it.components.follower:SetLeader(player)
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
        inst.AnimState:PlayAnimation("hit" .. inst.style )
	    inst.AnimState:PushAnimation("idle" .. inst.style )
    else
	    inst.AnimState:PlayAnimation("hit" .. inst.style )
	    inst.AnimState:PushAnimation("hit" .. inst.style )
        inst.SoundEmitter:PlaySound("dontstarve/common/chesspile_ressurect")
        inst.components.lootdropper:DropLoot()
	    doer:DoTaskInTime(0.7, OnPlayerRepaired, inst)
    end
end

--KAJ: NOT USED
--local function OnPlayerSpawnCritter(player, critter, pos)
--    TheWorld:PushEvent("ms_sendlightningstrike", pos)
--    SpawnAt("small_puff", pos, { 2, 2, 2 })
--    SpawnAt(critter, pos)
--end
--KAJ: NOT USED
--local function SpawnCritter(critter, pos)
--	ThePlayer:DoTaskInTime(GetRandomWithVariance(1, 0.8), OnPlayerSpawnCritter, critter, pos)
--end

local function OnHammered(inst, worker)
    SpawnAt("collapse_small", inst)
	inst.components.lootdropper:DropLoot()
    if math.random() <= .1 then
        TheWorld:PushEvent("ms_sendlightningstrike", Vector3(inst.Transform:GetWorldPosition()))
        SpawnScion(inst, false, worker)
    else
        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")
    end
	inst:Remove()
end

local function OnHit(inst, worker, workLeft)
	inst.AnimState:PlayAnimation("hit" .. inst.style )
	inst.AnimState:PushAnimation("idle" .. inst.style )
    inst.SoundEmitter:PlaySound("dontstarve/common/lightningrod")
end

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

local function BasePile()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.2)

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.AnimState:SetBank("chessmonster_ruins")
    inst.AnimState:SetBuild("chessmonster_ruins")

    inst.MiniMapEntity:SetIcon("chessjunk.png")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"trinket_6"}) -- frazzled wires
    inst.components.lootdropper:AddRandomLoot("trinket_6"  , 0.55)
    inst.components.lootdropper:AddRandomLoot("gears"     , 0.25)
    inst.components.lootdropper:AddRandomLoot("trinket_1" , 0.25) -- marbles
    inst.components.lootdropper:AddRandomLoot("redgem"    , 0.05)
    inst.components.lootdropper:AddRandomLoot("greengem"  , 0.05)
    inst.components.lootdropper:AddRandomLoot("yellowgem" , 0.05)
    inst.components.lootdropper:AddRandomLoot("purplegem" , 0.05)
    inst.components.lootdropper:AddRandomLoot("orangegem" , 0.05)
    if TheWorld:HasTag("cave") and TheWorld.topology.level_number == 2 then  -- ruins
        inst.components.lootdropper:AddRandomLoot("thulecite" , 0.01)
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(MAXHITS/2)
    inst.components.workable:SetMaxWork(MAXHITS)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)		

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = MATERIALS.GEARS
    inst.components.repairable.onrepaired = OnRepaired
    inst:AddTag("chess")
    inst:AddTag("mech")

    MakeHauntableWork(inst)

    inst:AddComponent("inspectable")

	return inst
end

local function Junk(style)
    return function()
        local inst = BasePile()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.style = style
        inst.AnimState:PlayAnimation("idle" .. inst.style)

        return inst
    end
end

return  Prefab("common/objects/chessjunk1", Junk(1), assets,prefabs),
        Prefab("common/objects/chessjunk2", Junk(2), assets,prefabs),
        Prefab("common/objects/chessjunk3", Junk(3), assets,prefabs)