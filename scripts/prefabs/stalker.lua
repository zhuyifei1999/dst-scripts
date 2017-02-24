local assets =
{
    Asset("ANIM", "anim/stalker_basic.zip"),
    Asset("ANIM", "anim/stalker_action.zip"),
    Asset("ANIM", "anim/stalker_shadow_build.zip"),
    Asset("ANIM", "anim/stalker_cave_build.zip"),
}

local prefabs =
{
    "shadowheart",
    "fossil_piece_clean",
    "fossilspike",
}

local brain = require("brains/stalkerbrain")

SetSharedLootTable('stalker',
{
    {"shadowheart",         1.00},
    {"fossil_piece_clean",  1.00},
    {"fossil_piece_clean",  1.00},
    {"fossil_piece_clean",  1.00},
    {"fossil_piece_clean",  1.00},
    {"fossil_piece_clean",  1.00},
    {"fossil_piece_clean",  1.00},
    {"fossil_piece_clean",  1.00},
    {"fossil_piece_clean",  1.00},
    {"nightmarefuel",       1.00},
    {"nightmarefuel",       1.00},
    {"nightmarefuel",       0.50},
    {"nightmarefuel",       0.50},
})

--------------------------------------------------------------------------

local function OnDoneTalking(inst)
    if inst.talktask ~= nil then
        inst.talktask:Cancel()
        inst.talktask = nil
    end
    --inst.SoundEmitter:KillSound("talk")
end

local function OnTalk(inst)
    OnDoneTalking(inst)
    --inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/talk_LP", "talk")
    inst.talktask = inst:DoTaskInTime(1.5 + math.random() * .5, OnDoneTalking)
end

--------------------------------------------------------------------------

local function UpdatePlayerTargets(inst)
    local toadd = {}
    local toremove = {}
    local x, y, z = inst.Transform:GetWorldPosition()

    for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
        toremove[k] = true
    end
    for i, v in ipairs(FindPlayersInRange(x, y, z, TUNING.STALKER_DEAGGRO_DIST, true)) do
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

