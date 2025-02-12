--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local WobyCommon = require("prefabs/wobycommon")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local TIMEOUT = 2

local SKILL_TO_PROP =
{
	["walter_woby_itemfetcher"] = "pickup",
	["walter_woby_foraging"] = "foraging",
	["walter_woby_taskaid"] = "working",
	["walter_woby_sprint"] = "sprinting",
	["walter_woby_shadow"] = "shadowdash",
}

local PROP_TO_SKILL = {}
for k, v in pairs(SKILL_TO_PROP) do
	PROP_TO_SKILL[v] = k
end

--------------------------------------------------------------------------
--Common helpers
--------------------------------------------------------------------------

local function HasSkillFor(inst, prop)
	local skill = PROP_TO_SKILL[prop]
	return skill == nil
		or (inst._parent ~= nil and
			inst._parent.components.skilltreeupdater ~= nil and
			inst._parent.components.skilltreeupdater:IsActivated(skill))
end

local function CancelTurboSprint(inst)
	if inst._parent and inst._parent.sg then
		inst._parent.sg.mem.turbowoby = nil
	end
end

--------------------------------------------------------------------------
--Server interface
--------------------------------------------------------------------------

local function SetDirty(netvar, val)
	--Forces a netvar to be dirty regardless of value
	netvar:set_local(val)
	netvar:set(val)
end

local function IsBusy_Server(inst)
	return inst._task ~= nil
		or inst._parent == nil
		or inst._parent._PostActivateHandshakeState_Server ~= POSTACTIVATEHANDSHAKE.READY
end

local function OnActivateSkill(inst, skill)
	local prop = SKILL_TO_PROP[skill]
	if prop then
		inst[prop]:set(true)
	end
end

local function OnDeactivateSkill(inst, skill)
	local prop = SKILL_TO_PROP[skill]
	if prop then
		inst[prop]:set(false)
	end
end

local function RefreshAttunedSkills(inst, player)
	assert(player == inst._parent)
	local skilltreeupdater = player and player.components.skilltreeupdater or nil
	for k, v in pairs(SKILL_TO_PROP) do
		inst[v]:set(skilltreeupdater ~= nil and skilltreeupdater:IsActivated(k))
	end
end

local function InitializePetInst(inst, pet)
	assert(pet and inst._pet == nil)
	inst._pet = pet
	inst.woby:set(pet)
	inst:ListenForEvent("onremove", inst._onremovepet, pet)
	--Already has parent when transfering to another prefab, ie. pets that switch prefabs when transforming
	if inst._parent == nil then
		inst.entity:SetParent(pet.entity)
		inst.Network:SetClassifiedTarget(inst)
	end
end

local function OnRemovePet(inst, pet)
	assert(pet == inst._pet)
	local player = inst._parent
	if player then
		assert(player.woby_commands_classified == inst)
		inst:RemoveEventCallback("onremove", inst._onremoveplayer, player)
		inst:RemoveEventCallback("onactivateskill_server", inst._onactivateskill, player)
		inst:RemoveEventCallback("ondeactivateskill_server", inst._ondeactivateskill, player)
		player.woby_commands_classified = nil
		inst._parent = nil
		inst:Remove()
		if player:IsValid() then
			--player:PushEvent("show_pet_hunger", false)
		end
	end
end

local function AttachClassifiedToPetOwner(inst, player)
	assert(inst._pet)
	assert(inst._parent == nil)
	assert(player.woby_commands_classified == nil)
	inst._parent = player
	player.woby_commands_classified = inst
	inst.entity:SetParent(player.entity)
	inst.Network:SetClassifiedTarget(player)
	inst:ListenForEvent("onremove", inst._onremoveplayer, player)
	inst:ListenForEvent("onactivateskill_server", inst._onactivateskill, player)
	inst:ListenForEvent("ondeactivateskill_server", inst._ondeactivateskill, player)
	if player._PostActivateHandshakeState_Server == POSTACTIVATEHANDSHAKE.READY then
		RefreshAttunedSkills(inst, player)
	else
		inst:ListenForEvent("ms_skilltreeinitialized", inst._onskilltreeinitialized, player)
	end
