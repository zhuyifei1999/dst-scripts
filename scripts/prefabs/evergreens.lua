local assets =
{
    Asset("ANIM", "anim/evergreen_new.zip"), --build
    Asset("ANIM", "anim/evergreen_new_2.zip"), --build
    Asset("ANIM", "anim/evergreen_tall_old.zip"),
    Asset("ANIM", "anim/evergreen_short_normal.zip"),

    Asset("SOUND", "sound/forest.fsb"),
    Asset("MINIMAP_IMAGE", "evergreen_lumpy"),
}

local twiggy_assets =
{
    Asset("ANIM", "anim/twiggy_build.zip"), --build
    Asset("ANIM", "anim/twiggy_diseased_build.zip"), --build
    Asset("ANIM", "anim/twiggy_short_normal.zip"),
    Asset("ANIM", "anim/twiggy_tall_old.zip"),
    Asset("ANIM", "anim/twiggy_to_diseased.zip"),

    Asset("SOUND", "sound/forest.fsb"),
    Asset("MINIMAP_IMAGE", "twiggy"),
}

local prefabs =
{
    "log",
    "pinecone",
    "charcoal",
    "leif",
    "leif_sparse",
    "pine_needles_chop",
    "rock_petrified_tree_short",
    "rock_petrified_tree_med",
    "rock_petrified_tree_tall",
    "rock_petrified_tree_old",
    "disease_puff",
    "disease_fx_small",
    "disease_fx",
    "disease_fx_tall",
}

local twiggy_prefabs =
{
    "log",
    "twigs",
    "twiggy_nut",
    "charcoal",
    "disease_fx_small",
    "disease_fx",
    "disease_fx_tall",
    "diseaseflies",
    "green_leaves_chop",
}

SetSharedLootTable( 'diseaseTree',
{
    {'twigs',        0.125},
})

local builds =
{
    normal = {
        file="evergreen_new",
        file_bank = "evergreen_short",
        prefab_name="evergreen",
        regrowth_product="pinecone_sapling",
        regrowth_tuning=TUNING.EVERGREEN_REGROWTH,
        grow_times=TUNING.EVERGREEN_GROW_TIME,
        normal_loot = {"log", "log", "pinecone"},
        short_loot = {"log"},
        tall_loot = {"log", "log", "log", "pinecone", "pinecone"},
        drop_pinecones=true,
        leif="leif",
        chop_camshake_delay=0.4,
    },
    sparse = {
        file="evergreen_new_2",
        file_bank = "evergreen_short",
        prefab_name="evergreen_sparse",
        regrowth_product="lumpy_sapling",
        regrowth_tuning=TUNING.EVERGREEN_SPARSE_REGROWTH,
        grow_times=TUNING.EVERGREEN_GROW_TIME,
        normal_loot = {"log","log"},
        short_loot = {"log"},
        tall_loot = {"log", "log","log"},
        drop_pinecones=false,
        leif="leif_sparse",
        chop_camshake_delay=0.4,
    },
    twiggy = {
        file="twiggy_build",
        file_bank = "twiggy",
        file_disease = "twiggy_diseased_build",
        file_disease_bank = "twiggy",
        prefab_name="twiggytree",
        regrowth_product="twiggy_nut_sapling",
        regrowth_tuning=TUNING.EVERGREEN_REGROWTH,
        grow_times=TUNING.TWIGGY_TREE_GROW_TIME,
        normal_loot = {"log","twigs","twiggy_nut"},
        short_loot = {"twigs"},
        tall_loot = {"log", "twigs","twigs","twiggy_nut","twiggy_nut"},
        drop_pinecones=false,
        rebirth_loot = {loot="twigs", max=2},
        disease_fx = "green_leaves_chop",
        chop_camshake_delay=20*FRAMES,
    },
}

local function makeanims(stage)
    return {
        idle="idle_"..stage,
        sway1="sway1_loop_"..stage,
        sway2="sway2_loop_"..stage,
        chop="chop_"..stage,
        fallleft="fallleft_"..stage,
        fallright="fallright_"..stage,
        stump="stump_"..stage,
        burning="burning_loop_"..stage,
        burnt="burnt_"..stage,
        chop_burnt="chop_burnt_"..stage,
        idle_chop_burnt="idle_chop_burnt_"..stage,
        transform = "transform_"..stage,
    }
