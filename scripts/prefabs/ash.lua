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

local function BlowAway(inst)
	if inst.blowawaytask then
		inst.blowawaytask:Cancel()
    	inst.blowawaytask = nil
    end
    inst.persists = false
    inst:RemoveComponent("inventoryitem")
    inst:RemoveComponent("inspectable")
	inst.SoundEmitter:PlaySound("dontstarve/common/dust_blowaway")
	inst.AnimState:PlayAnimation("disappear")
	inst:ListenForEvent("animover", inst.Remove)
end

local function StopBlowAway(inst)
	if inst.blowawaytask then
		inst.blowawaytask:Cancel()
		inst.blowawaytask = nil
	end
end
		
local function PrepareBlowAway(inst)
	StopBlowAway(inst)
	inst.blowawaytask = inst:DoTaskInTime(25+math.random()*10, BlowAway)
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

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    ---------------------

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(StopBlowAway)

	inst:AddComponent("named")
	inst.components.named.nameformat = STRINGS.NAMES.ASH_REMAINS

	inst:ListenForEvent("stacksizechange", function(inst, stackdata)
		if stackdata.stacksize and stackdata.stacksize > 1 then
			inst.components.named:SetName(nil)
		end
	end)

	inst:ListenForEvent("ondropped", PrepareBlowAway)
	PrepareBlowAway(inst)

	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown_on_successful_haunt = false
	inst.components.hauntable.usefx = false
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
	inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
		BlowAway(inst)
		return true
	end)

    return inst
end

return Prefab("common/inventory/ash", fn, assets)