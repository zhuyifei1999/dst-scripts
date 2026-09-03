local assets=
{
    Asset("ANIM", "anim/charlie_arena_light_ray.zip"),
}

local function MakeLightRay(name)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.Transform:SetEightFaced()

        inst.AnimState:SetBank("charlie_arena_light_ray")
        inst.AnimState:SetBuild("charlie_arena_light_ray")
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetLightOverride(1)

        inst:AddTag("lightrays")
        inst:AddTag("ignorewalkableplatforms")
        inst:AddTag("NOBLOCK")
        inst:AddTag("NOCLICK")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        return inst
    end

    return Prefab(name, fn, assets)
end

return MakeLightRay("charliearena_lightray")
