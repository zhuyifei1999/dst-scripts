local assets =
{
	Asset("ANIM", "anim/rook.zip"),
	Asset("ANIM", "anim/rook_build.zip"),
	Asset("ANIM", "anim/rook_nightmare.zip"),
	Asset("SOUND", "sound/chess.fsb"),
}

local prefabs =
{
	"gears",
    "thulecite_pieces",
    "nightmarefuel",
}

local brain = require "brains/rookbrain"

SetSharedLootTable( 'rook',
{
    {'gears',  1.0},
    {'gears',  1.0},
})

SetSharedLootTable( 'rook_nightmare',
{
    {'gears',            1.0},
    {'nightmarefuel',    0.6},
    {'thulecite_pieces', 0.5},
})

local SLEEP_DIST_FROMHOME = 1
local SLEEP_DIST_FROMTHREAT = 20
local MAX_CHASEAWAY_DIST = 40
local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40

local function ShouldSleep(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = Vector3(inst.Transform:GetWorldPosition() )
    if not (homePos and distsq(homePos, myPos) <= SLEEP_DIST_FROMHOME*SLEEP_DIST_FROMHOME)
       or (inst.components.combat and inst.components.combat.target)
       or (inst.components.burnable and inst.components.burnable:IsBurning() )
       or (inst.components.freezable and inst.components.freezable:IsFrozen() ) then
        return false
    end
    local nearestEnt = GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT)
    return nearestEnt == nil
end

