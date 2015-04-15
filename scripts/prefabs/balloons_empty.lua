local assets =
{
	Asset("ANIM", "anim/balloons_empty.zip"),
	--Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
	"balloon",
}    

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("balloons_empty")
    inst.AnimState:SetBuild("balloons_empty")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("balloons_empty.png")

    inst:AddComponent("inventoryitem")
    -----------------------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("balloonmaker")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if inst.components.balloonmaker then
            local x,y,z = inst.Transform:GetWorldPosition()
            inst.components.balloonmaker:MakeBalloon(x,y,z)
            return true
        end
        return false
    end)

    inst:AddComponent("characterspecific")
    inst.components.characterspecific:SetOwner("wes")

    return inst
end

return Prefab("common/balloons_empty", fn, assets, prefabs)