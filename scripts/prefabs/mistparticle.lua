local texture = "levels/textures/ds_fog1.tex"
local shader = "shaders/particle.ksh"
local colour_envelope_name = "mistcolourenvelope"
local scale_envelope_name = "mistscaleenvelope"

local assets =
{
	Asset( "IMAGE", texture ),
	Asset( "SHADER", shader ),
}

local max_scale = 10

local init = false
local function InitEnvelopes()
	if EnvelopeManager and not init then
		init = true
		EnvelopeManager:AddColourEnvelope(
			colour_envelope_name,
			{	{ 0,	{ 1, 1, 1, 0 } },
				{ 0.1,	{ 1, 1, 1, 0.12 } },
				{ 0.75,	{ 1, 1, 1, 0.12 } },
				{ 1,	{ 1, 1, 1, 0 } },
			} )

		EnvelopeManager:AddVector2Envelope(
			scale_envelope_name,
			{	{ 0,	{ 6, 6 } },
				{ 1,	{ max_scale, max_scale } },
			} )
	end
end

local max_lifetime = 31
local ground_height = 0.4
local emitter_radius = 25

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	
	inst.persists = false
	-----------------------------------------------------	
	InitEnvelopes()

	
	local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 1 )
   	
	local config = {texture = texture, shader = shader,
						max_num_particles = (max_lifetime + 1),
						max_lifetime = max_lifetime, 
						SV ={{x=-1, y=0, z=1},{x=1,y=0,z=1}},
						sort_order = 3, 
						colour_envelope_name = colour_envelope_name,
						scale_envelope_name = scale_envelope_name
						}
	effect:SetRenderResources( 0, config.texture, config.shader )
	effect:SetMaxNumParticles( 0, config.max_num_particles)
	effect:SetMaxLifetime( 0, config.max_lifetime )
	effect:SetSpawnVectors( 0, config.SV[1].x, config.SV[1].y, config.SV[1].z,
							 config.SV[2].x, config.SV[2].y, config.SV[2].z)
	effect:SetSortOrder( 0, config.sort_order )
	effect:SetColourEnvelope( 0, config.colour_envelope_name )
	effect:SetScaleEnvelope( 0, config.scale_envelope_name )
	
	effect:SetRadius( 0, emitter_radius )
	-----------------------------------------------------	

	inst:AddComponent("emitter")
	inst.components.emitter.config = config
	inst.components.emitter.max_lifetime = max_lifetime
	inst.components.emitter.ground_height = ground_height
	inst.components.emitter.particles_per_tick = 1
    return inst
end

return Prefab( "mist", fn, assets) 
 
