local assets =
{
    Asset("ANIM", "anim/bulb_plant_single.zip"),
    Asset("ANIM", "anim/bulb_plant_double.zip"),
    Asset("ANIM", "anim/bulb_plant_triple.zip"),
    Asset("ANIM", "anim/bulb_plant_springy.zip"),
    Asset("SOUND", "sound/common.fsb"),
	Asset("MINIMAP_IMAGE", "bulb_plant"),
}

local prefabs =
{
    "lightbulb",
}

local LIGHT_STATES =
{
    ON = "ON", --Light current on.
    CHARGED = "CHARGED", --Light currently off but ready to turn on.
    RECHARGING = "RECHARGING", --Light current off and is unable to turn on.
}

local STATE_ANIMS =
{
    [LIGHT_STATES.ON] = { "recharge", "idle" },
    [LIGHT_STATES.CHARGED] = { "revive", "off" },
    [LIGHT_STATES.RECHARGING] = { "drain", "withered" },
}

local function SetLightState(inst, state)
    inst.AnimState:PlayAnimation(STATE_ANIMS[state][1])
    for i=2,#STATE_ANIMS[state] do
        inst.AnimState:PushAnimation(STATE_ANIMS[state][i], STATE_ANIMS[state][i] == "idle")
    end
    inst.light_state = state
end

local function CanTurnOn(inst)
    return inst.light_state == LIGHT_STATES.CHARGED -- and not inst.components.pickable.picked
end

local function ForceOff(inst)
    if inst.light_state == LIGHT_STATES.ON then
        inst:SetLightState(LIGHT_STATES.RECHARGING)
    end
    inst.components.lighttweener:EndTween()
    inst.Light:Enable(false)
end

local function ForceOn(inst)
    if not inst.components.pickable:CanBePicked() then
        return
    end

    inst:SetLightState(LIGHT_STATES.ON)

    inst.components.lighttweener:EndTween()
    inst.Light:Enable(true)
    inst.Light:SetRadius(inst.light_radius)
    inst.Light:SetIntensity(inst.light_intensity)
    inst.Light:SetFalloff(inst.light_falloff)
end

local function TurnOff(inst)
    --Light turns off and starts to charge.
    local tween_time = math.random(4,8)
    inst.components.timer:StartTimer("recharge", TUNING.FLOWER_CAVE_RECHARGE_TIME + tween_time)
    inst:SetLightState(LIGHT_STATES.RECHARGING)
    inst.components.lighttweener:StartTween(inst.Light, 0, 0, 1, nil, tween_time, function() inst.Light:Enable(false) end)
end

local function TurnOn(inst)
    if not inst.components.pickable:CanBePicked() then
        return
    end

    --Turn turns on and starts to decharge
    if not inst:CanTurnOn() then return end

    inst.Light:Enable(true)
    inst:SetLightState(LIGHT_STATES.ON)
    local tween_time = math.random(4,8)
    inst.components.lighttweener:StartTween(inst.Light, inst.light_radius * 1.33, inst.light_intensity, inst.light_falloff * 0.8, nil, tween_time * 0.33,
    function()
        inst.components.lighttweener:StartTween(inst.Light, inst.light_radius, inst.light_intensity, inst.light_falloff, nil, tween_time * 0.64)
    end)
    inst.components.timer:StartTimer("turnoff", TUNING.FLOWER_CAVE_LIGHT_TIME + tween_time + (math.random() * 10))
end

local function Recharge(inst)
    --Light is finished charging and can turn on again.
    inst:SetLightState(LIGHT_STATES.CHARGED)
    if inst.LightWatcher:IsInLight() then
        TurnOn(inst)
    end
end

local function ontimerdone(inst, data)
    if data.name == "recharge" then
        Recharge(inst)
    elseif data.name == "turnoff" then
        TurnOff(inst)
    end
end

local function enterlight(inst)
    TurnOn(inst)
end

local function onregenfn(inst)
    TurnOff(inst) -- starts recharging

    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function makefullfn(inst)
    inst.AnimState:PlayAnimation("idle", true)
end

local function onpickedfn(inst)
    ForceOff(inst)
    inst.components.timer:StopTimer("turnoff")
    inst.components.timer:StopTimer("recharge")

    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lightbulb")
    inst.AnimState:PlayAnimation("picking")

    if inst.components.pickable:IsBarren() then
        inst.AnimState:PushAnimation("idle_dead")
    else
        inst.AnimState:PushAnimation("picked")
    end
