local smoke_texture = "fx/smoke.tex"
local shader = "shaders/vfx_particle.ksh"

local colour_envelope_name_smoke = "torch_spooky_colourenvelope_smoke"
local scale_envelope_name_smoke = "torch_spooky_scaleenvelope_smoke"

local assets =
{
    Asset( "IMAGE", smoke_texture ),
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
	end
end

local smoke_max_lifetime = 1.1
local fire_max_lifetime = 0.9

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    InitEnvelope()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 1 )
    
    --SMOKE
    effect:SetRenderResources( 0, smoke_texture, shader )
    effect:SetMaxNumParticles( 0, 128 )
    effect:SetMaxLifetime( 0, smoke_max_lifetime )
    effect:SetColourEnvelope( 0, colour_envelope_name_smoke )
    effect:SetScaleEnvelope( 0, scale_envelope_name_smoke )
    effect:SetBlendMode( 0, BLENDMODE.Premultiplied )
    effect:EnableBloomPass( 0, true )
    effect:SetUVFrameSize( 0, 0.25, 1 )
    effect:SetSortOrder( 0, 0 )
    effect:SetSortOffset( 0, 1 )
    effect:SetRadius( 0, 3 ) --only needed on a single emitter
    
    inst.fx_offset = -125

    -----------------------------------------------------
    local tick_time = TheSim:GetTickTime()
    
    local smoke_desired_pps = 80
    local smoke_particles_per_tick = smoke_desired_pps * tick_time
    local smoke_num_particles_to_emit = -50 --start delay
    
    local sphere_emitter = CreateSphereEmitter(0.05)

    
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
    
    
    local function updateFunc()
		--SMOKE
        while smoke_num_particles_to_emit > 1 do
            emit_smoke_fn()
            smoke_num_particles_to_emit = smoke_num_particles_to_emit - 1
        end
        smoke_num_particles_to_emit = smoke_num_particles_to_emit + smoke_particles_per_tick
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

return Prefab("torchfire_spooky", fn, assets)
