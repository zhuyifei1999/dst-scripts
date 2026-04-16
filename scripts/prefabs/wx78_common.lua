-- These functions can also be used for wx78_backupbody so check everything.
-- Search string: WX78Common / WX78_Common file definition.
local WX78Common -- Predeclare for use inside of functions.

local DEPENDENCIES = {
	assets =
	{
		Asset("ANIM", "anim/wx_fx.zip"),
	},
	prefabs = {
        "wx78_big_spark",
        "wx78_classified",
        -- socket_shadow_harvester component
        "shadow_puff",
        "shadow_harvester_trail",
        -- socket_shadow_heart component
        "wx78_possessed_shadow",
        "wx78_shadow_heart_debuff",
    },
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
			return not inst:HasAnyTag("wx_screeching", "busy", "inspectingupgrademodules", "using_drone_remote")
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
			return not inst:HasAnyTag("wx_shielding", "busy", "inspectingupgrademodules", "using_drone_remote")
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

local function CreateDizzyFx()
	local inst = CreateEntity()

	inst:AddTag("DECOR")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	--inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("wilson")
	inst.AnimState:SetBuild("player_wx78_actions")
	inst.AnimState:PlayAnimation("dizzy_meter", true)
	inst.AnimState:SetFinalOffset(2)

	return inst
end

local function RemoveDizzyFx(inst)
	inst._dizzyfxremovaltask = nil
	inst._dizzyfx:Remove()
	inst._dizzyfx = nil
end

local function OnDizzyLevel(inst)
	local level = inst.dizzylevel:value()
	if level > 0 then
		if inst._dizzyfxremovaltask then
			inst._dizzyfxremovaltask:Cancel()
			inst._dizzyfxremovaltask = nil
			inst._dizzyfx:Show()
		elseif inst._dizzyfx == nil then
			inst._dizzyfx = CreateDizzyFx()
			inst._dizzyfx.entity:SetParent(inst.entity)
			inst._dizzyfx.Follower:FollowSymbol(inst.GUID, "headbase")
		end
		for i = 1, level do
			inst._dizzyfx.AnimState:Show("dizzy"..tostring(i))
		end
		for i = level + 1, 6 do
			inst._dizzyfx.AnimState:Hide("dizzy"..tostring(i))
		end
	elseif inst._dizzyfx and inst._dizzyfxremovaltask == nil then
		inst._dizzyfx:Hide()
		inst._dizzyfxremovaltask = inst:DoTaskInTime(60, RemoveDizzyFx)
	end
end

local function SetDizzyLevel(inst, level)
	if inst.dizzylevel:value() ~= level then
		inst.dizzylevel:set(level)
		if not TheNet:IsDedicated() then
			OnDizzyLevel(inst)
		end
	end
end

local function CalcMaxDizzy(inst)
	return inst:GetModuleTypeCount("spin") > 1 and TUNING.WX78_SPIN_TIME_TO_DIZZY_2 or TUNING.WX78_SPIN_TIME_TO_DIZZY
end

local function CalcRecoveredDizzy(inst)
	local dizzy = inst.sg.mem.wx_spin_buildup
	local max
	if dizzy and inst.sg.mem.wx_spin_last then
		local k = (GetTime() - inst.sg.mem.wx_spin_last) / TUNING.WX78_SPIN_DIZZY_RECOVER_TIME
		max = CalcMaxDizzy(inst)
		dizzy = math.max(0, dizzy - k * k * max)
	end
	return dizzy, max
end

local function SetDizzySound(inst, level, recovering)
	level = Remap(math.floor(level * 12), 1, 12, 0, 0.6)
	if level > 0 then
		if inst._dizzysound ~= level then
			inst._dizzysound = level
			--local volume = level + (recovering and Remap(level, 0, 0.6, 0.1, 0.4) or 0.4)
			if not inst.SoundEmitter:PlayingSound("dizzyloop") then
				inst.SoundEmitter:PlaySound("WX_rework/dizzy/loop", "dizzyloop")--, volume)
			--else
			--	inst.SoundEmitter:SetVolume("dizzyloop", volume)
			end
			inst.SoundEmitter:SetParameter("dizzyloop", "dizziness", level)
		end
	elseif inst._dizzysound then
		inst._dizzysound = nil
		inst.SoundEmitter:KillSound("dizzyloop")
	end
