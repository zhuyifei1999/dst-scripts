local glow_texture = "fx/heartglow.tex"

local shader = "shaders/vfx_particle_add.ksh"

local colour_envelope_name_heart = "cupid_beat1_colourenvelope"
local scale_envelope_name_heart = "cupid_beat1_scaleenvelope"

local assets =
{
    Asset( "IMAGE", glow_texture ),
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
            colour_envelope_name_heart,
            {
				{ 0,    IntColour( 255, 0, 0, 0 ) },
				{ .2,   IntColour( 255, 0, 0, 30 ) },
				{ .65,   IntColour( 255, 0, 0, 7 ) },
                { 1,    IntColour( 255, 0, 0, 0 ) },
            } )

        local heart_max_scale = 3.7
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name_heart,
            {
                { 0,    { heart_max_scale * 0.2, heart_max_scale * 0.2} },
				{ .40,  { heart_max_scale * 0.7, heart_max_scale * 0.7} },
				{ .60,  { heart_max_scale * 0.8, heart_max_scale * 0.8} },
				{ .75,  { heart_max_scale * 0.9, heart_max_scale * 0.9} },
                { 1,    { heart_max_scale, heart_max_scale} },
            } )
	end
end

local heart_lifetime = 1

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    InitEnvelope()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 1 )
    
    effect:SetRenderResources( 0, glow_texture, shader )
    effect:SetMaxNumParticles( 0, 4 )
    effect:SetMaxLifetime( 0, heart_lifetime )
    effect:SetRotationStatus( 0, true )
    effect:SetColourEnvelope( 0, colour_envelope_name_heart )
    effect:SetScaleEnvelope( 0, scale_envelope_name_heart )
    effect:SetBlendMode( 0, BLENDMODE.Additive )
    effect:EnableBloomPass( 0, true )
    effect:SetUVFrameSize( 0, 1, 1 )
    effect:SetSortOrder( 0, 1 )
    effect:SetSortOffset( 0, 1 )

    local function updateFunc()
		--sync the particle bursting with the star tof the animation, and then wait until the next start
		local parent = inst.entity:GetParent()
		if parent.AnimState:GetCurrentAnimationTime() < 0.1 then
			if inst.wait_for_burst then
				effect:AddRotatingParticle(
					0,
					heart_lifetime, -- lifetime
					0, 0, 0,        -- position
					0, 0, 0,         -- velocity
					UnitRand() * 3, -- angle
					UnitRand() * 0.5	 -- angular_velocity
				)
				inst.wait_for_burst = false
			end
		else
			inst.wait_for_burst = true
		end
    end
	
    EmitterManager:AddEmitter(inst, nil, updateFunc)
	
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("reviver_cupid_beat_fx", fn, assets)
