local PlayerCommonExtensions = require("prefabs/player_common_extensions")
local WX78Common = require("prefabs/wx78_common")

local assets = JoinArrays({
    Asset("SCRIPT", "scripts/prefabs/wx78_common.lua"),
    Asset("ANIM", "anim/wx_chassis.zip"),
    Asset("ANIM", "anim/ui_wx78_backupbody_5x3.zip"),
	Asset("ANIM", "anim/wx78_map_marker.zip"),
}, WX78Common.DEPENDENCIES.assets)

local prefabs = JoinArrays({
    "wx78_classified",
    "wx78_big_spark",
	"wx78_backupbody_globalicon",
	"wx78_backupbody_revealableicon",
    "explode_reskin",
    "collapse_small",
    "wx78_heat_steam",
    "wx78_backupbody_inventory",
}, WX78Common.DEPENDENCIES.prefabs)

local PHYSICS_RADIUS = 0.5

local function SpawnBigSpark(inst)
    SpawnPrefab("wx78_big_spark"):AlignToTarget(inst)
end

local function OnWorked(inst, worker)
    local pt = inst:GetPosition()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(pt:Get())
    fx:SetMaterial("metal")

    inst.wx78_backupbody_inventory.components.inventory:DropEverything()
    inst.components.container:DropEverything()
    local modules = inst.components.upgrademoduleowner:PopAllModules()
    for _, onemodule in ipairs(modules) do
        inst.components.lootdropper:FlingItem(onemodule)
    end

    inst:Remove()
end

local function OnHit(inst, worker, workleft)
    if workleft > 0 then
        inst.SoundEmitter:PlaySound("WX_rework/shock/big")
        if inst.wx78_backupbody_inventory.AnimState:IsCurrentAnimation("wx_chassis_idle") then
            inst.wx78_backupbody_inventory.AnimState:PlayAnimation("wx_chassis_hit")
            inst.wx78_backupbody_inventory.AnimState:PushAnimation("wx_chassis_idle", true)
        end
    end
end

local function DisplayNameFn(inst)
    local ownername = inst.components.linkeditem:GetOwnerName()
    return ownername and subfmt(STRINGS.NAMES.WX78_BACKUPBODY_FMT, { name = ownername }) or nil
end

local function GetSpecialDescription(inst, viewer)
    if not viewer:HasTag("playerghost") then
        local ownername =  inst.components.linkeditem:GetOwnerName()
        if ownername then
            local descriptions = GetString(viewer.prefab, "DESCRIBE", "WX78")
            local description = descriptions and descriptions.GENERIC or nil
            if description then
                return string.format(description, ownername) -- Bypass translations for player names.
            end
        end
    end
end

local function TryToActivateBetaCircuitStates(inst)
    local modules = inst.components.upgrademoduleowner:GetModules(CIRCUIT_BARS.BETA)
    for _, mod in ipairs(modules) do
        mod.components.upgrademodule:TryActivate()
    end
end

local function TryToDeactivateBetaCircuitStates(inst)
    local modules = inst.components.upgrademoduleowner:GetModules(CIRCUIT_BARS.BETA)
    for _, mod in ipairs(modules) do
        mod.components.upgrademodule:TryDeactivate()
    end
end

local function CheckBetaCircuitStatesFrom(inst, owner)
    if owner and owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("wx78_bodycircuits") then
        inst:TryToActivateBetaCircuitStates()
    else
        inst:TryToDeactivateBetaCircuitStates()
    end
end

local function CheckCircuitSlotStatesFrom(inst, owner)
    inst._maxcharge = owner ~= nil and owner.components.upgrademoduleowner ~= nil and owner.components.upgrademoduleowner:GetMaxChargeLevel()
        or TUNING.WX78_INITIAL_MAXCHARGELEVEL
    inst.components.upgrademoduleowner:SetMaxCharge(inst._maxcharge)
end

