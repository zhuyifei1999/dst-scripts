local assets =
{
    Asset("ANIM", "anim/staff.zip"),
}

local MAX_LAG = 1.5
local COMPLETE = 4294967295 --0xFFFFFFFF

local function RGBToUint(r, g, b)
    return math.floor(r * 255 + 0.5) * 65536 +
        math.floor(g * 255 + 0.5) * 256 +
        math.floor(b * 255 + 0.5)
end

local function UintToRGBA(c)
    local r = math.floor(c / 65536)
    c = c - r * 65536
    local g = math.floor(c / 256)
    return r, g, c - g * 256, 1
end

local function PlayCastAnim(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.AnimState:SetBank("staff_fx")
    inst.AnimState:SetBuild("staff")
    inst.AnimState:PlayAnimation("staff")
    inst.AnimState:SetMultColour(UintToRGBA(proxy._colour:value()))

    inst:ListenForEvent("animover", inst.Remove)

    --If proxy removed, check if completed or cancelled on server
    inst:ListenForEvent("onremove", function()
        if proxy._colour:value() ~= COMPLETE then
            inst:Remove()
        end
    end, proxy)

    if TheWorld.ismastersim then
        --Complete on server: removing the proxy shouldn't cancel client fx
        proxy:ListenForEvent("onremove", function()
            proxy._colour:set(COMPLETE)
            proxy:DoTaskInTime(MAX_LAG, proxy.Remove)
        end, inst)
    end
end

local function OnSetUpDirty(inst)
    if inst._complete or inst._colour:value() <= 0 or inst._colour:value() == COMPLETE then
        return
    end

    --Delay one frame so that all setup params are synced
    --or in case we are about to be removed
    inst:DoTaskInTime(0, PlayCastAnim)
    inst._complete = true
end

local function SetUp(inst, colour)
    inst._colour:set(RGBToUint(unpack(colour)))
end

local function Disable(inst)
    if inst._colour:value() ~= COMPLETE then
        inst._colour:set_local(0)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst._colour = net_uint(inst.GUID, "_colour", "setupdirty")
    inst._complete = false

    inst:ListenForEvent("setupdirty", OnSetUpDirty)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Transform:SetFourFaced()

    inst.SetUp = SetUp

    inst:AddTag("FX")
    inst.persists = false

    --Disable instead of remove, because spawned fx also listens to the
    --proxy state in order to remove itself (since fx can be cancelled)
    inst:DoTaskInTime(MAX_LAG, Disable)

    return inst
end

return Prefab("staffcastfx", fn, assets)