end

local function DizzyUpdate(inst)--, dt)
	if inst.sg:HasStateTag("dizzy") then
		SetDizzyLevel(inst, 6)
		SetDizzySound(inst, 1)
		return
	end

	local dizzy, max
	local recovering = not inst.sg:HasStateTag("spinning")
	if recovering then
		dizzy, max = CalcRecoveredDizzy(inst)
	else
		dizzy = inst.sg.mem.wx_spin_buildup
	end
	if dizzy and dizzy > 0 then
		dizzy = math.min(1, dizzy / (max or CalcMaxDizzy(inst)))
		SetDizzyLevel(inst, math.floor(dizzy * 6))
		SetDizzySound(inst, dizzy, recovering)
	else
		inst.components.updatelooper:RemoveOnUpdateFn(DizzyUpdate)
		inst._dizzyupdate = nil
		SetDizzyLevel(inst, 0)
		SetDizzySound(inst, 0)
	end
end

local function StartDizzyFx(inst)
	if not inst._dizzyupdate then
		if inst.components.updatelooper == nil then
			inst:AddComponent("updatelooper")
		end
		inst.components.updatelooper:AddOnUpdateFn(DizzyUpdate)
		inst._dizzyupdate = true
	end
	DizzyUpdate(inst, 0)
end

local function AddDizzyFx_Common(inst)
	inst.dizzylevel = net_tinybyte(inst.GUID, "wx78.dizzylevel", "dizzyleveldirty")

	if TheWorld.ismastersim then
		inst.SetDizzyLevel = SetDizzyLevel
		inst.StartDizzyFx = StartDizzyFx
		inst.CalcMaxDizzy = CalcMaxDizzy
		inst.CalcRecoveredDizzy = CalcRecoveredDizzy
	else
		inst:ListenForEvent("dizzyleveldirty", OnDizzyLevel)
	end
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
-- socketable
local function MakeItemSocketable(inst)
    MakeItemSocketable_Server(inst)
    local useabletargeteditem = inst.components.useabletargeteditem
    useabletargeteditem:SetCanSelfTarget(true)
    useabletargeteditem:SetUsingItemDoesNotToggleUseability(true)
end

-- socketholder
local function ShouldAllowSocketable_CLIENT(inst, item, doer)
    if inst == doer then
        return true
    end

    return inst.components.linkeditem and inst.components.linkeditem:GetOwnerUserID() == doer.userid
end

local function OnGetSocketable(inst, item, doer) -- doer can be nil!
    local socketname = item.components.socketable:GetSocketName()
    local socketquality = item.components.socketable:GetSocketQuality()
    if socketname == "socket_shadow" then
        if socketquality >= SOCKETQUALITY.LOW then
            if not inst.components.socket_shadow_harvester then
                local socket_shadow_harvester = inst:AddComponent("socket_shadow_harvester")
                socket_shadow_harvester:SetHarvestRadius(TUNING.SKILLS.WX78.HARVEST_RADIUS)
                socket_shadow_harvester:SetTravelSpeed(TUNING.SKILLS.WX78.HARVEST_TRAVEL_SPEED)
                socket_shadow_harvester:SetMaxTendrils(TUNING.SKILLS.WX78.HARVEST_MAX_TENDRILS)
            end
            if socketquality >= SOCKETQUALITY.MEDIUM then
                WX78Common.SetHeartVeins(inst, true)
                if not inst.components.socket_shadow_heart then
                    local socket_shadow_heart = inst:AddComponent("socket_shadow_heart")
                    socket_shadow_heart:SetDebuffRadius(TUNING.SKILLS.WX78.SHADOWHEART_DEBUFF_RADIUS)
                    socket_shadow_heart:SetDamageMult(TUNING.SKILLS.WX78.SHADOWHEART_DAMAGEMULT)
                end
                if socketquality >= SOCKETQUALITY.HIGH then
                    WX78Common.SetMimicEyes(inst, true, doer)
                    if not inst.components.socket_shadow_mimicry then
                        inst:AddComponent("socket_shadow_mimicry")
                    end
                end
            end
        end
    elseif socketname == "socket_gestalttrapper" then
        inst:AddTag("possessable_chassis")
        WX78Common.SetTrapper(inst, true)
    end