local function TryToAttachToOwner(inst, owner)
    if owner == nil or owner.is_snapshot_user_session then
        return false
    end
    local linkeditem = inst.components.linkeditem
    if linkeditem == nil or linkeditem:GetOwnerUserID() ~= nil then
        return false
    end

    local isbuildbuffered = owner.components.builder and owner.components.builder:IsBuildBuffered("wx78_backupbody")
    local numfreeneeded = isbuildbuffered and 1 or 0
    if owner.wx78_classified and (owner.wx78_classified:GetNumFreeBackupBodies() > numfreeneeded) then
        linkeditem:LinkToOwnerUserID(owner.userid)
        if owner.isplayer then
            inst.wx78_backupbody_inventory.components.skinner:CopySkinsFromPlayer(owner, true)
            if not inst._hide_body_skinfx then
                local x, y, z = inst.Transform:GetWorldPosition()
                local fx = SpawnPrefab("explode_reskin")
                fx.Transform:SetPosition(x, y, z)
            else
                inst._hide_body_skinfx = nil
            end
        else
            inst.wx78_backupbody_inventory.components.skinner:SetupNonPlayerData()
        end
        inst:CheckBetaCircuitStatesFrom(owner)
        inst:CheckCircuitSlotStatesFrom(owner)
        return true
    end

    return false
end

local function OnBuiltFn(inst, builder)
    inst._hide_body_skinfx = true
    inst:TryToAttachToOwner(builder)
    inst.wx78_backupbody_inventory.AnimState:PlayAnimation("wx_chassis_place")
    inst.wx78_backupbody_inventory.AnimState:PushAnimation("wx_chassis_idle", true)
end

local function CanDoerActivate(inst, doer)
    if not doer.isplayer or doer.wx78_classified == nil then
        return false, "NOTAROBOT"
    end

    local owneruserid = inst.components.linkeditem:GetOwnerUserID()
    if owneruserid and owneruserid ~= doer.userid then
        return false, "NOTMYBACKUP"
    end

    if not owneruserid and not inst:TryToAttachToOwner(doer) then
        return false, "TOOMANYBACKUPBODIES"
    end

    return true
end

local function OnActivateFn(inst, doer)
    -- FIXME(JBK): WX: Make this code less in here and more in a component or component util file.
    inst.components.activatable.inactive = true -- FIXME(JBK): WX: Make this a task?

    local x, y, z = inst.Transform:GetWorldPosition()
    local x2, y2, z2 = doer.Transform:GetWorldPosition()

    inst.wx78_backupbody_inventory.components.inventory:SwapEquipment(doer, nil, true)

    if doer.components.inventory then
        doer.components.inventory.ignoresound = true
        doer.components.inventory.silentfull = true
        doer.components.inventory:ReturnActiveItem()
        local maxslotstouse = math.min(inst.components.container.numslots, doer.components.inventory.maxslots)
        local itemsfromcontainer = {}
        for slot = 1, inst.components.container.numslots do
            local item = inst.components.container:RemoveItemBySlot(slot)
            if item then
                item.prevcontainer = nil
                item.prevslot = nil
                itemsfromcontainer[slot] = item
            end
        end
        local itemsfrominventory = {}
        for slot = 1, doer.components.inventory.maxslots do
            local item = doer.components.inventory:RemoveItemBySlot(slot)
            if item then
                item.prevcontainer = nil
                item.prevslot = nil
                itemsfrominventory[slot] = item
            end
        end
        for slot = 1, maxslotstouse do
            local item = itemsfromcontainer[slot]
            if item and not doer.components.inventory:GiveItem(item, slot) then
                item.Transform:SetPosition(x, y, z)
                if item.components.inventoryitem then
                    item.components.inventoryitem:OnDropped(true)
                end
            end
            item = itemsfrominventory[slot]
            if item and not inst.components.container:GiveItem(item, slot) then
                item.Transform:SetPosition(x2, y2, z2)
                if item.components.inventoryitem then
                    item.components.inventoryitem:OnDropped(true)
                end
            end
        end
        for slot = maxslotstouse + 1, inst.components.container.numslots do
            local item = itemsfromcontainer[slot]
            if item then
                item.Transform:SetPosition(x2, y2, z2)
                if item.components.inventoryitem then
                    item.components.inventoryitem:OnDropped(true)
                end
            end
        end
        for slot = maxslotstouse + 1, doer.components.inventory.maxslots do
            local item = itemsfrominventory[slot]
            if item then
                item.Transform:SetPosition(x2, y2, z2)
                if item.components.inventoryitem then
                    item.components.inventoryitem:OnDropped(true)
                end
            end
        end
        doer.components.inventory.silentfull = false
        doer.components.inventory.ignoresound = false
    end

    if doer.components.skinner then
        local skindata = deepcopy(inst.wx78_backupbody_inventory.components.skinner:OnSave())
        inst.wx78_backupbody_inventory.components.skinner:CopySkinsFromPlayer(doer, true)
        doer.components.skinner:OnLoad(skindata)
    end

    if doer.components.upgrademoduleowner then
        local doer_charge_level = doer.components.upgrademoduleowner:GetChargeLevel()
        local charge_level = inst.components.upgrademoduleowner:GetChargeLevel()
        inst.components.upgrademoduleowner:SetChargeLevel(doer_charge_level)
        doer.components.upgrademoduleowner:SetChargeLevel(charge_level)

        inst.components.upgrademoduleowner:SwapUpgradeModules(doer.components.upgrademoduleowner)
        inst:CheckBetaCircuitStatesFrom(doer)
    end

    local rot = inst.Transform:GetRotation()
    local rot2 = doer.Transform:GetRotation()
    inst.Transform:SetRotation(rot2)
    if inst.Physics ~= nil then
        inst.Physics:Teleport(x2, y2, z2)
    else
        inst.Transform:SetPosition(x2, y2, z2)
        inst.Transform:ClearTransformationHistory()
    end
    doer.Transform:SetRotation(rot)
    if doer.Physics ~= nil then
        doer.Physics:Teleport(x, y, z)
    else
        doer.Transform:SetPosition(x, y, z)
        doer.Transform:ClearTransformationHistory()
    end
    inst:PushEvent("teleported")
    doer:PushEvent("teleported")
    return true
