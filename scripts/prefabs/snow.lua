local texture = "fx/snow.tex"
local winter_texture = "fx/wintersnow.tex"
local shader = "shaders/vfx_particle.ksh"
local colour_envelope_name = "snowcolourenvelope"
local scale_envelope_name = "snowscaleenvelope"
local winter_scale_envelope_name = "wintersnowscaleenvelope"

local assets =
{
	Asset("IMAGE", texture),
	Asset("IMAGE", winter_texture),
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

		if IsSpecialEventActive( SPECIAL_EVENTS.WINTERS_FEAST ) then
			local max_scale = 0.3
			EnvelopeManager:AddVector2Envelope(
				winter_scale_envelope_name,
				{
					{ 0, { max_scale, max_scale } },
					{ 1, { max_scale, max_scale } },
				})
		else
			local max_scale = 1
			EnvelopeManager:AddVector2Envelope(
				scale_envelope_name,
				{
					{ 0, { max_scale, max_scale } },
					{ 1, { max_scale, max_scale } },
				})
		end
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

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 1 )
    if IsSpecialEventActive( SPECIAL_EVENTS.WINTERS_FEAST ) then
		effect:SetRenderResources( 0, winter_texture, shader )
		effect:SetScaleEnvelope( 0, winter_scale_envelope_name )
		effect:SetUVFrameSize( 0, 0.25, 1 )
	else
		effect:SetRenderResources( 0, texture, shader )
		effect:SetScaleEnvelope( 0, scale_envelope_name )
	end
	effect:SetMaxNumParticles( 0, 4800 )
	effect:SetMaxLifetime( 0, max_lifetime )
	effect:SetColourEnvelope( 0, colour_envelope_name )
	effect:SetBlendMode( 0, BLENDMODE.Premultiplied )
	effect:SetSortOrder( 0, 3 )
	effect:SetAcceleration( 0, -1, -9.80, 1 )
	effect:SetDragCoefficient( 0, 0.8 )
	effect:EnableDepthTest( 0, true )


	
	-----------------------------------------------------
	local rng = math.random
	local tick_time = TheSim:GetTickTime()

	local desired_particles_per_second = 0--300
	inst.particles_per_tick = desired_particles_per_second * tick_time

	inst.num_particles_to_emit = inst.particles_per_tick

	local bx, by, bz = 0, 20, 0
	local emitter_shape = CreateBoxEmitter( bx, by, bz, bx + 20, by, bz + 20 )
	
	local update_fn = nil
	
	if IsSpecialEventActive( SPECIAL_EVENTS.WINTERS_FEAST ) then
		local function emit_fn()
			local vx, vy, vz = 0, 0, 0
			local lifetime = min_lifetime + (max_lifetime - min_lifetime) * UnitRand()
			local px, py, pz = emitter_shape()

			local uv_offset = math.random(0, 3) * 0.25
			
			effect:AddParticleUV(
				0,
				lifetime,			-- lifetime
				px, py, pz,			-- position
				vx, vy, vz,			-- velocity
				uv_offset, 0        -- uv offset
			)
		end
		update_fn = function()
			while inst.num_particles_to_emit > 1 do
					emit_fn(effect)
					inst.num_particles_to_emit = inst.num_particles_to_emit - 1
				end

			inst.num_particles_to_emit = inst.num_particles_to_emit + (inst.particles_per_tick * 2)
		end
	else
		local function emit_fn()
			local vx, vy, vz = 0, 0, 0
			local lifetime = min_lifetime + (max_lifetime - min_lifetime) * UnitRand()
			local px, py, pz = emitter_shape()
			
			effect:AddParticle(
				0,
				lifetime,			-- lifetime
				px, py, pz,			-- position
				vx, vy, vz			-- velocity
			)
		end
		
		update_fn = function()
			while inst.num_particles_to_emit > 1 do
					emit_fn(effect)
					inst.num_particles_to_emit = inst.num_particles_to_emit - 1
				end

			inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick
		end
	end

	EmitterManager:AddEmitter(inst, nil, update_fn)

    function inst:PostInit()
        local dt = 1 / 30
        local t = max_lifetime
        while t > 0 do
            t = t - dt
            update_fn()
            effect:FastForward( 0, dt )
        end
    end

    return inst
end

return Prefab("snow", fn, assets)