end

local function OnRemoveSocketable(inst, item)
    local socketname = item.components.socketable:GetSocketName()
    if socketname == "socket_shadow" then
        local socketquality = inst.components.socketholder:GetHighestQualitySocketed("socket_shadow")
        if socketquality < SOCKETQUALITY.HIGH then
            inst:RemoveComponent("socket_shadow_mimicry")
            WX78Common.SetMimicEyes(inst, false)
            if socketquality < SOCKETQUALITY.MEDIUM then
                inst:RemoveComponent("socket_shadow_heart")
                WX78Common.SetHeartVeins(inst, false)
                if socketquality < SOCKETQUALITY.LOW then
                    inst:RemoveComponent("socket_shadow_harvester")
                end
            end
        end
    elseif socketname == "socket_gestalttrapper" then
        inst:RemoveTag("possessable_chassis")
        WX78Common.SetTrapper(inst, false)
    end
end

local function ActivateSocketsIn(inst, socketposition, socketname)
    if inst.components.socketholder then
        inst.components.socketholder:SetSocketPositionName(socketposition, socketname)
    end
end
local function DeactivateSocketsIn(inst, socketposition)
    if inst.components.socketholder then
        inst.components.socketholder:SetSocketPositionName(socketposition, 0)
    end
end

--------------------------------------------------------------------------
-- Mimic eyes
local function ShowMimicEyes(inst, doer)
    local animstateowner = inst.wx78_backupbody_inventory or inst
    animstateowner.AnimState:Hide("mimic1")
    animstateowner.AnimState:Hide("mimic2")
    animstateowner.AnimState:Hide("mimic3")
    local x, y, z = (doer or inst).Transform:GetWorldPosition()
    local prng = PRNG_Uniform(math.floor(x + 0.5) * math.floor(z + 0.5))
    local haseye = false
    if prng:Rand() < 0.5 then
        animstateowner.AnimState:Show("mimic1")
        haseye = true
    end
    if prng:Rand() < 0.5 then
        animstateowner.AnimState:Show("mimic2")
        haseye = true
    end
    if prng:Rand() < 0.5 then
        animstateowner.AnimState:Show("mimic3")
        haseye = true
    end
    if not haseye then
        local eyeindex = prng:RandInt(1, 3)
        animstateowner.AnimState:Show("mimic" .. tostring(eyeindex))
    end
end

local function HideMimicEyes(inst)
    local animstateowner = inst.wx78_backupbody_inventory or inst
    animstateowner.AnimState:Hide("mimic1")
    animstateowner.AnimState:Hide("mimic2")
    animstateowner.AnimState:Hide("mimic3")
end

local function OnMimicEyesUpdated(inst, data)
    local enabled, doer
    if data then
        enabled = data.enabled
        doer = data.doer
    end
    local animstateowner = inst.wx78_backupbody_inventory or inst
    if enabled then
        WX78Common.ShowMimicEyes(inst, doer)
    else
        WX78Common.HideMimicEyes(inst)
    end
end

local function SetMimicEyes(inst, enabled, doer)
    -- Always fire off this event to update the mimic eyes since there are three that could be on or off.
    -- The doer is needed to know what it should be before a teleport happens.
    inst._has_mimiceyes = enabled
    if not inst.isplayer then -- Player is handled in SGwilson.
        inst:PushEvent("mimiceyes_update", {enabled = inst._has_mimiceyes, doer = doer,})
    end
end