end

local short_anims = makeanims("short")
local tall_anims = makeanims("tall")
local normal_anims = makeanims("normal")
local old_anims =
{
    idle="idle_old",
    sway1="idle_old",
    sway2="idle_old",
    chop="chop_old",
    fallleft="chop_old",
    fallright="chop_old",
    stump="stump_old",
    burning="idle_olds",
    burnt="burnt_tall",
    chop_burnt="chop_burnt_tall",
    idle_chop_burnt="idle_chop_burnt_tall",
    transform="transform_old",
}

local function dig_up_stump(inst, chopper)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
end

local function chop_down_burnt_tree(inst, chopper)
    inst:RemoveComponent("workable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    if not chopper or (chopper and not chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    end
    inst.AnimState:PlayAnimation(inst.anims.chop_burnt)
    RemovePhysicsColliders(inst)
    inst:ListenForEvent("animover", inst.Remove)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    inst.components.lootdropper:DropLoot()
    if inst.pineconetask then
        inst.pineconetask:Cancel()
        inst.pineconetask = nil
    end
end

local function GetBuild(inst)
    return builds[inst.build] or builds["normal"]
end

local function OnBurnt(inst, immediate)
    local function changes()
        if inst.components.burnable ~= nil then
            inst.components.burnable:Extinguish()
        end
        inst:RemoveComponent("burnable")
        inst:RemoveComponent("propagator")
        inst:RemoveComponent("growable")
        inst:RemoveComponent("hauntable")
        inst:RemoveComponent("diseaseable")
        inst:RemoveTag("shelter")
        MakeHauntableWork(inst)

        inst.components.lootdropper:SetLoot({})
        if GetBuild(inst).drop_pinecones then
            inst.components.lootdropper:AddChanceLoot("pinecone", 0.1)
        end

        if GetBuild(inst).drop_pinecones_twiggy then
            inst.components.lootdropper:AddChanceLoot("twiggy_nut", 0.1)
        end

        if inst.components.workable then
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnWorkCallback(nil)
            inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
        end
    end

    if immediate then
        changes()
    else
        inst:DoTaskInTime( 0.5, changes)
    end
    inst.AnimState:PlayAnimation(inst.anims.burnt, true)

    inst.AnimState:SetRayTestOnBB(true)
    inst:AddTag("burnt")

    if inst.components.timer ~= nil and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(GetBuild(inst).regrowth_tuning.DEAD_DECAY_TIME, GetBuild(inst).regrowth_tuning.DEAD_DECAY_TIME*0.5))
    end
end

local function DoRebirthLoot(inst)
    local rebirth_loot = GetBuild(inst).rebirth_loot
    if rebirth_loot ~= nil then
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, 8)
        local numloot = 0
        for i,ent in ipairs(ents) do
            if ent.prefab == rebirth_loot.loot then
                numloot = numloot + 1
            end
        end
        local prob = 1-(numloot/rebirth_loot.max)
        if math.random() < prob then
            inst:DoTaskInTime(17*FRAMES, function()
                inst.components.lootdropper:SpawnLootPrefab(rebirth_loot.loot)
            end)
        end
        inst._lastrebirth = GetTime()
    end
end

local function PushSway(inst)
    if math.random() > .5 then
        inst.AnimState:PushAnimation(inst.anims.sway1, true)
    else
        inst.AnimState:PushAnimation(inst.anims.sway2, true)
    end
end

local function Sway(inst)
    if math.random() > .5 then
        inst.AnimState:PlayAnimation(inst.anims.sway1, true)
    else
        inst.AnimState:PlayAnimation(inst.anims.sway2, true)
    end
end

local function SetShort(inst)
    inst.anims = short_anims

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.EVERGREEN_CHOPS_SMALL)
    end

    inst.components.lootdropper:SetLoot(GetBuild(inst).short_loot)

    inst:AddTag("shelter")

    Sway(inst)
end

