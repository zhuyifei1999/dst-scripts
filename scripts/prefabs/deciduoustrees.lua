local assets =
{
    Asset("ANIM", "anim/tree_leaf_short.zip"),
    Asset("ANIM", "anim/tree_leaf_normal.zip"),
    Asset("ANIM", "anim/tree_leaf_tall.zip"),
    Asset("ANIM", "anim/tree_leaf_monster.zip"),
    Asset("ANIM", "anim/tree_leaf_trunk_build.zip"), --trunk build (winter leaves build)
    Asset("ANIM", "anim/tree_leaf_green_build.zip"), --spring, summer leaves build
    Asset("ANIM", "anim/tree_leaf_red_build.zip"), --autumn leaves build
    Asset("ANIM", "anim/tree_leaf_orange_build.zip"), --autumn leaves build
    Asset("ANIM", "anim/tree_leaf_yellow_build.zip"), --autumn leaves build
    Asset("ANIM", "anim/tree_leaf_poison_build.zip"), --poison leaves build
    Asset("SOUND", "sound/forest.fsb"),
    Asset("SOUND", "sound/decidous.fsb"),
    Asset("MINIMAP_IMAGE", "tree_leaf"),
    Asset("MINIMAP_IMAGE", "tree_leaf_burnt"),
    Asset("MINIMAP_IMAGE", "tree_leaf_stump"),
}

local prefabs =
{
    "log",
    "twigs",
    "acorn",
    "charcoal",
    "green_leaves",
    "red_leaves",
    "orange_leaves",
    "yellow_leaves",
    "purple_leaves",
    "green_leaves_chop",
    "red_leaves_chop",
    "orange_leaves_chop",
    "yellow_leaves_chop",
    "purple_leaves_chop",
    "deciduous_root",
    "livinglog",
    "nightmarefuel",
    "spoiled_food",
    "birchnutdrake"
}

local builds =
{
    normal = { --Green
        leavesbuild="tree_leaf_green_build",
        prefab_name="deciduoustree",
        normal_loot = {"log", "log"},
        short_loot = {"log"},
        tall_loot = {"log", "log", "log", "acorn"},
        drop_acorns=true,
        fx="green_leaves",
        chopfx="green_leaves_chop",
        shelter=true,
    },
    barren = {
        leavesbuild=nil,
        prefab_name="deciduoustree",
        normal_loot = {"log", "log"},
        short_loot = {"log"},
        tall_loot = {"log", "log", "log"},
        drop_acorns=false,
        fx=nil,
        chopfx=nil,
        shelter=false,
    },
    red = {
        leavesbuild="tree_leaf_red_build",
        prefab_name="deciduoustree",
        normal_loot = {"log", "log"},
        short_loot = {"log"},
        tall_loot = {"log", "log", "log", "acorn"},
        drop_acorns=true,
        fx="red_leaves",
        chopfx="red_leaves_chop",
        shelter=true,
    },
    orange = {
        leavesbuild="tree_leaf_orange_build",
        prefab_name="deciduoustree",
        normal_loot = {"log", "log"},
        short_loot = {"log"},
    tall_loot = {"log", "log", "log", "acorn"},
        drop_acorns=true,
        fx="orange_leaves",
        chopfx="orange_leaves_chop",
        shelter=true,
    },
    yellow = {
        leavesbuild="tree_leaf_yellow_build",
        prefab_name="deciduoustree",
        normal_loot = {"log", "log"},
        short_loot = {"log"},
        tall_loot = {"log", "log", "log", "acorn"},
        drop_acorns=true,
        fx="yellow_leaves",
        chopfx="yellow_leaves_chop",
        shelter=true,
    },
    poison = {
        leavesbuild="tree_leaf_poison_build",
        prefab_name="deciduoustree",
        normal_loot = {"livinglog", "acorn", "acorn"},
        short_loot = {"livinglog", "acorn"},
        tall_loot = {"livinglog", "acorn", "acorn", "acorn"},
        drop_acorns=true,
        fx="purple_leaves",
        chopfx="purple_leaves_chop",
        shelter=true,
    },
}

local function makeanims(stage)
    if stage == "monster" then
        return {
            idle="idle_tall",
            sway1="sway_loop_agro",
            sway2="sway_loop_agro",
            swayaggropre="sway_agro_pre",
            swayaggro="sway_loop_agro",
            swayaggropst="sway_agro_pst",
            swayaggroloop="idle_loop_agro",
            swayfx="swayfx_tall",
            chop="chop_tall_monster",
            fallleft="fallleft_tall_monster",
            fallright="fallright_tall_monster",
            stump="stump_tall_monster",
            burning="burning_loop_tall",
            burnt="burnt_tall",
            chop_burnt="chop_burnt_tall",
            idle_chop_burnt="idle_chop_burnt_tall",
            dropleaves = "drop_leaves_tall",
            growleaves = "grow_leaves_tall",
        }
    else
        return {
            idle="idle_"..stage,
            sway1="sway1_loop_"..stage,
            sway2="sway2_loop_"..stage,
            swayaggropre="sway_agro_pre",
            swayaggro="sway_loop_agro",
            swayaggropst="sway_agro_pst",
            swayaggroloop="idle_loop_agro",
            swayfx="swayfx_"..stage,
            chop="chop_"..stage,
            fallleft="fallleft_"..stage,
            fallright="fallright_"..stage,
            stump="stump_"..stage,
            burning="burning_loop_"..stage,
            burnt="burnt_"..stage,
            chop_burnt="chop_burnt_"..stage,
            idle_chop_burnt="idle_chop_burnt_"..stage,
            dropleaves = "drop_leaves_"..stage,
            growleaves = "grow_leaves_"..stage,
        }
    end
end

local short_anims = makeanims("short")
local tall_anims = makeanims("tall")
local normal_anims = makeanims("normal")
local monster_anims = makeanims("monster")

