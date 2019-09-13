local brain = require "brains/malbatrossbrain"

local assets =
{
    Asset("ANIM", "anim/malbatross_basic.zip"),
    Asset("ANIM", "anim/malbatross_actions.zip"),    
    Asset("ANIM", "anim/malbatross_build.zip"),
}

local rippleassets =
{
    Asset("ANIM", "anim/malbatross_ripple.zip"),
}

local prefabs =
{
    "malbatross_ripple",
    "wave_med",
    "splash_teal",    
    "splash_green",
    "malbatross_beak",
    "mast_malbatross",
    "mast_malbatross_item",
    "malbatross_feather",
    "malbatross_feather_fall",
}

local TARGET_DIST = 16

local function RetargetFn(inst)
local range = inst:GetPhysicsRadius(0) + 8
    return FindEntity(
            inst,
            TARGET_DIST,
            function(guy)
                return inst.components.combat:CanTarget(guy)
                    and (   guy.components.combat:TargetIs(inst) or
                            guy:IsNear(inst, range)
                        )
            end,
            { "_combat","hostile" },
            { "wall","INLIMBO" }
        )
end

local function KeepTargetFn(inst, target)
    local home = inst.components.knownlocations:GetLocation("home")
    if home and inst:GetDistanceSqToPoint(home:Get()) > TUNING.MALBATROSS_MAX_CHASEAWAY_DIST * TUNING.MALBATROSS_MAX_CHASEAWAY_DIST then
        return false
    end

    return inst.components.combat:CanTarget(target)
end

local function ShouldSleep(inst)
    return false
end

local function ShouldWake(inst)
    return true
end

local function OnSave(inst, data)

end

local function OnLoad(inst, data)
    if data then

    end
end

local function MalbatrossIsHungry(inst)
    return not inst.components.timer:TimerExists("satiated")
end

local function OnAttacked(inst, data)
    inst.staredown = nil
    
    inst.components.combat:SetTarget(data.attacker)

    if not inst.components.knownlocations:GetLocation("home") then
        local pos = Vector3(inst.Transform:GetWorldPosition())
        inst.components.knownlocations:RememberLocation("home", pos)
    end

    for i=1,4 do
        if math.random() < 0.05 then    
            inst.spawnfeather(inst,0.4)        
        end
    end

    if not inst.divetask and not inst.readytodive then
        inst.resetdivetask(inst)
    end
end

local function OnHealthChange(inst,data)
    if data.newpercent <= 0.66 then
        inst.willdive = true    
    end
    if data.newpercent <= 0.33 then
        inst.willswoop = true            
    end
end

local function OnRemove(inst)
    TheWorld:PushEvent("malbatrossremoved", inst)
end

local function OnDead(inst)
    if inst.swooptask then
        inst.swooptask:Cancel()
        inst.swooptask = nil
    end
end

local function OnLostTarget(inst)
    inst.staredown = nil
end

local function spawnfeather(inst,time)
    local feather = SpawnPrefab("malbatross_feather_fall")
    local pos = Vector3(inst.Transform:GetWorldPosition())
    local angle = math.random() * 2* PI
    local offset = Vector3(math.cos(angle), 0, -math.sin(angle)):Normalize() * (math.random()*2+ 1)
    pos = pos + offset
    feather.Transform:SetPosition(pos.x,pos.y,pos.z)

    if time then
        local set = time * 79/30
        feather.AnimState:SetTime( set )
    end

    feather.Transform:SetRotation(math.random()*360)
end


local function OnEntitySleep(inst)
    inst.components.timer:StartTimer("sleeping_relocate", TUNING.MALBATROSS_ENTITYSLEEP_RELOCATE_TIME)
end

local function OnEntityWake(inst)
    inst.components.timer:StopTimer("sleeping_relocate")
end

local function OnTimerDone(inst, data)
    if data.name == "sleeping_relocate" then
        TheWorld.components.malbatrossspawner:Relocate(inst)
    end
end

local function resetdivetask(inst)
    
    if inst.divetask then
        inst.divetask:Cancel()
        inst.divetask = nil
    end
    inst.divetask = inst:DoTaskInTime(10, 
        function(inst) 
            inst.readytodive = true 
            inst.divetask:Cancel()
            inst.divetask = nil
        end)
end

local function spawnwaves(inst, numWaves, totalAngle, waveSpeed, wavePrefab, initialOffset, idleTime, instantActivate, random_angle)
    SpawnAttackWaves(
        inst:GetPosition(),
        (not random_angle and inst.Transform:GetRotation()) or nil,
        initialOffset or (inst.Physics and inst.Physics:GetRadius()) or nil,
        numWaves,
        totalAngle,
        waveSpeed,
        wavePrefab,
        idleTime,
        instantActivate
    )
end

local function ClearRecentlyCharged(inst, other)
    inst.recentlycharged[other] = nil
end

