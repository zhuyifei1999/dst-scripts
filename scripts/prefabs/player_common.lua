local easing = require("easing")
local PlayerHud = require("screens/playerhud")

local USE_MOVEMENT_PREDICTION = true

local screen_fade_time = .4

local DEFAULT_PLAYER_COLOUR = { 1, 1, 1, 1 }

local function giveupstring(combat, target)
    return GetString(combat.inst, "COMBAT_QUIT", target ~= nil and target:HasTag("prey") and "prey" or nil)
end

local function battlecrystring(combat, target)
    return target ~= nil
        and target:IsValid()
        and GetString(combat.inst, "BATTLECRY", target:HasTag("prey") and "PREY" or target.prefab)
        or nil
end

local function GetStatus(inst, viewer)
    return (inst:HasTag("playerghost") and "GHOST")
        or (inst.hasRevivedPlayer and "REVIVER")
        or (inst.hasKilledPlayer and "MURDERER")
        or (inst.hasAttackedPlayer and "ATTACKER")
        or nil
end

local function GetDescription(inst, viewer)
    local modifier = GetStatus(inst, viewer) or "GENERIC"
    local charstrings = STRINGS.CHARACTERS[string.upper(viewer.prefab)] or STRINGS.CHARACTERS.GENERIC
    local playerdesc = charstrings.DESCRIBE.PLAYER or STRINGS.CHARACTERS.GENERIC.DESCRIBE.PLAYER
    return string.format(playerdesc[modifier], inst:GetDisplayName())
end

local function GetTemperature(inst)
    if inst.components.temperature ~= nil then
        return inst.components.temperature:GetCurrent()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currenttemperature
    else
        return TUNING.STARTING_TEMP
    end
end

local function IsFreezing(inst)
    if inst.components.temperature ~= nil then
        return inst.components.temperature:IsFreezing()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currenttemperature < 0
    else
        return false
    end
end

local function IsOverheating(inst)
    if inst.components.temperature ~= nil then
        return inst.components.temperature:IsOverheating()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.currenttemperature > TUNING.OVERHEAT_TEMP
    else
        return false
    end
end

local function GetMoisture(inst)
    if inst.components.moisture ~= nil then
        return inst.components.moisture:GetMoisture()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.moisture:value()
    else
        return 0
    end
end

local function GetMaxMoisture(inst)
    if inst.components.moisture ~= nil then
        return inst.components.moisture:GetMaxMoisture()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.maxmoisture:value()
    else
        return 100
    end
end

local function GetMoistureRateScale(inst)
    if inst.components.moisture ~= nil then
        return inst.components.moisture:GetRateScale()
    elseif inst.player_classified ~= nil then
        return inst.player_classified.moistureratescale:value()
    else
        return RATE_SCALE.NEUTRAL
    end
end

local function ShouldKnockout(inst)
    return DefaultKnockoutTest(inst) and not inst.sg:HasStateTag("yawn")
end

local function ShouldAcceptItem(inst, item)
    if inst:HasTag("playerghost") then
        return item.prefab == "reviver"
    else
        return item.components.inventoryitem ~= nil
    end
end

local function OnGetItem(inst, giver, item)
    if item ~= nil and item.prefab == "reviver" and inst:HasTag("playerghost") then
        inst.reviver = giver
        item:PushEvent("usereviver", { user = giver })
        giver.hasRevivedPlayer = true
        item:Remove()
        inst:PushEvent("respawnfromghost")

        --giver.components.health.numrevives = giver.components.health.numrevives + 1
        --giver.components.health:RecalculatePenalty(true)

        inst.components.health.numrevives = inst.components.health.numrevives + .5
        if inst.components.health.numrevives > 3 then
            inst.components.health.numrevives = 3
        end

        inst.components.health:RecalculatePenalty(true)
    end
end

local function DropItem(inst, target, item)
    inst.components.inventory:Unequip(EQUIPSLOTS.HANDS, true) 
    inst.components.inventory:DropItem(item)
    if item.Physics then
        local x, y, z = item:GetPosition():Get()
        y = .3
        item.Physics:Teleport(x,y,z)

        local hp = target:GetPosition()
        local pt = inst:GetPosition()
        local vel = (hp - pt):GetNormalized()     
        local speed = 3 + (math.random() * 2)
        local angle = -math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
        item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
    end
    inst.components.talker:Say(GetString(inst, "ANNOUNCE_TOOL_SLIP"))
end

local function DropWetTool(inst, data)
    --Tool slip.
    if inst.components.moisture:GetSegs() < 4 then
        return
    end

    local tool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool ~= nil and tool:GetIsWet() and math.random() < easing.inSine(TheWorld.state.wetness, 0, 0.15, inst.components.moisture:GetMaxMoisture()) then
        DropItem(inst, data.target, tool)
        --Lock out from picking up for a while?
    end
end

local function FrozenItems(item)
    return item:HasTag("frozen")
end

local function OnStartFireDamage(inst)
    local frozenitems = inst.components.inventory:FindItems(FrozenItems)
    for i, v in ipairs(frozenitems) do
        v:PushEvent("firemelt")
    end
end

local function OnStopFireDamage(inst)
    local frozenitems = inst.components.inventory:FindItems(FrozenItems)
    for i, v in ipairs(frozenitems) do
        v:PushEvent("stopfiremelt")
    end
end

--------------------------------------------------------------------------
--Audio events
--------------------------------------------------------------------------

local function OnContainerGotItem()
    TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
end

local function OnGotNewItem(inst, data)
    if data.slot ~= nil or data.eslot ~= nil then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
    end
end

local function OnEquip()
    TheFocalPoint.SoundEmitter:PlaySound("dontstarve/wilson/equip_item")
end

local function OnPickSomething(inst, data)
    if data.object ~= nil and data.object.components.pickable ~= nil and data.object.components.pickable.picksound ~= nil then
        --Others can hear this
        inst.SoundEmitter:PlaySound(data.object.components.pickable.picksound)
    end
end

local function OnDropItem(inst)
    --Others can hear this
    inst.SoundEmitter:PlaySound("dontstarve/common/dropGeneric")
end

--------------------------------------------------------------------------
--Action events
--------------------------------------------------------------------------

local function OnActionFailed(inst, data)
    if inst.components.talker ~= nil
        and (data.reason ~= nil or
            not data.action.autoequipped or
            inst.components.inventory.activeitem == nil) then
        --V2C: Added edge case to suppress talking when failure is just due to
        --     action equip failure when your inventory is full.
        --     Note that action equip fail is an indirect check by testing
        --     whether your active slot is now empty or not.
        --     This is just to simplify making it consistent on client side.
        inst.components.talker:Say(GetActionFailString(inst, data.action.action.id, data.reason))
    end
