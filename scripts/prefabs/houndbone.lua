local assets =
{
    Asset("ANIM", "anim/hound_base.zip"),
}

local names = {"piece1","piece2","piece3","piece4"}

local function onsave(inst, data)
	data.anim = inst.animname
end

local function onload(inst, data)
    if data and data.anim then
        inst.animname = data.anim
	    inst.AnimState:PlayAnimation(inst.animname)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("hound_base")
    inst.AnimState:SetBank("houndbase")

    inst:AddTag("bone")

    --MakeSnowCoveredPristine(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.animname = names[math.random(#names)]
    inst.AnimState:PlayAnimation(inst.animname)

    -------------------
    inst:AddComponent("inspectable")
    
	--MakeSnowCovered(inst)
    inst.OnSave = onsave 
    inst.OnLoad = onload 
	return inst
end

return Prefab("forest/monsters/houndbone", fn, assets)