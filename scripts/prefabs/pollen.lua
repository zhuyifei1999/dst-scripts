local texture = "fx/snow.tex"
local shader = "shaders/particle.ksh"
local colour_envelope_name = "pollencolourenvelope"
local scale_envelope_name = "pollenscaleenvelope"

local assets =
{
	Asset( "IMAGE", texture ),
	Asset( "SHADER", shader ),
}

local function IntColour( r, g, b, a )
	return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local init = false
local function InitEnvelope()
	if EnvelopeManager and not init then
		init = true
		EnvelopeManager:AddColourEnvelope(
			colour_envelope_name,
			{	{ 0,	IntColour( 255, 255, 0, 0 ) },
				{ 0.5,	IntColour( 255, 255, 0, 127 ) },				
				{ 1,	IntColour( 255, 255, 0, 0 ) },
			} )

        local min_scale = 0.8
		local max_scale = 1.0
		EnvelopeManager:AddVector2Envelope(
			scale_envelope_name,
			{
				{ 0,	{ min_scale, min_scale } },
				{ 0.5,	{ max_scale, max_scale } },
				{ 1,	{ min_scale, min_scale } },
			} )
	end
end

local max_lifetime = 60
local min_lifetime = 30

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
    local effect = inst.entity:AddVFXEffect()
	inst:AddTag("FX")

	InitEnvelope()

    effect:InitEmitters( 1 )
	effect:SetRenderResources( 0, texture, shader )
	effect:SetMaxNumParticles( 0, 1000 )
	effect:SetMaxLifetime( 0, max_lifetime )
	effect:SetColourEnvelope( 0, colour_envelope_name )
	effect:SetScaleEnvelope( 0, scale_envelope_name );
	effect:SetBlendMode( 0, BLENDMODE.Premultiplied )
	effect:SetSortOrder( 0, 3 )
	--effect:SetLayer( 0, LAYER_BACKGROUND )
	effect:SetAcceleration( 0, 0, 0.0001, 0 )
	effect:SetDragCoefficient( 0, 0.0001 )
	effect:EnableDepthTest( 0, false )

	-----------------------------------------------------
	local rng = math.random
	local tick_time = TheSim:GetTickTime()

	local desired_particles_per_second = 0--300
	inst.particles_per_tick = desired_particles_per_second * tick_time

	local emitter = inst.ParticleEmitter

	inst.num_particles_to_emit = inst.particles_per_tick

    local halfheight = 2
	local emitter_shape = CreateBoxEmitter( 0, 0, 0, 40, halfheight, 40 )

	local emit_fn = function()
		if TheWorld.Map ~= nil then
			local x, y, z = inst.Transform:GetWorldPosition()
	        local px, py, pz = emitter_shape()		
            py = py + halfheight -- otherwise the particles appear under the ground
			x = x + px
			z = z + pz

            -- don't spawn particles over water
			if TheWorld.Map:GetTileAtPoint( x, y, z ) ~= GROUND.IMPASSABLE then
				
                local vx = 0.03 * (math.random() - 0.5)
                local vy = 0
                local vz = 0.03 * (math.random() - 0.5)        		
                if TheWorld.state.isday and TheWorld.state.temperature > TUNING.WILDFIRE_THRESHOLD then
                    vx = vx * 0.1
                    vy = 0.01
                    vz = vz * 0.1
                end

                local lifetime = min_lifetime + ( max_lifetime - min_lifetime ) * UnitRand()

	            effect:AddParticle(
					0,
		            lifetime,			-- lifetime
		            px, py, pz,			-- position
		            vx, vy, vz			-- velocity
	            )
			end
		end		
	end

	local updateFunc = function()
		while inst.num_particles_to_emit > 1 do
			emit_fn( emitter )
			inst.num_particles_to_emit = inst.num_particles_to_emit - 1
		end

		inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick
		
		-- vary the acceleration with time in a circular pattern
		-- together with the random initial velocities this should give a variety of motion		
		inst.time = inst.time + tick_time		
		inst.interval = inst.interval + 1
		if 10 < inst.interval then
		    inst.interval = 0
            if TheWorld.state.isday and TheWorld.state.temperature > TUNING.WILDFIRE_THRESHOLD then
                local sin_val = 0.01 * math.sin(inst.time*.8)
                effect:SetAcceleration( 0, 0, sin_val, 0 )
            else
                local sin_val = 0.006 * math.sin(inst.time/3)
                local cos_val = 0.006 * math.cos(inst.time/3)
                effect:SetAcceleration( 0, sin_val, 0.05 * sin_val, cos_val )
            end
		end
		
	end
	
	inst.time = 0.0
	inst.interval = 0

	EmitterManager:AddEmitter( inst, nil, updateFunc )

    function inst:PostInit()
        local dt = 1 / 30
        local t = max_lifetime
        while t > 0 do
            t = t - dt
            updateFunc()
            effect:FastForward( 0, dt )
        end
    end

    return inst
end

return Prefab( "pollen", fn, assets) 