end

local function OnWontEatFood(inst, data)
    if inst.components.talker ~= nil then
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "YUCKY"))
    end
end

local function OnWork(inst, data)
    DropWetTool(inst, data)
end

--------------------------------------------------------------------------
--PVP events
--------------------------------------------------------------------------

local function OnAttackOther(inst, data)
    if data ~= nil and data.target ~= nil and data.target:HasTag("player") then
        inst.hasAttackedPlayer = true
    end
    if data.weapon then
        DropWetTool(inst, data)
    end
end

local function OnAreaAttackOther(inst, data)
    if data ~= nil and data.target ~= nil and data.target:HasTag("player") then
        inst.hasAttackedPlayer = true
    end
end

local function OnKilled(inst, data)
    if data ~= nil and data.victim ~= nil and data.victim:HasTag("player") then
        inst.hasKilledPlayer = true
        inst.hasRevivedPlayer = false
    end
end

--------------------------------------------------------------------------

local function RegisterActivePlayerEventListeners(inst)
    --HUD Audio events
    inst:ListenForEvent("containergotitem", OnContainerGotItem)
    inst:ListenForEvent("gotnewitem", OnGotNewItem)
    inst:ListenForEvent("equip", OnEquip)
end

local function UnregisterActivePlayerEventListeners(inst)
    --HUD Audio events
    inst:RemoveEventCallback("containergotitem", OnContainerGotItem)
    inst:RemoveEventCallback("gotnewitem", OnGotNewItem)
    inst:RemoveEventCallback("equip", OnEquip)
end

local function RegisterMasterEventListeners(inst)
    --Audio events
    inst:ListenForEvent("picksomething", OnPickSomething)
    inst:ListenForEvent("dropitem", OnDropItem)

    --Speech events
    inst:ListenForEvent("actionfailed", OnActionFailed)
    inst:ListenForEvent("wonteatfood", OnWontEatFood)
    inst:ListenForEvent("working", OnWork)

    --PVP events
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("onareaattackother", OnAreaAttackOther)
    inst:ListenForEvent("killed", OnKilled)
end

--------------------------------------------------------------------------
--Construction/Destruction helpers
--------------------------------------------------------------------------

local function AddActivePlayerComponents(inst)
    inst:AddComponent("playertargetindicator")
end

local function RemoveActivePlayerComponents(inst)
    inst:RemoveComponent("playertargetindicator")
end

local function ActivateHUD(inst)
    local hud = PlayerHud()
    TheFrontEnd:PushScreen(hud)
    TheCamera:SetOnUpdateFn(not TheWorld:HasTag("cave") and function(camera) hud:UpdateClouds(camera) end or nil)
    hud:SetMainCharacter(inst)
end

local function DeactivateHUD(inst)
    TheCamera:SetOnUpdateFn(nil)
    TheFrontEnd:PopScreen(inst.HUD)
    inst.HUD = nil
end

local function ActivatePlayer(inst)
    inst.activatetask = nil

    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    local minimap = TheWorld.minimap.MiniMap

    if inst == ThePlayer then
        minimap:EnablePlayerMinimapUpdate(not inst:HasTag("playerghost"))
        minimap:DrawForgottenFogOfWar(true)
        minimap:ClearRevealedAreas()
        minimap:CacheForgottenEntities(true)

        -- Reference local minimap reveal cache
        -- In the future this will come from the server
        TheNet:DeserializeLocalUserSessionMinimap()
    end

    inst:PushEvent("playeractivated")
    TheWorld:PushEvent("playeractivated", inst)
end

local function DeactivatePlayer(inst)
    if inst.activatetask ~= nil then
        inst.activatetask:Cancel()
        inst.activatetask = nil
        return
    end

    if inst == ThePlayer then
        TheWorld.minimap.MiniMap:EnablePlayerMinimapUpdate(false)
    end

    inst:PushEvent("playerdeactivated")
    TheWorld:PushEvent("playerdeactivated", inst)
end

--------------------------------------------------------------------------

local function OnPlayerJoined(inst)
    inst.jointask = nil

    -- "playerentered" is available on both server and client.
    -- - On clients, this is pushed whenever a player entity is added
    --   locally because it has come into range of your network view.
    -- - On servers, this message is identical to "ms_playerjoined", since
    --   players are always in network view range once they are connected.
    TheWorld:PushEvent("playerentered", inst)
    if TheWorld.ismastersim then
        TheWorld:PushEvent("ms_playerjoined", inst)
        TheNet:Announce(inst:GetDisplayName().." "..STRINGS.UI.NOTIFICATION.JOINEDGAME, inst.entity, true, "join_game")
    end
end

local function ConfigurePlayerLocomotor(inst)
    inst.components.locomotor:SetSlowMultiplier(0.6)
    inst.components.locomotor.pathcaps = { player = true, ignorecreep = true } -- 'player' cap not actually used, just useful for testing
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED -- 4
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED -- 6
    inst.components.locomotor.fasteronroad = true
    inst.components.locomotor:SetTriggersCreep(not inst:HasTag("spiderwhisperer"))
end

local function ConfigureGhostLocomotor(inst)
    inst.components.locomotor:SetSlowMultiplier(0.6)
    inst.components.locomotor.pathcaps = { player = true, ignorecreep = true } -- 'player' cap not actually used, just useful for testing
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED -- 4 is base
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED -- 6 is base
    inst.components.locomotor.fasteronroad = false
    inst.components.locomotor:SetTriggersCreep(false)
end

local function OnCancelMovementPrediction(inst)
    inst.components.locomotor:Clear()
    inst:ClearBufferedAction()
    inst.sg:GoToState("idle", "cancel")
end

local function EnableMovementPrediction(inst, enable)
    if USE_MOVEMENT_PREDICTION and not TheWorld.ismastersim then
        if enable then
            if inst.components.locomotor == nil then
                local isghost =
                    (inst.player_classified ~= nil and inst.player_classified.isghostmode:value()) or
                    (inst.player_classified == nil and inst:HasTag("playerghost"))

                inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
                if isghost then
                    ConfigureGhostLocomotor(inst)
                else
                    ConfigurePlayerLocomotor(inst)
                end

                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller.locomotor = inst.components.locomotor
                end

                inst:SetStateGraph(isghost and "SGwilsonghost_client" or "SGwilson_client")
                inst:ListenForEvent("cancelmovementprediction", OnCancelMovementPrediction)

                inst.entity:EnableMovementPrediction(true)
                print("Movement prediction enabled")
            end
        elseif inst.components.locomotor ~= nil then
            inst:RemoveEventCallback("cancelmovementprediction", OnCancelMovementPrediction)
            inst.entity:EnableMovementPrediction(false)
            inst:ClearBufferedAction()
            inst:ClearStateGraph()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller.locomotor = nil
            end
            inst:RemoveComponent("locomotor")
            print("Movement prediction disabled")
        end
    end
