require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/treasure_chest.zip"),
	Asset("ANIM", "anim/ui_chest_3x2.zip"),

	Asset("ANIM", "anim/pandoras_chest.zip"),
	Asset("ANIM", "anim/skull_chest.zip"),
	Asset("ANIM", "anim/pandoras_chest_large.zip"),
}

local chests = {
	treasure_chest = {
		bank="chest",
		build="treasure_chest",
	},
	skull_chest = {
		bank="skull_chest",
		build="skull_chest",
	},
	pandoras_chest = {
		bank="pandoras_chest",
		build="pandoras_chest",
	},
	minotaur_chest = {
		bank = "pandoras_chest_large",
		build = "pandoras_chest_large",
	},
}

local function onopen(inst) 
	inst.AnimState:PlayAnimation("open") 
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
end 

local function onclose(inst) 
	inst.AnimState:PlayAnimation("close") 
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")		
end 

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	inst.components.container:DropEverything()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")	
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.components.container:DropEverything()
	inst.AnimState:PushAnimation("closed", false)
	inst.components.container:Close()
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("closed", false)
end

local function chest(style)
	return function()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon(style..".png")

        inst:AddTag("structure")
        inst.AnimState:SetBank(chests[style].bank)
        inst.AnimState:SetBuild(chests[style].build)
        inst.AnimState:PlayAnimation("closed")

        MakeSnowCoveredPristine(inst)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.entity:SetPristine()

		inst:AddComponent("inspectable")
		inst:AddComponent("container")
        inst.components.container:WidgetSetup("treasurechest")
		inst.components.container.onopenfn = onopen
		inst.components.container.onclosefn = onclose

		inst:AddComponent("lootdropper")
		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(2)
		inst.components.workable:SetOnFinishCallback(onhammered)
		inst.components.workable:SetOnWorkCallback(onhit) 

		inst:AddComponent("hauntable")
		inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
		inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
			local ret = false
	        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
	            if inst.components.container then
	                local item = inst.components.container:FindItem(function(item) return not item:HasTag("nosteal") end)
	                if item then
	                    inst.components.container:DropItem(item)
	                    inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
	                    ret = true
	                end
	            end
	        end
	        if math.random() <= TUNING.HAUNT_CHANCE_VERYRARE then
	        	if inst.components.workable then
	                inst.components.workable:WorkedBy(haunter, 1)
	                inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
	                ret = true
	            end
	        end
	        return ret
		end)

		inst:ListenForEvent("onbuilt", onbuilt)
		MakeSnowCovered(inst)	
		return inst
	end
end

return Prefab("common/treasurechest", chest("treasure_chest"), assets),
		MakePlacer("common/treasurechest_placer", "chest", "treasure_chest", "closed"),
		Prefab("common/pandoraschest", chest("pandoras_chest"), assets),
		Prefab("common/skullchest", chest("skull_chest"), assets),
		Prefab("common/minotaurchest", chest("minotaur_chest"), assets)