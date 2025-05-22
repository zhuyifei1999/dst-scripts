local assets =
{
    Asset("ANIM", "anim/security_pulse_cage.zip"),
}

local prefabs_empty =
{
    "security_pulse_cage_full",
}

local prefabs_full =
{

}

local SOUND_LOOP_NAME = "soundloop"

local FULL_IDLE_ANIMNAME      = "idle_full2"
local FULL_FUNNYIDLE_ANIMNAME = "idle_full"

local FULL_FUNNYIDLE_TIME_MIN = 7
local FULL_FUNNYIDLE_TIME_MAX = 12

--
local function finish_erode(inst)
    inst.AnimState:SetErosionParams(0, 0, 0)
    if inst._erode_thread then
        scheduler:KillTask(inst._erode_thread)
        inst._erode_thread = nil
    end
end

local SHADER_CUTOFF_HEIGHT = -0.125
local function erode(inst, data)
    if not inst._erode_thread then
        local time_to_erode = (data and data.time) or 1
        local tick_time = TheSim:GetTickTime()

        inst._erode_thread = inst:StartThread(function()
            local ticks = 0
            while ticks * tick_time < time_to_erode do
                local erode_amount = 1 - (ticks * tick_time / time_to_erode)
                inst.AnimState:SetErosionParams(erode_amount, SHADER_CUTOFF_HEIGHT, -1.0)
                ticks = ticks + 1

                Yield()
            end
        end)

        inst:DoTaskInTime(1.1 * time_to_erode, finish_erode)
    end
end

------------------------------------------------------------------------------------------------------------------

-- security_pulse_cage_full fns

local function PlayFunnyIdle(inst)
    inst.AnimState:PushAnimation(FULL_FUNNYIDLE_ANIMNAME)
    inst.AnimState:PushAnimation(FULL_IDLE_ANIMNAME)

    local tasktime = GetRandomMinMax(FULL_FUNNYIDLE_TIME_MIN, FULL_FUNNYIDLE_TIME_MAX)

    inst._funnyidletask = inst:DoTaskInTime(tasktime, PlayFunnyIdle)
end

local function OnEntityWake(inst)
    if inst:IsInLimbo() or inst:IsAsleep() then
        return
    end

    if not inst.SoundEmitter:PlayingSound(SOUND_LOOP_NAME) then
        inst.SoundEmitter:PlaySound("grotto/common/archive_security_desk/leave_LP", SOUND_LOOP_NAME)
    end

    if inst._funnyidletask ~= nil then
        inst._funnyidletask:Cancel()
        inst._funnyidletask = nil
    end

    local tasktime = GetRandomMinMax(FULL_FUNNYIDLE_TIME_MIN, FULL_FUNNYIDLE_TIME_MAX)

    inst._funnyidletask = inst:DoTaskInTime(tasktime, PlayFunnyIdle)
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound(SOUND_LOOP_NAME)

    if inst._funnyidletask ~= nil then
        inst._funnyidletask:Cancel()
        inst._funnyidletask = nil
    end
end

------------------------------------------------------------------------------------------------------------------

local function OnPossess(inst, data)
    local pulse = data.possesser

    if pulse ~= nil and pulse:HasTag("power_point") then
        pulse:Remove()

        local full = ReplacePrefab(inst, "security_pulse_cage_full")

        if full ~= nil then
            full.AnimState:PlayAnimation("trap")
            full.AnimState:PushAnimation(FULL_IDLE_ANIMNAME)
        end

        return full -- Mods
    end
end

------------------------------------------------------------------------------------------------------------------

local function CommonFn(commonfn, anim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("security_pulse_cage")
    inst.AnimState:SetBuild("security_pulse_cage")
    inst.AnimState:PlayAnimation(anim, true)

    MakeInventoryFloatable(inst, "med", 0.35, 0.7)

    if commonfn ~= nil then
        commonfn(inst)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_anim = anim

    inst:ListenForEvent("doerode", erode)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)

    return inst
end

local function EmptyCageCommonFn(inst)
    inst:AddTag("security_powerpoint")
end

local function FullCageCommonFn(inst)
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    inst.AnimState:SetSymbolLightOverride("fx_archive_circles",    1)
    inst.AnimState:SetSymbolLightOverride("fx_archive_point",      1)
    inst.AnimState:SetSymbolLightOverride("fx_archive_point_loop", 1)
    inst.AnimState:SetSymbolLightOverride("light",                 1)
end

local function EmptyCageFn()
    local inst = CommonFn(EmptyCageCommonFn, "idle_empty")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnPossess = OnPossess -- Mods
    inst:ListenForEvent("possess", inst.OnPossess)

    return inst
end

local function FullCageFn(full)
    local inst = CommonFn(FullCageCommonFn, FULL_IDLE_ANIMNAME)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst.OnEntityWake  = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep
    inst:ListenForEvent("exitlimbo", OnEntityWake)
    inst:ListenForEvent("enterlimbo", OnEntitySleep)

    return inst
end

return Prefab("security_pulse_cage", EmptyCageFn, assets, prefabs_empty),
    Prefab("security_pulse_cage_full", FullCageFn,  assets, prefabs_full )
