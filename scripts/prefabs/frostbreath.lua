local texture = "fx/frostbreath.tex"
local shader = "shaders/vfx_particle.ksh"
local colour_envelope_name = "breathcolourenvelope"
local scale_envelope_name = "breathscaleenvelope"

local assets =
{
	Asset( "IMAGE", texture ),
	Asset( "SHADER", shader ),
}

local min_scale = 0.4
local max_scale = 3

local function IntColour( r, g, b, a )
	return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local init = false
local function InitEnvelopes()
	
	if EnvelopeManager and not init then
		init = true
		EnvelopeManager:AddColourEnvelope(
			colour_envelope_name,
			{	{ 0,	IntColour( 255, 255, 255, 0 ) },
				{ 0.10,	IntColour( 255, 255, 255, 128 ) },
				{ 0.3,	IntColour( 255, 255, 255, 64 ) },
				{ 1,	IntColour( 255, 255, 255, 0 ) },
			} )

		EnvelopeManager:AddVector2Envelope(
			scale_envelope_name,
			{
				{ 0,	{ min_scale, min_scale } },
				{ 1,	{ max_scale, max_scale } },
			} )
	end
end

local max_lifetime = 2.5

local function Emit(inst)
	local effect = inst.VFXEffect
	local sphere_emitter = CreateSphereEmitter(0.05)

	local vx, vy, vz = 0, .005, 0
	local lifetime = max_lifetime * (0.9 + UnitRand() * 0.1)
	local px, py, pz

	px, py, pz = sphere_emitter()

	local angle = UnitRand() * 360
	local angular_velocity = UnitRand()*5

	effect:AddRotatingParticleUV(
		0,
		lifetime,			-- lifetime
		px, py, pz,			-- position
		vx, vy, vz,			-- velocity
		angle,				-- rotation
		angular_velocity,	-- angular_velocity :P
		0, 0				-- uv offset
	)

end

local function empty_func()
end

local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

	InitEnvelopes()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 1 )
	effect:SetRenderResources( 0, texture, shader )
	effect:SetRotationStatus( 0, true )
	effect:SetMaxNumParticles( 0, 64 )
	effect:SetMaxLifetime( 0, max_lifetime )
	effect:SetColourEnvelope( 0, colour_envelope_name )
	effect:SetScaleEnvelope( 0, scale_envelope_name );
	effect:SetBlendMode( 0, BLENDMODE.Premultiplied )
	effect:SetUVFrameSize( 0, 1.0, 1.0 )

	-----------------------------------------------------
	inst.Emit = Emit

	--local breath_period = 2.0
	--local particle_this_breath = false

	--local updateFunc = function()
		--local breathforce = math.sin(GetTime()/breath_period*math.pi*2)
		--if breathforce > 0 then
			--if particle_this_breath == false then
				--particle_this_breath = true
				--inst.Emit( inst, sphere_emitter )
			--end
		--else
			--particle_this_breath = false
		--end
	--end

	EmitterManager:AddEmitter(inst, nil, empty_func)--updateFunc)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddTag("FX")
    inst.persists = false

    return inst
end

return Prefab("frostbreath", fn, assets)