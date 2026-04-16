local function CreateIcon(target, icondata)
	local inst = CreateEntity()

	inst:AddTag("CLASSIFIED")
	--[[Non-networked entity]]
	--inst.entity:SetCanSleep(false) --commented out; follow parent sleep instead
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddMiniMapEntity()

	inst.MiniMapEntity:SetIcon((icondata.selectedicon or icondata.icon or target.prefab)..".png")
	inst.MiniMapEntity:SetPriority(icondata.selectedpriority or icondata.priority or 50)
	inst.MiniMapEntity:SetCanUseCache(false)
	inst.MiniMapEntity:SetDrawOverFogOfWar(true)
	inst.MiniMapEntity:SetIsProxy(false)

	return inst
end

local function OnActionDirty(inst)
	local player = ThePlayer
	if player and player.components.playercontroller then
		local target = inst.entity:GetParent()
		if target.bufferedmapaction_icondata then
			CreateIcon(target, target.bufferedmapaction_icondata).entity:SetParent(inst.entity)
		end
		player.components.playercontroller:PullUpMap(target, inst:GetAction())
	end
end

local function OnEntityReplicated(inst)
	local parent = inst.entity:GetParent()
	if parent then
		parent.bufferedmapaction = inst
		inst:ListenForEvent("cancelmaptarget", function(target, doer)
			--This RPC with the nil params will cancelmaptarget on server.
			SendRPCToServer(RPC.DoActionOnMap, nil, nil, nil, target)
		end, parent)
	end
end

local function OnRemoveEntity(inst)
	local parent = inst.entity:GetParent()
	if parent and parent.bufferedmapaction == inst then
		parent.bufferedmapaction = nil
	end
end

local function GetAction(inst)
	return ACTIONS_BY_ACTION_CODE[inst.action:value()]
end

local function IsDoer_Client(inst, doer)
	return doer ~= nil and doer == ThePlayer
end

local function IsDoer_Server(inst, doer)
	return doer ~= nil and doer == inst.doer
end

local function SetupMapAction(inst, action, target, doer)
	target.bufferedmapaction = inst
	inst.entity:SetParent(target.entity)
	inst.action:set(action.code)
	inst.Network:SetClassifiedTarget(doer)
	inst.doer = doer
	if doer.HUD then
		OnActionDirty(inst)
	end
	inst:ListenForEvent("cancelmaptarget", function(target, _doer)
		if _doer == doer then
			inst:Remove()
		end
	end, target)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	inst:AddTag("CLASSIFIED")

	inst.action = net_ushortint(inst.GUID, "bufferedmapaction.action", "actiondirty")

	inst.GetAction = GetAction
	inst.OnRemoveEntity = OnRemoveEntity

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("actiondirty", OnActionDirty)
		inst.OnEntityReplicated = OnEntityReplicated
		inst.IsDoer = IsDoer_Client

		return inst
	end

	inst.IsDoer = IsDoer_Server
	inst.SetupMapAction = SetupMapAction

	inst.persists = false

	return inst
end

return Prefab("bufferedmapaction", fn)
