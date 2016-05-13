local assets =
{
    Asset("ANIM", "anim/book_fx.zip")
}

local MAX_LAG = 1.5

local function PlayBookFX(proxy, tint, tintalpha, anim)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.Transform:SetFromProxy(proxy.GUID)

    local parent = proxy.entity:GetParent()
    if parent ~= nil then
        inst.Transform:SetPosition(parent.Transform:GetWorldPosition())
        inst.Transform:SetRotation(parent.Transform:GetRotation())
    end

    inst.AnimState:SetBank("book_fx")
    inst.AnimState:SetBuild("book_fx")
    inst.AnimState:PlayAnimation(anim)
    --inst.AnimState:SetScale(1.5, 1, 1)
    inst.AnimState:SetFinalOffset(-1)

    if tint ~= nil then
        inst.AnimState:SetMultColour(tint.x, tint.y, tint.z, tintalpha or 1)
    elseif tintalpha ~= nil then
        inst.AnimState:SetMultColour(tintalpha, tintalpha, tintalpha, tintalpha)
    end

    inst:ListenForEvent("animover", inst.Remove)

    --If proxy removed, check if completed or cancelled on server
    inst:ListenForEvent("onremove", function()
        if proxy._state:value() ~= 2 then
            inst:Remove()
        end
    end, proxy)

    if TheWorld.ismastersim then
        --Complete on server: removing the proxy shouldn't cancel client fx
        proxy:ListenForEvent("onremove", function()
            proxy._state:set(2)
            proxy:DoTaskInTime(MAX_LAG, proxy.Remove)
        end, inst)
    end    
end

local function OnStateDirty(inst)
    if inst._complete or inst._state:value() ~= 1 then
        return
    end

    --Delay one frame in case we are about to be removed
    inst:DoTaskInTime(0, PlayBookFX, inst.tint, inst.tintalpha, inst.anim)
    inst._complete = true
end

local function Disable(inst)
    if inst._state:value() ~= 2 then
        inst._state:set_local(0)
    end
end

local function common_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst:AddTag("FX")

    inst._state = net_tinybyte(inst.GUID, "_state", "statedirty")
    inst._complete = false

    inst.anim = "book_fx"

    inst:ListenForEvent("statedirty", OnStateDirty)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    --Disable instead of remove, because spawned fx also listens to the
    --proxy state in order to remove itself (since fx can be cancelled)
    inst:DoTaskInTime(MAX_LAG, Disable)

    inst._state:set(1)

    return inst
end

local function book_fn()
    local inst = common_fn()

    inst.tintalpha = 0.4

    return inst
end

local function mount_book_fn()
    local inst = common_fn()

    inst.tintalpha = 0.4
    inst.anim = "book_fx_mount"

    return inst
end

local function waxwell_book_fn()
    local inst = common_fn()

    inst.tint = Vector3(0, 0, 0)

    return inst
end

return Prefab("book_fx", book_fn, assets),
    Prefab("book_fx_mount", mount_book_fn, assets),
    Prefab("waxwell_book_fx", waxwell_book_fn, assets)
