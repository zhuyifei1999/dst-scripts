-- These functions can also be used for wx78_backupbody so check everything.
-- Search string: WX78Common file definition.

local DEPENDENCIES = {
	assets =
	{
		Asset("ANIM", "anim/wx_fx.zip"),
	},
	prefabs = {},
}

---------------------------------------------------------------------------

local function GetMaxEnergy(inst)
    if inst.components.upgrademoduleowner ~= nil then
        return inst.components.upgrademoduleowner.max_charge
    elseif inst.wx78_classified ~= nil then
        return inst.wx78_classified.maxenergylevel:value()
    else
        return TUNING.WX78_INITIAL_MAXCHARGELEVEL
    end
end

local function GetEnergyLevel(inst)
    if inst.components.upgrademoduleowner ~= nil then
        return inst.components.upgrademoduleowner.charge_level
    elseif inst.wx78_classified ~= nil then
        return inst.wx78_classified.currentenergylevel:value()
    else
        return 0
    end
end

local DEFAULT_ZEROS_MODULEDATA = {}
for moduletype, i in pairs(CIRCUIT_BARS) do
    DEFAULT_ZEROS_MODULEDATA[i] = {}
    for j = 1, MAX_CIRCUIT_SLOTS do
        table.insert(DEFAULT_ZEROS_MODULEDATA[i], 0)
    end
end

local function GetModulesData(inst)
    local moddata = {}
    for i, v in pairs(CIRCUIT_BARS) do
        moddata[v] = {}
    end

    if inst.components.upgrademoduleowner ~= nil then
        for bartype, modules in pairs(inst.components.upgrademoduleowner.module_bars) do
            for i, module in ipairs(modules) do
                table.insert(moddata[bartype], module._netid)
            end

            -- Fill out the rest of the table with 0s
            while #moddata[bartype] < MAX_CIRCUIT_SLOTS do
                table.insert(moddata[bartype], 0)
            end
        end

    elseif inst.wx78_classified ~= nil then
        moddata = inst.wx78_classified:GetModulesData()
    else
        moddata = DEFAULT_ZEROS_MODULEDATA
    end

    return moddata
end

local function CanUpgradeWithModule(inst, moduleent)
    if moduleent == nil then
        return false
    end

    local bar_type = moduleent._type
    local slots_inuse = moduleent._slots or 0

    if inst.components.upgrademoduleowner ~= nil then
        for _, module in ipairs(inst.components.upgrademoduleowner:GetModules(bar_type)) do
            local modslots = module.components.upgrademodule.slots
            slots_inuse = slots_inuse + modslots
        end

        return (inst.components.upgrademoduleowner.max_charge - slots_inuse) >= 0
    elseif inst.wx78_classified ~= nil then
        return inst.wx78_classified:CanUpgradeWithModule(moduleent)
    end
end

local function GetModuleTypeCount_Internal(inst, module_name)
    if inst.components.upgrademoduleowner ~= nil then
        return inst.components.upgrademoduleowner:GetModuleTypeCount(module_name)
    elseif inst.wx78_classified ~= nil then
        return inst.wx78_classified:GetModuleTypeCount(module_name)
    else
        return 0
    end
end

local function GetModuleTypeCount(inst, ...)
    local c = 0
    --
    local module_names = select(1, ...)
	if type(module_names) == "table" then
		for i, v in ipairs(module_names) do
            c = c + GetModuleTypeCount_Internal(inst, v)
		end
	else
        c = c + GetModuleTypeCount_Internal(inst, module_names)
		for i = 2, select("#", ...) do
            c = c + GetModuleTypeCount_Internal(inst, select(i, ...))
		end
	end

    return c
end

local function UnplugModule(inst, moduletype, moduleindex)
    if inst.components.upgrademoduleowner ~= nil then
        local module = inst.components.upgrademoduleowner:GetModule(moduletype, moduleindex)
        if module ~= nil then
            inst:PushEventImmediate("unplugmodule", module)
        end
    elseif inst.wx78_classified ~= nil then
        inst.wx78_classified:UnplugModule(moduletype, moduleindex)
    end
