local assets =
{
	Asset("ANIM", "anim/buzzard_shadow.zip"),
	Asset("ANIM", "anim/buzzard_build.zip"),
	Asset("MINIMAP_IMAGE", "buzzard"),
}

local prefabs =
{
	"buzzard",
}

local FOOD_TAGS = { "edible_"..FOODTYPE.MEAT, "prey" }
local NO_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function RemoveBuzzardShadow(inst, shadow)
	shadow.components.colourtweener:StartTween({1,1,1,0}, 3, function() shadow:Remove() end)
    for i,v in ipairs(inst.buzzardshadows) do
        if v == shadow then
            table.remove(inst.buzzardshadows, i)
            break
        end
    end
end

local function SpawnBuzzardShadow(inst)
	local shadow = SpawnPrefab("circlingbuzzard")
	shadow.components.circler:SetCircleTarget(inst)
	shadow.components.circler:Start()
    return shadow
end

local function UpdateShadows(inst)
    local count = inst.components.childspawner.childreninside
    while #inst.buzzardshadows < count do
        table.insert(inst.buzzardshadows, SpawnBuzzardShadow(inst))
    end
    while #inst.buzzardshadows > count do
        local shadow = inst.buzzardshadows[#inst.buzzardshadows]
        RemoveBuzzardShadow(inst, shadow)
    end
end

local function ReturnChildren(inst)
	for k,child in pairs(inst.components.childspawner.childrenoutside) do
		if child.components.homeseeker then
			child.components.homeseeker:GoHome()
		end
		child:PushEvent("gohome")
	end
end

local function OnAddChild(inst)
    UpdateShadows(inst)
end

local function OnSpawn(inst, child)
	for i,shadow in ipairs(inst.buzzardshadows) do
		if shadow and shadow:IsValid() then
			local dist = shadow.components.circler.distance
			local angle = shadow.components.circler.angleRad
			local offset = FindWalkableOffset(inst:GetPosition(), angle, dist, 8, false) or Vector3(0,0,0)
			offset.y = 30
			child.Transform:SetPosition((inst:GetPosition() + offset):Get())
			child.sg:GoToState("glide")
			RemoveBuzzardShadow(inst, shadow)
			break
		end
	end
end

local function stophuntingfood(inst)
    local food = inst.foodHunted or inst
    local buzzard = inst.buzzardHunted or inst
    if food ~= nil and buzzard ~= nil then
        food.buzzardHunted = nil
        buzzard.foodHunted = nil
        food:RemoveEventCallback("onpickup", stophuntingfood)
        food:RemoveEventCallback("onremove", stophuntingfood)
        buzzard:RemoveEventCallback("onremove", stophuntingfood)
    end
end

local function CanBeHunted(food)
    return food.buzzardHunted == nil and food:IsOnValidGround() and FindEntity(food, 3, nil, { "buzzard" }, NO_TAGS) == nil
end

local function LookForFood(inst)
    if inst.components.childspawner == nil or
        not inst.components.childspawner:CanSpawn() or
        TheWorld.state.isnight or
        math.random() <= .25 then
        return
    end

    local food = FindEntity(inst, 25, CanBeHunted, nil, NO_TAGS, FOOD_TAGS)
    if food ~= nil then
        local buzzard = inst.components.childspawner:SpawnChild()
        local x, y, z = food.Transform:GetWorldPosition()
        buzzard.Transform:SetPosition(x + math.random(-1.5, 1.5), 30, z + math.random(-1.5, 1.5))
        buzzard:FacePoint(x, y, z)

        if food:HasTag("prey") then
            buzzard.sg.statemem.target = food
        end

        food.buzzardHunted = buzzard
        buzzard.foodHunted = food
        food:ListenForEvent("onpickup", stophuntingfood)
        food:ListenForEvent("onremove", stophuntingfood)
        buzzard:ListenForEvent("onremove", stophuntingfood)

        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/buzzard/distant")
    end
end

local function OnEntitySleep(inst)
	for i,buzzard in ipairs(inst.buzzardshadows) do
		buzzard:Remove()
		inst.buzzardshadows[i] = nil
	end
	if inst.foodTask then
		inst.foodTask:Cancel()
		inst.foodTask = nil
	end
end

local function OnEntityWake(inst)
	inst:DoTaskInTime(0.5, function() 
		if not inst:IsAsleep() then 
			if not inst.components.childspawner then 
				print("no childspawner on ", inst)
			else
                UpdateShadows(inst)
			end
		end
	end)
	inst.foodTask = inst:DoPeriodicTask(math.random(20,40)*0.1, LookForFood)
end

local function OnIsDay(inst)
	if not TheWorld.state.iswinter then
	    inst.components.childspawner:StartSpawning()
		inst.components.childspawner:StopRegen()
	end
end

local function OnIsNight(inst)
	inst.components.childspawner:StopSpawning()
	inst.components.childspawner:StartRegen()
	ReturnChildren(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("buzzard.png")

    inst:AddTag("buzzardspawner")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent( "childspawner" )
	inst.components.childspawner.childname = "buzzard"
	inst.components.childspawner:SetSpawnedFn(OnSpawn)
	inst.components.childspawner:SetOnAddChildFn(OnAddChild)
	inst.components.childspawner:SetMaxChildren(math.random(1,2))
	inst.components.childspawner:SetSpawnPeriod(TUNING.BUZZARD_SPAWN_PERIOD + math.random(-TUNING.BUZZARD_SPAWN_VARIANCE, TUNING.BUZZARD_SPAWN_VARIANCE))
	inst.components.childspawner:SetRegenPeriod(TUNING.BUZZARD_REGEN_PERIOD)

	inst:WatchWorldState("isday", OnIsDay)
	inst:WatchWorldState("isnight", OnIsNight)
	
	inst.buzzardshadows = {}

	inst.OnEntityWake = OnEntityWake
	inst.OnEntitySleep = OnEntitySleep

	return inst
end

local function CircleOnDay(inst)
	 if not TheWorld.state.iswinter then
		inst.components.colourtweener:StartTween({1,1,1,1}, 3)
	end
end

local function CircleOnNight(inst)
	inst.components.colourtweener:StartTween({1,1,1,0}, 3)
end

local function DoFlap(inst)
	if math.random() > 0.66 then 
		local numFlaps = math.random(3, 6)
		inst.AnimState:PlayAnimation("shadow_flap_loop") 

		for i = 2, numFlaps do
			inst.AnimState:PushAnimation("shadow_flap_loop") 
		end

		inst.AnimState:PushAnimation("shadow") 
	end
end

local function circlingbuzzardfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("buzzard")
    inst.AnimState:SetBuild("buzzard_build")
    inst.AnimState:PlayAnimation("shadow", true)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetMultColour(1,1,1,0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("circler")

	inst:AddComponent("colourtweener")
	if not TheWorld.state.isnight then
		inst.components.colourtweener:StartTween({1,1,1,1}, 3)
	end

	inst:WatchWorldState("isday", CircleOnDay)
	inst:WatchWorldState("isnight", CircleOnNight)

	inst:DoPeriodicTask(math.random(3,5), DoFlap)

    inst.persists = false

	return inst
end

return Prefab("buzzardspawner", fn, assets, prefabs),
    Prefab("circlingbuzzard", circlingbuzzardfn, assets, prefabs)
