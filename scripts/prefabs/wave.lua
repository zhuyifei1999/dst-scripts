local GroundTiles = require("worldtiledefs")

local waveassets =
{
	Asset( "ANIM", "anim/wave.zip" ),
}

local splashassets =
{
    Asset( "ANIM", "anim/splash_water_rot.zip" ),
}

local prefabs =
{
    "wave_splash",
}

local SPLASH_WETNESS = 9

local function do_splash(inst)

    local wave_splash = SpawnPrefab("wave_splash")
    local pos = inst:GetPosition()
    TintByOceanTile(wave_splash)
    wave_splash.Transform:SetPosition(pos.x, pos.y, pos.z)

    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 4)
    for _, v in pairs(ents) do
        local moisture = v.components.moisture
        if moisture ~= nil then
            local waterproofness = (v.components.inventory and math.min(v.components.inventory:GetWaterproofness(), 1)) or 0
            moisture:DoDelta(SPLASH_WETNESS * (1 - waterproofness))

            local entity_splash = SpawnPrefab("splash")
            entity_splash.Transform:SetPosition(v:GetPosition():Get())
        end
    end

    inst:Remove()
end

local function oncollidewave(inst, other)
    if other and (inst.waveactive or not other:HasTag("wave")) then
        if other.collisionboat and inst.waveactive then
            local vx, vy, vz = inst.Physics:GetVelocity()
            local speed_modifier = VecUtil_Length(vx, vz)
            vx,vz = VecUtil_Normalize(vx,vz)

        local boat_physics = other.collisionboat.components.boatphysics
            boat_physics:ApplyForce(vx, vz, speed_modifier)
        end

        do_splash(inst)
    end
end 

local function CheckGround(inst)
    --Check if I'm about to hit land
    local x, y, z = inst.Transform:GetWorldPosition()
    local vx, vy, vz = inst.Physics:GetVelocity()

    if TheWorld.Map:IsVisualGroundAtPoint(x + vx, y, z + vz) then
        do_splash(inst)
    end
end 

local function onRemove(inst)
    if inst and inst.soundloop then
        inst.SoundEmitter:KillSound(inst.soundloop)
    end
end

local function med_fn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetEightFaced()

    inst.AnimState:SetBuild("wave")
    inst.AnimState:SetBank("wave_ripple")
    
    TintByOceanTile(inst)
    
    MakeCharacterPhysics(inst, 100, 1)

    inst:AddTag("scarytoprey")
    inst:AddTag("wave")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false

    inst.checkgroundtask = inst:DoPeriodicTask(0.5, CheckGround)

    inst.OnEntitySleep = inst.Remove

    inst.Physics:SetCollisionCallback(oncollidewave)
    inst.waveactive = false

    inst:SetStateGraph("SGwave")

    return inst
end

local function wavesplash_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("splash_water_rot")
    inst.AnimState:SetBank("splash_water_rot")
    inst.AnimState:PlayAnimation("idle")

	inst.Transform:SetScale(0.7, 0.7, 0.7)

    inst:AddTag("FX")

    if not TheNet:IsDedicated() then
		inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small", nil, nil, true)
	end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false

    inst.AnimState:SetTime(math.random() / 3)

    inst:ListenForEvent("animover", inst.Remove)
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 0.1, inst.Remove)

    return inst
end 

return Prefab( "wave_med", med_fn, waveassets, prefabs ),
       Prefab( "wave_splash", wavesplash_fn, splashassets)
