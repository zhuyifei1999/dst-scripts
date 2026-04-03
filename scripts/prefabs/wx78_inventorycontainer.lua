local assets =
{
    Asset("ANIM", "anim/wx78_inventorycontainer.zip"),
    Asset("INV_IMAGE", "wx78_inventorycontainer_open"),
	Asset("INV_IMAGE", "wx78_inventorycontainer_powered"),
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

local function OnPutInInventory(inst)
    inst:RemoveTag("no_container_store")
	inst.components.inventoryitem.islockedinslot = true
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

local function RefreshIcon(inst)
	local skin_name = inst:GetSkinName()
	inst.components.inventoryitem:ChangeImageName(
		(inst.components.container:IsOpen() and ((skin_name or "wx78_inventorycontainer").."_open")) or
		(inst.components.container.canbeopened and ((skin_name or "wx78_inventorycontainer").."_powered")) or
		skin_name
	)
end

local function OnOpen(inst)--, data)
	RefreshIcon(inst)
end

local function OnClose(inst)--, data)
	RefreshIcon(inst)
end

local function SetPowered(inst, powered)
	if inst.components.container.canbeopened ~= powered then
		inst.components.container.canbeopened = powered
		if not powered and inst.components.container:IsOpen() then
			inst.components.container:Close()
		else
			RefreshIcon(inst)
		end
	end
end

local function ValidateOnLoad(inst)
	local owner = inst.components.inventoryitem.owner
	if owner == nil then
		return --valid!
	end

	local inventory = owner.components.inventory or owner.components.container

	local maxcount = owner._stacksize_modules or 0
	local minslot = inventory:GetNumSlots() - (maxcount - 1)
	local slot = inventory:GetItemSlot(inst)
	if slot and slot >= minslot then
		return --valid!
	end

	--invalid
	inst.components.inventoryitem.islockedinslot = false
	--wx78_inventorycontainer is not stackable so we don't need to branch for container:DroptItemBySlot()
	inventory:DropItem(inst)
end

local function OnLoad(inst)--, data, ents)
	inst:DoTaskInTime(0, ValidateOnLoad)
end

local function GetStatus(inst)--, viewer)
	return inst.components.inventoryitem:IsHeld()
		and (inst.components.container.canbeopened and "HELD" or "NOPOWER")
		or nil
end

local function DisplayNameFn(inst)
	local inventoryitem = inst.replica.inventoryitem
	return inventoryitem and inventoryitem:IsHeld()
		and STRINGS.NAMES.WX78_INVENTORYCONTAINER_HELD
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

    inst:AddTag("nosteal")
    inst:AddTag("pickable_rummage_str")
    inst:AddTag("no_container_store")

    inst.displaynamefn = DisplayNameFn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem.canbepickedup = false
	--inst.components.inventoryitem.canonlygoinpocket = true --needs to go in container for wx78_backupbody

    inst:AddComponent("container")
    inst.components.container:EnableInfiniteStackSize(true)
    inst.components.container:WidgetSetup("wx78_inventorycontainer")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
	inst.components.container.canbeopened = false

	inst:AddComponent("pickable")
	inst.components.pickable.onpickedfn = OnPicked
	inst.components.pickable:SetUp(nil, 0)

    -- inst:AddComponent("preserver")
    -- inst.components.preserver:SetPerishRateMultiplier(TUNING.BEARGERFUR_SACK_PRESERVER_RATE)

    MakeHauntableLaunchAndDropFirstItem(inst)

	inst.SetPowered = SetPowered
	inst.OnLoad = OnLoad

    return inst
end

return Prefab("wx78_inventorycontainer", fn, assets, prefabs)