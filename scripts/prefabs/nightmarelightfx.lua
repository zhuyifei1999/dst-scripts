local assets =
{
	Asset("ANIM", "anim/rock_light_fx.zip"),
    Asset("ANIM", "anim/nightmare_crack_ruins_fx.zip"),
    Asset("ANIM", "anim/nightmare_crack_upper_fx.zip"),    
}

local function Make(bank)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork() -- gjans: this is networked coz we trigger animations on it

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(bank)
        inst.AnimState:PlayAnimation("idle_closed", false)

        inst:AddTag("NOCLICK")
        inst:AddTag("FX")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        return inst
    end
end

return Prefab("common/nightmarelightfx", Make("rock_light_fx"), assets),
    Prefab("common/nightmarefissurefx", Make("nightmare_crack_ruins_fx"), assets),
    Prefab("common/upper_nightmarefissurefx", Make("nightmare_crack_upper_fx"), assets)
