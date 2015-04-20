local assets =
{
    Asset("ANIM", "anim/gravestones.zip"),
}

local prefabs =
{
    "ghost",
    "mound",
}

local function onsave(inst, data)
	if inst.mound then
		data.mounddata = inst.mound:GetSaveRecord()
	end

	if inst.setepitaph then
		data.setepitaph = inst.setepitaph
	end
end

local function onload(inst, data, newents)
	if data then
		if inst.mound and data.mounddata then
	        if newents and data.mounddata.id then
	            newents[data.mounddata.id] = {entity=inst.mound, data=data.mounddata} 
	        end
			inst.mound:SetPersistData(data.mounddata.data, newents)
		end

		if data.setepitaph then	
			--this handles custom epitaphs set in the tile editor		
	    	inst.components.inspectable:SetDescription("'"..data.setepitaph.."'")
	    	inst.setepitaph = data.setepitaph
		end
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .25)

    inst.MiniMapEntity:SetIcon("gravestones.png")

    inst:AddTag("grave")

    inst.AnimState:SetBank("gravestone")
    inst.AnimState:SetBuild("gravestones")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:PlayAnimation("grave"..tostring(math.random(4)))

    inst:AddComponent("inspectable")	
    inst.components.inspectable:SetDescription( STRINGS.EPITAPHS[math.random(#STRINGS.EPITAPHS)] )	    	

    inst.mound = inst:SpawnChild("mound")

    --local pos = Vector3(0,0,0)
    --pos.x = pos.x -.407
    --pos.z = pos.z -.407

    inst.OnLoad = onload
    inst.OnSave = onsave

    inst.mound.Transform:SetPosition((TheCamera:GetDownVec()*.5):Get())

    return inst
end

return Prefab("common/objects/gravestone", fn, assets, prefabs)