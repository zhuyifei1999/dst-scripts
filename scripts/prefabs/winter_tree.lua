require "prefabs/winter_ornaments"

-- forward delcaration
local queuegifting

local prefabs = GetAllWinterOrnamentPrefabs()
table.insert(prefabs, "charcoal")
table.insert(prefabs, "ash")
table.insert(prefabs, "collapse_small")
table.insert(prefabs, "gift")

local statedata =
{
    { -- empty
        idleanim    = "idle",
        loot        = function(inst) return {inst.seedprefab, "boards", "poop"} end,
        burntloot   = function(inst) return {"boards", "poop"} end,
        burntanim   = "burnt",
        burnfxlevel = 3,
    },
    { -- sapling
        idleanim    = "idle_sapling",
        burntanim   = "burnt",
        growsound   = "dontstarve/forest/treeGrow", 
        workleft    = 1,
        workaction  = "HAMMER",
        growsound   = "dontstarve/wilson/plant_tree",
        loot        = function(inst) return {inst.seedprefab, "boards", "poop"} end,
        burntloot   = function(inst) return {"ash", "boards", "poop"} end,
        burnfxlevel = 3,
    },
    { -- short
        idleanim    = "idle_short",
        sway1anim   = "sway1_loop_short",
        sway2anim   = "sway2_loop_short",
        hitanim     = "chop_short",
        breakrightanim = "fallright_short",
        breakleftanim  = "fallleft_short",
        burntbreakanim = "chop_burnt_short",
        burntanim   = "burnt_short",
        growanim    = "grow_sapling_to_short",
        growsound   = "dontstarve/forest/treeGrow", 
        workleft    = TUNING.WINTER_TREE_CHOP_SMALL,
        workaction  = "CHOP",
        loot        = function(inst) return {"log", "boards", "poop"} end,
        burntloot   = function(inst) return {"charcoal", "boards", "poop"} end,
        burnfxlevel = 4,
        burntree    = true,
    },
    { -- normal
        idleanim    = "idle_normal",
        sway1anim   = "sway1_loop_normal",
        sway2anim   = "sway2_loop_normal",
        hitanim     = "chop_normal",
        breakrightanim = "fallright_normal",
        breakleftanim  = "fallleft_normal",
        burntbreakanim = "chop_burnt_normal",
        burntanim   = "burnt_normal",
        growanim    = "grow_short_to_normal",
        growsound   = "dontstarve/forest/treeGrow", 
        workleft    = TUNING.WINTER_TREE_CHOP_NORMAL,
        workaction  = "CHOP",
        loot        = function(inst) return {"log", "log", inst.seedprefab, "boards", "poop"} end,
        burntloot   = function(inst) return {"charcoal", "boards", "poop"} end,
        burnfxlevel = 4,
        burntree    = true,
    },
    { -- tall
        idleanim    = "idle_tall",
        sway1anim   = "sway1_loop_tall",
        sway2anim   = "sway2_loop_tall",
        hitanim     = "chop_tall",
        breakrightanim = "fallright_tall",
        breakleftanim  = "fallleft_tall",
        burntbreakanim = "chop_burnt_tall",
        burntanim   = "burnt_tall",
        growanim    = "grow_normal_to_tall",
        growsound   = "dontstarve/forest/treeGrow", 
        workleft    = TUNING.WINTER_TREE_CHOP_TALL,
        workaction  = "CHOP",
        loot        = function(inst) return {"log", "log", "log", inst.seedprefab, "boards", "poop"} end,
        burntloot   = function(inst) return {"charcoal", "charcoal", inst.seedprefab, "boards", "poop"} end,
        burnfxlevel = 4,
        burntree    = true,
    },
}

-------------------------------------------------------------------------------
local function PushSway(inst)
    if inst.statedata.sway1anim ~= nil then
        inst.AnimState:PushAnimation(math.random() > .5 and inst.statedata.sway1anim or inst.statedata.sway2anim, true)
    else
        inst.AnimState:PushAnimation(inst.statedata.idleanim, false)
    end
