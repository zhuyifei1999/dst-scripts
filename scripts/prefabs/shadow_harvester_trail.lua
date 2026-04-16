local assets = {
    Asset("ANIM", "anim/wx78_nightmare_fuel.zip"),
    Asset("ANIM", "anim/shadow_breath.zip"),
}

local function CreateOneshotFx()
    local oneshotfx = CreateEntity()
    oneshotfx.entity:AddTransform()
    oneshotfx.entity:AddAnimState()
    oneshotfx:AddTag("CLASSIFIED")
    --[[Non-networked entity]]
    oneshotfx.entity:SetCanSleep(false)

    oneshotfx.AnimState:SetBank("shadow_breath")
    oneshotfx.AnimState:SetBuild("shadow_breath")
    oneshotfx.AnimState:SetMultColour(1, 1, 1, 0.5)
    oneshotfx.AnimState:PlayAnimation("idle"..tostring(math.random(3)))

    oneshotfx.persists = false

    return oneshotfx
end

local function InitializeFx(inst, fx)
    table.insert(inst.trailfx, fx)
    fx.AnimState:PlayAnimation("blob_decal_pre", false)
    fx.AnimState:PushAnimation("blob_decal_loop", false)
    fx.AnimState:PushAnimation("blob_decal_pst", false)

    fx.oneshotfx.AnimState:PlayAnimation("idle"..tostring(math.random(3)))
    if math.random() < .5 then
        fx.oneshotfx.AnimState:SetScale(-1, 1)
    else
        fx.oneshotfx.AnimState:SetScale(1, 1)
    end
end

local function CreateTrailFx(inst)
    local fx = table.remove(inst.trailfx_pool, #inst.trailfx_pool)
    if not fx then
        fx = CreateEntity()
        fx.entity:AddTransform()
        fx.entity:AddAnimState()
        fx:AddTag("CLASSIFIED")
        --[[Non-networked entity]]
        fx.entity:SetCanSleep(false)

        fx.AnimState:SetBank("wx78_nightmare_fuel")
        fx.AnimState:SetBuild("wx78_nightmare_fuel")
        fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        fx.AnimState:SetLayer(LAYER_BACKGROUND)
        fx.AnimState:SetSortOrder(1)
        fx.AnimState:SetMultColour(1, 1, 1, 0.3)

        fx.persists = false
        fx:ListenForEvent("animqueueover", function(fx)
            table.removearrayvalue(inst.trailfx, fx)
            if fx.finalize then
                fx:Remove()
            else
                table.insert(inst.trailfx_pool, fx)
            end
        end)
        fx:ListenForEvent("onremove", function(fx)
            table.removearrayvalue(inst.trailfx, fx)
        end)

        fx.oneshotfx = CreateOneshotFx()
        fx.oneshotfx.entity:SetParent(fx.entity)
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    -- Intentional center biased random circle distribution.
    local theta = math.random() * PI2
    local radius = math.random() * 0.1 + 0.1
    local dx, dz = math.cos(theta) * radius, math.sin(theta) * radius
    fx.Transform:SetPosition(x + dx, y, z + dz)

    InitializeFx(inst, fx)
    inst:DoTaskInTime((3 + math.random(0, 2)) * FRAMES, CreateTrailFx)
end

local function ExpireTrailFx(inst)
    for _, fx in ipairs(inst.trailfx) do
        fx.finalize = true
    end
    for i = #inst.trailfx_pool, 1, -1 do
        local fx = inst.trailfx_pool[i]
        fx:Remove()
        inst.trailfx_pool[i] = nil
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("wx78_nightmare_fuel")
    inst.AnimState:SetBuild("wx78_nightmare_fuel")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetMultColour(1, 1, 1, 0.3)
    inst.AnimState:PlayAnimation("blob_decal_pre", false)
    inst.AnimState:PushAnimation("blob_head_loop", true)

    inst.entity:SetPristine()
    if not TheNet:IsDedicated() then
        inst.trailfx = {}
        inst.trailfx_pool = {}
        inst:DoTaskInTime((3 + math.random(0, 2)) * FRAMES, CreateTrailFx)
        inst:ListenForEvent("onremove", ExpireTrailFx)
    end
    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("shadow_harvester_trail", fn, assets)
