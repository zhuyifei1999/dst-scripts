local smoke_texture = "fx/smoke.tex"
local ember_texture = "fx/snow.tex"
local fire_texture = "fx/torchfire.tex"
local shader = "shaders/vfx_particle.ksh"
local add_shader = "shaders/vfx_particle_add.ksh"
local colour_envelope_name_smoke = "torch_rag_colourenvelope_smoke"
local scale_envelope_name_smoke = "torch_rag_scaleenvelope_smoke"
local colour_envelope_name = "torch_rag_colourenvelope"
local scale_envelope_name = "torch_rag_scaleenvelope"
local colour_envelope_name_ember = "torch_rag_colourenvelope_ember"
local scale_envelope_name_ember = "torch_rag_scaleenvelope_ember"

local assets =
{
    Asset( "IMAGE", smoke_texture ),
    Asset( "IMAGE", ember_texture ),
    Asset( "IMAGE", fire_texture ),
    Asset( "SHADER", shader ),
    Asset( "SHADER", add_shader ),
}


local function IntColour( r, g, b, a )
    return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local init = false
local function InitEnvelope()
    if EnvelopeManager and not init then
        init = true
        EnvelopeManager:AddColourEnvelope(
            colour_envelope_name_smoke,
            {
				{ 0,    IntColour( 30, 22, 15, 0 ) },
				{ .3,   IntColour( 20, 18, 15, 100 ) },
				{ .52,  IntColour( 15, 15, 15, 20 ) },
                { 1,    IntColour( 15, 15, 15, 0 ) },
            } )

        local smoke_max_scale = 2.5
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name_smoke,
            {
                { 0,    { smoke_max_scale * 0.4, smoke_max_scale * 0.4} },
				{ .50,  { smoke_max_scale * 0.6, smoke_max_scale * 0.6} },
				{ .65,  { smoke_max_scale * 0.9, smoke_max_scale * 0.9} },
                { 1,    { smoke_max_scale, smoke_max_scale} },
            } )
            
	
        EnvelopeManager:AddColourEnvelope(
            colour_envelope_name,
            {   { 0,    IntColour( 200, 85, 60, 25 ) },
                { 0.19, IntColour( 200, 125, 80, 100 ) },
                { 0.35, IntColour( 255, 20, 10, 200 ) },
                { 0.51, IntColour( 255, 20, 10, 128 ) },
                { 0.75, IntColour( 255, 20, 10, 64 ) },
                { 1,    IntColour( 255, 7, 5, 0 ) },
            } )

		local fire_max_scale = 4
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name,
            {
                { 0,    { fire_max_scale * 0.9, fire_max_scale } },
                { 1,    { fire_max_scale * 0.5, fire_max_scale * 0.4 } },
            } )
            
		EnvelopeManager:AddColourEnvelope(
            colour_envelope_name_ember,
            {   { 0,    IntColour( 200, 85, 60, 25 ) },
                { 0.2, IntColour( 230, 140, 90, 200 ) },
                { 0.3, IntColour( 255, 90, 70, 255 ) },
                { 0.6, IntColour( 255, 90, 70, 255 ) },
                { 0.9, IntColour( 255, 90, 70, 230 ) },
                { 1,    IntColour( 255, 70, 70, 0 ) },
            } )

		local ember_max_scale = 0.35
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name_ember,
            {
                { 0,    { ember_max_scale, ember_max_scale } },
                { 1,    { ember_max_scale, ember_max_scale } },
            } )
    end
end

