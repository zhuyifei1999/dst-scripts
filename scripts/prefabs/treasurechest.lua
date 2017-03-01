require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/treasure_chest.zip"),
    Asset("ANIM", "anim/ui_chest_3x2.zip"),

    Asset("ANIM", "anim/pandoras_chest.zip"),
    Asset("ANIM", "anim/skull_chest.zip"),
    Asset("ANIM", "anim/pandoras_chest_large.zip"),
	Asset("MINIMAP_IMAGE", "treasure_chest"),
	Asset("MINIMAP_IMAGE", "minotaur_chest"),
	Asset("MINIMAP_IMAGE", "pandoras_chest"),
}

local prefabs =
{
    "collapse_small",
}

local chests =
{
    treasure_chest =
    {
        bank = "chest",
        build = "treasure_chest",
    },
    skull_chest =
    {
        bank = "skull_chest",
        build = "skull_chest",
    },
    pandoras_chest =
    {
        bank = "pandoras_chest",
        build = "pandoras_chest",
    },
    minotaur_chest =
    {
        bank = "pandoras_chest_large",
        build = "pandoras_chest_large",
    },
}

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    end
end 

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

local function chest(style, indestructible, custom_postinit)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon(style..".png")

        inst:AddTag("structure")
        inst:AddTag("chest")
        inst.AnimState:SetBank(chests[style].bank)
        inst.AnimState:SetBuild(chests[style].build)
        inst.AnimState:PlayAnimation("closed")

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("container")
        inst.components.container:WidgetSetup("treasurechest")
        inst.components.container.onopenfn = onopen
        inst.components.container.onclosefn = onclose

		if not indestructible then
			inst:AddComponent("lootdropper")
			inst:AddComponent("workable")
			inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
			inst.components.workable:SetWorkLeft(2)
			inst.components.workable:SetOnFinishCallback(onhammered)
			inst.components.workable:SetOnWorkCallback(onhit) 
		end
		
        AddHauntableDropItemOrWork(inst)

        inst:ListenForEvent("onbuilt", onbuilt)
        MakeSnowCovered(inst)   

		if not indestructible then
			MakeSmallBurnable(inst, nil, nil, true)
			MakeMediumPropagator(inst)
		end
		
        inst.OnSave = onsave 
        inst.OnLoad = onload

		if custom_postinit ~= nil then
			custom_postinit(inst)
		end

        return inst
    end
end

local function pandora_custom_postinit(inst)
	local function OnResetRuins()
		local was_open = inst.components.container:IsOpen()

		if inst.components.scenariorunner == nil then
			inst.components.container:Close()
			inst.components.container:DestroyContents()

			inst:AddComponent("scenariorunner")
			inst.components.scenariorunner:SetScript("chest_labyrinth")
		    inst.components.scenariorunner:Run()

		end

		if not inst:IsAsleep() then
			if not was_open then
				inst.AnimState:PlayAnimation("hit")
				inst.AnimState:PushAnimation("closed", false)
			end
		
			SpawnPrefab("statue_transition").Transform:SetPosition(inst.Transform:GetWorldPosition())
		end
	end
	
	inst:ListenForEvent("resetruins", OnResetRuins, TheWorld)
end

local function minotuar_custom_postinit(inst)
	inst:ListenForEvent("resetruins", 
		function() 
			inst.components.container:Close()
			inst.components.container:DropEverything()

			if not inst:IsAsleep() then
				local fx = SpawnPrefab("collapse_small")
				fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
				fx:SetMaterial("wood")
			end
			
			inst:Remove()
		end, TheWorld)
end

return Prefab("treasurechest", chest("treasure_chest"), assets, prefabs),
    MakePlacer("treasurechest_placer", "chest", "treasure_chest", "closed"),
    Prefab("pandoraschest", chest("pandoras_chest", true, pandora_custom_postinit), assets, prefabs),
    Prefab("skullchest", chest("skull_chest"), assets, prefabs),
    Prefab("minotaurchest", chest("minotaur_chest", true, minotuar_custom_postinit), assets, prefabs)