end

--
local WX78_UPGRADE_MODULE_ACTIONS = ACTIONS and
{
    [ACTIONS.TOGGLEWXSCREECH] = {
        validfn = function(inst)
            if inst:HasTag("wx_screeching") then
                return true
            end

            if inst.components.wx78_abilitycooldowns and inst.components.wx78_abilitycooldowns:IsInCooldown("wxscreech") then
                return false
            end

            return not inst:HasAnyTag("wx_screeching", "busy")
        end,
    },
    [ACTIONS.TOGGLEWXSHIELDING] = {
        validfn = function(inst)
            if inst:HasTag("wx_shielding") then
                return true
            end

            if inst.components.wx78_abilitycooldowns and inst.components.wx78_abilitycooldowns:IsInCooldown("wxshielding") then
                return false
            end
            return not inst:HasAnyTag("wx_shielding", "busy")
        end,
    },
}

local function CollectUpgradeModuleActions(inst, actions)
    -- Piggyback off of entityscript.inherentactions functionality
    if inst.wx78_classified ~= nil and inst.wx78_classified.inherentactions ~= nil then
        for k, v in pairs(inst.wx78_classified.inherentactions) do
            local actiondata = WX78_UPGRADE_MODULE_ACTIONS[k]
            if actiondata ~= nil and actiondata.validfn(inst) then
                table.insert(actions, k)
            end
        end
    end
end

-- Didn't want to make upgrademoduleowner a networked component
local function SetupUpgradeModuleOwnerInstanceFunctions(inst)
    inst.GetMaxEnergy = GetMaxEnergy
    inst.GetEnergyLevel = GetEnergyLevel
    inst.GetModulesData = GetModulesData
    inst.CanUpgradeWithModule = CanUpgradeWithModule
    inst.GetModuleTypeCount = GetModuleTypeCount
    inst.UnplugModule = UnplugModule
    inst.CollectUpgradeModuleActions = CollectUpgradeModuleActions
end

--------------------------------------------------------------------------

local _steam_fx_pool

local function OnSteamFxTimeOut(inst)
	inst:Remove()
	table.removearrayvalue(_steam_fx_pool, inst)
	if #_steam_fx_pool <= 0 then
		_steam_fx_pool = nil
	end
end

local function OnSteamFxAnimOver(inst)
	inst.Follower:StopFollowing()
	inst:RemoveFromScene()
	if _steam_fx_pool then
		table.insert(_steam_fx_pool, inst)
	else
		_steam_fx_pool = { inst }
	end
	--assert(inst._timeouttask == nil)
	inst._timeouttask = inst:DoTaskInTime(30, OnSteamFxTimeOut)
end

local function CreateSteamFx(frame)
	local inst = _steam_fx_pool and table.remove(_steam_fx_pool)
	if inst then
		inst:ReturnToScene()
		inst._timeouttask:Cancel()
		inst._timeouttask = nil
	else
		inst = CreateEntity()

		--[[Non-networked entity]]
		inst.entity:SetCanSleep(false)
		inst.persists = false

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddFollower()

		inst:AddTag("DECOR")
		inst:AddTag("NOCLICK")

		inst.AnimState:SetBank("wx_fx")
		inst.AnimState:SetBuild("wx_fx")
		inst.AnimState:SetFinalOffset(1)

		inst:ListenForEvent("animover", OnSteamFxAnimOver)
	end

	inst.AnimState:PlayAnimation("steam_"..tostring(frame))

	return inst
end

local function OnSteamFx_NoFaced(inst)
	if not inst:IsAsleep() then
		CreateSteamFx(1).Follower:FollowSymbol(inst.GUID, "headbase", 0, 0, 0, true)
	end
end

local function OnSteamFx(inst)
	if not inst:IsAsleep() then
		CreateSteamFx(1).Follower:FollowSymbol(inst.GUID, "headbase", 0, 0, 0, true, nil, 0)
		CreateSteamFx(2).Follower:FollowSymbol(inst.GUID, "headbase", 0, 0, 0, true, nil, 1)
		CreateSteamFx(1).Follower:FollowSymbol(inst.GUID, "headbase", 0, 0, 0, true, nil, 2, 5)
	end