local function GrowShort(inst)
    inst.AnimState:PlayAnimation("grow_old_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    PushSway(inst)
    DoRebirthLoot(inst)
end

local function SetNormal(inst)
    inst.anims = normal_anims

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.EVERGREEN_CHOPS_NORMAL)
    end

    inst.components.lootdropper:SetLoot(GetBuild(inst).normal_loot)

    inst:AddTag("shelter")

    Sway(inst)
end

local function GrowNormal(inst)
    inst.AnimState:PlayAnimation("grow_short_to_normal")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    PushSway(inst)
end

local function SetTall(inst)
    inst.anims = tall_anims
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.EVERGREEN_CHOPS_TALL)
    end

    inst.components.lootdropper:SetLoot(GetBuild(inst).tall_loot)

    inst:AddTag("shelter")

    Sway(inst)
end

local function GrowTall(inst)
    inst.AnimState:PlayAnimation("grow_normal_to_tall")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    PushSway(inst)
end

local function SetOld(inst)
    inst.anims = old_anims

    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end

    if GetBuild(inst).drop_pinecones then
        inst.components.lootdropper:SetLoot({"pinecone"})
    elseif GetBuild(inst).drop_pinecones_twiggy then
        inst.components.lootdropper:SetLoot({"twiggy_nut"})
    else

        inst.components.lootdropper:SetLoot({})
    end

    inst:RemoveTag("shelter")

    Sway(inst)
end

local function GrowOld(inst)
    inst.AnimState:PlayAnimation("grow_tall_to_old")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeWilt")
    PushSway(inst)
end

local function inspect_tree(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst:HasTag("stump") and "CHOPPED")
        or (inst:HasTag("diseased") and "DISEASED")
        or nil
end

local growth_stages = {}
for build,data in pairs(builds) do
    growth_stages[build] =
    {
        {
            name="short",
            time = function(inst) return GetRandomWithVariance(data.grow_times[1].base, data.grow_times[1].random) end,
            fn = function(inst) SetShort(inst) end,
            growfn = function(inst) GrowShort(inst) end ,
            leifscale=.7
        },
        {
            name="normal",
            time = function(inst) return GetRandomWithVariance(data.grow_times[2].base, data.grow_times[2].random) end,
            fn = function(inst) SetNormal(inst) end,
            growfn = function(inst) GrowNormal(inst) end,
            leifscale=1
        },
        {
            name="tall",
            time = function(inst) return GetRandomWithVariance(data.grow_times[3].base, data.grow_times[3].random) end,
            fn = function(inst) SetTall(inst) end,
            growfn = function(inst) GrowTall(inst) end,
            leifscale=1.25
        },
        {
            name="old",
            time = function(inst) return GetRandomWithVariance(data.grow_times[4].base, data.grow_times[4].random) end,
            fn = function(inst) SetOld(inst) end,
            growfn = function(inst) GrowOld(inst) end
        },
    }
end

local function GetGrowthStages(inst)
    return growth_stages[inst.build] or growth_stages["normal"]
end

local function WakeUpLeif(ent)
    ent.components.sleeper:WakeUp()
end

local function chop_tree(inst, chopper, chops)
    if chopper == nil or not chopper:HasTag("playerghost") then
        inst.SoundEmitter:PlaySound(
            chopper ~= nil and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end

    inst.AnimState:PlayAnimation(inst.anims.chop)
    inst.AnimState:PushAnimation(inst.anims.sway1, true)

    if inst.build ~= "twiggy" then
        local x, y, z = inst.Transform:GetWorldPosition()
        SpawnPrefab("pine_needles_chop").Transform:SetPosition(x, y + math.random() * 2, z)

        --tell any nearby leifs to wake up
        local ents = TheSim:FindEntities(x, y, z, TUNING.LEIF_REAWAKEN_RADIUS, { "leif" })
        for i, v in ipairs(ents) do
            if v.components.sleeper ~= nil and v.components.sleeper:IsAsleep() then
                v:DoTaskInTime(math.random(), WakeUpLeif)
            end
            v.components.combat:SuggestTarget(chopper)
        end
    end
end

local function chop_down_tree_shake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .03,
        inst.components.growable ~= nil and
        inst.components.growable.stage > 2 and .5 or .25,
        inst, 6)
end

local function chop_down_twiggy_shake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .025,
        inst.components.growable ~= nil and
        inst.components.growable.stage > 2 and .14 or .07,
        inst, 6)
