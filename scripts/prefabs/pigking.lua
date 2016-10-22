local assets =
{
    Asset("ANIM", "anim/pig_king.zip"),
    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs =
{
    "goldnugget",
}

for i = 1, NUM_HALLOWEENCANDY do
	table.insert(prefabs, "halloweencandy_"..i)
end

local function ontradeforgold(inst, item, giver)
    inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingThrowGold")

    for k = 1, item.components.tradable.goldvalue do
        local nug = SpawnPrefab("goldnugget")
        local pt = Vector3(inst.Transform:GetWorldPosition()) + Vector3(0, 4.5, 0)

        nug.Transform:SetPosition(pt:Get())
        local down = TheCamera:GetDownVec()
        local angle = math.atan2(down.z, down.x) + (math.random() * 60 - 30) * DEGREES
        --local angle = (math.random() * 60 - 30 - TUNING.CAM_ROT - 90) / 180 * PI
        local sp = math.random() * 4 + 2
        nug.Physics:SetVel(sp * math.cos(angle), math.random() * 2 + 8, sp * math.sin(angle))
    end
    
    if item.components.tradable.tradefor ~= nil then
	    for _,v in pairs(item.components.tradable.tradefor) do
			local item = SpawnPrefab(v)
			if item ~= nil then
				local pt = Vector3(inst.Transform:GetWorldPosition()) + Vector3(0, 4.5, 0)

				item.Transform:SetPosition(pt:Get())
				local down = TheCamera:GetDownVec()
				local angle = math.atan2(down.z, down.x) + (math.random() * 60 - 30) * DEGREES
				--local angle = (math.random() * 60 - 30 - TUNING.CAM_ROT - 90) / 180 * PI
				local sp = math.random() * 4 + 2
				item.Physics:SetVel(sp * math.cos(angle), math.random() * 2 + 8, sp * math.sin(angle))
			end
	    end
    end
    
    if IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) then
		-- pick out up to 3 types of candies to throw out
		local candytypes = { math.random(NUM_HALLOWEENCANDY), math.random(NUM_HALLOWEENCANDY), math.random(NUM_HALLOWEENCANDY) }

		local numcandies = item.components.tradable.halloweencandyvalue or 1
		numcandies = numcandies + math.random(2) + 2

		-- only people in costumes get a good amount of candy!		
		if giver ~= nil and giver:IsValid() and giver.components.skinner ~= nil then
			local costume = giver.components.skinner:GetClothing().base
			if costume ~= nil and costume ~= "" and Prefabs[costume] ~= nil and table.contains(Prefabs[costume].tags, "COSTUME") then
				numcandies = numcandies + math.random(4) + 2
			end
		end
		
		for k = 1, numcandies do
			local candy = SpawnPrefab("halloweencandy_"..GetRandomItem(candytypes))
			local pt = Vector3(inst.Transform:GetWorldPosition()) + Vector3(0, 4.5, 0)

			candy.Transform:SetPosition(pt:Get())
			local down = TheCamera:GetDownVec()
			local angle = math.atan2(down.z, down.x) + (math.random() * 60 - 30) * DEGREES
			local sp = math.random() * 4 + 2
			candy.Physics:SetVel(sp * math.cos(angle), math.random() * 2 + 8, sp * math.sin(angle))
		end
	end
	
end

local function onplayhappysound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingHappy")
end

local function onendhappytask(inst)
    inst.happy = false
    inst.endhappytask = nil
end

local function OnGetItemFromPlayer(inst, giver, item)
	local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and item.components.tradable.halloweencandyvalue and item.components.tradable.halloweencandyvalue > 0
	
    if item.components.tradable.goldvalue > 0 or is_event_item then
        inst.AnimState:PlayAnimation("cointoss")
        inst.AnimState:PushAnimation("happy")
        inst.AnimState:PushAnimation("idle", true)
        inst:DoTaskInTime(20/30, ontradeforgold, item, giver)
        inst:DoTaskInTime(1.5, onplayhappysound)
        inst.happy = true
        if inst.endhappytask ~= nil then
            inst.endhappytask:Cancel()
        end
        inst.endhappytask = inst:DoTaskInTime(5, onendhappytask)
    end
end

local function OnRefuseItem(inst, giver, item)
    inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingReject")
    inst.AnimState:PlayAnimation("unimpressed")
    inst.AnimState:PushAnimation("idle", true)
    inst.happy = false
end

local function AcceptTest(inst, item)
	local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and item.components.tradable.halloweencandyvalue and item.components.tradable.halloweencandyvalue > 0
    return item.components.tradable.goldvalue > 0 or is_event_item
end

local function OnIsNight(inst, isnight)
    if isnight then
        inst.components.trader:Disable()
        inst.AnimState:PlayAnimation("sleep_pre")
        inst.AnimState:PushAnimation("sleep_loop", true)
    else
        inst.components.trader:Enable()
        inst.AnimState:PlayAnimation("sleep_pst")
        inst.AnimState:PushAnimation("idle", true)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 2, .5)

    inst.MiniMapEntity:SetIcon("pigking.png")
    inst.MiniMapEntity:SetPriority(1)

    inst.DynamicShadow:SetSize(10, 5)

    --inst.Transform:SetScale(1.5, 1.5, 1.5)

    inst:AddTag("king")
    inst.AnimState:SetBank("Pig_King")
    inst.AnimState:SetBuild("Pig_King")
    inst.AnimState:PlayAnimation("idle", true)

    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("trader")

    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

    inst:WatchWorldState("isnight", OnIsNight)
    OnIsNight(inst, TheWorld.state.isnight)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        if inst.components.trader and inst.components.trader.enabled then
            OnRefuseItem(inst)
            return true
        end
        return false
    end)

    return inst
end

return Prefab("pigking", fn, assets, prefabs)
