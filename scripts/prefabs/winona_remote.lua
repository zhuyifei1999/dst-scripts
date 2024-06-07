require("components/deployhelper") -- TriggerDeployHelpers lives here

local assets =
{
	Asset("ANIM", "anim/winona_remote.zip"),
	Asset("ANIM", "anim/spell_icons_winona.zip"),
}

local prefabs =
{
	"reticuleaoecatapultvolley",
	"reticuleaoecatapultvolleyping",
	"reticuleaoecatapultwakeup",
	"reticuleaoecatapultwakeupping",
	"reticuleaoewinonaengineeringping",
	"reticuleaoehostiletarget_1d25",
	"winona_battery_sparks",
}

local function ShouldRepeatCast(inst, doer)
	return not inst:HasTag("usesdepleted")
end

local CATAPULT_TAGS = { "catapult", "engineering" }
local CATAPULT_NO_TAGS = { "burnt" }

local function ForEachCatapult(inst, pos, fn)
	local success = false

	--NOTE: FindEntities is <= max range test
	for i, v in ipairs(TheSim:FindEntities(pos.x, 0, pos.z, TUNING.WINONA_CATAPULT_MAX_RANGE, CATAPULT_TAGS, CATAPULT_NO_TAGS)) do
		if v.IsPowered == nil or v:IsPowered() then
			if fn(inst, pos, v) then
				success = true
			end
		end
	end
	return success
end

local function PingCatapult(inst, pos, catapult)
	local ping = SpawnPrefab("reticuleaoewinonaengineeringping")
	ping.Transform:SetPosition(catapult.Transform:GetWorldPosition())
	ping.Transform:SetRotation(catapult.Transform:GetRotation())

	--placer colours:
	--  -base colour 0x6e6045 via multcolour
	--  -validcolour (0.25, 0.75, 0.25) via addcolour
	--
	--normally, reticule:PingReticuleAt controls the colours
	--to manually match it:
	--  use multcolour to match the base+validclour
	--  addcolour is fixed (0.2, 0.2, 0.2) when triggering ping
	ping.AnimState:SetMultColour(math.min(1, 0x6e/255+0.25), math.min(1, 0x60/255+0.75), math.min(1, 0x45/255+0.25), 1)
	ping.AnimState:SetAddColour(0.2, 0.2, 0.2, 0)

	return true
end

--------------------------------------------------------------------------

local function TryVolley(inst, pos, catapult)
	local min_range = TUNING.WINONA_CATAPULT_MIN_RANGE
	if catapult:GetDistanceSqToPoint(pos) >= min_range * min_range then
		catapult:PushEvent("activewakeup")
		catapult:PushEvent("dovolley", { targetpos = pos })
		return true
	end
	return false
end

local function TryPingVolley(inst, pos, catapult)
	local min_range = TUNING.WINONA_CATAPULT_MIN_RANGE
	if catapult:GetDistanceSqToPoint(pos) >= min_range * min_range then
		return PingCatapult(inst, pos, catapult)
	end
	return false
end

local function VolleySpellFn(inst, doer, pos)
	if inst.components.fueled:IsEmpty() then
		return false, "NO_BATTERY"
	elseif ForEachCatapult(inst, pos, TryVolley) then
		inst.components.fueled:DoDelta(-TUNING.WINONA_REMOTE_COST)
		return true
	end
	return false, "NO_CATAPULTS"
end

local function VolleyUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
	reticule.Transform:SetPosition(pos:Get())
	if reticule.prefab == "reticuleaoecatapultvolleyping" then
		ForEachCatapult(inst, pos, TryPingVolley)
	else
		TriggerDeployHelpers(pos.x, 0, pos.z, 64, nil, reticule)
	end
end

--------------------------------------------------------------------------

local function TryElementalVolley(inst, pos, catapult)
	local min_range = TUNING.WINONA_CATAPULT_MIN_RANGE
	if catapult:GetDistanceSqToPoint(pos) >= min_range * min_range then
		local haselement = false
		if catapult.components.circuitnode then
			catapult.components.circuitnode:ForEachNode(function(inst, node)
				local elem = node:CheckElementalBattery()
				if elem == "horror" or elem == "brilliance" then
					haselement = true
				end
			end)
			if haselement then
				catapult:PushEvent("activewakeup")
				catapult:PushEvent("doelementalvolley", { targetpos = pos })
				return true
			end
		end
	end
	return false
end