end

local function find_leif_spawn_target(item)
    return not item.noleif
        and item.components.growable ~= nil
        and item.components.growable.stage <= 3
end

local function spawn_leif(target)
    --assert(GetBuild(target).leif ~= nil)
    local leif = SpawnPrefab(GetBuild(target).leif)
    local scale = target.leifscale
    local r,g,b,a = target.AnimState:GetMultColour()
    leif.AnimState:SetMultColour(r,g,b,a)

    --we should serialize this?
    leif.components.locomotor.walkspeed = leif.components.locomotor.walkspeed*scale
    leif.components.combat.defaultdamage = leif.components.combat.defaultdamage*scale
    leif.components.combat.hitrange = leif.components.combat.hitrange*scale
    leif.components.combat.attackrange = leif.components.combat.attackrange*scale
    local maxhealth = leif.components.health.maxhealth*scale
    local currenthealth = leif.components.health.currenthealth*scale
    leif.components.health:SetMaxHealth(maxhealth)
    leif.components.health:SetCurrentHealth(currenthealth)

    leif.Transform:SetScale(scale,scale,scale)
    if target.chopper then leif.components.combat:SuggestTarget(target.chopper) end
    leif.sg:GoToState("spawn")
    target:Remove()

    leif.Transform:SetPosition(target.Transform:GetWorldPosition())
end

local function make_stump(inst)
    inst:RemoveComponent("burnable")
    MakeSmallBurnable(inst)
    MakeDragonflyBait(inst, 1)
    inst:RemoveComponent("propagator")
    MakeSmallPropagator(inst)
    inst:RemoveComponent("workable")
    inst:RemoveTag("shelter")
    inst:RemoveComponent("hauntable")
    MakeHauntableIgnite(inst)

    RemovePhysicsColliders(inst)

    inst:AddTag("stump")
    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    if inst.components.timer and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(GetBuild(inst).regrowth_tuning.DEAD_DECAY_TIME, GetBuild(inst).regrowth_tuning.DEAD_DECAY_TIME*0.5))
    end
end

local function finish_chop_down_diseased_tree(inst)
    SpawnPrefab("disease_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function chop_down_tree(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
    local pt = inst:GetPosition()

    local he_right = true

    if chopper then
        local hispos = chopper:GetPosition()
        he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
    else
        if math.random() > 0.5 then
            he_right = false
        end
    end

    if he_right then
        inst.AnimState:PlayAnimation(inst.anims.fallleft)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(inst.anims.fallright)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    if inst.build ~= "twiggy" then
        inst:DoTaskInTime(GetBuild(inst).chop_camshake_delay, chop_down_tree_shake)
    elseif inst.components.growable == nil or inst.components.growable.stage > 1 then
        inst:DoTaskInTime(GetBuild(inst).chop_camshake_delay, chop_down_twiggy_shake)
    end

    if inst.components.diseaseable ~= nil and inst.components.diseaseable:IsDiseased() then
        inst:AddTag("NOCLICK")
        inst.persists = false
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), finish_chop_down_diseased_tree)
    else
        make_stump(inst)
        inst.AnimState:PushAnimation(inst.anims.stump)

        if GetBuild(inst).leif ~= nil then
            local days_survived = TheWorld.state.cycles
            if days_survived >= TUNING.LEIF_MIN_DAY then
                if math.random() <= TUNING.LEIF_PERCENT_CHANCE then

                    local numleifs = 1
                    if days_survived > 30 then
                        numleifs = math.random(2)
                    elseif days_survived > 80 then
                        numleifs = math.random(3)
                    end

                    for k = 1,numleifs do
                        local target = FindEntity(inst, TUNING.LEIF_MAXSPAWNDIST, find_leif_spawn_target, { "evergreens", "tree" }, { "leif", "stump", "burnt" })
                        if target ~= nil then
                            target.noleif = true
                            target.leifscale = GetGrowthStages(target)[target.components.growable.stage].leifscale or 1
                            target.chopper = chopper
                            target:DoTaskInTime(1 + math.random() * 3, spawn_leif)
                        end
                    end
                end
            end
        end 
    end
end

