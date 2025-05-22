local assets = {
    Asset("ANIM", "anim/wagpunk_floor_kit.zip"),
    Asset("INV_IMAGE", "wagpunk_floor_kit"),
}

local function CLIENT_CanDeployKit(inst, pt, mouseover, deployer, rotation)
    local x, y, z = pt:Get()
    if not TheWorld.Map:IsPointInWagPunkArena(x, y, z) then
        return false
    end

    local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
    if not TileGroupManager:IsOceanTile(tile) then
        return false
    end

    local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
    if not TheWorld.Map:HasAdjacentLandTile(tx, ty) then
        return false
    end

    local center_pt = Vector3(TheWorld.Map:GetTileCenterPoint(tx, ty))
    return TheWorld.Map:CanDeployDockAtPoint(center_pt, inst, mouseover)
end

local INDICATOR_MUST_TAGS = {"CLASSIFIED", "wagpunk_floor_placerindicator"}
local function on_deploy(inst, pt, deployer)
    if deployer ~= nil and deployer.SoundEmitter ~= nil then
        deployer.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage", { intensity = 0.8 })
    end

    local tx, ty, tz = TheWorld.Map:GetTileCenterPoint(pt.x, pt.y, pt.z)
    local tile_x, tile_y = TheWorld.Map:GetTileCoordsAtPoint(pt.x, pt.y, pt.z)

    local current_tile = nil
    local undertile = TheWorld.components.undertile
    if undertile ~= nil then
        current_tile = TheWorld.Map:GetTile(tile_x, tile_y)
    end

    TheWorld.Map:SetTile(tile_x, tile_y, WORLD_TILES.WAGSTAFF_FLOOR)
    -- Because of a terraforming callback in farming_manager.lua, the undertile gets cleared during SetTile.
    -- We can circumvent this for now by setting the undertile after SetTile.
    if undertile ~= nil and current_tile ~= nil then
        undertile:SetTileUnderneath(tile_x, tile_y, current_tile)
    end

    inst.components.stackable:Get():Remove()
    local ents = TheSim:FindEntities(tx, ty, tz, 1, INDICATOR_MUST_TAGS)
    for _, v in ipairs(ents) do
        v:Remove()
    end

    TheWorld:PushEvent("ms_wagpunk_floor_kit_deployed")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wagpunk_floor_kit")
    inst.AnimState:SetBuild("wagpunk_floor_kit")
    inst.AnimState:PlayAnimation("idle")

    inst.pickupsound = "wood"

    MakeInventoryFloatable(inst, "med", 0.2, 0.75)

    inst:AddTag("groundtile")
    inst:AddTag("deploykititem")
    inst:AddTag("usedeployspacingasoffset")

    inst._custom_candeploy_fn = CLIENT_CanDeployKit -- for DEPLOYMODE.CUSTOM

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -------------------------------------------------------
    inst:AddComponent("inspectable")

    -------------------------------------------------------
    inst:AddComponent("inventoryitem")

    -------------------------------------------------------
    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable.ondeploy = on_deploy

    -------------------------------------------------------
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    return inst
end

-------------------------------------------
-- wagpunk_floor_kit_placer

local function OnCanBuild(inst, mouse_blocked)
    inst.AnimState:SetMultColour(1, 1, 1, 1)
    inst:Show()
end

local function OnCannotBuild(inst, mouse_blocked)
    inst.AnimState:SetMultColour(.75, .25, .25, 1)
    inst:Show()
end
local function PlacerPostinit(inst)
    inst.deployhelper_key = "wagpunk_floor_kit"

    inst.components.placer.hide_inv_icon = false
    inst.components.placer.snap_to_tile = true
    inst.components.placer.oncanbuild = OnCanBuild
    inst.components.placer.oncannotbuild = OnCannotBuild
end

-------------------------------------------------------
-- wagpunk_floor_marker

local function UpdateNetvars(inst)
    if inst.updatenetvarstask ~= nil then -- Let this function repeat entry safe.
        inst.updatenetvarstask:Cancel()
        inst.updatenetvarstask = nil
    end

    local _world = TheWorld
    local wagpunk_floor_helper = _world.net and _world.net.components.wagpunk_floor_helper
    if not wagpunk_floor_helper then
        inst.updatenetvarstask = inst:DoTaskInTime(0, UpdateNetvars) -- Reschedule.
        return
    end

    wagpunk_floor_helper:TryToSetMarker(inst) -- May remove inst if it is in conflict.
end

local function fn_marker()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("CLASSIFIED")

    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, inst.Remove) -- Not meant for clients.

        return inst
    end

    inst:DoTaskInTime(0, UpdateNetvars)

    return inst
end

-----------------------------------------------------------
-- wagpunk_floor_placerindicator

local assets_placerindicator = {
    Asset("ANIM", "anim/wagpunk_floor_kit.zip"),
}

local function CreateFloorDecal()
    local inst = CreateEntity()

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.AnimState:SetBank("wagpunk_floor_kit_placer")
    inst.AnimState:SetBuild("wagpunk_floor_kit")
    inst.AnimState:PlayAnimation("anim")
    inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetMultColour(0.4, 0.5, 0.6, 0.6)

    return inst
end

local function OnEnableHelper(inst, enabled, recipename, placerinst)
    if enabled then
        inst.helper = CreateFloorDecal()
        inst.helper.entity:SetParent(inst.entity)

        inst.helper.placerinst = placerinst
    elseif inst.helper ~= nil then
        inst.helper:Remove()
        inst.helper = nil
    end
end

local function OnSave_placerindicator(inst, data)
    local rotation = inst.Transform:GetRotation()
    if rotation ~= 0 then
        data.rotation = rotation
    end
end
local function OnLoad_placerindicator(inst, data)
    if not data then
        return
    end

    if data.rotation then
        inst.Transform:SetRotation(data.rotation)
    end
end

local function fn_placerindicator()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("wagpunk_floor_placerindicator")

    --Dedicated server does not need deployhelper
    if not TheNet:IsDedicated() then
        local deployhelper = inst:AddComponent("deployhelper")
        deployhelper:AddKeyFilter("wagpunk_floor_kit")
        deployhelper.onenablehelper = OnEnableHelper
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnSave = OnSave_placerindicator
    inst.OnLoad = OnLoad_placerindicator

    return inst
end

return Prefab("wagpunk_floor_kit", fn, assets),
    MakePlacer("wagpunk_floor_kit_placer", "gridplacer", "gridplacer", "anim", true, nil, nil, nil, nil, nil, PlacerPostinit),
    Prefab("wagpunk_floor_marker", fn_marker),
    Prefab("wagpunk_floor_placerindicator", fn_placerindicator, assets_placerindicator)