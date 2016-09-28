local prefabs =
{
	"collapse_big",
}

local assets =
{
    Asset("ANIM", "anim/dragonfly_furnace.zip"),
	Asset("MINIMAP_IMAGE", "dragonfly_furnace"),
}

local function getstatus(inst)
    return "HIGH"
end

local function onworkfinished(inst)
    inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_big")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("metal")
	inst:Remove()
end

local function onworked(inst)
    inst.AnimState:PlayAnimation("hi_hit")
    inst.AnimState:PushAnimation("hi")
end

local function GetHeatFn(inst, observer)
	return 115
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("hi_pre", false)
    inst.AnimState:PushAnimation("hi")
    inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/place")
    inst:DoTaskInTime(30 * FRAMES, function(inst)
		inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
		inst:DoTaskInTime(10 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/light")
			inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/fire_LP", "loop")
		end)
	end)
end

local function MakeGrill()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.persists = false

    inst.AnimState:SetBank("dragonfly_furnace")
    inst.AnimState:SetBuild("dragonfly_furnace")
    inst.AnimState:PlayAnimation("windowlight_idle")
    inst.AnimState:SetLightOverride(.6)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

    --inst:Hide()

    return inst
end

local function onsave(inst, data)
	if inst.salad then
		data.salad = true
	end
end

local function onload(inst, data)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/fire_LP", "loop")

	if data ~= nil and data.salad then
		inst.salad = true
		inst.AnimState:SetMultColour(.1, 1, .1, 1)
		inst:AddComponent("named")
		inst.components.named:SetName("Salad Furnace")
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

	inst.MiniMapEntity:SetIcon("dragonfly_furnace.png")

    inst.Light:Enable(true)
    inst.Light:SetRadius(1.0)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)
     
    inst.AnimState:SetBank("dragonfly_furnace")
    inst.AnimState:SetBuild("dragonfly_furnace")
    inst.AnimState:PlayAnimation("hi", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.4)

    inst:AddTag("structure")
    inst:AddTag("wildfireprotected")
    inst:AddTag("HASHEATER")
    inst:AddTag("iceblocker")
    inst:AddTag("cooker")

    if not TheNet:IsDedicated() then
        --inst._grill = MakeGrill()
        --inst._grill.entity:SetParent(inst.entity)
	end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    -----------------------
	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(6)
    inst.components.workable:SetOnFinishCallback(onworkfinished)
    inst.components.workable:SetOnWorkCallback(onworked)

    -----------------------
    inst:AddComponent("cooker")
    inst:AddComponent("lootdropper")

    -----------------------
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    -----------------------
    inst:AddComponent("heater")
    inst.components.heater.heatfn = GetHeatFn

    -----------------------
	MakeHauntableWork(inst)

    inst:ListenForEvent("onbuilt", onbuilt)
	inst.OnSave = onsave
	inst.OnLoad = onload
	
    return inst
end

local function saladfurnacefn()
	local inst = fn()
	inst.salad = true
	if not TheWorld.ismastersim then
		return inst
	end
	inst.AnimState:SetMultColour(.1, 1, .1, 1)
	inst:SetPrefabName("dragonflyfurnace")
	inst:AddComponent("named")
    inst.components.named:SetName("Salad Furnace")
	return inst
end

return Prefab("dragonflyfurnace", fn, assets, prefabs),
       Prefab("saladfurnace", saladfurnacefn, assets, prefabs),
       MakePlacer("dragonflyfurnace_placer", "dragonfly_furnace", "dragonfly_furnace", "idle")

