local assets =
{
   Asset("ANIM", "anim/star.zip")
}

local PULSE_SYNC_PERIOD = 30

--Needs to save/load time alive.

local function kill_sound(inst)
    inst.SoundEmitter:KillSound("staff_star_loop")
end

local function kill_light(inst)
    inst.AnimState:PlayAnimation("disappear")
    inst:ListenForEvent("animover", kill_sound)
    inst:DoTaskInTime(1, inst.Remove) --originally 0.6, padded for network
end

local function resumestar(inst, time)
    if inst.death then
        inst.death:Cancel()
        inst.death = nil
    end
    inst.death = inst:DoTaskInTime(time, kill_light)
    inst.timeleft = time
end

local function onsave(inst, data)
    data.timealive = inst:GetTimeAlive()
    data.init_time = inst.init_time
end

local function onload(inst, data)
        if data.timealive and data.init_time then
            inst.init_time = data.init_time
            local timeleft = (inst.init_time or 120) - data.timealive
            if timeleft > 0 then
            resumestar(inst, timeleft)
        else
            kill_light(inst)
        end
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
    inst.entity:AddSoundEmitter()
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

    inst.init_time = 120
    inst.death = inst:DoTaskInTime(inst.init_time, kill_light)

    inst.Light:SetColour(223/255, 208/255, 69/255)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst.AnimState:SetBank("star")
    inst.AnimState:SetBuild("star")
    inst.AnimState:PlayAnimation("appear")
    inst.AnimState:PushAnimation("idle_loop", true)

    inst:AddComponent("inspectable")

    inst:AddComponent("cooker")

    inst:AddComponent("propagator")
    inst.components.propagator.heatoutput = 15
    inst.components.propagator.spreading = true
    inst.components.propagator:StartUpdating()

    inst:AddComponent("heater")
    inst.components.heater.heat = 180

    inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_create")
    inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_LP", "staff_star_loop")    

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        kill_light(inst)
        return true
    end)

    inst.OnLoad = onload
    inst.OnSave = onsave

    return inst
end

return Prefab("common/stafflight", fn, assets)