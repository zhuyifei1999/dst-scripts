local assets =
{
    Asset("ANIM", "anim/charlie_basic.zip"),
    Asset("ANIM", "anim/charlie_transform.zip"),
}

local KNOWS_CHARLIE_LOOKUP =
{
    winona  = true,
    waxwell = true,
}

local function OnRemove(inst)
    -- Charliecutscene cmp save/load will handle this not running.
    if inst.atrium ~= nil and inst.atrium.components.charliecutscene ~= nil then
        if inst.socketing_key then
            inst.atrium.components.charliecutscene:FinishKeySocket()
        else
            inst.atrium.components.charliecutscene:Finish()
        end
    end
end

local function StartCastingWithDelay(inst, delay, cast_time, nodespawn)
    inst:PushEventInTime(delay, "casting")
    inst:PushEventInTime(delay + cast_time, "stop_casting", { despawn = not nodespawn })
end

local function StartCasting2WithDelay(inst, delay, cast_time)
    inst.components.npc_talker:Chatter("CHARLIE_NPC_SACRIFICE_REQUEST")
    inst:PushEventInTime(delay, "casting2")
    inst:PushEventInTime(delay + cast_time, "stop_casting")
end

local function GetStatus(inst)--, viewer)
    return (inst.socketing_key or inst.ritualnagtask and "SCENE2")
        or nil
end

local function OnEntityWake(inst)
	inst.OnEntityWake = nil
    inst.SoundEmitter:PlaySound("rifts2/charlie/charlie_amb", "loop")
end

local function OnDoneTalking(inst)
    if inst.talktask ~= nil then
        inst.talktask:Cancel()
        inst.talktask = nil
    end
    inst.SoundEmitter:KillSound("talk")
end

local function OnTalk(inst)
    OnDoneTalking(inst)
    inst.SoundEmitter:PlaySound("dontstarve/charlie/talk_LP", "talk")
    local timeouttalk = (2 + math.random() * .5)
    inst.talktask = inst:DoTaskInTime(timeouttalk, OnDoneTalking)
end

local function DisplayNameFn(inst)
    return ThePlayer ~= nil and KNOWS_CHARLIE_LOOKUP[ThePlayer.prefab]
        and STRINGS.NAMES[string.upper(inst.prefab)]
        or STRINGS.NAMES[string.upper(inst.prefab.."_ALT")]
end

local CHARLIE_NAME_COLOUR = Vector3(234/255, 69/255, 75/255)
local CHARLIE_TEXT_COLOUR = Vector3(255/255, 103/255, 94/255)
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.5)

    inst.DynamicShadow:SetSize(3, 2)
    inst.DynamicShadow:Enable(true)

    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBank("charlie_basic")
    inst.AnimState:SetBuild("charlie_basic")
    inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("character")
    inst:AddTag("charlie_npc")

    local talker = inst:AddComponent("talker")
    talker.fontsize = 50
    talker.font = TALKINGFONT_CHARLIE
    talker.offset = Vector3(0, -600, 0)
    talker.name_colour = CHARLIE_NAME_COLOUR
    talker.colour = CHARLIE_TEXT_COLOUR
    talker.chaticon = "npcchatflair_charlie"
    talker:MakeChatter()

    local npc_talker = inst:AddComponent("npc_talker")
    npc_talker.default_chatpriority = CHATPRIORITIES.HIGH
    npc_talker.speaktime = 2.5

    inst.entity:SetPristine()

    inst.displaynamefn = DisplayNameFn

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.persists = false
    inst.StartCastingWithDelay = StartCastingWithDelay
    inst.StartCasting2WithDelay = StartCasting2WithDelay
    inst.OnRemoveEntity = OnRemove
    inst.OnEntityWake = OnEntityWake

    inst:SetStateGraph("SGcharlie_npc")
    inst:ListenForEvent("ontalk", OnTalk)
    inst:ListenForEvent("donetalking", OnDoneTalking)

    return inst
end

return Prefab("charlie_npc", fn, assets)