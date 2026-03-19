local assets =
{
	Asset("ANIM", "anim/w_radio.zip"),
	Asset("DYNAMIC_ATLAS", "images/w_radio_parts.xml"),
	Asset("ASSET_PKGREF", "images/w_radio_parts.tex"),
}

local prefabs =
{
	"collapse_small",
}

local function _dbg_print(...)
	print("[w_radio.lua]:", ...)
end

local function _DecodePart(hex, partnum)
	return bit.band(0x7, bit.rshift(hex, (partnum - 1) * 3)) + 1
end

local function _EncodePart(variation, partnum)
	variation = math.clamp(tonumber(variation) or 1, 1, 8)
	return bit.lshift(variation - 1, (partnum - 1) * 3)
end

local function _AddIconLayer(tbl, idx, partname, variation)
	tbl[idx] = tbl[idx] or { atlas = "images/w_radio_parts.xml" }
	tbl[idx].image = string.format("%s%04d.tex", partname, variation)
end

local function LayeredInvImageFn(inst)
	if inst._icondirty then
		if inst._iconlayers == nil then
			inst._iconlayers = {}
			_AddIconLayer(inst._iconlayers, 2, "base", 1)
		end
		local hex = inst.parts:value()
		_AddIconLayer(inst._iconlayers, 1, "antenna",		_DecodePart(hex, 5))
		_AddIconLayer(inst._iconlayers, 3, "right_side",	_DecodePart(hex, 4))
		_AddIconLayer(inst._iconlayers, 4, "left_side",		_DecodePart(hex, 3))
		_AddIconLayer(inst._iconlayers, 5, "face",			_DecodePart(hex, 2))
		_AddIconLayer(inst._iconlayers, 6, "plate",			_DecodePart(hex, 1))
		inst._icondirty = nil
	end
	return inst._iconlayers
end

local function OnPartsDirty(inst)
	inst._icondirty = true
	inst:PushEvent("imagechange")
end

local function DoApplyFurnitureShadow(inst, enable)
	if enable then
		local skin_build = inst:GetSkinBuild()
		if skin_build then
			inst.AnimState:OverrideItemSkinSymbol("shadow01", skin_build, "shadow02", inst.GUID, "w_radio")
		end
	else
		inst.AnimState:ClearOverrideSymbol("shadow01")
	end
end

local function OnPutOnFurniture(inst)--, furniture)
	inst.components.workable:SetWorkable(false)
	DoApplyFurnitureShadow(inst, true)
end

local function OnTakeOffFurniture(inst)--, furniture)
	inst.components.workable:SetWorkable(true)
	DoApplyFurnitureShadow(inst, false)
end

local function OnHammered(inst)
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("metal")
	inst.components.lootdropper:DropLoot()
	inst:Remove()
end

local function _SymbolName(partname, variation)
	return string.format("%s%02d", partname, variation)
end

local function SetPart(inst, skin_build, partname, variation)
	local basesym = _SymbolName(partname, 1)
	if variation > 1 then
		inst.AnimState:OverrideItemSkinSymbol(basesym, skin_build, _SymbolName(partname, variation), inst.GUID, "w_radio")
		inst[partname] = variation
	else
		inst.AnimState:ClearOverrideSymbol(basesym)
		inst[partname] = nil
	end
end

local function DoApplyPartsFromCode(inst, hex)
	local skin_build = inst:GetSkinBuild()
	if skin_build then
		SetPart(inst, skin_build, "plate",		_DecodePart(hex, 1))
		SetPart(inst, skin_build, "face",		_DecodePart(hex, 2))
		SetPart(inst, skin_build, "left_side",	_DecodePart(hex, 3))
		SetPart(inst, skin_build, "right_side",	_DecodePart(hex, 4))
		SetPart(inst, skin_build, "antenna",	_DecodePart(hex, 5))
	end

	if not TheNet:IsDedicated() then
		OnPartsDirty(inst)
	end
end

local function SetPartsFromCode(inst, hex)
	if type(hex) == "string" then
		hex = tonumber(hex, 16)
	end
	if inst.parts:value() ~= hex then
		inst.parts:set(hex)
		DoApplyPartsFromCode(inst, hex)
	end
end

local function ArePartsDifferentFromCode(inst, hex)
    if type(hex) == "string" then
        hex = tonumber(hex, 16)
    end
    return inst.parts:value() ~= hex
end

local function _parse_skin_custom_data(data)
	local hex = _EncodePart(data.PLATE, 1)
	hex = bit.bor(hex, _EncodePart(data.FACE, 2))
	hex = bit.bor(hex, _EncodePart(data.LEFT, 3))
	hex = bit.bor(hex, _EncodePart(data.RIGHT, 4))
	return bit.bor(hex, _EncodePart(data.ANTENNA, 5))
