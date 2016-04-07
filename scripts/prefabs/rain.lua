local texture = "fx/rain.tex"
local shader = "shaders/vfx_particle.ksh"
local colour_envelope_name = "raincolourenvelope"
local scale_envelope_name = "rainscaleenvelope"

local assets =
{
	Asset("IMAGE", texture),
	Asset("SHADER", shader),
}

local prefabs =
{
    "raindrop",
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

		local max_scale = 10
		EnvelopeManager:AddVector2Envelope(
			scale_envelope_name,
			{
				{ 0, { 0.1, max_scale } },
				{ 1, { 0.1, max_scale } },
			})
	end
end

local max_lifetime = 2
local min_lifetime = 2

local function fn()
	local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

	inst.entity:AddTransform()

	InitEnvelope()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 1 )
	effect:SetRenderResources( 0, texture, shader )
	effect:SetRotationStatus( 0, true )
	effect:SetMaxNumParticles( 0, 4800 )
	effect:SetMaxLifetime( 0, max_lifetime )
	effect:SetColourEnvelope( 0, colour_envelope_name )
	effect:SetScaleEnvelope( 0, scale_envelope_name )
	effect:SetBlendMode( 0, BLENDMODE.Premultiplied )
	effect:SetSortOrder( 0, 3 )
	effect:SetDragCoefficient( 0, 0.2 )
	effect:EnableDepthTest( 0, true )

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
	local dx = math.cos(angle * PI / 180)
	effect:SetAcceleration( 0, dx, -9.80, 1 )

	local function emit_fn()
		local vy = -2 + UnitRand() * -8
		local vz = 0
		local vx = dx

		local lifetime = min_lifetime + (max_lifetime - min_lifetime) * UnitRand()
		local px, py, pz = emitter_shape()

		effect:AddRotatingParticle(
			0,					-- the only emitter
			lifetime,			-- lifetime
			px, py, pz,			-- position
			vx, vy, vz,			-- velocity
			angle, 0			-- angle, angular_velocity
		)
	end
	
	local raindrop_offset = CreateDiscEmitter(20)
	
    local map = TheWorld.Map

	local function updateFunc(fastforward)
		while inst.num_particles_to_emit > 0 do
			emit_fn(effect)
			inst.num_particles_to_emit = inst.num_particles_to_emit - 1
		end
		
		while inst.num_splashes_to_emit > 0 do
			local x, y, z = inst.Transform:GetWorldPosition()
			local dx, dz = raindrop_offset()

			x = x + dx
			z = z + dz

			if map:IsPassableAtPoint(x, y, z) then
				local raindrop = SpawnPrefab("raindrop")
				raindrop.Transform:SetPosition(x, y, z)

                if fastforward then
                    raindrop.AnimState:FastForward(fastforward)
                end
				
			end
			inst.num_splashes_to_emit = inst.num_splashes_to_emit - 1
		end

		inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick
		inst.num_splashes_to_emit = inst.num_splashes_to_emit + inst.splashes_per_tick
	end

	EmitterManager:AddEmitter(inst, nil, updateFunc)

    function inst:PostInit()
        local dt = 1 / 30
        local t = max_lifetime
        while t > 0 do
            t = t - dt
            updateFunc(t)
            effect:FastForward( 0, dt  )
        end
    end

    return inst
end

return Prefab("rain", fn, assets, prefabs)