end

local function GetActivateVerb()
    return "EXCHANGEKNOWLEDGE"
end

local function AttachClassified_wx78(inst, classified)
    inst.wx78_classified = classified
    inst.ondetach_wx78_classified = function() inst:DetachClassified_wx78() end
    inst:ListenForEvent("onremove", inst.ondetach_wx78_classified, classified)
end

local function DetachClassified_wx78(inst)
    inst.wx78_classified = nil
    inst.ondetach_wx78_classified = nil
end

local function OnOpen(inst, data)
    if data and data.doer then
        if inst.wx78_classified then
            inst.wx78_classified.Network:SetClassifiedTarget(data.doer)
        end

        -- inst.components.upgrademoduleowner:StartInspecting(data.doer)
    end
end
local function OnClose(inst, data)
    -- inst.components.upgrademoduleowner:StopInspecting()
    if inst.wx78_classified then
        inst.wx78_classified.Network:SetClassifiedTarget(inst)
    end
end

local function OnSkillTreeInitializedFn(inst, owner)
    if owner.wx78_classified == nil or not owner.wx78_classified:TryToAddBackupBody(inst) then
        local linkeditem = inst.components.linkeditem
        if linkeditem then
            linkeditem:LinkToOwnerUserID(nil)
        end
        inst:TryToDeactivateBetaCircuitStates()
    else
        inst:CheckBetaCircuitStatesFrom(owner)
        inst:CheckCircuitSlotStatesFrom(owner)
    end
end
local function OnOwnerInstCreatedFn(inst, owner)
	inst.components.globaltrackingicon:StartTracking(owner)
end
local function OnOwnerInstRemovedFn(inst, owner)
    if inst.globalmapicon then
        if inst.globalmapicon:IsValid() then
            inst.globalmapicon:Remove()
        end
        inst.globalmapicon = nil
    end

    inst:TryToDeactivateBetaCircuitStates()

    if owner and owner.wx78_classified then
        owner.wx78_classified:TryToRemoveBackupBody(inst)
    end
end

----------------------------------------------------------------------------------------

-- TODO can we pop and unpop modules?

local function OnUpgradeModuleAdded(inst, moduleent)
    local moduletype = moduleent.components.upgrademodule:GetType()

    -- inst:PushEvent("upgrademodulesdirty", inst:GetModulesData())
    if inst.wx78_classified ~= nil then
        local newmodule_index = inst.components.upgrademoduleowner:GetNumModules(moduletype)
        inst.wx78_classified.upgrademodulebars[moduletype][newmodule_index]:set(moduleent._netid or 0)
    end
