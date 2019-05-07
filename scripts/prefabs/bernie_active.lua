local brain = require("brains/berniebrain")

local assets =
{
    Asset("ANIM", "anim/bernie.zip"),
    Asset("ANIM", "anim/bernie_build.zip"),
    Asset("SOUND", "sound/together.fsb"),
}

local prefabs =
{
    "bernie_inactive",
    "bernie_big",
}

local function goinactive(inst)
    local skin_name = nil
    if inst:GetSkinName() ~= nil then
        skin_name = string.gsub(inst:GetSkinName(), "_active", "")
    end

    local inactive = SpawnPrefab("bernie_inactive", skin_name, inst.skin_id, nil )
    if inactive ~= nil then
        --Transform health % into fuel.
        inactive.components.fueled:SetPercent(inst.components.health:GetPercent())
        inactive.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inactive.Transform:SetRotation(inst.Transform:GetRotation())
        local bigcd = inst.components.timer:GetTimeLeft("transform_cd")
        if bigcd ~= nil then
            inactive.components.timer:StartTimer("transform_cd", bigcd)
        end
        inst:Remove()
        return inactive
    end
end

local function gobig(inst)
    local skin_name = nil
    if inst:GetSkinName() ~= nil then
        skin_name = string.gsub(inst:GetSkinName(), "_active", "_big")
    end
    
    local big = SpawnPrefab("bernie_big", skin_name, inst.skin_id, nil )
    if big ~= nil then
        --Rescale health %
        big.components.health:SetPercent(inst.components.health:GetPercent())
        big.Transform:SetPosition(inst.Transform:GetWorldPosition())
        big.Transform:SetRotation(inst.Transform:GetRotation())
        inst:Remove()
        return big
    end
end

local function onpickup(inst, owner)
    local inactive = goinactive(inst)
    if inactive ~= nil then
        owner.components.inventory:GiveItem(inactive, nil, owner:GetPosition())
    end
    return true
end

local function TrackBernieBig(inst, berniebig)
    if not inst._berniebigs[berniebig] then
        inst._berniebigs[berniebig] = true
        inst:ListenForEvent("onremove", inst._onremoveberniebig, berniebig)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, .25)
    inst.DynamicShadow:SetSize(1, .5)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("bernie")
    inst.AnimState:SetBuild("bernie_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("smallcreature")
    inst:AddTag("companion")
    inst:AddTag("soulless")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BERNIE_HEALTH)
    inst.components.health.nofadeout = true

    inst:AddComponent("inspectable")
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.BERNIE_SPEED
    inst:AddComponent("combat")
    inst:AddComponent("timer")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPickupFn(onpickup)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:SetStateGraph("SGbernie")
    inst:SetBrain(brain)

    inst.GoInactive = goinactive
    inst.GoBig = gobig

    inst._berniebigs = {}
    inst.TrackBernieBig = TrackBernieBig
    inst._onremoveberniebig = function(berniebig) inst._berniebigs[berniebig] = nil end
    inst:ListenForEvent("ms_registerberniebig", function(src, berniebig) inst:TrackBernieBig(berniebig) end, TheWorld)
    TheWorld:PushEvent("ms_registerbernieactive", inst)

    return inst
end

return Prefab("bernie_active", fn, assets, prefabs)