local function GetBuild(inst)
    local build = builds[inst.build]
    if build == nil then
        return builds["normal"]
    end
    return build
end

local function SpawnLeafFX(inst, waittime, chop)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or
        inst:HasTag("stump") or
        inst:HasTag("burnt") or
        inst:IsAsleep() then
        return
    end
    if waittime then
        inst:DoTaskInTime(waittime, function(inst, chop) SpawnLeafFX(inst, nil, chop) end)
        return
    end

    local fx = nil
    if chop then 
        if GetBuild(inst).chopfx then fx = SpawnPrefab(GetBuild(inst).chopfx) end
    else
        if GetBuild(inst).fx then fx = SpawnPrefab(GetBuild(inst).fx) end
    end
    if fx then
        local x, y, z= inst.Transform:GetWorldPosition()
        if inst.components.growable and inst.components.growable.stage == 1 then
            y = y + 0 --Short FX height
        elseif inst.components.growable and inst.components.growable.stage == 2 then
            y = y - .3 --Normal FX height
        elseif inst.components.growable and inst.components.growable.stage == 3 then
            y = y + 0 --Tall FX height
        end
        if chop then y = y + (math.random()*2) end --Randomize height a bit for chop FX
        fx.Transform:SetPosition(x,y,z)
    end
end

local function PushSway(inst, monster, monsterpost, skippre)
    if monster then
        inst.sg:GoToState("gnash_pre", {push=true, skippre=skippre})
    else
        if monsterpost then
            if inst.sg:HasStateTag("gnash") then
                inst.sg:GoToState("gnash_pst")
            else
                inst.sg:GoToState("gnash_idle")
            end
        else   
            if inst.monster then 
                inst.sg:GoToState("gnash_idle")
            else    
                if math.random() > .5 then
                    inst.AnimState:PushAnimation(inst.anims.sway1, true)
                else
                    inst.AnimState:PushAnimation(inst.anims.sway2, true)
                end
            end
        end
    end
end

local function Sway(inst, monster, monsterpost)
    if inst.sg:HasStateTag("burning") or inst:HasTag("stump") then return end
    if monster then
        inst.sg:GoToState("gnash_pre", {push=false, skippre=false})
    else
        if monsterpost then
            if inst.sg:HasStateTag("gnash") then
                inst.sg:GoToState("gnash_pst")
            else
                inst.sg:GoToState("gnash_idle")
            end
        else
            if inst.monster then 
                inst.sg:GoToState("gnash_idle")
            else
                if math.random() > .5 then
                    inst.AnimState:PlayAnimation(inst.anims.sway1, true)
                else
                    inst.AnimState:PlayAnimation(inst.anims.sway2, true)
                end
            end
        end
    end
end

local function GrowLeavesFn(inst, monster, monsterout)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or
        inst:HasTag("stump") or
        inst:HasTag("burnt") then
        inst:RemoveEventCallback("animover", GrowLeavesFn)
        return
    end

    if inst.leaf_state == "barren" or inst.target_leaf_state == "barren" then 
        inst:RemoveEventCallback("animover", GrowLeavesFn)
        if inst.target_leaf_state == "barren" then inst.build = "barren" end
    end

    if GetBuild(inst).leavesbuild then
        inst.AnimState:OverrideSymbol("swap_leaves", GetBuild(inst).leavesbuild, "swap_leaves")
    else
        inst.AnimState:ClearOverrideSymbol("swap_leaves")
    end

    if inst.components.growable then
        if inst.components.growable.stage == 1 then
            inst.components.lootdropper:SetLoot(GetBuild(inst).short_loot)
        elseif inst.components.growable.stage == 2 then
            inst.components.lootdropper:SetLoot(GetBuild(inst).normal_loot)
        else
            inst.components.lootdropper:SetLoot(GetBuild(inst).tall_loot)
        end
    end

    inst.leaf_state = inst.target_leaf_state
    if inst.leaf_state == "barren" then
        inst.AnimState:Hide("mouseover")
    else
        if inst.build == "barren" then
            inst.build = (inst.leaf_state == "normal") and "normal" or "red"
        end
        inst.AnimState:Show("mouseover")
    end

    if monster ~= true and monsterout ~= true then
        Sway(inst)
    end
end

local function OnChangeLeaves(inst, monster, monsterout)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or
        inst:HasTag("stump") or
        inst:HasTag("burnt") then
        inst.targetleaveschangetime = nil
        inst.leaveschangetask = nil
        return
    end
    if not monster and inst.components.workable and inst.components.workable.lastworktime and inst.components.workable.lastworktime < GetTime() - 10 then
        inst.targetleaveschangetime = GetTime() + 11
        inst.leaveschangetask = inst:DoTaskInTime(11, OnChangeLeaves)
        return
    else
        inst.targetleaveschangetime = nil
        inst.leaveschangetask = nil
    end

    if inst.target_leaf_state ~= "barren" then
        if inst.target_leaf_state == "colorful" then
            local rand = math.random()
            if rand < .33 then
                inst.build = "red"
            elseif rand < .67 then
                inst.build = "orange"
            else
                inst.build = "yellow"
            end
            inst.AnimState:SetMultColour(1, 1, 1, 1)
        elseif inst.target_leaf_state == "poison" then
            inst.AnimState:SetMultColour(1, 1, 1, 1)
            inst.build = "poison"
        else
            inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
            inst.build = "normal"
        end

        if inst.leaf_state == "barren" then
            if GetBuild(inst).leavesbuild then
                inst.AnimState:OverrideSymbol("swap_leaves", GetBuild(inst).leavesbuild, "swap_leaves")
            else
                inst.AnimState:ClearOverrideSymbol("swap_leaves")
            end
            inst.AnimState:PlayAnimation(inst.anims.growleaves)
            inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
            inst:ListenForEvent("animover", GrowLeavesFn)
        else
            GrowLeavesFn(inst, monster, monsterout)
        end
    else
        inst.AnimState:PlayAnimation(inst.anims.dropleaves)
        SpawnLeafFX(inst, 11*FRAMES)
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeWilt")
        inst:ListenForEvent("animover", GrowLeavesFn)
    end
    if GetBuild(inst).shelter then
        inst:AddTag("shelter")
    else
        inst:RemoveTag("shelter")
    end