end

local function OnUpgradeModuleRemoved(inst, moduleent)
    -- TODO?
end

local function OnOneUpgradeModulePopped(inst, moduleent, was_activated)
    -- If the module we just popped was charged, use that charge
    -- as the cost of this removal.
    local moduletype = moduleent.components.upgrademodule:GetType()
    local moduleslotcount = moduleent.components.upgrademodule:GetSlots()
    if was_activated then
        local charge_cost = -moduleslotcount
        local owner = inst.components.linkeditem:GetOwnerInst()
        local skilltreeupdater = owner.components.skilltreeupdater
        if skilltreeupdater and skilltreeupdater:IsActivated("wx78_circuitry_lesschargeloss") then
            charge_cost = math.min(charge_cost + 1, -1)
        end
        inst.components.upgrademoduleowner:DoDeltaCharge(charge_cost)
    end

    -- inst:PushEvent("upgrademodulesdirty", inst:GetModulesData())
    if inst.wx78_classified ~= nil then
        -- This is a callback of the remove, so our current NumModules should be
        -- 1 lower than the index of the module that was just removed.
        local top_module_index = inst.components.upgrademoduleowner:GetNumModules(moduletype) + 1
        inst.wx78_classified.upgrademodulebars[moduletype][top_module_index]:set(0)
    end
end

local function OnAllUpgradeModulesRemoved(inst)
    if inst.components.workable == nil or inst.components.workable:GetWorkLeft() > 0 then
        SpawnBigSpark(inst)
    end

    inst:PushEvent("upgrademoduleowner_popallmodules")

    if inst.wx78_classified ~= nil then
        for i, modules in pairs(inst.wx78_classified.upgrademodulebars) do
            for j, netvar in ipairs(modules) do
                netvar:set(0)
            end
        end
    end
end

----------------------------------------------------------------------------------------

local function UnregisterGhostRezEvents(inst, doer)
    inst:RemoveEventCallback("ms_respawnedfromghost", inst._ghostrez_respawned, doer)
    inst:RemoveEventCallback("onremove", inst._ghostrez_removed, doer)
    inst._ghostrez_respawned = nil
    inst._ghostrez_removed = nil
end

local function RegisterGhostRezEvents(inst, doer)
    inst._ghostrez_respawned = function()
        UnregisterGhostRezEvents(inst, doer)
        if inst.components.activatable:CanActivate(doer) then
            inst.components.upgrademoduleowner:SetChargeLevel(0)
            inst.components.activatable:DoActivate(doer)
            inst:Remove()
        end
    end
    inst._ghostrez_removed = function()
        UnregisterGhostRezEvents(inst, doer)
    end
    inst:ListenForEvent("ms_respawnedfromghost", inst._ghostrez_respawned, doer)
    inst:ListenForEvent("onremove", inst._ghostrez_removed, doer)
end

local function OnHaunt(inst, doer)
    if not inst.components.activatable:CanActivate(doer) then
        return false
    end
    if not (doer.components.skilltreeupdater and doer.components.skilltreeupdater:IsActivated("wx78_ghostrevive_1")) then
        return false
    end
    RegisterGhostRezEvents(inst, doer)
    return true
end

local function AnimStateGetterFn(inst)
    return inst.wx78_backupbody_inventory.AnimState
end

----------------------------------------------------------------------------------------

local function OnSave(inst, data)
    data.body_inventory = inst.wx78_backupbody_inventory:GetSaveRecord()
    data.maxcharge = inst._maxcharge or nil
end