end

local function makeemptyfn(inst)
    ForceOff(inst)
    inst.components.timer:StopTimer("turnoff")
    inst.components.timer:StopTimer("recharge")

    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation("picked")
end

local function onburnt(inst)
    TheWorld:PushEvent("beginregrowth", inst)
    DefaultBurntFn(inst)
end

local function OnSave(inst, data)
    data.light_state = inst.light_state
end

local function OnLoad(inst, data)
    if data == nil then return end

    inst.light_state = data.light_state

    if inst.components.pickable:CanBePicked() then
        if inst.light_state == LIGHT_STATES.ON then
            ForceOn(inst)
        elseif inst.light_state == LIGHT_STATES.CHARGED
            or inst.light_state == LIGHT_STATES.RECHARGING then
            ForceOff(inst)
        end
    else
        ForceOff(inst)
    end
end

local function TurnOnInLight(inst)
    if inst.LightWatcher:IsInLight() then
        TurnOn(inst)
    end
end

local function OnWake(inst)
    -- lightwatcher initializes to "in light", so wait a frame (or a few, apparently)
    inst:DoTaskInTime(1, TurnOnInLight)
end

local function GetDebugString(inst)
    return string.format("State: %s", inst.light_state)
end

local function commonfn(bank, build, masterfn)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

    inst.LightWatcher:SetLightThresh(.075)
    inst.LightWatcher:SetDarkThresh(.05)

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0)
    inst.Light:SetRadius(0)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(false)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("off")

    inst.MiniMapEntity:SetIcon("bulb_plant.png")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.light_state = LIGHT_STATES.CHARGED

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("timer")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.makefullfn = makefullfn
    inst.components.pickable.max_cycles = 20
    inst.components.pickable.cycles_left = 20

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    inst:AddComponent("lighttweener")

    ---------------------
    MakeMediumBurnable(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    MakeSmallPropagator(inst)
    ---------------------

    inst.CanTurnOn = CanTurnOn
    inst.SetLightState = SetLightState

    inst.TurnOn = TurnOn

    inst:ListenForEvent("timerdone", ontimerdone)
    inst:ListenForEvent("enterlight", enterlight)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave
    inst.OnEntityWake = OnWake
    inst.debugstringfn = GetDebugString

    MakeHauntableIgnite(inst)

    if masterfn ~= nil then
        masterfn(inst)
    end

    return inst
end

local plantnames = {"_single", "_springy"}

local function onsave_single(inst, data)
    OnSave(inst, data)
    data.plantname = inst.plantname
end

local function onload_single(inst,data)
    OnLoad(inst, data)
    if data ~= nil and data.plantname ~= nil then
        inst.plantname = data.plantname
        inst.AnimState:SetBank("bulb_plant"..inst.plantname)
        inst.AnimState:SetBuild("bulb_plant"..inst.plantname)
    end
end

local function single()
    return commonfn(
        "bulb_plant_single",
        "bulb_plant_single",
        function(inst)

            inst.plantname = plantnames[math.random(1, #plantnames)]
            inst.AnimState:SetBank("bulb_plant"..inst.plantname)
            inst.AnimState:SetBuild("bulb_plant"..inst.plantname)

            inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME)

            inst.light_falloff = 0.5
            inst.light_intensity = 0.8
            inst.light_radius = 3

            inst.OnSave = onsave_single
            inst.OnLoad = onload_single

        end)
end

local function double()
    return commonfn(
        "bulb_plant_double",
        "bulb_plant_double",
        function(inst)

            inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME * 1.5, 2)

            inst.light_falloff = 0.5
            inst.light_intensity = 0.8
            inst.light_radius = 4.5

        end)
end

local function triple()
    return commonfn(
        "bulb_plant_triple",
        "bulb_plant_triple",
        function(inst)

            inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME * 2, 3)

            inst.light_falloff = 0.5
            inst.light_intensity = 0.8
            inst.light_radius = 4.5

        end)
end

return Prefab("flower_cave", single, assets, prefabs),
    Prefab("flower_cave_double", double, assets, prefabs),
    Prefab("flower_cave_triple", triple, assets, prefabs)
