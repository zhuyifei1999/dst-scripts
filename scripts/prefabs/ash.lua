local assets =
{
    Asset("ANIM", "anim/ash.zip"),
}

-- NOTE:
-- You have to add a custom DESCRIBE for each item you
-- mark as nonpotatable
local function GetStatus(inst)
    return inst.components.named.name ~= nil
        and string.gsub("REMAINS_"..inst.components.named.name, " ", "_")
        or nil
end

local function VacuumUp(inst)
	inst.components.disappears:StopDisappear()
    inst.persists = false
    inst:RemoveComponent("inventoryitem")
    inst:RemoveComponent("inspectable")
	inst.AnimState:PlayAnimation("eaten")
	inst:ListenForEvent("animover", function() inst:Remove() end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ashes")
    inst.AnimState:SetBuild("ash")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("molebait")
    inst:AddTag("ashes")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    ---------------------

    inst:AddComponent("disappears")
    inst.components.disappears.sound = "dontstarve/common/dust_blowaway"
    inst.components.disappears.anim = "disappear"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(function() inst.components.disappears:StopDisappear() end)

	inst:AddComponent("named")
	inst.components.named.nameformat = STRINGS.NAMES.ASH_REMAINS

    inst:AddComponent("bait")

	inst:ListenForEvent("stacksizechange", function(inst, stackdata)
		if stackdata.stacksize and stackdata.stacksize > 1 then
			inst.components.named:SetName(nil)
		end
	end)

	inst:ListenForEvent("ondropped", function() inst.components.disappears:PrepareDisappear() end)
	inst.components.disappears:PrepareDisappear()

	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown_on_successful_haunt = false
	inst.components.hauntable.usefx = false
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
	inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
		inst.components.disappears:Disappear()
		return true
	end)

	inst.VacuumUp = VacuumUp

    return inst
end

return Prefab("common/inventory/ash", fn, assets)