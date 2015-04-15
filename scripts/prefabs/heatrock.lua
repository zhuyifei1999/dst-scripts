local assets =
{
	Asset("ANIM", "anim/heat_rock.zip"),
}

local HIGH_TEMP_RANGE = 4
local LOW_TEMP_RANGE = 2

local function OnSave(inst, data)
    data.reachedHighTemp = inst.reachedHighTemp
end

local function OnLoad(inst, data)
    if data then
    	inst.reachedHighTemp = data.reachedHighTemp
    end
end

local function OnRemove(inst)
    inst._light:Remove()
end

local function HeatFn(inst, observer)
	return inst.components.temperature:GetCurrent()
end

local function GetStatus(inst)
	if inst.currentTempRange == 1 then
		return "COLD"
	elseif inst.currentTempRange == 5 then
		return "HOT"
	elseif inst.currentTempRange == 4 or inst.currentTempRange == 3 then
		return "WARM"
	end
end

-- These represent the boundaries between the images
local temperature_thresholds = { 0, 25, 40, 50 }

local function GetRangeForTemperature(temp)
	local range = 1
	for i,v in ipairs(temperature_thresholds) do
		if temp > v then
			range = range + 1
		end
	end
	return range
end

local function UpdateImages(inst, range)
	inst.currentTempRange = range

	if range >= HIGH_TEMP_RANGE then
		inst.reachedHighTemp = true
	end

	inst.AnimState:PlayAnimation(tostring(range), true)
	inst.components.inventoryitem:ChangeImageName("heat_rock"..tostring(range))
	if range == 5 then
		inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst._light.Light:Enable(true)
	else
		inst.AnimState:ClearBloomEffectHandle()
        inst._light.Light:Enable(false)
	end
end

local function AdjustLighting(inst)
	local hottest = inst.components.temperature.maxtemp - temperature_thresholds[#temperature_thresholds]
	local current = inst.components.temperature.current - temperature_thresholds[#temperature_thresholds]
	inst._light.Light:SetIntensity(0.5 * current / hottest)
end

local function TemperatureChange(inst, data)
	AdjustLighting(inst)
	local range = GetRangeForTemperature(inst.components.temperature.current)
	if range ~= inst.currentTempRange then
		local percent = inst.components.fueled:GetPercent()

		--going from hot to cold
		if range == LOW_TEMP_RANGE and inst.reachedHighTemp then
			percent = percent - 1 / TUNING.HEATROCK_NUMUSES
			inst.reachedHighTemp = false
		end

		UpdateImages(inst, range)

		--wait until after setting the image to set the percent
		inst.components.fueled:SetPercent(percent)
	end
end

local function OnOwnerChange(inst)
    local newowners = {}
    local owner = inst
    while owner.components.inventoryitem ~= nil do
        newowners[owner] = true

        if inst._owners[owner] then
            inst._owners[owner] = nil
        else
            inst:ListenForEvent("onputininventory", inst._onownerchange, owner)
            inst:ListenForEvent("ondropped", inst._onownerchange, owner)
        end

        local nextowner = owner.components.inventoryitem.owner
        if nextowner == nil then
            break
        end

        owner = nextowner
    end

    inst._light.entity:SetParent(owner.entity)

    for k, v in pairs(inst._owners) do
        if k:IsValid() then
            inst:RemoveEventCallback("onputininventory", inst._onownerchange, k)
            inst:RemoveEventCallback("ondropped", inst._onownerchange, k)
        end
    end

    inst._owners = newowners
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("heat_rock")
    inst.AnimState:SetBuild("heat_rock")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus
    
    inst:AddComponent("inventoryitem")

	inst:AddComponent("temperature")
	inst.components.temperature.maxtemp = 60
	inst.components.temperature.current = 1
	inst.components.temperature.inherentinsulation = TUNING.INSULATION_MED

	inst:AddComponent("heater")
	inst.components.heater.heatfn = HeatFn
	inst.components.heater.carriedheatfn = HeatFn
	
    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(100)
    inst.components.fueled:SetDepletedFn(inst.Remove)
    
	inst:ListenForEvent("temperaturedelta", TemperatureChange)
	inst.currentTempRange = 0

    --Create light
    inst._light = SpawnPrefab("heatrocklight")
    inst._owners = {}
    inst._onownerchange = function() OnOwnerChange(inst) end
    --

    UpdateImages(inst, 1)
    OnOwnerChange(inst)

	MakeHauntableLaunchAndSmash(inst)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
    inst.OnRemoveEntity = OnRemove

	return inst
end

local function lightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(235 / 255, 165 / 255, 12 / 255)
    inst.Light:Enable(false)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.persists = false

    return inst
end

return Prefab("common/inventory/heatrock", fn, assets),
    Prefab("common/inventory/heatrocklight", lightfn)