end

local function OnWRadioSkinChanged(inst, skin_build, skin_custom)
	inst.OnEntityWake = nil
	inst.OnEntitySleep = nil
	if skin_build then
		local data = skin_custom and json.decode(skin_custom) or nil
		if data then
			--V2C: crafted
			SetPartsFromCode(inst, _parse_skin_custom_data(data))
			_dbg_print("skin parts changed.")
		elseif inst.parts:value() ~= 0 then
			--V2C: this should not really happen
			DoApplyPartsFromCode(inst, inst.parts:value())
			_dbg_print("skin changed => refreshing parts.")
		else
			--V2C: probably loading, since skin_custom is nil then
			_dbg_print("skin changed.")
		end
		if inst.components.furnituredecor:IsOnFurniture() then
			DoApplyFurnitureShadow(inst, true)
		end
	else
		inst.persists = false
		inst:DoStaticTaskInTime(0, inst.Remove)
		_dbg_print("removing due to skin cleared.")
	end
end

local function ReskinToolCustomDataDiffers(inst, skin_custom)
    local data = skin_custom and json.decode(skin_custom) or nil
    if not data then
        return false
    end

    return ArePartsDifferentFromCode(inst, _parse_skin_custom_data(data))
end

local function ReskinToolUpdateCustomData(inst, skin_custom)
    local data = skin_custom and json.decode(skin_custom) or nil
    if not data then
        return
    end

    SetPartsFromCode(inst, _parse_skin_custom_data(data))
    _dbg_print("skin parts changed via reskin tool.")
end

local function OnSpawnCheckSkin(inst)
	inst.OnEntityWake = nil
	inst.OnEntitySleep = nil
	if inst:GetSkinBuild() == nil then
		inst.persists = false
		inst:DoStaticTaskInTime(0, inst.Remove)
		_dbg_print("removing due to missing skin.")
	end
end

local function OnSave(inst, data)
	if inst.parts:value() ~= 0 then
		data.parts = string.format("%x", inst.parts:value())
	end
end

local function OnLoad(inst, data, ents)
	OnSpawnCheckSkin(inst)
	if inst.persists and data and data.parts then
		SetPartsFromCode(inst, data.parts)
	end
end

local function TurnOn(inst)
	if not inst.SoundEmitter:PlayingSound("loop") then
		inst.SoundEmitter:PlaySound("dontstarve/music/w_radio", "loop")
	end
end

local function TurnOff(inst)
	if inst.SoundEmitter:PlayingSound("loop") then
		inst.SoundEmitter:KillSound("loop")
		inst.SoundEmitter:PlaySound("dontstarve/music/gramaphone_end")
	end
end

local function ToPocket(inst, owner)
	if inst.components.machine:IsOn() then
		inst.SoundEmitter:KillSound("loop")
		if owner and owner.SoundEmitter then
			owner.SoundEmitter:PlaySound("dontstarve/music/gramaphone_end")
		end
		inst.components.machine:TurnOff()
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("w_radio")
	--inst.AnimState:SetBuild("w_radio")
	inst.AnimState:PlayAnimation("idle")

	--furnituredecor (from furnituredecor component) added to pristine state for optimization
	inst:AddTag("furnituredecor")

	MakeInventoryFloatable(inst, "med", 0.45, { 1.25, 1.5, 1.25 })

	inst.parts = net_ushortint(inst.GUID, "w_radio", "partsdirty")

	--inst._iconlayers = nil
	inst._icondirty = true
	inst.layeredinvimagefn = LayeredInvImageFn

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("partsdirty", OnPartsDirty)

		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnPutInInventoryFn(ToPocket)

	inst:AddComponent("furnituredecor")
	inst.components.furnituredecor.onputonfurniture = OnPutOnFurniture
	inst.components.furnituredecor.ontakeofffurniture = OnTakeOffFurniture

	inst:AddComponent("machine")
	inst.components.machine.turnonfn = TurnOn
	inst.components.machine.turnofffn = TurnOff
	inst.components.machine.cooldowntime = 0

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(OnHammered)

	inst:AddComponent("lootdropper")

	MakeHauntable(inst)

	inst.OnWRadioSkinChanged = OnWRadioSkinChanged
    inst.ReskinToolCustomDataDiffers = ReskinToolCustomDataDiffers
    inst.ReskinToolUpdateCustomData = ReskinToolUpdateCustomData
	inst.OnEntityWake = OnSpawnCheckSkin
	inst.OnEntitySleep = OnSpawnCheckSkin
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	--inst.dbg_Randomize = function() SetPartsFromCode(inst, math.random(0, 0x7FFF)) end

	return inst
end

return Prefab("w_radio", fn, assets, prefabs)
