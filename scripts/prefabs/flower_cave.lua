local assets =
{
	Asset("ANIM", "anim/bulb_plant_single.zip"),
	Asset("ANIM", "anim/bulb_plant_double.zip"),
	Asset("ANIM", "anim/bulb_plant_triple.zip"),
	Asset("ANIM", "anim/bulb_plant_springy.zip"),
	Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
	"lightbulb"
}

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow") 
	inst.AnimState:PushAnimation("idle", true)
	inst.Light:Enable(true)
end

local function makefullfn(inst)
	inst.AnimState:PlayAnimation("idle", true)
	inst.Light:Enable(true)
end

local function onpickedfn(inst)
	inst.Light:Enable(false)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lightbulb") 
	inst.AnimState:PlayAnimation("picking") 
	
	if inst.components.pickable:IsBarren() then
		inst.AnimState:PushAnimation("idle_dead")
	else
		inst.AnimState:PushAnimation("picked")
	end
end

local function makeemptyfn(inst)
	inst.Light:Enable(false)
	inst.AnimState:PlayAnimation("picked")
end

local function commonfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end
        
	--inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst.MiniMapEntity:SetIcon("bulb_plant.png")

    inst.AnimState:SetTime(math.random() * 2)
    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("pickable")
	inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

	inst.components.pickable.onregenfn = onregenfn
	inst.components.pickable.onpickedfn = onpickedfn
	inst.components.pickable.makeemptyfn = makeemptyfn
	inst.components.pickable.makefullfn = makefullfn
	inst.components.pickable.max_cycles = 20
	inst.components.pickable.cycles_left = 20

	inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    inst.components.inspectable.nameoverride = "flower_cave"

    ---------------------        
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    ---------------------   

    return inst
end

local plantnames = {"_single", "_springy"}

local function onsave(inst, data)
	data.plantname = inst.plantname
end

local function onload(inst,data)
	if data ~= nil and data.plantname ~= nil then
		inst.plantname = data.plantname
        inst.AnimState:SetBank("bulb_plant"..inst.plantname)
        inst.AnimState:SetBuild("bulb_plant"..inst.plantname)
	end
end

local function single()
	local inst = commonfn()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.plantname = plantnames[math.random(1, #plantnames)]
	inst.AnimState:SetBank("bulb_plant"..inst.plantname)
	inst.AnimState:SetBuild("bulb_plant"..inst.plantname)

	inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME)

	inst.Light:SetFalloff(0.5)
	inst.Light:SetIntensity(.8)
	inst.Light:SetRadius(1.5)
	inst.Light:SetColour(237/255, 237/255, 209/255)
	inst.Light:Enable(true)

	inst.OnSave = onsave
	inst.OnLoad = onload

    inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetTime(math.random() * 2)    
	return inst
end

local function double()
	local inst = commonfn()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.AnimState:SetBank("bulb_plant_double")
	inst.AnimState:SetBuild("bulb_plant_double")

	inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME * 1.5, 2)

	inst.Light:SetFalloff(0.5)
	inst.Light:SetIntensity(.8)
	inst.Light:SetRadius(2.5)
	inst.Light:SetColour(237/255, 237/255, 209/255)
	inst.Light:Enable(true)

	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetTime(math.random() * 2)    
	return inst
end

local function triple()
	local inst = commonfn()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.AnimState:SetBank("bulb_plant_triple")
	inst.AnimState:SetBuild("bulb_plant_triple")

	inst.components.pickable:SetUp("lightbulb", TUNING.FLOWER_CAVE_REGROW_TIME * 2, 3)

	inst.Light:SetFalloff(0.5)
	inst.Light:SetIntensity(.8)
	inst.Light:SetRadius(2.5)
	inst.Light:SetColour(237/255, 237/255, 209/255)
	inst.Light:Enable(true)

    inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetTime(math.random() * 2)    
	return inst
end

return Prefab("cave/objects/flower_cave", single, assets, prefabs),
Prefab("cave/objects/flower_cave_double", double, assets, prefabs),
Prefab("cave/objects/flower_cave_triple", triple, assets, prefabs)