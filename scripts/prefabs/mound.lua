local assets =
{
	Asset("ANIM", "anim/gravestones.zip"),
}

local prefabs =
{
	"ghost",
	"amulet",
	"redgem",
	"gears",
	"bluegem",
	"nightmarefuel",
}

for k = 1, NUM_TRINKETS do
    table.insert(prefabs, "trinket_"..tostring(k))
end

local LOOTS =
{
    nightmarefuel = 1,
    amulet = 1,
    gears = 1,
    redgem = 5,
    bluegem = 5,
}

local function spawnghost(inst, chance)
    if inst.ghost == nil and math.random() <= (chance or 1) then
        inst.ghost = SpawnPrefab("ghost")
        if inst.ghost ~= nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.ghost.Transform:SetPosition(x - .3, y, z - .3)
            inst:ListenForEvent("onremove", function() inst.ghost = nil end, inst.ghost)
            return true
        end
    end
    return false
end

local function onfinishcallback(inst, worker)
    inst.AnimState:PlayAnimation("dug")
    inst:RemoveComponent("workable")

	if worker ~= nil then
		if worker.components.sanity ~= nil then
			worker.components.sanity:DoDelta(-TUNING.SANITY_SMALL)
		end
		if not spawnghost(inst, .1) and worker.components.inventory ~= nil then
			local item = nil
			if math.random() < .5 then
				item = weighted_random_choice(LOOTS)
			else
				item = "trinket_"..tostring(math.random(NUM_TRINKETS))
			end

			if item ~= nil then
				inst.components.lootdropper:SpawnLootPrefab(item)
			end
		end
	end	
end

local function GetStatus(inst)
    if not inst.components.workable then            
        return "DUG"
    end
end

local function OnSave(inst, data)
    if inst.components.workable == nil then
        data.dug = true
    end
end        

local function OnLoad(inst, data)
    if data ~= nil and data.dug or inst.components.workable == nil then
        inst:RemoveComponent("workable")
        inst.AnimState:PlayAnimation("dug")
    end
end

local function OnHaunt(inst, haunter)
    return spawnghost(inst, TUNING.HAUNT_CHANCE_HALF)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("gravestone")
    inst.AnimState:SetBuild("gravestones")
    inst.AnimState:PlayAnimation("gravedirt")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
	inst:AddComponent("lootdropper")
        
    inst.components.workable:SetOnFinishCallback(onfinishcallback)

    inst.ghost = nil

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("common/objects/mound", fn, assets, prefabs)