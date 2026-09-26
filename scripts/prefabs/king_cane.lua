local assets =
{
    Asset("ANIM", "anim/king_cane.zip"),
    Asset("SCRIPT", "scripts/prefabs/staff_common.lua"),
    Asset("INV_IMAGE", "king_cane_redgem"),
    Asset("INV_IMAGE", "king_cane_bluegem"),
    Asset("INV_IMAGE", "king_cane_purplegem"),
    Asset("INV_IMAGE", "king_cane_yellowgem"),
    Asset("INV_IMAGE", "king_cane_orangegem"),
    Asset("INV_IMAGE", "king_cane_greengem"),
}

local prefabs =
{
    "king_cane_fx",
}

local staff_common = require("prefabs/staff_common")
local stafffns = staff_common.fns

local function UpdateFxLevel(inst, current)
    local level =
        current >= 100 and 3 or
        current >= 66 and 2 or
        current >= 33 and 1 or
        0
    inst:SetFXLevel(level)
    inst._fx:SetFXLevel(level)
end

local function OnEquip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_king_cane", inst.GUID, "king_cane")
    else
        owner.AnimState:OverrideSymbol("swap_object", "king_cane", "swap_king_cane")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

	if inst._fx ~= nil then
		inst._fx:Remove()
	end
    inst._fx = SpawnPrefab("king_cane_fx")
	inst._fx:AttachToOwner(owner)
    UpdateFxLevel(inst, inst.components.corruption:GetCurrent())
    if inst.gem then
        inst._fx.AnimState:OverrideSymbol("swap_gem", "king_cane", "swap_"..inst.gem)
    end

    if owner.components.playerspeedmult then
        owner.components.playerspeedmult:SetCappedPredictedSpeedMult(inst, TUNING.KING_CANE_SPEED_MULT)
    elseif owner.components.locomotor then
        owner.components.locomotor:SetExternalSpeedMultiplier(inst, "king_cane", TUNING.KING_CANE_SPEED_MULT)
    end
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    if inst._fx ~= nil then
        inst._fx:Remove()
        inst._fx = nil
    end

    if owner.components.playerspeedmult then
        owner.components.playerspeedmult:RemoveCappedPredictedSpeedMult(inst)
    elseif owner.components.locomotor then
        owner.components.locomotor:RemoveExternalSpeedMultiplier(inst, "king_cane")
    end
end

local function GetGemId(gemtype)
    return string.sub(gemtype, 0, -4)
end

local function ItemTradeTest(inst, item)
    if item == nil then
        return false
    -- elseif inst.components.rechargeable and not inst.components.rechargeable:IsCharged() then
    --     return false, "KINGSTAFF_COOLDOWN"
    elseif string.sub(item.prefab, -11, -4) == "precious" then
        return false, "WRONGGEM"
    elseif not stafffns[GetGemId(item.prefab)] or not item:HasTag("gem") then
        return false, "NOTGEM"
    end
    return true
end

local function OnDischarged(inst)
    inst:AddTag("nomagiccast")
    inst._removetag = (inst:HasTag("rangedlighter") and "rangedlighter") or (inst:HasTag("extinguisher") and "extinguisher")
    if inst._removetag then
        inst:RemoveTag(inst._removetag)
    end
end

local function OnCharged(inst)
    inst:RemoveTag("nomagiccast")
    if inst._removetag then
        inst:AddTag(inst._removetag)
        inst._removetag = nil
    end
end

local function OnGemDirty(inst)
    staff_common.cleargemstaff_client(inst)
    local clientfn = stafffns[GetGemId(inst._gem:value()).."_client"]
    if clientfn then
        clientfn(inst)
    end

    local inventoryitem = inst.replica.inventoryitem
	local playercontroller = ThePlayer and ThePlayer.components.playercontroller
	if playercontroller and inventoryitem and inventoryitem:IsGrandOwner(ThePlayer) then
        playercontroller:RefreshReticule(inst)
    end
end

local function SetGem(inst, gemtype)
    inst.gem = gemtype
    inst._gem:set(gemtype)
    stafffns[GetGemId(gemtype)](inst, true)

    inst.components.inventoryitem:ChangeImageName("king_cane_"..inst.gem)

    local swapsym = "swap_"..inst.gem
    inst.AnimState:OverrideSymbol("swap_gem", "king_cane", swapsym)
    if inst._fx then
        inst._fx.AnimState:OverrideSymbol("swap_gem", "king_cane", swapsym)
    end
    if not TheNet:IsDedicated() then
        OnGemDirty(inst)
    end
end

local function OnGemGiven(inst, giver, item)
    if inst.gem then
        staff_common.cleargemstaff(inst)

        local x, y, z = (giver or inst).Transform:GetWorldPosition()
        local oldgem = SpawnPrefab(inst.gem)
        if giver and giver.components.inventory then
            giver.components.inventory:GiveItem(oldgem, nil, Vector3(x, y, z))
        else
            oldgem.components.inventoryitem:DoDropPhysics(x, y, z, true)
        end
    end
    SetGem(inst, item.prefab)
    inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
end

local function OnCorruptedFn(inst)
    inst:AddTag("shadow_item")
    inst.dodischarge = true
    inst:AddComponent("shadowdominance")
    inst.components.trader:Disable()
end

local function OnCorruptionCurrentFn(inst, current)
    if inst._fx then
        UpdateFxLevel(inst, current)
    end
end

local function DoCorruption(inst)
    inst.components.corruption:DoDelta(TUNING.KING_CANE_CORRUPTION[inst.gem])
end

local function GetDappernessFn(inst)
    local corruption = inst.components.corruption:GetCurrent()
    return (corruption >= 20 and TUNING.CRAZINESS_TINY)
        or (corruption >= 50 and TUNING.CRAZINESS_SMALL)
        or (corruption >= 80 and TUNING.CRAZINESS_MED)
        or 0
