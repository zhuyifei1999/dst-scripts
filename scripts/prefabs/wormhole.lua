local assets =
{
    Asset("ANIM", "anim/teleporter_worm.zip"),
    Asset("ANIM", "anim/teleporter_worm_build.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local function GetStatus(inst)
    return inst.sg.currentstate.name ~= "idle" and "OPEN" or nil
end

local function oncameraarrive(doer)
    doer:SnapCamera()
    doer:ScreenFade(true, 2)
end

local function ondoerarrive(doer)
    doer:Show()
    doer.DynamicShadow:Enable(true)
    doer.sg:GoToState("jumpout")
    if doer.components.sanity ~= nil then
        doer.components.sanity:DoDelta(-TUNING.SANITY_MED)
    end
end

local function ondoerwormholespit(doer)
    doer:PushEvent("wormholespit")
    doer.components.health:SetInvincible(false)
    doer.components.playercontroller:Enable(true)
end

local function OnActivate(inst, doer)
    --print("OnActivated!")
    if doer:HasTag("player") then
        ProfileStatsSet("wormhole_used", true)
        doer.components.health:SetInvincible(true)
        doer.components.playercontroller:Enable(false)
        
        if inst.components.teleporter.targetTeleporter ~= nil then
            DeleteCloseEntsWithTag("WORM_DANGER", inst.components.teleporter.targetTeleporter, 15)
        end

        doer:Hide()
        doer.DynamicShadow:Enable(false)
        doer:ScreenFade(false)
        doer:DoTaskInTime(3, oncameraarrive)
        doer:DoTaskInTime(4, ondoerarrive)
        doer:DoTaskInTime(5, ondoerwormholespit)
        --Sounds are triggered in player's stategraph
    elseif doer.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/common/teleportworm/swallow")
    end
end

local function OnActivateOther(inst, other, doer)
    other.sg:GoToState("open")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("wormhole.png")

    inst.AnimState:SetBank("teleporter_worm")
    inst.AnimState:SetBuild("teleporter_worm_build")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetStateGraph("SGwormhole")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.components.inspectable:RecordViews()

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(4,5)
    inst.components.playerprox.onnear = function()
        if inst.components.teleporter.targetTeleporter ~= nil and not inst.sg:HasStateTag("open") then
            inst.sg:GoToState("opening")
        end
    end
    inst.components.playerprox.onfar = function()
        inst.sg:GoToState("closing")
    end

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnActivate
    inst.components.teleporter.onActivateOther = OnActivateOther
    inst.components.teleporter.offset = 0

    inst:AddComponent("inventory")

    inst:AddComponent("trader")
    inst.components.trader.onaccept = function(reciever, giver, item)
        -- pass this on to our better half
        reciever.components.inventory:DropItem(item)
        inst.components.teleporter:Activate(item)
    end

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    --print("Wormhole Spawned!")

    return inst
end

return Prefab("common/wormhole", fn, assets)