local function ElementalVolleySpellFn(inst, doer, pos)
	if inst.components.fueled:IsEmpty() then
		return false, "NO_BATTERY"
	elseif ForEachCatapult(inst, pos, TryElementalVolley) then
		inst.components.fueled:DoDelta(-TUNING.WINONA_REMOTE_COST)
		return true
	end
	return false, "NO_CATAPULTS"
end

--------------------------------------------------------------------------

local function TryWakeUp(inst, pos, catapult)
	catapult:PushEvent("activewakeup")
	return true
end

local function WakeUpSpellFn(inst, doer, pos)
	if inst.components.fueled:IsEmpty() then
		return false, "NO_BATTERY"
	elseif ForEachCatapult(inst, pos, TryWakeUp) then
		inst.components.fueled:DoDelta(-TUNING.WINONA_REMOTE_COST)
		return true
	end
	return false, "NO_CATAPULTS"
end

local function WakeUpUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
	reticule.Transform:SetPosition(pos:Get())
	if reticule.prefab == "reticuleaoecatapultwakeupping" then
		ForEachCatapult(inst, pos, PingCatapult)
	else
		TriggerDeployHelpers(pos.x, 0, pos.z, 64, nil, reticule)
	end
end

--------------------------------------------------------------------------

local function TryBoost(inst, pos, catapult)
	catapult:PushEvent("activewakeup")
	catapult:PushEvent("catapultspeedboost")
	return true
end

local function BoostSpellFn(inst, doer, pos)
	if inst.components.fueled:IsEmpty() then
		return false, "NO_BATTERY"
	elseif ForEachCatapult(inst, pos, TryBoost) then
		inst.components.fueled:DoDelta(-TUNING.WINONA_REMOTE_COST)
		return true
	end
	return false, "NO_CATAPULTS"
end

--------------------------------------------------------------------------

local function ReticuleTargetAllowWaterFn()
	local player = ThePlayer
	local ground = TheWorld.Map
	local pos = Vector3()
	--Cast range is 30, leave room for error
	--15 is the aoe range
	for r = 10, 0, -.25 do
		pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
		if ground:IsPassableAtPoint(pos.x, 0, pos.z, true) and not ground:IsGroundTargetBlocked(pos) then
			return pos
		end
	end
	return pos
end

local function StartAOETargeting(inst)
	local playercontroller = ThePlayer.components.playercontroller
	if playercontroller ~= nil then
		playercontroller:StartAOETargetingUsing(inst)
	end
end

local ICON_SCALE = .6
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS + 2
local ELEMENTAL_VOLLEY_ICONS =
{
	shadow =
	{
		idle = { anim = "icon_target_shadow" },
		focus = { anim = "icon_target_shadow_focus" },
		down = { anim = "icon_target_shadow_pressed" },
		disabled = { anim = "icon_target_shadow_disabled" },
	},
	lunar =
	{
		idle = { anim = "icon_target_lunar" },
		focus = { anim = "icon_target_lunar_focus" },
		down = { anim = "icon_target_lunar_pressed" },
		disabled = { anim = "icon_target_lunar_disabled" },
	},
	hybrid =
	{
		idle = { anim = "icon_target_hybrid" },
		focus = { anim = "icon_target_hybrid_focus" },
		down = { anim = "icon_target_hybrid_pressed" },
		disabled = { anim = "icon_target_hybrid_disabled" },
	},
}

local function GetSkillElement(user)
	local shadow, lunar
	if user.components.skilltreeupdater then
		shadow = user.components.skilltreeupdater:IsActivated("winona_shadow_3")
		lunar = user.components.skilltreeupdater:IsActivated("winona_lunar_3")
	end
	return (shadow == lunar and "hybrid") --both or none
		or (shadow and "shadow")
		or (--[[lunar and]] "lunar")
end

