local TEXTURE = "fx/lunarhail.tex"

local SHADER = "shaders/vfx_particle.ksh"

local COLOUR_ENVELOPE_NAME = "lunarhailcolourenvelope"
local SCALE_ENVELOPE_NAME = "lunarhailscaleenvelope"

local assets =
{
    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER),
}

local prefabs =
{
    "lunarhaildrop",
}

--------------------------------------------------------------------------

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0, IntColour(255, 255, 255, 200) },
            { 1, IntColour(255, 255, 255, 200) },
        }
    )

    local mix_scale = 2
    local max_scale = 4
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0, { mix_scale, max_scale } },
            { 1, { mix_scale, max_scale } },
        }
    )

    InitEnvelope = nil
    IntColour = nil
end

--------------------------------------------------------------------------

local MAX_LIFETIME = 3
local MIN_LIFETIME = 2

--------------------------------------------------------------------------

local function SpawnLunarHailDropAtXZ(x, z, fastforward)
    local onwater = TheWorld.Map:IsOceanAtPoint(x, 0, z)

    local lunarhaildrop = SpawnPrefab(onwater and "raindrop" or "lunarhaildrop")
    lunarhaildrop.Transform:SetPosition(x, 0, z)

    if fastforward then
        lunarhaildrop.AnimState:FastForward(fastforward)
    end
end

--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()

    if InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, TEXTURE, SHADER)
    effect:SetRotationStatus(0, true)
    effect:SetMaxNumParticles(0, 4800)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.Premultiplied)
    effect:SetSortOrder(0, 3)
    effect:SetDragCoefficient(0, .2)
    effect:EnableDepthTest(0, true)

    -----------------------------------------------------

    local rng = math.random
    local tick_time = TheSim:GetTickTime()

    local desired_particles_per_second = 0--1000
    local desired_splashes_per_second = 0--100

    inst.particles_per_tick = desired_particles_per_second * tick_time
    inst.splashes_per_tick = desired_splashes_per_second * tick_time

    inst.num_particles_to_emit = inst.particles_per_tick
    inst.num_splashes_to_emit = 0

    local bx, by, bz = 0, 20, 0
    local emitter_shape = CreateBoxEmitter(bx, by, bz, bx + 20, by, bz + 20)

    local angle = 0
    local dx = math.cos(angle * DEGREES)
    effect:SetAcceleration(0, dx, -6, 1 )

    local function emit_fn(x, z, left_sx, right_sx, bottom_sy)
        local vy = -1 + UnitRand() * -2
        local vz = 0
        local vx = dx
        local lifetime = MIN_LIFETIME + (MAX_LIFETIME - MIN_LIFETIME) * UnitRand()
        local px, py, pz = emitter_shape()
        local px1 = x + px
        local pz1 = z + pz

        angle = rng(-3, 3)

        if not IsUnderRainDomeAtXZ(px1, pz1) then
            if bottom_sy ~= nil then
                local psx, psy = TheSim:GetScreenPos(px1, 0, pz1)
                if psy < bottom_sy and psx > left_sx and psx < right_sx then
                    return --skip
                end
            end

            effect:AddRotatingParticle(
                0,                  -- the only emitter
                lifetime,           -- lifetime
                px, py, pz,         -- position
                vx, vy, vz,         -- velocity
                angle, 0            -- angle, angular_velocity
            )
        end
    end

    local lunarhaildrop_offset = CreateDiscEmitter(30)

    local last_domes = nil
    local last_domes_ticks = 0

    local function updateFunc(fastforward)
        local x, y, z = inst.Transform:GetWorldPosition()
        local left_sx, right_sx, bottom_sy
        local under_domes = GetRainDomesAtXZ(x, z)
        if #under_domes > 0 then
            left_sx, bottom_sy = TheSim:GetScreenPos(x, 0, z)
            left_sx, right_sx = math.huge, -math.huge
            local right_vec = TheCamera:GetRightVec()
            for i, v in ipairs(under_domes) do
                local r = 16--v.components.raindome.radius
                local rvx = right_vec.x * r
                local rvz = right_vec.z * r
                local x1, y1, z1 = v.Transform:GetWorldPosition()
                local x2 = TheSim:GetScreenPos(x1 + rvx, 0, z1 + rvz)
                right_sx = math.max(right_sx, x2)
                x2 = TheSim:GetScreenPos(x1 - rvx, 0, z1 - rvz)
                left_sx = math.min(left_sx, x2)
            end
        end

        while inst.num_particles_to_emit > 0 do
            emit_fn(x, z, left_sx, right_sx, bottom_sy)
            inst.num_particles_to_emit = inst.num_particles_to_emit - 1
        end

        while inst.num_splashes_to_emit > 0 do
            local dx, dz = lunarhaildrop_offset()

            local x1 = x + dx
            local z1 = z + dz

            if not IsUnderRainDomeAtXZ(x1, z1) then
                SpawnLunarHailDropAtXZ(x1, z1, fastforward)
            end

            inst.num_splashes_to_emit = inst.num_splashes_to_emit - 1
        end

        inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick
        inst.num_splashes_to_emit = inst.num_splashes_to_emit + inst.splashes_per_tick
    end

    EmitterManager:AddEmitter(inst, nil, updateFunc)

    function inst:PostInit()
        local dt = 1 / 30
        local t = MAX_LIFETIME
        while t > 0 do
            t = t - dt
            updateFunc(t)
            effect:FastForward(0, dt)
        end
    end

    return inst
end

return Prefab("lunarhail", fn, assets, prefabs)