end

local function SetGhostMode(inst, isghost)
    if not inst.ghostenabled then
        return
    end
    TheWorld.minimap.MiniMap:EnablePlayerMinimapUpdate(not isghost)
    TheWorld:PushEvent("enabledynamicmusic", not isghost)
    inst.HUD.controls.status:SetGhostMode(isghost)
    if isghost then
        TheMixer:PushMix("death")
    else
        TheMixer:PopMix("death")
    end
    if not TheWorld.ismastersim and USE_MOVEMENT_PREDICTION then
        if inst.components.locomotor ~= nil then
            inst:PushEvent("cancelmovementprediction")
            if isghost then
                ConfigureGhostLocomotor(inst)
            else
                ConfigurePlayerLocomotor(inst)
            end
        end
        if inst.sg ~= nil then
            inst:SetStateGraph(isghost and "SGwilsonghost_client" or "SGwilson_client")
        end
    end
end

--Action filter must be a valid check on both server and client
local function CheckGhostActionFilter(inst, action)
    if action.ghost_exclusive then
        return inst:HasTag("playerghost")
    end
    return action.ghost_valid or not inst:HasTag("playerghost")
end

local function OnSetOwner(inst)
    inst.name = inst.Network:GetClientName()
    inst.userid = inst.Network:GetUserID()
    inst.playercolour = inst.Network:GetPlayerColour()
    if TheWorld.ismastersim then
        TheNet:SetIsClientInWorld(inst.userid, true)
        inst.player_classified.Network:SetClassifiedTarget(inst)
        inst.components.inspectable.getspecialdescription = GetDescription
    end

    if inst ~= nil and (inst == ThePlayer or TheWorld.ismastersim) then
        if inst.components.playercontroller == nil then
            EnableMovementPrediction(inst, true)
            inst:AddComponent("playeractionpicker")
            inst:AddComponent("playercontroller")
            inst.components.playeractionpicker.actionfilter = CheckGhostActionFilter
        end
    elseif inst.components.playercontroller ~= nil then
        inst:RemoveComponent("playeractionpicker")
        inst:RemoveComponent("playercontroller")
        DisableMovementPrediction(inst)
    end

    if inst == ThePlayer then
        if inst.HUD == nil then
            ActivateHUD(inst)
            AddActivePlayerComponents(inst)
            RegisterActivePlayerEventListeners(inst)
            inst.activatetask = inst:DoTaskInTime(0, ActivatePlayer)
        end
    elseif inst.HUD ~= nil then
        UnregisterActivePlayerEventListeners(inst)
        RemoveActivePlayerComponents(inst)
        DeactivateHUD(inst)
        DeactivatePlayer(inst)
    end
end

local function AttachClassified(inst, classified)
    inst.player_classified = classified
    inst.ondetachclassified = function() inst:DetachClassified() end
    inst:ListenForEvent("onremove", inst.ondetachclassified, classified)
end

local function DetachClassified(inst)
    inst.player_classified = nil
    inst.ondetachclassified = nil
end

local function OnRemoveEntity(inst)
    if inst.jointask ~= nil then
        inst.jointask:Cancel()
    end

    if inst.player_classified ~= nil then
        if TheWorld.ismastersim then
            inst.player_classified:Remove()
            inst.player_classified = nil
            if inst.ghostenabled then
                inst.Network:RemoveUserFlag(USERFLAGS.IS_GHOST)
            end
            inst.Network:RemoveUserFlag(USERFLAGS.CHARACTER_STATE_1)
            inst.Network:RemoveUserFlag(USERFLAGS.CHARACTER_STATE_2)
        else
            inst.player_classified._parent = nil
            inst:RemoveEventCallback("onremove", inst.ondetachclassified, inst.player_classified)
            inst:DetachClassified()
        end
    end

    RemoveByValue(AllPlayers, inst)

    -- "playerexited" is available on both server and client.
    -- - On clients, this is pushed whenever a player entity is removed
    --   locally because it has gone out of range of your network view.
    -- - On servers, this message is identical to "ms_playerleft", since
    --   players are always in network view range until they disconnect.
    TheWorld:PushEvent("playerexited", inst)
    if TheWorld.ismastersim then
        TheWorld:PushEvent("ms_playerleft", inst)
        TheNet:SetIsClientInWorld(inst.userid, false)
    end

    if inst.HUD ~= nil then
        DeactivateHUD(inst)
    end

    if inst == ThePlayer then
        UnregisterActivePlayerEventListeners(inst)
        RemoveActivePlayerComponents(inst)
        DeactivatePlayer(inst)
    end
end

--------------------------------------------------------------------------
--Death/Ghost stuff
--------------------------------------------------------------------------

local function RemoveDeadPlayer(inst, spawnskeleton)
    if spawnskeleton then
        local x, y, z = inst.Transform:GetWorldPosition()

        -- Spawn a skeleton
        local skel = SpawnPrefab("skeleton_player")
        if skel ~= nil then
            skel.Transform:SetPosition(x, y, z)
            -- Set the description
            skel:SetSkeletonDescription(inst.prefab, inst:GetDisplayName(), inst.deathcause, inst.deathpkname)
        end

        -- Death FX
        SpawnPrefab("die_fx").Transform:SetPosition(x, y, z)
    end
    inst:OnDespawn()
    DeleteUserSession(inst)
    inst:Remove()
end

local function FadeOutDeadPlayer(inst, spawnskeleton)
    inst:ScreenFade(false, screen_fade_time, true)
    inst:DoTaskInTime(screen_fade_time * 1.25, RemoveDeadPlayer, spawnskeleton)
end

--Player has completed death sequence
local function OnPlayerDied(inst, data)
    inst:DoTaskInTime(3, FadeOutDeadPlayer, data ~= nil and data.skeleton)
end

