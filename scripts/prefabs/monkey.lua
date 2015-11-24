local assets =
{
    Asset("ANIM", "anim/kiki_basic.zip"),
    Asset("ANIM", "anim/kiki_build.zip"),
    Asset("ANIM", "anim/kiki_nightmare_skin.zip"),
    Asset("SOUND", "sound/monkey.fsb"),
}

local prefabs =
{
    "poop",
    "monkeyprojectile",
    "smallmeat",
    "cave_banana",
}

local brain = require "brains/monkeybrain"
local nightmarebrain = require "brains/nightmaremonkeybrain"

local SLEEP_DIST_FROMHOME = 1
local SLEEP_DIST_FROMTHREAT = 20
local MAX_CHASEAWAY_DIST = 80
local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 40

SetSharedLootTable( 'monkey',
{
    {'smallmeat',     1.0},
    {'cave_banana',   1.0},
    {'nightmarefuel', 0.5},
})

local function WeaponDropped(inst)
    inst:Remove()
end

local function oneat(inst)
    --Monkey ate some food. Give him some poop!
    if inst.components.inventory then
        local maxpoop = 3
        local poopstack = inst.components.inventory:FindItem(function(item) return item.prefab == "poop" end )
        if poopstack and poopstack.components.stackable.stacksize < maxpoop then
            local newpoop = SpawnPrefab("poop")
            inst.components.inventory:GiveItem(newpoop)
        elseif not poopstack then
            local newpoop = SpawnPrefab("poop")
            inst.components.inventory:GiveItem(newpoop)
        end
    end
end

local function onthrow(weapon, inst)
    if inst.components.inventory then
        local poopstack = inst.components.inventory:FindItem(function(item) return item.prefab == "poop" end )
        if poopstack then
            inst.components.inventory:ConsumeByName("poop", 1)
        end
    end
end

local function hasammo(inst)
    if inst.components.inventory then
        local poopstack = inst.components.inventory:FindItem(function(item) return item.prefab == "poop" end )
        return poopstack ~= nil
    end
end

local function EquipWeapons(inst)
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local thrower = CreateEntity()
        thrower.name = "Thrower"
        thrower.entity:AddTransform()
        thrower:AddComponent("weapon")
        thrower.components.weapon:SetDamage(TUNING.MONKEY_RANGED_DAMAGE)
        thrower.components.weapon:SetRange(TUNING.MONKEY_RANGED_RANGE)
        thrower.components.weapon:SetProjectile("monkeyprojectile")
        thrower.components.weapon:SetOnProjectileLaunch(onthrow)
        thrower:AddComponent("inventoryitem")
        thrower.persists = false
        thrower.components.inventoryitem:SetOnDroppedFn(thrower.Remove)
        thrower:AddComponent("equippable")
        inst.components.inventory:GiveItem(thrower)
        inst.weaponitems.thrower = thrower

        local hitter = CreateEntity()
        hitter.name = "Hitter"
        hitter.entity:AddTransform()
        hitter:AddComponent("weapon")
        hitter.components.weapon:SetDamage(TUNING.MONKEY_MELEE_DAMAGE)
        hitter.components.weapon:SetRange(0)
        hitter:AddComponent("inventoryitem")
        hitter.persists = false
        hitter.components.inventoryitem:SetOnDroppedFn(hitter.Remove)
        hitter:AddComponent("equippable")
        inst.components.inventory:GiveItem(hitter)
        inst.weaponitems.hitter = hitter

    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.harassplayer = nil
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.task = inst:DoTaskInTime(math.random(55, 65), function() inst.components.combat:SetTarget(nil) end)    --Forget about target after a minute

    local pt = inst:GetPosition()
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 30, {"monkey"})  
    for k,v in pairs(ents) do
        if v ~= inst then
            v.components.combat:SuggestTarget(data.attacker)
            v.harassplayer = nil

            if v.task then
                v.task:Cancel()
                v.task = nil
            end
            v.task = v:DoTaskInTime(math.random(55, 65), function() v.components.combat:SetTarget(nil) end) --Forget about target after a minute
        end
    end
end

