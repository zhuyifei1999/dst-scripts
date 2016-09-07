SetSharedLootTable('sculptures_loot',
{
    {'marble', 1.0},
    {'marble', 0.5},
})

local function onworked(inst, worker, workleft)
    if inst._task ~= nil then
        inst:Reanimate()
    elseif workleft <= TUNING.SCULPTURE_COVERED_WORK then
        inst.components.workable.workleft = 0
    end
end

local PIECE_NAME =
{
    ["sculpture_rookbody"] = "sculpture_rooknose",
    ["sculpture_bishopbody"] = "sculpture_bishophead",
    ["sculpture_knightbody"] = "sculpture_knighthead",
}

local function DoStruggle(inst, count)
    inst.AnimState:PlayAnimation("jiggle")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/lavae/egg_crack")
    inst._task =
        count > 1 and
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), DoStruggle, count - 1) or
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + math.random() + .6, DoStruggle, math.max(1, math.random(3) - 1))
end

local function StartStruggle(inst)
    if inst._task == nil then
        inst._task = inst:DoTaskInTime(math.random(), DoStruggle, 1)
    end
end

local function StopStruggle(inst)
    if inst._task ~= nil then
        inst._task:Cancel()
        inst._task = nil
    end
end

local function CheckMorph(inst)
    if inst.components.repairable == nil and
        inst.components.workable.workleft > TUNING.SCULPTURE_COVERED_WORK and
        TheWorld.state.isfullmoon and
        not inst:IsAsleep() and
        inst._reanimatetask == nil then
        StartStruggle(inst)
    else
        StopStruggle(inst)
    end
end

local function MakeFixed(inst)
    inst.AnimState:PlayAnimation("fixed")
    inst.MiniMapEntity:SetIcon(inst.prefab.."_fixed.png")

    inst.components.workable:SetOnWorkCallback(onworked)

    if inst.components.repairable ~= nil then
        inst:RemoveComponent("repairable")
    end

    inst.components.lootdropper:SetChanceLootTable(nil)
    inst.components.lootdropper:SetLoot({ PIECE_NAME[inst.prefab] })

    CheckMorph(inst)
end