local SPELLS =
{
	{
		label = STRINGS.ENGINEER_REMOTE.VOLLEY,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ENGINEER_REMOTE.VOLLEY)
			inst.components.aoetargeting:SetDeployRadius(0)
			inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
			inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoecatapultvolley"
			inst.components.aoetargeting.reticule.pingprefab = "reticuleaoecatapultvolleyping"
			inst.components.aoetargeting.reticule.updatepositionfn = VolleyUpdatePositionFn
			if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX("reticuleaoehostiletarget_1d25")
				inst.components.aoespell:SetSpellFn(VolleySpellFn)
				inst.components.spellbook:SetSpellFn(nil)
			end
		end,
		execute = StartAOETargeting,
		bank = "spell_icons_winona",
		build = "spell_icons_winona",
		anims =
		{
			idle = { anim = "icon_target" },
			focus = { anim = "icon_target_focus" },
			down = { anim = "icon_target_pressed" },
			disabled = { anim = "icon_target_disabled" },
		},
		widget_scale = ICON_SCALE,
		checkenabled = function(user)
			--client safe
			return user.components.skilltreeupdater
				and user.components.skilltreeupdater:IsActivated("winona_catapult_volley_1")
		end,
	},
	{
		label = STRINGS.ENGINEER_REMOTE.BOOST,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ENGINEER_REMOTE.BOOST)
			inst.components.aoetargeting:SetDeployRadius(0)
			inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
			inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoecatapultwakeup"
			inst.components.aoetargeting.reticule.pingprefab = "reticuleaoecatapultwakeupping"
			inst.components.aoetargeting.reticule.updatepositionfn = WakeUpUpdatePositionFn
			if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX(nil)
				inst.components.aoespell:SetSpellFn(BoostSpellFn)
				inst.components.spellbook:SetSpellFn(nil)
			end
		end,
		execute = StartAOETargeting,
		bank = "spell_icons_winona",
		build = "spell_icons_winona",
		anims =
		{
			idle = { anim = "icon_boost" },
			focus = { anim = "icon_boost_focus" },
			down = { anim = "icon_boost_pressed" },
			disabled = { anim = "icon_boost_disabled" },
		},
		widget_scale = ICON_SCALE,
		checkenabled = function(user)
			--client safe
			return user.components.skilltreeupdater
				and user.components.skilltreeupdater:IsActivated("winona_catapult_boost_1")
		end,
	},
	{
		label = STRINGS.ENGINEER_REMOTE.WAKEUP,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ENGINEER_REMOTE.WAKEUP)
			inst.components.aoetargeting:SetDeployRadius(0)
			inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
			inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoecatapultwakeup"
			inst.components.aoetargeting.reticule.pingprefab = "reticuleaoecatapultwakeupping"
			inst.components.aoetargeting.reticule.updatepositionfn = WakeUpUpdatePositionFn
			if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX(nil)
				inst.components.aoespell:SetSpellFn(WakeUpSpellFn)
				inst.components.spellbook:SetSpellFn(nil)
			end
		end,
		execute = StartAOETargeting,
		bank = "spell_icons_winona",
		build = "spell_icons_winona",
		anims =
		{
			idle = { anim = "icon_wake" },
			focus = { anim = "icon_wake_focus" },
			down = { anim = "icon_wake_pressed" },
			disabled = { anim = "icon_wake_disabled" },
		},
		widget_scale = ICON_SCALE,
	},
	{
		label = STRINGS.ENGINEER_REMOTE.ELEMENTAL_VOLLEY,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.ENGINEER_REMOTE.ELEMENTAL_VOLLEY)
			inst.components.aoetargeting:SetDeployRadius(0)
			inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
			inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoecatapultvolley"
			inst.components.aoetargeting.reticule.pingprefab = "reticuleaoecatapultvolleyping"
			inst.components.aoetargeting.reticule.updatepositionfn = VolleyUpdatePositionFn
			if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX("reticuleaoehostiletarget_1d25")
				inst.components.aoespell:SetSpellFn(ElementalVolleySpellFn)
				inst.components.spellbook:SetSpellFn(nil)
			end
		end,
		execute = StartAOETargeting,
		bank = "spell_icons_winona",
		build = "spell_icons_winona",
		anims =
		{
			idle = function(user) return ELEMENTAL_VOLLEY_ICONS[GetSkillElement(user)].idle end,
			focus = function(user) return ELEMENTAL_VOLLEY_ICONS[GetSkillElement(user)].focus end,
			down = function(user) return ELEMENTAL_VOLLEY_ICONS[GetSkillElement(user)].down end,
			disabled = function(user) return ELEMENTAL_VOLLEY_ICONS[GetSkillElement(user)].disabled end,
		},
		widget_scale = ICON_SCALE,
		checkenabled = function(user)
			--client safe
			return user.components.skilltreeupdater
				and (	user.components.skilltreeupdater:IsActivated("winona_shadow_3") or
						user.components.skilltreeupdater:IsActivated("winona_lunar_3")
					)
		end,
	},
}

--[[local function OnOpenSpellBook(inst)
	local inventoryitem = inst.replica.inventoryitem
	if inventoryitem ~= nil then
		inventoryitem:OverrideImage("waxwelljournal_open")
	end
end

local function OnCloseSpellBook(inst)
	local inventoryitem = inst.replica.inventoryitem
	if inventoryitem ~= nil then
		inventoryitem:OverrideImage(nil)
	end
end]]

