local assets =
{
    Asset("ANIM", "anim/wx78_inventorycontainer.zip"),
    Asset("INV_IMAGE", "wx78_inventorycontainer_open"),
    Asset("ANIM", "anim/ui_wx78_inventorycontainer_1x1.zip"),
}

-----------------------------------------------------------------------------------------------

local function ShouldCollapse(inst)
    local overstacks = 0
	for k, v in pairs(inst.components.container.slots) do
		local stackable = v.components.stackable
		if stackable then
			overstacks = overstacks + math.ceil(stackable:StackSize() / (stackable.originalmaxsize or stackable.maxsize))
			if overstacks >= TUNING.COLLAPSED_CHEST_EXCESS_STACKS_THRESHOLD then
				return true
			end
		end
	end
    return false
end

local function OnPickup(inst)
    inst:RemoveTag("no_container_store")
end

local function OnDropped(inst)
    inst:AddTag("no_container_store")
	if ShouldCollapse(inst) then
		inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_MAX_EXCESS_STACKS_DROPS)
		if inst.components.container:IsEmpty() then
            inst:Remove()
        end
    else
        inst.components.container:DropEverything()
        inst:Remove()
    end
end

local function OnPicked(inst, picker, loot)
    inst.SoundEmitter:PlaySound("qol1/wagstaff_ruins/rummagepile_pst") -- pickable.picksound only works for something that gives pickable loot the usuable way

	local loots = inst.components.container:GetAllItems()
	if #loots > 0 then
		local item = loots[math.random(#loots)]
		if picker and picker.components.inventory then
			item = inst.components.container:RemoveItem(item, true, nil, true)
			picker.components.inventory:GiveItem(item, nil, inst:GetPosition())
		else
			local slot = inst.components.container:GetItemSlot(item)
			inst.components.container:DropItemBySlot(slot, inst:GetPosition(), true)
		end
	end

	if inst.components.container:IsEmpty() then
		local fx = SpawnPrefab("collapse_small")
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		fx:SetMaterial("metal")
		inst:Remove()
	else
		inst.AnimState:PlayAnimation("dropped_rummage")
		inst.AnimState:PushAnimation("dropped_idle", false)
	end
end

local function OnOpen(inst)
    local skin_name = inst:GetSkinName() or "wx78_inventorycontainer"
    inst.components.inventoryitem:ChangeImageName(skin_name .. "_open")
end

local function OnClose(inst)
    local skin_name = inst:GetSkinName()
    inst.components.inventoryitem:ChangeImageName(skin_name)
end

local function DisplayNameFn(inst)
    return (inst.replica.inventoryitem ~= nil and inst.replica.inventoryitem:IsHeld()
        and STRINGS.NAMES.WX78_INVENTORYCONTAINER_HELD)
        or STRINGS.NAMES.WX78_INVENTORYCONTAINER
end

local FLOATER_SWAP_DATA = { bank = "wx78_inventorycontainer", anim = "dropped_idle" }
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("wx78_inventorycontainer")
    inst.AnimState:SetBuild("wx78_inventorycontainer")
    inst.AnimState:PlayAnimation("dropped_idle")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.35, 1.15, nil, nil, FLOATER_SWAP_DATA)

    inst:AddTag("portablestorage")
    inst:AddTag("nosteal")
    inst:AddTag("pickable_rummage_str")
    inst:AddTag("no_container_store")

    inst.displaynamefn = DisplayNameFn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPickupFn(OnPickup)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem.canbepickedup = false
    -- inst.components.inventoryitem.cangoincontainer = false
    --inst.components.inventoryitem:SetLocked(true) -- TODO FIXME: for Vito to do.

    inst:AddComponent("container")
    inst.components.container:EnableInfiniteStackSize(true)
    inst.components.container:WidgetSetup("wx78_inventorycontainer")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

	inst:AddComponent("pickable")
	inst.components.pickable.onpickedfn = OnPicked
	inst.components.pickable:SetUp(nil, 0)

    -- inst:AddComponent("preserver")
    -- inst.components.preserver:SetPerishRateMultiplier(TUNING.BEARGERFUR_SACK_PRESERVER_RATE)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("wx78_inventorycontainer", fn, assets, prefabs)