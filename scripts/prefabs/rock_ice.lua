local rock_ice_assets =
{
    Asset("ANIM", "anim/ice_boulder.zip"),
}

local prefabs =
{
    "ice",
    "rocks",
    "flint",
    "ice_puddle",
    "ice_splash",
}

local function SetLoot(inst, size)
    inst.components.lootdropper:SetLoot(nil)
    if size == "short" then
        inst.components.lootdropper:SetChanceLootTable('rock_ice_short')
    elseif size == "medium" then
        inst.components.lootdropper:SetChanceLootTable('rock_ice_medium')
    else
        inst.components.lootdropper:SetChanceLootTable('rock_ice_tall')
    end
end

local STAGES = {
    {
        name = "empty",
        animation = "melted",
        showrock = false,
        work = -1,
    },
    {
        name = "short",
        animation = "low",
        showrock = true,
        work = TUNING.ICE_MINE,
        icecount = 2,
    },
    {
        name = "medium",
        animation = "med",
        showrock = true,
        work = TUNING.ICE_MINE*0.67,
        icecount = 2,
    },
    {
        name = "tall",
        animation = "full",
        showrock = true,
        work = TUNING.ICE_MINE*0.67,
        icecount = 3,
    },
}

local STAGE_INDICES = {}
for i,v in ipairs(STAGES) do
    STAGE_INDICES[v.name] = i
end

local function SetStage(inst, stage, source)
    if stage == inst.stage then
        return
    end

    local target_workleft = TUNING.ICE_MINE

    local currentstage = STAGE_INDICES[inst.stage]
    local targetstage = STAGE_INDICES[stage]
    if (source == "melt" or source == "work") then
        if currentstage and currentstage > targetstage then
            targetstage = currentstage - 1
        else
            return
        end
    elseif source == "grow" then
        if currentstage and currentstage < targetstage then
            targetstage = currentstage + 1
        else
            return
        end
    end
    -- otherwise just set the stage to the target!

    inst.stage = STAGES[targetstage].name

    if STAGES[targetstage].showrock then
        inst.AnimState:PlayAnimation(STAGES[targetstage].animation)

        inst.AnimState:Show("rock")
        if TheWorld.state.snowlevel >= SNOW_THRESH then
            inst.AnimState:Show("snow")
        end
        inst.MiniMapEntity:SetEnabled(true)
        inst.components.named:SetName(STRINGS.NAMES["ROCK_ICE"])
        ChangeToObstaclePhysics(inst)
    else
        inst.AnimState:Hide("rock")
        inst.AnimState:Hide("snow")
        inst.MiniMapEntity:SetEnabled(false)
        inst.components.named:SetName(STRINGS.NAMES["ROCK_ICE_MELTED"])
        RemovePhysicsColliders(inst)
    end

    inst.puddle.AnimState:PlayAnimation(STAGES[targetstage].animation)
    if STAGES[targetstage].name == "empty" then inst.puddle.AnimState:PushAnimation("idle", true) end
    if source == "melt" then inst.splash.AnimState:PlayAnimation(STAGES[targetstage].animation) end

    local workable = inst and inst.components.workable or nil
    if workable then
        if source == "work" then
            local pt = Point(inst.Transform:GetWorldPosition())
            for i=1,math.random(1,STAGES[currentstage].icecount) do
                inst.components.lootdropper:SpawnLootPrefab("ice", pt)
            end
        end
        if STAGES[targetstage].work < 0 then
            workable:SetWorkable(false)
        else
            workable:SetWorkLeft(STAGES[targetstage].work)
        end
    end
end

local function OnWorked(inst, worker, workleft)
    if workleft <= 0 then
        SetStage(inst, "empty", "work")
        if inst.stage == "empty" then
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/iceboulder_smash")
        end
    end
end