--------------------------------------------------------------------------

local function OnUpdateChargingFuel(inst)
	if inst.components.fueled:IsFull() then
		inst.components.fueled:StopConsuming()
	end
end

local function SetCharging(inst, powered, duration)
	if not powered then
		if inst._powertask then
			inst._powertask:Cancel()
			inst._powertask = nil
			inst.components.fueled:StopConsuming()
			inst.components.fueled.rate = 0
			inst.components.fueled:SetUpdateFn(nil)
			inst.components.powerload:SetLoad(0)
			--RefreshLedStatus(inst)
		end
	else
		local waspowered = inst._powertask ~= nil
		local remaining = waspowered and GetTaskRemaining(inst._powertask) or 0
		if duration > remaining then
			if inst._powertask then
				inst._powertask:Cancel()
			end
			inst._powertask = inst:DoTaskInTime(duration, SetCharging, false)
			if not waspowered then
				inst.components.fueled.rate = TUNING.WINONA_REMOTE_RECHARGE_RATE * (inst._quickcharge and TUNING.SKILLS.WINONA.QUICKCHARGE_MULT or 1)
				inst.components.fueled:SetUpdateFn(OnUpdateChargingFuel)
				inst.components.fueled:StartConsuming()
				inst.components.powerload:SetLoad(TUNING.WINONA_REMOTE_POWER_LOAD_CHARGING)
				--RefreshLedStatus(inst)
			end
		end
	end
end

local function OnPutInInventory(inst, owner)
	if inst._inittask then
		inst._inittask:Cancel()
		inst._inittask = nil
	end
	inst._owner = owner
	inst._quickcharge = false
	inst.components.circuitnode:Disconnect()
	--RefreshLedStatus(inst)
end

local function OnDropped(inst)
	if inst._owner then
		if inst._owner.components.skilltreeupdater and
			inst._owner.components.skilltreeupdater:IsActivated("winona_gadget_recharge") and
			not (inst._owner.components.health and inst._owner.components.health:IsDead() or inst._owner:HasTag("playerghost"))
		then
			inst._quickcharge = true
		end
		inst._owner = nil
	end

	if inst.components.inventoryitem.is_landed then
		inst.components.circuitnode:ConnectTo("engineeringbattery")
	else
		inst.components.circuitnode:Disconnect()
	end
	--RefreshLedStatus(inst)
end

local function OnNoLongerLanded(inst)
	inst.components.circuitnode:Disconnect()
end

local function OnLanded(inst)
	if not (inst.components.circuitnode:IsEnabled() or inst.components.inventoryitem:IsHeld()) then
		inst.components.circuitnode:ConnectTo("engineeringbattery")
	end
end

local function OnSave(inst, data)
	data.power = inst._powertask and math.ceil(GetTaskRemaining(inst._powertask) * 1000) or nil

	--skilltree
	data.quickcharge = inst._quickcharge or nil
end

local function OnLoad(inst, data)--, newents)
	if inst._inittask then
		inst._inittask:Cancel()
		inst._inittask = nil
	end

	--skilltree
	inst._quickcharge = data and data.quickcharge or false

	if data and data.power then
		inst:AddBatteryPower(math.max(2 * FRAMES, data.power / 1000))
	else
		SetCharging(inst, false)
	end
	--Enable connections, but leave the initial connection to batteries' OnPostLoad
	inst.components.circuitnode:ConnectTo(nil)
end

local function OnInit(inst)
	inst._inittask = nil
	inst.components.circuitnode:ConnectTo("engineeringbattery")
end

--------------------------------------------------------------------------

local function GetStatus(inst)
	return (inst._powertask and "CHARGING")
		or (inst.components.circuitnode:IsConnected() and inst.components.fueled:IsFull() and "CHARGED")
		or (inst.components.fueled:IsEmpty() and "OFF")
		or nil
end

local function AddBatteryPower(inst, power)
	if inst.components.fueled:IsFull() then
		SetCharging(inst, false)
	else
		SetCharging(inst, true, power)
	end
end

local function OnUpdateSparks(inst)
	if inst._flash > 0 then
		local k = inst._flash * inst._flash
		inst.components.colouradder:PushColour("wiresparks", .3 * k, .3 * k, 0, 0)
		inst._flash = inst._flash - .15
	else
		inst.components.colouradder:PopColour("wiresparks")
		inst._flash = nil
		inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateSparks)
	end