local function OnLoad(inst, data, newents)
    if data then
        if data.body_inventory ~= nil then
            inst.wx78_backupbody_inventory:Remove()
            inst.wx78_backupbody_inventory = SpawnSaveRecord(data.body_inventory, newents)
            inst.wx78_backupbody_inventory.entity:SetParent(inst.entity)
            inst.wx78_backupbody_inventory.Transform:SetPosition(0, 0, 0) -- Remove saved position from stored record.
            if not TheNet:IsDedicated() then
                inst.highlightchildren[1] = inst.wx78_backupbody_inventory
            end
        end
        if data.maxcharge ~= nil then
            inst.components.upgrademoduleowner:SetMaxCharge(data.maxcharge)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    --Default to electrocute light values
    inst.Light:SetIntensity(.8)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.65)
    inst.Light:SetColour(255 / 255, 255 / 255, 236 / 255)
    inst.Light:Enable(false)

    MakeSmallObstaclePhysics(inst, PHYSICS_RADIUS)
    inst:SetPhysicsRadiusOverride(PHYSICS_RADIUS)

    inst.Transform:SetFourFaced()

    WX78Common.SetupUpgradeModuleOwnerInstanceFunctions(inst)

    inst:AddTag("scarytoprey")
    inst:AddTag("equipmentmodel")
    inst:AddTag("wx78_backupbody")
    inst:AddTag("followsthroughvirtualrooms")
    --upgrademoduleowner (from upgrademoduleowner component) added to pristine state for optimization
    inst:AddTag("upgrademoduleowner")

    local linkeditem = inst:AddComponent("linkeditem")
    inst.displaynamefn = DisplayNameFn
    inst.GetActivateVerb = GetActivateVerb

    inst.AttachClassified_wx78 = AttachClassified_wx78
    inst.DetachClassified_wx78 = DetachClassified_wx78

    WX78Common.Initialize_Common(inst)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.wx78_classified = SpawnPrefab("wx78_classified")
    inst.wx78_classified.entity:SetParent(inst.entity)
    inst.wx78_classified.Network:SetClassifiedTarget(inst)

    inst.wx78_backupbody_inventory = SpawnPrefab("wx78_backupbody_inventory")
    inst.wx78_backupbody_inventory.entity:SetParent(inst.entity)
    if not TheNet:IsDedicated() then
        inst.highlightchildren = { inst.wx78_backupbody_inventory }
    end

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.HAMMER)
    workable:SetWorkLeft(TUNING.SKILLS.WX78.BACKUPBODY_WORK_REQUIRED)
    workable:SetOnFinishCallback(OnWorked)
    workable:SetOnWorkCallback(OnHit)

    local inspectable = inst:AddComponent("inspectable")
    inspectable.getspecialdescription = GetSpecialDescription

    local activatable = inst:AddComponent("activatable")
    activatable.CanActivateFn = CanDoerActivate
    activatable.OnActivate = OnActivateFn
    activatable.quickaction = true
    activatable.forcerightclickaction = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("timer")

    local hauntable = inst:AddComponent("hauntable")
    hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
    hauntable:SetOnHauntFn(OnHaunt)
    hauntable:SetAnimStateGetterFn(AnimStateGetterFn)

    local container = inst:AddComponent("container")
    container:WidgetSetup("wx78_backupbody")
    container.onopenfn = OnOpen
    container.onclosefn = OnClose

	inst:AddComponent("globaltrackingicon")
	inst.components.globaltrackingicon:StartTracking(nil, "wx78_backupbody")

    local upgrademoduleowner = inst:AddComponent("upgrademoduleowner")
    upgrademoduleowner.onmoduleadded = OnUpgradeModuleAdded
    upgrademoduleowner.onmoduleremoved = OnUpgradeModuleRemoved
    upgrademoduleowner.ononemodulepopped = OnOneUpgradeModulePopped
    upgrademoduleowner.onallmodulespopped = OnAllUpgradeModulesRemoved
    -- upgrademoduleowner.canupgradefn = CanUseUpgradeModule
    upgrademoduleowner:SetChargeLevel(3)
    upgrademoduleowner:SetAutomaticModuleActivations(false)

    linkeditem:SetOnSkillTreeInitializedFn(OnSkillTreeInitializedFn)
    linkeditem:SetOnOwnerInstCreatedFn(OnOwnerInstCreatedFn)
    linkeditem:SetOnOwnerInstRemovedFn(OnOwnerInstRemovedFn)

    inst.OnBuiltFn = OnBuiltFn
    inst.TryToAttachToOwner = TryToAttachToOwner
    inst.TryToActivateBetaCircuitStates = TryToActivateBetaCircuitStates
    inst.TryToDeactivateBetaCircuitStates = TryToDeactivateBetaCircuitStates
    inst.CheckBetaCircuitStatesFrom = CheckBetaCircuitStatesFrom
    inst.CheckCircuitSlotStatesFrom = CheckCircuitSlotStatesFrom
    inst.AddTemperatureModuleLeaning = WX78Common.AddTemperatureModuleLeaning
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    WX78Common.Initialize_Master(inst)

    return inst
