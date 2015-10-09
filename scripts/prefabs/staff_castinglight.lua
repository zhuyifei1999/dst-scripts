local easing = require("easing")

local function RGBToUint(r, g, b)
    return math.floor(r * 255 + 0.5) * 65536 +
        math.floor(g * 255 + 0.5) * 256 +
        math.floor(b * 255 + 0.5)
end

local function UintToRGB(c)
    local r = math.floor(c / 65536)
    c = c - r * 65536
    local g = math.floor(c / 256)
    return r, g, c - g * 256
end

local function OnUpdate(inst)
    inst.LightTimer = inst.LightTimer + FRAMES

    if inst.LightTimer < inst.LightDuration then
        inst.Light:SetRadius(easing.inQuint(inst.LightTimer, 0.3, 10, inst.LightDuration))
        inst.Light:SetIntensity(easing.inQuint(inst.LightTimer, 0.8, -0.6, inst.LightDuration))
        inst.Light:SetFalloff(easing.inQuint(inst.LightTimer, 0.9, -0.4, inst.LightDuration))
    else
        inst:Remove()
    end
end

local function PlayLightAnim(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddLight()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.LightTimer = 0
    inst.LightDuration = proxy._duration:value()

    inst.Light:SetColour(UintToRGB(proxy._colour:value()))
    inst.Light:SetRadius(0.3)
    inst.Light:SetIntensity(.8)
    inst.Light:SetFalloff(0.9)

    inst:DoPeriodicTask(FRAMES, OnUpdate, proxy._delay:value())
end

local function OnSetUpDirty(inst)
    if inst._complete or inst._colour:value() <= 0 then
        return
    end

    --Delay one frame so that all setup params are synced
    --or in case we are about to be removed
    inst:DoTaskInTime(0, PlayLightAnim)
    inst._complete = true
end

local function SetUp(inst, colour, duration, delay)
    inst._colour:set(RGBToUint(unpack(colour)))
    inst._duration:set(duration)
    inst._delay:set(delay or 0)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst._colour = net_uint(inst.GUID, "_colour", "setupdirty")
    inst._duration = net_float(inst.GUID, "_duration")
    inst._delay = net_float(inst.GUID, "_delay")
    inst._complete = false

    inst:ListenForEvent("setupdirty", OnSetUpDirty)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetUp = SetUp

    inst:AddTag("FX")
    inst.persists = false

    inst:DoTaskInTime(1.5, inst.Remove)

    return inst
end

return Prefab("staff_castinglight", fn)