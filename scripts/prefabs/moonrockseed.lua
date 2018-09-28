local easing = require("easing")

local assets =
{
    Asset("ANIM", "anim/moonrock_seed.zip"),
}

local prefabs =
{
    "moonrockseedfx",
}

local function updatelight(inst)
    inst._light = inst._light < inst._targetlight and math.min(inst._targetlight, inst._light + .04) or math.max(inst._targetlight, inst._light - .02)
    inst.AnimState:SetLightOverride(inst._light)
    if inst._light == inst._targetlight then
        inst._task:Cancel()
        inst._task = nil
    end
end

local function fadelight(inst, target, instant)
    inst._targetlight = target
    if inst._light ~= target then
        if instant then
            if inst._task ~= nil then
                inst._task:Cancel()
                inst._task = nil
            end
            inst._light = target
            inst.AnimState:SetLightOverride(target)
        elseif inst._task == nil then
            inst._task = inst:DoPeriodicTask(FRAMES, updatelight)
        end
    elseif inst._task ~= nil then
        inst._task:Cancel()
        inst._task = nil
    end
end

local function cancelblink(inst)
    if inst._blinktask ~= nil then
        inst._blinktask:Cancel()
        inst._blinktask = nil
    end
end

local function updateblink(inst, data)
    local c = easing.outQuad(data.blink, 0, 1, 1)
    inst.AnimState:SetAddColour(c, c, c, 0)
    if data.blink > 0 then
        data.blink = math.max(0, data.blink - .05)
    else
        inst._blinktask:Cancel()
        inst._blinktask = nil
    end
end

local function blink(inst)
    if inst._blinktask ~= nil then
        inst._blinktask:Cancel()
    end
    local data = { blink = 1 }
    inst._blinktask = inst:DoPeriodicTask(FRAMES, updateblink, nil, data)
    updateblink(inst, data)
end

local function dodropsound(inst, taskid, volume)
    inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt", nil, volume)
    inst._tasks[taskid] = nil
end

local function canceldropsounds(inst)
    local k, v = next(inst._tasks)
    while k ~= nil do
        v:Cancel()
        inst._tasks[k] = nil
        k, v = next(inst._tasks)
    end
end

local function scheduledropsounds(inst)
    inst._tasks[1] = inst:DoTaskInTime(6.5 * FRAMES, dodropsound, 1)
    inst._tasks[2] = inst:DoTaskInTime(13.5 * FRAMES, dodropsound, 2, .5)
    inst._tasks[3] = inst:DoTaskInTime(18.5 * FRAMES, dodropsound, 2, .15)
end

local function turnon(inst, instant)
    canceldropsounds(inst)
    inst.AnimState:PlayAnimation("proximity_pre")
    inst.AnimState:PushAnimation("proximity_loop", true)
    fadelight(inst, .15, instant)
    if not inst.SoundEmitter:PlayingSound("idlesound") then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/book_maxwell/active_LP", "idlesound")
    end
end

local function onturnon(inst)
    turnon(inst, false)
end

local function onturnoff(inst)
    canceldropsounds(inst)
    inst.SoundEmitter:KillSound("idlesound")
    if not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PlayAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
        fadelight(inst, 0, false)
        scheduledropsounds(inst)
    else
        inst.AnimState:PlayAnimation("idle")
        fadelight(inst, 0, true)
    end
end

local function onactivate(inst)
    blink(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/spawn_vines/spawnportal_open")
    SpawnPrefab("moonrockseedfx").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function topocket(inst)
    cancelblink(inst)
    onturnoff(inst)
end

local function toground(inst)
    if inst.components.prototyper.on then
        onturnon(inst, true)
    end
end

local function OnSpawned(inst)
    if not (inst.components.prototyper.on or inst.components.inventoryitem:IsHeld()) then
        canceldropsounds(inst)
        scheduledropsounds(inst)
        inst.AnimState:PlayAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("moonrock_seed")
    inst.AnimState:SetBuild("moonrock_seed")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("irreplaceable")

    inst.MiniMapEntity:SetIcon("moonrockseed.png")
    inst.MiniMapEntity:SetPriority(5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._tasks = {}
    inst._light = 0
    inst._targetlight = 0

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true

    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff
    inst.components.prototyper.onactivate = onactivate
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.MOONORB_LOW

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("onputininventory", topocket)
    inst:ListenForEvent("ondropped", toground)

    inst.OnSpawned = OnSpawned

    return inst
end

local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("moonrock_seed")
    inst.AnimState:SetBuild("moonrock_seed")
    inst.AnimState:PlayAnimation("use")
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false

    return inst
end

return Prefab("moonrockseed", fn, assets, prefabs),
    Prefab("moonrockseedfx", fxfn, assets)