local function FindTargetOfInterest(inst)

    if not inst.curious then
        return 
    end

    if inst.harassplayer == nil and inst.components.combat.target == nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        -- Get all players in range
        local targets = FindPlayersInRange(x, y, z, 25)
        -- randomly iterate over all players until we find one we're interested in.
        for i = 1,#targets do
            local randomtarget = math.random(1,#targets)
            local target = targets[randomtarget]
            table.remove(targets, randomtarget)
            if target.components.inventory then
                local interest_chance = 0.15
                local item = target.components.inventory:FindItem(function(item) return item.prefab == "cave_banana" or item.prefab == "cave_banana_cooked" end )

                if item then
                    -- He has bananas! Maybe we should start following...
                    interest_chance = 0.6 
                end
                if math.random() < interest_chance then
                    inst.harassplayer = target
                    inst:DoTaskInTime(120, function() inst.harassplayer = nil end)
                    return
                end
            end
        end
    end
end

local function retargetfn(inst)
    if inst:HasTag("nightmare") then
        local newtarget = FindEntity(inst, 20, function(guy)
                return inst.components.combat:CanTarget(guy)
        end,
        nil,
        nil,
        {"character","monster"})
        return newtarget
    end
end

local function shouldKeepTarget(inst, target)
    if inst:HasTag("nightmare") then
        return true
    end

    return true
end

local function IsInCharacterList(name)
    local characters = GetActiveCharacterList()

    for k,v in pairs(characters) do
        if name == v then
            return true
        end
    end
end

local function OnMonkeyDeath(inst, data)
    if data.inst:HasTag("monkey") then  --A monkey died! 
        if IsInCharacterList(data.cause) then   --And it was the player! Run home!
            --Drop all items, go home
            inst:DoTaskInTime(math.random(), function() 
                if inst.components.inventory then
                    inst.components.inventory:DropEverything(false, true)
                end

                if inst.components.homeseeker and inst.components.homeseeker.home then
                    inst.components.homeseeker.home:PushEvent("monkeydanger")
                end
            end)
        end
    end
end

local function OnPickup(inst, data)
    if data.item then
        if data.item.components.equippable and
        data.item.components.equippable.equipslot == EQUIPSLOTS.HEAD and not 
        inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
            --Ugly special case for how the PICKUP action works.
            --Need to wait until PICKUP has called "GiveItem" before equipping item.
            inst:DoTaskInTime(0.1, function() inst.components.inventory:Equip(data.item) end)       
        end
    end
end

local function DoFx(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition_2")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(.8, .8, .8)
    end
    fx = SpawnPrefab("statue_transition")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(.8, .8, .8)
    end
end

local function SetNormalMonkey(inst)
    inst:RemoveTag("nightmare")
    inst:SetBrain(brain)
    inst.AnimState:SetBuild("kiki_basic")
    inst.AnimState:SetMultColour(1,1,1,1)
    inst.curious = true
    inst.soundtype = ""
    inst.components.lootdropper:SetLoot({"smallmeat", "cave_banana"})
    inst.components.lootdropper.droppingchanceloot = false

    inst.components.combat:SetTarget(nil)
    
    inst:ListenForEvent("entity_death", inst.listenfn, TheWorld)
end

local function SetNightmareMonkey(inst)
    inst:AddTag("nightmare")
    inst.AnimState:SetMultColour(1,1,1,.6)
    inst:SetBrain(nightmarebrain)
    inst.AnimState:SetBuild("kiki_nightmare_skin")
    inst.soundtype = "_nightmare"
    inst.harassplayer = nil
    inst.curious = false
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    
    inst.components.lootdropper:SetLoot({"beardhair"})
    inst.components.lootdropper.droppingchanceloot = true
    inst.components.combat:SetTarget(nil)
    
    inst:RemoveEventCallback("entity_death", inst.listenfn, TheWorld)
end

local function TestNightmareArea(inst, area)
    if (TheWorld.state.isnightmarewild or TheWorld.state.isnightmaredawn)
        and inst.components.areaaware:CurrentlyInTag("Nightmare")
        and not inst:HasTag("nightmare") then

        DoFx(inst)
        SetNightmareMonkey(inst)
    elseif (not TheWorld.state.isnightmarewild and not TheWorld.state.isnightmaredawn)
        and inst:HasTag("nightmare") then
        DoFx(inst)
        SetNormalMonkey(inst)
    end
end

local function TestNightmarePhase(inst, phase)
    if (phase == "wild" or phase == "dawn")
        and inst.components.areaaware:CurrentlyInTag("Nightmare")
        and not inst:HasTag("nightmare") then

        DoFx(inst)
        SetNightmareMonkey(inst)
    elseif (phase ~= "wild" and phase ~= "dawn")
        and inst:HasTag("nightmare") then
        DoFx(inst)
        SetNormalMonkey(inst)
    end
end

local function OnCustomHaunt(inst)
    inst.components.periodicspawner:TrySpawn()
    return true
end

local function OnSave(inst, data)
    data.nightmare = inst:HasTag("nightmare") or nil
end

local function OnLoad(inst, data)
    if data ~= nil and data.nightmare then
        SetNightmareMonkey()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()   
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, 1.25)

    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 10, 0.25)

    inst.AnimState:SetBank("kiki")
    inst.AnimState:SetBuild("kiki_basic")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("cavedweller")
    inst:AddTag("monkey")
    inst:AddTag("animal")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.soundtype = ""

    MakeMediumBurnableCharacter(inst)
    MakeMediumFreezableCharacter(inst)

    inst:AddComponent("inventory")

    inst:AddComponent("inspectable")

    inst:AddComponent("thief")

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 1 )
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = false }
    inst.components.locomotor.walkspeed = TUNING.MONKEY_MOVE_SPEED

    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(TUNING.MONKEY_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.MONKEY_MELEE_RANGE)
    inst.components.combat:SetRetargetFunction(1, retargetfn)

    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
    inst.components.combat:SetDefaultDamage(0)  --This doesn't matter, monkey uses weapon damage

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.MONKEY_HEALTH)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("poop")
    inst.components.periodicspawner:SetRandomTimes(200,400)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(15)
    inst.components.periodicspawner:Start()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('monkey')
    inst.components.lootdropper.droppingchanceloot = false

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
    inst.components.eater:SetOnEatFn(oneat)

    inst:AddComponent("sleeper")
    inst.components.sleeper.sleeptestfn = NocturnalSleepTest
    inst.components.sleeper.waketestfn = NocturnalWakeTest

    inst:AddComponent("areaaware")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGmonkey")

    inst.FindTargetOfInterestTask = inst:DoPeriodicTask(10, FindTargetOfInterest)   --Find something to be interested in!

    inst.HasAmmo = hasammo
    inst.curious = true

    inst:AddComponent("knownlocations")    

    inst.listenfn = function(listento, data) OnMonkeyDeath(inst, data) end

    inst:ListenForEvent("onpickupitem", OnPickup)
    inst:ListenForEvent("attacked", OnAttacked)

    inst:WatchWorldState("nightmarephase", TestNightmarePhase)
    inst:ListenForEvent("changearea", TestNightmareArea)

    MakeHauntablePanic(inst)
    AddHauntableCustomReaction(inst, OnCustomHaunt, true, false, true)

    inst.weaponitems = {}
    EquipWeapons(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.harassplayer = nil

    return inst
end

return Prefab("monkey", fn, assets, prefabs)
