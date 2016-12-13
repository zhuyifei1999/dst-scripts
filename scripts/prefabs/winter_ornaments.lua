local assets =
{
    Asset("ANIM", "anim/winter_ornaments.zip"),
}

local BLINK_PERIOD = 1.2

local NUM_BASIC_ORNAMENT = 8
local NUM_FANCY_ORNAMENT = 4
local NUM_LIGHT_ORNAMENT = 4

local ORNAMENT_GOLD_VALUE =
{
    ["basic"] = 1,
    ["fancy"] = 2,
    ["light"] = 3,
}

function GetAllWinterOrnamentPrefabs()
    local decor = {}
    for i = 1, NUM_BASIC_ORNAMENT do
        table.insert(decor, "winter_ornament_plain" .. tostring(i))
    end
    for i = 1, NUM_FANCY_ORNAMENT do
        table.insert(decor, "winter_ornament_fancy" .. tostring(i))
    end
    for i = 1, NUM_LIGHT_ORNAMENT do
        table.insert(decor, "winter_ornament_light" .. tostring(i))
    end
    return decor
end

function GetRandomBasicWinterOrnament()
    return "winter_ornament_plain"..math.random(NUM_BASIC_ORNAMENT)
end

function GetRandomFancyWinterOrnament()
    return "winter_ornament_fancy"..math.random(NUM_FANCY_ORNAMENT)
end

function GetRandomLightWinterOrnament()
    return "winter_ornament_light"..math.random(NUM_LIGHT_ORNAMENT)
end

local function updatelight(inst, data)
    if data ~= nil and data.name == "blink" then
        inst.ornamentlighton = not inst.ornamentlighton
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner then
            owner:PushEvent("updatelight", inst)
        else
            inst.Light:Enable(inst.ornamentlighton)
            inst.AnimState:PlayAnimation(inst.winter_ornamentid .. (inst.ornamentlighton and "_on" or "_off"))
        end
        if not inst.components.timer:TimerExists("blink") then
            inst.components.timer:StartTimer("blink", BLINK_PERIOD)
        end
    end
end

local function ondropped(inst)
    inst.ornamentlighton = false
    updatelight(inst, {name="blink"})
    inst.components.fueled:StartConsuming()
end

local function onpickup(inst, by)
    if by ~= nil and by:HasTag("winter_tree") then
        if not inst.components.timer:TimerExists("blink") then
            inst.ornamentlighton = false
            updatelight(inst, {name="blink"})
        end
        inst.components.fueled:StartConsuming()
    else
        inst.ornamentlighton = false
        inst.Light:Enable(false)
        inst.components.timer:StopTimer("blink")
        if by ~= nil and by:HasTag("lamp") then
            inst.components.fueled:StartConsuming()
        else
            inst.components.fueled:StopConsuming()
        end
    end
end

local function onentitywake(inst)
    if inst.components.timer:IsPaused("blink") then
        inst.components.timer:ResumeTimer("blink")
    else
        updatelight(inst, {name="blink"})
    end
end

local function onentitysleep(inst)
    inst.components.timer:PauseTimer("blink")
end

local function ondepleted(inst)
    inst.ornamentlighton = false
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner ~= nil then
        owner:PushEvent("updatelight", inst)
    end
    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation(inst.winter_ornamentid.."_off")
    inst.components.timer:StopTimer("blink")
    inst.components.fueled:StopConsuming()
    inst.components.inventoryitem:SetOnDroppedFn(nil)
    inst.components.inventoryitem:SetOnPutInInventoryFn(nil)
    inst.OnEntitySleep = nil
    inst.OnEntityWake = nil
    inst.OnSave = nil
    if inst.components.fuel ~= nil then
        inst:RemoveComponent("fuel")
    end
end

local function onsave(inst, data)
    data.ornamentlighton = inst.ornamentlighton

    -------------------------------------------------------------------------
    --V2C: #TODO #REMOVE temporary fix for previously stackable winter lights
    if inst._unstack ~= nil and data.stackable == nil then
        data.stackable = { stack = inst._unstack }
    end
    -------------------------------------------------------------------------
end

