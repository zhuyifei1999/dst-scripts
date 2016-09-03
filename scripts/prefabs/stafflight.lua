local PULSE_SYNC_PERIOD = 30

--Needs to save/load time alive.

local function kill_sound(inst)
    inst.SoundEmitter:KillSound("staff_star_loop")
end

local function kill_light(inst)
    inst.AnimState:PlayAnimation("disappear")
    inst:ListenForEvent("animover", kill_sound)
    inst:DoTaskInTime(1, inst.Remove) --originally 0.6, padded for network
    inst.persists = false
end

local function ontimer(inst, data)
    if data.name == "extinguish" then
        kill_light(inst)
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
    local rad = Lerp(11, 12, s)
    local intentsity = Lerp(0.8, 0.7, s)
    local falloff = Lerp(0.8, 0.7, s) 
    inst.Light:SetFalloff(falloff)
    inst.Light:SetIntensity(intentsity)
    inst.Light:SetRadius(rad)
end

local function onhaunt(inst)
    if inst.components.timer:TimerExists("extinguish") then
        inst.components.timer:StopTimer("extinguish")
        kill_light(inst)
    end
    return true
end

local function makestafflight(name, is_hot, anim, colour, idles)
    local assets =
    {
        Asset("ANIM", "anim/"..anim..".zip"),
    }

    local PlayRandomStarIdle = #idles > 1 and function(inst)
        --Don't if we're extinguished
        if inst.persists then
            inst.AnimState:PlayAnimation(idles[math.random(#idles)])
        end
    end or nil

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

        inst.Light:SetColour(unpack(colour))
        inst.Light:Enable(false)
        inst.Light:EnableClientModulation(true)

        inst.AnimState:SetBank(anim)
        inst.AnimState:SetBuild(anim)
        inst.AnimState:PlayAnimation("appear")
        if #idles == 1 then
            inst.AnimState:PushAnimation(idles[1], true)
        end
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

        inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_LP", "staff_star_loop")

        --HASHEATER (from heater component) added to pristine state for optimization
        inst:AddTag("HASHEATER")

        if is_hot then
            --cooker (from cooker component) added to pristine state for optimization
            inst:AddTag("cooker")

            inst:AddTag("daylight")
        end

        inst.no_wet_prefix = true

        inst.entity:SetPristine()

        if not inst._ismastersim then
            inst:ListenForEvent("pulsetimedirty", onpulsetimedirty)
            return inst
        end

        inst._pulsetime:set(inst:GetTimeAlive())
        inst._lastpulsesync = inst._pulsetime:value()

        inst:AddComponent("inspectable")

        if is_hot then
            inst:AddComponent("cooker")

            inst:AddComponent("propagator")
            inst.components.propagator.heatoutput = 15
            inst.components.propagator.spreading = true
            inst.components.propagator:StartUpdating()
        end

        inst:AddComponent("heater")
        if is_hot then
            inst.components.heater.heat = 100
        else
            inst.components.heater.heat = -100
            inst.components.heater:SetThermics(false, true)
        end

        inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_create")

        inst:AddComponent("sanityaura")
        inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
        inst.components.hauntable:SetOnHauntFn(onhaunt)

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("extinguish", is_hot and TUNING.YELLOWSTAFF_STAR_DURATION or TUNING.OPALSTAFF_STAR_DURATION)
        inst:ListenForEvent("timerdone", ontimer)

        if #idles > 1 then
            inst:ListenForEvent("animover", PlayRandomStarIdle)
        end

        return inst
    end

    return Prefab(name, fn, assets)
end

return makestafflight("stafflight", true, "star_hot", { 223 / 255, 208 / 255, 69 / 255 }, { "idle_loop" }),
       makestafflight("staffcoldlight", false, "star_cold", { 64 / 255, 64 / 255, 208 / 255 }, { "idle_loop", "idle_loop2", "idle_loop3" })
