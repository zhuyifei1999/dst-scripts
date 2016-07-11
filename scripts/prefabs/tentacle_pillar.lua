local prefabs = 
{
    "tentacle_pillar_arm",
    "tentacle_pillar_hole",
    "tentaclespike",
    "tentaclespots",
    "skeleton",
    "turf_marsh",
    "rocks",
}

local assets =
{
    Asset("ANIM", "anim/tentacle_pillar.zip"),
    Asset("SOUND", "sound/tentacle.fsb"),
	Asset("MINIMAP_IMAGE", "tentapillar"),
}

SetSharedLootTable("tentacle_pillar",
{
    { 'tentaclespike' , 0.50 },
    { 'skeleton'      , 0.10 },
    { 'turf_marsh'    , 0.25 },
    { 'tentaclespots' , 0.40 },
    { 'rocks'         , 1.00 },
})

local function OnLongUpdate(inst, dt)
    inst.emergetime = inst.emergetime - dt
end

-- Kill off the arms in the garden, optionally just those furtherThan the given distance from the player
local function KillArms(inst, instant, fartherThan)
    if type(inst.arms) == "table" then
        if not fartherThan then
            for key, v in pairs(inst.arms) do
                if not instant then
                    key:PushEvent("full_retreat")
                else
                    key:Remove()
                end
            end
            inst.arms = {}
        else
            for key, v in pairs(inst.arms) do
                if not (key:IsNear(inst, 4) or key:IsNearPlayer(fartherThan)) then
                    key:PushEvent("full_retreat")
                end
            end
        end
    end
end

local function ManageArms(inst)
    local numArms = 0
    for key, value in pairs(inst.arms) do
        if not key:IsValid() or key.components.health:IsDead() then
            inst.arms[key] = nil
        else
            numArms = numArms + 1
        end
    end
    return numArms
end

local function ArmEmerge(inst)
    inst:Emerge()
end

local function SpawnArms(inst, attacker, forcelocal)

    -- this can be called with false for the attacker. It should use the(?errr?) player then - this is only used for the position when forcelocal is false
    -- It seems this is actually not used in this combination. When it's called without a target it's called with forcelocal set to true

    --spawn tentacles to spring the trap
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local pillarLoc = pt
    local minRadius = 3
    local ringdelta = 1.5
    local rings = 3
    local steps = math.floor(TUNING.TENTACLE_PILLAR_ARMS / rings + 0.5)

    -- Walk the circle trying to find a valid spawn point 
    local numArms = ManageArms(inst)

    if numArms >= TUNING.TENTACLE_PILLAR_ARMS_TOTAL - 3 then
        KillArms(inst, false, 6)  -- despawn tentacles away from player
        inst.spawnLocal = true
        return
    end

    if not forcelocal and inst.spawnLocal and attacker then
        pt = Vector3(attacker.Transform:GetWorldPosition())
        minRadius = 1
        ringdelta = 1
        rings = 3
        steps = 4
        inst.spawnLocal = nil
    end

    local map = TheWorld.Map

    for r = 1, rings do
        local theta = GetRandomWithVariance(0, PI / 2) -- randomize starting angle
        --print("Starting theta:",theta)
        for i = 1, steps do
            local radius = GetRandomWithVariance(ringdelta, ringdelta / 3) + minRadius
            local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
            local wander_point = pt + offset
            local pillars = TheSim:FindEntities(wander_point.x, wander_point.y, wander_point.z, 3.5, { "tentacle_pillar" })
            if next(pillars) then
                --print("FoundPillar",pillars[1])
                pillarLoc = Vector3(pillars[1].Transform:GetWorldPosition())
            end

            if map:IsAboveGroundAtPoint(wander_point:Get())
                and distsq(pillarLoc, wander_point) > 8
                and numArms < TUNING.TENTACLE_PILLAR_ARMS_TOTAL then

                local arm = SpawnPrefab("tentacle_pillar_arm")
                if arm ~= nil then
                    inst.arms[arm] = true           -- keep track of arms this pillar has
                    numArms = numArms + 1
                    arm.Transform:SetPosition(wander_point:Get())
                    arm:DoTaskInTime(GetRandomWithVariance(0.3, 0.2), ArmEmerge)
                end
            end

            theta = theta - (2 * PI / steps)
        end
        minRadius = minRadius + ringdelta
    end
end

local function Emerge(inst, withArms)
    inst.AnimState:PlayAnimation("emerge")
    inst.AnimState:PushAnimation("idle", true)

    inst.retracted = nil

    inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_emerge")

    ShakeAllCameras(CAMERASHAKE.FULL, 5, .05, .2, inst, 40)

    if withArms then
        SpawnArms(inst, false, true)
    end
end