local function HasMimicEyes(inst)
    local wx = inst.wx78_backupbody_inventory or inst
    return wx._has_mimiceyes
end

-- HeartVeins

local function HideVeins(animstateowner)
    animstateowner.AnimState:Hide("shad_veins")
    animstateowner.AnimState:Hide("mimic1")
    animstateowner.AnimState:Hide("mimic2")
    animstateowner.AnimState:Hide("mimic3")
    animstateowner:RemoveEventCallback("animover", HideVeins)
end

local function OnHeartVeinsChanged(inst, enabled)
    local animstateowner = inst.wx78_backupbody_inventory or inst
    if enabled then
        animstateowner:RemoveEventCallback("animover", HideVeins)
        animstateowner.AnimState:Show("shad_veins")
        if WX78Common.HasMimicEyes(inst) then
            WX78Common.ShowMimicEyes(inst)
        end
        if animstateowner.AnimState:IsCurrentAnimation("wx_chassis_idle") then
            animstateowner.AnimState:PlayAnimation("wx_veins_pre", false)
            animstateowner.AnimState:PushAnimation("wx_chassis_idle", true)
        end
    else
        if not inst._backupbody_transferring and animstateowner.AnimState:IsCurrentAnimation("wx_chassis_idle") then
            animstateowner.AnimState:PlayAnimation("wx_veins_pst")
            animstateowner.AnimState:PushAnimation("wx_chassis_idle", true)
            animstateowner:ListenForEvent("animover", HideVeins)
        else
            animstateowner.AnimState:Hide("shad_veins")
            WX78Common.HideMimicEyes(inst)
        end
    end
end

local function SetHeartVeins(inst, enabled)
    if inst._has_heartveins ~= enabled then
        inst._has_heartveins = enabled
        if not inst.isplayer then -- Player is handled in SGwilson.
            inst:PushEvent("heartveins_changed", inst._has_heartveins)
        end
    end
end

local function HasHeartVeins(inst)
    local wx = inst.wx78_backupbody_inventory or inst
    return wx._has_heartveins
end

-- Trapper

local function HideTrapper(animstateowner)
    animstateowner.AnimState:Hide("trapper")
    animstateowner:RemoveEventCallback("animover", HideTrapper)
end

local function OnTrapperChanged(inst, enabled)
    local animstateowner = inst.wx78_backupbody_inventory or inst
    if enabled then
        animstateowner:RemoveEventCallback("animover", HideTrapper)
        animstateowner.AnimState:Show("trapper")
        if animstateowner.AnimState:IsCurrentAnimation("wx_chassis_idle") then
            animstateowner.AnimState:PlayAnimation("wx_trapper_pre", false)
            animstateowner.SoundEmitter:PlaySound("rifts5/generic_metal/ratchet")
            animstateowner.AnimState:PushAnimation("wx_chassis_idle", true)
        end
    else
        if not inst._backupbody_transferring and animstateowner.AnimState:IsCurrentAnimation("wx_chassis_idle") then
            animstateowner.AnimState:PlayAnimation("wx_trapper_pst")
            animstateowner.AnimState:PushAnimation("wx_chassis_idle", true)
            animstateowner:ListenForEvent("animover", HideTrapper)
        else
            animstateowner.AnimState:Hide("trapper")
        end
    end
end

local function SetTrapper(inst, enabled)
    if inst._has_trapper ~= enabled then
        inst._has_trapper = enabled
        if not inst.isplayer then -- Player is handled in SGwilson.
            inst:PushEvent("trapper_changed", inst._has_trapper)
        end
    end
end

local function HasTrapper(inst)
    local wx = inst.wx78_backupbody_inventory or inst
    return wx._has_trapper
end

-- For telling our possessed chassis what to do.
local function OnWxSpinActions(inst, actionsdata)
    local actiondata = actionsdata[1]
    -- Prioritize an attack first.
    for i, data in ipairs(actionsdata) do
        if data.action == ACTIONS.ATTACK then
            actiondata = data
            break
        end
    end

    if actiondata ~= nil then
        inst._lastspinaction = actiondata.action
        inst._lastspintarget = actiondata.target
        inst._lastspintime = GetTime()
    end
