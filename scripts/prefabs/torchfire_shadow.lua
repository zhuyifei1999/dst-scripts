local anim_hand_texture = "fx/animhand.tex"
local anim_smoke_texture = "fx/animsmoke.tex"
local fire_texture = "fx/animflame.tex"

local shader = "shaders/vfx_particle.ksh"
local add_shader = "shaders/vfx_particle_add.ksh"
local reveal_shader = "shaders/vfx_particle_reveal.ksh"


local colour_envelope_name_smoke = "torch_shadow_colourenvelope_smoke"
local scale_envelope_name_smoke = "torch_shadow_scaleenvelope_smoke"

local colour_envelope_name = "torch_shadow_colourenvelope"
local scale_envelope_name = "torch_shadow_scaleenvelope"

local colour_envelope_name_hand = "torch_shadow_colourenvelope_hand"
local scale_envelope_name_hand = "torch_shadow_scaleenvelope_hand"


local assets =
{
    Asset( "IMAGE", anim_hand_texture ),
    Asset( "IMAGE", anim_smoke_texture ),
    Asset( "IMAGE", fire_texture ),
    Asset( "SHADER", shader ),
    Asset( "SHADER", add_shader ),
    Asset( "SHADER", reveal_shader ),
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
				{ 0,    IntColour( 24, 24, 24, 64 ) },
				{ .2,   IntColour( 20, 20, 20, 240 ) },
				{ .7,   IntColour( 18, 18, 18, 256 ) },
                { 1,    IntColour( 12, 12, 12, 0 ) },
            } )

        local smoke_max_scale = 0.3
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name_smoke,
            {
                { 0,    { smoke_max_scale * 0.2, smoke_max_scale * 0.2} },
				{ .40,  { smoke_max_scale * 0.7, smoke_max_scale * 0.7} },
				{ .60,  { smoke_max_scale * 0.8, smoke_max_scale * 0.8} },
				{ .75,  { smoke_max_scale * 0.7, smoke_max_scale * 0.7} },
                { 1,    { smoke_max_scale, smoke_max_scale} },
            } )
	
        EnvelopeManager:AddColourEnvelope(
            colour_envelope_name,
            {   { 0,    IntColour( 200, 85, 60, 25 ) },
                { 0.19, IntColour( 200, 125, 80, 256 ) },
                { 0.35, IntColour( 255, 20, 10, 256 ) },
                { 0.51, IntColour( 255, 20, 10, 256 ) },
                { 0.75, IntColour( 255, 20, 10, 256 ) },
                { 1,    IntColour( 255, 7, 5, 0 ) },
            } )

		local fire_max_scale = 0.1
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name,
            {
                { 0,    { fire_max_scale * 0.5, fire_max_scale * 0.5 } },
                { 0.55, { fire_max_scale * 1.3, fire_max_scale * 1.3 } },
                { 1,    { fire_max_scale * 1.5, fire_max_scale * 1.5 } },
            } )
            
		EnvelopeManager:AddColourEnvelope(
            colour_envelope_name_hand,
            {
				{ 0,    IntColour( 24, 24, 24, 64 ) },
				{ .2,   IntColour( 20, 20, 20, 256 ) },
				{ .75,   IntColour( 18, 18, 18, 256 ) },
                { 1,    IntColour( 12, 12, 12, 0 ) },
            } )

        local hand_max_scale = 1
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name_hand,
            {
                { 0,    { hand_max_scale * 0.3, hand_max_scale * 0.3} },
                { 0.2,  { hand_max_scale * 0.7, hand_max_scale * 0.7} },
                { 1,    { hand_max_scale, hand_max_scale} },
            } )
	end
end