local smoke_max_lifetime = 1.1
local fire_max_lifetime = 0.25
local ember_max_lifetime = 0.7

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    InitEnvelope()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 3 )
    
    --SMOKE
    effect:SetRenderResources( 0, smoke_texture, shader )
    effect:SetMaxNumParticles( 0, 128 )
    effect:SetMaxLifetime( 0, smoke_max_lifetime )
    effect:SetColourEnvelope( 0, colour_envelope_name_smoke )
    effect:SetScaleEnvelope( 0, scale_envelope_name_smoke )
    effect:SetBlendMode( 0, BLENDMODE.Premultiplied ) --AlphaBlended Premultiplied
    effect:EnableBloomPass( 0, true )
    effect:SetUVFrameSize( 0, 0.25, 1 )
    effect:SetSortOrder( 0, 1 )
    effect:SetRadius( 0, 3 ) --only needed on a single emitter
    
    
    --FIRE
    effect:SetRenderResources( 1, fire_texture, add_shader )
    effect:SetMaxNumParticles( 1, 64 )
    effect:SetMaxLifetime( 1, fire_max_lifetime )
    effect:SetColourEnvelope( 1, colour_envelope_name )
    effect:SetScaleEnvelope( 1, scale_envelope_name )
    effect:SetBlendMode( 1, BLENDMODE.Additive )
    effect:EnableBloomPass( 1, true )
    effect:SetUVFrameSize( 1, 0.25, 1 )
    effect:SetSortOrder( 1, 2 )

    --EMBER
    effect:SetRenderResources( 2, ember_texture, add_shader )
    effect:SetMaxNumParticles( 2, 128 )
    effect:SetMaxLifetime( 2, ember_max_lifetime )
    effect:SetColourEnvelope( 2, colour_envelope_name_ember )
    effect:SetScaleEnvelope( 2, scale_envelope_name_ember )
    effect:SetBlendMode( 2, BLENDMODE.Additive )
    effect:EnableBloomPass( 2, true )
    effect:SetUVFrameSize( 2, 1, 1 )
    effect:SetSortOrder( 2, 2 )
    effect:SetDragCoefficient( 2, 0.07 )
    

	inst.fx_offset = -120

    -----------------------------------------------------
    local tick_time = TheSim:GetTickTime()

    local smoke_desired_pps = 80
    local smoke_particles_per_tick = smoke_desired_pps * tick_time
    local smoke_num_particles_to_emit = -50 --start delay
	
    local fire_desired_pps = 40
	local fire_particles_per_tick = fire_desired_pps * tick_time
    local fire_num_particles_to_emit = 1

    local ember_time_to_emit = -2
    local ember_num_particles_to_emit = 1

    local sphere_emitter = CreateSphereEmitter(0.05)
    local ember_sphere_emitter = CreateSphereEmitter(0.1)

    local function emit_smoke_fn()
		--SMOKE
        local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()
        vy = vy + 0.08 + 0.02 * UnitRand()
        local lifetime = smoke_max_lifetime * (0.9 + UnitRand() * 0.1)
        local px, py, pz = sphere_emitter()
		py = py + 0.2

		local uv_offset = math.random(0, 3) * 0.25

        effect:AddParticleUV(
            0,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            uv_offset, 0        -- uv offset
        )       
    end
    
    local function emit_fire_fn()            
        --FIRE
        local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()
        local lifetime = fire_max_lifetime * (0.9 + UnitRand() * 0.1)
		local px, py, pz = sphere_emitter()

        local uv_offset = math.random(0, 3) * 0.25

        effect:AddParticleUV(
			1,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            uv_offset, 0        -- uv offset
        )
    end
    
    local function emit_ember_fn()            
        --EMBER
        local vx, vy, vz = 0.02 * UnitRand(), 0, 0.02 * UnitRand()
        vy = vy + 0.08 + 0.03 * UnitRand()
        local lifetime = ember_max_lifetime * (0.9 + UnitRand() * 0.1)
		local px, py, pz = ember_sphere_emitter()
		py = py + 0.4

        effect:AddParticleUV(
			2,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            0, 0        -- uv offset
        )
    end
    
    local function updateFunc()
		--SMOKE
        while smoke_num_particles_to_emit > 1 do
            emit_smoke_fn()
            smoke_num_particles_to_emit = smoke_num_particles_to_emit - 1
        end
        smoke_num_particles_to_emit = smoke_num_particles_to_emit + smoke_particles_per_tick
        
        --FIRE
        while fire_num_particles_to_emit > 1 do
            emit_fire_fn()
            fire_num_particles_to_emit = fire_num_particles_to_emit - 1
        end
        fire_num_particles_to_emit = fire_num_particles_to_emit + fire_particles_per_tick * (math.random() * 3)
        
        --EMBERS
        if ember_time_to_emit < 0 then
			for i=1,ember_num_particles_to_emit do
				emit_ember_fn()
			end
			ember_num_particles_to_emit = 2 + 3 * math.random() --4 + 9 * math.random()
			ember_time_to_emit = 0.2-- + (math.random() * 0.5)
        end
        ember_time_to_emit = ember_time_to_emit - tick_time
    end

    EmitterManager:AddEmitter(inst, nil, updateFunc)
	
	
	
    inst:AddTag("FX")
    inst:AddTag("playerlight")

    inst.Light:Enable(true)
    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(197 / 255, 197 / 255, 50 / 255)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("torchfire_rag", fn, assets)
