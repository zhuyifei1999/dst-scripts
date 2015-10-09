local assets =
{
    Asset("ANIM", "anim/lightning_goat_build.zip"),
    Asset("ANIM", "anim/lightning_goat_shocked_build.zip"),
    Asset("ANIM", "anim/lightning_goat_basic.zip"),
    Asset("ANIM", "anim/lightning_goat_actions.zip"),
    Asset("SOUND", "sound/lightninggoat.fsb"),
}

local prefabs =
{
    "meat",
    "lightninggoathorn",
    "goatmilk",
    "lightninggoatherd",
}

local brain = require("brains/lightninggoatbrain")

SetSharedLootTable( 'lightninggoat',
{
    {'meat',              1.00},
    {'meat',              1.00},
    {'lightninggoathorn', 0.25},
})

SetSharedLootTable( 'chargedlightninggoat',
{
    {'meat',              1.00},
    {'meat',              1.00},
    {'goatmilk',          1.00},  
    {'lightninggoathorn', 0.25},
})

local function RetargetFn(inst)
    if inst.charged then
        local function CheckTarget(guy)
            return inst.components.combat:CanTarget(guy)
        end
        return
            -- Look for non-wall targets first
            FindEntity(
                inst,
                TUNING.LIGHTNING_GOAT_TARGET_DIST,
                CheckTarget,
                { "_combat" },
                { "lightninggoat", "wall" })
            or
            -- If none, look for walls
            FindEntity(
                inst,
                TUNING.LIGHTNING_GOAT_TARGET_DIST,
                CheckTarget,
                { "_combat", "wall" },
                { "lightninggoat" })
            or
            nil
    end
end

local function KeepTargetFn(inst, target)
    if target:HasTag("wall") then
        --Don't keep wall target if a non-wall target is available
        return
            FindEntity(
                inst,
                TUNING.LIGHTNING_GOAT_TARGET_DIST,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                end,
                { "_combat" },
                { "lightninggoat", "wall" }) == nil
    end
    --Don't keep target if we chased too far from our herd
    local herd = inst.components.herdmember ~= nil and inst.components.herdmember:GetHerd() or nil
    return herd == nil or inst:IsNear(herd, TUNING.LIGHTNING_GOAT_CHASE_DIST)
end

local function discharge(inst)
    inst:RemoveTag("charged")
    inst.components.lootdropper:SetChanceLootTable('lightninggoat') 
    inst.sg:GoToState("discharge")
    inst.AnimState:ClearBloomEffectHandle()
    inst.charged = false
    inst.Light:Enable(false)
    inst.chargeleft = nil
end

local function ReduceCharges(inst)
    if inst.chargeleft then
        inst.chargeleft = inst.chargeleft - 1
        if inst.chargeleft <= 0 then
            discharge(inst)
        end
    end
end

local function setcharged(inst, instant)
    inst:AddTag("charged")
    inst.components.lootdropper:SetChanceLootTable('chargedlightninggoat')
    inst.AnimState:SetBuild("lightning_goat_shocked_build")
    inst.AnimState:Show("fx") 
    if not instant then
        inst.sg:GoToState("shocked")
    end
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.charged = true
    inst.chargeleft = 3
    inst.Light:Enable(true)
    inst:WatchWorldState("cycles", ReduceCharges)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)

    if inst.charged then
        if data.attacker.components.health then
            if (data.weapon == nil or (not data.weapon:HasTag("projectile") and data.weapon.projectile == nil))
                and not (data.attacker.components.inventory and data.attacker.components.inventory:IsInsulated()) then

                data.attacker.components.health:DoDelta(-TUNING.LIGHTNING_GOAT_DAMAGE)
                if data.attacker:HasTag("player") then
                    data.attacker.sg:GoToState("electrocute")
                end
            end
        end
    end

    if not inst.charged and data and data.weapon and data.weapon.components.weapon and data.weapon.components.weapon.stimuli == "electric" then
        setcharged(inst)
    end

    local attacker = data and data.attacker
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, 20, function(dude) return dude:HasTag("lightninggoat") and dude:HasTag("charged") end, 3)
end

local function OnSave(inst, data)
    if inst.charged then
        data.charged = inst.charged
        data.chargeleft = inst.chargeleft
    end
end

local function OnLoad(inst, data)
    if data and data.charged and data.chargeleft then
        setcharged(inst, true)
        inst.chargeleft = data.chargeleft
    end
end

local function getstatus(inst)
    return inst.charged and "CHARGED" or nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.75, .75)

    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 100, 1)

    inst.AnimState:SetBank("lightning_goat")
    inst.AnimState:SetBuild("lightning_goat_build")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("fx")

    ------------------------------------------

    inst:AddTag("lightninggoat")
    inst:AddTag("animal")
    inst:AddTag("lightningrod")

    inst.Light:Enable(false)
    inst.Light:SetRadius(.85)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(255 / 255, 255 / 255, 236 / 255)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    ------------------------------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(350)

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.LIGHTNING_GOAT_DAMAGE)
    inst.components.combat:SetRange(TUNING.LIGHTNING_GOAT_ATTACK_RANGE)
    inst.components.combat.hiteffectsymbol = "lightning_goat_body"
    inst.components.combat:SetAttackPeriod(TUNING.LIGHTNING_GOAT_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/lightninggoat/hurt")
    ------------------------------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('lightninggoat') 

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    ------------------------------------------

    inst:AddComponent("knownlocations")
    inst:AddComponent("herdmember")
    inst.components.herdmember:SetHerdPrefab("lightninggoatherd")

    ------------------------------------------

    inst:ListenForEvent("attacked", OnAttacked)

    ------------------------------------------

    MakeMediumBurnableCharacter(inst, "lightning_goat_body")
    MakeMediumFreezableCharacter(inst, "lightning_goat_body")

    inst:ListenForEvent("lightningstrike", setcharged)
    inst.setcharged = setcharged

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    ------------------------------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.LIGHTNING_GOAT_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.LIGHTNING_GOAT_RUN_SPEED

    MakeHauntablePanic(inst)

    inst:SetStateGraph("SGlightninggoat")
    inst:SetBrain(brain)

    return inst
end

return Prefab("lightninggoat", fn, assets, prefabs)