local function TryStageChange(inst)
    if inst.components.workable and inst.components.workable.lastworktime and GetTime() - inst.components.workable.lastworktime < 10 then
        inst.components.timer:StartTimer("rock_ice_change", 30)
    end

    local pct = TheWorld.state.seasonprogress
    if TheWorld.state.isspring then
        if pct < inst.threshold1 then
            SetStage(inst, "tall", "melt")
        elseif pct < inst.threshold2 then
            SetStage(inst, "medium", "melt")
        elseif pct < inst.threshold3 then
            SetStage(inst, "short", "melt")
        else
            SetStage(inst, "empty", "melt")
        end
    elseif TheWorld.state.issummer then--and pct > .1 then
        SetStage(inst, "empty", "melt")
    elseif TheWorld.state.isautumn then
        if pct < inst.threshold1 then
            SetStage(inst, "empty", "grow")
        elseif pct < inst.threshold2 then
            SetStage(inst, "short", "grow")
        elseif pct < inst.threshold3 then
            SetStage(inst, "medium", "grow")
        else
            SetStage(inst, "tall", "grow")
        end
    elseif TheWorld.state.iswinter then--and pct > .1 then
        SetStage(inst, "tall", "grow")
    end
end

local function DayEnd(inst)
    if not inst.components.timer:TimerExists("rock_ice_change") then
        inst.components.timer:StartTimer("rock_ice_change", math.random(TUNING.TOTAL_DAY_TIME, TUNING.TOTAL_DAY_TIME*3))
    end
end

local function StartFireMelt(inst)
    if inst.firemelttask then return end

    inst.firemelttask = inst:DoTaskInTime(4, function(inst)
        SetStage(inst, "empty", "melt")
        inst.firemelttask = nil
    end)
end

local function StopFireMelt(inst)
    if inst.firemelttask then 
        inst.firemelttask:Cancel()
        inst.firemelttask = nil
    end
end

local function onsave(inst, data)
    data.stage = inst.stage
end

local function onload(inst, data)
    if data and data.stage then
        while inst.stage ~= data.stage do
            SetStage(inst, data.stage)
        end
    end
end

local function ontimerdone(inst, data)
    if data.name == "rock_ice_change" then
        TryStageChange(inst)
    end
end

local function rock_ice_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ice_boulder")
    inst.AnimState:SetBuild("ice_boulder")

    MakeObstaclePhysics(inst, 1)
    
    inst.MiniMapEntity:SetIcon("iceboulder.png")

    inst:AddTag("frozen")
    MakeSnowCoveredPristine(inst)

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst:AddComponent("lootdropper") 
    SetLoot(inst, "tall")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.ICE_MINE)

    inst.components.workable:SetOnWorkCallback( OnWorked )

    inst:AddComponent("named")
    inst.components.named:SetName(STRINGS.NAMES["ROCK_ICE"])

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst, viewer)
        if inst.stage == "empty" then
            return "MELTED"
        end
    end

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst.puddle = SpawnPrefab("ice_puddle")
    inst.splash = SpawnPrefab("ice_splash")
    inst:AddChild(inst.puddle)    
    inst.puddle.Transform:SetPosition(0,0,0)
    inst:AddChild(inst.splash)    
    inst.splash.Transform:SetPosition(0,0,0)

    -- Make sure we start at a good height for starting in a season when it shouldn't start as full
    inst:DoTaskInTime(0, function()
        if inst.stage then
            SetStage(inst, inst.stage)
        elseif TheWorld.state.isspring or TheWorld.state.iswinter then
            SetStage(inst, "tall")
        else
            SetStage(inst, "empty")
        end
    end)

    -- Bias to changing towards end of seasons, these suckers have a lot of thermal momentum!
    inst.threshold1 = Lerp(.4,.6,math.random())
    inst.threshold2 = Lerp(.65,.85,math.random())
    inst.threshold3 = Lerp(.9,1.1,math.random())

    inst:ListenForEvent("firemelt", StartFireMelt)
    inst:ListenForEvent("stopfiremelt", StopFireMelt)

    inst:WatchWorldState("cycles", DayEnd)

    inst.OnSave = onsave
    inst.OnLoad = onload

    MakeSnowCoveredPristine(inst)

    MakeHauntableWork(inst)

    return inst
end

return Prefab("forest/objects/rocks/rock_ice", rock_ice_fn, rock_ice_assets, prefabs)