local function onpineconetask(inst)
    local pt = inst:GetPosition()
    local angle = math.random() * 2 * PI
    pt.x = pt.x + math.cos(angle)
    pt.z = pt.z + math.sin(angle)
    inst.components.lootdropper:DropLoot(pt)
    inst.pineconetask = nil
    inst.burntcone = true
end

local function tree_burnt(inst)
    OnBurnt(inst)
    if not inst.burntcone then
        if inst.pineconetask ~= nil then
            inst.pineconetask:Cancel()
        end
        inst.pineconetask = inst:DoTaskInTime(10, onpineconetask)
    end
end

local function handler_growfromseed(inst)
    inst.components.growable:SetStage(1)
    inst.AnimState:PlayAnimation("grow_seed_to_short")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    PushSway(inst)
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end

    if inst:HasTag("stump") then
        data.stump = true
    end

    if inst.build ~= "normal" then
        data.build = inst.build
    end

    if inst._lastrebirth ~= nil then
        data.lastrebirth = inst._lastrebirth - GetTime()
    end

    data.burntcone = inst.burntcone
end

local function onload(inst, data)
    if data ~= nil then
        inst.build = data.build ~= nil and builds[data.build] ~= nil and data.build or "normal"

        if data.stump then
            make_stump(inst)
            inst.AnimState:PlayAnimation(inst.anims.stump)
            if data.burnt or inst:HasTag("burnt") then
                DefaultBurntFn(inst)
            end
        elseif data.burnt and not inst:HasTag("burnt") then
            OnBurnt(inst, true)
        end

        if not inst:IsValid() then
            return
        end

        if data.lastrebirth ~= nil then
            inst._lastrebirth = data.lastrebirth + GetTime()
        end

        inst.burntcone = data.burntcone
    end
end

local function OnEntitySleep(inst)
    local doBurnt = inst.components.burnable ~= nil and inst.components.burnable:IsBurning()
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("inspectable")
    if doBurnt then
        inst:AddTag("burnt")
    end
end

local function OnEntityWake(inst)
    if not inst:HasTag("burnt") and not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        if inst.components.burnable == nil then
            if inst:HasTag("stump") then
                MakeSmallBurnable(inst)
                MakeDragonflyBait(inst, 1)
            else
                MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
                MakeDragonflyBait(inst, 1)
                inst.components.burnable:SetFXLevel(5)
                inst.components.burnable:SetOnBurntFn(tree_burnt)
            end
        end

        if inst.components.propagator == nil then
            if inst:HasTag("stump") then
                MakeSmallPropagator(inst)
            else
                MakeMediumPropagator(inst)
            end
        end
    elseif inst:HasTag("burnt") then
        tree_burnt(inst)
    end

    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end

    if GetBuild(inst).rebirth_loot ~= nil then
        -- This is a failsafe because trees don't actually grow offscreen (or
        -- rather, never more than one stage) So this will cause trees that
        -- have been offscreen for multiple stages to drop some loot even if
        -- their growth hasn't reached there yet.
        local growthcycletime = 0
        for i,data in ipairs(GetBuild(inst).grow_times) do
            growthcycletime = growthcycletime + data.base
        end
        growthcycletime = growthcycletime
        if inst._lastrebirth + growthcycletime < GetTime() then
            DoRebirthLoot(inst)
        end
    end
end

local function OnTimerDone(inst, data)
    if data.name == "decay" then
        -- before we disappear, clean up any crap left on the ground -- too
        -- many objects is as bad for server health as too few!
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z,6)
        local leftone = false
        for k,ent in pairs(ents) do
            if ent.prefab == "log"
                or ent.prefab == "pinecone"
                or ent.prefab == "charcoal" then
                if leftone then
                    ent:Remove()
                else
                    leftone = true
                end
            end
        end

        inst:Remove()
    end
end

local STAGE_PETRIFY_PREFABS =
{
    "rock_petrified_tree_short",
    "rock_petrified_tree_med",
    "rock_petrified_tree_tall",
    "rock_petrified_tree_old",
}
local function dopetrify(inst, stage)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst:Remove()
    --remap anim
    local rock = SpawnPrefab(STAGE_PETRIFY_PREFABS[stage])
    if rock ~= nil then
        rock.Transform:SetPosition(x, 0, z)
        rock.SoundEmitter:PlaySound("dontstarve/common/together/petrified/post")
        SpawnPrefab(
            (stage > 2 and "disease_fx_tall") or
            (stage > 1 and "disease_fx") or
            "disease_fx_small"
        ).Transform:SetPosition(x, y, z)
    end
