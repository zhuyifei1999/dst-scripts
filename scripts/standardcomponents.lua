function DefaultIgniteFn(inst)
    if inst.components.burnable ~= nil then
        inst.components.burnable:StartWildfire()
    end
end

function DefaultBurnFn(inst)
    if not (inst:HasTag("tree") or inst:HasTag("structure")) then
        inst.persists = false
    end
end

function DefaultBurntFn(inst)
    if inst.components.growable ~= nil then
        inst:RemoveComponent("growable")
    end

    if inst.inventoryitemdata ~= nil then
        inst.inventoryitemdata = nil
    end

    if inst.components.workable ~= nil and inst.components.workable.action ~= ACTIONS.HAMMER then
        inst.components.workable:SetWorkLeft(0)
    end

    local ash = SpawnPrefab("ash")
    ash.Transform:SetPosition(inst.Transform:GetWorldPosition())

    if inst.components.stackable ~= nil then
        ash.components.stackable.stacksize = math.min(ash.components.stackable.maxsize, inst.components.stackable.stacksize)
    end

    inst:Remove()
end

function DefaultExtinguishFn(inst)
    if not (inst:HasTag("tree") or inst:HasTag("structure")) then
        inst.persists = true
    end
end

function DefaultBurntStructureFn(inst)
    inst:AddTag("burnt")
    inst.components.burnable.canlight = false
    if inst.AnimState then
        inst.AnimState:PlayAnimation("burnt", true)
    end
    inst:PushEvent("burntup")
    if inst.SoundEmitter then
        inst.SoundEmitter:KillSound("idlesound")
        inst.SoundEmitter:KillSound("sound")
        inst.SoundEmitter:KillSound("loop")
        inst.SoundEmitter:KillSound("snd")
    end
    if inst.MiniMapEntity then
        inst.MiniMapEntity:SetEnabled(false)
    end
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
    end
    if inst.components.childspawner then
        if inst:GetTimeAlive() > 5 then inst.components.childspawner:ReleaseAllChildren() end
        inst.components.childspawner:StopSpawning()
        inst:RemoveComponent("childspawner")
    end
    if inst.components.container then
        inst.components.container:DropEverything()
        inst.components.container:Close()
        inst:RemoveComponent("container")
    end
    if inst.components.dryer then
        inst.components.dryer:StopDrying("fire")
        inst:RemoveComponent("dryer")
    end
    if inst.components.stewer then
        inst.components.stewer:StopCooking("fire") 
        inst:RemoveComponent("stewer")
    end
    if inst.components.harvestable then
        inst.components.harvestable:StopGrowing()
        inst:RemoveComponent("harvestable")
    end
    if inst.components.sleepingbag then
        inst:RemoveComponent("sleepingbag")
    end
    if inst.components.grower then
        inst.components.grower:Reset("fire")
        inst:RemoveComponent("grower")
    end
    if inst.components.spawner then
        if inst:GetTimeAlive() > 5 then inst.components.spawner:ReleaseChild() end
        inst:RemoveComponent("spawner")
    end
    if inst.components.prototyper then
        inst:RemoveComponent("prototyper")
    end
    if inst.Light then
        inst.Light:Enable(false)
    end
    if inst.components.burnable then
        inst:RemoveComponent("burnable")
    end
    inst:RemoveTag("dragonflybait_lowprio")
    inst:RemoveTag("dragonflybait_medprio")
    inst:RemoveTag("dragonflybait_highprio")
end


local burnfx = 
{
    character = "character_fire",
    generic = "fire",
}

function MakeSmallBurnable(inst, time, offset, structure)
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:SetBurnTime(time or 10)
    inst.components.burnable:AddBurnFX(burnfx.generic, offset or Vector3(0, 0, 0) )
    inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)
    if structure then
        inst.components.burnable:SetOnBurntFn(DefaultBurntStructureFn)
        MaybeMakeDragonflyBait(inst, 2)
    else
        inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    end
end

function MakeMediumBurnable(inst, time, offset, structure)
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(3)
    inst.components.burnable:SetBurnTime(time or 20)
    inst.components.burnable:AddBurnFX(burnfx.generic, offset or Vector3(0, 0, 0) )
    inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)
    if structure then
        inst.components.burnable:SetOnBurntFn(DefaultBurntStructureFn)
        MaybeMakeDragonflyBait(inst, 2)
    else
        inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    end