end

-------------------------------
-- Inventory handler.

local function OnRemoveEntity(inst)
	if inst.wx78_backupbody ~= nil and inst.wx78_backupbody.highlightchildren ~= nil then
		table.removearrayvalue(inst.wx78_backupbody.highlightchildren, inst)
		if #inst.wx78_backupbody.highlightchildren <= 0 then
			inst.wx78_backupbody.highlightchildren = nil
		end
	end
end

local function OnEntityReplicated(inst)
	local parent = inst.entity:GetParent()
	if parent ~= nil and parent.prefab == "wx78_backupbody" then
		if parent.highlightchildren == nil then
			parent.highlightchildren = { inst }
		else
			table.insert(parent.highlightchildren, inst)
		end

		inst.wx78_backupbody = parent
		inst.OnRemoveEntity = OnRemoveEntity
	end
end

local function fn_inventory()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst:AddTag("equipmentmodel")
    inst:AddTag("FX")

    PlayerCommonExtensions.SetupBaseSymbolVisibility(inst)
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wx78")
    inst.AnimState:AddOverrideBuild("wx_chassis")
    inst.AnimState:PlayAnimation("wx_chassis_idle")

    inst.DynamicShadow:SetSize(1.3, .6)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
        return inst
    end

    local inventory = inst:AddComponent("inventory") -- For equipment only.
    inventory.maxslots = 0

    local skinner = inst:AddComponent("skinner")
    skinner:SetupNonPlayerData()
    skinner.useskintypeonload = true -- Hack.

    return inst
end

-------------------------------
-- Placer.

local PLAYER_SYMBOLS = {
    "arm_lower",
    "arm_upper",
    "arm_upper_skin",
    "beard",
    "cheeks",
    "face",
    "foot",
    "hair",
    "hair_hat",
    "hairfront",
    "hairpigtails",
    "hand",
    "headbase",
    "headbase_hat",
    "leg",
    "skirt",
    "tail",
    "torso",
    "torso_pelvis",
}
local function Placer_OnSetBuilder(inst)
    local builder = inst.components.placer.builder
    if builder and builder == ThePlayer and builder.wx78_classified and builder.wx78_classified:GetNumFreeBackupBodies() > 0 then
        -- NOTES(JBK): Special case. This does not handle the symbol exchange logic.
        -- For this structure it does not matter what the correct layering is for what the torso symbols are.
        local skin_build = builder.AnimState:GetSkinBuild()
        if skin_build and skin_build ~= "" then
            inst.AnimState:SetSkin(skin_build, builder.prefab)
        end
        for _, v in ipairs(PLAYER_SYMBOLS) do
            if builder.AnimState:BuildHasSymbol(v) and inst.AnimState:BuildHasSymbol(v) then
                local build, sym = builder.AnimState:GetSymbolOverride(v)
                if build then
                    if builder.AnimState:IsSkinBuild(build) then
                        inst.AnimState:OverrideSkinSymbol(v, build, sym)
                    else
                        inst.AnimState:OverrideSymbol(v, build, sym)
                    end
                end
            end
        end
    end
end
local function PlacerPostinit(inst)
    PlayerCommonExtensions.SetupBaseSymbolVisibility(inst)
    if inst.components.placer then
        inst.components.placer.onbuilderset = Placer_OnSetBuilder
    end
end

-------------------------------
-- Map icons.

local globalicon, revealableicon =
	MakeGlobalTrackingIcons("wx78_backupbody", {
		icondata =
		{
			icon = "wx78_backupbody",
			priority = MINIMAP_DECORATION_PRIORITY,
			globalicon = "wx78_backupbody_global",
		},
	})

return Prefab("wx78_backupbody", fn, assets, prefabs),
    Prefab("wx78_backupbody_inventory", fn_inventory),
    MakePlacer("wx78_backupbody_placer", "wilson", "wx78", "wx_chassis_idle", nil, nil, nil, nil, 0, "four", PlacerPostinit),
	globalicon,
	revealableicon
