local assets =
{
    Asset("ANIM", "anim/horn.zip"),
}

local function FollowLeader(follower, leader)
    follower.sg:PushEvent("heardhorn", { musician = leader })
end

local function TryAddFollower(leader, follower)
    if leader.components.leader
       and follower.components.follower
       and follower:HasTag("beefalo") and not follower:HasTag("baby")
       and leader.components.leader:CountFollowers("beefalo") < TUNING.HORN_MAX_FOLLOWERS then
        leader.components.leader:AddFollower(follower)
        follower.components.follower:AddLoyaltyTime(TUNING.HORN_EFFECTIVE_TIME+math.random())
        if follower.components.combat and follower.components.combat.target and follower.components.combat.target == leader then
            follower.components.combat:SetTarget(nil)
        end
        follower:DoTaskInTime(math.random(), FollowLeader, leader)
    end
end

local function HearHorn(inst, musician, instrument)
    if musician.components.leader then
        local herd = nil
        if inst:HasTag("beefalo") and not inst:HasTag("baby") and inst.components.herdmember then
            if inst.components.combat and inst.components.combat.target then
                inst.components.combat:GiveUp()
            end
            TryAddFollower(musician, inst)
            herd = inst.components.herdmember:GetHerd()
        end
        if herd and herd.components.herd then
            for k,v in pairs(herd.components.herd.members) do
                TryAddFollower(musician, k)
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)

    inst:AddTag("horn")

    inst.AnimState:SetBank("horn")
    inst.AnimState:SetBuild("horn")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("instrument")
    inst.components.instrument.range = TUNING.HORN_RANGE
    inst.components.instrument:SetOnHeardFn(HearHorn)
    
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.PLAY)
    
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.HORN_USES)
    inst.components.finiteuses:SetUses(TUNING.HORN_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)
        
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_HALF then
            if inst.components.finiteuses then
                inst.components.finiteuses:Use(1)
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
                return true
            end
        end
        return false
    end, true, false, true)
    
    return inst
end

return Prefab("horn", fn, assets)