end

function MakeLargeBurnable(inst, time, offset, structure)
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(4)
    inst.components.burnable:SetBurnTime(time or 30)
    inst.components.burnable:AddBurnFX(burnfx.generic, offset or Vector3(0, 0, 0) )
    inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)
    if structure then
        inst.components.burnable:SetOnBurntFn(DefaultBurntStructureFn)
        MaybeMakeDragonflyBait(inst, 2)
    else
        inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    end
end

function MakeSmallPropagator(inst)
   
    inst:AddComponent("propagator")
    inst.components.propagator.acceptsheat = true
    inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    inst.components.propagator.flashpoint = 5 + math.random()*5
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 5
    inst.components.propagator.heatoutput = 5--8
    
    inst.components.propagator.damagerange = 2
    inst.components.propagator.damages = true
end

function MakeMediumPropagator(inst)

    inst:AddComponent("propagator")
    inst.components.propagator.acceptsheat = true
    inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    inst.components.propagator.flashpoint = 15+math.random()*10
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 7
    inst.components.propagator.heatoutput = 8.5--12

    inst.components.propagator.damagerange = 3
    inst.components.propagator.damages = true
end

function MakeLargePropagator(inst)

    inst:AddComponent("propagator")
    inst.components.propagator.acceptsheat = true
    inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    inst.components.propagator.flashpoint = 45+math.random()*10
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.propagaterange = 8
    inst.components.propagator.heatoutput = 9.5--12

    inst.components.propagator.damagerange = 3
    inst.components.propagator.damages = true
end

function MakeSmallBurnableCharacter(inst, sym, offset)
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(1)
    inst.components.burnable:SetBurnTime(6)
    inst.components.burnable.canlight = false
    inst.components.burnable:AddBurnFX(burnfx.character, offset or Vector3(0, 0, 1), sym)
    MakeSmallPropagator(inst)
    inst.components.propagator.acceptsheat = false
end

function MakeMediumBurnableCharacter(inst, sym, offset)
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(2)
    inst.components.burnable.canlight = false
    inst.components.burnable:SetBurnTime(8)
    inst.components.burnable:AddBurnFX(burnfx.character, offset or Vector3(0, 0, 1), sym)
    MakeSmallPropagator(inst)
    inst.components.propagator.acceptsheat = false
end

function MakeLargeBurnableCharacter(inst, sym, offset)
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(3)
    inst.components.burnable.canlight = false
    inst.components.burnable:SetBurnTime(10)
    inst.components.burnable:AddBurnFX(burnfx.character, offset or Vector3(0, 0, 1), sym)
    MakeLargePropagator(inst)
    inst.components.propagator.acceptsheat = false
end

local shatterfx = 
{
    character = "shatter",
}

function MakeTinyFreezableCharacter(inst, sym, offset)
    inst:AddComponent("freezable")
    inst.components.freezable:SetShatterFXLevel(1)
    inst.components.freezable:AddShatterFX(shatterfx.character, offset or Vector3(0, 0, 0), sym)
end

function MakeSmallFreezableCharacter(inst, sym, offset)
    inst:AddComponent("freezable")
    inst.components.freezable:SetShatterFXLevel(2)
    inst.components.freezable:AddShatterFX(shatterfx.character, offset or Vector3(0, 0, 0), sym)
end

function MakeMediumFreezableCharacter(inst, sym, offset)
    inst:AddComponent("freezable")
    inst.components.freezable:SetShatterFXLevel(3)
    inst.components.freezable:SetResistance(2)
    inst.components.freezable:AddShatterFX(shatterfx.character, offset or Vector3(0, 0, 0), sym)
end

function MakeLargeFreezableCharacter(inst, sym, offset)
    inst:AddComponent("freezable")
    inst.components.freezable:SetShatterFXLevel(4)
    inst.components.freezable:SetResistance(3)
    inst.components.freezable:AddShatterFX(shatterfx.character, offset or Vector3(0, 0, 0), sym)
end

function MakeHugeFreezableCharacter(inst, sym, offset)
    inst:AddComponent("freezable")
    inst.components.freezable:SetShatterFXLevel(5)
    inst.components.freezable:SetResistance(4)
    inst.components.freezable:AddShatterFX(shatterfx.character, offset or Vector3(0, 0, 0), sym)