local function onload(inst, data)
    if inst.components.fueled:IsEmpty() then
        ondepleted(inst)
    elseif data ~= nil then
        inst.ornamentlighton = data.ornamentlighton
    end

    -------------------------------------------------------------------------
    --V2C: #TODO #REMOVE temporary fix for previously stackable winter lights
    if inst.components.stackable == nil and
        data ~= nil and
        data.stackable ~= nil and
        data.stackable.stack ~= nil and
        data.stackable.stack > 1 then
        inst._unstack = data.stackable.stack
        inst:DoTaskInTime(0, function()
            local x, y, z = inst.Transform:GetWorldPosition()
            local fuel = inst.components.fueled ~= nil and inst.components.fueled.currentfuel or nil
            for i = 2, inst._unstack do
                local dupe = SpawnPrefab(inst.prefab)
                if fuel ~= nil and dupe.components.fueled ~= nil then
                    dupe.components.fueled:InitializeFuelLevel(fuel)
                    if dupe.components.fueled:IsEmpty() then
                        ondepleted(dupe)
                    end
                end
                dupe.components.inventoryitem:DoDropPhysics(x, 0, z, true, .5)
            end
            inst._unstack = nil
        end)
    end
    -------------------------------------------------------------------------
end

local function MakeOrnament(ornamentid, lightdata)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst, 0.1)

        inst.AnimState:SetBank("winter_ornaments")
        inst.AnimState:SetBuild("winter_ornaments")

        inst:AddTag("winter_ornament")
        inst:AddTag("molebait")
        inst:AddTag("cattoy")

        inst.winter_ornamentid = ornamentid

        if lightdata then
            inst:SetPrefabNameOverride("winter_ornamentlight")

            inst.entity:AddLight()
            inst.Light:SetFalloff(0.7)
            inst.Light:SetIntensity(.5)
            inst.Light:SetRadius(0.5)
            inst.Light:SetColour(lightdata.colour.x, lightdata.colour.y, lightdata.colour.z)
            inst.Light:Enable(false)

            inst:AddTag("lightbattery")

            inst.AnimState:PlayAnimation(tostring(ornamentid).."_on")
        else
            inst:SetPrefabNameOverride("winter_ornament")

            inst.AnimState:PlayAnimation(tostring(ornamentid))
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")

        inst:AddComponent("tradable")
        inst.components.tradable.goldvalue = ORNAMENT_GOLD_VALUE[string.sub(ornamentid, 1, 5)] or 1

        if lightdata then
            inst:AddComponent("fueled")
            inst.components.fueled.fueltype = FUELTYPE.USAGE
            inst.components.fueled.no_sewing = true
            inst.components.fueled:InitializeFuelLevel(160 * TUNING.TOTAL_DAY_TIME)
            inst.components.fueled:SetDepletedFn(ondepleted)
            inst.components.fueled:StartConsuming()

            inst:AddComponent("timer")
            inst:ListenForEvent("timerdone", updatelight)

            inst:AddComponent("fuel")
            inst.components.fuel.fuelvalue = TUNING.MED_LARGE_FUEL
            inst.components.fuel.fueltype = FUELTYPE.CAVE

            inst.components.inventoryitem:SetOnDroppedFn(ondropped)
            inst.components.inventoryitem:SetOnPutInInventoryFn(onpickup)

            inst.OnEntitySleep = onentitysleep
            inst.OnEntityWake = onentitywake
            inst.OnSave = onsave
            inst.OnLoad = onload

            inst.ornamentlighton = math.random() < .5
            inst.components.timer:StartTimer("blink", math.random() * BLINK_PERIOD)
        else
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        end

        ---------------------
        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab("winter_ornament_"..tostring(ornamentid), fn, assets, prefabs)
end

local ornament = {}
for i = 1, NUM_BASIC_ORNAMENT do
    table.insert(ornament, MakeOrnament("plain"..i))
end
for i = 1, NUM_FANCY_ORNAMENT do
    table.insert(ornament, MakeOrnament("fancy"..i))
end

table.insert(ornament, MakeOrnament("light1", {colour=Vector3(1,.1,.1)}))
table.insert(ornament, MakeOrnament("light2", {colour=Vector3(.1,1,.1)}))
table.insert(ornament, MakeOrnament("light3", {colour=Vector3(.5,.5,1)}))
table.insert(ornament, MakeOrnament("light4", {colour=Vector3(1,1,1)}))

return unpack(ornament)