--Player has initiated death sequence
local function OnPlayerDeath(inst, data)
    if inst:HasTag("playerghost") then
        --ghosts should not be able to die atm
        return
    end

    inst:ClearBufferedAction()

    inst.components.age:PauseAging()
    inst.components.inventory:Close()
    inst:PushEvent("ms_closepopups")

    inst.deathcause = data ~= nil and data.cause or "unknown"
    inst.deathpkname =
        data ~= nil and
        data.afflicter ~= nil and
        data.afflicter:HasTag("player") and
        data.afflicter:GetDisplayName() or nil

    if not inst.ghostenabled then
        if inst.deathcause ~= "file_load" then
            inst.player_classified:AddMorgueRecord()

            local announcement_string = GetNewDeathAnnouncementString(inst, inst.deathcause, inst.deathpkname)
            if announcement_string ~= "" then
               TheNet:Announce(announcement_string, inst.entity, false, "death")
            end
        end
        --Early delete in case client disconnects before removal timeout
        DeleteUserSession(inst)
    end
end

local function DoActualRez(inst, source)
    if inst == ThePlayer then
        TheWorld.minimap.MiniMap:EnablePlayerMinimapUpdate(true)
    end

    local x, y, z
    if source ~= nil then
        x, y, z = source.Transform:GetWorldPosition()
    else
        x, y, z = inst.Transform:GetWorldPosition()
    end

    local diefx = SpawnPrefab("die_fx")
    if diefx and x and y and z then
        diefx.Transform:SetPosition(x, y, z)
    end

    inst.AnimState:Hide("HAT_HAIR")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")

    inst:Show()

    inst:SetStateGraph("SGwilson")

    inst.Physics:Teleport(x, y, z)

    inst.components.inventory:Open()
    inst.player_classified:SetGhostMode(false)

    -- Resurrector is involved
    if source ~= nil then
        inst.DynamicShadow:Enable(true)
        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild(inst.skin_name or inst.prefab)
        inst.AnimState:ClearBloomEffectHandle()
        inst.AnimState:SetLightOverride(0)
        inst.AnimState:Hide("HAT")
        inst.AnimState:Hide("HatFX")

        source:PushEvent("activateresurrection", inst)

        if source.prefab == "amulet" then
            inst.components.inventory:Equip(source)
            inst.sg:GoToState("amulet_rebirth")
        elseif source.prefab == "resurrectionstone" then
            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            inst.sg:GoToState("wakeup")
        elseif source.prefab == "resurrectionstatue" then
            inst.sg:GoToState("rebirth")
        elseif source.prefab == "multiplayer_portal" then
            inst.components.health.numrevives = inst.components.health.numrevives + 1
            if inst.components.health.numrevives > 3 then
                inst.components.health.numrevives = 3
            end
            inst.components.health:RecalculatePenalty(true)
            source:PushEvent("rez_player")
            inst.sg:GoToState("portal_rez")
        end
    else -- Telltale Heart
        inst.sg:GoToState("reviver_rebirth")
    end

    --Default to electrocute light values
    inst.Light:SetIntensity(.8)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.65)
    inst.Light:SetColour(255 / 255, 255 / 255, 236 / 255)
    inst.Light:Enable(false)

    MakeCharacterPhysics(inst, 75, .5)

    inst.components.hunger:Resume()
    inst.components.temperature:SetTemp() --nil param will resume temp

    MakeMediumBurnableCharacter(inst, "torso")
    inst.components.burnable:SetBurnTime(TUNING.PLAYER_BURN_TIME)
    MakeHugeFreezableCharacter(inst, "torso")
    inst.components.freezable:SetDefaultWearOffTime(TUNING.PLAYER_FREEZE_WEAR_OFF_TIME)

    inst:AddComponent("grogginess")
    inst.components.grogginess:SetResistance(3)
    inst.components.grogginess:SetKnockOutTest(ShouldKnockout)

    inst.components.moisture:ForceDry(false)

    inst.components.sheltered:Start()

    --we disabled health penalty for PAX. I think I prefer it. If we like it, do it properly.
    inst.components.health:RecalculatePenalty(true)

    --don't ignore sanity any more
    inst.components.sanity.ignore = false

    inst:RemoveTag("playerghost")
    inst.Network:RemoveUserFlag(USERFLAGS.IS_GHOST)

    inst.components.age:ResumeAging()

    ConfigurePlayerLocomotor(inst)

    if inst.rezsource ~= nil then
        local announcement_string = GetNewRezAnnouncementString(inst, inst.rezsource)
        if announcement_string ~= "" then
            TheNet:Announce(announcement_string, inst.entity, nil, "resurrect")
        end
        inst.rezsource = nil
    end

    inst:PushEvent("ms_respawnedfromghost")
end

local function DoRezDelay(inst, source, delay)
    if not source:IsValid() or source:IsInLimbo() then
        --Revert OnRespawnFromGhost state
        inst:ShowHUD(true)
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:Enable(true)
        end
        inst.rezsource = nil
        --Revert DoMoveToRezSource state
        inst:Show()
        inst.Light:Enable(true)
        inst:SetCameraDistance()
        inst.sg:GoToState("haunt")
        --
    elseif delay == nil or delay <= 0 then
        DoActualRez(inst, source)
    elseif delay > .35 then
        inst:DoTaskInTime(.35, DoRezDelay, source, delay - .35)
    else
        inst:DoTaskInTime(delay, DoRezDelay, source)
    end
end

local function DoMoveToRezSource(inst, source, delay)
    if not source:IsValid() or source:IsInLimbo() then
        --Revert OnRespawnFromGhost state
        inst:ShowHUD(true)
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:Enable(true)
        end
        inst.rezsource = nil
        --
        return
    end

    inst:Hide()
    inst.Light:Enable(false)
    inst.Physics:Teleport(source.Transform:GetWorldPosition())
    inst:SetCameraDistance(24)

    DoRezDelay(inst, source, delay)
end

local function OnRespawnFromGhost(inst, data)
    if not inst:HasTag("playerghost") then
        return
    end

    inst.deathcause = nil
    inst.deathpkname = nil
    inst:ShowHUD(false)
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(false)
    end
    if inst.components.talker ~= nil then
        inst.components.talker:ShutUp()
    end
    inst.sg:AddStateTag("busy")

    if data ~= nil and data.source ~= nil and
        (data.source.prefab == "amulet" or
        data.source.prefab == "resurrectionstatue" or
        data.source.prefab == "resurrectionstone" or
        data.source.prefab == "multiplayer_portal") then
        inst:DoTaskInTime(9 * FRAMES, DoMoveToRezSource, data.source, --[[60-9]] 51 * FRAMES)
    else
        inst:DoTaskInTime(0, DoActualRez)
    end

    inst.rezsource =
        (data ~= nil and data.source ~= nil and data.source.name) or
        (inst.reviver ~= nil and inst.reviver:GetDisplayName()) or
        STRINGS.NAMES.SHENANIGANS
