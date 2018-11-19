local assets =
{
    --Asset("ANIM", "anim/lavaarena_beetletaur.zip"),
    --Asset("ANIM", "anim/lavaarena_beetletaur_basic.zip"),
    --Asset("ANIM", "anim/lavaarena_beetletaur_actions.zip"),
    --Asset("ANIM", "anim/lavaarena_beetletaur_block.zip"),
    Asset("ANIM", "anim/fossilized.zip"),
}

local prefabs =
{
    "fossilizing_fx",
    "beetletaur_fossilized_break_fx_right",
    "beetletaur_fossilized_break_fx_left",
    "beetletaur_fossilized_break_fx_left_alt",
    "beetletaur_fossilized_break_fx_alt",
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
    inst.Transform:SetScale(1.05, 1.05, 1.05)

    inst:SetPhysicsRadiusOverride(1.5)
    MakeCharacterPhysics(inst, 500, inst.physicsradiusoverride)

    inst.AnimState:SetBank("beetletaur")
    inst.AnimState:SetBuild("lavaarena_beetletaur")
    inst.AnimState:PlayAnimation("idle_loop", true)

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

local function MakeFossilizedBreakFX(anim, side, interrupted)
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
        inst.AnimState:PlayAnimation(anim)

        if not interrupted then
            inst.AnimState:OverrideSymbol("rock", "lavaarena_beetletaur", "rock")
            inst.AnimState:OverrideSymbol("rock2", "lavaarena_beetletaur", "rock2")
        end

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

    return Prefab("beetletaur_"..anim..(side:len() > 0 and ("_"..side) or "")..(interrupted and "_alt" or ""), fn, assets)
end

return Prefab("beetletaur", fn, assets, prefabs),
    MakeFossilizedBreakFX("fossilized_break_fx", "right", false),
    MakeFossilizedBreakFX("fossilized_break_fx", "left", false),
    MakeFossilizedBreakFX("fossilized_break_fx", "left", true),
    MakeFossilizedBreakFX("fossilized_break_fx", "", true)