end

local function PlaySway(inst)
    if inst.statedata.sway1anim ~= nil then
        inst.AnimState:PlayAnimation(math.random() > .5 and inst.statedata.sway1anim or inst.statedata.sway2anim, true)
    else
        inst.AnimState:PlayAnimation(inst.statedata.idleanim, false)
    end
end

-------------------------------------------------------------------------------
-- Tree Decor

local light_str =
{
    {radius = 3.25, falloff = .85, intensity = 0.75},
}

local function IsLightOn(inst)
    return inst.Light:IsEnabled()
end

local function UpdateLights(inst, light)
    local was_on = IsLightOn(inst)

    local batteries = inst.forceoff ~= true and inst.components.container:FindItems( function(item) return item:HasTag("lightbattery") end ) or {}

    local lightcolour = Vector3(0,0,0)
    local num_lights_on = 0
    for i, v in ipairs(batteries) do
        if v.ornamentlighton then
            lightcolour = lightcolour + Vector3(v.Light:GetColour())
            num_lights_on = num_lights_on + 1
        end
    end

    if light ~= nil then
        local slot = inst.components.container:GetItemSlot(light)
        if slot ~= nil then
            inst.AnimState:OverrideSymbol("plain"..slot, "winter_ornaments", light.winter_ornamentid..(light.ornamentlighton and "_on" or "_off"))
        end
    end

    if num_lights_on == 0 then
        if was_on then
            inst.Light:Enable(false)
            inst.AnimState:ClearBloomEffectHandle()
            inst.AnimState:SetLightOverride(0)
        end
    else
        if not was_on then
            inst.Light:Enable(true)
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
            inst.AnimState:SetLightOverride(0.2)
        end

        inst.Light:SetRadius(light_str[1].radius)
        inst.Light:SetFalloff(light_str[1].falloff)
        inst.Light:SetIntensity(light_str[1].intensity)

        lightcolour:Normalize()
        inst.Light:SetColour(lightcolour.x, lightcolour.y, lightcolour.z)
    end
end

local function RemoveDecor(inst, data)
    inst.AnimState:ClearOverrideSymbol("plain"..data.slot)
    UpdateLights(inst)
end

local function AddDecor(inst, data)
    if inst:HasTag("burnt") or data == nil or data.slot == nil or data.item == nil or data.item.winter_ornamentid == nil then
        return
    end

    if data.item.ornamentlighton ~= nil then
        UpdateLights(inst, data.item)
    else
        inst.AnimState:OverrideSymbol("plain"..data.slot, "winter_ornaments", data.item.winter_ornamentid)
    end
    
end

-------------------------------------------------------------------------------
local GIFTING_PLAYER_RADIUS_SQ = 25*25

local random_gift =
{
    flint = 1,
    moonrocknugget = 1,
    silk = 1,
    nitre = 1,
    gears = .5,
    bluegem = .5,
    compass = .5,
    redgem = .5,
    orangegem = .1,
}

local function NobodySeesPoint(pt)
    for i, v in ipairs(AllPlayers) do
        if CanEntitySeePoint(v, pt.x, pt.y, pt.z) then
            return false
        end
    end
    return true
end

local function NoOverlap(pt)
    return NobodySeesPoint(pt) and #TheSim:FindEntities(pt.x, 0, pt.z, .75, nil, { "INLIMBO" }) <= 0
end

