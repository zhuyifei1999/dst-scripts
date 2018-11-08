local assets =
{
    --Asset("ANIM", "anim/lavaarena_rhinodrill_basic.zip"),
    --Asset("ANIM", "anim/lavaarena_rhinodrill_damaged.zip"),
    Asset("ANIM", "anim/wilson_fx.zip"),
    Asset("ANIM", "anim/fossilized.zip"),
}

local assets_alt =
{
    --Asset("ANIM", "anim/lavaarena_rhinodrill_basic.zip"),
    --Asset("ANIM", "anim/lavaarena_rhinodrill_clothed_b_build.zip"),
    --Asset("ANIM", "anim/lavaarena_rhinodrill_damaged.zip"),
    Asset("ANIM", "anim/wilson_fx.zip"),
    Asset("ANIM", "anim/fossilized.zip"),
}

local prefabs =
{
    "fossilizing_fx",
    "rhinodrill_fossilized_break_fx_right",
    "rhinodrill_fossilized_break_fx_left",
    "rhinodrill_fossilized_break_fx",
    "rhinobuff",
    "rhinobumpfx",
    "lavaarena_creature_teleport_small_fx",
}

local function MakeRhinoDrill(name, alt)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        inst.DynamicShadow:SetSize(2.75, 1.25)
        inst.Transform:SetSixFaced()
        inst.Transform:SetScale(1.15, 1.15, 1.15)

        inst:SetPhysicsRadiusOverride(1)
        MakeCharacterPhysics(inst, 400, inst.physicsradiusoverride)

        inst.AnimState:SetBank("rhinodrill")
        inst.AnimState:SetBuild("lavaarena_rhinodrill_basic")
        inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
        if alt then
            inst.AnimState:AddOverrideBuild("lavaarena_rhinodrill_clothed_b_build")
        end
        --inst.AnimState:PlayAnimation("idle_loop", true)

        inst.AnimState:AddOverrideBuild("fossilized")

        inst:AddTag("LA_mob")
        inst:AddTag("monster")
        inst:AddTag("hostile")
        inst:AddTag("largecreature")

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

        event_server_data("lavaarena", "prefabs/lavaarena_rhinodrill").master_postinit(inst, alt)

        return inst
    end

    return Prefab(name, fn, alt and assets_alt or assets, prefabs)
end

local function MakeFossilizedBreakFX(side)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        inst.Transform:SetSixFaced()

        --Leave this out of pristine state to force animstate to be dirty later
        --inst.AnimState:SetBank("rhinodrill")
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

    return Prefab(side:len() > 0 and ("rhinodrill_fossilized_break_fx_"..side) or "rhinodrill_fossilized_break_fx", fn, assets)
end

return MakeRhinoDrill("rhinodrill"),
    MakeRhinoDrill("rhinodrill2", true),
    MakeFossilizedBreakFX("right"),
    MakeFossilizedBreakFX("left"),
    MakeFossilizedBreakFX("")
