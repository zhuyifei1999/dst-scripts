local prefabs =
{
    "collapse_small",
}

local function IsLightOn(inst)
	return inst.Light:IsEnabled()
end


local light_str = 
{
	{radius = 2.5, falloff = .85, intensity = 0.75},
	{radius = 3.25, falloff = .85, intensity = 0.75},
	{radius = 4.25, falloff = .85, intensity = 0.75},
	{radius = 5.5, falloff = .85, intensity = 0.75},
}

local colour_tint = { 0.4, 0.3, 0.25, 0.2, 0.1 }
local mult_tint = { 0.7, 0.6, 0.55, 0.5, 0.45 }

local function UpdateLightState(inst, skip_toggle_anims)
	if inst:HasTag("burnt") then
		return
	end

	local num_batteries = #inst.components.container:FindItems( function(item) return item:HasTag("lightbattery") or item:HasTag("spore") end )
	local toggling = IsLightOn(inst) ~= (num_batteries > 0)
	
	if num_batteries > 0 then
		inst.Light:SetRadius(light_str[num_batteries].radius)
		inst.Light:SetFalloff(light_str[num_batteries].falloff)
		inst.Light:SetIntensity(light_str[num_batteries].intensity)

		if not inst.onlywhite then
			-- For the GlowCap, spores will tint the light colour to allow for a disco/rave in your base
			local r = #inst.components.container:FindItems(function(item) return item.prefab == MUSHTREE_SPORE_RED end)
			local g = #inst.components.container:FindItems(function(item) return item.prefab == MUSHTREE_SPORE_GREEN end)
			local b = #inst.components.container:FindItems(function(item) return item.prefab == MUSHTREE_SPORE_BLUE end)

			local colour = Vector3( colour_tint[g+b + 1] + r/11, colour_tint[r+b + 1] + g/11, colour_tint[r+g + 1] + b/11)
			inst.Light:SetColour(colour.x, colour.y, colour.z)

			inst.AnimState:SetMultColour(mult_tint[g+b + 1], mult_tint[r+b + 1], mult_tint[r+g + 1], 1)
		end
		
		inst.Light:Enable(true)
	    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	
		if skip_toggle_anims then
			inst.AnimState:PlayAnimation("idle_on", true)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_LP", "loop")
		elseif toggling then
			inst.AnimState:PlayAnimation("turn_on")
			inst.AnimState:PushAnimation("idle_on", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_LP", "loop")
		else
			inst.AnimState:PlayAnimation( inst.onlywhite and "turn_on" or "colour_change" )
			inst.AnimState:PushAnimation("idle_on", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_on")
		end
	else
		inst.Light:Enable(false)
        inst.AnimState:ClearBloomEffectHandle()
		inst.AnimState:SetMultColour(.7, .7, .7, 1)
		inst.SoundEmitter:KillSound("loop")
		if skip_toggle_anims then
			inst.AnimState:PlayAnimation("idle", true)
		elseif toggling then
			inst.AnimState:PlayAnimation("turn_off")
			inst.AnimState:PushAnimation("idle")
		    inst.SoundEmitter:PlaySound(inst.onlywhite and "dontstarve/wilson/lantern_off" or "dontstarve/wilson/lantern_on" )
		end
	end
end

local function onworkfinished(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onworked(inst, worker, workleft)
    if not inst:HasTag("burnt") and workleft > 0 then
        inst.AnimState:PlayAnimation(IsLightOn(inst) and "hit_on" or "hit")
        inst.AnimState:PushAnimation(IsLightOn(inst) and "idle_on" or "idle")

		inst.components.container:DropEverything()
        inst.components.container:Close()
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
    UpdateLightState(inst)
end

local function getstatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
           or (IsLightOn(inst) and "ON")
           or "Off"
end

local function onchangeitems(inst)
	UpdateLightState(inst)
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function MakeMushroomLight( name, onlywhite, physics_rad )
	local assets =
	{
		Asset("ANIM", "anim/"..name..".zip"),
        Asset("SOUND", "sound/wilson.fsb"),
	}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
        inst.entity:AddLight()
		inst.entity:AddNetwork()

		MakeObstaclePhysics(inst, physics_rad)

		inst.AnimState:SetBank(name)
		inst.AnimState:SetBuild(name)
		inst.AnimState:PlayAnimation("idle")
	     
		inst:AddTag("structure")
		--inst:AddTag("fridge")
		
		inst.onlywhite = onlywhite

	    MakeSnowCoveredPristine(inst)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		MakeSmallBurnable(inst, nil, nil, true)
		MakeSmallPropagator(inst)
		MakeHauntableWork(inst)
	    MakeSnowCovered(inst)

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(3)
		inst.components.workable:SetOnFinishCallback(onworkfinished)
		inst.components.workable:SetOnWorkCallback(onworked)

		inst:AddComponent("inspectable")
	    inst.components.inspectable.getstatus = getstatus
	    
		inst:AddComponent("lootdropper")

		inst:AddComponent("container")
		inst.components.container:WidgetSetup(name)
		
	    inst:ListenForEvent("onbuilt", onbuilt)
	    inst:ListenForEvent("itemget", onchangeitems)
	    inst:ListenForEvent("itemlose", onchangeitems)

		if onlywhite then
			inst.Light:SetColour(.65, .65, .5)
		end
		
	    inst.OnSave = onsave
	    inst.OnLoad = onload

		UpdateLightState(inst, true)

		return inst
	end
	
	return Prefab(name, fn, assets, prefabs)
end

return MakeMushroomLight("mushroom_light", true, .25),
       MakeMushroomLight("mushroom_light2", false, .4),
       MakePlacer("mushroom_light_placer", "mushroom_light", "mushroom_light", "idle"),
       MakePlacer("mushroom_light2_placer", "mushroom_light2", "mushroom_light2", "idle")