end

local function OnSeasonChange(inst, targetSeason)
    if targetSeason == SEASONS.AUTUMN then
        inst.target_leaf_state = "colorful"
    elseif targetSeason == SEASONS.WINTER then
        inst.target_leaf_state = "barren"
    else --SPRING AND SUMMER
        inst.target_leaf_state = "normal"
    end

    if inst.target_leaf_state ~= inst.leaf_state then
        local time = math.random(TUNING.MIN_LEAF_CHANGE_TIME, TUNING.MAX_LEAF_CHANGE_TIME)
        inst.targetleaveschangetime = GetTime() + time
        inst.leaveschangetask = inst:DoTaskInTime(time, OnChangeLeaves)
    end
end

local function ChangeSizeFn(inst)
    inst:RemoveEventCallback("animover", ChangeSizeFn)
    if inst.components.growable then
        if inst.components.growable.stage == 1 then
            inst.anims = short_anims
        elseif inst.components.growable.stage == 2 then
            inst.anims = normal_anims
        else
            if inst.monster then
                inst.anims = monster_anims
            else
                inst.anims = tall_anims
            end
        end
    end

    Sway(inst, nil, inst.monster)
end

local function SetShort(inst)
    if not inst.monster then
        inst.anims = short_anims
        if inst.components.workable then
           inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_SMALL)
        end
        inst.components.lootdropper:SetLoot(GetBuild(inst).short_loot)
    end
end

local function GrowShort(inst)
    if not inst.monster then
        inst.AnimState:PlayAnimation("grow_tall_to_short")
        if inst.leaf_state == "colorful" then SpawnLeafFX(inst, 17*FRAMES) end
        inst:ListenForEvent("animover", ChangeSizeFn)
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    end
end

local function SetNormal(inst)
    inst.anims = normal_anims
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_NORMAL)
    end
    inst.components.lootdropper:SetLoot(GetBuild(inst).normal_loot)
end

local function GrowNormal(inst)
    inst.AnimState:PlayAnimation("grow_short_to_normal")
    if inst.leaf_state == "colorful" then SpawnLeafFX(inst, 10*FRAMES) end
    inst:ListenForEvent("animover", ChangeSizeFn)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local function SetTall(inst)
    inst.anims = tall_anims
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_TALL)
    end
    inst.components.lootdropper:SetLoot(GetBuild(inst).tall_loot)
end

local function GrowTall(inst)
    inst.AnimState:PlayAnimation("grow_normal_to_tall")
    if inst.leaf_state == "colorful" then SpawnLeafFX(inst, 10*FRAMES) end
    inst:ListenForEvent("animover", ChangeSizeFn)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
end

local growth_stages =
{
    { name = "short", time = function(inst) return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[1].base, TUNING.DECIDUOUS_GROW_TIME[1].random) end, fn = SetShort, growfn = GrowShort },
    { name = "normal", time = function(inst) return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[2].base, TUNING.DECIDUOUS_GROW_TIME[2].random) end, fn = SetNormal, growfn = GrowNormal },
    { name = "tall", time = function(inst) return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[3].base, TUNING.DECIDUOUS_GROW_TIME[3].random) end, fn = SetTall, growfn = GrowTall },
    --{ name = "old", time = function(inst) return GetRandomWithVariance(TUNING.DECIDUOUS_GROW_TIME[4].base, TUNING.DECIDUOUS_GROW_TIME[4].random) end, fn = SetOld, growfn = GrowOld },
}

local function chop_tree(inst, chopper, chops)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper ~= nil and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end

    SpawnLeafFX(inst, nil, true)

    -- Force update anims if monster
    if inst.monster then 
        inst.anims = monster_anims
    end
    inst.AnimState:PlayAnimation(inst.anims.chop)

    if inst.monster then
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/decidous/hurt_chop")
        inst.sg:GoToState("chop_pst")
    else
        PushSway(inst)
    end
end

local function dig_up_stump(inst)
    inst.components.lootdropper:SpawnLootPrefab(inst.monster and "livinglog" or "log")
    inst:Remove()
end

local function chop_down_tree_shake(inst)
    local sz = (inst.components.growable and inst.components.growable.stage > 2) and .5 or .25
    ShakeAllCameras(CAMERASHAKE.FULL, 0.25, 0.03, sz, inst, 6)
end

local function delayed_start_monster(inst)
    inst.monster_start_task = nil
    inst:StartMonster()
end

local function make_stump(inst)
    inst:RemoveComponent("burnable")
    MakeSmallBurnable(inst)
    inst:RemoveComponent("propagator")
    MakeSmallPropagator(inst)
    inst:RemoveComponent("workable")
    inst:RemoveTag("shelter")
    inst:RemoveTag("cattoyairborne")
    inst:AddTag("stump")

    inst.MiniMapEntity:SetIcon("tree_leaf_stump.png")
	
    if inst.monster_start_task ~= nil then
        inst.monster_start_task:Cancel()
        inst.monster_start_task = nil
    end
    if inst.monster_stop_task ~= nil then
        inst.monster_stop_task:Cancel()
        inst.monster_stop_task = nil
    end
    if inst.leaveschangetask ~= nil then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end
    if inst.leaveschangetask ~= nil then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end

    RemovePhysicsColliders(inst)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
    inst.components.workable:SetWorkLeft(1)

    if inst.components.growable ~= nil then
        inst.components.growable:StopGrowing()
    end

    if inst.components.timer and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(TUNING.DECIDUOUS_REGROWTH.DEAD_DECAY_TIME, TUNING.DECIDUOUS_REGROWTH.DEAD_DECAY_TIME*0.5))
    end