end

local STAGE_PETRIFY_ANIMS =
{
    "petrify_short",
    "petrify_normal",
    "petrify_tall",
    "petrify_old",
}
local function ondiseasedfn_evergreen(inst)
    if inst.components.growable ~= nil and not inst:HasTag("stump") then
        local stage = inst.components.growable.stage
        if STAGE_PETRIFY_ANIMS[stage] ~= nil then
            inst.AnimState:PlayAnimation(STAGE_PETRIFY_ANIMS[stage])
            inst.SoundEmitter:PlaySound("dontstarve/common/together/petrified/pre")
            inst:AddTag("NOCLICK")
            inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), dopetrify, stage)
            inst.components.diseaseable:Stop()
            return
        end
    end
    inst.components.diseaseable:ForceDeath()
end

local function ondiseaseddeathfn_evergreen(inst)
    --Should normally only reach here for stumps
    --Others would've petrified
    SpawnPrefab("disease_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function ondiseasedfn_twiggy(inst)
    inst.AnimState:SetBuild(GetBuild(inst).file_disease)
    local disease_bank = GetBuild(inst).file_disease_bank
    if disease_bank ~= nil then
        inst.AnimState:SetBank(disease_bank)
    end

    if inst:HasTag("stump") then
        ondiseaseddeathfn_evergreen(inst)
        return
    end

    inst.components.lootdropper:SetLoot({})
    inst.components.lootdropper:SetChanceLootTable('diseaseTree')

    if GetBuild(inst).disease_fx then
        local leaffx = SpawnPrefab(GetBuild(inst).disease_fx) 
        local x, y, z= inst.Transform:GetWorldPosition()
        if inst.components.growable and inst.components.growable.stage == 1 then
            y = y + 0 --Short FX height
        elseif inst.components.growable and inst.components.growable.stage == 2 then
            y = y + 0.3 --Normal FX height
        elseif inst.components.growable and inst.components.growable.stage == 3 then
            y = y + 1 --Tall FX height
        end
        leaffx.Transform:SetPosition(x,y,z)
    end

    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
        SpawnPrefab(
            (inst.components.growable.stage > 2 and "disease_fx_tall") or
            (inst.components.growable.stage > 1 and "disease_fx") or
            "disease_fx_small"
        ).Transform:SetPosition(inst.Transform:GetWorldPosition())
    else
        SpawnPrefab("disease_fx_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    inst.AnimState:PlayAnimation(inst.anims.transform)
    PushSway(inst)
end

local function onhauntwork(inst, haunter)
    if inst.components.workable ~= nil and math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
        inst.components.workable:WorkedBy(haunter, 1)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function onhauntevergreen(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_SUPERRARE and
        find_leif_spawn_target(inst) and
        not (inst:HasTag("burnt") or inst:HasTag("stump")) then

        inst.leifscale = GetGrowthStages(inst)[inst.components.growable.stage].leifscale or 1
        spawn_leif(inst)

        inst.components.hauntable.hauntvalue = TUNING.HAUNT_HUGE
        inst.components.hauntable.cooldown_on_successful_haunt = false
        return true
    end
    return onhauntwork(inst, haunter)
end

local function tree(name, build, stage, data)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .25)

        if build == "twiggy" then
            inst.MiniMapEntity:SetIcon("twiggy.png")
        else
            inst:AddTag("evergreens")
            if build == "normal" then
                inst.MiniMapEntity:SetIcon("evergreen.png")
            elseif build == "sparse" then
                inst.MiniMapEntity:SetIcon("evergreen_lumpy.png")
            end
        end

        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("tree")
        inst:AddTag("shelter")

        inst.build = build
        inst.AnimState:SetBuild(GetBuild(inst).file)

        inst.AnimState:SetBank(GetBuild(inst).file_bank)

        inst:SetPrefabName(GetBuild(inst).prefab_name)
        inst:AddTag(GetBuild(inst).prefab_name) -- used by regrowth

        MakeDragonflyBait(inst, 1)
        MakeSnowCoveredPristine(inst)

        if data == "stump" then
            RemovePhysicsColliders(inst)
            inst:AddTag("stump")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        local color = 0.5 + math.random() * 0.5
        inst.AnimState:SetMultColour(color, color, color, 1)

        -------------------
        MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(tree_burnt)
        MakeMediumPropagator(inst)

        -------------------
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        -------------------
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(chop_tree)
        inst.components.workable:SetOnFinishCallback(chop_down_tree)

        -------------------
        inst:AddComponent("lootdropper")

        ---------------------
        inst:AddComponent("growable")
        inst.components.growable.stages = GetGrowthStages(inst)
        inst.components.growable:SetStage(stage == 0 and math.random(1, 3) or stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()

        inst.growfromseed = handler_growfromseed

        ---------------------        
        inst:AddComponent("plantregrowth")
        inst.components.plantregrowth:SetRegrowthRate(GetBuild(inst).regrowth_tuning.OFFSPRING_TIME)
        inst.components.plantregrowth:SetProduct(GetBuild(inst).regrowth_product)
        inst.components.plantregrowth:SetSearchTag(GetBuild(inst).prefab_name)

        ---------------------
        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)

        ---------------------
        inst:AddComponent("diseaseable")
        if build == "twiggy" then
            inst.components.diseaseable:SetDiseasedFn(ondiseasedfn_twiggy)
            inst.components.diseaseable:SetRebirthedFn(SetShort)
            inst.components.diseaseable:SetDiseasedDeathFn(chop_down_tree)
        else
            inst.components.diseaseable:SetDefaultDelayRange(TUNING.SEG_TIME, TUNING.SEG_TIME * 1.3)
            inst.components.diseaseable:SetDiseasedFn(ondiseasedfn_evergreen)
            inst.components.diseaseable:SetDiseasedDeathFn(ondiseaseddeathfn_evergreen)
        end

        ---------------------
        --PushSway(inst)

        ---------------------

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(build == "twiggy" and onhauntevergreen or onhauntwork)

        ---------------------

        inst.OnSave = onsave
        inst.OnLoad = onload

        MakeSnowCovered(inst)
        ---------------------

        if GetBuild(inst).rebirth_loot ~= nil then
            inst._lastrebirth = 0
            for i,time in ipairs(GetBuild(inst).grow_times) do
                if i == inst.components.growable.stage then
                    break
                end
                inst._lastrebirth = inst._lastrebirth - time.base
            end
        end

        if data == "stump" then
            inst:RemoveComponent("burnable")
            MakeSmallBurnable(inst)
            inst:RemoveComponent("workable")
            inst:RemoveComponent("propagator")
            MakeSmallPropagator(inst)
            inst:RemoveComponent("growable")
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.DIG)
            inst.components.workable:SetOnFinishCallback(dig_up_stump)
            inst.components.workable:SetWorkLeft(1)
            inst.AnimState:PlayAnimation(inst.anims.stump)
        else
            inst.AnimState:SetTime(math.random() * 2)
            if data == "burnt" then
                OnBurnt(inst)
            end
        end

        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake

        return inst
    end

    return build == "twiggy"
        and Prefab(name, fn, twiggy_assets, twiggy_prefabs)
        or Prefab(name, fn, assets, prefabs)
end

return  tree("evergreen", "normal", 0),
        tree("evergreen_normal", "normal", 2),
        tree("evergreen_tall", "normal", 3),
        tree("evergreen_short", "normal", 1),
        tree("evergreen_sparse", "sparse", 0),
        tree("evergreen_sparse_normal", "sparse", 2),
        tree("evergreen_sparse_tall", "sparse", 3),
        tree("evergreen_sparse_short", "sparse", 1),

        tree("twiggytree", "twiggy", 0),
        tree("twiggy_normal", "twiggy", 2),
        tree("twiggy_tall", "twiggy", 3),
        tree("twiggy_short", "twiggy", 1),
        tree("twiggy_old", "twiggy", 4),

        tree("evergreen_burnt", "normal", 0, "burnt"),
        tree("evergreen_stump", "normal", 0, "stump")
