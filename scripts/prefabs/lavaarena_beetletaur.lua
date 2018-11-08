local assets =
{
    --Asset("ANIM", "anim/lavaarena_beetletaur_basic.zip"),
    Asset("ANIM", "anim/fossilized.zip"),
}

local prefabs =
{
    "fossilizing_fx",
    "beetletaur_fossilized_break_fx_right",
    "beetletaur_fossilized_break_fx_left",
    "beetletaur_fossilized_break_fx",
    "lavaarena_creature_teleport_medium_fx",
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(4.5, 2.25)
    inst.Transform:SetFourFaced()

    inst:SetPhysicsRadiusOverride(1.5)
    MakeCharacterPhysics(inst, 500, inst.physicsradiusoverride)

    inst.AnimState:SetBank("beetletaur")
    inst.AnimState:SetBuild("lavaarena_beetletaur_basic")
    --inst.AnimState:PlayAnimation("idle_loop", true)

    inst.AnimState:AddOverrideBuild("fossilized")

    inst:AddTag("LA_mob")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("largecreature")
    inst:AddTag("epic")

    --fossilizable (from fossilizable component) added to pristine state for optimization
    inst:AddTag("fossilizable")

    ------------------------------------------

    if TheWorld.components.lavaarenamobtracker ~= nil then
        TheWorld.components.lavaarenamobtracker:StartTracking(inst)
    end

    ------------------------------------------

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    event_server_data("lavaarena", "prefabs/lavaarena_beetletaur").master_postinit(inst)

    return inst
end

local function MakeFossilizedBreakFX(side)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        inst.Transform:SetFourFaced()

        --Leave this out of pristine state to force animstate to be dirty later
        --inst.AnimState:SetBank("beetletaur")
        inst.AnimState:SetBuild("fossilized")
        --inst.AnimState:PlayAnimation("fossilized_break_fx")

        if side:len() > 0 then
            inst.AnimState:Hide(side == "right" and "fx_lavarock_L" or "fx_lavarock_R")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false
        inst:ListenForEvent("animover", ErodeAway)

        return inst
    end

    return Prefab(side:len() > 0 and ("beetletaur_fossilized_break_fx_"..side) or "beetletaur_fossilized_break_fx", fn, assets)
end

return Prefab("beetletaur", fn, assets, prefabs),
    MakeFossilizedBreakFX("right"),
    MakeFossilizedBreakFX("left"),
    MakeFossilizedBreakFX("")
