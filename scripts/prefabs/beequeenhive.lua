require "prefabutil"

local base_assets =
{
    Asset("ANIM", "anim/hive_base.zip"),
}

local base_prefabs =
{
    "beequeenhivegrown",
}

local assets =
{
    Asset("ANIM", "anim/bee_queen_hive.zip"),
}

local prefabs =
{
    "beequeen",
    "honey",
    "honeycomb",
}

local MAX_WORK = 16
local SPAWN_WORK_THRESHOLD = 12

local function StartHiveGrowthTimer(inst)
    inst.components.timer:StartTimer("hivegrowth", GetRandomMinMax(TUNING.BEEQUEEN_MIN_RESPAWN_TIME, TUNING.BEEQUEEN_MAX_RESPAWN_TIME))
end

local function OnQueenRemoved(queen)
    if queen.hivebase ~= nil then
        local otherqueen = queen.hivebase.components.entitytracker:GetEntity("queen")
        if (otherqueen == nil or otherqueen == queen) and
            queen.hivebase.components.entitytracker:GetEntity("hive") == nil then
            StartHiveGrowthTimer(queen.hivebase)
        end
    end
end

local function OnWorked(inst, worker, workleft)
    if not inst.components.workable.workable then
        return
    end

    inst.components.timer:StopTimer("hiveregen")

    if workleft < 1 then
        inst.components.workable:SetWorkLeft(1)
    end

    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
    inst.AnimState:PlayAnimation("hit")

    if worker ~= nil and worker:IsValid() and
        worker.components.health ~= nil and not worker.components.health:IsDead() and
        worker:HasTag("player") and not worker:HasTag("playerghost") then

        local spawnchance = workleft < SPAWN_WORK_THRESHOLD and math.min(.8, 1 - workleft / SPAWN_WORK_THRESHOLD) or 0
        if math.random() < spawnchance then
            inst.components.workable:SetWorkable(false)
            local x1, y1, z1 = worker.Transform:GetWorldPosition()
            inst:ListenForEvent("animover", function()
                local x, y, z = inst.Transform:GetWorldPosition()
                local hivebase = inst.hivebase
                inst:Remove()

                local queen = SpawnPrefab("beequeen")
                queen.Transform:SetPosition(x, y, z)
                queen:ForceFacePoint(x1, y1, z1)

                if worker:IsValid() and
                    worker.components.health ~= nil and
                    not worker.components.health:IsDead() and
                    not worker:HasTag("playerghost") then
                    queen.components.combat:SetTarget(worker)
                end

                queen.sg:GoToState("emerge")
                if hivebase ~= nil then
                    queen.hivebase = hivebase
                    hivebase.components.timer:StopTimer("hivegrowth")
                    hivebase.components.entitytracker:TrackEntity("queen", queen)
                    hivebase:ListenForEvent("onremove", OnQueenRemoved, queen)
                end
            end)
            return
        end

        local lootscale = workleft / MAX_WORK
        local rnd = lootscale > 0 and math.random() / lootscale or 1
        local loot =
            (rnd < .1 and "honeycomb") or
            (rnd < .5 and "honey") or
            nil

        if loot ~= nil then
            loot = SpawnPrefab(loot)
            local x, y, z = inst.Transform:GetWorldPosition()
            local angle = (150 + math.random() * 60 - worker:GetAngleToPoint(x, 0, z)) * DEGREES
            local speed = math.random() * 2 + 1
            loot.Transform:SetPosition(x + math.cos(angle), 3.5, z + math.sin(angle))
            loot.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 6, speed * math.sin(angle))
        end
    end

    inst.AnimState:PushAnimation("idle", false)

    inst.components.timer:StartTimer("hiveregen", 4 * TUNING.SEG_TIME)
end

local function OnHiveRegenTimer(inst, data)
    if data.name == "hiveregen" and
        inst.components.workable.workable and
        inst.components.workable.workleft < MAX_WORK then
        inst.components.workable:SetWorkLeft(inst.components.workable.workleft + 1)
        if inst.components.workable.workleft < MAX_WORK then
            inst.components.timer:StartTimer("hiveregen", TUNING.SEG_TIME)
        end
    end