end

local function OnMakePlayerGhost( inst, data )
    if inst:HasTag("playerghost") then
        return
    end
    
    if inst == ThePlayer then
        TheWorld.minimap.MiniMap:EnablePlayerMinimapUpdate(false)
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    -- Spawn a skeleton
    if data ~= nil and data.skeleton then
        local skel = SpawnPrefab("skeleton_player")
        if skel ~= nil then
            skel.Transform:SetPosition(x, y, z)
            -- Set the description
            skel:SetSkeletonDescription(inst.prefab, inst:GetDisplayName(), inst.deathcause, inst.deathpkname)
        end
    end

    if data ~= nil and data.loading then
        -- Set temporary flag for resuming game as a ghost
        -- Used in ghost stategraph as well as below in this function
        inst.loading_ghost = true
    else
        local announcement_string = GetNewDeathAnnouncementString(inst, inst.deathcause, inst.deathpkname)
        if announcement_string ~= "" then
           TheNet:Announce(announcement_string, inst.entity, false, "death" )
        end

        -- Death FX
        SpawnPrefab("die_fx").Transform:SetPosition(x, y, z)
    end

    inst.AnimState:SetBank("ghost")
    inst.AnimState:SetBuild(inst.ghostbuild or ("ghost_"..inst.prefab.."_build"))
    inst.AnimState:SetBloomEffectHandle("shaders/anim_bloom_ghost.ksh")
    inst.AnimState:SetLightOverride(TUNING.GHOST_LIGHT_OVERRIDE)
    if inst:HasTag("ghostwithhat") then
        inst.AnimState:Show("HAT")
        inst.AnimState:Show("HatFX")
    else
        inst.AnimState:Hide("HAT")
        inst.AnimState:Hide("HatFX")
    end
    --inst.AnimState:ClearOverrideSymbol("FX")

    inst:SetStateGraph("SGwilsonghost")

    --Switch to ghost light values
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.6)
    inst.Light:SetColour(180/255, 195/255, 225/255)
    inst.Light:Enable(true)
    inst.DynamicShadow:Enable(false)

    MakeGhostPhysics(inst, 1, .5)
    inst.Physics:Teleport(x, y, z)

    inst:AddTag("playerghost")
    inst.Network:AddUserFlag(USERFLAGS.IS_GHOST)

    inst:RemoveComponent("burnable")

    inst.components.freezable:Reset()
    inst:RemoveComponent("freezable")
    inst:RemoveComponent("propagator")

    inst:RemoveComponent("grogginess")

    inst.components.moisture:ForceDry(true)

    inst.components.sheltered:Stop()

    inst.components.age:PauseAging()

    inst.components.health:Respawn(TUNING.RESURRECT_HEALTH)
    inst.components.health:SetInvincible(true) 

    inst.components.sanity:SetPercent(.5, true)
    inst.components.sanity.ignore = true

    inst.components.hunger:SetPercent(2 / 3, true)
    inst.components.hunger:Pause()

    inst.components.temperature:SetTemp(TUNING.STARTING_TEMP)

    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(true)
    end
    inst.player_classified:SetGhostMode(true)

    ConfigureGhostLocomotor(inst)

    inst:PushEvent("ms_becameghost")

    if inst.loading_ghost then
        inst.loading_ghost = nil
        inst.components.inventory:Close()
    else
        inst.player_classified:AddMorgueRecord()
        SerializeUserSession(inst)
    end
end

local function OnSave(inst, data)
    data.is_ghost = inst:HasTag("playerghost") or nil
    data.skin_name = inst.skin_name or nil

    if inst._OnSave ~= nil then
        inst:_OnSave(data)
    end
end

local function OnLoad(inst, data)
    --If this character is being loaded then it isn't a new spawn
    inst.OnNewSpawn = nil
    inst._OnNewSpawn = nil

    if data ~= nil and data.is_ghost then
        OnMakePlayerGhost(inst, { loading = true })
    end

    inst:OnSetSkin(data ~= nil and data.skin_name or nil)

    if inst._OnLoad ~= nil then
        inst:_OnLoad(data)
    end
end

--V2C: sleeping bag hacks
--     The gist of it is that when we sleep, we gotta temporarly unequip
--     our hand item so it doesn't drain fuel, and hide our active item
--     so that it doesn't show up on our cursor.  However, we do not want
--     anything to be dropped on the ground due to full inventory, and we
--     want everything restored silently to the same state when we wakeup.
local function OnSleepIn(inst)
    if inst._sleepinghandsitem ~= nil then
        --Should not get here...unless previously somehow got out of
        --sleeping state without properly going through wakeup state
        inst._sleepinghandsitem:Show()
        inst.components.inventory.silentfull = true
        inst.components.inventory:GiveItem(inst._sleepinghandsitem)
        inst.components.inventory.silentfull = false
    end
    if inst._sleepingactiveitem ~= nil then
        --Should not get here...unless previously somehow got out of
        --sleeping state without properly going through wakeup state
        inst.components.inventory.silentfull = true
        inst.components.inventory:GiveItem(inst._sleepingactiveitem)
        inst.components.inventory.silentfull = false
    end

    inst._sleepinghandsitem = inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
    if inst._sleepinghandsitem ~= nil then
        inst._sleepinghandsitem:Hide()
    end
    inst._sleepingactiveitem = inst.components.inventory:GetActiveItem()
    if inst._sleepingactiveitem ~= nil then
        inst.components.inventory:SetActiveItem(nil)
    end
end

--V2C: sleeping bag hacks
local function OnWakeUp(inst)
    if inst._sleepinghandsitem ~= nil then
        inst._sleepinghandsitem:Show()
        inst.components.inventory.silentfull = true
        inst.components.inventory:Equip(inst._sleepinghandsitem)
        inst.components.inventory.silentfull = false
        inst._sleepinghandsitem = nil
    end
    if inst._sleepingactiveitem ~= nil then
        inst.components.inventory.silentfull = true
        inst.components.inventory:GiveActiveItem(inst._sleepingactiveitem)
        inst.components.inventory.silentfull = false
        inst._sleepingactiveitem = nil
    end
end

