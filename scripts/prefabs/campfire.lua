require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/campfire.zip"),
}

local prefabs =
{
    "campfirefire",
}    

local function onignite(inst)
    if not inst.components.cooker then
        inst:AddComponent("cooker")
    end
end

local function onextinguish(inst)
    if inst.components.cooker then
        inst:RemoveComponent("cooker")
    end
    if inst.components.fueled then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function destroy(inst)
	local time_to_wait = 1
	local time_to_erode = 1
	local tick_time = TheSim:GetTickTime()

	if inst.DynamicShadow then
        inst.DynamicShadow:Enable(false)
    end

	inst:StartThread( function()
		local ticks = 0
		while ticks * tick_time < time_to_wait do
			ticks = ticks + 1
			Yield()
		end

		ticks = 0
		while ticks * tick_time < time_to_erode do
			local erode_amount = ticks * tick_time / time_to_erode
			inst.AnimState:SetErosionParams( erode_amount, 0.1, 1.0 )
			ticks = ticks + 1
			Yield()
		end
		inst:Remove()
	end)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("campfire")
    inst.AnimState:SetBuild("campfire")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("campfire")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    -----------------------
    inst:AddComponent("propagator")
    -----------------------
    
    inst:AddComponent("burnable")
    --inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:AddBurnFX("campfirefire", Vector3() )
    inst:ListenForEvent("onextinguish", onextinguish)
    inst:ListenForEvent("onignite", onignite)

    -------------------------
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.CAMPFIRE_FUEL_MAX
    inst.components.fueled.accepting = true
    
    inst.components.fueled:SetSections(4)
    
    inst.components.fueled.ontakefuelfn = function() inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") end
    inst.components.fueled:SetUpdateFn( function()
        if inst.components.burnable and inst.components.fueled then
            if TheWorld.state.israining then
                inst.components.fueled.rate = 1 + TUNING.CAMPFIRE_RAIN_RATE * TheWorld.state.precipitationrate
            else
                inst.components.fueled.rate = 1
            end

            inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
        end
    end)
    
    inst.components.fueled:SetSectionCallback(
        function(section)
            if section == 0 then
                inst.components.burnable:Extinguish() 
                inst.AnimState:PlayAnimation("dead") 
                RemovePhysicsColliders(inst)             

				local ash = SpawnPrefab("ash")
				ash.Transform:SetPosition(inst.Transform:GetWorldPosition())

                inst.components.fueled.accepting = false
                inst:RemoveComponent("cooker")
                inst:RemoveComponent("propagator")
                destroy(inst)            
            else
                inst.AnimState:PlayAnimation("idle") 
                inst.components.burnable:SetFXLevel(section, inst.components.fueled:GetSectionPercent() )
                inst.components.fueled.rate = 1
                
                local ranges = {1,2,3,4}
                local output = {2,5,5,10}
                inst.components.propagator.propagaterange = ranges[section]
                inst.components.propagator.heatoutput = output[section]
            end
        end)
        
    inst.components.fueled:InitializeFuelLevel(TUNING.CAMPFIRE_FUEL_START)
    
    -----------------------------
    
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst)
        local sec = inst.components.fueled:GetCurrentSection()
        if sec == 0 then 
            return "OUT"
        elseif sec <= 4 then
            local t= {"EMBERS","LOW","NORMAL","HIGH"} 
            return t[sec]
        end
    end
    
    --------------------
    
    inst.components.burnable:Ignite()
    inst:ListenForEvent("onbuilt", function()
        inst.AnimState:PlayAnimation("place")
        inst.AnimState:PushAnimation("idle", false)
        inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
    end)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            if inst.components.fueled then
                local fuel = SpawnPrefab("petals")
                if fuel then
                    inst.components.fueled:TakeFuelItem(fuel)
                    return true
                end
            end
        end
        return false
    end)
    
    return inst
end

return Prefab("common/objects/campfire", fn, assets, prefabs),
		MakePlacer("common/campfire_placer", "campfire", "campfire", "preview")