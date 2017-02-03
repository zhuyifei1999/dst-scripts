local assets =
{
    Asset("ANIM", "anim/antlion_sinkhole.zip"),
    Asset("MINIMAP_IMAGE", "sinkhole"),
}

local prefabs =
{
    "sinkhole_spawn_fx_1",
    "sinkhole_spawn_fx_2",
    "sinkhole_spawn_fx_3",
}

local NUM_CRACKING_STAGES = 3
local COLLAPSE_STAGE_DURATION = 0.9


local function UpdateOverrideSymbols(inst, state)
	if state == NUM_CRACKING_STAGES then
		inst.AnimState:ClearOverrideSymbol("cracks1")
		inst.components.unevenground:Enable()
	else
		inst.AnimState:OverrideSymbol("cracks1", "antlion_sinkhole", "cracks_pre"..tostring(state))
		inst.components.unevenground:Disable()
	end
end

local function UpdateSinkholeRepair(inst)
	if inst.collapsetask == nil then
		local age = (TheWorld.state.cycles + TheWorld.state.time) - inst.creataiontime
		if age < TUNING.ANTLION_SINKHOLE.LIFETIME_FIRST_REPAIR then
			UpdateOverrideSymbols(inst, 3)
		elseif age < TUNING.ANTLION_SINKHOLE.LIFETIME_SECOND_REPAIR then
			UpdateOverrideSymbols(inst, 2)
		elseif age < TUNING.ANTLION_SINKHOLE.LIFETIME_FINAL_REPAIR then
			UpdateOverrideSymbols(inst, 1)
		else
			inst:Remove()
		end
	end
end

local function donextcollapse(inst)
	inst.collapsestage = inst.collapsestage + 1

	local isfinalstage = inst.collapsestage >= NUM_CRACKING_STAGES

	if isfinalstage then
		inst.collapsetask:Cancel()
		inst.collapsetask = nil

	    inst:RemoveTag("scarytoprey")
		ShakeAllCameras(CAMERASHAKE.FULL, COLLAPSE_STAGE_DURATION, .03, .15, inst, TUNING.ANTLION_SINKHOLE.RADIUS*6)
	else
		ShakeAllCameras(CAMERASHAKE.FULL, COLLAPSE_STAGE_DURATION, .015, .15, inst, TUNING.ANTLION_SINKHOLE.RADIUS*4)
	end

	UpdateOverrideSymbols(inst, inst.collapsestage)

	local dir = math.random()*PI*2
	local num = 7
	local radius = 1.6
	SpawnPrefab("sinkhole_spawn_fx_"..math.random(3)).Transform:SetPosition(inst:GetPosition():Get())
	for i = 1, num do
		local function spawnit(inst)
			local dust=SpawnPrefab("sinkhole_spawn_fx_"..math.random(3))
			dust.Transform:SetPosition((inst:GetPosition() + Vector3(math.cos(dir)*radius*(1+math.random()*0.1), 0, -math.sin(dir))*radius*(1+math.random()*0.1)):Get())
			local scale = .8 + math.random() * .5
			dust.Transform:SetScale(scale * (i%2==0 and -1 or 1), scale, scale)
			dir = dir + ((2*PI) / num)
		end
		spawnit(inst)
	end

	inst.SoundEmitter:PlaySoundWithParams("dontstarve/creatures/together/antlion/sfx/ground_break", {size=math.pow(inst.collapsestage/NUM_CRACKING_STAGES, 2)})

	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, TUNING.ANTLION_SINKHOLE.RADIUS + 1, nil, {"flying", "bird"})
	for i,v in ipairs(ents) do
		if v.components.workable ~= nil and v.components.workable:CanBeWorked() then
			if isfinalstage then
				v.components.workable:Destroy(inst)
			else
				v.components.workable:WorkedBy(inst, 1)
			end
		elseif v.components.pickable ~= nil then
			if v.components.pickable:CanBePicked() then
				local num = v.components.pickable.numtoharvest or 1
				local product = v.components.pickable.product
				local pt = v:GetPosition()
				v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
				if product and num then
					for i = 1, num do
						local loot = SpawnPrefab(product)
						loot.Transform:SetPosition(pt:Get())
						Launch(loot, inst, 0)
					end
				end
			end
		elseif v:IsValid() and
			v.components.combat ~= nil and
			v.components.health ~= nil and
			(inst.collapsestage > 1 or (not v:HasTag("player") and not v:HasTag("smallcreature"))) and
			not v.components.health:IsDead() then

            v.components.combat:GetAttacked(inst, TUNING.ANTLION_SINKHOLE.DAMAGE)
		end
	end
end

local function onstartcollapse(inst)
	inst.collapsestage = 0
	inst.creataiontime = (TheWorld.state.cycles + TheWorld.state.time) - math.random() * TUNING.ANTLION_SINKHOLE.LIFETIME_VARIANCE

    inst:AddTag("scarytoprey")

	inst.collapsetask = inst:DoPeriodicTask(COLLAPSE_STAGE_DURATION, donextcollapse)
	donextcollapse(inst)
end

-------------------------------------------------------------------------------

local function OnSave(inst, data)
	data.creataiontime = inst.creataiontime

	if inst.collapsetask ~= nil then
		data.collapsestage = inst.collapsestage
	end
end

local function OnLoad(inst, data)
	inst.creataiontime = data ~= nil and data.creataiontime or 0

	if data ~= nil and data.collapsestage then
		inst.collapsestage = data.collapsestage
		UpdateOverrideSymbols(inst, inst.collapsestage)
		inst.collapsetask = inst:DoPeriodicTask(COLLAPSE_STAGE_DURATION, donextcollapse)
	else
		UpdateSinkholeRepair(inst)
	end
end


-------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("sinkhole")
    inst.AnimState:SetBuild("antlion_sinkhole")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("sinkhole.png")

    inst.Transform:SetEightFaced()

    inst:AddTag("antlion_sinkhole")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("workrepairable")

    inst.deploy_spacing = 4

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("terraformer")

    inst:AddComponent("unevenground")
    inst.components.unevenground.radius = TUNING.ANTLION_SINKHOLE.UNEVENGROUND_RADIUS

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    inst.OnEntitySleep = UpdateSinkholeRepair
    inst.OnEntityWake = UpdateSinkholeRepair

	inst.creataiontime = 0

	inst:ListenForEvent("startcollapse", onstartcollapse)

    return inst
end

return Prefab("antlion_sinkhole", fn, assets, prefabs)