--Player cleanup usually called just before save/delete
--just before the the player entity is actually removed
local function OnDespawn(inst)
    if inst._OnDespawn ~= nil then
        inst:_OnDespawn()
    end

    --V2C: Unfortunately the sleeping bag code is incredibly garbage
    --     so we need all this extra cleanup to cover its edge cases
    if inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("tent") then
        inst:ClearBufferedAction()
    end
    if inst.sleepingbag ~= nil then
        inst.sleepingbag.components.sleepingbag:DoWakeUp(true)
        inst.sleepingbag = nil
    end
    inst:OnWakeUp()
    --

    inst.components.inventory:DropEverythingWithTag("irreplaceable")
    inst.components.leader:RemoveAllFollowers()

    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(false)
    end
    inst.components.locomotor:StopMoving()
    inst.components.locomotor:Clear()
end

local function OnSetSkin(inst, skin_name)
    inst.skin_name = skin_name ~= "" and skin_name or nil

    if not inst:HasTag("playerghost") then
        inst.AnimState:SetBuild(inst.skin_name or inst.prefab)
    end

    if inst._OnSetSkin ~= nil then
        inst:_OnSetSkin(skin_name)
    end
end

--------------------------------------------------------------------------
--HUD/Camera/FE interface
--------------------------------------------------------------------------

local function IsActionsVisible(inst)
    --V2C: This flag is a hack for hiding actions during sleep states
    --     since controls and HUD are technically not "disabled" then
    return inst.player_classified ~= nil and inst.player_classified.isactionsvisible:value()
end

local function IsHUDVisible(inst)
    return inst.player_classified.ishudvisible:value()
end

local function ShowActions(inst, show)
    if TheWorld.ismastersim then
        inst.player_classified:ShowActions(show)
    end
end

local function ShowHUD(inst, show)
    if TheWorld.ismastersim then
        inst.player_classified:ShowHUD(show)
    end
end

local function SetCameraDistance(inst, distance)
    if TheWorld.ismastersim then
        inst.player_classified.cameradistance:set(distance or 0)
    end
end

local function SnapCamera(inst)
    if TheWorld.ismastersim then
        --Forces a netvar to be dirty regardless of value
        inst.player_classified.camerasnap:set_local(true)
        inst.player_classified.camerasnap:set(true)
    end
end

local function ShakeCamera(inst, mode, duration, speed, scale, source, maxDist)
    if source ~= nil and maxDist ~= nil then
        local distSq = inst:GetDistanceSqToInst(source)
        local k = math.max(0, math.min(1, distSq / (maxDist * maxDist)))
        scale = easing.outQuad(k, scale, -scale, 1)
    end

    --normalize for net_byte
    duration = math.floor((duration >= 16 and 16 or duration) * 16 + .5) - 1
    speed = math.floor((speed >= 1 and 1 or speed) * 256 + .5) - 1
    scale = math.floor((scale >= 8 and 8 or scale) * 32 + .5) - 1

    if scale > 0 and speed > 0 and duration > 0 then
        if TheWorld.ismastersim then
            --Forces a netvar to be dirty regardless of value
            inst.player_classified.camerashakemode:set_local(mode)
            inst.player_classified.camerashakemode:set(mode)
            --
            inst.player_classified.camerashaketime:set(duration)
            inst.player_classified.camerashakespeed:set(speed)
            inst.player_classified.camerashakescale:set(scale)
        end
        if inst.HUD ~= nil then
            TheCamera:Shake(
                mode,
                (duration + 1) / 16,
                (speed + 1) / 256,
                (scale + 1) / 32
            )
        end
    end
end

local function ScreenFade(inst, isfadein, time, iswhite)
    if TheWorld.ismastersim then
        --truncate to half of net_smallbyte, so we can include iswhite flag
        time = time ~= nil and math.min(31, math.floor(time * 10 + .5)) or 0
        inst.player_classified.fadetime:set(iswhite and time + 32 or time)
        inst.player_classified.isfadein:set(isfadein)
    end
end

local function ScreenFlash(inst, intensity)
    if TheWorld.ismastersim then
        --normalize for net_tinybyte
        intensity = math.floor((intensity >= 1 and 1 or intensity) * 8 + .5) - 1
        if intensity >= 0 then
            --Forces a netvar to be dirty regardless of value
            inst.player_classified.screenflash:set_local(intensity)
            inst.player_classified.screenflash:set(intensity)
            TheWorld:PushEvent("screenflash", (intensity + 1) / 8)
        end
    end
end

--------------------------------------------------------------------------

local function ApplyScale(inst, source, scale)
    if TheWorld.ismastersim and source ~= nil then
        if scale ~= 1 and scale ~= nil then
            if inst._scalesource == nil then
                inst._scalesource = { [source] = scale }
                inst.Transform:SetScale(scale, scale, scale)
            elseif inst._scalesource[source] ~= scale then
                inst._scalesource[source] = scale
                local scale = 1
                for k, v in pairs(inst._scalesource) do
                    scale = scale * v
                end
                inst.Transform:SetScale(scale, scale, scale)
            end
        elseif inst._scalesource ~= nil and inst._scalesource[source] ~= nil then
            inst._scalesource[source] = nil
            if next(inst._scalesource) == nil then
                inst._scalesource = nil
                inst.Transform:SetScale(1, 1, 1)
            else
                local scale = 1
                for k, v in pairs(inst._scalesource) do
                    scale = scale * v
                end
                inst.Transform:SetScale(scale, scale, scale)
            end
        end
    end
end

--------------------------------------------------------------------------