local function dogifting(inst)
    if TheWorld.state.isnight then
        local players = {}
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(AllPlayers) do
            if v:GetDistanceSqToPoint(x, y, z) < GIFTING_PLAYER_RADIUS_SQ then
                table.insert(players, v)
            end
        end

        if #players > 0 then
            local days_since_last_gift = inst.previousgiftday == nil and 100 or (TheWorld.state.cycles - inst.previousgiftday)
            inst.previousgiftday = TheWorld.state.cycles

            local num_ornaments = inst.components.container:NumItems()

            --print("dogifting! ", num_players, days_since_last_gift, TheWorld.state.cycles, num_ornaments)

            for _, player in ipairs(players) do
                local loot = {}
                if days_since_last_gift > 4 then
                    table.insert(loot, { prefab = "winter_food".. math.random(NUM_WINTERFOOD), stack = 4 })
                    table.insert(loot, { prefab = PickRandomTrinket() })
                    table.insert(loot, { prefab = weighted_random_choice(random_gift) })

                    if num_ornaments == inst.components.container:GetNumSlots() and math.random() < 0.10 then
                        table.insert(loot, { prefab = GetRandomBasicWinterOrnament() })
                    end
                else
                    table.insert(loot, { prefab = "winter_food".. math.random(NUM_WINTERFOOD)})
                    table.insert(loot, { prefab = "charcoal" })
                end

                local items = {}
                for i, v in ipairs(loot) do
                    local item = SpawnPrefab(v.prefab)
                    if item ~= nil then
                        if item.components.stackable ~= nil then
                            item.components.stackable.stacksize = math.max(1, v.stack or 1)
                        end
                        table.insert(items, item)
                    end
                end
                if #items > 0 then
                    local gift = SpawnPrefab("gift")
                    gift.components.unwrappable:WrapItems(items)
                    for i, v in ipairs(items) do
                        v:Remove()
                    end
                    local pos = inst:GetPosition()
                    local radius = inst.Physics:GetRadius() + .7 + math.random() * .5
                    local theta = inst:GetAngleToPoint(player.Transform:GetWorldPosition()) * DEGREES
                    local offset =
                        FindWalkableOffset(pos, theta, radius, 8, false, true, NoOverlap) or
                        FindWalkableOffset(pos, theta, radius + .5, 8, false, true, NoOverlap) or
                        FindWalkableOffset(pos, theta, radius, 8, false, true, NobodySeesPoint) or
                        FindWalkableOffset(pos, theta, radius + .5, 8, false, true, NobodySeesPoint)
                    if offset ~= nil then
                        gift.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
                    else
                        inst.components.lootdropper:FlingItem(gift)
                    end
                end

                if inst.forceoff then
                    inst:DoTaskInTime(1, function() inst.forceoff = false end, inst)
                end

                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bell")
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/chain")
                inst.SoundEmitter:PlaySound("dontstarve/common/dropGeneric")

                return true
            end
        end
    end
end

local function trygifting(inst)
    inst.giftingtask = nil

    --print("trygifting")

    if TheWorld.state.isnight and inst.components.container ~= nil and not inst.components.container:IsEmpty() then
        local x, y, z = inst.Transform:GetWorldPosition()

        local players_near = {}
        for i, v in ipairs(AllPlayers) do
            if v:GetDistanceSqToPoint(x, y, z) < GIFTING_PLAYER_RADIUS_SQ then
                table.insert(players_near, v)
            end
        end

        local all_players_sleeping = true
        if #players_near > 0 then
            for i, v in ipairs(players_near) do
                if not v:HasTag("sleeping") then
                    all_players_sleeping = false
                    break
                end
            end

            if all_players_sleeping then
                local tree_is_visible = false
                for i, v in ipairs(players_near) do
                    if CanEntitySeePoint(v, x, y, z) then
                        tree_is_visible = true
                        break
                    end
                end

                if tree_is_visible then
                    local batteries = inst.components.container:FindItems( function(item) return item:HasTag("lightbattery") end )
                    if #batteries > 0 then
                        inst.forceoff = true
                        UpdateLights(inst)

                        inst.giftingtask = inst:DoTaskInTime(.2, trygifting, inst)
                        return
                    end
                else
                    if dogifting(inst) then
                        return
                    end
                end
            end
        end

        inst.forceoff = false
        queuegifting(inst)
    end
end

queuegifting = function(inst)
    if TheWorld.state.isnight and inst.components.container ~= nil and not inst.components.container:IsEmpty()  and inst.giftingtask == nil then
        --print("queuegifting")

        inst.giftingtask = inst:DoTaskInTime(2, trygifting, inst)
    end
