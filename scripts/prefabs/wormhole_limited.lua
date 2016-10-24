local assets =
{
    Asset("ANIM", "anim/teleporter_worm.zip"),
    Asset("ANIM", "anim/teleporter_sickworm_build.zip"),
    Asset("SOUND", "sound/common.fsb"),
    Asset("MINIMAP_IMAGE", "wormhole_sick"),
}

local function onsave(inst, data)
    data.usesleft = inst.usesleft > 0 and inst.usesleft or nil
end

local function onload(inst, data)
    inst.usesleft = data ~= nil and data.usesleft or 0
end

local function GetStatus(inst)
    return inst.sg.currentstate.name ~= "idle" and "OPEN" or "CLOSED"
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
            if other.components.teleporter ~= nil and not other.components.playerprox:IsPlayerClose() then
                other.sg:GoToState("closing")
            end
        end
    end
end

local function onusedup(inst)
    inst.sg:GoToState("death")
end

local function OnActivate(inst, doer)
    if doer:HasTag("player") then
        ProfileStatsSet("wormhole_ltd_used", true)

        local other = inst.components.teleporter.targetTeleporter
        if other ~= nil then
            DeleteCloseEntsWithTag("WORM_DANGER", other, 15)
            other.teleporting = (other.teleporting or 0) + 1
        end

        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end

        doer:ScreenFade(false)
        doer:DoTaskInTime(3, oncameraarrive)
        doer:DoTaskInTime(4, ondoerarrive)
        doer:DoTaskInTime(5, doer.PushEvent, "wormholespit") -- for wisecracker
        --Sounds are triggered in player's stategraph

        if inst.usesleft > 1 then
            inst.usesleft = inst.usesleft - 1
            if other ~= nil then
                if other.usesleft > 1 then
                    other.usesleft = other.usesleft - 1
                end
                other:DoTaskInTime(4.5, ondoneteleporting)
            end
        else
            if inst.teleporting == nil then
                inst.sg:GoToState("closing")
            end
            inst.usesleft = 0
            inst.persists = false
            inst:RemoveComponent("teleporter")
            inst:RemoveComponent("trader")
            inst:DoTaskInTime(4.5, onusedup)
            if other ~= nil then
                other.usesleft = 0
                other.persists = false
                other:RemoveComponent("teleporter")
                other:RemoveComponent("trader")
                other:DoTaskInTime(4.5, onusedup)
            end
        end
    elseif inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/common/teleportworm/swallow")
    end
end

local function OnActivateByOther(inst, source, doer)
    if not inst.sg:HasStateTag("open") then
        inst.sg:GoToState("opening")
    end
end

local function onnear(inst)
    if inst.components.teleporter ~= nil and inst.components.teleporter.targetTeleporter ~= nil and not inst.sg:HasStateTag("open") then
        inst.sg:GoToState("opening")
    end
end

local function onfar(inst)
    if inst.teleporting == nil and inst.components.teleporter ~= nil and inst.sg:HasStateTag("open") then
        inst.sg:GoToState("closing")
    end
end

local function onitemarrive(other, item)
    if not item:IsValid() then
        return
    end

    other:RemoveChild(item)
    item:ReturnToScene()

    if item.Transform ~= nil then
        local x, y, z = item.Transform:GetWorldPosition()
        local angle = math.random() * 2 * PI
        if item.Physics ~= nil then
            item.Physics:Stop()
            if item:IsAsleep() then
                local radius = 2 + math.random() * .5
                item.Physics:Teleport(
                    x + math.cos(angle) * radius,
                    0,
                    z - math.sin(angle) * radius)
            else
                local bounce = item.components.inventoryitem ~= nil and not item.components.inventoryitem.nobounce
                local speed = (bounce and 3 or 4) + math.random() * .5
                item.Physics:Teleport(x, 0, z)
                item.Physics:SetVel(
                    speed * math.cos(angle),
                    bounce and speed * 3 or 0,
                    speed * math.sin(angle))
            end
        else
            local radius = 2 + math.random() * .5
            item.Transform:SetPosition(
                x + math.cos(angle) * radius,
                0,
                z - math.sin(angle) * radius)
        end
    end
end

local function onaccept(inst, giver, item)
    if inst.components.teleporter == nil then
        return
    end

    ProfileStatsSet("wormhole_ltd_accept_item", item.prefab)
    inst.components.inventory:DropItem(item)
    inst.components.teleporter:Activate(item)

    local other = inst.components.teleporter.targetTeleporter or inst
    item:RemoveFromScene()
    other:AddChild(item)
    other.teleporting = (other.teleporting or 0) + 1
    other:DoTaskInTime(.5, onitemarrive, item)
    other:DoTaskInTime(1.5, ondoneteleporting)
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

        --trader, alltrader (from trader component) added to pristine state for optimization
        inst:AddTag("trader")
        inst:AddTag("alltrader")

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
        inst.components.teleporter.onActivateByOther = OnActivateByOther
        inst.components.teleporter.offset = 0

        inst:AddComponent("inventory")

        inst:AddComponent("trader")
        inst.components.trader.acceptnontradable = true
        inst.components.trader.onaccept = onaccept
        inst.components.trader.deleteitemonaccept = false

        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end

    return Prefab("wormhole_limited_"..uses, fn, assets)
end

return makewormhole(1)