local function MakePlayerCharacter(name, customprefabs, customassets, common_postinit, master_postinit, starting_inventory)
    local assets =
    {
        Asset("ANIM", "anim/player_basic.zip"),
        Asset("ANIM", "anim/player_idles_shiver.zip"),
        Asset("ANIM", "anim/player_actions.zip"),
        Asset("ANIM", "anim/player_actions_axe.zip"),
        Asset("ANIM", "anim/player_actions_pickaxe.zip"),
        Asset("ANIM", "anim/player_actions_shovel.zip"),
        Asset("ANIM", "anim/player_actions_blowdart.zip"),
        Asset("ANIM", "anim/player_actions_eat.zip"),
        Asset("ANIM", "anim/player_actions_item.zip"),
        Asset("ANIM", "anim/player_cave_enter.zip"),
        Asset("ANIM", "anim/player_actions_uniqueitem.zip"),
        Asset("ANIM", "anim/player_actions_bugnet.zip"),
        Asset("ANIM", "anim/player_actions_fishing.zip"),
        Asset("ANIM", "anim/player_actions_boomerang.zip"),
        Asset("ANIM", "anim/player_bush_hat.zip"),
        Asset("ANIM", "anim/player_attacks.zip"),
        Asset("ANIM", "anim/player_idles.zip"),
        Asset("ANIM", "anim/player_rebirth.zip"),
        Asset("ANIM", "anim/player_jump.zip"),
        Asset("ANIM", "anim/player_amulet_resurrect.zip"),
        Asset("ANIM", "anim/player_teleport.zip"),
        Asset("ANIM", "anim/wilson_fx.zip"),
        Asset("ANIM", "anim/player_one_man_band.zip"),
        Asset("ANIM", "anim/player_slurtle_armor.zip"),
        Asset("ANIM", "anim/player_staff.zip"),
        Asset("ANIM", "anim/player_hit_darkness.zip"),

        Asset("ANIM", "anim/player_frozen.zip"),
        Asset("ANIM", "anim/player_shock.zip"),
        Asset("ANIM", "anim/shock_fx.zip"),
        Asset("ANIM", "anim/player_tornado.zip"),

        Asset("ANIM", "anim/goo.zip"),

        Asset("ANIM", "anim/shadow_hands.zip"),

        Asset("SOUND", "sound/sfx.fsb"),
        Asset("SOUND", "sound/wilson.fsb"),

        Asset("ANIM", "anim/player_ghost_withhat.zip"),
        Asset("ANIM", "anim/player_revive_ghosthat.zip"),
        Asset("ANIM", "anim/player_revive_to_character.zip"),
        Asset("ANIM", "anim/player_knockedout.zip"),
        Asset("ANIM", "anim/player_emotesxl.zip"),
        Asset("ANIM", "anim/player_emotes_dance0.zip"),
        Asset("ANIM", "anim/emote_fx.zip"),
        Asset("ANIM", "anim/tears.zip"),
        Asset("ANIM", "anim/puff_spawning.zip"),

        Asset("ANIM", "anim/player_idles_groggy.zip"),
        Asset("ANIM", "anim/player_groggy.zip"),

        Asset("ANIM", "anim/fish01.zip"),   --These are used for the fishing animations.
        Asset("ANIM", "anim/eel01.zip"),

        Asset("IMAGE", "images/colour_cubes/ghost_cc.tex"),
        Asset("IMAGE", "images/colour_cubes/mole_vision_on_cc.tex"),
        Asset("IMAGE", "images/colour_cubes/mole_vision_off_cc.tex"),
    }

    local prefabs =
    {
        "brokentool",
        "frostbreath",
        "reticule",
        "mining_fx",
        "die_fx",
        "ghost_transform_overlay_fx",
    }

    if starting_inventory ~= nil or customprefabs ~= nil then
        local prefabs_cache = {}
        for i, v in ipairs(prefabs) do
            prefabs_cache[v] = true
        end

        if starting_inventory ~= nil then
            for i, v in ipairs(starting_inventory) do
                if not prefabs_cache[v] then
                    table.insert(prefabs, v)
                    prefabs_cache[v] = true
                end
            end
        end

        if customprefabs ~= nil then
            for i, v in ipairs(customprefabs) do
                if not prefabs_cache[v] then
                    table.insert(prefabs, v)
                    prefabs_cache[v] = true
                end
            end
        end
    end

    if customassets ~= nil then
        for i, v in ipairs(customassets) do
            table.insert(assets, v)
        end
    end

    local function fn()
        local inst = CreateEntity()

        table.insert(AllPlayers, inst)

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddLight()
        inst.entity:AddLightWatcher()
        inst.entity:AddNetwork()

        inst.Transform:SetFourFaced()

        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        inst.AnimState:Hide("ARM_carry")
        inst.AnimState:Hide("HAT")
        inst.AnimState:Hide("HAT_HAIR")
        inst.AnimState:Show("HAIR_NOHAT")
        inst.AnimState:Show("HAIR")
        inst.AnimState:Show("HEAD")
        inst.AnimState:Hide("HEAD_HAT")

        inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
        inst.AnimState:OverrideSymbol("fx_liquid", "wilson_fx", "fx_liquid")
        inst.AnimState:OverrideSymbol("shadow_hands", "shadow_hands", "shadow_hands")

        --Additional effects symbols for hit_darkness animation
        inst.AnimState:AddOverrideBuild("player_hit_darkness")

        inst.DynamicShadow:SetSize(1.3, .6)

        inst.MiniMapEntity:SetIcon(name..".png")
        inst.MiniMapEntity:SetPriority(10)
        inst.MiniMapEntity:SetCanUseCache(false)

        --Default to electrocute light values
        inst.Light:SetIntensity(.8)
        inst.Light:SetRadius(.5)
        inst.Light:SetFalloff(.65)
        inst.Light:SetColour(255 / 255, 255 / 255, 236 / 255)
        inst.Light:Enable(false)

        inst.LightWatcher:SetLightThresh(.075)
        inst.LightWatcher:SetDarkThresh(.05)

        MakeCharacterPhysics(inst, 75, .5)

        inst:AddTag("player")
        inst:AddTag("scarytoprey")
        inst:AddTag("character")
        inst:AddTag("lightningtarget")

        inst.AttachClassified = AttachClassified
        inst.DetachClassified = DetachClassified
        inst.OnRemoveEntity = OnRemoveEntity
        inst.CanExamine = nil -- Can be overridden; Needs to be on client as well for actions
        inst.ActionStringOverride = nil -- Can be overridden; Needs to be on client as well for actions
        inst.GetTemperature = GetTemperature -- Didn't want to make temperature a networked component
        inst.IsFreezing = IsFreezing -- Didn't want to make temperature a networked component
        inst.IsOverheating = IsOverheating -- Didn't want to make temperature a networked component
        inst.GetMoisture = GetMoisture -- Didn't want to make moisture a networked component
        inst.GetMaxMoisture = GetMaxMoisture -- Didn't want to make moisture a networked component
        inst.GetMoistureRateScale = GetMoistureRateScale -- Didn't want to make moisture a networked component
        inst.EnableMovementPrediction = EnableMovementPrediction
        inst.ShakeCamera = ShakeCamera
        inst.SetGhostMode = SetGhostMode
        inst.IsActionsVisible = IsActionsVisible

        inst.foleysound = nil --Characters may override this in common_postinit
        inst.playercolour = DEFAULT_PLAYER_COLOUR --Default player colour used in case it doesn't get set properly
        inst.ghostenabled = GetGhostEnabled(TheNet:GetServerGameMode())

        inst.jointask = inst:DoTaskInTime(0, OnPlayerJoined)
        inst:ListenForEvent("setowner", OnSetOwner)

        -- V2C: also TODO implement talker properly after PAX
        inst:AddComponent("talker")

        inst:AddComponent("playervision")

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        --trader (from trader component) added to pristine state for optimization
        inst:AddTag("trader")

        --Sneak these into pristine state for optimization
        inst:AddTag("_health")
        inst:AddTag("_hunger")
        inst:AddTag("_sanity")
        inst:AddTag("_builder")
        inst:AddTag("_combat")
        inst:AddTag("_moisture")
        inst:AddTag("_sheltered")

        inst.userid = ""

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false --handled in a special way

        --Remove these tags so that they can be added properly when replicating components below
        inst:RemoveTag("_health")
        inst:RemoveTag("_hunger")
        inst:RemoveTag("_sanity")
        inst:RemoveTag("_builder")
        inst:RemoveTag("_combat")
        inst:RemoveTag("_moisture")
        inst:RemoveTag("_sheltered")

        if inst.ghostenabled then
            inst.Network:RemoveUserFlag(USERFLAGS.IS_GHOST)
        end
        inst.Network:RemoveUserFlag(USERFLAGS.CHARACTER_STATE_1)
        inst.Network:RemoveUserFlag(USERFLAGS.CHARACTER_STATE_2)

        inst.player_classified = SpawnPrefab("player_classified")
        inst.player_classified.entity:SetParent(inst.entity)

        inst:ListenForEvent("death", OnPlayerDeath)
        if inst.ghostenabled then
            --Ghost events (Edit stategraph to push makeplayerghost instead of makeplayerdead to enter ghost state)
            inst:ListenForEvent("makeplayerghost", OnMakePlayerGhost)
            inst:ListenForEvent("respawnfromghost", OnRespawnFromGhost)
            inst:ListenForEvent("ghostdissipated", OnPlayerDied)
        else
            inst:ListenForEvent("playerdied", OnPlayerDied)
        end

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        ConfigurePlayerLocomotor(inst)

        inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE)
        inst.components.combat.GetGiveUpString = giveupstring
        inst.components.combat.GetBattleCryString = battlecrystring
        inst.components.combat.hiteffectsymbol = "torso"
        inst.components.combat.pvp_damagemod = TUNING.PVP_DAMAGE_MOD -- players shouldn't hurt other players very much
        inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
        inst.components.combat:SetRange(2)

        MakeMediumBurnableCharacter(inst, "torso")
        inst.components.burnable:SetBurnTime(TUNING.PLAYER_BURN_TIME)

        MakeHugeFreezableCharacter(inst, "torso")
        inst.components.freezable:SetDefaultWearOffTime(TUNING.PLAYER_FREEZE_WEAR_OFF_TIME)

        inst:AddComponent("inventory")
        --players handle inventory dropping manually in their stategraph
        inst.components.inventory:DisableDropOnDeath()

        -- Player labeling stuff
        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus

        inst:AddComponent("temperature")
        inst.components.temperature.usespawnlight = true

        inst:AddComponent("moisture")
        inst:AddComponent("sheltered")

        -------
        
        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH)
        inst.components.health.nofadeout = true

        inst:AddComponent("hunger")
        inst.components.hunger:SetMax(TUNING.WILSON_HUNGER)
        inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE)
        inst.components.hunger:SetKillRate(TUNING.WILSON_HEALTH/TUNING.STARVE_KILL_TIME)

        inst:AddComponent("sanity")
        inst.components.sanity:SetMax(TUNING.WILSON_SANITY)

        inst:AddComponent("builder")

        -------

        inst:AddComponent("wisecracker")
        inst:AddComponent("distancetracker")

        inst:AddComponent("catcher")

        inst:AddComponent("playerlightningtarget")

        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.onaccept = OnGetItem
        inst.components.trader.deleteitemonaccept = false

        -------

        inst:AddComponent("eater")
        inst:AddComponent("leader")
        inst:AddComponent("frostybreather")
        inst:AddComponent("age")

        inst:AddComponent("grue")
        inst.components.grue:SetSounds("dontstarve/charlie/warn","dontstarve/charlie/attack")

        inst:AddComponent("pinnable")

        inst:AddComponent("grogginess")
        inst.components.grogginess:SetResistance(3)
        inst.components.grogginess:SetKnockOutTest(ShouldKnockout)

        inst:AddComponent("colourtweener")

        -------
        if METRICS_ENABLED then
            inst:AddComponent("overseer") 
        end
        -------

        inst:AddInherentAction(ACTIONS.PICK)
        inst:AddInherentAction(ACTIONS.SLEEPIN)

        inst:SetStateGraph("SGwilson")

        RegisterMasterEventListeners(inst)

        --HUD interface
        inst.IsHUDVisible = IsHUDVisible
        inst.ShowActions = ShowActions
        inst.ShowHUD = ShowHUD
        inst.SetCameraDistance = SetCameraDistance
        inst.SnapCamera = SnapCamera
        inst.ScreenFade = ScreenFade
        inst.ScreenFlash = ScreenFlash

        --Other
        inst._scalesource = nil
        inst.ApplyScale = ApplyScale

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        --V2C: sleeping bag hacks
        inst.OnSleepIn = OnSleepIn
        inst.OnWakeUp = OnWakeUp

        inst._OnSave = inst.OnSave
        inst._OnLoad = inst.OnLoad
        inst._OnDespawn = inst.OnDespawn
        inst._OnSetSkin = inst.OnSetSkin
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnDespawn = OnDespawn
        inst.OnSetSkin = OnSetSkin

        if starting_inventory ~= nil and #starting_inventory > 0 then
            --Will be triggered from SpawnNewPlayerOnServerFromSim
            --only if it is a new spawn
            inst._OnNewSpawn = inst.OnNewSpawn
            inst.OnNewSpawn = function()
                if inst.components.inventory ~= nil then
                    inst.components.inventory.ignoresound = true
                    for i, v in ipairs(starting_inventory) do
                        inst.components.inventory:GiveItem(SpawnPrefab(v))
                    end
                    inst.components.inventory.ignoresound = false
                end
                if inst._OnNewSpawn ~= nil then
                    inst:_OnNewSpawn()
                    inst._OnNewSpawn = nil
                end
            end
        end

        inst:ListenForEvent("startfiredamage", OnStartFireDamage)
        inst:ListenForEvent("stopfiredamage", OnStopFireDamage)

        TheWorld:PushEvent("ms_playerspawn", inst)

        return inst
    end

    return Prefab("characters/"..name, fn, assets, prefabs)
end

return MakePlayerCharacter
