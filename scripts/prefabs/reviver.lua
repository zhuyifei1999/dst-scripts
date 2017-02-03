local assets =
{
    Asset("ANIM", "anim/bloodpump.zip"),
}

local function beat(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve/ghost/bloodpump")
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end

local function beatfx_start(inst)
	local skin_fx = SKIN_FX_PREFAB[inst:GetSkinName()] or {}
    local beat_fx = skin_fx[1] --slot 1 in the skin data is the beatfx
	if beat_fx ~= nil then
		local fx = SpawnPrefab(beat_fx)
		fx.entity:SetParent(inst.entity)
		fx.entity:AddFollower()
		fx.Follower:FollowSymbol(inst.GUID, "bloodpump02", -5, -30, 0)

		inst.beat_fx = fx
	end
	inst.beatfx_start_task = nil
end

local function ondropped(inst)
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
    end
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
    
    inst.beatfx_start_task = inst:DoTaskInTime(0, beatfx_start)
end

local function onpickup(inst)
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
        inst.beattask = nil
    end
    
    if inst.beatfx_start_task ~= nil then
        inst.beatfx_start_task:Cancel()
        inst.beatfx_start_task = nil
    end
    
    if inst.beat_fx ~= nil then
		inst.beat_fx:Remove()
		inst.beat_fx = nil
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bloodpump01")
    inst.AnimState:SetBuild("bloodpump")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(onpickup)

    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")

    MakeHauntableLaunch(inst)

	inst.beattask = nil
	ondropped(inst)
		
    return inst
end

return Prefab("reviver", fn, assets)
