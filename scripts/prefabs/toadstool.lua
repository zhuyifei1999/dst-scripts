local easing = require("easing")

local assets =
{
    Asset("ANIM", "anim/toadstool_basic.zip"),
    Asset("ANIM", "anim/toadstool_actions.zip"),
    Asset("ANIM", "anim/toadstool_build.zip"),
    Asset("ANIM", "anim/toadstool_upg_build.zip"),
}

local prefabs =
{
    "mushroomsprout",
    "mushroombomb_projectile",
    "sporebomb",

    --loot
    "froglegs",
    "meat",
    "shroom_skin",
    "red_cap",
    "blue_cap",
    "green_cap",
    "red_mushroomhat_blueprint",
    "green_mushroomhat_blueprint",
    "blue_mushroomhat_blueprint",
    "mushroom_light_blueprint",
    "mushroom_light2_blueprint",
    MUSHTREE_SPORE_RED,
    MUSHTREE_SPORE_GREEN,
    MUSHTREE_SPORE_BLUE,
}

local function AddSpecialLoot(inst)
	-- one hat
	local hat = GetRandomItem({"red_mushroomhat_blueprint", "green_mushroomhat_blueprint", "blue_mushroomhat_blueprint"})
    inst.components.lootdropper:AddChanceLoot(hat, 1.0)

	-- one mushroom light
	inst.components.lootdropper:AddChanceLoot(math.random() < 0.1 and "mushroom_light2_blueprint" or "mushroom_light_blueprint", 1.0)
    
    -- 2-3 spores
	local sopres = PickSomeWithDups(3, {MUSHTREE_SPORE_RED, MUSHTREE_SPORE_GREEN, MUSHTREE_SPORE_BLUE})
	inst.components.lootdropper:AddChanceLoot(sopres[1], 1.0)
	inst.components.lootdropper:AddChanceLoot(sopres[2], 1.0)
	inst.components.lootdropper:AddChanceLoot(sopres[3], 0.5)
end


SetSharedLootTable('toadstool',
{
    {"froglegs",      1.00},
    {"meat",          1.00},
    {"meat",          1.00},
    {"meat",          1.00},
    {"meat",          0.50},
    {"meat",          0.25},

    {"shroom_skin",   1.00},

    {"red_cap",       1.00},
    {"red_cap",       0.33},
    {"red_cap",       0.33},

    {"blue_cap",      1.00},
    {"blue_cap",      0.33},
    {"blue_cap",      0.33},

    {"green_cap",     1.00},
    {"green_cap",     0.33},
    {"green_cap",     0.33},
})

local brain = require("brains/toadstoolbrain")

--------------------------------------------------------------------------