end

-------------------------------------------------------------------------------
local function SetGrowth(inst)
    local new_size = inst.components.growable.stage
    inst.statedata = statedata[new_size]
    PlaySway(inst)

    inst.components.workable:SetWorkAction(ACTIONS[inst.statedata.workaction])
    inst.components.workable:SetWorkLeft(inst.statedata.workleft)

    inst.components.burnable:SetFXLevel(inst.statedata.burnfxlevel)
    inst.components.burnable:SetBurnTime(inst.statedata.burntree and TUNING.TREE_BURN_TIME or 20)

    if new_size == #statedata then
        inst.components.container.canbeopened = true
        inst.components.growable:StopGrowing()

        inst:WatchWorldState("isnight", queuegifting)
    end
end

local function DoGrow(inst)
    if inst.statedata.growanim ~= nil then
        inst.AnimState:PlayAnimation(inst.statedata.growanim)
    end
    if inst.statedata.growsound ~= nil then
        inst.SoundEmitter:PlaySound(inst.statedata.growsound)
    end

    PushSway(inst)
end

local GROWTH_STAGES =
{
    {
        time = function(inst) return 0 end,
        fn = SetGrowth,
        growfn = function() end,
    },
    {
        time = function(inst) return GetRandomWithVariance(TUNING.WINTER_TREE_GROW_TIME[2].base, TUNING.WINTER_TREE_GROW_TIME[2].random) end,
        fn = SetGrowth,
        growfn = DoGrow,
    },
    {
        time = function(inst) return GetRandomWithVariance(TUNING.WINTER_TREE_GROW_TIME[3].base, TUNING.WINTER_TREE_GROW_TIME[3].random) end,
        fn = SetGrowth,
        growfn = DoGrow,
    },
    {
        time = function(inst) return GetRandomWithVariance(TUNING.WINTER_TREE_GROW_TIME[4].base, TUNING.WINTER_TREE_GROW_TIME[4].random) end,
        fn = SetGrowth,
        growfn = DoGrow,
    },
    {
        time = function(inst) return GetRandomWithVariance(TUNING.WINTER_TREE_GROW_TIME[5].base, TUNING.WINTER_TREE_GROW_TIME[5].random) end,
        fn = SetGrowth,
        growfn = DoGrow,
    },
}

local function lootsetfn(lootdropper)
    lootdropper:SetLoot(lootdropper.inst:HasTag("burnt") and lootdropper.inst.statedata.burntloot(lootdropper.inst) or lootdropper.inst.statedata.loot(lootdropper.inst))
end

local function onworked(inst, worker, workleft)
    if workleft > 0 then
        inst.AnimState:PlayAnimation(inst.statedata.hitanim)
        PushSway(inst)

        if not (worker ~= nil and worker:HasTag("playerghost")) then
            inst.SoundEmitter:PlaySound(
                worker ~= nil and worker:HasTag("beaver") and
                "dontstarve/characters/woodie/beaver_chop_tree" or
                "dontstarve/wilson/use_axe_tree"
            )
        end

    else
        if inst:HasTag("burnt") then
            if inst.statedata.burntbreakanim ~= nil then
                inst.AnimState:PlayAnimation(inst.statedata.burntbreakanim)
                inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
                if not (worker ~= nil and worker:HasTag("playerghost")) then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
                end

                inst.persists = false
                inst:AddTag("NOCLICK")
                inst:DoTaskInTime(1.5, ErodeAway)
            else
                inst.components.lootdropper:DropLoot()
                local fx = SpawnPrefab("collapse_small")
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                fx:SetMaterial("wood")
                inst:Remove()
            end

            inst.components.lootdropper:DropLoot()
        else
            local fx = SpawnPrefab("collapse_small")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            fx:SetMaterial("wood")

            inst.components.lootdropper:DropLoot()
            if inst.components.container ~= nil then
                inst.components.container:DropEverything()
                inst.components.container:Close()
            end

            if inst.statedata.breakrightanim ~= nil then
                inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

                local worker_is_to_right = worker and ((worker:GetPosition() - inst:GetPosition()):Dot(TheCamera:GetRightVec()) > 0) or (math.random() > 0.5)
                inst.AnimState:PlayAnimation(worker_is_to_right and inst.statedata.breakleftanim or inst.statedata.breakrightanim)

                inst:ListenForEvent("animover", inst.Remove)
                inst.persists = false
            else
                inst:Remove()
            end
        end
    end
