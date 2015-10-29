local function IsPointInRange(player, x, z)
    local px, py, pz = player.Transform:GetWorldPosition()
    return distsq(x, z, px, pz) <= 4096
end

local RPC_HANDLERS =
{
    LeftClick = function(player, action, x, z, target, isreleased, controlmods, noforce, mod_name)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and action ~= nil and x ~= nil and z ~= nil then
            if IsPointInRange(player, x, z) then
                playercontroller:OnRemoteLeftClick(action, Vector3(x, 0, z), target, isreleased, controlmods, noforce, mod_name)
            else
                print("Remote left click out of range")
            end
        end
    end,

    RightClick = function(player, action, x, z, target, isreleased, controlmods, noforce, mod_name)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and action ~= nil and x ~= nil and z ~= nil then
            if IsPointInRange(player, x, z) then
                playercontroller:OnRemoteRightClick(action, Vector3(x, 0, z), target, isreleased, controlmods, noforce, mod_name)
            else
                print("Remote right click out of range")
            end
        end
    end,

    ActionButton = function(player, action, target, isreleased, noforce, mod_name)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil then
            playercontroller:OnRemoteActionButton(action, target, isreleased, noforce, mod_name)
        end
    end,

    AttackButton = function(player, target, forceattack, noforce)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil then
            playercontroller:OnRemoteAttackButton(target, forceattack, noforce)
        end
    end,

    InspectButton = function(player, target)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and target ~= nil then
            playercontroller:OnRemoteInspectButton(target)
        end
    end,

    ResurrectButton = function(player)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil then
            playercontroller:OnRemoteResurrectButton()
        end
    end,

    ControllerActionButton = function(player, action, target, isreleased, noforce, mod_name)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and action ~= nil and target ~= nil then
            playercontroller:OnRemoteControllerActionButton(action, target, isreleased, noforce, mod_name)
        end
    end,

    ControllerActionButtonDeploy = function(player, invobject, x, z, isreleased)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and invobject ~= nil and x ~= nil and z ~= nil then
            if IsPointInRange(player, x, z) then
                playercontroller:OnRemoteControllerActionButtonDeploy(invobject, Vector3(x, 0, z), isreleased)
            else
                print("Remote controller action button deploy out of range")
            end
        end
    end,

    ControllerAltActionButton = function(player, action, target, isreleased, noforce, mod_name)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and action ~= nil and target ~= nil then
            playercontroller:OnRemoteControllerAltActionButton(action, target, isreleased, noforce, mod_name)
        end
    end,

    ControllerAltActionButtonPoint = function(player, action, x, z, isreleased, noforce, mod_name)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and x ~= nil and z ~= nil then
            if IsPointInRange(player, x, z) then
                playercontroller:OnRemoteControllerAltActionButtonPoint(action, Vector3(x, 0, z), isreleased, noforce, mod_name)
            else
                print("Remote controller alt action button point out of range")
            end
        end
    end,

    ControllerAttackButton = function(player, target, isreleased, noforce)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil then
            playercontroller:OnRemoteControllerAttackButton(target, isreleased, noforce)
        end
    end,

    StopControl = function(player, control)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and control ~= nil then
            playercontroller:OnRemoteStopControl(control)
        end
    end,

    StopAllControls = function(player)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil then
            playercontroller:OnRemoteStopAllControls()
        end
    end,

    DirectWalking = function(player, x, z)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and x ~= nil and z ~= nil then
            playercontroller:OnRemoteDirectWalking(x, z)
        end
    end,

    DragWalking = function(player, x, z)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and x ~= nil and z ~= nil then
            playercontroller:OnRemoteDragWalking(x, z)
        end
    end,

    PredictWalking = function(player, x, z, isdirectwalking)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and x ~= nil and z ~= nil then
            playercontroller:OnRemotePredictWalking(x, z, isdirectwalking)
        end
    end,

    StopWalking = function(player)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil then
            playercontroller:OnRemoteStopWalking()
        end
    end,

    DoWidgetButtonAction = function(player, action, target, mod_name)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and playercontroller:IsEnabled() and not player.sg:HasStateTag("busy") then
            mod_name = mod_name or nil
            if mod_name ~= nil then
                action = action ~= nil and ACTION_MOD_IDS[mod_name] ~= nil and ACTION_MOD_IDS[mod_name][action] ~= nil and ACTIONS[ACTION_MOD_IDS[mod_name][action]] or nil
            else
                action = action ~= nil and ACTION_IDS[action] ~= nil and ACTIONS[ACTION_IDS[action]] or nil
            end
            if action ~= nil then
                local container = target ~= nil and target.components.container or nil
                if container == nil or container.opener == player then
                    BufferedAction(player, target, action):Do()
                end
            end
        end
    end,

    ReturnActiveItem = function(player)
        local inventory = player.components.inventory
        if inventory ~= nil then
            inventory:ReturnActiveItem()
        end
    end,

    PutOneOfActiveItemInSlot = function(player, slot, container)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil then
            if container == nil then
                inventory:PutOneOfActiveItemInSlot(slot)
            else
                container = container.components.container
                if container ~= nil and container:IsOpenedBy(player) then
                    container:PutOneOfActiveItemInSlot(slot)
                end
            end
        end
    end,

    PutAllOfActiveItemInSlot = function(player, slot, container)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil then
            if container == nil then
                inventory:PutAllOfActiveItemInSlot(slot)
            else
                container = container.components.container
                if container ~= nil and container:IsOpenedBy(player) then
                    container:PutAllOfActiveItemInSlot(slot)
                end
            end
        end
    end,

    TakeActiveItemFromHalfOfSlot = function(player, slot, container)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil then
            if container == nil then
                inventory:TakeActiveItemFromHalfOfSlot(slot)
            else
                container = container.components.container
                if container ~= nil and container:IsOpenedBy(player) then
                    container:TakeActiveItemFromHalfOfSlot(slot)
                end
            end
        end
    end,

    TakeActiveItemFromAllOfSlot = function(player, slot, container)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil then
            if container == nil then
                inventory:TakeActiveItemFromAllOfSlot(slot)
            else
                container = container.components.container
                if container ~= nil and container:IsOpenedBy(player) then
                    container:TakeActiveItemFromAllOfSlot(slot)
                end
            end
        end
    end,

    AddOneOfActiveItemToSlot = function(player, slot, container)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil then
            if container == nil then
                inventory:AddOneOfActiveItemToSlot(slot)
            else
                container = container.components.container
                if container ~= nil and container:IsOpenedBy(player) then
                    container:AddOneOfActiveItemToSlot(slot)
                end
            end
        end
    end,

    AddAllOfActiveItemToSlot = function(player, slot, container)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil then
            if container == nil then
                inventory:AddAllOfActiveItemToSlot(slot)
            else
                container = container.components.container
                if container ~= nil and container:IsOpenedBy(player) then
                    container:AddAllOfActiveItemToSlot(slot)
                end
            end
        end
    end,

    SwapActiveItemWithSlot = function(player, slot, container)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil then
            if container == nil then
                inventory:SwapActiveItemWithSlot(slot)
            else
                container = container.components.container
                if container ~= nil and container:IsOpenedBy(player) then
                    container:SwapActiveItemWithSlot(slot)
                end
            end
        end
    end,

    UseItemFromInvTile = function(player, action, item, controlmods, mod_name)
        local playercontroller = player.components.playercontroller
        local inventory = player.components.inventory
        if playercontroller ~= nil and inventory ~= nil and action ~= nil and item ~= nil then
            playercontroller:DecodeControlMods(controlmods)
            inventory:UseItemFromInvTile(item, action, mod_name)
            playercontroller:ClearControlMods()
        end
    end,

    ControllerUseItemOnItemFromInvTile = function(player, action, item, active_item, mod_name)
        local playercontroller = player.components.playercontroller
        local inventory = player.components.inventory
        if playercontroller ~= nil and inventory ~= nil and action ~= nil and item ~= nil and active_item ~= nil then
            playercontroller:ClearControlMods()
            inventory:ControllerUseItemOnItemFromInvTile(item, active_item, action, mod_name)
        end
    end,

    ControllerUseItemOnSelfFromInvTile = function(player, action, item, mod_name)
        local playercontroller = player.components.playercontroller
        local inventory = player.components.inventory
        if playercontroller ~= nil and inventory ~= nil and action ~= nil and item ~= nil then
            playercontroller:ClearControlMods()
            inventory:ControllerUseItemOnSelfFromInvTile(item, action, mod_name)
        end
    end,

    ControllerUseItemOnSceneFromInvTile = function(player, action, item, target, mod_name)
        local playercontroller = player.components.playercontroller
        local inventory = player.components.inventory
        if playercontroller ~= nil and inventory ~= nil and action ~= nil and item ~= nil then
            playercontroller:ClearControlMods()
            inventory:ControllerUseItemOnSceneFromInvTile(item, target, action, mod_name)
        end
    end,

    InspectItemFromInvTile = function(player, item)
        local inventory = player.components.inventory
        if inventory ~= nil and item ~= nil then
            inventory:InspectItemFromInvTile(item)
        end
    end,

    DropItemFromInvTile = function(player, item)
        local inventory = player.components.inventory
        if inventory ~= nil and item ~= nil then
            inventory:DropItemFromInvTile(item)
        end
    end,

    EquipActiveItem = function(player)
        local inventory = player.components.inventory
        if inventory ~= nil then
            inventory:EquipActiveItem()
        end
    end,

    EquipActionItem = function(player, item)
        local inventory = player.components.inventory
        if inventory ~= nil then
            inventory:EquipActionItem(item)
        end
    end,

    SwapEquipWithActiveItem = function(player)
        local inventory = player.components.inventory
        if inventory ~= nil then
            inventory:SwapEquipWithActiveItem()
        end
    end,

    TakeActiveItemFromEquipSlot = function(player, eslot)
        local inventory = player.components.inventory
        if inventory ~= nil and eslot ~= nil then
            inventory:TakeActiveItemFromEquipSlot(eslot)
        end
    end,

    MoveInvItemFromAllOfSlot = function(player, slot, destcontainer)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil and destcontainer ~= nil then
            inventory:MoveItemFromAllOfSlot(slot, destcontainer)
        end
    end,

    MoveInvItemFromHalfOfSlot = function(player, slot, destcontainer)
        local inventory = player.components.inventory
        if inventory ~= nil and slot ~= nil and destcontainer ~= nil then
            inventory:MoveItemFromHalfOfSlot(slot, destcontainer)
        end
    end,

    MoveItemFromAllOfSlot = function(player, slot, srccontainer, destcontainer)
        local container = srccontainer ~= nil and srccontainer.components.container or nil
        if container ~= nil and slot ~= nil then
            container:MoveItemFromAllOfSlot(slot, destcontainer or player)
        end
    end,

    MoveItemFromHalfOfSlot = function(player, slot, srccontainer, destcontainer)
        local container = srccontainer ~= nil and srccontainer.components.container or nil
        if container ~= nil and slot ~= nil then
            container:MoveItemFromHalfOfSlot(slot, destcontainer or player)
        end
    end,

    MakeRecipeFromMenu = function(player, recipe, skin_index)
        local builder = player.components.builder
        if builder ~= nil then
            for k, v in pairs(AllRecipes) do
                if v.rpc_id == recipe then
					local skin = nil
					if skin_index ~= -1 and PREFAB_SKINS[v.name] ~= nil then
						skin = PREFAB_SKINS[v.name][skin_index]
					end
                    builder:MakeRecipeFromMenu(v, skin)
                    return
                end
            end
        end
    end,

    MakeRecipeAtPoint = function(player, recipe, x, z, rot, skin_index)
        local builder = player.components.builder
        if builder ~= nil then
            for k, v in pairs(AllRecipes) do
                if v.rpc_id == recipe then
					local skin = nil
                    if skin_index ~= nil then
                       skin = PREFAB_SKINS[v.name][skin_index]
                    end
                    builder:MakeRecipeAtPoint(v, Vector3(x, 0, z), rot, skin)
                    return
                end
            end
        end
    end,

    BufferBuild = function(player, recipe)
        local builder = player.components.builder
        if builder ~= nil then
            for k, v in pairs(AllRecipes) do
                if v.rpc_id == recipe then
                    builder:BufferBuild(k)
                end
            end
        end
    end,

    WakeUp = function(player)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil and
            playercontroller:IsEnabled() and
            player.sleepingbag ~= nil and
            player.sg:HasStateTag("sleeping") and
            (player.sg:HasStateTag("bedroll") or player.sg:HasStateTag("tent")) then
            player:PushEvent("locomote")
        end
    end,

    SetWriteableText = function(player, target, text)
        local writeable = target ~= nil and target.components.writeable or nil
        if writeable ~= nil then
            writeable:Write(player, text)
        end
    end,

    ToggleController = function(player, isattached)
        local playercontroller = player.components.playercontroller
        if playercontroller ~= nil then
            playercontroller:ToggleController(isattached)
        end
    end,

    StartVote = function(player, command, parameters)
        TheWorld.net.components.voter:StartVote(player, command, parameters)
    end,

    Vote = function(player, option_index)
        TheWorld.net.components.voter:ReceivedVote(player, option_index)
    end,

    OpenGift = function(player)
        local giftreceiver = player.components.giftreceiver
        if giftreceiver ~= nil then
            giftreceiver:OpenNextGift()
        end
    end,

    DoneOpenGift = function(player, usewardrobe)
        local giftreceiver = player.components.giftreceiver
        if giftreceiver ~= nil then
            giftreceiver:OnStopOpenGift(usewardrobe)
        end
    end,

    CloseWardrobe = function(player, base_skin, body_skin, hand_skin, legs_skin)
        player:PushEvent("ms_closewardrobe", {
            base = base_skin,
            body = body_skin,
            hand = hand_skin,
            legs = legs_skin,
        })
    end,
}

