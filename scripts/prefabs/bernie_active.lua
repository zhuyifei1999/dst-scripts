local brain = require("brains/berniebrain")

local assets =
{
    Asset("ANIM", "anim/bernie.zip"),
    Asset("ANIM", "anim/bernie_build.zip"),
    Asset("SOUND", "sound/together.fsb"),
}

local prefabs =
{
    "bernie_inactive",
}

local function refreshcontainer(container)
    for i = 1, container:GetNumSlots() do
        local item = container:GetItemInSlot(i)
        if item ~= nil and item.prefab == "bernie_inactive" then
            item:Refresh()
        end
    end
end

local function goinactive(inst)
    local inactive = SpawnPrefab("bernie_inactive")
    if inactive ~= nil then
        --Transform health % into fuel.
        inactive.components.fueled:SetPercent(inst.components.health:GetPercent())
        inactive.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:Remove()
        inactive:LinkToPlayer(inst._playerlink)
        return inactive
    end
end

local function unlink(inst)
    inst._playerlink.bernie = nil
    local inv = inst._playerlink.components.inventory
    refreshcontainer(inv)

    local activeitem = inv:GetActiveItem()
    if activeitem ~= nil and activeitem.prefab == "bernie_inactive" then
        activeitem:Refresh()
    end

    for k, v in pairs(inv.opencontainers) do
        refreshcontainer(k.components.container)
    end
end

local function checksanity(inst)
    if inst._playerlink.components.sanity:IsSane() then
        inst._onplayergosane()
    end
end

local function linktoplayer(inst, player)
    inst.persists = false
    inst._playerlink = player
    player.bernie = inst
    player.components.leader:AddFollower(inst, true)
    for k, v in pairs(player.bernie_bears) do
        k:Refresh()
    end
    player:ListenForEvent("onremove", unlink, inst)
    inst:ListenForEvent("gosane", inst._onplayergosane, player)
    if inst._checksanitytask == nil then
        inst._checksanitytask = inst:DoPeriodicTask(1, checksanity)
        inst:ListenForEvent("onremove", inst._onremoveplayer, player)
    end
end

local function onpickup(inst, owner)
    local inactive = goinactive(inst)
    if inactive ~= nil then
        owner.components.inventory:GiveItem(inactive, nil, owner:GetPosition())
    end
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, 0.25)
    inst.DynamicShadow:SetSize(1, 0.5)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("bernie")
    inst.AnimState:SetBuild("bernie_build")
    inst.AnimState:PlayAnimation("idle_loop")

    inst:AddTag("smallcreature")
    inst:AddTag("companion")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._playerlink = nil
    inst._checksanitytask = nil

    inst._onremoveplayer = function()
        if inst._checksanitytask ~= nil then
            inst._checksanitytask:Cancel()
            inst._checksanitytask = nil
        end
    end

    inst._onplayergosane = function()
        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("deactivate")
        end
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.BERNIE_HEALTH)
    inst.components.health.nofadeout = true

    inst:AddComponent("inspectable")
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.BERNIE_SPEED
    inst:AddComponent("follower")
    inst.components.follower:KeepLeaderOnAttacked()
    inst.components.follower.keepdeadleader = true
    inst:AddComponent("combat")
    inst:AddComponent("timer")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPickupFn(onpickup)

    inst:SetStateGraph("SGbernie")
    inst:SetBrain(brain)

    inst.LinkToPlayer = linktoplayer
    inst.GoInactive = goinactive

    return inst
end

return Prefab("bernie_active", fn, assets, prefabs)