end

--This is for transfering to another prefab, ie. pets that switch prefabs when transforming
local function DetachClassifiedFromPet(inst, pet)
	assert(pet and pet == inst._pet)
	inst._pet = nil
	inst.woby:set(nil)
	inst:RemoveEventCallback("onremove", inst._onremovepet, pet)
	if inst._parent == nil then
		inst.entity:SetParent(nil)
	end
end

local function OnRemovePlayer(inst, player)
	if inst._parent == nil then
		--Already cleared, probably got here after OnRemovePet
		assert(not inst:IsValid())
		return
	end
	assert(player == inst._parent)
	assert(player.woby_commands_classified == inst)
	player.woby_commands_classified = nil
	inst._parent = nil
	inst.entity:SetParent(inst._pet.entity)
	inst.Network:SetClassifiedTarget(inst)
	RefreshAttunedSkills(inst, nil)
end

local function DoAction_Server(inst, action)
	if inst._parent and inst._parent.components.playercontroller then
		local buffaction = BufferedAction(inst._parent, inst._pet, action)
		inst._parent.components.playercontroller:DoAction(buffaction)
		return true
	end
	return false
end

local function ToggleSkillCommand_Server(inst, name)
	if HasSkillFor(inst, name) then
		inst[name]:set(not inst[name]:value())
		return true
	end
	return false
end

local CmdFns_Server =
{
	[WobyCommon.COMMANDS.PET] =			function(inst) return DoAction_Server(inst, ACTIONS.PET) end,
	[WobyCommon.COMMANDS.MOUNT] =		function(inst) return DoAction_Server(inst, ACTIONS.MOUNT) end,
	[WobyCommon.COMMANDS.SHRINK] = function(inst)
		if inst._pet.TriggerTransformation then
			inst._pet:TriggerTransformation()
			return true
		end
		return false
	end,
	[WobyCommon.COMMANDS.SIT] = function(inst)
		if ToggleSkillCommand_Server(inst, "sit") then
			if inst.sit:value() then
				if inst._parent then
					inst._parent:PushEvent("tellwobysit", inst._pet)
				end
			else
				if inst._parent then
					inst._parent:PushEvent("tellwobyfollow", inst._pet)
				end
				if inst._pet.sg and inst._pet.sg:HasStateTag("sitting") then
					inst._pet.sg.currentstate:HandleEvent(inst._pet.sg, "stop_sitting")
				end
			end
			return true
		end
		return false
	end,
	[WobyCommon.COMMANDS.PICKUP] =		function(inst) return ToggleSkillCommand_Server(inst, "pickup") end,
	[WobyCommon.COMMANDS.FORAGING] =	function(inst) return ToggleSkillCommand_Server(inst, "foraging") end,
	[WobyCommon.COMMANDS.WORKING] =		function(inst) return ToggleSkillCommand_Server(inst, "working") end,
	[WobyCommon.COMMANDS.SPRINTING] = function(inst)
		if ToggleSkillCommand_Server(inst, "sprinting") then
			if not inst.sprinting:value() then
				CancelTurboSprint(inst)
			end
			return true
		end
		return false
	end,
	[WobyCommon.COMMANDS.SHADOWDASH] =	function(inst) return ToggleSkillCommand_Server(inst, "shadowdash") end,
}

local function ExecuteCommand_Server(inst, cmd)
	local fn = CmdFns_Server[cmd]
	if fn then
		return fn(inst)
	end
	print("Unsupported Woby command:", cmd)
	return false
end

--------------------------------------------------------------------------
--Client interface
--------------------------------------------------------------------------

local function IsBusy_Client(inst)
	return inst._task ~= nil
		or inst._parent == nil
		or inst._parent._PostActivateHandshakeState_Client ~= POSTACTIVATEHANDSHAKE.READY
end

local function ResetPreview(inst)
	inst._task = nil
	for k, v in pairs(inst._preview) do
		inst._preview[k] = nil
	end
end