--Stalker switches aggro off players easily
local function RetargetFn(inst)
    UpdatePlayerTargets(inst)

    local target = inst.components.combat.target
    local targetdistsq, x, y, z
    local hasplayer = false
    local inrange = false
    if target ~= nil then
        local range = target.Physics ~= nil and TUNING.STALKER_ATTACK_RANGE + target.Physics:GetRadius() or TUNING.STALKER_ATTACK_RANGE        
        x, y, z = inst.Transform:GetWorldPosition()
        targetdistsq = target:GetDistanceSqToPoint(x, y, z)
        inrange = targetdistsq < range * range
        hasplayer = target:HasTag("player")

        if hasplayer then
            local newplayer = inst.components.grouptargeter:TryGetNewTarget()
            if newplayer ~= nil and
                newplayer:IsNear(
                    inst,
                    (not inrange and TUNING.STALKER_KEEP_AGGRO_DIST) or
                    (newplayer.Physics ~= nil and TUNING.STALKER_ATTACK_RANGE + newplayer.Physics:GetRadius()) or
                    TUNING.STALKER_ATTACK_RANGE
                ) then
                return newplayer, true
            elseif inrange or targetdistsq < TUNING.STALKER_KEEP_AGGRO_DIST * TUNING.STALKER_KEEP_AGGRO_DIST then
                return
            end
        end
    end

    if not hasplayer then
        local nearplayers = {}
        for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
            if inst:IsNear(k,
                (not inrange and TUNING.STALKER_AGGRO_DIST) or
                (k.Physics ~= nil and TUNING.STALKER_ATTACK_RANGE + k.Physics:GetRadius()) or
                TUNING.STALKER_ATTACK_RANGE) then
                table.insert(nearplayers, k)
            end
        end
        if #nearplayers > 0 then
            return nearplayers[math.random(#nearplayers)], true
        end
    end

    --Also needs to deal with other creatures in the world
    local creature = FindEntity(
        inst,
        TUNING.STALKER_AGGRO_DIST,
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and (   guy.components.combat:TargetIs(inst) or
                        guy:IsNear(inst, TUNING.STALKER_KEEP_AGGRO_DIST)
                    )
        end,
        { "_combat" }, --see entityreplica.lua
        { "INLIMBO", "prey", "companion", "smallcreature" }
    )

    return creature ~= nil
        and (target == nil or creature:GetDistanceSqToPoint(x, y, z) < targetdistsq)
        and creature
        or nil,
        true
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
        and inst:IsNear(target, TUNING.STALKER_DEAGGRO_DIST)
end

local function OnAttacked(inst, data)
    if data.attacker ~= nil then
        local target = inst.components.combat.target
        if not (target ~= nil and
                target:HasTag("player") and
                target:IsNear(inst, target.Physics ~= nil and TUNING.STALKER_ATTACK_RANGE + target.Physics:GetRadius() or TUNING.STALKER_ATTACK_RANGE)) then
            inst.components.combat:SetTarget(data.attacker)
        end
    end
end

--------------------------------------------------------------------------

local PHASE2_HEALTH = .75

local function EnterPhase2Trigger(inst)
    inst.components.timer:ResumeTimer("snare_cd")
    inst:PushEvent("roar")
end

local function OnNewTarget(inst, data)
    if data.target ~= nil then
        inst:SetEngaged(true)
    end
end

local function SetEngaged(inst, engaged)
    --NOTE: inst.engaged is nil at instantiation, and engaged must not be nil
    if inst.engaged ~= engaged then
        inst.engaged = engaged
        inst.components.timer:StopTimer("snare_cd")
        if engaged then
            if inst.components.health:GetPercent() > PHASE2_HEALTH then
                inst.components.timer:StartTimer("snare_cd", FRAMES, true)
            else
                inst.components.timer:StartTimer("snare_cd", TUNING.STALKER_FIRST_SNARE_CD)
            end
            inst:RemoveEventCallback("newcombattarget", OnNewTarget)
        else
            inst:ListenForEvent("newcombattarget", OnNewTarget)
        end
    end
end

local function battlecry(combat, target)
    local strtbl =
        target ~= nil and
        target:HasTag("player") and
        "STALKER_PLAYER_BATTLECRY" or
        "STALKER_BATTLECRY"
    return strtbl, math.random(#STRINGS[strtbl])
end

--------------------------------------------------------------------------

local SNARE_OVERLAP_MIN = 1
local SNARE_OVERLAP_MAX = 3
local function NoSnareOverlap(x, z, r)
    return #TheSim:FindEntities(x, 0, z, r or SNARE_OVERLAP_MIN, { "fossilspike" }) <= 0
end

--Hard limit target list size since casting does multiple passes it
local SNARE_MAX_TARGETS = 20
local SNARE_TAGS = { "_combat", "locomotor" }
local SNARE_NO_TAGS = { "flying", "ghost", "playerghost", "shadowcreature", "tallbird", "shadow", "shadowminion", "INLIMBO", "epic", "smallcreature" }
local function FindSnareTargets(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = {}
    local priorityindex = 1
    local priorityindex2 = 1
    local ents = TheSim:FindEntities(x, y, z, TUNING.STALKER_SNARE_RANGE, SNARE_TAGS, SNARE_NO_TAGS)
    for i, v in ipairs(ents) do
        if not (v.components.health ~= nil and v.components.health:IsDead()) then
            if v:HasTag("player") then
                table.insert(targets, priorityindex, v)
                priorityindex = priorityindex + 1
                priorityindex2 = priorityindex2 + 1
            elseif v.components.combat:TargetIs(inst) then
                table.insert(targets, priorityindex2, v)
                priorityindex2 = priorityindex2 + 1
            else
                table.insert(targets, v)
            end
            if #targets >= SNARE_MAX_TARGETS then
                return targets
            end
        end
    end
    return #targets > 0 and targets or nil
end

local function SpawnSnare(inst, x, z, r, num, target)
    local vars = { 1, 2, 3, 4, 5, 6, 7 }
    local used = {}
    local queued = {}
    local count = 0
    local dtheta = PI * 2 / num
    local thetaoffset = math.random() * PI * 2
    local delaytoggle = 0
    local map = TheWorld.Map
    for theta = math.random() * dtheta, PI * 2, dtheta do
        local x1 = x + r * math.cos(theta)
        local z1 = z + r * math.sin(theta)
        if map:IsPassableAtPoint(x1, 0, z1) then
            local spike = SpawnPrefab("fossilspike")
            spike.Transform:SetPosition(x1, 0, z1)

            local delay = delaytoggle == 0 and 0 or .2 + delaytoggle * math.random() * .2
            delaytoggle = delaytoggle == 1 and -1 or 1

            local duration = GetRandomWithVariance(TUNING.STALKER_SNARE_TIME, TUNING.STALKER_SNARE_TIME_VARIANCE)

            local variation = table.remove(vars, math.random(#vars))
            table.insert(used, variation)
            if #used > 3 then
                table.insert(queued, table.remove(used, 1))
            end
            if #vars <= 0 then
                local swap = vars
                vars = queued
                queued = vars
            end

            spike:RestartSpike(delay, duration, variation)
            count = count + 1
        end
    end
    if count <= 0 then
        return false
    elseif target:IsValid() then
        target:PushEvent("snared", { attacker = inst })
    end
    return true
end

local function SpawnSnares(inst, targets)
    local count = 0
    local nextpass = {}
    for i, v in ipairs(targets) do
        if v:IsValid() and v:IsNear(inst, TUNING.STALKER_SNARE_MAX_RANGE) then
            local x, y, z = v.Transform:GetWorldPosition()
            local islarge = v:HasTag("largecreature")
            local r = (v.Physics ~= nil and v.Physics:GetRadius() or 0) + (islarge and 1.5 or .5)
            local num = islarge and 12 or 6
            if NoSnareOverlap(x, z, r + SNARE_OVERLAP_MAX) then
                if SpawnSnare(inst, x, z, r, num, v) then
                    count = count + 1
                    if count >= TUNING.STALKER_MAX_SNARES then
                        return
                    end
                end
            else
                table.insert(nextpass, { x = x, z = z, r = r, n = num, inst = v })
            end
        end
    end
    if #nextpass <= 0 then
        return
    end
    for range = SNARE_OVERLAP_MAX - 1, SNARE_OVERLAP_MIN, -1 do
        local i = 1
        while i <= #nextpass do
            local v = nextpass[i]
            if NoSnareOverlap(v.x, v.z, v.r + range) then
                if SpawnSnare(inst, v.x, v.z, v.r, v.n, v.inst) then
                    count = count + 1
                    if count >= TUNING.STALKER_MAX_SNARES or #nextpass <= 1 then
                        return
                    end
                end
                table.remove(nextpass, i)
            else
                i = i + 1
            end
        end
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
        other.components.workable.action ~= ACTIONS.DIG and
        other.components.workable.action ~= ACTIONS.NET and
        not inst.recentlycharged[other] then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
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
        other.components.workable.action ~= ACTIONS.DIG and
        other.components.workable.action ~= ACTIONS.NET and
        not inst.recentlycharged[other] then
        inst:DoTaskInTime(2 * FRAMES, OnDestroyOther, other)
    end
end

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.DynamicShadow:SetSize(4, 2)

    MakeGiantCharacterPhysics(inst, 1000, .75)

    inst.AnimState:SetBank("stalker")
    inst.AnimState:SetBuild("stalker_shadow_build")
    inst.AnimState:AddOverrideBuild("stalker_cave_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("stalker")
    inst:AddTag("shadowancient")

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 40
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(238 / 255, 69 / 255, 105 / 255)
    inst.components.talker.offset = Vector3(0, -700, 0)
    inst.components.talker.symbol = "fossil_chest"
    inst.components.talker:MakeChatter()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.recentlycharged = {}
    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("stalker")

    inst:AddComponent("locomotor")
    inst.components.locomotor.pathcaps = { ignorewalls = true }
    inst.components.locomotor.walkspeed = TUNING.STALKER_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.STALKER_HEALTH)
    inst.components.health.nofadeout = true

    inst:AddComponent("healthtrigger")
    inst.components.healthtrigger:AddTrigger(PHASE2_HEALTH, EnterPhase2Trigger)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.STALKER_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.STALKER_ATTACK_PERIOD)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetRange(TUNING.STALKER_ATTACK_RANGE, TUNING.STALKER_HIT_RANGE)
    inst.components.combat:SetAreaDamage(TUNING.STALKER_AOE_RANGE, TUNING.STALKER_AOE_SCALE)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat.battlecryinterval = 10
    inst.components.combat.GetBattleCryString = battlecry
    inst.components.combat:SetHurtSound("dontstarve/creatures/together/stalker/hit")

    inst:AddComponent("grouptargeter")

    inst:AddComponent("timer")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE

    inst:AddComponent("epicscare")
    inst.components.epicscare:SetRange(TUNING.STALKER_EPICSCARE_RANGE)

    inst:SetStateGraph("SGstalker")
    inst:SetBrain(brain)

    inst.SetEngaged = SetEngaged
    inst.FindSnareTargets = FindSnareTargets
    inst.SpawnSnares = SpawnSnares

    inst:ListenForEvent("ontalk", OnTalk)
    inst:ListenForEvent("donetalking", OnDoneTalking)
    inst:ListenForEvent("attacked", OnAttacked)
    SetEngaged(inst, false)

    return inst
end

return Prefab("stalker", fn, assets, prefabs)