end

local function chop_down_tree(inst, chopper)
    local days_survived = TheWorld.state.cycles
    if not inst.monster and inst.leaf_state ~= "barren" and inst.components.growable ~= nil and inst.components.growable.stage == 3 and days_survived >= TUNING.DECID_MONSTER_MIN_DAY then
        --print("Chance of making a monster")
        local chance = 0
        if TheWorld.state.season == "autumn" then 
            chance = TUNING.DECID_MONSTER_SPAWN_CHANCE_AUTUMN
        elseif TheWorld.state.season == "spring" then 
            chance = TUNING.DECID_MONSTER_SPAWN_CHANCE_SPRING
        elseif TheWorld.state.season == "summer" then 
            chance = TUNING.DECID_MONSTER_SPAWN_CHANCE_SUMMER
        elseif TheWorld.state.season == "winter" then 
            chance = TUNING.DECID_MONSTER_SPAWN_CHANCE_WINTER -- this should always be 0 (because barren trees can't become monsters), but is included in tuning values for consistency
        end

        local chance_mod = TUNING.DECID_MONSTER_SPAWN_CHANCE_MOD[1]
        for k,v in ipairs(TUNING.DECID_MONSTER_DAY_THRESHOLDS) do
            if days_survived >= v then
                chance_mod = TUNING.DECID_MONSTER_SPAWN_CHANCE_MOD[k+1]
            else
                break
            end
        end
        chance = chance * chance_mod

        --print("Chance is ", chance, TheWorld.state.season)
        if math.random() <= chance then
            --print("Trying to spawn monster")
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 30, { "birchnut" }, { "fire", "stump", "burnt", "monster", "FX", "NOCLICK", "DECOR", "INLIMBO" })
            local max_monsters_to_spawn = math.random(3, 4)
            for i, v in ipairs(ents) do
                if v:IsValid() and v.leaf_state ~= "barren" and not v.monster and v.monster_start_task == nil and v.monster_stop_task == nil then
                    if v.monster_start_task ~= nil then
                        v.monster_start_task:Cancel()
                    end
                    v.monster_start_task = v:DoTaskInTime(math.random(1, 4), delayed_start_monster)
                    max_monsters_to_spawn = max_monsters_to_spawn - 1
                    if max_monsters_to_spawn <= 0 then
                        break
                    end
                end
            end
        end
    end

    if inst.monster then
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/decidous/death")
        inst.sg:GoToState("empty")
        inst.components.lootdropper:AddChanceLoot("livinglog", TUNING.DECID_MONSTER_ADDITIONAL_LOOT_CHANCE)
        inst.components.lootdropper:AddChanceLoot("nightmarefuel", TUNING.DECID_MONSTER_ADDITIONAL_LOOT_CHANCE)
        if inst.components.deciduoustreeupdater ~= nil then
            inst.components.deciduoustreeupdater:StopMonster()
        end
        if inst.monster_stop_task ~= nil then
            inst.monster_stop_task:Cancel()
            inst.monster_stop_task = nil
        end
        inst:RemoveComponent("combat")
    end

    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")

    local pt = Vector3(inst.Transform:GetWorldPosition())
    local hispos = Vector3(chopper.Transform:GetWorldPosition())

    local he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0

    if he_right then
        inst.AnimState:PlayAnimation(inst.anims.fallleft)
        if inst.components.growable and inst.components.growable.stage == 3 and inst.leaf_state == "colorful" then
            inst.components.lootdropper:SpawnLootPrefab("acorn", pt - TheCamera:GetRightVec())
        end
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation(inst.anims.fallright)
        if inst.components.growable and inst.components.growable.stage == 3 and inst.leaf_state == "colorful" then
            inst.components.lootdropper:SpawnLootPrefab("acorn", pt - TheCamera:GetRightVec())
        end
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

    inst:DoTaskInTime(.4, chop_down_tree_shake)

    inst.AnimState:PushAnimation(inst.anims.stump)

    make_stump(inst)
end

local function chop_down_burnt_tree(inst, chopper)
    inst:RemoveComponent("workable")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
    inst.AnimState:PlayAnimation(inst.anims.chop_burnt)
    RemovePhysicsColliders(inst)
    inst:ListenForEvent("animover", inst.Remove)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    inst.components.lootdropper:DropLoot()
    if inst.acorntask then
        inst.acorntask:Cancel()
        inst.acorntask = nil
    end
end

local function onburntchanges(inst)
    inst:RemoveComponent("growable")
    inst:RemoveTag("shelter")
    inst:RemoveTag("cattoyairborne")
    inst:RemoveTag("monster")
    inst.monster = false

    if inst.monster_start_task then
        inst.monster_start_task:Cancel()
        inst.monster_start_task = nil
    end
    if inst.monster_stop_task then
        inst.monster_stop_task:Cancel()
        inst.monster_stop_task = nil
    end

    inst.components.lootdropper:SetLoot({})
    if GetBuild(inst).drop_acorns then
        inst.components.lootdropper:AddChanceLoot("acorn", 0.1)
    end

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
    end

    if inst.leaveschangetask then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end

    inst.MiniMapEntity:SetIcon("tree_leaf_burnt.png")

    inst.AnimState:PlayAnimation(inst.anims.burnt, true)
    inst:DoTaskInTime(3*FRAMES, function(inst)
        if inst.components.burnable and inst.components.propagator then
            inst.components.burnable:Extinguish()
            inst.components.propagator:StopSpreading()
            inst:RemoveComponent("burnable")
            inst:RemoveComponent("propagator")
        end
    end)
end