local function DoAction_Client(inst, action, cmd)
	if inst._parent and inst._parent.components.playercontroller and inst.woby:value() then
		local buffaction = BufferedAction(inst._parent, inst.woby:value(), action)
		if inst._parent.components.locomotor == nil then
			-- NOTES(JBK): Does not call locomotor component functions needed for pre_action_cb, manual call here.
			if buffaction.action.pre_action_cb then
				buffaction.action.pre_action_cb(buffaction)
			end
			SendRPCToServer(RPC.WobyCommand, cmd)
			return true
		elseif inst._parent.components.playercontroller:CanLocomote() then
			buffaction.preview_cb = function()
				SendRPCToServer(RPC.WobyCommand, cmd)
			end
			inst._parent.components.playercontroller:DoAction(buffaction)
			return true
		end
	end
	return false
end

local function ToggleSkillCommand_Client(inst, name, cmd)
	if HasSkillFor(inst, name) then
		inst._preview[name] = not inst[name]:value()
		inst._task = inst:DoStaticTaskInTime(TIMEOUT, ResetPreview)
		SendRPCToServer(RPC.WobyCommand, cmd)
		return true
	end
	return false
end

local CmdFns_Client =
{
	[WobyCommon.COMMANDS.PET] =			function(inst, cmd) return DoAction_Client(inst, ACTIONS.PET, cmd) end,
	[WobyCommon.COMMANDS.MOUNT] =		function(inst, cmd) return DoAction_Client(inst, ACTIONS.MOUNT, cmd) end,
	[WobyCommon.COMMANDS.SHRINK] = function(inst, cmd)
		SendRPCToServer(RPC.WobyCommand, cmd)
		return true
	end,
	[WobyCommon.COMMANDS.SIT] =			function(inst, cmd) return ToggleSkillCommand_Client(inst, "sit", cmd) end,
	[WobyCommon.COMMANDS.PICKUP] =		function(inst, cmd) return ToggleSkillCommand_Client(inst, "pickup", cmd) end,
	[WobyCommon.COMMANDS.FORAGING] =	function(inst, cmd) return ToggleSkillCommand_Client(inst, "foraging", cmd) end,
	[WobyCommon.COMMANDS.WORKING] =		function(inst, cmd) return ToggleSkillCommand_Client(inst, "working", cmd) end,
	[WobyCommon.COMMANDS.SPRINTING] =	function(inst, cmd)
		if ToggleSkillCommand_Client(inst, "sprinting", cmd) then
			if not inst:GetValue("sprinting") then
				CancelTurboSprint(inst)
			end
			return true
		end
		return false
	end,
	[WobyCommon.COMMANDS.SHADOWDASH] =	function(inst, cmd) return ToggleSkillCommand_Client(inst, "shadowdash", cmd) end,
}

local function ExecuteCommand_Client(inst, cmd)
	if IsBusy_Client(inst) then
		return false
	end
	local fn = CmdFns_Client[cmd]
	if fn then
		return fn(inst, cmd)
	end
	print("Unsupported Woby command:", cmd)
	return false
end

local function OnSprintingDirty(inst)
	ResetPreview(inst)
	if not inst:GetValue("sprinting")then
		CancelTurboSprint(inst)
	end
end

local function OnWobyDirty(inst)
	if inst._parent and inst.woby:value() then
		WobyCommon.SetupClientCommandWheelRefreshers(inst.woby:value(), inst._parent)
	end
end

local function OnEntityReplicated(inst)
	--NOTE: parent is the player; pet inst may not actually be in view of client
	inst._parent = inst.entity:GetParent()
	if inst._parent == nil then
		print("Unable to initialize classified data for Woby commands")
	else
		assert(inst._parent.woby_commands_classified == nil)
		inst._parent.woby_commands_classified = inst
	end
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

local function GetWoby(inst)
	return inst.woby:value()
end

local function GetValue(inst, name)
	local val = inst._preview[name]
	if val ~= nil then
		return val
	end
	return inst[name]:value()
end