local smoke_max_lifetime = 1.1
local fire_max_lifetime = 0.9
local hand_max_lifetime = 1.7

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    InitEnvelope()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 3 )
    
    --SMOKE
    effect:SetRenderResources( 0, anim_smoke_texture, reveal_shader ) --reveal_shader --particle_add
    effect:SetMaxNumParticles( 0, 32 )
    effect:SetRotationStatus( 0, true )
    effect:SetMaxLifetime( 0, smoke_max_lifetime )
    effect:SetColourEnvelope( 0, colour_envelope_name_smoke )
    effect:SetScaleEnvelope( 0, scale_envelope_name_smoke )
    effect:SetBlendMode( 0, BLENDMODE.AlphaBlended ) --AlphaBlended Premultiplied
    effect:EnableBloomPass( 0, true )
    effect:SetUVFrameSize( 0, 1, 1 )
    effect:SetSortOrder( 0, 1 )
    
    --FIRE
    effect:SetRenderResources( 1, anim_smoke_texture, reveal_shader )
    effect:SetMaxNumParticles( 1, 32 )
    effect:SetRotationStatus( 1, true )
    effect:SetMaxLifetime( 1, fire_max_lifetime )
    effect:SetColourEnvelope( 1, colour_envelope_name )
    effect:SetScaleEnvelope( 1, scale_envelope_name )
    effect:SetBlendMode( 1, BLENDMODE.AlphaAdditive )
    effect:EnableBloomPass( 1, true )
    effect:SetUVFrameSize( 1, 1, 1 )
    effect:SetSortOrder( 1, 2 )
    effect:SetFollowEmitter( 1, true )
    
    --HAND
    effect:SetRenderResources( 2, anim_hand_texture, reveal_shader ) --reveal_shader --particle_add
    effect:SetMaxNumParticles( 2, 32 )
    effect:SetRotationStatus( 2, true )
    effect:SetMaxLifetime( 2, hand_max_lifetime )
    effect:SetColourEnvelope( 2, colour_envelope_name_hand )
    effect:SetScaleEnvelope( 2, scale_envelope_name_hand )
    effect:SetBlendMode( 2, BLENDMODE.AlphaBlended ) --AlphaBlended Premultiplied
    effect:EnableBloomPass( 2, true )
    effect:SetUVFrameSize( 2, 0.25, 1 )
    effect:SetSortOrder( 2, 1 )
    --effect:SetDragCoefficient( 2, 50 )
        

	inst.fx_offset = -100

    -----------------------------------------------------
    local tick_time = TheSim:GetTickTime()

    local smoke_desired_pps = 10
    local smoke_particles_per_tick = smoke_desired_pps * tick_time
    local smoke_num_particles_to_emit = -5 --start delay
	
    local fire_desired_pps = 6
	local fire_particles_per_tick = fire_desired_pps * tick_time
    local fire_num_particles_to_emit = 0

    local hand_desired_pps = 0.3
    local hand_particles_per_tick = hand_desired_pps * tick_time
    local hand_num_particles_to_emit = -1 ---50 --start delay
    
    
    local sphere_emitter = CreateSphereEmitter(0.05)

    local function emit_smoke_fn()
		--SMOKE
        local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()
        vy = vy + 0.06 + 0.02 * UnitRand()
        local lifetime = smoke_max_lifetime * (0.9 + UnitRand() * 0.1)
        local px, py, pz
        px, py, pz = sphere_emitter()
        py = py + 0.35 --offset the flame particles upwards a bit so they can be used on a torch

        effect:AddRotatingParticleUV(
            0,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            math.random() * 360,--* 2 * PI,	-- angle
            UnitRand() * 2,			-- angle velocity
            0, 0				-- uv offset
        )       
    end
    
    local function emit_fire_fn()            
        --FIRE
        local vx, vy, vz = 0.005 * UnitRand(), 0, 0.0005 * UnitRand()
        local lifetime = fire_max_lifetime * (0.9 + UnitRand() * 0.1)
		local px, py, pz
        px, py, pz = sphere_emitter()

        effect:AddRotatingParticleUV(
            1,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            math.random() * 360,	-- angle
            UnitRand() * 2,			-- angle velocity
            0, 0				-- uv offset
        )
    end
    
    local function emit_hand_fn()
		--HAND
        local vx, vy, vz = 0.0 * UnitRand(), (0.07 + 0.01 * UnitRand()), 0.0 * UnitRand()
        local px, py, pz
        px, py, pz = sphere_emitter()
        py = py + 0.65 --offset the flame particles upwards a bit so they can be used on a torch

        local uv_offset = math.random(0, 3) * 0.25
        
        effect:AddRotatingParticleUV(
            2,
            hand_max_lifetime,  -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            0 * math.random() * 360,--* 2 * PI,	-- angle
            UnitRand() * 1,			-- angle velocity
            uv_offset, 0				-- uv offset
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
        
		--HAND
        while hand_num_particles_to_emit > 1 do
            emit_hand_fn()
            hand_num_particles_to_emit = hand_num_particles_to_emit - 1
        end
        hand_num_particles_to_emit = hand_num_particles_to_emit + hand_particles_per_tick
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

return Prefab("torchfire_shadow", fn, assets)