end

local function GetStatus(inst)--, viewer)
    return (inst.gem == nil and "EMPTY")
end

local function OnSave(inst, data)
    data.gem = inst.gem
end

local function OnPreLoad(inst, data) -- before rechargeable component is added
    if data then
        if data.gem then
            SetGem(inst, data.gem)
        end
    end
end

-----------------

local function CreateCorruptionFX()
	local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")

	inst.AnimState:SetBank("king_cane")
	inst.AnimState:SetBuild("king_cane")
	inst.AnimState:PlayAnimation("corrupt_level1", true)

	inst:AddComponent("highlightchild")

    inst:Hide()
	inst.persists = false

	return inst
end

local function OnColourChanged(inst, r, g, b, a)
    inst.fx.AnimState:SetAddColour(r, g, b, a)
end

local function OnFXLevelDirty(inst)
    local val = inst.level:value()
    if val == 0 then
        inst.fx:Hide()
    else
        inst.fx:Show()
        inst.fx.AnimState:PlayAnimation("corrupt_level"..tostring(inst.level:value()), true)
    end
end

local function SetFXLevel(inst, level)
    if level ~= inst.level:value() then
        inst.level:set(level)
        if not TheNet:IsDedicated() then
            OnFXLevelDirty(inst)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("king_cane")
    inst.AnimState:SetBuild("king_cane")
    inst.AnimState:PlayAnimation("idle")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
	--rechargeable (from rechargeable component) added to pristine state for optimization
	inst:AddTag("rechargeable")
	--shadowlevel (from shadowlevel component) added to pristine state for optimization
	inst:AddTag("shadowlevel")
    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")
	inst:AddTag("give_dolongaction")
    inst:AddTag("gemsocket")

    local swap_data = {sym_build = "swap_king_cane"}
    MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85}, true, 1, swap_data)

    inst.projectiledelay = FRAMES -- only ice staff and fire staff need this

    inst._gem = net_string(inst.GUID, "king_cane_fx.gem", "gemdirty")
    inst.level = net_tinybyte(inst.GUID, "king_cane_fx.level", "leveldirty")
    inst.level:set(0)

    inst:AddComponent("colouraddersync")

    -- Dedicated server does not need to spawn local fx
    if not TheNet:IsDedicated() then
		inst.fx = CreateCorruptionFX()
		inst.fx.entity:SetParent(inst.entity)
		inst.fx.Follower:FollowSymbol(inst.GUID, "follow", nil, nil, nil, true)
        inst.highlightchildren = { inst.fx }
		inst.components.colouraddersync:SetColourChangedFn(OnColourChanged)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("gemdirty", OnGemDirty)
        return inst
    end

    inst.notlightningteleport = true
    inst.dodischarge = false

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetDappernessFn(GetDappernessFn)
    inst.components.equippable.is_magic_dapperness = true
    -- NOTE: speed mult done in OnEquip/OnUnequip to follow speed mult cap rule
    -- inst.components.equippable.walkspeedmult = TUNING.KING_CANE_SPEED_MULT

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.KING_CANE_DAMAGE)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

	inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.KING_CANE_SHADOW_LEVEL)

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader:SetOnAccept(OnGemGiven)
    inst.components.trader.deleteitemonaccept = true
    ---
    inst:AddComponent("corruption")
    inst.components.corruption:SetOnCurrentFn(OnCorruptionCurrentFn)
    inst.components.corruption:SetOnCorruptedFn(OnCorruptedFn)

    inst:ListenForEvent("onspellcast", DoCorruption)
    inst:ListenForEvent("onblink", DoCorruption)
    inst:ListenForEvent("weapononprojectilelaunched", DoCorruption)
    ---

    MakeHauntableLaunch(inst)

    inst.SetFXLevel = SetFXLevel
    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad

    return inst
end

-------------------------

local function FxOnRemoveEntity(inst)
	inst.fx:Remove()
end

local function FxOnEntityReplicated(inst)
	local owner = inst.entity:GetParent()
	if owner ~= nil then
		inst.fx = CreateCorruptionFX()
		inst.fx.entity:SetParent(inst.entity)
		inst.fx.Follower:FollowSymbol(inst.GUID, "follow", nil, nil, nil, true)
		inst.fx.components.highlightchild:SetOwner(owner)
		inst.components.colouraddersync:SetColourChangedFn(OnColourChanged)
		inst.OnRemoveEntity = FxOnRemoveEntity
	end
end

local function FxAttachToOwner(inst, owner)
	inst.entity:SetParent(owner.entity)
	inst.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true)
	inst.components.highlightchild:SetOwner(owner)
	if owner.components.colouradder ~= nil then
		owner.components.colouradder:AttachChild(inst)
	end

	--Dedicated server does not need to spawn the local fx
	if not TheNet:IsDedicated() then
		FxOnEntityReplicated(inst)
	end
end

local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

	inst.AnimState:SetBank("king_cane")
    inst.AnimState:SetBuild("king_cane")
    inst.AnimState:PlayAnimation("swap_loop1", true)

    inst:AddComponent("highlightchild")
	inst:AddComponent("colouraddersync")

    inst.level = net_tinybyte(inst.GUID, "king_cane_fx.level", "leveldirty")
    inst.level:set(0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("leveldirty", OnFXLevelDirty)
		inst.OnEntityReplicated = FxOnEntityReplicated

        return inst
    end

	inst.AttachToOwner = FxAttachToOwner
    inst.SetFXLevel = SetFXLevel
    inst.persists = false

    return inst
end

return Prefab("king_cane", fn, assets, prefabs),
    Prefab("king_cane_fx", fxfn, assets)
