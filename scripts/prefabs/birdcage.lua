require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/bird_cage.zip"),

	Asset("ANIM", "anim/crow_build.zip"),
	Asset("ANIM", "anim/robin_build.zip"),
	Asset("ANIM", "anim/robin_winter_build.zip"),
}

local prefabs =
{
	"bird_egg",

	-- everything it can "produce" and might need symbol swaps from
	"crow",
	"robin",
	"robin_winter",
	"collapse_small",
}

local bird_symbols=
{
	"crow_beak",
	"crow_body",
	"crow_eye",
	"crow_leg",
	"crow_wing",
	"tail_feather",
}

local function ShouldAcceptItem(inst, item)
	local seed_name = string.lower(item.prefab .. "_seeds")
	local can_accept = item.components.edible and (Prefabs[seed_name] or item.prefab == "seeds" or item.components.edible.foodtype == FOODTYPE.MEAT) 
	
	if item.prefab == "egg" or item.prefab == "bird_egg" or item.prefab == "rottenegg" or item.prefab == "monstermeat" then
		can_accept = false
	end
	
	return can_accept
end

local function OnRefuseItem(inst, item)
	inst.AnimState:PlayAnimation("flap")
    inst.SoundEmitter:PlaySound("dontstarve/birds/wingflap_cage")
    inst.AnimState:PushAnimation("idle_bird")
end

local function OnDigest(inst, item)
    if item.components.edible.foodtype == FOODTYPE.MEAT then
        inst.components.lootdropper:SpawnLootPrefab("bird_egg")
    else
        local seed_name = string.lower(item.prefab .. "_seeds")
        if Prefabs[seed_name] ~= nil then
            local num_seeds = math.random(2)
            for k = 1, num_seeds do
                inst.components.lootdropper:SpawnLootPrefab(seed_name)
            end
            
            if math.random() < .5 then
                inst.components.lootdropper:SpawnLootPrefab("seeds")
            end
        else
            inst.components.lootdropper:SpawnLootPrefab("seeds")
        end
    end
    if inst.components.occupiable and inst.components.occupiable.occupant 
        and inst.components.occupiable.occupant:IsValid() and inst.components.occupiable.occupant.components.perishable then
        inst.components.occupiable.occupant.components.perishable:SetPercent(1)		         
    end
end

local function OnGetItemFromPlayer(inst, giver, item)

	if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end

    if item.components.edible ~= nil and
        (   item.components.edible.foodtype == FOODTYPE.MEAT or
            item.prefab == "seeds" or
            Prefabs[string.lower(item.prefab.."_seeds")] ~= nil
        ) then
		inst.AnimState:PlayAnimation("peck")
		inst.AnimState:PushAnimation("peck")
		inst.AnimState:PushAnimation("peck")
		inst.AnimState:PushAnimation("hop")
		
		inst.AnimState:PushAnimation("idle_bird", true)
		inst:DoTaskInTime(60 * FRAMES, OnDigest, item)
    end
end

local function DoIdle(inst)
	local r = math.random()
	if r < .5 then
        inst.AnimState:PlayAnimation("caw")
        if inst.chirpsound then
			inst.SoundEmitter:PlaySound(inst.chirpsound)
		end
	elseif r < .6 then
        inst.AnimState:PlayAnimation("flap")
        inst.SoundEmitter:PlaySound("dontstarve/birds/wingflap_cage")
	else
        inst.AnimState:PlayAnimation("hop")
	end
    inst.AnimState:PushAnimation("idle_bird")
end

local function StopIdling(inst)
    if inst.idletask then
        inst.idletask:Cancel()
        inst.idletask = nil
    end
end

local function StartIdling(inst)
    inst.idletask = inst:DoPeriodicTask(6, DoIdle)
end

local function ShouldSleep(inst)
    return TheWorld.state.isnight and inst.components.occupiable:IsOccupied()
end

local function ShouldWake(inst)
    return TheWorld.state.isday
end

local function onoccupied(inst, bird)

	if bird.components.perishable then
		bird.components.perishable:StopPerishing()
	end

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

	inst.components.trader:Enable()
	for k,v in pairs(bird_symbols) do
		inst.AnimState:OverrideSymbol(v, bird.prefab .. "_build", v)
	end
	inst.chirpsound = bird.sounds and bird.sounds.chirp
	inst.AnimState:PlayAnimation("flap")
	inst.AnimState:PushAnimation("idle_bird", true)
	StartIdling(inst)
end

local function onemptied(inst, bird)
	inst:RemoveComponent("sleeper")
	
	StopIdling(inst)
	inst.components.trader:Disable()
	for k,v in pairs(bird_symbols) do
		inst.AnimState:ClearOverrideSymbol(v)
	end
	inst.AnimState:PlayAnimation("idle", true)
end

local function onhammered(inst, worker)
	--[[
	inst.components.container:DropEverything()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	--]]
	if inst.components.occupiable:IsOccupied() then
		local item = inst.components.occupiable:Harvest()
		if item then
			item.Transform:SetPosition(inst.Transform:GetWorldPosition())
			item.components.inventoryitem:OnDropped()
		end
	end
	inst.components.lootdropper:DropLoot()
	inst:Remove()
	
end

local function onhit(inst, worker)

	if inst.components.occupiable:IsOccupied() then
		inst.AnimState:PlayAnimation("hit_bird")
		inst.AnimState:PushAnimation("flap")
        inst.SoundEmitter:PlaySound("dontstarve/birds/wingflap_cage")
		inst.AnimState:PushAnimation("idle_bird", true)
	else
		inst.AnimState:PlayAnimation("hit_idle")
		inst.AnimState:PushAnimation("idle")
	end
	--inst.components.container:Close()
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle")
end

local function GoToSleep(inst)
	if inst.components.occupiable:IsOccupied() then
		StopIdling(inst)
		inst.AnimState:PlayAnimation("sleep_pre")
		inst.AnimState:PushAnimation("sleep_loop", true)
	end
end

local function WakeUp(inst)
	if inst.components.occupiable:IsOccupied() then
		inst.AnimState:PlayAnimation("sleep_pst")
		inst.AnimState:PushAnimation("idle_bird", true)
		StartIdling(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("birdcage.png")

    inst.AnimState:SetBank("birdcage")
    inst.AnimState:SetBuild("bird_cage")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("structure")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
    inst:AddComponent("lootdropper")
    
    inst:AddComponent("occupiable")
    inst.components.occupiable.occupanttype = OCCUPANTTYPE.BIRD
    inst.components.occupiable.onoccupied = onoccupied
    inst.components.occupiable.onemptied = onemptied

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)    
	
	inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
	inst.components.trader.onaccept = OnGetItemFromPlayer
	inst.components.trader.onrefuse = OnRefuseItem
	inst.components.trader:Disable()
	MakeSnowCovered(inst)	
	inst:ListenForEvent( "onbuilt", onbuilt)

	MakeHauntableWork(inst)
	
    inst:ListenForEvent("gotosleep", GoToSleep)
    inst:ListenForEvent("onwakeup", WakeUp)
	
    return inst
end

return Prefab("common/birdcage", fn, assets, prefabs),
		MakePlacer("common/birdcage_placer", "birdcage", "bird_cage", "idle")