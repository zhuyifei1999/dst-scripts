local assets =
{
    Asset("ANIM", "anim/teleporter_worm.zip"),
    Asset("ANIM", "anim/teleporter_sickworm_build.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local function onsave(inst, data)
    data.usesleft = inst.usesleft
end

local function onload(inst, data)
    if data and data.usesleft then
        inst.usesleft = data.usesleft
    end
end

local function GetStatus(inst)
    return inst.sg.currentstate.name ~= "idle" and "OPEN" or "CLOSED"
end

local function incrementuses(inst)
    local sisterworm = inst.components.teleporter.targetTeleporter 
    inst.usesleft = inst.usesleft - 1
    print("Worm Uses Left:", inst.usesleft)
    if inst.usesleft <= 0 then
        inst.sg:GoToState("death")
        inst.components.teleporter.targetTeleporter = nil
    end

    if sisterworm then
        sisterworm.usesleft = sisterworm.usesleft - 1
        if sisterworm.usesleft <= 0 then
            sisterworm.sg:GoToState("death")
            sisterworm.components.teleporter.targetTeleporter = nil
        end
    end
end

local function oncameraarrive(doer)
    doer:SnapCamera()
    doer:ScreenFade(true, 2)
end

local function ondoerarrive(doer)
    doer.sg:GoToState("jumpout")
    if doer.components.sanity ~= nil then
        doer.components.sanity:DoDelta(-TUNING.SANITY_MED)
    end
end

local function ondoneteleporting(other)
    if other.teleporting ~= nil then
        if other.teleporting > 1 then
            other.teleporting = other.teleporting - 1
        else
            other.teleporting = nil
            if not other.components.playerprox:IsPlayerClose() then
                other.sg:GoToState("closing")
            end
        end
    end
end

local function OnActivate(inst, doer)
    if inst.components.teleporter.targetTeleporter and inst.usesleft > 0 then
        if doer:HasTag("player") then
            ProfileStatsSet("wormhole_ltd_used", true)

            local other = inst.components.teleporter.targetTeleporter
            if other ~= nil then
                DeleteCloseEntsWithTag("WORM_DANGER", other, 15)
                other.teleporting = (other.teleporting or 0) + 1
                other:DoTaskInTime(4.5, ondoneteleporting)
            end

            if doer.components.talker ~= nil then
                doer.components.talker:ShutUp()
            end

            doer:ScreenFade(false)
            doer:DoTaskInTime(3, oncameraarrive)
            doer:DoTaskInTime(4, ondoerarrive)
            inst:DoTaskInTime(4.5, incrementuses)
            doer:DoTaskInTime(5, doer.PushEvent, "wormholespit") -- for wisecracker
            --Sounds are triggered in player's stategraph
        elseif doer.SoundEmitter ~= nil then
            inst.SoundEmitter:PlaySound("dontstarve/common/teleportworm/swallow")
        end
    end
end

local function OnActivateOther(inst, other, doer)
    if not other.sg:HasStateTag("open") then
        other.sg:GoToState("opening")
    end
end

local function onnear(inst)
    if inst.components.teleporter.targetTeleporter ~= nil and not inst.sg:HasStateTag("open") then
        inst.sg:GoToState("opening")
    end
end

local function onfar(inst)
    if inst.teleporting == nil then
        inst.sg:GoToState("closing")
    end
end

local function onaccept(reciever, giver, item)
    if giver and giver.components.inventory then
        giver.components.inventory:DropItem(item)
    end
    if reciever and reciever.components.teleporter then
        ProfileStatsSet("wormhole_ltd_accept_item", item.prefab)
        reciever.components.teleporter:Activate(item)
    end
end

local function makewormhole(uses)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon("wormhole_sick.png")

        inst.AnimState:SetBank("teleporter_worm")
        inst.AnimState:SetBuild("teleporter_sickworm_build")
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.usesleft = uses

        inst:SetStateGraph("SGwormhole_limited")

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = GetStatus
        inst.components.inspectable.nameoverride = "WORMHOLE_LIMITED"
        inst.components.inspectable:RecordViews()

        inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(4, 5)
        inst.components.playerprox.onnear = onnear
        inst.components.playerprox.onfar = onfar

        inst.teleporting = nil

        inst:AddComponent("teleporter")
        inst.components.teleporter.onActivate = OnActivate
        inst.components.teleporter.onActivateOther = OnActivateOther
        inst.components.teleporter.offset = 0

        inst:AddComponent("inventory")

        inst:AddComponent("trader")
        inst.components.trader.onaccept = onaccept

        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end

    return Prefab("common/wormhole_limited_"..uses, fn, assets)
end

return makewormhole(1)