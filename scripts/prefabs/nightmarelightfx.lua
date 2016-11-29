local function Make(name, bank)
    local assets =
    {
        Asset("ANIM", "anim/"..bank..".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork() -- gjans: this is networked coz we trigger animations on it

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(bank)
        inst.AnimState:PlayAnimation("idle_closed")

        inst:AddTag("NOCLICK")
        inst:AddTag("FX")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        return inst
    end

    return Prefab(name, fn, assets)
end

return Make("nightmarelightfx", "rock_light_fx"),
    Make("nightmarefissurefx", "nightmare_crack_ruins_fx"),
    Make("upper_nightmarefissurefx", "nightmare_crack_upper_fx")