RPC = {}

--Generate RPC codes from table of handlers
local i = 1
for k, v in pairs(RPC_HANDLERS) do
    RPC[k] = i
    i = i + 1
end
i = nil

--Switch handler keys from code name to code value
for k, v in pairs(RPC) do
    RPC_HANDLERS[v] = RPC_HANDLERS[k]
    RPC_HANDLERS[k] = nil
end

function SendRPCToServer(code, ...)
    assert(RPC_HANDLERS[code] ~= nil)
    TheNet:SendRPCToServer(code, ...)
end

local RPC_Queue = {}
local RPC_Timeline = {}

function HandleRPC(sender, tick, code, data)
    local fn = RPC_HANDLERS[code]
    if fn ~= nil then
        table.insert(RPC_Queue, { fn, sender, data, tick })
    else
        print("Invalid RPC code: "..tostring(code))
    end
end

function HandleRPCQueue()
    local i = 1
    while i <= #RPC_Queue do
        local fn, sender, data, tick = unpack(RPC_Queue[i])

        if not sender:IsValid() then
            table.remove(RPC_Queue, i)
        elseif RPC_Timeline[sender] == nil or RPC_Timeline[sender] == tick then
            table.remove(RPC_Queue, i)
            if TheNet:CallRPC(fn, sender, data) then
                RPC_Timeline[sender] = tick
            end
        else
            RPC_Timeline[sender] = 0
            i = i + 1
        end
    end
