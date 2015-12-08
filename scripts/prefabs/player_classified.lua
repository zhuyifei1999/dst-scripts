local TIMEOUT = 2

--------------------------------------------------------------------------
--Server interface
--------------------------------------------------------------------------

local function SetValue(inst, name, value)
    assert(value >= 0 and value <= 65535, "Player "..tostring(name).." out of range: "..tostring(value))
    inst[name]:set(math.ceil(value))
end

local function SetDirty(netvar, val)
    --Forces a netvar to be dirty regardless of value
    netvar:set_local(val)
    netvar:set(val)
end

local function PushPausePredictionFrames(inst, frames)
    --Force dirty, we just want to trigger an event on the client
    SetDirty(inst.pausepredictionframes, frames)
end

local function OnHealthDelta(parent, data)
    if data.overtime then
        parent.player_classified.ishealthpulse:set_local(false)
    else
        --Force dirty, we just want to trigger an event on the client
        SetDirty(parent.player_classified.ishealthpulse, true)
    end
end

local function OnHungerDelta(parent, data)
    if data.overtime then
        parent.player_classified.ishungerpulse:set_local(false)
    else
        --Force dirty, we just want to trigger an event on the client
        SetDirty(parent.player_classified.ishungerpulse, true)
    end
end

local function UpdateAnimOverrideSanity(parent)
    parent.AnimState:SetClientSideBuildOverrideFlag("insane", parent.replica.sanity:IsCrazy())
end

local function OnSanityDelta(parent, data)
    if data.overtime then
        parent.player_classified.issanitypulse:set_local(false)
    else
        --Force dirty, we just want to trigger an event on the client
        SetDirty(parent.player_classified.issanitypulse, true)
    end
    if parent == ThePlayer then
	    parent:DoTaskInTime(0, UpdateAnimOverrideSanity)
	end
end

local function OnBeavernessDelta(parent, data)
    if data.overtime then
        parent.player_classified.isbeavernesspulse:set_local(false)
    else
        --Force dirty, we just want to trigger an event on the client
        SetDirty(parent.player_classified.isbeavernesspulse, true)
    end
end

local function OnAttacked(parent, data)
    parent.player_classified.attackedpulseevent:push()
    parent.player_classified.isattackedbydanger:set(data ~= nil
                                                and data.attacker ~= nil
                                                and not (data.attacker:HasTag("shadow")
                                                         or data.attacker:HasTag("thorny")
                                                         or data.attacker:HasTag("smolder")
                                                        )
                                                )
end

local function OnBuildSuccess(parent)
    parent.player_classified.buildevent:push()
end

local function OnConsumeHealthCost(parent)
    parent.player_classified.builderdamagedevent:push()
end

local function OnLearnRecipeSuccess(parent)
    parent.player_classified.learnrecipeevent:push()
end

local function OnRepairSuccess(parent)
    parent.player_classified.repairevent:push()
end

local function OnPerformAction(parent)
    SetDirty(parent.player_classified.isperformactionsuccess, true)
end

local function OnActionFailed(parent)
    SetDirty(parent.player_classified.isperformactionsuccess, false)
end

local function OnWormholeTravel(parent, wormholetype)
    SetDirty(parent.player_classified.wormholetravelevent, wormholetype)
end

local function OnMakeFriend(parent)
    parent.player_classified.makefriendevent:push()
end

local function AddMorgueRecord(inst)
    if inst._parent ~= nil then
        SetDirty(inst.isdeathbypk, inst._parent.deathpkname ~= nil)
        inst.deathcause:set(inst._parent.deathpkname or inst._parent.deathcause)
    end
end

--Temperature stuff
local max_precision_temp = 6
local min_precision_temp = -11
local precision_factor = 4
local coarse_factor = 1
local pivot = math.floor((256 - (max_precision_temp + min_precision_temp) * precision_factor) / 2)

local function SetTemperature(inst, temperature)
    if temperature >= max_precision_temp then
        inst.currenttemperaturedata:set(pivot + max_precision_temp * precision_factor + math.floor((temperature - max_precision_temp) * coarse_factor + .5))
    elseif temperature <= min_precision_temp then
        inst.currenttemperaturedata:set(pivot + min_precision_temp * precision_factor + math.floor((temperature - min_precision_temp) * coarse_factor + .5))
    else
        inst.currenttemperaturedata:set(pivot + math.floor(temperature * precision_factor + .5))
    end
end

--------------------------------------------------------------------------
--Client interface
--------------------------------------------------------------------------

