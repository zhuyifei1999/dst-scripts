


local FIRE_TEXTURE = "fx/sparkle.tex"

local ADD_SHADER = "shaders/vfx_particle_add.ksh"

local COLOUR_ENVELOPE_NAME = "cane_victorian_colourenvelope"
local SCALE_ENVELOPE_NAME = "cane_victorian_scaleenvelope"

local assets =
{
    Asset("IMAGE", FIRE_TEXTURE),
    Asset("SHADER", ADD_SHADER),
}

--------------------------------------------------------------------------

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local function InitEnvelope()

    local envs = {}
    local t = 0
    local step = .15
    while (t + step + 0.01) < 1 do
        table.insert( envs, { t, IntColour(255, 255, 150, 255) } )
        t = t + step
        table.insert( envs, { t, IntColour(255, 255, 150, 0) } )
        t = t + 0.01
    end
    table.insert( envs, { 1, IntColour(255, 255, 150, 0) } )

    EnvelopeManager:AddColourEnvelope( COLOUR_ENVELOPE_NAME, envs )


    local fire_max_scale = 0.4
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { fire_max_scale, fire_max_scale } },
            { 1,    { fire_max_scale * .5, fire_max_scale * .5 } },
        }
    )
end

--------------------------------------------------------------------------
local MAX_LIFETIME = 1.75

local function emit_fire_fn(effect, sphere_emitter)
    local vx, vy, vz = .012 * UnitRand(), 0, .012 * UnitRand()
    local lifetime = MAX_LIFETIME * (.7 + UnitRand() * .3)
    local px, py, pz = sphere_emitter()

    local angle = math.random() * 360    
    local uv_offset = math.random(0, 3) * .25
    local ang_vel = (UnitRand() - 1) * 5

    effect:AddRotatingParticleUV(
        0,
        lifetime,           -- lifetime
        px, py, pz,         -- position
        vx, vy, vz,         -- velocity
        angle, ang_vel,     -- angle, angular_velocity
        uv_offset, 0        -- uv offset
    )
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	
	InitEnvelope()
	
	local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)

    --FIRE
    effect:SetRenderResources(0, FIRE_TEXTURE, ADD_SHADER)
    effect:SetRotationStatus(0, true)
    effect:SetUVFrameSize(0, .25, 1)
    effect:SetMaxNumParticles(0, 256)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.Additive)
    effect:EnableBloomPass(0, true)
    effect:SetSortOrder(0, 0)
    effect:SetSortOffset(0, 2)

    -----------------------------------------------------

    local tick_time = TheSim:GetTickTime()

    local fire_desired_pps_low = 5
    local fire_desired_pps_high = 50
    local low_per_tick = fire_desired_pps_low * tick_time
    local high_per_tick = fire_desired_pps_high * tick_time
    local num_to_emit = 0

    local sphere_emitter = CreateSphereEmitter(.25)
    inst.last_pos = inst:GetPosition()

    EmitterManager:AddEmitter(inst, nil, function()
        local dist_moved = inst:GetPosition() - inst.last_pos
        local move = dist_moved:Length()
        move = math.clamp(move*6, 0, 1)

        local per_tick = Lerp(low_per_tick, high_per_tick, move)

        inst.last_pos = inst:GetPosition()
                
        num_to_emit = num_to_emit + per_tick * math.random() * 3
        while num_to_emit > 1 do
            emit_fire_fn(effect, sphere_emitter)
            num_to_emit = num_to_emit - 1
        end
    end)
	
	return inst
end

local pf = Prefab("cane_victorian_fx", fn, assets, {})
pf.vfx_fx = true --not to get confused with the cane prefab fx
return pf