end

-------------------------------------------------------------------------------
local function getstatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst:HasTag("fire") and "BURNING")
        or (inst.components.growable.stage == #statedata and "CANDECORATE")
        or "YOUNG"
end

local function onburnt(inst)
    DefaultBurntStructureFn(inst)

    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
    end

    inst.AnimState:PlayAnimation(inst.statedata.burntanim)
end

-------------------------------------------------------------------------------
local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end

    data.previousgiftday = inst.previousgiftday
end

local function onload(inst, data)
    if data ~= nil then
        inst.previousgiftday = data.previousgiftday
    end
end

local function onloadpostpass(inst, ents, data)
    inst.statedata = statedata[inst.components.growable.stage]

    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    else
        PlaySway(inst)
        inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())

        queuegifting(inst)
    end
end

local function onentitywake(inst)
    if inst.giftingtask ~= nil then
        inst.giftingtask:Cancel()
        inst.giftingtask = nil
    end

    queuegifting(inst)
end

local function onentitysleep(inst)
    if inst.giftingtask ~= nil then
        inst.giftingtask:Cancel()
        inst.giftingtask = nil
    end
end

local function MakeWinterTree(treetype)
    local assets =
    {
        Asset("ANIM", "anim/wintertree.zip"),
        Asset("ANIM", "anim/wintertree_build.zip"),
        Asset("ANIM", "anim/"..treetype.build..".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()  
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()
        inst.entity:AddLight()

        MakeObstaclePhysics(inst, 0.5)

        inst.MiniMapEntity:SetIcon(treetype.name..".png")
        inst.MiniMapEntity:SetPriority(-1)

        inst.AnimState:SetBank(treetype.bank)
        inst.AnimState:SetBuild(treetype.build)
        inst.AnimState:AddOverrideBuild("wintertree_build")
        inst.AnimState:PlayAnimation("idle")

        inst.Light:Enable(false)

        MakeSnowCoveredPristine(inst)
        inst:AddTag("winter_tree")
        inst:AddTag("structure")
        inst:AddTag("fridge")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.statedata = statedata[1]
        inst.seedprefab = treetype.seedprefab

        inst:AddComponent("growable")
        inst.components.growable.stages = GROWTH_STAGES
        inst.components.growable.loopstages = false

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLootSetupFn(lootsetfn)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(onworked)

        inst:AddComponent("container")
        inst.components.container:WidgetSetup("winter_tree")
        inst.components.container.canbeopened = false

        inst:AddComponent("timer")

        ---------------------
        MakeHauntableWork(inst)
        MakeSnowCovered(inst)
        MakeMediumBurnable(inst, nil, nil, true)
        MakeMediumPropagator(inst)
        inst.components.burnable:SetOnBurntFn(onburnt)

        inst.OnSave = onsave
        inst.OnLoad = onload
        inst.OnLoadPostPass = onloadpostpass

        inst.components.growable:SetStage(1)

        inst:ListenForEvent("itemget", AddDecor)
        inst:ListenForEvent("itemlose", RemoveDecor)
        inst:ListenForEvent("updatelight", UpdateLights)

        inst.OnEntitySleep = onentitysleep
        inst.OnEntityWake = onentitywake

        return inst
    end

    return Prefab(treetype.name, fn, assets, prefabs)
end

local treetype =
{
    { name = "winter_tree", bank = "wintertree", build = "evergreen_new", seedprefab = "pinecone" },
}

for _, v in ipairs(treetype) do
    table.insert(prefabs, v.seedprefab)
end

return MakeWinterTree(treetype[1])
