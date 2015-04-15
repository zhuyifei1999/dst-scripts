--[[
    The worm should wander around looking for fights until it finds a "home".    
    A good home will look like a place with multiple other items that have the pickable
    component so the worm can set up a lure nearby.

    Once the worm has found a good home it will hang around that area and
    feed off of the plants and creatures that are nearby.

    If the player tries to interact with the worm's lure or
    approaches the worm while it isn't in a lure state it will strike.

    Spawn a dirt mound that must be dug up to get loot?
]]

local assets=
{
	Asset("ANIM", "anim/worm.zip"),
    Asset("SOUND", "sound/worm.fsb"),
}

local prefabs =
{
    "monstermeat",
    "wormlight",
}

local brain = require"brains/wormbrain"

local function retargetfn(inst)

    --Don't search for targets when you're luring. Targets will come to you.
    if inst.sg:HasStateTag("lure") then
        return
    end

    return FindEntity(inst, TUNING.WORM_TARGET_DIST, function(guy) 
        if guy.components.health and not guy.components.health:IsDead() then
            return not (guy.prefab == inst.prefab)
        end
    end,
    {"_combat"}, -- see entityscript.lua
    {"prey"},
    {"character","monster","animal"}
    )
end

local function shouldKeepTarget(inst, target)

    if inst.sg:HasStateTag("lure") then
        return false
    end

    local home = inst.components.knownlocations:GetLocation("home")
    
    if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
        if home then
            return distsq(home, target:GetPosition()) < TUNING.WORM_CHASE_DIST * TUNING.WORM_CHASE_DIST
        elseif not home then
            local distsq = target:GetDistanceSqToInst(inst)
            return distsq < TUNING.WORM_CHASE_DIST * TUNING.WORM_CHASE_DIST
        end
    else
        return false
    end
end

local function onpickedfn(inst, target)
    if target then
        inst.components.combat:SetTarget(target)
        inst:FacePoint(target:GetPosition())
        inst.components.combat:TryAttack(target)
    end

    if inst.attacktask then
        inst.attacktask:Cancel()
        inst.attacktask = nil
    end
end

local function displaynamefn(inst)
    return STRINGS.NAMES[
        inst:HasTag("lure") and "WORM_PLANT" or
        (inst:HasTag("dirt") and "WORM_DIRT" or "WORM")]
end

local function areaislush(pos)
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 7)
    local num_plants = 0
    for k, v in pairs(ents) do
        if v.components.pickable ~= nil then
            if num_plants < 2 then
                num_plants = num_plants + 1
            else
                --return true once we have found at least 3 plants
                return true
            end
        end
    end
    return false
end

local function notclaimed(inst, pos)
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 30)
    for k, v in pairs(ents) do
        if v ~= inst and v.prefab == inst.prefab then
            return false
        end
    end
    return true
end

local function LookForHome(inst)
    if inst.components.knownlocations:GetLocation("home") ~= nil then
        inst.HomeTask:Cancel()
        inst.HomeTask = nil
        return
    end

    local pt = inst:GetPosition()

    local positions = {}
    local distancemod = 30

    for i = 1, 30 do
        local s = i/32.0--(num/2) -- 32.0
        local a = math.sqrt(s*512.0)
        local b = math.sqrt(s)
        table.insert(positions, Vector3(math.sin(a)*b, 0, math.cos(a)*b))
    end

    local map = TheWorld.Map

    for k, v in pairs(positions) do
        local offset = Vector3(v.x * distancemod, 0, v.z * distancemod)
        local pos = offset + pt
        if map:IsAboveGroundAtPoint(pos:Get()) and areaislush(pos) and notclaimed(inst, pos) then
            --Yay! Set this as my home
            inst.components.knownlocations:RememberLocation("home", pos)
            break
        end
    end
end

local function playernear(inst, player)
    if not inst.attacktask and inst.sg:HasStateTag("lure") then
        inst.attacktask = inst:DoTaskInTime(2 + math.random(), function() onpickedfn(inst, player) end )
    end
end

local function playerfar(inst)
    if inst.attacktask then
        inst.attacktask:Cancel()
        inst.attacktask = nil
    end
end

local function onattacked(inst, data)
    if data.attacker then
        inst.components.combat:SetTarget(data.attacker)
        inst.components.combat:ShareTarget(data.attacker, 40, function(dude) return dude:HasTag("worm") and not dude.components.health:IsDead() end, 3)
    end
end

local function fn()
	local inst = CreateEntity()
	
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
 	inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1000, .5)
    
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("worm")
    inst.AnimState:SetBuild("worm")
    inst.AnimState:PlayAnimation("idle_loop")

    inst:AddTag("monster")    
    inst:AddTag("hostile")
    inst:AddTag("wet")
    
    inst.displaynamefn = displaynamefn  --Handles the changing names.

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.WORM_HEALTH)
        
    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.WORM_ATTACK_DIST)
    inst.components.combat:SetDefaultDamage(TUNING.WORM_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.WORM_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(GetRandomWithVariance(2, 0.5), retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
        
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }

    inst:AddComponent("eater")
    inst.components.eater:SetOmnivore()

    inst:AddComponent("pickable")
    inst.components.pickable.canbepicked = false
    inst.components.pickable.onpickedfn = onpickedfn

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(2, 5)
    inst.components.playerprox:SetOnPlayerNear(playernear)
    inst.components.playerprox:SetOnPlayerFar(playerfar)

    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, 0, 0.8, 0.5, {1,1,1}, 0, function(inst, light) if light then light:Enable(false) end end)

    inst:AddComponent("knownlocations")
    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"monstermeat", "monstermeat", "monstermeat", "monstermeat", "wormlight"})

    --Disable this task for worm attacks
    inst.HomeTask = inst:DoPeriodicTask(3, LookForHome)
    inst.lastluretime = 0
    inst:ListenForEvent("attacked", onattacked)

    inst:SetStateGraph("SGworm")
    inst:SetBrain(brain)

    return inst
end

return Prefab("cave/monsters/worm", fn, assets, prefabs)