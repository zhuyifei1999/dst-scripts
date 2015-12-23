local texture = "fx/snow.tex"
local shader = "shaders/particle.ksh"
local colour_envelope_name = "snowcolourenvelope"
local scale_envelope_name = "snowscaleenvelope"

local assets =
{
	Asset("IMAGE", texture),
	Asset("SHADER", shader),
}

local function IntColour(r, g, b, a)
	return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local init = false
local function InitEnvelope()
	if EnvelopeManager and not init then
		init = true
		EnvelopeManager:AddColourEnvelope(
			colour_envelope_name,
			{	{ 0, IntColour(255, 255, 255, 200) },
				{ 1, IntColour(255, 255, 255, 200) },
			})

		local max_scale = 1
		EnvelopeManager:AddVector2Envelope(
			scale_envelope_name,
			{
				{ 0, { max_scale, max_scale } },
				{ 1, { max_scale, max_scale } },
			})
	end
end

local max_lifetime = 7
local min_lifetime = 4

local function fn()
	local inst = CreateEntity()

	inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()

	InitEnvelope()

    local emitter = inst.entity:AddParticleEmitter()
	emitter:SetRenderResources(texture, shader)
	emitter:SetMaxNumParticles(4800)
	emitter:SetMaxLifetime(max_lifetime)
	emitter:SetColourEnvelope(colour_envelope_name)
	emitter:SetScaleEnvelope(scale_envelope_name)
	emitter:SetBlendMode(BLENDMODE.Premultiplied)
	emitter:SetSortOrder(3)
	emitter:SetAcceleration(-1, -9.80, 1)
	emitter:SetDragCoefficient(0.8)
	emitter:EnableDepthTest(true)

	-----------------------------------------------------
	local rng = math.random
	local tick_time = TheSim:GetTickTime()

	local desired_particles_per_second = 0--300
	inst.particles_per_tick = desired_particles_per_second * tick_time

	inst.num_particles_to_emit = inst.particles_per_tick

	local bx, by, bz = 0, 20, 0
	local emitter_shape = CreateBoxEmitter( bx, by, bz, bx + 20, by, bz + 20 )

	local function emit_fn()
		local vx, vy, vz = 0, 0, 0
		local lifetime = min_lifetime + (max_lifetime - min_lifetime) * UnitRand()
		local px, py, pz = emitter_shape()

		emitter:AddParticle(
			lifetime,			-- lifetime
			px, py, pz,			-- position
			vx, vy, vz			-- velocity
		)
	end

	local function updateFunc()
		while inst.num_particles_to_emit > 1 do
			emit_fn(emitter)
			inst.num_particles_to_emit = inst.num_particles_to_emit - 1
		end

		inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick
	end

	EmitterManager:AddEmitter(inst, nil, updateFunc)

    function inst:PostInit()
        local dt = 1 / 30
        local t = max_lifetime
        while t > 0 do
            t = t - dt
            updateFunc()
            emitter:FastForward(dt)
        end
    end

    return inst
end

return Prefab("snow", fn, assets)