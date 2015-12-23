local assets =
{
    --Asset("ANIM", "anim/fire_large_character.zip"),
    Asset("ANIM", "anim/campfire_fire.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local firelevels =
{
    {anim="level1", sound="dontstarve/common/maxlight", radius=1, intensity=.75, falloff= 1, colour = {207/255,234/255,245/255}, soundintensity=.1},
    {anim="level2", sound="dontstarve/common/maxlight", radius=1.5, intensity=.8, falloff=.9, colour = {207/255,234/255,245/255}, soundintensity=.3},
    {anim="level3", sound="dontstarve/common/maxlight", radius=2, intensity=.8, falloff=.8, colour = {207/255,234/255,245/255}, soundintensity=.6},
    {anim="level4", sound="dontstarve/common/maxlight", radius=2.5, intensity=.9, falloff=.7, colour = {207/255,234/255,245/255}, soundintensity=1},
    {anim="level1", sound="dontstarve/common/maxlight", radius=2, intensity=.75, falloff=.4, colour = {207/255,234/255,245/255}, soundintensity=.1},
    {anim="level2", sound="dontstarve/common/maxlight", radius=3, intensity=.8, falloff=.4, colour = {207/255,234/255,245/255}, soundintensity=.3},
    {anim="level3", sound="dontstarve/common/maxlight", radius=4, intensity=.8, falloff=.4, colour = {207/255,234/255,245/255}, soundintensity=.6},
    {anim="level4", sound="dontstarve/common/maxlight", radius=6, intensity=.9, falloff=.4, colour = {207/255,234/255,245/255}, soundintensity=1},
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.AnimState:SetBank("campfire_fire")
    inst.AnimState:SetBuild("campfire_fire")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetFinalOffset(-1)
    --inst.AnimState:SetMultColour(27 / 255, 234 / 255, 245 / 255, .6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("firefx")
    inst.components.firefx.levels = firelevels
    inst.components.firefx.lightsound = "dontstarve/common/maxlightAddFuel"
    inst.components.firefx.extinguishsound =  "dontstarve/common/maxlightOut" 

    return inst
end

return Prefab("maxwelllight_flame", fn, assets)