end

local function OnHiveGrowAnimOver(inst)
    inst:RemoveEventCallback("animover", OnHiveGrowAnimOver)
    inst.components.workable:SetWorkable(true)
end

local function OnHiveRemoved(hive)
    if hive.hivebase ~= nil then
        local otherhive = hive.hivebase.components.entitytracker:GetEntity("hive")
        if otherhive == nil or otherhive == hive then
            hive.hivebase.AnimState:PlayAnimation("grow")
            hive.hivebase.AnimState:PushAnimation("idle", false)
            hive.hivebase.Physics:SetActive(true)
            hive.hivebase:RemoveTag("NOCLICK")

            if hive.hivebase.components.entitytracker:GetEntity("queen") == nil then
                StartHiveGrowthTimer(hive.hivebase)
            end
        end
    end
end

local function OnHiveGrowthTimer(inst, data)
    if data.name == "hivegrowth" then
        inst.AnimState:PlayAnimation("shrink")
        inst.AnimState:PushAnimation("empty", false)
        inst.Physics:SetActive(false)
        inst:AddTag("NOCLICK")

        local hive = SpawnPrefab("beequeenhivegrown")
        hive.Transform:SetPosition(inst.Transform:GetWorldPosition())
        hive.AnimState:PlayAnimation("grow")
        hive.components.workable:SetWorkable(false)
        hive:ListenForEvent("animover", OnHiveGrowAnimOver)

        hive.hivebase = inst
        inst.components.entitytracker:TrackEntity("hive", hive)
        inst:ListenForEvent("onremove", OnHiveRemoved, hive)
    end
end

local function OnBaseLoadPostPass(inst, newents, data)
    local hive = inst.components.entitytracker:GetEntity("hive")
    if hive ~= nil then
        hive.hivebase = inst
        inst.components.timer:StopTimer("hivegrowth")
        inst.AnimState:PlayAnimation("empty")
        inst.Physics:SetActive(false)
        inst:AddTag("NOCLICK")
        inst:ListenForEvent("onremove", OnHiveRemoved, hive)
    end

    local queen = inst.components.entitytracker:GetEntity("queen")
    if queen ~= nil then
        queen.hivebase = inst
        inst.components.timer:StopTimer("hivegrowth")
        inst:ListenForEvent("onremove", OnQueenRemoved, queen)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.9)

    inst.AnimState:SetBank("bee_queen_hive")
    inst.AnimState:SetBuild("bee_queen_hive")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetScale(1.4, 1.4, 1.4)

    inst.MiniMapEntity:SetIcon("beequeenhivegrown.png")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnHiveRegenTimer)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetOnWorkCallback(OnWorked)
    inst.components.workable:SetMaxWork(MAX_WORK)
    inst.components.workable:SetWorkLeft(MAX_WORK)
    inst.components.workable.savestate = true

    return inst
end

local function base_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    --MakeObstaclePhysics(inst, 2)
    ----------------------------------------------------
    inst:AddTag("blocker")
    inst.entity:AddPhysics()
    inst.Physics:SetMass(0) 
    inst.Physics:SetCapsule(2, 2)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    --inst.Physics:CollidesWith(COLLISION.GIANTS)
    ----------------------------------------------------

    inst.AnimState:SetBank("hive_base")
    inst.AnimState:SetBuild("hive_base")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.Transform:SetScale(1.4, 1.4, 1.4)

    inst.MiniMapEntity:SetIcon("beequeenhive.png")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")
    StartHiveGrowthTimer(inst)
    inst:ListenForEvent("timerdone", OnHiveGrowthTimer)

    inst:AddComponent("entitytracker")

    inst.LoadPostPass = OnBaseLoadPostPass

    return inst
end

return Prefab("beequeenhive", base_fn, base_assets, base_prefabs),
    Prefab("beequeenhivegrown", fn, assets, prefabs)
