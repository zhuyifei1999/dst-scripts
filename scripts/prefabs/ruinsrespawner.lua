local function onnewobjectfn(inst, obj)
    inst:ListenForEvent("onremove", function(obj)
        RemoveByValue(inst.components.objectspawner.objects, obj)
    end, obj)
end

local function tryspawn(inst)
    if inst.resetruins and #inst.components.objectspawner.objects <= 0 then
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, 1, nil, { "INLIMBO" })) do
            if v.components.workable ~= nil and v.components.workable:GetWorkAction() ~= ACTIONS.NET then
                v.components.workable:Destroy(v)
            end
        end

        local obj = inst.components.objectspawner:SpawnObject(inst.spawnprefab)
        obj.Transform:SetPosition(x, y, z)
  		if inst.onrespawnfn ~= nil then
			inst.onrespawnfn(obj, inst)
		end

    end

    inst.resetruins = nil
end

local function onsave(inst, data)
    data.resetruins = inst.resetruins
end

local function onload(inst, data)
    if data ~= nil then
        inst.resetruins = data.resetruins
    end
end

local function MakeFn(obj, onrespawnfn)
	local fn = function()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		--[[Non-networked entity]]

		inst:AddTag("CLASSIFIED")

		inst.spawnprefab = obj
		inst.onrespawnfn = onrespawnfn

		inst:AddComponent("objectspawner")
		inst.components.objectspawner.onnewobjectfn = onnewobjectfn

		inst:ListenForEvent("resetruins", function()
			inst.resetruins = true
			inst:DoTaskInTime(math.random()*0.75, function() tryspawn(inst) end)
		end, TheWorld)

		inst.OnSave = onsave
		inst.OnLoad = onload

		return inst
	end
	return fn
end

local function MakeRuinsRespawnerInst(obj, onrespawnfn)
	return Prefab(obj.."_ruinsrespawner_inst", MakeFn(obj, onrespawnfn), nil, { obj, obj.."_spawner" })
end

local function MakeRuinsRespawnerWorldGen(obj, onrespawnfn)
	local function worldgenfn()
		local inst = MakeFn(obj, onrespawnfn)()

		inst:SetPrefabName(obj.."_ruinsrespawner_inst")
		
        inst.resetruins = true
		inst:DoTaskInTime(0, tryspawn)

		return inst
	end

	return Prefab(obj.."_spawner", worldgenfn, nil, { obj })
end

return {Inst = MakeRuinsRespawnerInst, WorldGen = MakeRuinsRespawnerWorldGen}
