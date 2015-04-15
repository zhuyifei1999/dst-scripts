local assets =
{
   Asset("ANIM", "anim/star.zip")
}

local PULSE_SYNC_PERIOD = 30

--Needs to save/load time alive.

local function kill_light(inst)
    inst.AnimState:PlayAnimation("disappear")
    inst:DoTaskInTime(1, inst.Remove) --originally 0.6, padded for network
end

local function onsave(inst, data)
end

local function onload(inst, data)
    if TheWorld.state.isday then
        inst:Remove()
    end
end

local function onpulsetimedirty(inst)
    inst._pulseoffs = inst._pulsetime:value() - inst:GetTimeAlive()
end

local function pulse_light(inst)
    local timealive = inst:GetTimeAlive()

    if inst._ismastersim then
        if timealive - inst._lastpulsesync > PULSE_SYNC_PERIOD then
            inst._pulsetime:set(timealive)
            inst._lastpulsesync = timealive
        else
            inst._pulsetime:set_local(timealive)
        end

        inst.Light:Enable(true)
    end

    --Client light modulation is enabled:

    --local s = GetSineVal(0.05, true, inst)
    local s = math.abs(math.sin(PI * (timealive + inst._pulseoffs) * 0.05))
    local rad = Lerp(4, 5, s)
    local intentsity = Lerp(0.8, 0.7, s)
    local falloff = Lerp(0.8, 0.7, s) 
    inst.Light:SetFalloff(falloff)
    inst.Light:SetIntensity(intentsity)
    inst.Light:SetRadius(rad)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst._ismastersim = TheWorld.ismastersim
    inst._pulseoffs = 0
    inst._pulsetime = net_float(inst.GUID, "_pulsetime", "pulsetimedirty")

    inst:DoPeriodicTask(0.1, pulse_light)

    if not inst._ismastersim then
        inst:ListenForEvent("pulsetimedirty", onpulsetimedirty)
        return inst
    end

    inst._pulsetime:set(inst:GetTimeAlive())
    inst._lastpulsesync = inst._pulsetime:value()

    inst:WatchWorldState("cycles", kill_light)

    inst.Light:SetColour(223/255, 208/255, 69/255)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst.AnimState:SetBank("star")
    inst.AnimState:SetBuild("star")
    inst.AnimState:PlayAnimation("appear")
    inst.AnimState:PushAnimation("idle_loop", true)

    --#srosen will likely need to update this for RoG Summer spawn
    inst:AddComponent("heater")
    inst.components.heater.heat = 180 

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.OnLoad = onload
    inst.OnSave = onsave

    return inst
end

return Prefab("common/spawnlight_multiplayer", fn, assets)