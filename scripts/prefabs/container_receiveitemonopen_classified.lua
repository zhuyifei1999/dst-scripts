local function OnItemDirty(inst)
	local parent = inst.entity:GetParent()
	if parent and inst.item:value() then
		inst._data = 
		{
			item = inst.item:value(),
			isstack = inst.isstack:value(),
		}
		parent._receiveitemonopen = inst._data
	end
end

local function OnRemoveEntity(inst)
	local parent = inst.entity:GetParent()
	if parent and parent._receiveitemonopen == inst._data then
		parent._receiveitemonopen = nil
	end
end

local function fn()
	local inst = CreateEntity()

	if TheWorld.ismastersim then
		inst.entity:AddTransform() --So we can follow parent's sleep state
	end
	inst.entity:AddNetwork()
	inst.entity:Hide()
	inst:AddTag("CLASSIFIED")

	inst.item = net_entity(inst.GUID, "container_receiveitemonopen_classified.item", "itemdirty")
	inst.isstack = net_bool(inst.GUID, "container_receiveitemonopen_classified.isstack")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("itemdirty", OnItemDirty)
		inst.OnRemoveEntity = OnRemoveEntity

	    return inst
	end

	inst.persists = false
	inst:DoTaskInTime(0.2, inst.Remove)

	return inst
end

return Prefab("container_receiveitemonopen_classified", fn)
