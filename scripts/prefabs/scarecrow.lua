require "prefabutil"


local assets =
{
    Asset("ANIM", "anim/scarecrow.zip"),
    Asset("ANIM", "anim/swap_scarecrow_face.zip"),
}

local prefabs =
{
    "collapse_big",
}

local numfaces =
{
	hit = 4,
	scary = 10,
	screaming = 3,
}

local function ChangeFace(inst, prefix)
	if inst:HasTag("fire") then
		prefix = "screaming"
	end
	prefix = prefix or "scary"
	
	local prev_face = inst.face or 1
	inst.face = math.random(numfaces[prefix]-1)
	if inst.face >= prev_face then
		inst.face = inst.face + 1
	end
	
	inst.AnimState:OverrideSymbol("swap_scarecrow_face", "swap_scarecrow_face", prefix.."face"..inst.face)
end

local function onhammered(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        ChangeFace(inst, "hit")
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.SoundEmitter:PlaySound("dontstarve/common/scarecrow_craft")
end

local function onburnt(inst)
	DefaultBurntStructureFn(inst)
	inst:RemoveTag("scarecrow")
end

local function onignite(inst)
	DefaultBurnFn(inst)
	ChangeFace(inst)
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.4)

    inst:AddTag("structure")
    inst:AddTag("scarecrow")

    inst.MiniMapEntity:SetIcon("scarecrow.png")

    inst.AnimState:SetBank("scarecrow")
    inst.AnimState:SetBuild("scarecrow")
    inst.AnimState:PlayAnimation("idle")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(6)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeMediumBurnable(inst, nil, nil, true)
    inst.components.burnable.onburnt = onburnt
    inst.components.burnable:SetOnIgniteFn(onignite)
    MakeMediumPropagator(inst)

    MakeSnowCovered(inst)
    MakeHauntableWork(inst)
    
    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnEntityWake = ChangeFace

    inst.OnSave = onsave
    inst.OnLoad = onload

    ChangeFace(inst)

    return inst
end

return Prefab("scarecrow", fn, assets, prefabs),
    MakePlacer("scarecrow_placer", "scarecrow", "scarecrow", "idle")