local function OnBurnt(inst, immediate)
    inst:AddTag("burnt")
    if immediate then
        if inst.monster then
            inst.monster = false
            if inst.components.deciduoustreeupdater then 
                inst.components.deciduoustreeupdater:StopMonster() 
                inst:RemoveComponent("deciduoustreeupdater")
            end
            if inst.components.combat then inst:RemoveComponent("combat") end
            inst.sg:GoToState("empty")
            inst.AnimState:SetBank("tree_leaf")
            inst:DoTaskInTime(1*FRAMES, onburntchanges)
        else
            onburntchanges(inst)
        end
    else
        inst:DoTaskInTime( 0.5, function(inst)
            if inst.monster then
                inst.monster = false
                if inst.components.deciduoustreeupdater then 
                    inst.components.deciduoustreeupdater:StopMonster() 
                    inst:RemoveComponent("deciduoustreeupdater")
                end
                if inst.components.combat then inst:RemoveComponent("combat") end
                inst.sg:GoToState("empty")
                inst.AnimState:SetBank("tree_leaf")
                inst:DoTaskInTime(1*FRAMES, onburntchanges)
            else
                onburntchanges(inst)
            end
        end)
    end    

    if inst.components.timer and not inst.components.timer:TimerExists("decay") then
        inst.components.timer:StartTimer("decay", GetRandomWithVariance(TUNING.DECIDUOUS_REGROWTH.DEAD_DECAY_TIME, TUNING.DECIDUOUS_REGROWTH.DEAD_DECAY_TIME*0.5))
    end

    inst.AnimState:SetRayTestOnBB(true)
end

local function tree_burnt(inst)
    OnBurnt(inst)
    inst.acorntask = inst:DoTaskInTime(10,
        function()
            local pt = Vector3(inst.Transform:GetWorldPosition())
            if math.random(0, 1) == 1 then
                pt = pt + TheCamera:GetRightVec()
            else
                pt = pt - TheCamera:GetRightVec()
            end
            inst.components.lootdropper:DropLoot(pt)
            inst.acorntask = nil
        end)
    if inst.leaveschangetask then
        inst.leaveschangetask:Cancel()
        inst.leaveschangetask = nil
    end
end

local function handler_growfromseed(inst)
    inst.components.growable:SetStage(1)

    local season = TheWorld.state.season
    if season then
        if season == SEASONS.AUTUMN then
            local rand = math.random()
            if rand < .33 then
                inst.build = "red"
            elseif rand < .67 then
                inst.build = "orange"
            else
                inst.build = "yellow"
            end
            inst.AnimState:SetMultColour(1, 1, 1, 1)
            inst.leaf_state = "colorful"
            inst.target_leaf_state = "colorful"
        elseif season == SEASONS.WINTER then
            inst.build = "barren"
            inst.leaf_state = "barren"
            inst.target_leaf_state = "barren"
        else
            inst.build = "normal"
            inst.leaf_state = "normal"
            inst.target_leaf_state = "normal"
        end

        --print(inst, "growfromseed, ", inst.target_leaf_state)
    end

    if GetBuild(inst).leavesbuild then
        inst.AnimState:OverrideSymbol("swap_leaves", GetBuild(inst).leavesbuild, "swap_leaves")
    else
        inst.AnimState:ClearOverrideSymbol("swap_leaves")
    end
    inst.AnimState:PlayAnimation("grow_seed_to_short")
    if inst.leaf_state == "colorful" then SpawnLeafFX(inst, 5*FRAMES) end
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
    inst.anims = short_anims

    PushSway(inst)
end

local function inspect_tree(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst:HasTag("stump") and "CHOPPED")
        or (inst.monster and "POISON")
        or nil
end

local function DoStartMonster(inst, starttimeoffset)
    if inst.components.workable ~= nil then
       inst.components.workable:SetWorkLeft(TUNING.DECIDUOUS_CHOPS_MONSTER)
    end
    inst.AnimState:SetBank("tree_leaf_monster")
    inst.AnimState:PlayAnimation("transform_in")
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/decidous/transform_in")
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/decidous/transform_voice")
    SpawnLeafFX(inst, 7 * FRAMES)
    local leavesbuild = GetBuild(inst).leavesbuild
    if leavesbuild ~= nil then
        inst.AnimState:OverrideSymbol("legs", leavesbuild, "legs")
        inst.AnimState:OverrideSymbol("legs_mouseover", leavesbuild, "legs_mouseover")
        inst.AnimState:OverrideSymbol("eye", leavesbuild, "eye")
        inst.AnimState:OverrideSymbol("mouth", leavesbuild, "mouth")
    else
        inst.AnimState:ClearOverrideSymbol("legs")
        inst.AnimState:ClearOverrideSymbol("legs_mouseover")
        inst.AnimState:ClearOverrideSymbol("eye")
        inst.AnimState:ClearOverrideSymbol("mouth")
    end
    inst:AddComponent("combat")
    if inst.components.deciduoustreeupdater == nil then
        inst:AddComponent("deciduoustreeupdater")
    end
    inst.components.deciduoustreeupdater:StartMonster(starttimeoffset)
end

local function DoStartMonsterChangeLeaves(inst)
    OnChangeLeaves(inst, true)
    inst.components.growable:StopGrowing()
end

local function StartMonster(inst, force, starttimeoffset)
    -- Become a monster. Requires tree to have leaves and be medium size (it will grow to large size when become monster)
    if force or (inst.anims == normal_anims and inst.leaf_state ~= "barren") then
        inst.monster = true
        inst.target_leaf_state = "poison"
        inst:RemoveTag("cattoyairborne")

        if inst.leaveschangetask ~= nil then
            inst.leaveschangetask:Cancel()
            inst.leaveschangetask = nil
        end

        if not force then
            inst.components.growable:DoGrowth()
            inst:DoTaskInTime(12 * FRAMES, DoStartMonsterChangeLeaves)
        else
            OnChangeLeaves(inst, true)
        end

        inst:DoTaskInTime(26 * FRAMES, DoStartMonster, starttimeoffset)
    end
end

