local assets =
{
	Asset("ANIM", "anim/buzzard_shadow.zip"),
	Asset("ANIM", "anim/buzzard_build.zip"),
}

local prefabs =
{
	"buzzard",
}

local FOOD_TAGS = {"edible", "prey"}
local NO_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO"}

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

local function BuzzardNearFood(inst, food)
    local x,y,z = food.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 3,  {"buzzard"}, {"FX", "NOCLICK", "DECOR","INLIMBO"})
    return #ents > 0
end

local function SpawnOnFood(inst, food)
	if food.buzzardHunted then return end
	if math.random() > 0.25 then
		local buzzard = inst.components.childspawner:SpawnChild()
		local foodPos = food:GetPosition()
		buzzard.Transform:SetPosition(foodPos.x + math.random(-1.5, 1.5), 30, foodPos.z + math.random(-1.5, 1.5))

		if food:HasTag("prey") then
			buzzard.sg.statemem.target = food
		end
		
		buzzard:FacePoint(food.Transform:GetWorldPosition())

        local stophuntingfood = nil
        stophuntingfood = function()
            food.buzzardHunted = nil
            food:RemoveEventCallback("onpickup", stophuntingfood)
            buzzard:RemoveEventCallback("onremove", stophuntingfood)
        end

		food:ListenForEvent("onpickup", stophuntingfood)
        buzzard:ListenForEvent("onremove", stophuntingfood)
		food.buzzardHunted = true

		inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/buzzard/distant")
	end
end

local function LookForFood(inst)
	if not inst.components.childspawner then 
		print("no childspawner on ", inst)
	end
	if not inst.components.childspawner:CanSpawn() or TheWorld.state.isnight then return end

	local pt = inst:GetPosition()
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 25, nil, NO_TAGS)
    for k,v in pairs(ents) do
        if v and v:IsOnValidGround() and (v.components.edible and v.components.edible.foodtype == "MEAT" and not v.components.inventoryitem:IsHeld())
        or v:HasTag("prey") and not BuzzardNearFood(inst, v) and not v.buzzardHunted then
        	SpawnOnFood(inst, v)
            break
        end
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
	inst.components.childspawner:SetSpawnPeriod(math.random(40, 50))
	inst.components.childspawner:SetRegenPeriod(20)

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

return Prefab("badlands/objects/buzzardspawner", fn, assets, prefabs),
    Prefab("badlands/objects/circlingbuzzard", circlingbuzzardfn, assets, prefabs)
