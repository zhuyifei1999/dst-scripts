local assets =
{
    Asset("ANIM", "anim/balloon.zip"),
    Asset("ANIM", "anim/balloon_shapes.zip"),
}

local colours =
{
    {198/255,43/255,43/255},
    {79/255,153/255,68/255},
    {35/255,105/255,235/255},
    {233/255,208/255,69/255},
    {109/255,50/255,163/255},
    {222/255,126/255,39/255},
}

local function onsave(inst, data)
    data.num = inst.balloon_num
    data.colour_idx = inst.colour_idx
end

local function onload(inst, data)
    if data then
        if data.num then
            inst.balloon_num = data.num
            inst.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_" .. tostring(inst.balloon_num))
        end
        
        if data.colour_idx then
            inst.colour_idx = math.min(#colours, data.colour_idx)
            inst.AnimState:SetMultColour(colours[inst.colour_idx][1],colours[inst.colour_idx][2],colours[inst.colour_idx][3],1)
        end
    end
end

local function DoAreaAttack(inst)
    inst.components.combat:DoAreaAttack(inst, 2)
end

local function OnDeath(inst)
    RemovePhysicsColliders(inst)
    inst.AnimState:PlayAnimation("pop")
    inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
    inst.DynamicShadow:Enable(false)
    inst:DoTaskInTime(.1 + math.random() * .2, DoAreaAttack)
end

local function oncollide(inst, other)
    
    local v1 = Vector3(inst.Physics:GetVelocity())
    local v2 = Vector3(other.Physics:GetVelocity()) 
    if v1:LengthSq() > .1 or v2:LengthSq() > .1 then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
        inst.SoundEmitter:PlaySound("dontstarve/common/balloon_bounce")
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .25)
    inst.Physics:SetFriction(.3)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(1)

    inst.AnimState:SetBank("balloon")
    inst.AnimState:SetBuild("balloon")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetRayTestOnBB(true)

    inst.DynamicShadow:SetSize(1, .5)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.Physics:SetCollisionCallback(oncollide)

    inst.AnimState:SetTime(math.random() * 2)

    inst.balloon_num = math.random(4)
    inst.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes", "balloon_"..tostring(inst.balloon_num))
    inst.colour_idx = math.random(#colours)
    inst.AnimState:SetMultColour(colours[inst.colour_idx][1], colours[inst.colour_idx][2], colours[inst.colour_idx][3], 1)

    inst:AddComponent("inspectable")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(5)
    inst:ListenForEvent("death", OnDeath)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)

    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown_on_successful_haunt = false
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    inst.components.hauntable:SetOnHauntFn(function(inst,haunter)
        OnDeath(inst)
        return true
    end)

	--MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    inst.OnSave = onsave
    inst.OnLoad = onload
    return inst
end

return Prefab("common/balloon", fn, assets)