local function checkpiece(inst, piece)
    local basename = string.sub(inst.prefab, 1, -5) --remove "body" suffix
    if basename == string.sub(piece.prefab, 1, #basename) then
        return true
    end
    return false, "WRONGPIECE"
end

local function MakeBroken(inst)
    inst.AnimState:PlayAnimation("med")

    inst.components.workable:SetOnWorkCallback(nil)

    if inst.components.repairable == nil then
        inst:AddComponent("repairable")
        inst.components.repairable.repairmaterial = MATERIALS.SCULPTURE
        inst.components.repairable.onrepaired = MakeFixed
        inst.components.repairable.checkmaterialfn = checkpiece
        inst.components.repairable.noannounce = true
    end

    StopStruggle(inst)
end

local function getstatus(inst)
    return (inst._task ~= nil and "READY")
        or (inst.components.repairable ~= nil and "UNCOVERED")
        or (inst.components.workable.workleft > TUNING.SCULPTURE_COVERED_WORK and "FINISHED")
        or "COVERED"
end

local function onworkfinished(inst, worker)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
    inst.components.lootdropper:DropLoot(inst:GetPosition())

    MakeBroken(inst)

    if inst.components.lootdropper.chanceloottable ~= nil and
        worker ~= nil and worker.components.talker ~= nil then
        -- say the uncovered state description string
        worker.components.talker:Say(inst.components.inspectable:GetDescription(worker, inst, "UNCOVERED"))
    end
end

local function onworkload(inst)
    if inst.components.workable.workleft > TUNING.SCULPTURE_COVERED_WORK then
        MakeFixed(inst)
    elseif inst.components.workable.workleft <= 0 then
        MakeBroken(inst)
    end
end

local function makesculpture(name, physics_radius, second_piece_name)
    local assets =
    {
        Asset("ANIM", "anim/sculpture_"..name..".zip"),
        Asset("MINIMAP_IMAGE", "sculpture_"..name.."body_full.png"),
        Asset("MINIMAP_IMAGE", "sculpture_"..name.."body_fixed.png"),
    }

    local prefabs =
    {
        "marble",
    }

    if second_piece_name ~= nil then
        table.insert(prefabs, "sculpture_"..second_piece_name)
    end

    local function Reanimate(inst)
        if inst._reanimatetask == nil then
            StopStruggle(inst)

            inst.components.workable:SetOnWorkCallback(nil)
            inst.components.workable:SetOnFinishCallback(nil)
            inst.components.workable:SetWorkable(false)

            inst.AnimState:PlayAnimation("transform")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
            RemovePhysicsColliders(inst)
            inst:AddTag("NOCLICK")
            inst.persists = false
            inst._reanimatetask = inst:DoTaskInTime(2, ErodeAway)

            local creature = SpawnPrefab(name)
            creature.Transform:SetPosition(inst.Transform:GetWorldPosition())
            creature.Transform:SetRotation(inst.Transform:GetRotation())
            creature.sg:GoToState("taunt")

            local player = creature:GetNearestPlayer(true)
            if player ~= nil and creature:IsNear(player, 20) then
                creature.components.combat:SetTarget(player)
            end
        end
    end

    local onloadpostpass = second_piece_name ~= nil and function(inst)
        local second_piece = SpawnPrefab("sculpture_"..second_piece_name)

        local placed = false
        while not placed do
            local topology = TheWorld.topology
            local area = topology.nodes[math.random(#topology.nodes)]
            local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(area.x, area.y, area.poly, 1)
            if #points_x == 1 and #points_y == 1 then
                local x = points_x[1]
                local z = points_y[1]

                if TheWorld.Map:CanPlantAtPoint(x, 0, z) then
                    second_piece.Transform:SetPosition(x, 0, z)
                    placed = true
                end
            end
        end
    end or nil

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst:AddTag("statue")
        inst:AddTag("sculpture")

        MakeObstaclePhysics(inst, physics_radius)

        inst.Transform:SetFourFaced()

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild("sculpture_"..name)
        inst.AnimState:PlayAnimation("full")

        inst:SetPrefabName("sculpture_"..name.."body")
        inst.MiniMapEntity:SetIcon(inst.prefab.."_fixed.png")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable("sculptures_loot")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetMaxWork(TUNING.SCULPTURE_COMPLETE_WORK)
        inst.components.workable:SetWorkLeft(TUNING.SCULPTURE_COVERED_WORK)
        inst.components.workable:SetOnFinishCallback(onworkfinished)
        inst.components.workable:SetOnLoadFn(onworkload)
        inst.components.workable.savestate = true

        MakeHauntableWork(inst)

        inst.OnLoadPostPass = onloadpostpass
        inst.OnEntityWake = CheckMorph
        inst.OnEntitySleep = CheckMorph

        inst:WatchWorldState("isfullmoon", CheckMorph)
        inst.Reanimate = Reanimate

        return inst
    end

    local prefab_name = "sculpture_"..(second_piece_name ~= nil and name or (name.."body"))
    return Prefab(prefab_name, fn, assets, prefabs)
end

local ROOK_VOLUME = 2.25
local KNIGHT_VOLUME = 0.66
local BISHOP_VOLUME = 0.70

return makesculpture("rook",   ROOK_VOLUME, nil),    makesculpture("rook",   ROOK_VOLUME, "rooknose"),
       makesculpture("knight", KNIGHT_VOLUME, nil),  makesculpture("knight", KNIGHT_VOLUME, "knighthead"),
       makesculpture("bishop", BISHOP_VOLUME, nil),  makesculpture("bishop", BISHOP_VOLUME, "bishophead")