local function FindSporeBombTargets(inst, preferredtargets)
    local targets = {}

    if preferredtargets ~= nil then
        for i, v in ipairs(preferredtargets) do
            if v:IsValid() and v.entity:IsVisible() and
                v.components.debuffable ~= nil and
                v.components.debuffable:IsEnabled() and
                not v.components.debuffable:HasDebuff("sporebomb") and
                not (v.components.health ~= nil and
                    v.components.health:IsDead()) and
                v:IsNear(inst, TUNING.TOADSTOOL_SPOREBOMB_HIT_RANGE) then
                table.insert(targets, v)
                if #targets >= inst.sporebomb_targets then
                    return targets
                end
            end
        end
    end

    local newtargets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.TOADSTOOL_SPOREBOMB_ATTACK_RANGE, { "debuffable" }, { "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO" })
    for i, v in ipairs(ents) do
        if v.entity:IsVisible() and
            v.components.debuffable ~= nil and
            not v.components.debuffable:HasDebuff("sporebomb") and
            not (v.components.health ~= nil and
                v.components.health:IsDead()) then
            table.insert(newtargets, v)
        end
    end

    for i = #targets + 1, inst.sporebomb_targets do
        if #newtargets <= 0 then
            return targets
        end
        table.insert(targets, table.remove(newtargets, math.random(#newtargets)))
    end

    return targets
end

local function DoSporeBomb(inst, targets)
    for i, v in ipairs(FindSporeBombTargets(inst, targets)) do
        v.components.debuffable:AddDebuff("sporebomb", "sporebomb")
    end
end

--------------------------------------------------------------------------

local function FindMushroomBombTargets(inst)
    --ring with a random gap
    local maxbombs = inst.mushroombomb_variance > 0 and inst.mushroombomb_count + math.random(inst.mushroombomb_variance) or inst.mushroombomb_count
    local delta = (1 + math.random()) * PI / maxbombs
    local offset = 2 * PI * math.random()
    local angles = {}
    for i = 1, maxbombs do
        table.insert(angles, i * delta + offset)
    end

    local pt = inst:GetPosition()
    local range = GetRandomMinMax(TUNING.TOADSTOOL_MUSHROOMBOMB_MIN_RANGE, TUNING.TOADSTOOL_MUSHROOMBOMB_MAX_RANGE)
    local targets = {}
    while #angles > 0 do
        local theta = table.remove(angles, math.random(#angles))
        local offset = FindWalkableOffset(pt, theta, range, 12, true)
        if offset ~= nil then
            offset.x = offset.x + pt.x
            offset.y = 0
            offset.z = offset.z + pt.z
            table.insert(targets, offset)
        end
    end

    return targets
end

local function SpawnMushroomBombProjectile(inst, targets)
    local x, y, z = inst.Transform:GetWorldPosition()
    local projectile = SpawnPrefab("mushroombomb_projectile")
    projectile.Transform:SetPosition(x, y, z)
    projectile.components.entitytracker:TrackEntity("toadstool", inst)

    --V2C: scale the launch speed based on distance
    --     because 15 does not reach our max range.
    local targetpos = table.remove(targets, 1)
    local dx = targetpos.x - x
    local dz = targetpos.z - z
    local rangesq = dx * dx + dz * dz
    local maxrange = 15
    local bigNum = 15 -- 13 + (math.random()*4)
    local speed = easing.linear(rangesq, bigNum, 3, maxrange * maxrange)
    projectile.components.complexprojectile:SetHorizontalSpeed(speed)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)

    if #targets > 0 then
        inst:DoTaskInTime(FRAMES, SpawnMushroomBombProjectile, targets)
    end
end

local function DoMushroomBomb(inst)
    local targets = FindMushroomBombTargets(inst)
    if #targets > 0 then
        inst:DoTaskInTime(FRAMES, SpawnMushroomBombProjectile, targets)
    end
end

--------------------------------------------------------------------------

local function FindMushroomSproutAngles(inst)
    --evenly spaced ring
    local maxspawns = TUNING.TOADSTOOL_MUSHROOMSPROUT_NUM
    local delta = 2 * PI / maxspawns
    local offset = 2 * PI * math.random()
    local angles = {}
    for i = 1, maxspawns do
        table.insert(angles, i * delta + offset)
    end
    return angles
end

local function DoMushroomSprout(inst, angles)
    if angles == nil or #angles <= 0 then
        return
    end

    local map = TheWorld.Map
    local pt = inst:GetPosition()
    local theta = table.remove(angles, math.random(#angles))
    local radius = GetRandomMinMax(TUNING.TOADSTOOL_MUSHROOMSPROUT_MIN_RANGE, TUNING.TOADSTOOL_MUSHROOMSPROUT_MAX_RANGE)
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    pt.y = 0

    --number of attempts to find an unblocked spawn point
    for i = 1, 10 do
        if i > 1 then
            offset = FindWalkableOffset(pt, 2 * PI * math.random(), 2.5, 8, true)
        end
        if offset ~= nil then
            pt.x = pt.x + offset.x
            pt.z = pt.z + offset.z
            if map:CanDeployAtPoint(pt, inst) then --inst is dummy param cuz we can't pass nil
                local ent = SpawnPrefab("mushroomsprout")
                ent.Transform:SetPosition(pt:Get())
                ent:PushEvent("linktoadstool", inst)
                break
            end
        end
    end
end

--------------------------------------------------------------------------

local function SetLevel(inst, level)
    inst.level = level
    if level < 1 then
        inst.AnimState:ClearOverrideSymbol("toad_mushroom")
        inst.components.locomotor.walkspeed = TUNING.TOADSTOOL_SPEED
        inst.components.combat:SetDefaultDamage(TUNING.TOADSTOOL_DAMAGE)
        inst.components.combat:SetAttackPeriod(TUNING.TOADSTOOL_ATTACK_PERIOD)
        inst.mushroombomb_variance = 0
        inst.mushroombomb_maxchain = 1
    else
        inst.AnimState:OverrideSymbol("toad_mushroom", "toadstool_upg_build", "toad_mushroom"..tostring(level))
        if level == 1 then
            inst.components.locomotor.walkspeed = TUNING.TOADSTOOL_UPG1_SPEED
            inst.components.combat:SetDefaultDamage(TUNING.TOADSTOOL_UPG1_DAMAGE)
            inst.components.combat:SetAttackPeriod(TUNING.TOADSTOOL_UPG1_ATTACK_PERIOD)
            inst.mushroombomb_variance = 1
            inst.mushroombomb_maxchain = 2
        elseif level == 2 then
            inst.components.locomotor.walkspeed = TUNING.TOADSTOOL_UPG2_SPEED
            inst.components.combat:SetDefaultDamage(TUNING.TOADSTOOL_UPG2_DAMAGE)
            inst.components.combat:SetAttackPeriod(TUNING.TOADSTOOL_UPG2_ATTACK_PERIOD)
            inst.mushroombomb_variance = 2
            inst.mushroombomb_maxchain = 3
        else
            inst.components.locomotor.walkspeed = TUNING.TOADSTOOL_UPG3_SPEED
            inst.components.combat:SetDefaultDamage(TUNING.TOADSTOOL_UPG3_DAMAGE)
            inst.components.combat:SetAttackPeriod(TUNING.TOADSTOOL_UPG3_ATTACK_PERIOD)
            inst.mushroombomb_variance = 3
            inst.mushroombomb_maxchain = 5
        end
    end
    inst:PushEvent("toadstoollevel", level)
end

local function CalculateLevel(links)
    return (links < 1 and 0)
        or (links < 5 and 1)
        or (links < 8 and 2)
        or 3
end

local function OnUnlinkMushroomSprout(inst, link)
    if inst._links[link] ~= nil then
        inst:RemoveEventCallback("onremove", inst._links[link], link)
        inst._links[link] = nil
        inst._numlinks = inst._numlinks - 1
        SetLevel(inst, CalculateLevel(inst._numlinks))
    end
end

local function OnLinkMushroomSprout(inst, link)
    if inst._links[link] == nil then
        inst._numlinks = inst._numlinks + 1
        inst._links[link] = function(link) OnUnlinkMushroomSprout(inst, link) end
        inst:ListenForEvent("onremove", inst._links[link], link)
        SetLevel(inst, CalculateLevel(inst._numlinks))
    end
end

--------------------------------------------------------------------------

local function UpdatePlayerTargets(inst)
    local toadd = {}
    local toremove = {}
    local pos = inst.components.knownlocations:GetLocation("spawnpoint")

    for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
        toremove[k] = true
    end
    for i, v in ipairs(FindPlayersInRange(pos.x, pos.y, pos.z, TUNING.TOADSTOOL_DEAGGRO_DIST, true)) do
        if toremove[v] then
            toremove[v] = nil
        else
            table.insert(toadd, v)
        end
    end

    for k, v in pairs(toremove) do
        inst.components.grouptargeter:RemoveTarget(k)
    end
    for i, v in ipairs(toadd) do
        inst.components.grouptargeter:AddTarget(v)
    end
end

local function RetargetFn(inst)
    UpdatePlayerTargets(inst)

    local player = inst.components.grouptargeter:TryGetNewTarget()
    if player ~= nil then
        return player, true
    end

    --Also needs to deal with other creatures in the world
    local spawnpoint = inst.components.knownlocations:GetLocation("spawnpoint")
    local deaggro_dist_sq = TUNING.TOADSTOOL_DEAGGRO_DIST * TUNING.TOADSTOOL_DEAGGRO_DIST
    return FindEntity(
        inst,
        TUNING.TOADSTOOL_AGGRO_DIST,
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and guy:GetDistanceSqToPoint(spawnpoint) < deaggro_dist_sq
        end,
        { "_combat" }, --see entityreplica.lua
        { "prey", "smallcreature" }
    )
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
        and target:GetDistanceSqToPoint(inst.components.knownlocations:GetLocation("spawnpoint")) < TUNING.TOADSTOOL_DEAGGRO_DIST * TUNING.TOADSTOOL_DEAGGRO_DIST
end

local function OnNewTarget(inst, data)
    if data.target ~= nil and inst.components.timer:IsPaused("flee") then
        inst.components.timer:ResumeTimer("flee")
        inst.components.timer:StartTimer("fleewarning", inst.components.timer:GetTimeLeft("flee") - TUNING.TOADSTOOL_FLEE_WARNING)
        --Ability first use timers 
        inst.components.timer:StartTimer("sporebomb_cd", TUNING.TOADSTOOL_ABILITY_INTRO_CD)
        --inst.components.timer:StartTimer("mushroombomb_cd", inst.mushroombomb_cd)
        inst.components.timer:StartTimer("mushroomsprout_cd", inst.mushroomsprout_cd)
        inst.components.timer:StartTimer("pound_cd", TUNING.TOADSTOOL_ABILITY_INTRO_CD, true)
    end
end

local function AnnounceWarning(inst, player)
    if player:IsValid() and player.entity:IsVisible() and
        not (player.components.health ~= nil and player.components.health:IsDead()) and
        not player:HasTag("playerghost") and
        not (inst.sg:HasStateTag("noattack") or inst.components.health:IsDead()) then
        player:PushEvent("toadstoolwarning", { escaped = false })
    end
end

local function OnTimerDone(inst, data)
    if data.name == "fleewarning" and not (inst.sg:HasStateTag("noattack") or inst.components.health:IsDead()) then
        --Toadstool escaping soon, announce to all live players in range
        --Must re-validate Toadstool state
        local x, y, z = inst.Transform:GetWorldPosition()
        local players = FindPlayersInRange(x, y, z, 15)
        for i, v in ipairs(players) do
            inst:DoTaskInTime(math.random() * 2, AnnounceWarning, v)
        end
    end
end

local function AnnounceEscaped(player)
    if player:IsValid() and player.entity:IsVisible() and
        not (player.components.health ~= nil and player.components.health:IsDead()) and
        not player:HasTag("playerghost") then
        player:PushEvent("toadstoolwarning", { escaped = true })
    end
end

local function OnEscaped(inst)
    --Toadstool escaped, announce to all live players in range
    --Don't validate Toadstool state
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 15)
    for i, v in ipairs(players) do
        v:DoTaskInTime(math.random(), AnnounceEscaped)
    end

    inst:Remove()
end

--------------------------------------------------------------------------

local PHASE2_HEALTH = .7
local PHASE3_HEALTH = .4

local function EnterPhase2Trigger(inst)
    if not POPULATING then
        inst:PushEvent("roar")
    end
    inst.sporebomb_targets = 2
    inst.sporebomb_cd = TUNING.TOADSTOOL_SPOREBOMB_CD_PHASE2
    inst.mushroombomb_count = 5
end

local function EnterPhase3Trigger(inst)
    if not POPULATING then
        inst:PushEvent("roar")
    end
    inst.sporebomb_targets = 2
    inst.sporebomb_cd = TUNING.TOADSTOOL_SPOREBOMB_CD_PHASE2
    inst.mushroombomb_count = 6
    inst.components.timer:ResumeTimer("pound_cd")
end

local function OnLoad(inst)
    local healthpct = inst.components.health:GetPercent()
    if healthpct <= PHASE3_HEALTH then
        EnterPhase3Trigger(inst)
    elseif healthpct <= PHASE2_HEALTH then
        EnterPhase2Trigger(inst)
    end
end

--------------------------------------------------------------------------

local function ClearRecentlyCharged(inst, other)
    inst.recentlycharged[other] = nil
end

local function OnDestroyOther(inst, other)
    if other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET and
        not inst.recentlycharged[other] then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        if other.components.lootdropper ~= nil and (other:HasTag("tree") or other:HasTag("boulder")) then
            other.components.lootdropper:SetLoot({})
        end
        other.components.workable:Destroy(inst)
        if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
            inst.recentlycharged[other] = true
            inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        end
    end
end

local function OnCollide(inst, other)
    if other ~= nil and
        other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET and
        Vector3(inst.Physics:GetVelocity()):LengthSq() >= 1 and
        not inst.recentlycharged[other] then
        inst:DoTaskInTime(2 * FRAMES, OnDestroyOther, other)
    end
end

--------------------------------------------------------------------------

local function getstatus(inst)
    return inst.level >= 3  and "RAGE" or nil
end

local function PushMusic(inst)
    if ThePlayer ~= nil and ThePlayer:IsNear(inst, 30) then
        ThePlayer:PushEvent("triggeredevent")
    end
end

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()

    inst.DynamicShadow:SetSize(6, 3.5)

    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(.5)
    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(255 / 255, 235 / 255, 153 / 255)

    MakeGiantCharacterPhysics(inst, 1000, 2.5)

    inst.AnimState:SetBank("toadstool")
    inst.AnimState:SetBuild("toadstool_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetLightOverride(.3)

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")

    inst:DoPeriodicTask(1, PushMusic, 0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.recentlycharged = {}
    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus
    inst.components.inspectable:RecordViews()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("toadstool")
    AddSpecialLoot(inst)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.TOADSTOOL_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.TOADSTOOL_HEALTH)
    inst.components.health.destroytime = 5

    inst:AddComponent("healthtrigger")
    inst.components.healthtrigger:AddTrigger(PHASE2_HEALTH, EnterPhase2Trigger)
    inst.components.healthtrigger:AddTrigger(PHASE3_HEALTH, EnterPhase3Trigger)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.TOADSTOOL_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.TOADSTOOL_ATTACK_PERIOD)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetRange(TUNING.TOADSTOOL_ATTACK_RANGE)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.battlecryenabled = false
    inst.components.combat.hiteffectsymbol = "toad_torso"

    inst:AddComponent("epicscare")
    inst.components.epicscare:SetRange(TUNING.TOADSTOOL_EPICSCARE_RANGE)

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("flee", TUNING.TOADSTOOL_FLEE_TIME, true)

    inst:AddComponent("grouptargeter")
    inst:AddComponent("groundpounder")
    inst:AddComponent("knownlocations")

    MakeLargeBurnableCharacter(inst, "swap_fire")
    MakeHugeFreezableCharacter(inst, "toad_torso")

    inst:SetStateGraph("SGtoadstool")
    inst:SetBrain(brain)

    inst.FindSporeBombTargets = FindSporeBombTargets
    inst.DoSporeBomb = DoSporeBomb
    inst.DoMushroomBomb = DoMushroomBomb
    inst.FindMushroomSproutAngles = FindMushroomSproutAngles
    inst.DoMushroomSprout = DoMushroomSprout
    inst.OnEscaped = OnEscaped

    inst.sporebomb_targets = 1
    inst.sporebomb_cd = TUNING.TOADSTOOL_SPOREBOMB_CD_PHASE1

    inst.mushroombomb_count = 4
    inst.mushroombomb_variance = 0
    inst.mushroombomb_maxchain = 1
    inst.mushroombomb_cd = TUNING.TOADSTOOL_MUSHROOMBOMB_CD

    inst.mushroomsprout_cd = TUNING.TOADSTOOL_MUSHROOMSPROUT_CD

    inst.pound_cd = TUNING.TOADSTOOL_POUND_CD

    inst.level = 0
    inst._numlinks = 0
    inst._links = {}
    inst:ListenForEvent("linkmushroomsprout", OnLinkMushroomSprout)
    inst:ListenForEvent("unlinkmushroomsprout", OnUnlinkMushroomSprout)

    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst.OnLoad = OnLoad

    return inst
end

return Prefab("toadstool", fn, assets, prefabs)