local function DeserializeTemperature(inst)
    if inst.currenttemperaturedata:value() >= pivot + max_precision_temp * precision_factor then
        inst.currenttemperature = (inst.currenttemperaturedata:value() - pivot - max_precision_temp * precision_factor) / coarse_factor + max_precision_temp
    elseif inst.currenttemperaturedata:value() <= pivot + min_precision_temp * precision_factor then
        inst.currenttemperature = (inst.currenttemperaturedata:value() - pivot - min_precision_temp * precision_factor) / coarse_factor + min_precision_temp
    else
        inst.currenttemperature = (inst.currenttemperaturedata:value() - pivot) / precision_factor
    end
end

local function OnEntityReplicated(inst)
    inst._parent = inst.entity:GetParent()
    if inst._parent == nil then
        print("Unable to initialize classified data for player")
    else
        inst._parent:AttachClassified(inst)
        for i, v in ipairs({ "builder", "combat", "health", "hunger", "sanity" }) do
            if inst._parent.replica[v] ~= nil then
                inst._parent.replica[v]:AttachClassified(inst)
            end
        end
        for i, v in ipairs({ "playercontroller" }) do
            if inst._parent.components[v] ~= nil then
                inst._parent.components[v]:AttachClassified(inst)
            end
        end
    end
end

local function OnHealthDirty(inst)
    if inst._parent ~= nil then
        local data =
        {
            oldpercent = inst._oldhealthpercent,
            newpercent = inst.currenthealth:value() / inst.maxhealth:value(),
            overtime = not inst.ishealthpulse:value(),
        }
        inst._oldhealthpercent = data.newpercent
        inst.ishealthpulse:set_local(false)
        inst._parent:PushEvent("healthdelta", data)
    else
        inst._oldhealthpercent = 1
        inst.ishealthpulse:set_local(false)
    end
end

local function OnIsTakingFireDamageDirty(inst)
    if inst._parent ~= nil then
        if inst.istakingfiredamage:value() then
            inst._parent:PushEvent("startfiredamage")
        else
            inst._parent:PushEvent("stopfiredamage")
        end
    end
end