end

function MakeInventoryPhysics(inst)
    local phys = inst.entity:AddPhysics()
    phys:SetSphere(.5)
    phys:SetMass(1)
    phys:SetFriction(.1)
    phys:SetDamping(0)
    phys:SetRestitution(.5)
    phys:SetCollisionGroup(COLLISION.ITEMS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.SMALLOBSTACLES)
end

function MakeCharacterPhysics(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetCapsule(rad, 1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.SMALLOBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
end

function MakeGiantCharacterPhysics(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetCapsule(rad, 1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.GIANTS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
end

function MakeFlyingGiantCharacterPhysics(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetCapsule(rad, 1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.GIANTS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    --phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
end

function MakeGhostPhysics(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetCapsule(rad, 1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    --phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
end

function ChangeToGhostPhysics(inst)
    local phys = inst.Physics
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    --phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
end

function ChangeToCharacterPhysics(inst)
    local phys = inst.Physics
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.SMALLOBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
end

function ChangeToObstaclePhysics(inst)
    local phys = inst.Physics
    phys:SetCollisionGroup(COLLISION.OBSTACLES)
    phys:ClearCollisionMask()
    phys:SetMass(0) 
    --phys:CollidesWith(COLLISION.GROUND)
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
end

function ChangeToInventoryPhysics(inst)
    local phys = inst.Physics
    phys:SetCollisionGroup(COLLISION.OBSTACLES)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.SMALLOBSTACLES)
end

function MakeObstaclePhysics(inst, rad, height)
    height = height or 2
    inst:AddTag("blocker")
    local phys = inst.entity:AddPhysics()
    --this is lame. Bullet wants 0 mass for static objects, 
    -- for for some reason it is slow when we do that
    
    -- Doesnt seem to slow anything down now.
    phys:SetMass(0) 
    phys:SetCapsule(rad,height)
    phys:SetCollisionGroup(COLLISION.OBSTACLES)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
end

function MakeSmallObstaclePhysics(inst, rad, height)
    height = height or 2
    inst:AddTag("blocker")
    local phys = inst.entity:AddPhysics()
    --this is lame. Bullet wants 0 mass for static objects, 
    -- for for some reason it is slow when we do that
    
    -- Doesnt seem to slow anything down now.
    phys:SetMass(0) 
    phys:SetCapsule(rad,height)
    phys:SetCollisionGroup(COLLISION.SMALLOBSTACLES)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.CHARACTERS)
end

function RemovePhysicsColliders(inst)
    inst.Physics:ClearCollisionMask()
    if inst.Physics:GetMass() > 0 then
        inst.Physics:CollidesWith(COLLISION.GROUND)
    end
end

local function TogglePickable(pickable, iswinter)
    pickable[iswinter and "Pause" or "Resume"](pickable)
end

function MakeNoGrowInWinter(inst)
    inst.components.pickable:WatchWorldState("iswinter", TogglePickable)
    TogglePickable(inst.components.pickable, TheWorld.state.iswinter)
end


function MakeSnowCoveredPristine(inst)
    inst.AnimState:OverrideSymbol("snow", "snow", "snow")
    inst:AddTag("SnowCovered")

    inst.AnimState:Hide("snow")
end

function MakeSnowCovered(inst)
    if not inst:HasTag("SnowCovered") then
        MakeSnowCoveredPristine(inst)
    end
    
    if TheWorld.state.issnowcovered then
        inst.AnimState:Show("snow")
    else
        inst.AnimState:Hide("snow")
    end
end

local function oneat(inst)
    if inst.components.perishable ~= nil then
        inst.components.perishable:SetPercent(1)
    end
end

local function onperish(inst)
    local owner = inst.components.inventoryitem.owner
    if owner ~= nil then
        inst.components.inventoryitem:RemoveFromOwner(true)

        local container = owner.components.inventory or owner.components.container or nil
        if container ~= nil and inst.components.lootdropper ~= nil then
            local stacksize = inst.components.stackable ~= nil and inst.components.stackable.stacksize or 1
            for i = 1, stacksize do
                local loots = inst.components.lootdropper:GenerateLoot()
                for k, v in pairs(loots) do
                    local loot = SpawnPrefab(v)
                    container:GiveItem(loot)
                end
            end
        end

        inst:Remove()
    end
end

function MakeFeedablePetPristine(inst)
    inst:AddTag("show_spoilage")
    inst:AddTag("pet")
end

function MakeFeedablePet(inst, starvetime, oninventory, ondropped)
    MakeFeedablePetPristine(inst)

    --This is acceptable.  Some eaters are added already to specify diets.
    if inst.components.eater == nil then
        inst:AddComponent("eater")
    end
    inst.components.eater:SetOnEatFn(oneat)

    --We want to see the warnings for duplicating perishable
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(starvetime)
    inst.components.perishable:StopPerishing()
    inst.components.perishable:SetOnPerishFn(onperish)

    inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst)
        inst.components.perishable:StartPerishing()
        if oninventory ~= nil then
            oninventory(inst)
        end
    end)

    inst.components.inventoryitem:SetOnDroppedFn(function(inst)
        inst.components.perishable:StopPerishing()
        if ondropped ~= nil then
            ondropped(inst)
        end
    end)
end

local dragonprioritytag =
{
    "dragonflybait_lowprio",
    "dragonflybait_medprio",
    "dragonflybait_highprio",
}
function MakeDragonflyBait(inst, priority)
    priority = priority or 1
    if inst.dragonflypriority ~= priority then
        if inst.dragonflypriority ~= nil then
            inst:RemoveTag(dragonprioritytag[inst.dragonflypriority])
        end
        inst.dragonflypriority = priority
        inst:AddTag(dragonprioritytag[priority])
    end
end

-- Used by the standard components above to only add the tags if it doesn't already have one
function MaybeMakeDragonflyBait(inst, priority)
    if inst.dragonflypriority == nil then
        inst.dragonflypriority = priority or 1
        inst:AddTag(dragonprioritytag[inst.dragonflypriority])
    end
end

function RemoveDragonflyBait(inst)
    if inst.dragonflypriority ~= nil then
        inst:RemoveTag(dragonprioritytag[inst.dragonflypriority])
        inst.dragonflypriority = nil
    end
end

function MakeHauntableLaunch(inst, chance, speed, cooldown, haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        chance = chance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= chance then
            Launch(inst, haunter, speed or TUNING.LAUNCH_SPEED_SMALL)
            inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_TINY
            return true
        end
        return false
    end)
end

function MakeHauntableLaunchAndSmash(inst, launch_chance, smash_chance, speed, cooldown, launch_haunt_value, smash_haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        launch_chance = launch_chance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= launch_chance then
            Launch(inst, haunter, speed or TUNING.LAUNCH_SPEED_SMALL)
            inst.components.hauntable.hauntvalue = launch_haunt_value or TUNING.HAUNT_TINY
            smash_chance = smash_chance or TUNING.HAUNT_CHANCE_OCCASIONAL
            if math.random() < smash_chance then
                inst.components.hauntable.hauntvalue = smash_haunt_value or TUNING.HAUNT_SMALL
                inst.smashtask = inst:DoPeriodicTask(.1, function(inst)
                    local pt = Point(inst.Transform:GetWorldPosition())
                    if pt.y <= .2 then
                        inst.SoundEmitter:PlaySound("dontstarve/common/stone_drop")
                        local pt = Vector3(inst.Transform:GetWorldPosition())
                        local breaking = SpawnPrefab("ground_chunks_breaking") --spawn break effect
                        breaking.Transform:SetPosition(pt.x, 0, pt.z)
                        inst:Remove()
                        inst.smashtask:Cancel()
                        inst.smashtask = nil
                    end
                end)
            end
            return true
        end
        return false
    end)
end

function MakeHauntableWork(inst, chance, cooldown, haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        chance = chance or TUNING.HAUNT_CHANCE_OFTEN
        if math.random() <= chance then
            if inst.components.workable and inst.components.workable.workleft > 0 then
                inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_SMALL
                inst.components.workable:WorkedBy(haunter, 1)
                return true
            end
        end
        return false
    end)
end

function MakeHauntableWorkAndIgnite(inst, work_chance, ignite_chance, cooldown, work_haunt_value, ignite_haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        local ret = false

        work_chance = work_chance or TUNING.HAUNT_CHANCE_OFTEN
        if math.random() <= work_chance then
            if inst.components.workable and inst.components.workable.workleft > 0 then
                inst.components.hauntable.hauntvalue = work_haunt_value or TUNING.HAUNT_SMALL
                inst.components.workable:WorkedBy(haunter, 1)
                ret = true
            end
        end

        ignite_chance = ignite_chance or TUNING.HAUNT_CHANCE_SUPERRARE
        if math.random() <= ignite_chance then
            if inst.components.burnable and not inst.components.burnable:IsBurning() then
                inst.components.burnable:Ignite()
                inst.components.hauntable.hauntvalue = ignite_haunt_value or TUNING.HAUNT_MEDLARGE
                inst.components.hauntable.cooldown_on_successful_haunt = false
                ret = true
            end
        end

        return ret
    end)
end

function MakeHauntableFreeze(inst, chance, cooldown, haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
        chance = chance or TUNING.HAUNT_CHANCE_HALF
        if math.random() <= chance then
            if inst.components.freezable and not inst.components.freezable:IsFrozen() then
                inst.components.freezable:Freeze()
                inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_MEDIUM
                inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_HUGE
                return true
            end
        end
        return false
    end)
end

function MakeHauntableIgnite(inst, chance, cooldown, haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        chance = chance or TUNING.HAUNT_CHANCE_VERYRARE
        if math.random() <= chance then
            if inst.components.burnable and not inst.components.burnable:IsBurning() then
                inst.components.burnable:Ignite()
                inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_LARGE
                inst.components.hauntable.cooldown_on_successful_haunt = false
                return true
            end
        end
        return false
    end)
end

function MakeHauntableLaunchAndIgnite(inst, launchchance, ignitechance, speed, cooldown, launch_haunt_value, ignite_haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        launchchance = launchchance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= launchchance then
            Launch(inst, haunter, speed or TUNING.LAUNCH_SPEED_SMALL)
            inst.components.hauntable.hauntvalue = launch_haunt_value or TUNING.HAUNT_TINY
            ignitechance = ignitechance or TUNING.HAUNT_CHANCE_VERYRARE
            if math.random() <= ignitechance then
                if inst.components.burnable and not inst.components.burnable:IsBurning() then
                    inst.components.burnable:Ignite()
                    inst.components.hauntable.hauntvalue = ignite_haunt_value or TUNING.HAUNT_MEDIUM
                    inst.components.hauntable.cooldown_on_successful_haunt = false
                end
            end
            return true
        end
        return false
    end)
end

function MakeHauntableChangePrefab(inst, newprefab, chance, haunt_value, nofx)
    if not newprefab then return end
    if type(newprefab) == "table" then
        newprefab = newprefab[math.random(#newprefab)]
    end

    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown_on_successful_haunt = false
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        chance = chance or TUNING.HAUNT_CHANCE_HALF
        if math.random() <= chance then
            if not nofx then
                local fx = SpawnPrefab("small_puff")
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            local new = SpawnPrefab(newprefab)
            if new then
                new.Transform:SetPosition(inst.Transform:GetWorldPosition())
                new:PushEvent("spawnedfromhaunt", {haunter=haunter, oldPrefab=inst}) --#srosen need to circle back and make sure anything that gets change-prefab'd from a haunt gets haunt FX and cooldown appropriately
                inst:PushEvent("despawnedfromhaunt", {haunter=haunter, newPrefab=new})
            end                                                         -- also that any relevant data gets carried over (i.e. bees' home, etc)
            inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_SMALL
            inst:DoTaskInTime(0, function(inst) 
                inst:Remove() 
            end)
            return true
        end
        return false
    end)
end 

function MakeHauntableLaunchOrChangePrefab(inst, launchchance, prefabchance, speed, cooldown, newprefab, prefab_haunt_value, launch_haunt_value, nofx)
    if not newprefab then return end

    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        launchchance = launchchance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= launchchance then
            prefabchance = prefabchance or TUNING.HAUNT_CHANCE_OCCASIONAL
            if math.random() <= prefabchance then
                if not nofx then
                    local fx = SpawnPrefab("small_puff")
                    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
                local new = SpawnPrefab(newprefab)
                new.Transform:SetPosition(inst.Transform:GetWorldPosition())
                new:PushEvent("spawnedfromhaunt", {haunter=haunter, oldPrefab=inst})
                inst:PushEvent("despawnedfromhaunt", {haunter=haunter, newPrefab=new})
                inst.components.hauntable.hauntvalue = prefab_haunt_value or TUNING.HAUNT_SMALL
                inst:DoTaskInTime(0, function(inst) 
                    inst:Remove() 
                end)
            else
                Launch(inst, haunter, speed or TUNING.LAUNCH_SPEED_SMALL)
                inst.components.hauntable.hauntvalue = launch_haunt_value or TUNING.HAUNT_TINY
            end
            return true
        end
        return false
    end)
end 

function MakeHauntablePerish(inst, perishpct, chance, cooldown, haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        chance = chance or TUNING.HAUNT_CHANCE_HALF
        if math.random() <= chance then
            if inst.components.perishable then
                inst.components.perishable:ReducePercent(perishpct or .3)
                inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_MEDIUM
                return true
            end
        end
        return false
    end)
end

function MakeHauntableLaunchAndPerish(inst, launchchance, perishchance, speed, perishpct, cooldown, launch_haunt_value, perish_haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        launchchance = launchchance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= launchchance then
            Launch(inst, haunter, speed or TUNING.LAUNCH_SPEED_SMALL)
            inst.components.hauntable.hauntvalue = launch_haunt_value or TUNING.HAUNT_TINY
            inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
            perishchance = perishchance or TUNING.HAUNT_CHANCE_OCCASIONAL
            if math.random() <= perishchance then
                if inst.components.perishable then
                    inst.components.perishable:ReducePercent(perishpct or .3)
                    inst.components.hauntable.hauntvalue = perish_haunt_value or TUNING.HAUNT_MEDIUM
                    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
                end
            end
            return true
        end
        return false
    end)
end

function MakeHauntablePanic(inst, panictime, chance, cooldown, haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if inst.components.sleeper then -- Wake up, there's a ghost!
            inst.components.sleeper:WakeUp()
        end

        chance = chance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= chance then
            inst.components.hauntable.panic = true
            inst.components.hauntable.panictimer = panictime or TUNING.HAUNT_PANIC_TIME_SMALL
            inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_SMALL
            return true
        end
        return false
    end)
end

function MakeHauntablePanicAndIgnite(inst, panictime, panicchance, ignitechance, cooldown, panic_haunt_value, ignite_haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        panicchance = panicchance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= panicchance then
            inst.components.hauntable.panic = true
            inst.components.hauntable.panictimer = panictime or TUNING.HAUNT_PANIC_TIME_SMALL
            inst.components.hauntable.hauntvalue = panic_haunt_value or TUNING.HAUNT_SMALL
            ignitechance = ignitechance or TUNING.HAUNT_CHANCE_RARE
            if math.random() <= ignitechance then
                if inst.components.burnable and not inst.components.burnable:IsBurning() then
                    inst.components.burnable:Ignite()
                    inst.components.hauntable.hauntvalue = ignite_haunt_value or TUNING.HAUNT_MEDIUM
                    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_HUGE
                end
            end
            return true
        end
        return false
    end)
end

function MakeHauntablePlayAnim(inst, anim, animloop, pushanim, animduration, endanim, endanimloop, soundevent, soundname, soundduration, chance, cooldown, haunt_value)
    if not anim then return end

    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        chance = chance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= chance then

            local loop = animloop ~= nil and animloop or false
            if pushanim then
                inst.AnimState:PushAnimation(anim, loop)
            else
                inst.AnimState:PlayAnimation(anim, loop)
            end
            if animduration and endanim then
                inst:DoTaskInTime(animduration, function(inst) inst.AnimState:PlayAnimation(endanim, endanimloop) end)
            end

            if soundevent and inst.SoundEmitter then
                if soundname then
                    inst.SoundEmitter:PlaySound(soundevent, soundname)
                    if soundduration then
                        inst:DoTaskInTime(soundduration, function(inst) inst.SoundEmitter:KillSound(soundname) end)
                    end
                else
                    inst.SoundEmitter:PlaySound(soundevent)
                end
            end

            inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_TINY
            return true
        end
        return false
    end)
end

function MakeHauntableGoToState(inst, state, chance, cooldown, haunt_value)
    if not (inst and inst.sg) or not state then return end

    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        chance = chance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= chance then
            inst.sg:GoToState(state)
            inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_TINY
            return true
        end
        return false
    end)
end

function MakeHauntableDropFirstItem(inst, chance, cooldown, haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
        chance = chance or TUNING.HAUNT_CHANCE_OCCASIONAL
        if math.random() <= chance then
            if inst.components.inventory then
                local item = inst.components.inventory:FindItem(function(item) return not item:HasTag("nosteal") end)
                if item then
                    local direction = Vector3(haunter.Transform:GetWorldPosition()) - Vector3(inst.Transform:GetWorldPosition() )
                    inst.components.inventory:DropItem(item, false, direction:GetNormalized())
                    inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_MEDIUM
                    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
                    return true
                end
            end
            if inst.components.container then
                local item = inst.components.container:FindItem(function(item) return not item:HasTag("nosteal") end)
                if item then
                    inst.components.container:DropItem(item)
                    inst.components.hauntable.hauntvalue = haunt_value or TUNING.HAUNT_MEDIUM
                    inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
                    return true
                end
            end
        end
        return false
    end)
end

function MakeHauntableLaunchAndDropFirstItem(inst, launchchance, dropchance, speed, cooldown, launch_haunt_value, drop_haunt_value)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        launchchance = launchchance or TUNING.HAUNT_CHANCE_ALWAYS
        if math.random() <= launchchance then
            Launch(inst, haunter, speed or TUNING.LAUNCH_SPEED_SMALL)
            inst.components.hauntable.hauntvalue = launch_haunt_value or TUNING.HAUNT_TINY
            inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_SMALL
            dropchance = dropchance or TUNING.HAUNT_CHANCE_OCCASIONAL
            if math.random() <= dropchance then
                if inst.components.inventory then
                    local item = inst.components.inventory:FindItem(function(item) return not item:HasTag("nosteal") end)
                    if item then
                        local direction = Vector3(haunter.Transform:GetWorldPosition()) - Vector3(inst.Transform:GetWorldPosition() )
                        inst.components.inventory:DropItem(item, false, direction:GetNormalized())
                        inst.components.hauntable.hauntvalue = drop_haunt_value or TUNING.HAUNT_MEDIUM
                        inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
                        return true
                    end
                end
                if inst.components.container then
                    local item = inst.components.container:FindItem(function(item) return not item:HasTag("nosteal") end)
                    if item then
                        inst.components.container:DropItem(item)
                        inst.components.hauntable.hauntvalue = drop_haunt_value or TUNING.HAUNT_MEDIUM
                        inst.components.hauntable.cooldown = cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
                        return true
                    end
                end
            end
            return true
        end
        return false
    end)
end

function AddHauntableCustomReaction(inst, fn, secondrxn, ignoreinitialresult, ignoresecondaryresult)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
    local onhaunt = inst.components.hauntable.onhaunt
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        local result = false
        if secondrxn then -- Custom reaction to come after any existing reactions (i.e. additional effects that are conditional on existing reactions)
            if onhaunt then
                result = onhaunt(inst, haunter)
            end
            if not onhaunt or result or ignoreinitialresult then -- Can use ignore flags if we don't care about the return value of a given part
                local prevresult = result
                result = fn(inst, haunter)
                if ignoresecondaryresult then result = prevresult end
            end
        else -- Custom reaction to come before any existing reactions (i.e. conditions required for existing reaction to trigger)
            result = fn(inst, haunter)
            if (result or ignoreinitialresult) and onhaunt then -- Can use ignore flags if we don't care about the return value of a given part
                local prevresult = result
                result = onhaunt(inst, haunter)
                if ignoresecondaryresult then result = prevresult end
            end
        end
        return result
    end)
end

function AddHauntableDropItemOrWork(inst)
    if not inst.components.hauntable then inst:AddComponent("hauntable") end
	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
		local ret = false
		if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
			if inst.components.container then
				local item = inst.components.container:FindItem(function(item) return not item:HasTag("nosteal") end)
				if item then
					inst.components.container:DropItem(item)
					inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
					ret = true
				end
			end
		end
		if math.random() <= TUNING.HAUNT_CHANCE_VERYRARE then
			if inst.components.workable then
				inst.components.workable:WorkedBy(haunter, 1)
				inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
				ret = true
			end
		end
		return ret
	end)
end