local function StopMonster(inst)
    -- Return to normal tree behavior (also grow from tall to short)
    if inst.monster then
        inst.monster = false
        inst.monster_start_time = nil
        inst.monster_duration = nil
        if inst.components.deciduoustreeupdater then inst.components.deciduoustreeupdater:StopMonster() end
        inst:RemoveComponent("combat")
        inst:RemoveComponent("deciduoustreeupdater")
        if not inst:HasTag("stump") and not inst:HasTag("burnt") then 
            inst.AnimState:PlayAnimation("transform_out")
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/decidous/transform_out")
            SpawnLeafFX(inst, 8*FRAMES)
            inst.sg:GoToState("empty")
        end
        inst:DoTaskInTime(16*FRAMES, function(inst)
            inst.AnimState:ClearOverrideSymbol("eye")
            inst.AnimState:ClearOverrideSymbol("mouth")
            if not inst:HasTag("stump") then 
                inst.AnimState:ClearOverrideSymbol("legs")
                inst.AnimState:ClearOverrideSymbol("legs_mouseover")
                inst.components.growable:StartGrowing()
            end
            inst.AnimState:SetBank("tree_leaf")
            inst:AddTag("cattoyairborne")

            if TheWorld.state.isautumn then
                inst.target_leaf_state = "colorful"
            elseif TheWorld.state.iswinter then
                inst.target_leaf_state = "barren"
            else
                inst.target_leaf_state = "normal"
            end

            inst.components.growable:DoGrowth()
            inst:DoTaskInTime(12 * FRAMES, OnChangeLeaves, false, true)
        end)
    end
end

local function onignite(inst)
    if inst.monster and not inst:HasTag("stump") then
        inst.sg:GoToState("burning_pre")
    end
    if inst.components.deciduoustreeupdater ~= nil then
        inst.components.deciduoustreeupdater:SpawnIgniteWave()
    end
end

local function onextinguish(inst)
    if inst.monster and not inst:HasTag("stump") then
        inst.sg:GoToState("gnash_idle")
    end
end

local function OnEntitySleep(inst)
    inst._wasonfire = inst._wasonfire or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or nil
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("inspectable")
    inst:RemoveComponent("deciduoustreeupdater")
end