end

function TickRPCQueue()
    RPC_Timeline = {}
end

local function __index_lower(t, k)
    return rawget(t, string.lower(k))
end

local function __newindex_lower(t, k, v)
    rawset(t, string.lower(k), v)
end

local function setmetadata( tab )
    setmetatable(tab, { __index = __index_lower, __newindex = __newindex_lower })
end

MOD_RPC = {}
MOD_RPC_HANDLERS = {}
 
setmetadata(MOD_RPC)
setmetadata(MOD_RPC_HANDLERS)

function AddModRPCHandler( namespace, name, fn )
	if MOD_RPC[namespace] == nil then
		MOD_RPC[namespace] = {}
		MOD_RPC_HANDLERS[namespace] = {}

        setmetadata(MOD_RPC[namespace])
        setmetadata(MOD_RPC_HANDLERS[namespace])
	end
	

	table.insert(MOD_RPC_HANDLERS[namespace], fn)
    MOD_RPC[namespace][name] = { namespace = namespace, id = #MOD_RPC_HANDLERS[namespace] }

    setmetadata(MOD_RPC[namespace][name])
	
	setmetadata(MOD_RPC[namespace][name])
end

function SendModRPCToServer(id_table, ...)
    assert(id_table.namespace ~= nil and MOD_RPC_HANDLERS[id_table.namespace] ~= nil and MOD_RPC_HANDLERS[id_table.namespace][id_table.id] ~= nil)
    TheNet:SendModRPCToServer(id_table.namespace, id_table.id, ...)
end

function HandleModRPC(sender, tick, namespace, code, data)
	if MOD_RPC_HANDLERS[namespace] ~= nil then
		local fn = MOD_RPC_HANDLERS[namespace][code]
		if fn ~= nil then
			table.insert(RPC_Queue, { fn, sender, data, tick })
		else
			print("Invalid RPC code: ", namespace, code)
		end
	else
		print("Invalid RPC namespace: ", namespace, code)
	end
end

function GetModRPCHandler( namespace, name )
	return MOD_RPC_HANDLERS[namespace][MOD_RPC[namespace][name].id]
end
