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
    inst.components.lootdropper:SetChanceLootTable(
        (size == "short" and "rock_ice_short") or
        (size == "medium" and "rock_ice_medium") or
        "rock_ice_tall"
    )
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
for i, v in ipairs(STAGES) do
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

    if inst.components.workable ~= nil then
        if source == "work" then
            local pt = inst:GetPosition()
            for i = 1, math.random(STAGES[currentstage].icecount) do
                inst.components.lootdropper:SpawnLootPrefab("ice", pt)
            end
        end
        if STAGES[targetstage].work < 0 then
            inst.components.workable:SetWorkable(false)
        else
            inst.components.workable:SetWorkLeft(STAGES[targetstage].work)
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

local function RescheduleTimer(inst)
    if not inst.components.timer:TimerExists("rock_ice_change") then
        inst.components.timer:StartTimer("rock_ice_change", 30)
    end
end

local function TryStageChange(inst)
    if inst.components.workable ~= nil and
        inst.components.workable.lastworktime ~= nil and
        GetTime() - inst.components.workable.lastworktime < 10 then
        --Reschedule if we recently worked it
        --V2C: Can't StartTimer immediately, because we are in a handler
        --     triggered by the same timer name that we want to restart.
        inst:DoTaskInTime(0, RescheduleTimer)
        return
    end

    local pct = TheWorld.state.seasonprogress
    if TheWorld.state.isspring then
        SetStage(
            inst,
            (pct < inst.threshold1 and "tall") or
            (pct < inst.threshold2 and "medium") or
            (pct < inst.threshold3 and "short") or
            "empty",
            "melt"
        )
    elseif TheWorld.state.issummer then
        --if pct > .1 then
            SetStage(inst, "empty", "melt")
        --end
    elseif TheWorld.state.isautumn then
        SetStage(
            inst,
            (pct < inst.threshold1 and "empty") or
            (pct < inst.threshold2 and "short") or
            (pct < inst.threshold3 and "medium") or
            "tall",
            "grow"
        )
    elseif TheWorld.state.iswinter then
        --if pct > .1 then
            SetStage(inst, "tall", "grow")
        --end
    end
end

local function DayEnd(inst)
    if not inst.components.timer:TimerExists("rock_ice_change") then
        inst.components.timer:StartTimer("rock_ice_change", math.random(TUNING.TOTAL_DAY_TIME, TUNING.TOTAL_DAY_TIME * 3))
    end
end

local function _OnFireMelt(inst)
    inst.firemelttask = nil
    SetStage(inst, "empty", "melt")
end

local function StartFireMelt(inst)
    if inst.firemelttask == nil then
        inst.firemelttask = inst:DoTaskInTime(4, _OnFireMelt)
    end
end

local function StopFireMelt(inst)
    if inst.firemelttask ~= nil then 
        inst.firemelttask:Cancel()
        inst.firemelttask = nil
    end
end

local function onsave(inst, data)
    data.stage = inst.stage
end

local function onload(inst, data)
    if data ~= nil and data.stage ~= nil then
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

local function GetStatus(inst)
    return inst.stage == "empty" and "MELTED" or nil
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
    inst.components.inspectable.getstatus = GetStatus

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
