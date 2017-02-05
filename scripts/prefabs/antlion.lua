local assets =
{
    Asset("ANIM", "anim/antlion_build.zip"),
    Asset("ANIM", "anim/antlion_basic.zip"),
    Asset("ANIM", "anim/antlion_action.zip"),
}

local prefabs =
{
    "antlion_sinkhole",
    "townportal_blueprint",
    "townportaltalisman",
    "antliontrinket",
}

local function Despawn(inst)
    if inst.persists then
        inst.persists = false
        if inst:IsAsleep() then
            inst:Remove()
        else
            inst.components.sinkholespawner:StopSinkholes()
            inst:PushEvent("antlion_leaveworld")
        end
    end
end

local function AcceptTest(inst, item)
    return ((item.components.tradable.rocktribute ~= nil and item.components.tradable.rocktribute > 0) 
                or (item.components.tradable.goldvalue ~= nil and item.components.tradable.goldvalue > 0))
            and not item:HasTag("meat")
            and inst.pendingrewarditem == nil
end

local function OnGivenItem(inst, giver, item)
    inst.pendingrewarditem = (item.prefab == "antliontrinket" and "townportal_blueprint") or 
                             (item.components.tradable.goldvalue > 0 and "townportaltalisman") or
                             nil
    inst.tributer = giver

    local rage_calming = (item.components.tradable.rocktribute ~= nil and item.components.tradable.rocktribute or math.ceil(item.components.tradable.goldvalue / 3)) * TUNING.ANTLION_TRIBUTE_TO_RAGE_TIME
    inst.maxragetime = math.min(inst.maxragetime + rage_calming, TUNING.ANTLION_RAGE_TIME_MAX)

    local timeleft = inst.components.timer:GetTimeLeft("rage")
    if timeleft ~= nil then
        timeleft = math.min(timeleft + rage_calming, TUNING.ANTLION_RAGE_TIME_MAX)
        inst.components.timer:SetTimeLeft("rage", timeleft)
    else
        inst.components.timer:StartTimer("rage", inst.maxragetime)
    end
    inst.components.sinkholespawner:StopSinkholes()

    inst:PushEvent("onaccepttribute", {tributepercent = (timeleft or 0)/TUNING.ANTLION_RAGE_TIME_MAX})

    if giver ~= nil and giver.components.talker ~= nil and (GetTime() - (inst.timesincelasttalker or -TUNING.ANTLION_TRIBUTER_TALKER_TIME)) > TUNING.ANTLION_TRIBUTER_TALKER_TIME then
        inst.timesincelasttalker = GetTime()
        giver.components.talker:Say(GetString(giver, "ANNOUNCE_ANTLION_TRIBUTE"))
    end
end

local function OnRefuseItem(inst, giver, item)
    inst:PushEvent("onrefusetribute")
end

-- c_sel():PushEvent("timerdone", {name="rage"})
local function ontimerdone(inst, data)
    if data.name == "rage" then
        inst.components.sinkholespawner:StartSinkholes()

        inst.maxragetime = math.max(inst.maxragetime * TUNING.ANTLION_RAGE_TIME_FAILURE_SCALE, TUNING.ANTLION_RAGE_TIME_MIN)
        inst.components.timer:StartTimer("rage", inst.maxragetime)
    end
end

local function HasRewardToGive(inst)
    return inst.pendingrewarditem ~= nil
end

local function GiveReward(inst)
    LaunchAt(SpawnPrefab(inst.pendingrewarditem), inst, (inst.tributer ~= nil and inst.tributer:IsValid()) and inst.tributer or nil, 1, 2, 1)
    inst.pendingrewarditem = nil
    inst.tributer = nil
end

local function GetRageLevel(inst)
    local ragetimepercent = (inst.components.timer:GetTimeLeft("rage") or 0) / TUNING.ANTLION_RAGE_TIME_MAX
    return (ragetimepercent <= TUNING.ANTLION_RAGE_TIME_UNHAPPY_PERCENT and 3) or
           (ragetimepercent <= TUNING.ANTLION_RAGE_TIME_HAPPY_PERCENT and 2) or
           1
end

local function getstatus(inst)
    local level = GetRageLevel(inst)
    return (level == 1 and "VERYHAPPY") or
           (level == 3 and "UNHAPPY") or
           nil
end

local function OnInit(inst)
    inst:ListenForEvent("ms_sandstormchanged", function(src, data)
        if not data then
            Despawn(inst)
        end
    end, TheWorld)
    if not (TheWorld.components.sandstorms ~= nil and TheWorld.components.sandstorms:IsSandstormActive()) then
        Despawn(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("antlion")
    inst.AnimState:SetBuild("antlion_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("antlion.png")
    inst.MiniMapEntity:SetPriority(1)

    MakeObstaclePhysics(inst, 1.5)

    inst:AddTag("antlion")
    inst:AddTag("trader")
    inst:AddTag("antlion_sinkhole_blocker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.maxragetime = TUNING.ANTLION_RAGE_TIME_INITIAL

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader.onaccept = OnGivenItem
    inst.components.trader.onrefuse = OnRefuseItem

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)
    inst.components.timer:StartTimer("rage", TUNING.ANTLION_RAGE_TIME_INITIAL)

    inst:AddComponent("sinkholespawner")
    inst:AddComponent("lootdropper")

    inst.GiveReward = GiveReward
    inst.HasRewardToGive = HasRewardToGive
    inst.GetRageLevel = GetRageLevel

    inst:SetStateGraph("SGantlion")

    inst:DoTaskInTime(0, OnInit)

    return inst
end

return Prefab("antlion", fn, assets, prefabs)