local function DoShake(inst)
    local quaker = TheWorld.components.quaker

    if quaker and math.random() > 0.3 then
        TheWorld:PushEvent("ms_miniquake", {rad=20, num=20, duration=2.5, target=inst})
        --TheWorld:PushEvent("ms_forcequake", {
            --warningtime = 0,
            --quaketime = function() return GetRandomWithVariance(3,.5) end,
            --debrispersecond = function() return GetRandomWithVariance(20,.5) end,
            --nextquake = function() return TUNING.TOTAL_DAY_TIME * 100 end,
            --mammals = 3,
        --})
    else
        --ShakeAllCameras(CAMERASHAKE.FULL, 5, .05, .2, inst, 40)
    end
end

local function Retract(inst)
    if inst.retracted then
        return
    end

    inst:DoTaskInTime(0, DoShake)

    KillArms(inst)

    inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_die")
    inst.AnimState:PlayAnimation("retract",false)
    inst.retracted = true
end

local function SwapToHole(inst)
    if inst.components.teleporter.numteleporting ~= 0 then
        -- We'll try again once teleporting is complete.
        return
    end

    local x,y,z = inst.Transform:GetWorldPosition()
    local hole = SpawnPrefab("tentacle_pillar_hole")
    hole.Transform:SetPosition(x,y,z)

    local other = inst.components.teleporter.targetTeleporter
    if other then
        hole.components.teleporter:Target(other)
        other.components.teleporter:Target(hole)
    end

    inst:Remove()
end

local function OnDeath(inst)
    Retract(inst)
    inst.SoundEmitter:KillSound("loop")
    inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_die_VO")

    inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()) + Vector3(0,20,0))

    inst.deathpending = true

    inst:ListenForEvent("animover", SwapToHole)
end

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_idle_LP","loop") 
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("loop")
    KillArms(inst, true)
end

local function OnFar(inst)
    ManageArms(inst)
    for arm,v in pairs(inst.arms) do
        arm:Retract()
    end
end

local function OnHit(inst, attacker, damage) 
    if attacker.components.combat and not attacker:HasTag("player") and math.random() > 0.5 then
        -- Followers should stop hitting the pillar
        attacker.components.combat:SetTarget(nil)
    end
    if not inst.components.health:IsDead() then
        inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_hurt_VO")
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)

        if attacker:HasTag("player") then
            attacker:ShakeCamera(CAMERASHAKE.SIDE, .5, .05, .2)
        end
        SpawnArms(inst, attacker)
    end
end

local function OnActivateByOther(inst, source, doer)
    Retract(inst)
    inst.components.health:SetInvincible(true)
end

local function OnDoneTeleporting(inst, obj)
    if inst.emergetask ~= nil then
        inst.emergetask:Cancel()
    end

    if inst.deathpending == true then
        inst.emergetask = inst:DoTaskInTime(1.5, function()
            SwapToHole(inst)
        end)
    else
        inst.emergetask = inst:DoTaskInTime(1.5, function()
            if inst.components.teleporter.numteleporting == 0 then
                inst.components.health:SetInvincible(false)
                Emerge(inst, false)
            end
        end)
    end

    if obj ~= nil and obj:HasTag("player") then
        obj:DoTaskInTime(1, obj.PushEvent, "wormholespit") -- for wisecracker
    end
end

local function CustomOnHaunt(inst, haunter)
    if math.random() < TUNING.HAUNT_CHANCE_RARE then
        inst.components.health:SetPercent(0)
        return true
    end
    return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 2.0, 24)

    -- HACK: this should really be in the c side checking the maximum size of the anim or the _current_ size of the anim instead
    -- of frame 0
    inst.entity:SetAABB(60, 20)

    inst:AddTag("cavedweller")
    inst:AddTag("tentacle_pillar")
    inst:AddTag("wet")

    inst.MiniMapEntity:SetIcon("tentapillar.png")

    inst.AnimState:SetBank("tentaclepillar")
    inst.AnimState:SetBuild("tentacle_pillar")
    inst.AnimState:PlayAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_idle_LP", "loop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.TENTACLE_PILLAR_HEALTH)
    inst.components.health.nofadeout = true
    inst:ListenForEvent("death", OnDeath)

    -------------------
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(10, 30)
    --inst.components.playerprox:SetOnPlayerNear(OnNear)
    inst.components.playerprox:SetOnPlayerFar(OnFar)

    -------------------
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('tentacle_pillar')

    --------------------
    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)

    --------------------
    inst:AddComponent("inspectable")

    --------------------
    inst:AddComponent("teleporter")
    inst.components.teleporter:SetEnabled(false) -- this turns off sending, not receiving
    inst.components.teleporter.onActivateByOther = OnActivateByOther
    inst.components.teleporter.offset = 0
    inst:ListenForEvent("doneteleporting", OnDoneTeleporting)

    --------------------
    
    AddHauntableCustomReaction(inst, CustomOnHaunt)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst.Emerge = Emerge

    inst.arms = {}

    return inst
end
return Prefab("tentacle_pillar", fn, assets, prefabs)
