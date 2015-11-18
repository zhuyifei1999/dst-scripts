local prefabs =
{
    "thulecite",
    "rocks",
    "cutstone",
    "trinket_6",
    "gears",
    "nightmarefuel",
    "greengem",
    "orangegem",
    "yellowgem",
    "collapse_small",
}

SetSharedLootTable('smashables',
{
    {'rocks',      0.80},
    {'cutstone',   0.10},
    {'trinket_6',  0.05}, -- frayed wires
})

local function makeassetlist(buildname)
    return
    {
        Asset("ANIM", "anim/"..buildname..".zip"),
    }
end

local function OnDeath(inst)
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial(inst.smashsound or "pot")
    --V2C: why play anim if we're removing?
    --     or did u want to remove after anim ends?
    --inst.AnimState:PlayAnimation("broken")
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function OnRepaired(inst, doer)
    if inst.components.health:GetPercent() >= 1 then
        inst.AnimState:PushAnimation("idle")
        if doer.components.sanity ~= nil then
            doer.components.sanity:DoDelta(TUNING.SANITY_MEDLARGE)
        end
        inst:RemoveComponent("repairable")
        inst.components.inspectable.nameoverride = "relic"
        inst.components.named:SetName(STRINGS.NAMES["RELIC"])
        inst.components.health:SetPercent(1)
        inst.rubble = false
        inst.SoundEmitter:PlaySound("dontstarve/common/fixed_stonefurniture")
    else
        inst.SoundEmitter:PlaySound("dontstarve/common/repair_stonefurniture")
        inst.AnimState:PlayAnimation("repair")
        inst.AnimState:PushAnimation("broken")
    end
end

-- local function HealthDelta(inst,old,new)
--     if inst.components.health.currenthealth <= 1 then
--         OnDeath(inst)
--     end
-- end

local function OnHit(inst)
    if not inst.rubble and inst.components.health:GetPercent() >= .5 then
        inst.AnimState:PlayAnimation("hit")
    end
end

local function OnLoad(inst, data)
    if data == nil then
        return
    end
    inst.rubble = data.rubble
    if not inst.rubble then
        inst.components.inspectable.nameoverride = "relic"
        inst.components.named:SetName(STRINGS.NAMES["RELIC"])
        inst.AnimState:PlayAnimation(inst.components.health:GetPercent() >= .5 and "idle" or "broken")
        if inst.components.repairable ~= nil then
            inst:RemoveComponent("repairable")
        end
    end
end

local function OnSave(inst, data)
    if inst.rubble then
        data.rubble = inst.rubble
    end
end

local function makefn(name, asset, smashsound, rubble, tag)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .25)

        inst.MiniMapEntity:SetIcon("relic.png")

        inst.AnimState:SetBank(asset)
        inst.AnimState:SetBuild(asset)
        inst.AnimState:PlayAnimation(rubble and "broken" or "idle")

        inst:AddTag("cavedweller")
        inst:AddTag("smashable")
        inst:AddTag("object")

        if tag ~= nil then
            inst:AddTag(tag)
        end

        --Sneak these into pristine state for optimization
        inst:AddTag("_named")

        inst.entity:SetPristine()

        local world = TheWorld
        if not world.ismastersim then
            return inst
        end

        --Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("_named")

        inst.rubble = rubble
        inst.rubbleName = name

        inst.OnLoad = OnLoad
        inst.OnSave = OnSave

        inst:AddComponent("combat")
        inst.components.combat.onhitfn = OnHit

        inst:AddComponent("health")
        inst.components.health.canmurder = false
        inst.components.health:SetMaxHealth(GetRandomWithVariance(90, 20))

        inst:ListenForEvent("death", OnDeath)

        inst:AddComponent("lootdropper")
        if not string.find(name, "bowl") and not string.find(name, "plate") then
            if string.find(name, "vase") then
                local trinket = GetRandomItem({ "tinket_1", "trinket_3", "trinket_9", "tinket_12", "tinket_6" })
                inst.components.lootdropper:AddChanceLoot(trinket          , 0.10)

                inst.components.lootdropper.numrandomloot = 1
                inst.components.lootdropper.chancerandomloot = 0.05  -- drop some random item X% of the time
                inst.components.lootdropper:AddRandomLoot("silk"           , 0.1) -- Weighted average
                inst.components.lootdropper:AddRandomLoot(trinket          , 0.1)
                inst.components.lootdropper:AddRandomLoot("thulecite"      , 0.1)
                inst.components.lootdropper:AddRandomLoot("sewing_kit"     , 0.1)
                inst.components.lootdropper:AddRandomLoot("spider_hider"   , 0.05)
                inst.components.lootdropper:AddRandomLoot("spider_spitter" , 0.05)
                inst.components.lootdropper:AddRandomLoot("monkey"         , 0.05)
                if world:HasTag("cave") and world.topology.level_number == 2 then  -- ruins
                    inst.components.lootdropper:AddChanceLoot("thulecite"  , 0.05)
                end
            else
                inst.components.lootdropper:SetChanceLootTable('smashables')
                inst.components.lootdropper.numrandomloot = 1
                inst.components.lootdropper.chancerandomloot = 0.01  -- drop some random item 1% of the time
                inst.components.lootdropper:AddRandomLoot("gears"         , 0.01)
                inst.components.lootdropper:AddRandomLoot("greengem"      , 0.01)
                inst.components.lootdropper:AddRandomLoot("yellowgem"     , 0.01)
                inst.components.lootdropper:AddRandomLoot("orangegem"     , 0.01)
                inst.components.lootdropper:AddRandomLoot("nightmarefuel" , 0.01)
                if world:HasTag("cave") and world.topology.level_number == 2 then  -- ruins
                    inst.components.lootdropper:AddRandomLoot("thulecite" , 0.02)
                end
            end
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("named")

        if rubble then
            inst.components.health:SetPercent(.2)
            inst.components.inspectable.nameoverride = "ruins_rubble"
            inst.components.named:SetName(STRINGS.NAMES["RUINS_RUBBLE"])

            inst:AddComponent("repairable")
            inst.components.repairable.repairmaterial = MATERIALS.STONE
            inst.components.repairable.onrepaired = OnRepaired
        else
            inst.components.health:SetPercent(.8)
            inst.components.inspectable.nameoverride = "relic"
            inst.components.named:SetName(STRINGS.NAMES["RELIC"])
        end

        inst:AddComponent("workable")
        inst.components.workable:SetWorkLeft(3)
        inst.components.workable.savestate = true
        inst.components.workable:SetOnFinishCallback(OnDeath)
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetOnWorkCallback(OnHit) 

        inst.smashsound = smashsound

        MakeHauntableWork(inst)

        return inst
    end
end

local function item(name, sound)
    return Prefab("cave/objects/smashables/"..name, makefn(name, name, sound, false), makeassetlist(name), prefabs)
end

local function rubble(name, assetname, sound, rubble)
    return Prefab("cave/objects/smashables/"..name, makefn(name, assetname, sound, rubble), makeassetlist(assetname), prefabs)
end

return item("ruins_plate"),
    item("ruins_bowl"),
    item("ruins_chair", "rock"),
    item("ruins_chipbowl"),
    item("ruins_vase"),
    item("ruins_table", "rock"),
    rubble("ruins_rubble_table", "ruins_table", "rock", true),
    rubble("ruins_rubble_chair", "ruins_chair", "rock", true),
    rubble("ruins_rubble_vase", "ruins_vase",  nil, true)
