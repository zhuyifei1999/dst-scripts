local REGISTERED_TARGET_TAGS

local function FindShockTargets(x, z, radius)
	if REGISTERED_TARGET_TAGS == nil then
		REGISTERED_TARGET_TAGS = TheSim:RegisterFindTags(
			{ "_combat" },
			{ "INLIMBO", "flight", "invisible", "notarget", "noattack", "ghost", "playerghost", "shadowthrall", "shadow", "shadowcreature", "shadowminion", "shadowchesspiece", "brightmare", "brightmareboss", "wagdrone", "wagboss" }
		)
	end
	return TheSim:FindEntities_Registered(x, 0, z, radius, REGISTERED_TARGET_TAGS)
end

--------------------------------------------------------------------------

local function SetLedEnabled(inst, enable)
	if enable then
		inst.AnimState:Show("LIGHT_ON")
	else
		inst.AnimState:Hide("LIGHT_ON")
	end
end

--------------------------------------------------------------------------

local function OnDespawn(inst)
	if inst:IsAsleep() then
		inst:Remove()
		return
	end
	inst:ListenForEvent("entitysleep", inst.Remove)
	inst.persists = false
	inst.components.locomotor:Stop()
	--stategraph will also handle the event
end

local function OnGotCommander(inst, data)
	inst.components.entitytracker:TrackEntity("robot", data.commander)
	inst.AnimState:OverrideSymbol("light_yellow_off", inst.prefab, "light_red_off")
	inst.AnimState:OverrideSymbol("light_yellow_on", inst.prefab, "light_red_on")
	inst:ListenForEvent("onremove", inst._onremovecommander, data.commander)
end

local function _DoClearCommander(inst, commander)
	inst.components.entitytracker:ForgetEntity("robot", commander)
	inst.AnimState:ClearOverrideSymbol("light_yellow_off")
	inst.AnimState:ClearOverrideSymbol("light_yellow_on")
end

local function OnLostCommander(inst, data)
	inst:RemoveEventCallback("onremove", inst._onremovecommander, data.commander)
	_DoClearCommander(inst, data.commander)
	inst:PushEvent("deactivate")

	--wagdrone_rolling specific
	inst.dest = nil
end

local function MakeHackable(inst)
	inst:AddComponent("entitytracker")

	inst._onremovecommander = function(commander) _DoClearCommander(inst, commander) end

	inst:ListenForEvent("gotcommander", OnGotCommander)
	inst:ListenForEvent("lostcommander", OnLostCommander)
	inst:ListenForEvent("despawn", OnDespawn)
end

local function HackableLoadPostPass(inst)--, ents, data)
	local robot = inst.components.entitytracker:GetEntity("robot")
	if robot then
		if robot.components.commander then
			robot.components.commander:AddSoldier(inst)
		else
			inst.components.entitytracker:ForgetEntity("robot")
		end
	end
end

--------------------------------------------------------------------------

local function teleport_override_fn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	if TheWorld.Map:IsPointInWagPunkArena(x, y, z) then
		return Vector3(x, y, z)
	end
end

local function PreventTeleportFromArena(inst)
	inst:AddComponent("teleportedoverride")
	inst.components.teleportedoverride:SetDestPositionFn(teleport_override_fn)
end

--------------------------------------------------------------------------

return
{
	FindShockTargets = FindShockTargets,
	SetLedEnabled = SetLedEnabled,
	MakeHackable = MakeHackable,
	HackableLoadPostPass = HackableLoadPostPass,
	PreventTeleportFromArena = PreventTeleportFromArena,
}