local function ShouldWake(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = Vector3(inst.Transform:GetWorldPosition() )
    if (homePos and distsq(homePos, myPos) > SLEEP_DIST_FROMHOME*SLEEP_DIST_FROMHOME)
       or (inst.components.combat and inst.components.combat.target)
       or (inst.components.burnable and inst.components.burnable:IsBurning() )
       or (inst.components.freezable and inst.components.freezable:IsFrozen() ) then
        return true
    end
    local nearestEnt = GetClosestInstWithTag("character", inst, SLEEP_DIST_FROMTHREAT)
    return nearestEnt
end

local function Retarget(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = Vector3(inst.Transform:GetWorldPosition() )
    if (homePos and distsq(homePos, myPos) > 40*40)  and not
    (inst.components.follower and inst.components.follower.leader)then
        return
    end
    
    local newtarget = FindEntity(inst, TUNING.ROOK_TARGET_DIST, function(guy)
			local myLeader = inst.components.follower and inst.components.follower.leader
			local theirLeader = guy.components.follower and guy.components.follower.leader
			local bothFollowingSamePlayer = myLeader and (myLeader == theirLeader) and myLeader:HasTag("player")
            return not (inst.components.follower and inst.components.follower.leader == guy)
                   and not (guy:HasTag("chess") and (guy.components.follower and not guy.components.follower.leader))
                   and not bothFollowingSamePlayer
                   and inst.components.combat:CanTarget(guy)
    end,
    nil,
    nil,
    {"character","monster"}
    )
    return newtarget
end

local function KeepTarget(inst, target)

    if (inst.components.follower and inst.components.follower.leader) then
        return true
    end

    if inst.sg and inst.sg:HasStateTag("running") then
        return true
    end

    local homePos = inst.components.knownlocations:GetLocation("home")
    local myPos = Vector3(inst.Transform:GetWorldPosition() )
    return (homePos and distsq(homePos, myPos) < 40*40)
end

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    if attacker and attacker:HasTag("chess") then return end
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("chess") end, MAX_TARGET_SHARES)
end

local function ClearRecentlyCharged(inst, target)
    inst.recentlycharged[target] = nil
end

local function DoChargeDamage(inst, target)
    if not inst.recentlycharged then
        inst.recentlycharged = {}
    end

    for k,v in pairs(inst.recentlycharged) do
        if v == target then
            --You've already done damage to this by charging it recently.
            return
        end
    end
    inst.recentlycharged[target] = target
    inst:DoTaskInTime(3, ClearRecentlyCharged, target)
    inst.components.combat:DoAttack(target, inst.weapon)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/rook/explo") 
end

local function onothercollide(inst, other)
    if other == nil then
        return
    elseif other:HasTag("smashable") then
        --other.Physics:SetCollides(false)
        other.components.health:Kill()
    elseif other.components.workable ~= nil and other.components.workable.workleft > 0 then
        SpawnPrefab("collapse_small").Transform:SetPosition(other:GetPosition():Get())
        other.components.workable:Destroy(inst)
    elseif other.components.health ~= nil and other.components.health:GetPercent() >= 0 then
        DoChargeDamage(inst, other)
    end
end

local function oncollide(inst, other)
    if other:HasTag("player") then
        return
    end
    local v1 = Vector3(inst.Physics:GetVelocity())
    if v1:LengthSq() < 42 then
        return
    end

    for i, v in ipairs(AllPlayers) do
        v:ShakeCamera(CAMERASHAKE.SIDE, .5, .05, .1, inst, 40)
    end

    inst:DoTaskInTime(2*FRAMES, onothercollide, other)
end

local function CreateWeapon(inst)
    local weapon = CreateEntity()
    --[[Non-networked entity]]
    weapon.entity:AddTransform()
    weapon:AddComponent("weapon")
    weapon.components.weapon:SetDamage(200)
    weapon.components.weapon:SetRange(0)
    weapon:AddComponent("inventoryitem")
    weapon.persists = false
    weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
    weapon:AddComponent("equippable")
    inst.components.inventory:GiveItem(weapon)
    inst.weapon = weapon
end

local function RememberKnownLocation(inst)
    inst.components.knownlocations:RememberLocation("home", Vector3(inst.Transform:GetWorldPosition()))
end

local function common_fn(build)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, 1.5)

    inst.DynamicShadow:SetSize(3, 1.25)
    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(0.66, 0.66, 0.66)

    inst.AnimState:SetBank("rook")
    inst.AnimState:SetBuild(build)

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("chess")
    inst:AddTag("rook")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.Physics:SetCollisionCallback(oncollide)

    inst:AddComponent("lootdropper")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.ROOK_WALK_SPEED
    inst.components.locomotor.runspeed =  TUNING.ROOK_RUN_SPEED

    inst:SetStateGraph("SGrook")
    inst:SetBrain(brain)
    
    inst:AddComponent("sleeper")
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetResistance(3)

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "spring"
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst.components.health:SetMaxHealth(TUNING.ROOK_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.ROOK_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.ROOK_ATTACK_PERIOD)
    --inst.components.combat.playerdamagepercent = 2

    inst:AddComponent("follower")

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    MakeHauntablePanic(inst)

    inst:DoTaskInTime(2*FRAMES, RememberKnownLocation)

    MakeMediumBurnableCharacter(inst, "spring")
    MakeMediumFreezableCharacter(inst, "spring")

    inst:ListenForEvent("attacked", OnAttacked)

    CreateWeapon(inst)

    --inst:AddComponent("debugger")

    return inst
end

local function rook_fn()
    local inst = common_fn("rook_build")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('rook')

    inst.kind = ""
    inst.soundpath = "dontstarve/creatures/rook/"
    inst.effortsound = "dontstarve/creatures/rook/steam"

    return inst
end

local function rook_nightmare_fn()
    local inst = common_fn("rook_nightmare")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('rook_nightmare')

    inst.kind = "_nightmare"
    inst.soundpath = "dontstarve/creatures/rook_nightmare/"
    inst.effortsound = "dontstarve/creatures/rook_nightmare/rattle"
    --TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.soundpath .. "steam") end ),

    return inst
end

return Prefab("chessboard/rook", rook_fn, assets, prefabs),
       Prefab("cave/monsters/rook_nightmare", rook_nightmare_fn, assets, prefabs)