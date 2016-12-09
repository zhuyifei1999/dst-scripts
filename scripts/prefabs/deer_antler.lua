local prefabs = 
{
	"deer_antler1",
	"deer_antler2",
	"deer_antler3",
}

local function setantlertype(inst, antlertype)
	inst.antlertype = antlertype
	inst.AnimState:PlayAnimation("idle"..tostring(antlertype))
	inst.components.inventoryitem:ChangeImageName("deer_antler"..tostring(antlertype))
end

local function onsave(inst, data)
    data.antlertype = inst.antlertype
end

local function onload(inst, data)
    setantlertype(inst, data ~= nil and data.antlertype or 1)
end

local function MakeAntler(antlertype, trueklaussackkey)
	local assets =
	{
		Asset("ANIM", "anim/deer_antler.zip"),
		Asset("INV_IMAGE", "deer_antler"..tostring(antlertype or 1)),
	}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank("deer_antler")
		inst.AnimState:SetBuild("deer_antler")
		inst.AnimState:PlayAnimation("idle"..tostring(antlertype or 1))

		inst:AddTag("deerantler")
		inst:AddTag("klaussackkey")

		if trueklaussackkey then
			inst:AddTag("trueklaussackkey")
			inst:AddTag("irreplaceable")
		else
	        inst:SetPrefabName("deer_antler")
		end

		inst.entity:SetPristine()
		
		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")
		inst:AddComponent("inventoryitem")
		inst:AddComponent("klaussackkey")

		MakeHauntableLaunch(inst)
		
		if trueklaussackkey then
			inst.components.inventoryitem:ChangeImageName("deer_antler"..tostring(antlertype))
		else
			inst.OnSave = onsave
			inst.OnLoad = onload

			setantlertype(inst, antlertype or 1)
		end
		
		return inst
	end

	local prefabname = trueklaussackkey and "klaussackkey" or "deer_antler"..tostring(antlertype or "")

	return Prefab(prefabname, fn, assets, antlertype == nil and prefabs or nil)
end

return MakeAntler(),
		MakeAntler(1),
		MakeAntler(2),
		MakeAntler(3),
		MakeAntler(4, true)