local function OnEntityWake(inst)
    if not (inst._wasonfire or
            (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or
            inst:HasTag("burnt")) then
        if inst:HasTag("stump") then
            inst:RemoveComponent("burnable")
            MakeSmallBurnable(inst)
            inst:RemoveComponent("propagator")
            MakeSmallPropagator(inst)
        else
            if inst.components.burnable == nil then
                MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
                inst.components.burnable:SetFXLevel(5)
                inst.components.burnable:SetOnBurntFn(tree_burnt)
                inst.components.burnable.extinguishimmediately = false
                inst.components.burnable:SetOnIgniteFn(onignite)
                inst.components.burnable:SetOnExtinguishFn(onextinguish)
            end

            if inst.components.propagator == nil then
                MakeMediumPropagator(inst)
            end

            if inst.components.deciduoustreeupdater == nil then
                inst:AddComponent("deciduoustreeupdater")
            end
        end
    end

    if inst.monster and inst.monster_start_time and inst.monster_duration and ((GetTime() - inst.monster_start_time) > inst.monster_duration) then
        if not (inst._wasonfire or
                (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or
                inst:HasTag("burnt") or
                inst:HasTag("stump")) then
            StopMonster(inst)
        else
            inst.monster = false
            inst.monster_start_time = nil
            inst.monster_duration = nil
            if inst.components.deciduoustreeupdater ~= nil then
                inst.components.deciduoustreeupdater:StopMonster()
                inst:RemoveComponent("deciduoustreeupdater")
            end
            if inst.components.combat ~= nil then
                inst:RemoveComponent("combat")
            end
        end
    end

    if (inst._wasonfire or
        (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())) and
        not inst:HasTag("burnt") then
        inst.sg:GoToState("empty")
        inst.AnimState:ClearOverrideSymbol("eye")
        inst.AnimState:ClearOverrideSymbol("mouth")
        if not inst:HasTag("stump") then 
            inst.AnimState:ClearOverrideSymbol("legs")
            inst.AnimState:ClearOverrideSymbol("legs_mouseover") 
        end
        inst.AnimState:SetBank("tree_leaf")
        OnBurnt(inst, true)
    end

    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree
    end

    inst._wasonfire = nil
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

    data.monster = inst.monster
    if inst.monster and inst.components.deciduoustreeupdater and inst.components.deciduoustreeupdater.monster_start_time then
        data.monster_start_offset = inst.components.deciduoustreeupdater.monster_start_time - GetTime()
    end
    data.target_leaf_state = inst.target_leaf_state
    data.leaf_state = inst.leaf_state
    if inst.leaveschangetask and inst.targetleaveschangetime then
        data.leaveschangetime = inst.targetleaveschangetime - GetTime()
    end
end

local function onload(inst, data)
    if data ~= nil then
        inst.build = data.build ~= nil and builds[data.build] ~= nil and data.build or "normal"

        inst.target_leaf_state = data.target_leaf_state
        inst.leaf_state = data.leaf_state

        if data.monster and not data.stump and not data.burnt then
            inst.monster = data.monster
            StartMonster(inst, true, data.monster_start_offset)
        elseif data.monster then
            if data.stump then
                inst.monster = data.monster
                inst.components.growable.stage = 3
                inst:AddTag("stump")
            elseif not data.burnt then
                inst.monster = false

                if TheWorld.state.isautumn then
                    inst.target_leaf_state = "colorful"
                elseif TheWorld.state.iswinter then
                    inst.target_leaf_state = "barren"
                else
                    inst.target_leaf_state = "normal"
                end

                inst.components.growable:DoGrowth()
                inst:DoTaskInTime(12 * FRAMES, OnChangeLeaves, false) 
            end
            if inst.components.deciduoustreeupdater then 
                inst.components.deciduoustreeupdater:StopMonster() 
                inst:RemoveComponent("deciduoustreeupdater")
            end
            if inst.components.combat then inst:RemoveComponent("combat") end
            inst.sg:GoToState("empty")
        end

        if inst.components.growable ~= nil then
            if inst.components.growable.stage == 1 then
                inst.anims = short_anims
            elseif inst.components.growable.stage == 2 then
                inst.anims = normal_anims
            else
                if inst.monster then
                    inst.anims = monster_anims
                else
                    inst.anims = tall_anims
                end
            end
        else
            inst.anims = tall_anims
        end

        if data.stump then
            if data.monster then
                inst.AnimState:SetBank("tree_leaf_monster")
                if GetBuild(inst).leavesbuild then
                    inst.AnimState:OverrideSymbol("legs", GetBuild(inst).leavesbuild, "legs")
                    inst.AnimState:OverrideSymbol("legs_mouseover", GetBuild(inst).leavesbuild, "legs_mouseover")
                    inst.AnimState:OverrideSymbol("eye", GetBuild(inst).leavesbuild, "eye")
                    inst.AnimState:OverrideSymbol("mouth", GetBuild(inst).leavesbuild, "mouth")
                else
                    inst.AnimState:ClearOverrideSymbol("legs")
                    inst.AnimState:ClearOverrideSymbol("legs_mouseover")
                    inst.AnimState:ClearOverrideSymbol("eye")
                    inst.AnimState:ClearOverrideSymbol("mouth")
                end
            end
            inst.AnimState:PlayAnimation(inst.anims.stump)

            make_stump(inst)
            if data.burnt or inst:HasTag("burnt") then
                DefaultBurntFn(inst)
            end
        elseif data.burnt then
            inst._wasonfire = true--OnEntityWake will handle it actually doing burnt logic
        end
    end

    if not inst:IsValid() then
        return
    end

    if data and data.leaveschangetime then
        inst.leaveschangetask = inst:DoTaskInTime(data.leaveschangetime, OnChangeLeaves)
    end

    if not data or (not data.burnt and not data.stump) then
        if inst.build ~= "normal" or inst.leaf_state ~= inst.target_leaf_state then
            OnChangeLeaves(inst)
        else
            if inst.build == "barren" then
                inst:RemoveTag("shelter")
                inst.AnimState:Hide("mouseover")
            else
                inst.AnimState:Show("mouseover")
            end
            Sway(inst)
        end
    end
end

local function ValidateLeaves(inst)
    if not inst:HasTag("stump") and not inst.monster and not inst:HasTag("burnt") then 

        --print("Validating leaves", TheWorld.state.remainingdaysinseason, TheWorld.state.season)
        if TheWorld.state.season == SEASONS.AUTUMN then 
            if inst.leaf_state ~= "colorful" then 
                inst.target_leaf_state = "colorful"
                --print(inst, "fixing leaves for autumn", inst.leaf_state, inst.target_leaf_state)
                if inst.leaveschangetask then inst.leaveschangetask:Cancel() end
                OnChangeLeaves(inst)
            end
        elseif TheWorld.state.season == SEASONS.WINTER then 
            if inst.leaf_state ~= "barren" then 
                inst.target_leaf_state = "barren"
                --print(inst, "fixing leaves for winter", inst.leaf_state, inst.target_leaf_state)
                if inst.leaveschangetask then inst.leaveschangetask:Cancel() end
                OnChangeLeaves(inst)
            end
        elseif inst.leaf_state ~= "normal" then 
            inst.target_leaf_state = "normal"
            --print(inst, "fixing leaves for spring/summer", inst.leaf_state, inst.target_leaf_state)
            if inst.leaveschangetask then inst.leaveschangetask:Cancel() end
            OnChangeLeaves(inst)
        end
    end
end

local function OnDayEnd(inst, data) 
    --print("OnDayEnd", TheWorld.state.season, TheWorld.state.autumnlength, TheWorld.state.elapseddaysinseason, TheWorld.state.remainingdaysinseason, TheWorld.state.seasonprogress)
    if inst.leaveschangetask ~= nil then return end
    local targetSeason = nil
    if TheWorld.state.remainingdaysinseason <= 3 then
        local nextSeason = {
            [SEASONS.AUTUMN] = SEASONS.WINTER, [SEASONS.WINTER] = SEASONS.SPRING,
            [SEASONS.SPRING] = SEASONS.SUMMER, [SEASONS.SUMMER] = SEASONS.AUTUMN,
        }

        local seasonlengths = {
            [SEASONS.AUTUMN] = "autumnlength", [SEASONS.WINTER] = "winterlength",
            [SEASONS.SPRING] = "springlength", [SEASONS.SUMMER] = "summerlength"
        }

        targetSeason = nextSeason[TheWorld.state.season]

        if targetSeason then
            if TheWorld.state[seasonlengths[targetSeason]] > 0 then
                OnSeasonChange(inst, targetSeason)
            else
                targetSeason = nextSeason[targetSeason]
                local numchecks = 0
                while not (TheWorld.state[seasonlengths[targetSeason]] > 0) do
                    targetSeason = nextSeason[targetSeason]
                    numchecks = numchecks + 1
                    if numchecks > 4 then break end
                end
                if TheWorld.state[seasonlengths[targetSeason]] > 0 and targetSeason ~= TheWorld.state.season then
                    OnSeasonChange(inst, targetSeason)
                end
            end
        end
    end
end

-- Set up leaf state at start of game
local function OnSeasonStart(inst)
    if not inst:HasTag("stump") and not inst.monster and not inst:HasTag("burnt") then
        if TheWorld.state.season == "autumn" then
            inst.target_leaf_state = "colorful"
        elseif TheWorld.state.season == "winter" then
            inst.target_leaf_state = "barren"
        else --SPRING AND SUMMER
            inst.target_leaf_state = "normal"
        end

        OnChangeLeaves(inst)
    end
end

local function onsway(inst, data)
    --NOTE: monster and monsterpost are booleans (hence no "or nil")
    Sway(inst, data ~= nil and data.monster, data ~= nil and data.monsterpost)
end

local function OnHaunt(inst, haunter)
    local isstump = inst:HasTag("stump")
    if not isstump and
        inst.components.workable ~= nil and
        math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
        inst.components.workable:WorkedBy(haunter, 1)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    elseif inst:HasTag("burnt") then
        return false
    --#HAUNTFIX
    --elseif inst.components.burnable ~= nil and
        --not inst.components.burnable:IsBurning() and
        --math.random() <= TUNING.HAUNT_CHANCE_VERYRARE then
        --inst.components.burnable:Ignite()
        --inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
        --inst.components.hauntable.cooldown_on_successful_haunt = false
        --return true
    elseif not (isstump or inst.monster) and
        math.random() <= TUNING.HAUNT_CHANCE_SUPERRARE then
        inst:StartMonster(true)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_HUGE
        return true
    end
    return false
end

local function makefn(build, stage, data)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .25)

        inst.MiniMapEntity:SetIcon("tree_leaf.png")
        inst.MiniMapEntity:SetPriority(-1)

        inst:AddTag("tree")
        inst:AddTag("birchnut")
        inst:AddTag("cattoyairborne")
        inst:AddTag("deciduoustree")
        inst:AddTag("shelter")

        inst.build = build
        inst.AnimState:SetBank("tree_leaf")
        inst.AnimState:SetBuild("tree_leaf_trunk_build")

        if GetBuild(inst).leavesbuild ~= nil then
            inst.AnimState:OverrideSymbol("swap_leaves", GetBuild(inst).leavesbuild, "swap_leaves")
        end

        inst:SetPrefabName(GetBuild(inst).prefab_name)

        MakeSnowCoveredPristine(inst)

        --Sneak these into pristine state for optimization
        inst:AddTag("__combat")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        --Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("__combat")

        inst:PrereplicateComponent("combat")

        inst:SetStateGraph("SGdeciduoustree")
        inst.sg:GoToState("empty")

        inst.color = 0.5 + math.random() * 0.5
        inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)

        MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(tree_burnt)
        inst.components.burnable.extinguishimmediately = false
        inst.components.burnable:SetOnIgniteFn(onignite)
        inst.components.burnable:SetOnExtinguishFn(onextinguish)

        MakeMediumPropagator(inst)

        inst:AddComponent("plantregrowth")
        inst.components.plantregrowth:SetRegrowthRate(TUNING.DECIDUOUS_REGROWTH.OFFSPRING_TIME)
        inst.components.plantregrowth:SetProduct("acorn_sapling")
        inst.components.plantregrowth:SetSearchTag("deciduoustree")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetOnWorkCallback(chop_tree)
        inst.components.workable:SetOnFinishCallback(chop_down_tree)

        inst:AddComponent("lootdropper")

        inst:AddComponent("deciduoustreeupdater")
        inst:ListenForEvent("sway", onsway)

        inst.lastleaffxtime = 0
        inst.leaffxinterval = math.random(TUNING.MIN_SWAY_FX_FREQUENCY, TUNING.MAX_SWAY_FX_FREQUENCY)
        inst.SpawnLeafFX = SpawnLeafFX
        inst:ListenForEvent("deciduousleaffx", function(world)
            if inst.entity:IsAwake() then
                if inst.leaf_state == "colorful" and GetTime() - inst.lastleaffxtime > inst.leaffxinterval then
                    local variance = math.random() * 2
                    SpawnLeafFX(inst, variance)
                    inst.leaffxinterval = math.random(TUNING.MIN_SWAY_FX_FREQUENCY, TUNING.MAX_SWAY_FX_FREQUENCY)
                    inst.lastleaffxtime = GetTime()
                end
            end
        end, TheWorld)

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(stage == 0 and math.random(1, 3) or stage)
        inst.components.growable.loopstages = true
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()

        inst.growfromseed = handler_growfromseed

        inst:AddComponent("hauntable")
        -- Haunt effects more or less the same as evergreens
        inst.components.hauntable:SetOnHauntFn(OnHaunt)

        inst:WatchWorldState("cycles", OnDayEnd)
        inst:WatchWorldState("season", ValidateLeaves)

        inst.leaf_state = "normal"

        inst.StartMonster = StartMonster
        inst.StopMonster = StopMonster
        inst.monster = false

        inst.OnSave = onsave 
        inst.OnLoad = onload

        MakeSnowCovered(inst)

        if data == "stump" then
            RemovePhysicsColliders(inst)
            inst:AddTag("stump")
            inst:RemoveTag("shelter")

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
            inst.MiniMapEntity:SetIcon("tree_leaf_stump.png")
        else
            --When POPULATING, season won't be valid yet at this point,
            --but we want this immediate for all later spawns.
            OnSeasonStart(inst)
            inst.AnimState:SetTime(math.random() * 2)
            if data == "burnt" then
                OnBurnt(inst, true)
            elseif POPULATING then
                --Redo this after season is valid
                inst:DoTaskInTime(0, OnSeasonStart)
            end
        end

        inst.OnEntitySleep = OnEntitySleep
        inst.OnEntityWake = OnEntityWake
        inst._wasonfire = nil

        return inst
    end
end

local function tree(name, build, stage, data)
    return Prefab(name, makefn(build, stage, data), assets, prefabs)
end

return tree("deciduoustree", "normal", 0),
        tree("deciduoustree_normal", "normal", 2),
        tree("deciduoustree_tall", "normal", 3),
        tree("deciduoustree_short", "normal", 1),
        tree("deciduoustree_burnt", "normal", 0, "burnt"),
        tree("deciduoustree_stump", "normal", 0, "stump")