local function ShouldSit(inst)			return GetValue(inst, "sit")			end
local function ShouldPickup(inst)		return GetValue(inst, "pickup")			end
local function ShouldForage(inst)		return GetValue(inst, "foraging")		end
local function ShouldWork(inst)			return GetValue(inst, "working")		end
local function ShouldSprint(inst)		return GetValue(inst, "sprinting")		end
local function ShouldShadowDash(inst)	return GetValue(inst, "shadowdash")		end

--------------------------------------------------------------------------

local function RegisterNetListeners(inst)
	inst._task = nil

	if not TheWorld.ismastersim then
		inst:ListenForEvent("isdirty", ResetPreview)
		inst:ListenForEvent("sprintingdirty", OnSprintingDirty)
		inst:ListenForEvent("wobydirty", OnWobyDirty)

		if inst.woby:value() then
			OnWobyDirty(inst)
		end
		if not inst.sprinting:value() then
			CancelTurboSprint(inst)
		end
	end
end

local function OnRemoveEntity(inst)
	if inst._parent and
		inst._parent.HUD and
		inst._parent.HUD:GetCurrentOpenSpellBook() and
		inst._parent.HUD:GetCurrentOpenSpellBook() == inst.woby:value()
	then
		inst._parent.HUD:CloseSpellWheel()
	end
end

--------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	if TheWorld.ismastersim then
		inst.entity:AddTransform() --So we can follow parent's sleep state
	end
	inst.entity:AddNetwork()
	inst.entity:Hide()
	inst:AddTag("CLASSIFIED")

	--Variables for tracking local preview state;
	--Whenever a server sync is received, all local dirty states are reverted
	inst._preview = {}

	inst.woby = net_entity(inst.GUID, "woby_commands.woby", "wobydirty")

	--NOTE: Don't change the name of these properties!
	--      Woby's command wheel uses them to call GetValue.
	inst.sit = net_bool(inst.GUID, "woby_commands.sit", "isdirty")
	inst.pickup = net_bool(inst.GUID, "woby_commands.pickup", "isdirty")
	inst.foraging = net_bool(inst.GUID, "woby_commands.foraging", "isdirty")
	inst.working = net_bool(inst.GUID, "woby_commands.working", "isdirty")
	inst.sprinting = net_bool(inst.GUID, "woby_commands.sprinting", "sprintingdirty") -- attn: special handler!
	inst.shadowdash = net_bool(inst.GUID, "woby_commands.shadowdash", "isdirty")

	--Delay net listeners until after initial values are deserialized
	inst._task = inst:DoStaticTaskInTime(0, RegisterNetListeners)

	inst.GetWoby = GetWoby
	inst.GetValue = GetValue
	--
	inst.ShouldSit = ShouldSit
	inst.ShouldPickup = ShouldPickup
	inst.ShouldForage = ShouldForage
	inst.ShouldWork = ShouldWork
	inst.ShouldSprint = ShouldSprint
	inst.ShouldShadowDash = ShouldShadowDash
	--
	inst.OnRemoveEntity = OnRemoveEntity

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		--Client interface
		inst.OnEntityReplicated = OnEntityReplicated
		inst.IsBusy = IsBusy_Client
		inst.ExecuteCommand = ExecuteCommand_Client

		return inst
	end

	--Server interface
	inst.InitializePetInst = InitializePetInst
	inst.AttachClassifiedToPetOwner = AttachClassifiedToPetOwner
	inst.DetachClassifiedFromPet = DetachClassifiedFromPet
	inst.IsBusy = IsBusy_Server
	inst.ExecuteCommand = ExecuteCommand_Server

	inst._onremovepet = function(pet) OnRemovePet(inst, pet) end
	inst._onremoveplayer = function(player) OnRemovePlayer(inst, player) end
	inst._onactivateskill = function(player, data) OnActivateSkill(inst, data and data.skill or nil) end
	inst._ondeactivateskill = function(player, data) OnDeactivateSkill(inst, data and data.skill or nil) end
	inst._onskilltreeinitialized = function(player)
		inst:RemoveEventCallback("ms_skilltreeinitialized", inst._onskilltreeinitialized, player)
		RefreshAttunedSkills(inst, player)
	end

	inst.persists = false

	return inst
end

return Prefab("woby_commands_classified", fn)
