local assets =
{
    Asset("ANIM", "anim/fossil_stalker.zip"),
}

local prefabs =
{
	"fossil_piece_clean",
	"collapse_small",
}

local MAX_MOUND_SIZE = 8
local MOUND_WRONG_START_SIZE = 5

local function UpdateFossileMound(inst, size, checkforwrong)
	if checkforwrong then
		if inst.moundsize < MOUND_WRONG_START_SIZE and size >= MOUND_WRONG_START_SIZE then
			inst.wrong = math.random() < 0.5
		end
	end
	
	inst.moundsize = size
	inst.components.workable:SetWorkLeft(size)
	inst.AnimState:PlayAnimation(((size >= MOUND_WRONG_START_SIZE and inst.wrong) and "wrong" or "")..inst.moundsize)
end

local function lootsetfn(lootdropper)
	local loot = {}
	for i= 1,lootdropper.inst.moundsize do
		table.insert(loot, "fossil_piece_clean")
	end
    lootdropper:SetLoot(loot)
end

local function onworked(inst)

	local pos = inst:GetPosition()
    local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(pos:Get())
	fx:SetMaterial("rock")

	inst.components.lootdropper:DropLoot(pos)
	inst:Remove()
end

local function onrepaired(inst)
	local size = inst.moundsize + 1
	UpdateFossileMound(inst, size, true)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/together/fossil/repair")
end

local function getstatus(inst)
	if inst.moundsize == MAX_MOUND_SIZE then
		return inst.wrong and "FUNNY" or "COMPLETE"
	end
	
    return "GENERIC"
end

local function onsave(inst, data)
    data.moundsize = inst.moundsize
    data.wrong = inst.wrong
end

local function onload(inst, data)
	if data ~= nil then
		inst.wrong = data.wrong
	    UpdateFossileMound(inst, data.moundsize, false)
	end
end

local function makemound( name )

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		MakeObstaclePhysics(inst, .45)

		inst.AnimState:SetBank(name)
		inst.AnimState:SetBuild(name)
		inst.AnimState:PlayAnimation("1")

		inst:AddTag("structure")
		--MakeSnowCoveredPristine(inst)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = getstatus
		
		inst:AddComponent("lootdropper")
		inst.components.lootdropper:SetLootSetupFn(lootsetfn)

		inst:AddComponent("workable")
	    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	    inst.components.workable:SetMaxWork(MAX_MOUND_SIZE)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnWorkCallback(onworked)
		inst.components.workable.savestate = true

        inst:AddComponent("repairable")
        inst.components.repairable.repairmaterial = MATERIALS.FOSSIL
        inst.components.repairable.onrepaired = onrepaired
        inst.components.repairable.noannounce = true

		MakeHauntableWork(inst)
		--MakeSnowCovered(inst)

		UpdateFossileMound(inst, 1)

		inst.OnSave = onsave
		inst.OnLoad = onload

		return inst
	end
	
	return Prefab(name, fn, assets)
end

return makemound("fossil_stalker")