end

--------------------------------------------------------------------------

local function _CanSpinUsingItem_Client(item)
	return item ~= nil and item:HasAnyTag("CHOP_tool", "MINE_tool")
end

local function _CanSpinUsingItem_Server(item)
	return item	~= nil
		and item.components.tool ~= nil
		and (	item.components.tool:CanDoAction(ACTIONS.CHOP) or
				item.components.tool:CanDoAction(ACTIONS.MINE)	)
end

local function CanSpinUsingItem(item)
	WX78Common.CanSpinUsingItem = TheWorld.ismastersim and _CanSpinUsingItem_Server or _CanSpinUsingItem_Client
	return WX78Common.CanSpinUsingItem(item)
end

--------------------------------------------------------------------------
-- Always LAST!
local function Initialize_Common(inst)
    MakeInstSocketHolder_Client(inst, 1)
    local socketholder = inst.components.socketholder
    socketholder:SetShouldAllowSocketableFn_CLIENT(ShouldAllowSocketable_CLIENT)

    if inst.AnimState then
        inst.AnimState:Hide("shad_veins")
        inst.AnimState:Hide("mimic1")
        inst.AnimState:Hide("mimic2")
        inst.AnimState:Hide("mimic3")
        inst.AnimState:Hide("trapper")
        inst.AnimState:Hide("gestalt_die")
        inst.AnimState:Hide("gestalt_flee")
    end
end
local function Initialize_Master(inst)
    inst._temperature_modulelean = 0 -- Positive if "hot", negative if "cold"; see wx78_moduledefs
    
    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, false)
    inst.components.heater.heatfn = GetThermicTemperatureFn

    inst:AddComponent("preserver")
    inst.components.preserver:SetPerishRateMultiplier(ModuleBasedPreserverRateFn)

    inst:ListenForEvent("timerdone", OnTimerFinished)

    local socketholder = inst.components.socketholder
    socketholder:SetOnGetSocketableFn(OnGetSocketable)
    socketholder:SetOnRemoveSocketableFn(OnRemoveSocketable)

    if not inst.isplayer then -- Player is handled in SGwilson.
        inst:ListenForEvent("mimiceyes_update", OnMimicEyesUpdated)
        inst:ListenForEvent("heartveins_changed", OnHeartVeinsChanged)
        inst:ListenForEvent("trapper_changed", OnTrapperChanged)
    else
        inst:ListenForEvent("ms_wx_spinactions", OnWxSpinActions)
    end
end
WX78Common = {
    DEPENDENCIES = DEPENDENCIES,
    SetupUpgradeModuleOwnerInstanceFunctions = SetupUpgradeModuleOwnerInstanceFunctions,
    AddTemperatureModuleLeaning = AddTemperatureModuleLeaning,
    MakeItemSocketable = MakeItemSocketable,
    ActivateSocketsIn = ActivateSocketsIn,
    DeactivateSocketsIn = DeactivateSocketsIn,
    SetMimicEyes = SetMimicEyes,
    HasMimicEyes = HasMimicEyes,
    ShowMimicEyes = ShowMimicEyes,
    HideMimicEyes = HideMimicEyes,
    SetHeartVeins = SetHeartVeins,
    HasHeartVeins = HasHeartVeins,
    SetTrapper = SetTrapper,
    HasTrapper = HasTrapper,
	CanSpinUsingItem = CanSpinUsingItem,

    -- Initialization functions should be last in the file do not add your functions below this line unless it is for initialization.
	AddDizzyFx_Common = AddDizzyFx_Common,
	AddHeatSteamFx_Common = AddHeatSteamFx_Common,
    Initialize_Common = Initialize_Common,
    Initialize_Master = Initialize_Master,

    -- Exposed for Mods.
    WX78_UPGRADE_MODULE_ACTIONS = WX78_UPGRADE_MODULE_ACTIONS,
}

return WX78Common