local function onothercollide(inst, other)
    if not other:IsValid() or inst.recentlycharged[other] or (not other:HasTag("tree") and not other:HasTag("mast") and not other.components.health) or other == inst then
        return
    elseif other:HasTag("smashable") and other.components.health ~= nil then
        --other.Physics:SetCollides(false)
        other.components.health:Kill()
    elseif other.components.workable ~= nil
        and other.components.workable:CanBeWorked()
        and other.components.workable.action ~= ACTIONS.NET then

        if other:HasTag("mast") then
            local vx, vy, vz = inst.Physics:GetVelocity()
            local velocity = VecUtil_Length(vx, vz) * 3
            local x,y,z = inst.Transform:GetWorldPosition()
            local boat = other:GetCurrentPlatform()
            if boat then
                local boat_physics = boat.components.boatphysics 
                vx,vz = VecUtil_Normalize(vx,vz)
                boat_physics:ApplyForce(vx, vz, velocity)         
            end

            spawnfeather(inst,0.4)
            spawnfeather(inst,0.4)
            spawnfeather(inst,0.4)
            if math.random() < 0.3 then spawnfeather(inst,0.4) end
            if math.random() < 0.3 then spawnfeather(inst,0.4) end
        end

        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
        if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
            inst.recentlycharged[other] = true
            inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        end    
    elseif other.components.health ~= nil and not other.components.health:IsDead() then
        inst.recentlycharged[other] = true
        inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        inst.components.combat:DoAttack(other, inst.weapon)
    end
end

local function oncollide(inst, other)
    if not (other ~= nil and other:IsValid() and inst:IsValid())
        or inst.recentlycharged[other]
        then
        return
    end
    inst:DoTaskInTime(2 * FRAMES, onothercollide, other)
end

local function CreateWeapon(inst)
    local weapon = CreateEntity()
    --[[Non-networked entity]]
    weapon.entity:AddTransform()
    weapon:AddComponent("weapon")
    weapon.components.weapon:SetDamage(75)
    weapon.components.weapon:SetRange(0)
    weapon:AddComponent("inventoryitem")
    weapon.persists = false
    weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
    weapon:AddComponent("equippable")
    inst.components.inventory:GiveItem(weapon)
    inst.weapon = weapon
end

SetSharedLootTable( 'malbatross',
{
    {'meat',                                1.00},
    {'meat',                                1.00},
    {'meat',                                1.00},
    {'meat',                                1.00},
    {'meat',                                1.00},
    {'meat',                                1.00},
    {'meat',                                1.00},    
    {'malbatross_beak',                     1.00},
    {'mast_malbatross_item_blueprint',      1.00},    
    {'malbatross_feathered_weave_blueprint',1.00},        
    {'bluegem',                             1},
    {'bluegem',                             1},
    {'bluegem',                             0.3},
    {'yellowgem',                           0.05},    
})


local function fn()
    
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()    
    inst.entity:AddNetwork()

    MakeTinyFlyingCharacterPhysics(inst,1000, 1.5)

    local s  = 1.30
    inst.Transform:SetScale(s, s, s)

    inst.AnimState:SetBank("malbatross")
    inst.AnimState:SetBuild("malbatross_build")

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("malbatross")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")

    inst.DynamicShadow:SetSize(6, 2)
    inst.Transform:SetSixFaced()

    inst.AnimState:PlayAnimation("idle_loop", true)

    MakeInventoryFloatable(inst, "large")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.recentlycharged = {}
    --inst.Physics:SetCollisionCallback(oncollide)
    inst.oncollide = oncollide

    ------------------------------------------

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 3  
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { allowocean = true }
    ------------------------------------------

    inst:SetStateGraph("SGmalbatross")

    ------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.MALBATROSS_HEALTH)
    inst.components.health.destroytime = 5

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.MALBATROSS_DAMAGE)
    inst.components.combat.playerdamagepercent = TUNING.MALBATROSS_DAMAGE_PLAYER_PERCENT
    inst.components.combat:SetRange(TUNING.MALBATROSS_ATTACK_RANGE)
    inst.components.combat:SetAreaDamage(TUNING.MALBATROSS_AOE_RANGE, TUNING.MALBATROSS_AOE_SCALE)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetAttackPeriod(TUNING.MALBATROSS_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    ------------------------------------------

    inst:AddComponent("inventory")

    ------------------------------------------

    inst:AddComponent("explosiveresist")

    ------------------------------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('malbatross')

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    ------------------------------------------

    inst:AddComponent("timer")

    ------------------------------------------

    inst:AddComponent("knownlocations")

    ------------------------------------------

    inst:AddComponent("entitytracker")

    ------------------------------------------

    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("healthdelta", OnHealthChange)
--    inst:ListenForEvent("onhitother", OnHitOther)
    inst:ListenForEvent("death", OnDead)
    inst:ListenForEvent("onremove", OnRemove)
 --   inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("entitysleep", OnEntitySleep)
    inst:ListenForEvent("entitywake", OnEntityWake)
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("losttarget", OnLostTarget)
    

    MakeLargeBurnableCharacter(inst, "body")
    MakeHugeFreezableCharacter(inst, "body")

    CreateWeapon(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.spawnwaves = spawnwaves
    inst.IsHungry = MalbatrossIsHungry
    inst.spawnfeather = spawnfeather
    inst.resetdivetask = resetdivetask

    inst.readytoswoop = true
    inst.readytosplash = true
    inst.willswoop = false -- changed when health is lowered.

    return inst
end



local function ripplefn()
    
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("malbatross_ripple")
    inst.AnimState:SetBuild("malbatross_ripple")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("fx")

    inst:ListenForEvent("animover", function(inst) inst:Remove() end)

    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.BOAT_TRAIL)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end    
    return inst
end

return Prefab("malbatross", fn, assets, prefabs),
       Prefab("malbatross_ripple", ripplefn, rippleassets )