local function OnAttackedPulseEvent(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("attacked", { isattackedbydanger = inst.isattackedbydanger:value() })
    end
end

local function OnHungerDirty(inst)
    if inst._parent ~= nil then
        local oldpercent = inst._oldhungerpercent
        local percent = inst.currenthunger:value() / inst.maxhunger:value()
        local data =
        {
            oldpercent = oldpercent,
            newpercent = percent,
            overtime = not inst.ishungerpulse:value(),
        }
        inst._oldhungerpercent = percent
        inst.ishungerpulse:set_local(false)
        inst._parent:PushEvent("hungerdelta", data)
        --push starving event if beaverness value isn't currently starving
        if inst._oldbeavernesspercent > 0 then
            if oldpercent > 0 then
                if percent <= 0 then
                    inst._parent:PushEvent("startstarving")
                end
            elseif percent > 0 then
                inst._parent:PushEvent("stopstarving")
            end
        end
    else
        inst._oldhungerpercent = 1
        inst.ishungerpulse:set_local(false)
    end
end

local function OnSanityDirty(inst)
    if inst._parent ~= nil then
        local data =
        {
            oldpercent = inst._oldsanitypercent,
            newpercent = inst.currentsanity:value() / inst.maxsanity:value(),
            overtime = not inst.issanitypulse:value(),
        }
        inst._oldsanitypercent = data.newpercent
        inst.issanitypulse:set_local(false)
        inst._parent:PushEvent("sanitydelta", data)

        inst._parent:DoTaskInTime(0, UpdateAnimOverrideSanity)
    else
        inst._oldsanitypercent = 1
        inst.issanitypulse:set_local(false)
    end
end

local function OnBeavernessDirty(inst)
    if inst._parent ~= nil then
        local oldpercent = inst._oldbeavernesspercent
        local percent = inst.currentbeaverness:value() * .01
        local data =
        {
            oldpercent = oldpercent,
            newpercent = percent,
            overtime = not inst.isbeavernesspulse:value(),
        }
        inst._oldbeavernesspercent = percent
        inst.isbeavernesspulse:set_local(false)
        inst._parent:PushEvent("beavernessdelta", data)
        --push starving event if hunger value isn't currently starving
        if inst._oldhungerpercent > 0 then
            if oldpercent > 0 then
                if percent <= 0 then
                    inst._parent:PushEvent("startstarving")
                end
            elseif percent > 0 then
                inst._parent:PushEvent("stopstarving")
            end
        end
    else
        inst._oldbeavernesspercent = 1
        inst.isbeavernesspulse:set_local(false)
    end
end

local function OnMoistureDirty(inst)
    if inst._parent ~= nil then
        local data =
        {
            old = inst._oldmoisture,
            new = inst.moisture:value(),
        }
        inst._oldmoisture = data.new
        inst._parent:PushEvent("moisturedelta", data)
    else
        inst._oldmoisture = 0
    end
end

local function OnTemperatureDirty(inst)
    DeserializeTemperature(inst)
    if inst._parent == nil then
        inst._oldtemperature = TUNING.STARTING_TEMP
    elseif inst._oldtemperature ~= inst.currenttemperature then
        local oldtemperature = inst._oldtemperature
        local temperature = inst.currenttemperature
        local data =
        {
            last = oldtemperature,
            new = temperature,
        }
        inst._oldtemperature = temperature
        if oldtemperature < 0 then
            if temperature >= 0 then
                inst._parent:PushEvent("stopfreezing")
            end
        elseif temperature < 0 then
            inst._parent:PushEvent("startfreezing")
        end
        inst._parent:PushEvent("temperaturedelta", data)
    end
end

local function OnTechTreesDirty(inst)
    inst.techtrees.SCIENCE = inst.sciencelevel:value()
    inst.techtrees.MAGIC = inst.magiclevel:value()
    inst.techtrees.ANCIENT = inst.ancientlevel:value()
    if inst._parent ~= nil then
        inst._parent:PushEvent("techtreechange", { level = inst.techtrees })
    end
end

local function OnRecipesDirty(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("unlockrecipe")
    end
end

local function Refresh(inst)
    inst._refreshtask = nil
    for k, v in pairs(inst._bufferedbuildspreview) do
        inst._bufferedbuildspreview[k] = nil
    end
    if inst._parent ~= nil then
        inst._parent:PushEvent("refreshcrafting")
    end
end

local function QueueRefresh(inst, delay)
    if inst._refreshtask == nil then
        inst._refreshtask = inst:DoTaskInTime(delay, Refresh)
    end
end

local function CancelRefresh(inst)
    if inst._refreshtask ~= nil then
        inst._refreshtask:Cancel()
        inst._refreshtask = nil
    end
end

local function OnBufferedBuildsDirty(inst)
    CancelRefresh(inst)
    Refresh(inst)
end

local function BufferBuild(inst, recipename)
    local recipe = GetValidRecipe(recipename)
    local inventory = inst._parent ~= nil and inst._parent.replica.inventory ~= nil and inst._parent.replica.inventory.classified or nil
    if recipe ~= nil and inventory ~= nil and inventory:RemoveIngredients(recipe, INGREDIENT_MOD_LOOKUP[inst.ingredientmod:value()]) then
        inst._bufferedbuildspreview[recipename] = true
        if inst._parent ~= nil then
            inst._parent:PushEvent("refreshcrafting")
        end
        CancelRefresh(inst)
        QueueRefresh(inst, TIMEOUT)
        SendRPCToServer(RPC.BufferBuild, recipe.rpc_id)
    end
end

local function OnIsPerformActionSuccessDirty(inst)
    if inst._parent ~= nil then
        if inst._parent.bufferedaction ~= nil and
            inst._parent.bufferedaction.ispreviewing then
            inst._parent:ClearBufferedAction()
        end
        if inst.isperformactionsuccess:value() then
            inst._parent:PushEvent("performaction")
        end
    end
end

local function CancelPausePrediction(inst)
    if inst._pausepredictiontask ~= nil then
        inst._pausepredictiontask:Cancel()
        inst._pausepredictiontask = nil
        inst.pausepredictionframes:set_local(0)
    end
end

local function OnPausePredictionFramesDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        if inst._pausepredictiontask ~= nil then
            inst._pausepredictiontask:Cancel()
        end
        inst._pausepredictiontask = inst.pausepredictionframes:value() > 0 and inst:DoTaskInTime(inst.pausepredictionframes:value() * FRAMES, CancelPausePrediction) or nil
        inst._parent:PushEvent("cancelmovementprediction")
    end
end

local function OnPlayerCameraShake(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        TheCamera:Shake(
            inst.camerashakemode:value(),
            (inst.camerashaketime:value() + 1) / 16,
            (inst.camerashakespeed:value() + 1) / 256,
            (inst.camerashakescale:value() + 1) / 32
        )
    end
end

local function OnPlayerScreenFlashDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        TheWorld:PushEvent("screenflash", (inst.screenflash:value() + 1) / 8)
    end
end

local function OnAttunedResurrectorDirty(inst)
    if inst._parent ~= nil then
        inst._parent:PushEvent("attunedresurrector", inst.attunedresurrector:value())
    end
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

local function OnBuildEvent(inst)
    if inst._parent ~= nil and TheFocalPoint.entity:GetParent() == inst._parent then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/collect_newitem")
        inst._parent:PushEvent("buildsuccess")
    end
end

local function OnBuilderDamagedEvent(inst)
    if inst._parent ~= nil and TheFocalPoint.entity:GetParent() == inst._parent then
        inst._parent:PushEvent("damaged")
    end
end

local function OnLearnRecipeEvent(inst)
    if inst._parent ~= nil and TheFocalPoint.entity:GetParent() == inst._parent then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/get_gold")
    end
end

local function OnRepairEvent(inst)
    if inst._parent ~= nil and TheFocalPoint.entity:GetParent() == inst._parent then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/repair_clothing")
    end
end

local function OnGhostModeDirty(inst)
    if inst._parent ~= nil then
        inst._parent.components.playervision:SetGhostVision(inst.isghostmode:value())
        if inst._parent.HUD ~= nil then
            inst._parent:SetGhostMode(inst.isghostmode:value())
        end
    end
end

local function OnPlayerHUDDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        if inst.ishudvisible:value() then
            inst._parent.HUD:Show()
        else
            inst._parent.HUD:Hide()
        end

        if inst.ismapcontrolsvisible:value() then
            inst._parent.HUD.controls.mapcontrols:ShowMapButton()
        else
            if inst._parent.HUD:IsMapScreenOpen() then
                TheFrontEnd:PopScreen()
            end
            inst._parent.HUD.controls.mapcontrols:HideMapButton()
        end
    end
end

local function OnPlayerCameraDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        if inst.iscamerazoomed:value() then
            if inst._prevcameradistance == nil then
                inst._prevcameradistance = TheCamera.distance
                inst._prevcameradistancegain = TheCamera.distancegain
                if inst._prevcameradistance > 18 then
                    TheCamera:SetDistance(18)
                    TheCamera.distancegain = 3
                    TheCamera:SetControllable(false)
                end
            end
        elseif inst._prevcameradistance ~= nil then
            TheCamera:SetDistance(inst.cameradistance:value() > 0 and inst.cameradistance:value() or inst._prevcameradistance)
            TheCamera.distancegain = inst._prevcameradistancegain
            inst._prevcameradistance = nil
            inst._prevcameradistancegain = nil
            TheCamera:SetControllable(true)
        elseif inst.cameradistance:value() > 0 then
            TheCamera:SetDistance(inst.cameradistance:value())
        else
            TheCamera:SetDefault()
        end
    end
end

local function OnIsWardrobePopUpVisibleDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        if not inst.iswardrobepopupvisible:value() then
            inst._parent.HUD:CloseWardrobeScreen()
        elseif not inst._parent.HUD:OpenWardrobeScreen() then
            if not TheWorld.ismastersim then
                SendRPCToServer(RPC.CloseWardrobe)
            else
                inst._parent:PushEvent("ms_closewardrobe")
            end
        end
    end
end

local function OnIsGiftItemPopUpVisibleDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        if not inst.isgiftitempopupvisible:value() then
            inst._parent.HUD:CloseItemManagerScreen()
        elseif not inst._parent.HUD:OpenItemManagerScreen() then
            if not TheWorld.ismastersim then
                SendRPCToServer(RPC.DoneOpenGift)
            elseif inst._parent.components.giftreceiver ~= nil then
                inst._parent.components.giftreceiver:OnStopOpenGift()
            end
        end
    end
end

local function OnGiftsDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        inst._parent:PushEvent("giftreceiverupdate", {
            numitems = inst.hasgift:value() and 1 or 0,
            active = inst.hasgiftmachine:value(),
        })
    end
end

local function DoSnapCamera()
    TheCamera:Snap()
end

local function OnPlayerCameraSnap(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        if TheWorld.ismastersim then
            TheCamera:Snap()
        else
            inst:DoTaskInTime(0, DoSnapCamera)
        end
    end
end

local function OnPlayerFadeDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        local iswhite = inst.fadetime:value() >= 32
        local time = iswhite and inst.fadetime:value() - 32 or inst.fadetime:value()
        if time > 0 then
            TheFrontEnd:Fade(inst.isfadein:value(), time / 10, nil, nil, nil, iswhite and "white" or "black")
            if inst.isfadein:value() then
                TheWorld.GroundCreep:FastForward()
            end
        else
            TheFrontEnd.fade_type = iswhite and "white" or "black"
            TheFrontEnd:SetFadeLevel(inst.isfadein:value() and 0 or 1)
        end
    end
end

local function OnWormholeTravelDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        if inst._parent.player_classified.wormholetravelevent:value() == WORMHOLETYPE.WORM then
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/teleportworm/travel")
        elseif inst._parent.player_classified.wormholetravelevent:value() == WORMHOLETYPE.TENTAPILLAR then
            TheFocalPoint.SoundEmitter:PlaySound("dontstarve/cave/tentapiller_hole_travel")
        end
    end
end

local function OnMakeFriendEvent(inst)
    if inst._parent ~= nil and TheFocalPoint.entity:GetParent() == inst._parent then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/makeFriend")
    end
end

local function OnMorgueDirty(inst)
    if inst._parent ~= nil and inst._parent.HUD ~= nil then
        Morgue:OnDeath({
            pk = inst.isdeathbypk:value() or nil,
            killed_by = inst.deathcause:value(),
            days_survived = inst._parent.Network:GetPlayerAge(),
            character = inst._parent.prefab,
            location = "unknown",
            world = TheWorld.meta ~= nil and TheWorld.meta.level_id or "unknown",
            server = TheNet:GetServerName(),
        })
    end
end

--------------------------------------------------------------------------
--Server overriden to handle dirty events immediately
--otherwise server HUD events will be one wall-update late
--and possibly show some flicker
--------------------------------------------------------------------------

local function SetGhostMode(inst, isghostmode)
    inst.isghostmode:set(isghostmode)
    OnGhostModeDirty(inst)
end

local function ShowActions(inst, show)
    inst.isactionsvisible:set(show)
end

local function ShowHUD(inst, show)
    inst.ishudvisible:set(show)
    OnPlayerHUDDirty(inst)
end

local function EnableMapControls(inst, enable)
    inst.ismapcontrolsvisible:set(enable)
    OnPlayerHUDDirty(inst)
end

local function ShowWardrobePopUp(inst, show)
    inst.iswardrobepopupvisible:set(show)
    OnIsWardrobePopUpVisibleDirty(inst)
end

local function ShowGiftItemPopUp(inst, show)
    inst.isgiftitempopupvisible:set(show)
    OnIsGiftItemPopUpVisibleDirty(inst)
end

--------------------------------------------------------------------------

local function RegisterNetListeners(inst)
    if TheWorld.ismastersim then
        inst._parent = inst.entity:GetParent()
        inst:ListenForEvent("healthdelta", OnHealthDelta, inst._parent)
        inst:ListenForEvent("hungerdelta", OnHungerDelta, inst._parent)
        inst:ListenForEvent("sanitydelta", OnSanityDelta, inst._parent)
        inst:ListenForEvent("beavernessdelta", OnBeavernessDelta, inst._parent)
        inst:ListenForEvent("attacked", OnAttacked, inst._parent)
        inst:ListenForEvent("builditem", OnBuildSuccess, inst._parent)
        inst:ListenForEvent("buildstructure", OnBuildSuccess, inst._parent)
        inst:ListenForEvent("consumehealthcost", OnConsumeHealthCost, inst._parent)
        inst:ListenForEvent("learnrecipe", OnLearnRecipeSuccess, inst._parent)
        inst:ListenForEvent("repair", OnRepairSuccess, inst._parent)
        inst:ListenForEvent("performaction", OnPerformAction, inst._parent)
        inst:ListenForEvent("actionfailed", OnActionFailed, inst._parent)
        inst:ListenForEvent("wormholetravel", OnWormholeTravel, inst._parent)
        inst:ListenForEvent("makefriend", OnMakeFriend, inst._parent)
    else
        inst.ishealthpulse:set_local(false)
        inst.ishungerpulse:set_local(false)
        inst.issanitypulse:set_local(false)
        inst.pausepredictionframes:set_local(0)
        inst:ListenForEvent("healthdirty", OnHealthDirty)
        inst:ListenForEvent("istakingfiredamagedirty", OnIsTakingFireDamageDirty)
        inst:ListenForEvent("combat.attackedpulse", OnAttackedPulseEvent)
        inst:ListenForEvent("hungerdirty", OnHungerDirty)
        inst:ListenForEvent("sanitydirty", OnSanityDirty)
        inst:ListenForEvent("beavernessdirty", OnBeavernessDirty)
        inst:ListenForEvent("temperaturedirty", OnTemperatureDirty)
        inst:ListenForEvent("moisturedirty", OnMoistureDirty)
        inst:ListenForEvent("techtreesdirty", OnTechTreesDirty)
        inst:ListenForEvent("recipesdirty", OnRecipesDirty)
        inst:ListenForEvent("bufferedbuildsdirty", OnBufferedBuildsDirty)
        inst:ListenForEvent("isperformactionsuccessdirty", OnIsPerformActionSuccessDirty)
        inst:ListenForEvent("pausepredictionframesdirty", OnPausePredictionFramesDirty)
        inst:ListenForEvent("isghostmodedirty", OnGhostModeDirty)
        inst:ListenForEvent("playerhuddirty", OnPlayerHUDDirty)
        inst:ListenForEvent("playercamerashake", OnPlayerCameraShake)
        inst:ListenForEvent("playerscreenflashdirty", OnPlayerScreenFlashDirty)
        inst:ListenForEvent("attunedresurrectordirty", OnAttunedResurrectorDirty)
        inst:ListenForEvent("iswardrobepopupvisibledirty", OnIsWardrobePopUpVisibleDirty)
        inst:ListenForEvent("isgiftitempopupvisibledirty", OnIsGiftItemPopUpVisibleDirty)

        OnIsTakingFireDamageDirty(inst)
        OnTemperatureDirty(inst)
        if inst._parent ~= nil then
            inst._oldhealthpercent = inst.maxhealth:value() > 0 and inst.currenthealth:value() / inst.maxhealth:value() or 0
            inst._oldhungerpercent = inst.maxhunger:value() > 0 and inst.currenthunger:value() / inst.maxhunger:value() or 0
            inst._oldsanitypercent = inst.maxsanity:value() > 0 and inst.currentsanity:value() / inst.maxsanity:value() or 0
            inst._oldbeavernesspercent = inst.currentbeaverness:value() * .01
            inst._oldmoisture = inst.moisture:value()
            UpdateAnimOverrideSanity(inst._parent)
        end
    end

    inst:ListenForEvent("builder.build", OnBuildEvent)
    inst:ListenForEvent("builder.damaged", OnBuilderDamagedEvent)
    inst:ListenForEvent("builder.learnrecipe", OnLearnRecipeEvent)
    inst:ListenForEvent("repair.repair", OnRepairEvent)
    inst:ListenForEvent("giftsdirty", OnGiftsDirty)
    inst:ListenForEvent("playercameradirty", OnPlayerCameraDirty)
    inst:ListenForEvent("playercamerasnap", OnPlayerCameraSnap)
    inst:ListenForEvent("playerfadedirty", OnPlayerFadeDirty)
    inst:ListenForEvent("wormholetraveldirty", OnWormholeTravelDirty)
    inst:ListenForEvent("leader.makefriend", OnMakeFriendEvent)
    inst:ListenForEvent("morguedirty", OnMorgueDirty)
    OnGiftsDirty(inst)
    OnGhostModeDirty(inst)
    OnPlayerHUDDirty(inst)
    OnPlayerCameraDirty(inst)
    OnIsWardrobePopUpVisibleDirty(inst)
    OnIsGiftItemPopUpVisibleDirty(inst)

    --Fade is initialized by OnPlayerActivated in gamelogic.lua
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

    --Health variables
    inst._oldhealthpercent = 1
    inst.currenthealth = net_ushortint(inst.GUID, "health.currenthealth", "healthdirty")
    inst.maxhealth = net_ushortint(inst.GUID, "health.maxhealth", "healthdirty")
    inst.healthpenalty = net_byte(inst.GUID, "health.penalty", "healthdirty")
    inst.istakingfiredamage = net_bool(inst.GUID, "health.takingfiredamage", "istakingfiredamagedirty")
    inst.issleephealing = net_bool(inst.GUID, "health.healthsleep")
    inst.ishealthpulse = net_bool(inst.GUID, "health.dodeltaovertime", "healthdirty")
    inst.currenthealth:set(100)
    inst.maxhealth:set(100)

    --Hunger variables
    inst._oldhungerpercent = 1
    inst.currenthunger = net_ushortint(inst.GUID, "hunger.current", "hungerdirty")
    inst.maxhunger = net_ushortint(inst.GUID, "hunger.max", "hungerdirty")
    inst.ishungerpulse = net_bool(inst.GUID, "hunger.dodeltaovertime", "hungerdirty")
    inst.currenthunger:set(100)
    inst.maxhunger:set(100)

    --Sanity variables
    inst._oldsanitypercent = 1
    inst.currentsanity = net_ushortint(inst.GUID, "sanity.current", "sanitydirty")
    inst.maxsanity = net_ushortint(inst.GUID, "sanity.max", "sanitydirty")
    inst.sanitypenalty = net_byte(inst.GUID, "sanity.penalty", "sanitydirty")
    inst.sanityratescale = net_tinybyte(inst.GUID, "sanity.ratescale")
    inst.issanitypulse = net_bool(inst.GUID, "sanity.dodeltaovertime", "sanitydirty")
    inst.issanityghostdrain = net_bool(inst.GUID, "sanity.ghostdrain")
    inst.currentsanity:set(100)
    inst.maxsanity:set(100)

    --Beaverness variables
    inst._oldbeavernesspercent = 1
    inst.currentbeaverness = net_byte(inst.GUID, "beaverness.current", "beavernessdirty")
    inst.isbeavernesspulse = net_bool(inst.GUID, "beaverness.dodeltaovertime", "beavernessdirty")
    inst.currentbeaverness:set(100)

    --Temperature variables
    inst._oldtemperature = TUNING.STARTING_TEMP
    inst.currenttemperature = inst._oldtemperature
    inst.currenttemperaturedata = net_byte(inst.GUID, "temperature.current", "temperaturedirty")
    SetTemperature(inst, inst.currenttemperature)

    --Moisture variables
    inst._oldmoisture = 0
    inst.moisture = net_ushortint(inst.GUID, "moisture.moisture", "moisturedirty")
    inst.maxmoisture = net_ushortint(inst.GUID, "moisture.maxmoisture")
    inst.moistureratescale = net_tinybyte(inst.GUID, "moisture.ratescale", "moisturedirty")
    inst.maxmoisture:set(100)

    --PlayerController variables
    inst._pausepredictiontask = nil
    inst.pausepredictionframes = net_tinybyte(inst.GUID, "playercontroller.pausepredictionframes", "pausepredictionframesdirty")
    inst.iscontrollerenabled = net_bool(inst.GUID, "playercontroller.enabled")
    inst.iscontrollerenabled:set(true)

    --Player HUD variables
    inst.ishudvisible = net_bool(inst.GUID, "playerhud.isvisible", "playerhuddirty")
    inst.ismapcontrolsvisible = net_bool(inst.GUID, "playerhud.ismapcontrolsvisible", "playerhuddirty")
    inst.isactionsvisible = net_bool(inst.GUID, "playerhud.isactionsvisible")
    inst.ishudvisible:set(true)
    inst.ismapcontrolsvisible:set(true)
    inst.isactionsvisible:set(true)

    --Player camera variables
    inst.cameradistance = net_smallbyte(inst.GUID, "playercamera.distance", "playercameradirty")
    inst.iscamerazoomed = net_bool(inst.GUID, "playercamera.iscamerazoomed", "playercameradirty")
    inst.camerasnap = net_bool(inst.GUID, "playercamera.snap", "playercamerasnap")
    inst.camerashakemode = net_tinybyte(inst.GUID, "playercamera.shakemode", "playercamerashake")
    inst.camerashaketime = net_byte(inst.GUID, "playercamera.shaketime")
    inst.camerashakespeed = net_byte(inst.GUID, "playercamera.shakespeed")
    inst.camerashakescale = net_byte(inst.GUID, "playercamera.shakescale")

    --Player front end variables
    inst.isfadein = net_bool(inst.GUID, "frontend.isfadein", "playerfadedirty")
    inst.fadetime = net_smallbyte(inst.GUID, "frontend.fadetime", "playerfadedirty")
    inst.screenflash = net_tinybyte(inst.GUID, "frontend.screenflash", "playerscreenflashdirty")
    inst.wormholetravelevent = net_tinybyte(inst.GUID, "frontend.wormholetravel", "wormholetraveldirty")
    inst.isfadein:set(true)

    --Builder variables
    inst.buildevent = net_event(inst.GUID, "builder.build")
    inst.builderdamagedevent = net_event(inst.GUID, "builder.damaged")
    inst.learnrecipeevent = net_event(inst.GUID, "builder.learnrecipe")
    inst.techtrees = deepcopy(TECH.NONE)
    inst.sciencebonus = net_tinybyte(inst.GUID, "builder.science_bonus")
    inst.magicbonus = net_tinybyte(inst.GUID, "builder.magic_bonus")
    inst.ancientbonus = net_tinybyte(inst.GUID, "builder.ancient_bonus")
    inst.ingredientmod = net_tinybyte(inst.GUID, "builder.ingredientmod")
    inst.sciencelevel = net_tinybyte(inst.GUID, "builder.accessible_tech_trees.SCIENCE", "techtreesdirty")
    inst.magiclevel = net_tinybyte(inst.GUID, "builder.accessible_tech_trees.MAGIC", "techtreesdirty")
    inst.ancientlevel = net_tinybyte(inst.GUID, "builder.accessible_tech_trees.ANCIENT", "techtreesdirty")
    inst.isfreebuildmode = net_bool(inst.GUID, "builder.freebuildmode", "recipesdirty")
    inst.recipes = {}
    inst.bufferedbuilds = {}
    for k, v in pairs(AllRecipes) do
        if IsRecipeValid(v.name) then
            inst.recipes[k] = net_bool(inst.GUID, "builder.recipes["..k.."]", "recipesdirty")
            inst.bufferedbuilds[k] = net_bool(inst.GUID, "builder.buffered_builds["..k.."]", "bufferedbuildsdirty")
        end
    end
    inst.ingredientmod:set(INGREDIENT_MOD[1])
    inst.sciencelevel:set(inst.techtrees.SCIENCE)
    inst.magiclevel:set(inst.techtrees.MAGIC)
    inst.ancientlevel:set(inst.techtrees.ANCIENT)

    --Repair variables
    inst.repairevent = net_event(inst.GUID, "repair.repair")

    --Wardrobe variables
    inst.iswardrobepopupvisible = net_bool(inst.GUID, "wardrobe.iswardrobepopupvisible", "iswardrobepopupvisibledirty")

    --GiftReceiver variables
    inst.hasgift = net_bool(inst.GUID, "giftreceiver.hasgift", "giftsdirty")
    inst.hasgiftmachine = net_bool(inst.GUID, "giftreceiver.hasgiftmachine", "giftsdirty")
    inst.isgiftitempopupvisible = net_bool(inst.GUID, "giftreceiver.isgiftitempopupvisible", "isgiftitempopupvisibledirty")

    --Combat variables
    inst.lastcombattarget = net_entity(inst.GUID, "combat.lasttarget")
    inst.canattack = net_bool(inst.GUID, "combat.canattack")
    inst.minattackperiod = net_float(inst.GUID, "combat.minattackperiod")
    inst.attackedpulseevent = net_event(inst.GUID, "combat.attackedpulse")
    inst.isattackedbydanger = net_bool(inst.GUID, "combat.isattackedbydanger")
    inst.canattack:set(true)
    inst.minattackperiod:set(4)

    --Leader variables
    inst.makefriendevent = net_event(inst.GUID, "leader.makefriend")

    --Stategraph variables
    inst.isperformactionsuccess = net_bool(inst.GUID, "sg.isperformactionsuccess", "isperformactionsuccessdirty")
    inst.isghostmode = net_bool(inst.GUID, "sg.isghostmode", "isghostmodedirty")

    --Locomotor variables
    inst.runspeed = net_float(inst.GUID, "locomotor.runspeed")
    inst.externalspeedmultiplier = net_float(inst.GUID, "locomotor.externalspeedmultiplier")
    inst.runspeed:set(TUNING.WILSON_RUN_SPEED)
    inst.externalspeedmultiplier:set(1)

    --Morgue variables
    inst.isdeathbypk = net_bool(inst.GUID, "morgue.isdeathbypk", "morguedirty")
    inst.deathcause = net_string(inst.GUID, "morgue.deathcause")

    --Delay net listeners until after initial values are deserialized
    inst:DoTaskInTime(0, RegisterNetListeners)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst._refreshtask = nil
        inst._bufferedbuildspreview = {}

        --Client interface
        inst.OnEntityReplicated = OnEntityReplicated
        inst.BufferBuild = BufferBuild

        return inst
    end

    --Server interface
    inst.SetValue = SetValue
    inst.PushPausePredictionFrames = PushPausePredictionFrames
    inst.AddMorgueRecord = AddMorgueRecord
    inst.SetTemperature = SetTemperature
    inst.SetGhostMode = SetGhostMode
    inst.ShowActions = ShowActions
    inst.ShowHUD = ShowHUD
    inst.ShowWardrobePopUp = ShowWardrobePopUp
    inst.ShowGiftItemPopUp = ShowGiftItemPopUp
    inst.EnableMapControls = EnableMapControls

    inst.persists = false

    return inst
end

return Prefab("player_classified", fn)