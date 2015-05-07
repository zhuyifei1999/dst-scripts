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
    --print("OnActivated!")
    if doer:HasTag("player") then
        ProfileStatsSet("wormhole_used", true)

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
        doer:DoTaskInTime(5, doer.PushEvent, "wormholespit") --for wisecracker
        --Sounds are triggered in player's stategraph
    elseif inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/common/teleportworm/swallow")
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
    if inst.teleporting == nil and inst.sg:HasStateTag("open") then
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
    inst.components.inventory:DropItem(item)
    inst.components.teleporter:Activate(item)

    local other = inst.components.teleporter.targetTeleporter or inst
    item:RemoveFromScene()
    other:AddChild(item)
    other.teleporting = (other.teleporting or 0) + 1
    other:DoTaskInTime(.5, onitemarrive, item)
    other:DoTaskInTime(1.5, ondoneteleporting)
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

    --trader, alltrader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")
    inst:AddTag("alltrader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetStateGraph("SGwormhole")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
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
    inst.components.trader.acceptnontradable = true
    inst.components.trader.onaccept = onaccept
    inst.components.trader.deleteitemonaccept = false

    return inst
end

return Prefab("common/wormhole", fn, assets)
