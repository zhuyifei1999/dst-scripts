require "prefabutil"

local cooking = require("cooking")

local assets =
{
	Asset("ANIM", "anim/cook_pot.zip"),
	Asset("ANIM", "anim/cook_pot_food.zip"),
}

local prefabs = {}
for k,v in pairs(cooking.recipes.cookpot) do
	table.insert(prefabs, v.name)
end

local function onhammered(inst, worker)
	if inst.components.stewer.product and inst.components.stewer.done then
		inst.components.lootdropper:AddChanceLoot(inst.components.stewer.product, 1)
	end
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")
	inst:Remove()
end

local function onhit(inst, worker)
	
	inst.AnimState:PlayAnimation("hit_empty")
	
	if inst.components.stewer.cooking then
		inst.AnimState:PushAnimation("cooking_loop")
	elseif inst.components.stewer.done then
		inst.AnimState:PushAnimation("idle_full")
	else
		inst.AnimState:PushAnimation("idle_empty")
	end
	
end

--anim and sound callbacks

local function startcookfn(inst)
	inst.AnimState:PlayAnimation("cooking_loop", true)
	--play a looping sound
	inst.SoundEmitter:KillSound("snd")
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
	inst.Light:Enable(true)
end

local function onopen(inst)
	inst.AnimState:PlayAnimation("cooking_pre_loop", true)
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open", "open")
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot", "snd")
end

local function onclose(inst)
	if not inst.components.stewer.cooking then
		inst.AnimState:PlayAnimation("idle_empty")
		inst.SoundEmitter:KillSound("snd")
	end
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close", "close")
end

local function donecookfn(inst)
	inst.AnimState:PlayAnimation("cooking_pst")
	inst.AnimState:PushAnimation("idle_full")
	inst.AnimState:OverrideSymbol("swap_cooked", "cook_pot_food", inst.components.stewer.product)
	
	inst.SoundEmitter:KillSound("snd")
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish", "snd")
	inst.Light:Enable(false)
	--play a one-off sound
end

local function continuedonefn(inst)
	inst.AnimState:PlayAnimation("idle_full")
	inst.AnimState:OverrideSymbol("swap_cooked", "cook_pot_food", inst.components.stewer.product)
end

local function continuecookfn(inst)
	inst.AnimState:PlayAnimation("cooking_loop", true)
	--play a looping sound
	inst.Light:Enable(true)

	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
end

local function harvestfn(inst)
	inst.AnimState:PlayAnimation("idle_empty")
end

local function getstatus(inst)
	if inst.components.stewer.cooking and inst.components.stewer:GetTimeToCook() > 15 then
		return "COOKING_LONG"
	elseif inst.components.stewer.cooking then
		return "COOKING_SHORT"
	elseif inst.components.stewer.done then
		return "DONE"
	else
		return "EMPTY"
	end
end

local function onfar(inst)
	inst.components.container:Close()
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle_empty")
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

    inst.MiniMapEntity:SetIcon("cookpot.png")
    
    inst.Light:Enable(false)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235/255,62/255,12/255)
    --inst.Light:SetColour(1,0,0)

    inst:AddTag("structure")
    
    inst.AnimState:SetBank("cook_pot")
    inst.AnimState:SetBuild("cook_pot")
    inst.AnimState:PlayAnimation("idle_empty")

    MakeSnowCoveredPristine(inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("stewer")
    inst.components.stewer.onstartcooking = startcookfn
    inst.components.stewer.oncontinuecooking = continuecookfn
    inst.components.stewer.oncontinuedone = continuedonefn
    inst.components.stewer.ondonecooking = donecookfn
    inst.components.stewer.onharvest = harvestfn

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("cookpot")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

    inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(3,5)
    inst.components.playerprox:SetOnPlayerFar(onfar)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
		local ret = false
		if math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
			if inst.components.workable then
                inst.components.workable:WorkedBy(haunter, 1)
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
                ret = true
            end
		end
		if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
			if inst.components.stewer.cooking and not inst.components.stewer.product == "wetgoop" then
				inst.components.stewer.product = "wetgoop"
				inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
				ret = true
			elseif inst.components.stewer.done and not inst.components.stewer.product == "wetgoop" then
				inst.components.stewer.product = "wetgoop"
				inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
				continuedonefn(inst)
				ret = true
			end
		end
		return ret
	end)

	MakeSnowCovered(inst)    
	inst:ListenForEvent("onbuilt", onbuilt)
    return inst
end

return Prefab("common/cookpot", fn, assets, prefabs),
		MakePlacer("common/cookpot_placer", "cook_pot", "cook_pot", "idle_empty")