require "prefabutil"
local easing = require("easing")

local assets =
{
    Asset("ANIM", "anim/firefighter.zip"),
    Asset("ANIM", "anim/firefighter_placement.zip"),
    Asset("ANIM", "anim/firefighter_meter.zip"),
}

local glow_assets =
{
    Asset("ANIM", "anim/firefighter_glow.zip"),
}

local prefabs =
{
    "snowball",
    "splash_snow_fx",
    "collapse_small",
    "firesuppressor_glow",
}

--Called from stategraph
local function LaunchProjectile(inst, targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()

    local projectile = SpawnPrefab("snowball")
    projectile.Transform:SetPosition(x, y, z)

    --V2C: scale the launch speed based on distance
    --     because 15 does not reach our max range.
    local dx = targetpos.x - x
    local dz = targetpos.z - z
    local rangesq = dx * dx + dz * dz
    local maxrange = TUNING.FIRE_DETECTOR_RANGE
    local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
    projectile.components.complexprojectile:SetHorizontalSpeed(speed)
    projectile.components.complexprojectile:SetGravity(-25)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
end

local function SpreadProtectionAtPoint(inst, firePos)
    inst.components.wateryprotection:SpreadProtectionAtPoint(firePos:Get())
end

local function OnFindFire(inst, firePos)
    if inst:IsAsleep() then
        inst:DoTaskInTime(1 + math.random(), SpreadProtectionAtPoint, firePos)
    else
        inst:PushEvent("putoutfire", { firePos = firePos })
    end
end

local WarningColours =
{
    green = { 163 / 255, 255 / 255, 186 / 255 },
    yellow = { 255 / 255, 228 / 255, 81 / 255 },
    red = { 255 / 255, 146 / 255, 146 / 255 },
}

local function GetWarningLevelLight(level)
    return (level == nil and "off")
        or (level <= 0 and "green")
        or (level <= TUNING.EMERGENCY_BURNT_NUMBER and "yellow")
        or "red"
end

local function SetWarningLevelLight(inst, level)
    local anim = GetWarningLevelLight(level)
    if inst._warninglevel ~= anim then
        inst._warninglevel = anim
        if WarningColours[anim] ~= nil then
            inst.Light:SetColour(unpack(WarningColours[anim]))
            inst.Light:Enable(true)
            inst._glow.AnimState:PlayAnimation(anim, true)
            inst._glow._ison:set(true)
        else
            inst.Light:Enable(false)
            inst._glow._ison:set(false)
        end
    end
end

local function TurnOff(inst, instant)
    inst.on = false
    inst.components.firedetector:Deactivate()

    if not inst:HasTag("fueldepleted") then 
        local randomizedStartTime = POPULATING
        inst:DoTaskInTime(0, inst.components.firedetector:ActivateEmergencyMode(randomizedStartTime)) -- this can be called from onload, so make sure everything is set up first
    end

    inst.components.fueled:StopConsuming()

    SetWarningLevelLight(inst, nil)
    inst.sg:GoToState(instant and "idle_off" or "turn_off")
end

local function TurnOn(inst, instant)
    inst.on = true
    local isemergency = inst.components.firedetector:IsEmergency()
    if not isemergency then
        local randomizedStartTime = POPULATING
        inst.components.firedetector:Activate(randomizedStartTime)
        SetWarningLevelLight(inst, 0)
    end
    inst.components.fueled:StartConsuming()
    inst.sg:GoToState(instant and "idle_on" or (inst.sg:HasStateTag("light") and "turn_on_light" or "turn_on"), isemergency == true--[[must not be nil]])
end

local function OnBeginEmergency(inst, level)
    SetWarningLevelLight(inst, math.huge)
    if not inst.on then
        inst.components.machine:TurnOn()
    end
end

local function OnEndEmergency(inst, level)
    if inst.on then
        inst.components.machine:TurnOff()
    end
end

local function OnBeginWarning(inst, level)
    SetWarningLevelLight(inst, level)
    if not inst.on then
        inst.sg:GoToState("light_on")
    end
end

local function OnUpdateWarning(inst, level)
    SetWarningLevelLight(inst, level)
    --inst:PushEvent("warninglevelchanged", { level = level })
end

local function OnEndWarning(inst, level)
    SetWarningLevelLight(inst, nil)
    if not inst.on then
        inst.sg:GoToState("light_off")
    end
end

local function OnFuelEmpty(inst)
    inst.components.machine:TurnOff()
end

local function OnAddFuel(inst)
    if inst.on == false then
        inst.components.machine:TurnOn()
    end
end

local function OnFuelSectionChange(new, old, inst)
    if inst._fuellevel ~= new then
        inst._fuellevel = new
        inst.AnimState:OverrideSymbol("swap_meter", "firefighter_meter", new)
    end
end

local function CanInteract(inst)
    return not inst.components.fueled:IsEmpty()
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.SoundEmitter:KillSound("firesuppressor_idle")
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    if not (inst:HasTag("burnt") or inst.sg:HasStateTag("busy")) then
        inst.sg:GoToState("hit", inst.sg:HasStateTag("light"))
    end
end

local function getstatus(inst, viewer)
    --if inst.on then
        return inst.components.fueled ~= nil
            and inst.components.fueled.currentfuel / inst.components.fueled.maxfuel <= .25
            and "LOWFUEL"
            or "ON"
    --else
        --return "OFF"
    --end
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("firesuppressor_idle")
end

local function OnRemoveEntity(inst)
    inst._glow:Remove()
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil and inst.components.burnable.onburnt ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

--V2C: Don't do this?
--     I believe all the affected components save their protected state already
--[[
local function OnLoadPostPass(inst, data)
    if not inst.components.fueled:IsEmpty() then
        inst.components.wateryprotection:SpreadProtection(inst, TUNING.FIRE_DETECTOR_RANGE, true)
    end
end]]

local function oninit(inst)
    inst._glow.Follower:FollowSymbol(inst.GUID, "swap_glow", 0, 0, 0)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("firesuppressor.png")

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("firefighter")
    inst.AnimState:SetBuild("firefighter")
    inst.AnimState:PlayAnimation("idle_off")
    inst.AnimState:OverrideSymbol("swap_meter", "firefighter_meter", 10)

    inst:AddTag("hasemergencymode")
    inst:AddTag("structure")

    inst.Light:SetIntensity(.4)
    inst.Light:SetRadius(.8)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(unpack(WarningColours.green))
    inst.Light:Enable(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._warninglevel = "off"
    inst._fuellevel = 10

    inst._glow = SpawnPrefab("firesuppressor_glow")
    inst:DoTaskInTime(0, oninit)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = TurnOn
    inst.components.machine.turnofffn = TurnOff
    inst.components.machine.caninteractfn = CanInteract
    inst.components.machine.cooldowntime = 0.5

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    inst.components.fueled.ontakefuelfn = OnAddFuel
    inst.components.fueled.accepting = true
    inst.components.fueled:SetSections(10)
    inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    inst.components.fueled:InitializeFuelLevel(TUNING.FIRESUPPRESSOR_MAX_FUEL_TIME)
    inst.components.fueled.bonusmult = 5
    inst.components.fueled.secondaryfueltype = FUELTYPE.CHEMICAL

    inst:AddComponent("firedetector")
    inst.components.firedetector:SetOnFindFireFn(OnFindFire)
    inst.components.firedetector:SetOnBeginEmergencyFn(OnBeginEmergency)
    inst.components.firedetector:SetOnEndEmergencyFn(OnEndEmergency)
    inst.components.firedetector:SetOnBeginWarningFn(OnBeginWarning)
    inst.components.firedetector:SetOnUpdateWarningFn(OnUpdateWarning)
    inst.components.firedetector:SetOnEndWarningFn(OnEndWarning)
    inst:AddComponent("wateryprotection")
    inst.components.wateryprotection.extinguishheatpercent = TUNING.FIRESUPPRESSOR_EXTINGUISH_HEAT_PERCENT
    inst.components.wateryprotection.temperaturereduction = TUNING.FIRESUPPRESSOR_TEMP_REDUCTION
    inst.components.wateryprotection.witherprotectiontime = TUNING.FIRESUPPRESSOR_PROTECTION_TIME
    inst.components.wateryprotection.addcoldness = TUNING.FIRESUPPRESSOR_ADD_COLDNESS
    inst.components.wateryprotection:AddIgnoreTag("player")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst.LaunchProjectile = LaunchProjectile
    inst:SetStateGraph("SGfiresuppressor")

    inst.OnSave = onsave 
    inst.OnLoad = onload
    --inst.OnLoadPostPass = OnLoadPostPass
    inst.OnEntitySleep = OnEntitySleep
    inst.OnRemoveEntity = OnRemoveEntity

    inst.components.machine:TurnOn()

    MakeHauntableWork(inst)

    return inst
end

local function onfade(inst)
    if inst._ison:value() then
        local df = math.max(.1, (1 - inst._fade) * .5)
        inst._fade = inst._fade + df
        if inst._fade >= 1 then
            inst._fade = 1
            inst._task:Cancel()
            inst._task = nil
        end
        inst.AnimState:OverrideMultColour(inst._fade, inst._fade, inst._fade, inst._fade)
    else
        local df = math.max(.1, inst._fade * .5)
        inst._fade = inst._fade - df
        if inst._fade <= 0 then
            inst._fade = 0
            inst._task:Cancel()
            inst._task = nil
        end
        inst.AnimState:OverrideMultColour(inst._fade, inst._fade, inst._fade, inst._fade)
    end
end

local function onisondirty(inst)
    if inst._task == nil and (inst._ison:value() and 1 or 0) ~= inst._fade then
        inst._task = inst:DoPeriodicTask(FRAMES, onfade, 0)
    end
end

local function oninitglow(inst)
    if inst._ison:value() then
        inst.AnimState:OverrideMultColour(1, 1, 1, 1)
        inst._fade = 1
    end
    inst:ListenForEvent("onisondirty", onisondirty)
end

local function glow_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("firefighter_glow")
    inst.AnimState:SetBuild("firefighter_glow")
    inst.AnimState:PlayAnimation("green", true)
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetFinalOffset(-1)
    inst.AnimState:OverrideMultColour(0, 0, 0, 0)

    inst._ison = net_bool(inst.GUID, "firesuppressor_glow._ison", "onisondirty")
    inst._fade = 0
    inst._task = nil
    inst:DoTaskInTime(0, oninitglow)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("firesuppressor", fn, assets, prefabs),
    Prefab("firesuppressor_glow", glow_fn, glow_assets),
    MakePlacer("firesuppressor_placer", "firefighter_placement", "firefighter_placement", "idle", true, nil, nil, 1.55)