end

local function AddHeatSteamFx_Common(inst, nofacings)
	inst.steamfx = net_event(inst.GUID, "wx78_common.steamfx")

	if not TheNet:IsDedicated() then
		inst:ListenForEvent("wx78_common.steamfx", nofacings and OnSteamFx_NoFaced or OnSteamFx)
	end
end

local HEATSTEAM_TIMERNAME = "heatsteam_tick"
local HEATSTEAM_TICKRATE = 5

local function do_steam_fx(inst)
	--NOTE: steamfx could be a reference to net_event on another prefab! (see wx78_backupbody)
	--      That's why we use event listener even on server.
	inst.steamfx:push()

    if inst.components.timer then
        inst.components.timer:StartTimer(HEATSTEAM_TIMERNAME, HEATSTEAM_TICKRATE)
    end
end

local function OnTimerFinished(inst, data)
    if data.name == HEATSTEAM_TIMERNAME then
        do_steam_fx(inst)
    end
end

local function AddTemperatureModuleLeaning(inst, leaning_change) -- Negative is colder, positive is warmer
    inst._temperature_modulelean = inst._temperature_modulelean + leaning_change

    if inst._temperature_modulelean > 0 then
        if inst.components.heater then
            inst.components.heater:SetThermics(true, false)
        end

        if inst.components.timer then
            if not inst.components.timer:TimerExists(HEATSTEAM_TIMERNAME) then
                inst.components.timer:StartTimer(HEATSTEAM_TIMERNAME, HEATSTEAM_TICKRATE, false, 0.5)
            end
        end

        if inst.components.frostybreather then
            inst.components.frostybreather:ForceBreathOff()
        end
    elseif inst._temperature_modulelean == 0 then
        if inst.components.heater then
            inst.components.heater:SetThermics(false, false)
        end

        if inst.components.timer then
            inst.components.timer:StopTimer(HEATSTEAM_TIMERNAME)
        end

        if inst.components.frostybreather then
            inst.components.frostybreather:ForceBreathOff()
        end
    else
        if inst.components.heater then
            inst.components.heater:SetThermics(false, true)
        end

        if inst.components.timer then
            inst.components.timer:StopTimer(HEATSTEAM_TIMERNAME)
        end

        if inst.components.frostybreather then
            inst.components.frostybreather:ForceBreathOn()
        end
    end
end

----------------------------------------------------------------------------------------

local function ModuleBasedPreserverRateFn(inst, item)
    return (inst._temperature_modulelean > 0 and TUNING.WX78_PERISH_HOTRATE)
        or (inst._temperature_modulelean < 0 and TUNING.WX78_PERISH_COLDRATE)
        or 1
end

----------------------------------------------------------------------------------------

local function GetThermicTemperatureFn(inst, observer)
    return inst._temperature_modulelean * TUNING.WX78_HEATERTEMPPERMODULE
end

--------------------------------------------------------------------------
-- Always LAST!
local function Initialize_Common(inst)
end
local function Initialize_Master(inst)
    inst._temperature_modulelean = 0 -- Positive if "hot", negative if "cold"; see wx78_moduledefs
    
    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, false)
    inst.components.heater.heatfn = GetThermicTemperatureFn

    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(ModuleBasedPreserverRateFn)

    inst:ListenForEvent("timerdone", OnTimerFinished)
end
return {
    DEPENDENCIES = DEPENDENCIES,
    SetupUpgradeModuleOwnerInstanceFunctions = SetupUpgradeModuleOwnerInstanceFunctions,
    AddTemperatureModuleLeaning = AddTemperatureModuleLeaning,


    -- Initialization functions should be last in the file do not add your functions below this line unless it is for initialization.
	AddHeatSteamFx_Common = AddHeatSteamFx_Common,
    Initialize_Common = Initialize_Common,
    Initialize_Master = Initialize_Master,
}
