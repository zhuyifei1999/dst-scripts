--[[
    Prefabs for 3 different mushtrees
--]]

local prefabs =
{
	"log",
	"blue_cap",
    "charcoal",
	"ash",
    "spore_tall",
    "spore_medium",
    "spore_small",
}

local TREESTATES =
{
    BLOOMING = "bloom",
    NORMAL = "normal",
}

local function onburntanimover(inst)
    inst.components.lootdropper:SpawnLootPrefab("ash")
    if math.random() < 0.5 then
        inst.components.lootdropper:SpawnLootPrefab("charcoal")
    end
    inst:Remove()
end

local function tree_burnt(inst)
	inst.persists = false
	inst.AnimState:PlayAnimation("chop_burnt")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
	inst:ListenForEvent("animover", onburntanimover)
end

local function stump_burnt(inst)
	inst.components.lootdropper:SpawnLootPrefab("ash")
	inst:Remove()
end

local function dig_up_stump(inst)
	inst.components.lootdropper:SpawnLootPrefab("log")
	inst:Remove()
end

local function inspect_tree(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    elseif inst.treestate == TREESTATES.BLOOMING then
        return "BLOOM"
    end
end

local function onspawnfn(inst, spawn)
    inst.AnimState:PlayAnimation("cough")
    inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_spore_fart")
    inst.AnimState:PushAnimation("idle_loop", true)

    spawn.components.knownlocations:RememberLocation("home", inst:GetPosition())
end

local function makestump(inst)
	RemovePhysicsColliders(inst)
	inst:AddTag("stump")
    inst:RemoveTag("shelter")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("burnable")
	MakeSmallPropagator(inst)
	MakeSmallBurnable(inst)
	inst.components.burnable:SetOnBurntFn(stump_burnt)
    inst.components.growable:StopGrowing()
    inst.components.periodicspawner:Stop()

    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnWorkCallback(nil)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
	inst.components.workable:SetWorkLeft(1)
	inst.AnimState:PlayAnimation("idle_stump")
	inst.AnimState:ClearBloomEffectHandle()

	inst.Light:Enable(false)
end

local function workcallback(inst, worker, workleft)
    if not worker or (worker and not worker:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_mushroom")
    end
	if workleft <= 0 then
		inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
		makestump(inst)

        inst.AnimState:PlayAnimation("fall")

		inst.components.lootdropper:DropLoot(inst:GetPosition())
		inst.AnimState:PushAnimation("idle_stump")

	else
		inst.AnimState:PlayAnimation("chop")
		inst.AnimState:PushAnimation("idle_loop", true)
	end
end

local function DoGrow(inst, tostage, targetscale)
    if tostage == 2 then
        inst.AnimState:PlayAnimation("change")
        inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_grow_1")
    elseif tostage == 3 then
        inst.AnimState:PlayAnimation("change")
        inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_grow_2")
    elseif tostage == 1 then
        inst.AnimState:PlayAnimation("shrink")
        inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_shrink")
    end
    inst.AnimState:PushAnimation("idle_loop", true)
    inst:DoTaskInTime(14*FRAMES, function()
        inst.components.growable:SetStage(inst.components.growable:GetNextStage())
    end)
end

local function GrowShort(inst)
    DoGrow(inst, 1, 0.9)
end

local function GrowNormal(inst)
    DoGrow(inst, 2, 1.0)
end

local function GrowTall(inst)
    DoGrow(inst, 3, 1.1)
end

local function SetShort(inst)
    inst.Transform:SetScale(0.9,0.9,0.9)
end

local function SetNormal(inst)
    inst.Transform:SetScale(1.0,1.0,1.0)
end

local function SetTall(inst)
    inst.Transform:SetScale(1.1,1.1,1.1)
end

local growth_stages =
{
    {name="short", time = function(inst) return GetRandomWithVariance(TUNING.EVERGREEN_GROW_TIME[1].base, TUNING.EVERGREEN_GROW_TIME[1].random) end, fn = function(inst) SetShort(inst) end,  growfn = function(inst) GrowShort(inst) end , leifscale=.7 },
    {name="normal", time = function(inst) return GetRandomWithVariance(TUNING.EVERGREEN_GROW_TIME[2].base, TUNING.EVERGREEN_GROW_TIME[2].random) end, fn = function(inst) SetNormal(inst) end, growfn = function(inst) GrowNormal(inst) end, leifscale=1 },
    {name="tall", time = function(inst) return GetRandomWithVariance(TUNING.EVERGREEN_GROW_TIME[3].base, TUNING.EVERGREEN_GROW_TIME[3].random) end, fn = function(inst) SetTall(inst) end, growfn = function(inst) GrowTall(inst) end, leifscale=1.25 },
}


local data =
{
    small =
    { --Green
        bank = "mushroom_tree_small",
        build = "mushroom_tree_small",
        season = SEASONS.SPRING,
        bloom_build = "mushroom_tree_small_bloom",
        spore = "spore_small",
        icon = "mushroom_tree_small.png",
        loot = {"log", "green_cap"},
        work = TUNING.MUSHTREE_CHOPS_SMALL,
        lightradius = 1.0,
        lightcolour = {146/255, 225/255, 146/255},
    },
    medium =
    { --Red
        bank = "mushroom_tree_med",
        build = "mushroom_tree_med",
        season = SEASONS.SUMMER,
        bloom_build = "mushroom_tree_med_bloom",
        spore = "spore_medium",
        icon = "mushroom_tree_med.png",
        loot = {"log", "red_cap"},
        work = TUNING.MUSHTREE_CHOPS_MEDIUM,
        lightradius = 1.25,
        lightcolour = {197/255, 126/255, 126/255},
    },
    tall =
    { --Blue
        bank = "mushroom_tree",
        build = "mushroom_tree_tall",
        season = SEASONS.WINTER,
        bloom_build = "mushroom_tree_tall_bloom",
        spore = "spore_tall",
        icon = "mushroom_tree.png",
        loot = {"log", "log", "blue_cap"},
        work = TUNING.MUSHTREE_CHOPS_TALL,
        lightradius = 1.5,
        lightcolour = {111/255, 111/255, 227/255},
        webbable = true,
    },
}

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end

    if inst:HasTag("stump") then
        data.stump = true
    end

    data.treestate = inst.treestate
end

local function onload(inst, data)
    if data ~= nil then
        if data.burnt then
            if data.stump then
            	stump_burnt(inst)
            else
            	tree_burnt(inst)
            end
        elseif data.stump then
        	makestump(inst)
        elseif data.treestate == TREESTATES.NORMAL then
            inst:Normal(true)
        elseif data.treestate == TREESTATES.BLOOMING then
            inst:Bloom(true)
        end
    end
end

local function maketree(data)

    local function bloom_tree(inst, instant)
        if not instant then
            inst:DoTaskInTime(math.random() * 3 * TUNING.SEG_TIME, function()
                inst.AnimState:PlayAnimation("change")
                inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_grow_3")
                local swapbuild = nil
                swapbuild = function()
                    inst.AnimState:PushAnimation("idle_loop", true)
                    inst.AnimState:SetBuild(data.bloom_build)
                    inst.components.periodicspawner:ForceNextSpawn()
                end
                inst:DoTaskInTime(14*FRAMES, swapbuild)
            end)
        else
            inst.AnimState:SetBuild(data.bloom_build)
        end
        inst.treestate = TREESTATES.BLOOMING
        inst.components.periodicspawner:Start()
    end

    local function normal_tree(inst, instant)
        if not instant then
            inst:DoTaskInTime(math.random() * 3 * TUNING.SEG_TIME, function()
                inst.AnimState:PlayAnimation("change")
                inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_shrink")
                local swapbuild = nil
                swapbuild = function()
                    inst.AnimState:PushAnimation("idle_loop", true)
                    inst.AnimState:SetBuild(data.build)
                end
                inst:DoTaskInTime(14*FRAMES, swapbuild)
            end)
        else
            inst.AnimState:SetBuild(data.build)
        end
        inst.treestate = TREESTATES.NORMAL
        inst.components.periodicspawner:Stop()
    end

    local function onseasonchange(inst, season)
        if not inst:HasTag("burnt") and not inst:HasTag("stump") then
            if season == data.season and inst.treestate ~= TREESTATES.BLOOM then
                bloom_tree(inst)
            elseif season ~= data.season and inst.treestate ~= TREESTATES.NORMAL then
                normal_tree(inst)
            end
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1)

        inst.AnimState:SetBuild(data.build)
        inst.AnimState:SetBank(data.bank)
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.AnimState:SetTime(math.random() * 2)

        inst.MiniMapEntity:SetIcon(data.icon)

        inst.Light:SetFalloff(0.5)
        inst.Light:SetIntensity(.8)
        inst.Light:SetRadius(data.lightradius)
        inst.Light:SetColour(unpack(data.lightcolour))
        inst.Light:Enable(true)

        inst:AddTag("shelter")
        if data.webbable then
            inst:AddTag("webbable")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        local color = 0.5 + math.random() * 0.5
        inst.AnimState:SetMultColour(color, color, color, 1)

        MakeMediumPropagator(inst)
        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(tree_burnt)

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(data.loot)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetWorkLeft(data.work)
        inst.components.workable:SetOnWorkCallback(workcallback)

        inst:AddComponent("periodicspawner")
        inst.components.periodicspawner:SetPrefab(data.spore)
        inst.components.periodicspawner:SetOnSpawnFn(onspawnfn)
        inst.components.periodicspawner:Stop()

        inst:AddComponent("growable")
        inst.components.growable.stages = growth_stages
        inst.components.growable:SetStage(math.random(1, 3))
        inst.components.growable.loopstages = true
        inst.components.growable.growonly = true
        inst.components.growable:StartGrowing()

        --inst:AddComponent("transformer") this component isn't in DST yet.

        --inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

        inst.treestate = TREESTATES.NORMAL

        inst.Bloom = bloom_tree
        inst.Normal = normal_tree
        inst.OnSave = onsave
        inst.OnLoad = onload
        inst:WatchWorldState("season", onseasonchange)

        return inst
    end
    return fn
end

return Prefab("cave/objects/mushtree_tall", maketree(data.tall), { Asset("ANIM", "anim/mushroom_tree_tall.zip"), Asset("ANIM", "anim/mushroom_tree_tall_bloom.zip") }, prefabs),
       Prefab("cave/objects/mushtree_medium", maketree(data.medium), { Asset("ANIM", "anim/mushroom_tree_med.zip"), Asset("ANIM", "anim/mushroom_tree_med_bloom.zip") }, prefabs),
       Prefab("cave/objects/mushtree_small", maketree(data.small), { Asset("ANIM", "anim/mushroom_tree_small.zip"), Asset("ANIM", "anim/mushroom_tree_small_bloom.zip") }, prefabs)
