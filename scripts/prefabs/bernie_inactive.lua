--Inventory item version
local assets =
{
    Asset("ANIM", "anim/bernie.zip"),
    Asset("ANIM", "anim/bernie_build.zip"),
}

local prefabs =
{
    "beardhair",
    "beefalowool",
    "silk",
    "small_puff",
}

local function getstatus(inst)
    return inst.components.fueled:IsEmpty() and "BROKEN" or "GENERIC"
end

local function activate(inst)
    if inst._activatetask == nil then
        inst._activatetask = inst:DoPeriodicTask(1, inst._onplayergoinsane)
    end
end

local function deactivate(inst)
    if inst._activatetask ~= nil then
        inst._activatetask:Cancel()
        inst._activatetask = nil
    end
end

local function IsValidLink(inst, player)
    return player:HasTag("pyromaniac") and player.bernie == nil
end

local function dodecay(inst)
    if inst.components.lootdropper == nil then
        inst:AddComponent("lootdropper")
    end
    inst.components.lootdropper:SpawnLootPrefab("beardhair")
    inst.components.lootdropper:SpawnLootPrefab("beefalowool")
    inst.components.lootdropper:SpawnLootPrefab("silk")
    SpawnPrefab("small_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function startdecay(inst)
    if inst._decaytask == nil then
        inst._decaytask = inst:DoTaskInTime(TUNING.BERNIE_DECAY_TIME, dodecay)
        inst._decaystart = GetTime()
    end
end

local function stopdecay(inst)
    if inst._decaytask ~= nil then
        inst._decaytask:Cancel()
        inst._decaytask = nil
        inst._decaystart = nil
    end
end

local function onsave(inst, data)
    if inst._decaystart ~= nil then
        local time = GetTime() - inst._decaystart
        if time > 0 then
            data.decaytime = time
        end
    end
end

local function onload(inst, data)
    if inst._decaytask ~= nil and data ~= nil and data.decaytime ~= nil then
        local remaining = math.max(0, TUNING.BERNIE_DECAY_TIME - data.decaytime)
        inst._decaytask:Cancel()
        inst._decaytask = inst:DoTaskInTime(remaining, dodecay)
        inst._decaystart = GetTime() + remaining - TUNING.BERNIE_DECAY_TIME
    end
end

local function updatestate(inst)
    if inst.components.fueled:IsEmpty() then
        if not inst._isdeadstate then
            inst._isdeadstate = true
            inst.AnimState:PlayAnimation("dead_loop")
            inst.components.inventoryitem:ChangeImageName("bernie_dead")
        end
    elseif inst._isdeadstate then
        inst._isdeadstate = nil
        inst.AnimState:PlayAnimation("inactive")
        inst.components.inventoryitem:ChangeImageName("bernie_dead")
    end

    if inst._playerlink ~= nil and
        not inst.components.fueled:IsEmpty() and
        inst.components.inventoryitem.owner == nil then
        activate(inst)
    else
        deactivate(inst)
    end
end

local function tryreanimate(inst)
    if inst._playerlink ~= nil and
        inst._playerlink.bernie == nil and
        inst._playerlink.components.sanity:IsCrazy() and
        inst._playerlink.components.leader ~= nil and
        inst.components.inventoryitem.owner == nil and
        not inst.components.fueled:IsEmpty() and
        inst:GetDistanceSqToInst(inst._playerlink) < 256 --[[16 * 16]] then

        local active = SpawnPrefab("bernie_active")
        if active ~= nil then
            --Transform fuel % into health.
            active.components.health:SetPercent(inst.components.fueled:GetPercent())
            active.Transform:SetPosition(inst.Transform:GetWorldPosition())
            active:LinkToPlayer(inst._playerlink)
            inst:Remove()
        end
    end
end

local function linktoplayer(inst, player)
    if player ~= nil and IsValidLink(inst, player) then
        inst:ListenForEvent("onremove", inst._onremoveplayer, player)
        inst:ListenForEvent("goinsane", inst._onplayergoinsane, player)
        inst._playerlink = player
        player.bernie_bears[inst] = true
    end
end

local function unlink(inst)
    if inst._playerlink ~= nil then
        inst:RemoveEventCallback("onremove", inst._onremoveplayer, inst._playerlink)
        inst:RemoveEventCallback("goinsane", inst._onplayergoinsane, inst._playerlink)
        inst._playerlink.bernie_bears[inst] = nil
        inst._playerlink = nil
    end
end

local function storeincontainer(inst, container)
    if container ~= nil and container.components.container ~= nil then
        inst:ListenForEvent("onopen", inst._ontogglecontainer, container)
        inst:ListenForEvent("onclose", inst._ontogglecontainer, container)
        inst:ListenForEvent("onremove", inst._onremovecontainer, container)
        inst._container = container
    end
end

local function unstore(inst)
    if inst._container ~= nil then
        inst:RemoveEventCallback("onopen", inst._ontogglecontainer, inst._container)
        inst:RemoveEventCallback("onclose", inst._ontogglecontainer, inst._container)
        inst:RemoveEventCallback("onremove", inst._onremovecontainer, inst._container)
        inst._container = nil
    end
end

local function topocket(inst, owner)
    stopdecay(inst)
    deactivate(inst)
    if inst._container ~= owner then
        unstore(inst)
        storeincontainer(inst, owner)
    end
    if owner.components.container ~= nil then
        owner = owner.components.container.opener
    end
    if inst._playerlink ~= owner then
        unlink(inst)
        linktoplayer(inst, owner)
        updatestate(inst)
    end
end

local function toground(inst)
    unstore(inst)
    if inst._playerlink == nil then
        startdecay(inst)
    elseif not inst.components.fueled:IsEmpty() then
        activate(inst)
    end
end

local function refresh(inst)
    if inst._playerlink == nil then
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil then
            if owner.components.container ~= nil then
                owner = owner.components.container.opener
            end
            linktoplayer(inst, owner)
            updatestate(inst)
        end
    elseif not IsValidLink(inst, inst._playerlink) then
        unlink(inst)
        updatestate(inst)
        if inst.components.inventoryitem.owner == nil then
            startdecay(inst)
        end
    end
end

local function externallinktoplayer(inst, player)
    linktoplayer(inst, player)
    updatestate(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bernie")
    inst.AnimState:SetBuild("bernie_build")
    inst.AnimState:PlayAnimation("inactive")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._isdeadstate = nil
    inst._playerlink = nil
    inst._container = nil
    inst._decaytask = nil
    inst._decaystart = nil
    inst._activatetask = nil

    inst._onremoveplayer = function() 
        unlink(inst)
        updatestate(inst)
        if inst.components.inventoryitem.owner == nil then
            startdecay(inst)
        end
    end

    inst._onplayergoinsane = function()
        tryreanimate(inst)
    end

    inst._ontogglecontainer = function(container)
        topocket(inst, container)
    end

    inst._onremovecontainer = function()
        unstore(inst)
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("inventoryitem")

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.BERNIE_FUEL)
    inst.components.fueled:SetSectionCallback(function() updatestate(inst) end)

    updatestate(inst)
    startdecay(inst)

    inst:ListenForEvent("onputininventory", topocket)
    inst:ListenForEvent("ondropped", toground)

    MakeHauntableLaunch(inst)

    inst.OnLoad = onload
    inst.OnSave = onsave
    inst.OnRemoveEntity = unlink
    inst.Refresh = refresh
    inst.LinkToPlayer = externallinktoplayer

    return inst
end

return Prefab("common/bernie_inactive", fn, assets, prefabs)