end

local function DoWireSparks(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/together/spot_light/electricity", nil, .5)
	SpawnPrefab("winona_battery_sparks").entity:AddFollower():FollowSymbol(inst.GUID, "wire", 0, 0, 0)
	if inst.components.updatelooper then
		if inst._flash == nil then
			inst.components.updatelooper:AddOnUpdateFn(OnUpdateSparks)
		end
		inst._flash = 1
		OnUpdateSparks(inst)
	end
end

local function NotifyCircuitChanged(inst, node)
	node:PushEvent("engineeringcircuitchanged")
end

local function OnCircuitChanged(inst)
	--Notify other connected batteries
	inst.components.circuitnode:ForEachNode(NotifyCircuitChanged)
end

local function OnConnectCircuit(inst)--, node)
	if not inst._wired then
		inst._wired = true
		inst.AnimState:ClearOverrideSymbol("wire")
		if not POPULATING then
			DoWireSparks(inst)
		end
	end
	OnCircuitChanged(inst)
end

local function OnDisconnectCircuit(inst)--, node)
	if inst.components.circuitnode:IsConnected() then
		OnCircuitChanged(inst)
	elseif inst._wired then
		inst._wired = nil
		--This will remove mouseover as well (rather than just :Hide("wire"))
		inst.AnimState:OverrideSymbol("wire", "winona_remote", "dummy")
		DoWireSparks(inst)
		SetCharging(inst, false)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("winona_remote")
	inst.AnimState:SetBuild("winona_remote")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("remotecontrol")
	inst:AddTag("engineering")
	inst:AddTag("engineeringbatterypowered")

	MakeInventoryFloatable(inst, "small", 0.15, 0.9)

	inst:AddComponent("spellbook")
	inst.components.spellbook:SetRequiredTag("portableengineer")
	inst.components.spellbook:SetRadius(SPELLBOOK_RADIUS)
	inst.components.spellbook:SetFocusRadius(SPELLBOOK_FOCUS_RADIUS)
	inst.components.spellbook:SetItems(SPELLS)
	--inst.components.spellbook:SetOnOpenFn(OnOpenSpellBook)
	--inst.components.spellbook:SetOnCloseFn(OnCloseSpellBook)
	inst.components.spellbook.opensound = "dontstarve/common/together/book_maxwell/use"
	inst.components.spellbook.closesound = "dontstarve/common/together/book_maxwell/close"
	--inst.components.spellbook.executesound = "dontstarve/common/together/book_maxwell/close"

	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAllowWater(true)
	inst.components.aoetargeting:SetRange(TUNING.WINONA_REMOTE_RANGE)
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetAllowWaterFn
	inst.components.aoetargeting.reticule.validcolour = { 0x33/255, 0x66/255, 0xFF/255, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { 0.5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting.reticule.twinstickmode = 1
	inst.components.aoetargeting.reticule.twinstickrange = TUNING.WINONA_REMOTE_RANGE

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.swap_build = "winona_remote"

	inst:AddComponent("updatelooper")
	inst:AddComponent("colouradder")

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
	inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.MAGIC
	inst.components.fueled.rate = 0
	inst.components.fueled:InitializeFuelLevel(TUNING.WINONA_REMOTE_FUEL)

	inst:AddComponent("circuitnode")
	inst.components.circuitnode:SetRange(TUNING.WINONA_BATTERY_RANGE)
	inst.components.circuitnode:SetFootprint(0)
	inst.components.circuitnode:SetOnConnectFn(OnConnectCircuit)
	inst.components.circuitnode:SetOnDisconnectFn(OnDisconnectCircuit)
	inst.components.circuitnode.connectsacrossplatforms = false
	inst.components.circuitnode.rangeincludesfootprint = false

	inst:AddComponent("powerload")
	inst.components.powerload:SetLoad(0)

	inst:ListenForEvent("engineeringcircuitchanged", OnCircuitChanged)
	inst:ListenForEvent("on_no_longer_landed", OnNoLongerLanded)
	inst:ListenForEvent("on_landed", OnLanded)

	inst:AddComponent("aoespell")

	MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunch(inst)

	inst.AddBatteryPower = AddBatteryPower
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	--skilltree
	inst._quickcharge = false

	inst._wired = nil
	inst._inittask = inst:DoTaskInTime(0, OnInit)

	return inst
end

return Prefab("winona_remote", fn, assets, prefabs)