local assets =
{
	Asset("ANIM", "anim/bearger_build.zip"),
	Asset("ANIM", "anim/bearger_basic.zip"),
	Asset("ANIM", "anim/bearger_groggy_build.zip"),
	Asset("ANIM", "anim/bearger_actions.zip"),
	Asset("SOUND", "sound/bearger.fsb"),
}

local prefabs =
{
	"groundpound_fx",
	"groundpoundring_fx",
	"bearger_fur",
	"furtuft",
	"collapse_small",
}

local brain = require("brains/beargerbrain")

SetSharedLootTable( 'bearger',
{
	{'meat',			 1.00},
	{'meat',			 1.00},
	{'meat',			 1.00},
	{'meat',			 1.00},
	{'meat',			 1.00},
	{'meat',			 1.00},
	{'meat',			 1.00},
	{'meat',			 1.00},
	{'bearger_fur',		 1.00},
})

local TARGET_DIST = 7.5

local function CalcSanityAura(inst, observer)
    return inst.components.combat.target ~= nil and -TUNING.SANITYAURA_HUGE or -TUNING.SANITYAURA_LARGE
end

local function SetGroundPounderSettings(inst, mode)
	if mode == "normal" then 
		inst.components.groundpounder.damageRings = 2
		inst.components.groundpounder.destructionRings = 2
		inst.components.groundpounder.numRings = 3
	--[[elseif mode == "hibernation" then 
		inst.components.groundpounder.damageRings = 3
		inst.components.groundpounder.destructionRings = 3
		inst.components.groundpounder.numRings = 4]]
	end
end

local function RetargetFn(inst)
	if inst.components.sleeper and inst.components.sleeper:IsAsleep() then return end	

	local attackingTarget = FindEntity(inst, TARGET_DIST, function(guy)
							        return inst.components.combat:CanTarget(guy)
							               and (guy.components.combat.target == inst)

								    end,
								    nil,
								    {"prey", "smallcreature"}
								    )

	if attackingTarget then 
		--print(inst, "got target that is attacking", attackingTarget)
		return attackingTarget               
	elseif inst.last_eat_time and (GetTime() - inst.last_eat_time) > TUNING.BEARGER_DISGRUNTLE_TIME then
		--print(inst, "looking for target with food")
		return FindEntity(inst, TARGET_DIST*5, function(guy)
			return inst.components.combat:CanTarget(guy) 
				and guy.components.inventory and (guy.components.inventory:FindItem(function(item) return item:HasTag("honeyed") end) ~= nil)
		end,
		nil,
		{ "prey", "smallcreature" }
		)
	end

end

local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target)
end

local function OnSave(inst, data)
	data.seenbase = inst.seenbase or nil-- from brain
	data.cangroundpound = inst.cangroundpound
	data.num_food_cherrypicked = inst.num_food_cherrypicked
	data.num_good_food_eaten = inst.num_good_food_eaten
	data.killedplayer = inst.killedplayer
	data.shouldgoaway = inst.shouldgoaway
end

local function OnLoad(inst, data)
	if data ~= nil then
		inst.seenbase = data.seenbase or nil-- for brain
		inst.cangroundpound = data.cangroundpound
		inst.num_food_cherrypicked = data.num_food_cherrypicked or 0
		inst.num_good_food_eaten = data.num_good_food_eaten or 0
		inst.killedplayer = data.killedplayer or false
		inst.shouldgoaway = data.shouldgoaway or false
	end
end

local function OnSeasonChange(inst, data)
	if TheWorld.state.season == "autumn" or TheWorld.state.season == "summer" then 
		SetGroundPounderSettings(inst, "normal")
		inst.components.health:SetAbsorptionAmount(0)
		inst:RemoveTag("hibernation")
	else
		--SetGroundPounderSettings(inst, "hibernation")
		inst:AddTag("hibernation")
	end
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
end

local function OnCollide(inst, other)

	local v1 = Vector3(inst.Physics:GetVelocity())
	if v1:LengthSq() < 1 then return end

	inst:DoTaskInTime(2*FRAMES, function()
		if other and other.components.workable and other.components.workable.workleft > 0 then
			SpawnPrefab("collapse_small").Transform:SetPosition(other:GetPosition():Get())
			other.components.lootdropper:SetLoot({})
			other.components.workable:Destroy(inst)
		end
	end)
end

local function WorkEntities(inst)
	local pt = inst:GetPosition()
	local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 5, nil, {"insect"})
	local heading_angle = -(inst.Transform:GetRotation())
	local dir = Vector3(math.cos(heading_angle*DEGREES),0, math.sin(heading_angle*DEGREES))

	for k,v in pairs(ents) do
		if v and v.components.workable then
			local hp = v:GetPosition()
			local offset = (hp - pt):GetNormalized()
			local dot = offset:Dot(dir)
			if dot > .3 then
				v.components.workable:Destroy(inst)
			end
		end
	end
end

local function LaunchItem(inst, target, item)
	if item.Physics then

		local x, y, z = item:GetPosition():Get()
		y = .1
		item.Physics:Teleport(x,y,z)

		local hp = target:GetPosition()
		local pt = inst:GetPosition()
		local vel = (hp - pt):GetNormalized()
		local speed = 5 + (math.random() * 2)
		local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
		item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)

	end
end

local function OnGroundPound(inst)
	if math.random() < .2 then 
		inst.components.shedder:DoMultiShed(3, false) -- can't drop too many, or it'll be really easy to farm for thick furs
	end
end

local function OnHitOther(inst, data)
	local other = data.target
	if other and other.components.inventory then
		local item = other.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if not item then return end
		other.components.inventory:DropItem(item)
		LaunchItem(inst, data.target, item)
	end
end

local function ontimerdone(inst, data)
	if data.name == "GroundPound" then
		inst.cangroundpound = true
	elseif data.name == "Yawn" and inst:HasTag("hibernation") then 
		inst.canyawn = true
	end
end

local function ShouldSleep(inst)
	-- don't fall asleep if we have a target, we were either chasing it, or it woke us up
	if inst.components.combat.target then
		return false
	end

	-- don't fall asleep while on fire
	if inst.components.health.takingfiredamage then 
		return false
	end

	if TheWorld.state.season == "winter" or TheWorld.state.season == "spring" then 
		inst.components.shedder:StopShedding()
		inst:AddTag("hibernation")
		inst:AddTag("asleep")
		inst.AnimState:SetBuild("bearger_groggy_build")
		--SetGroundPounderSettings(inst, "hibernation")
		--inst.components.health:SetAbsorptionAmount(.15)
		return true
	end
	
	return false
end

local function ShouldWake(inst)
	if TheWorld.state.season == "summer" or TheWorld.state.season == "autumn" then 
		
		inst.components.shedder:StartShedding(TUNING.BEARGER_SHED_INTERVAL)
		inst:RemoveTag("hibernation")
		inst:RemoveTag("asleep")
		inst.AnimState:SetBuild("bearger_build")
		--SetGroundPounderSettings(inst, "normal")
		--inst.components.health:SetAbsorptionAmount(0)
		return true
	else
		return false
	end
end

local function OnLostTarget(inst, data)
	--Remove the listening set up on "OnCombatTarget"
	if data.oldtarget and data.oldtarget.BEARGER_OnDropItemFn then
		inst:RemoveEventCallback("dropitem", data.oldtarget.BEARGER_OnDropItemFn, data.oldtarget)
	end
end

local function OnCombatTarget(inst, data)
	--Listen for dropping of items... if it's food, maybe forgive your target?
	if data.oldtarget then
		OnLostTarget(inst, data)
	end
	if data.target then
		inst.num_food_cherrypicked = TUNING.BEARGER_STOLEN_TARGETS_FOR_AGRO - 1
		inst.components.locomotor.walkspeed = TUNING.BEARGER_ANGRY_WALK_SPEED
		data.target.BEARGER_OnDropItemFn = function(target, info)
			if inst.components.eater:CanEat(info.item) then
				--print("Bearger saw dropped food, losing target")
				if info.item:HasTag("honeyed") or math.random() < 1 then
					inst.components.combat:SetTarget(nil)
				end
			end
		end
		inst:ListenForEvent("dropitem", data.target.BEARGER_OnDropItemFn, data.target)
	else
		inst.components.locomotor.walkspeed = TUNING.BEARGER_CALM_WALK_SPEED
	end
end

local function IsTargetValidForAreaAttack(inst, target)

	local pos = Vector3(inst.Transform:GetWorldPosition())
	local targetPos = Vector3(target.Transform:GetWorldPosition())

	local forwardAngle = inst.Transform:GetRotation()*DEGREES
	local forwardVector = Vector3(math.cos(forwardAngle), 0, math.sin(forwardAngle))

	return IsWithinAngle(pos, forwardVector, TUNING.BEARGER_ATTACK_CONE_WIDTH, targetPos)
end

local function SetStandState(inst, state)
	--"quad" or "bi" state
	inst.StandState = string.lower(state)
end

local function IsStandState(inst, state)
	return inst.StandState == string.lower(state)
end

local function OnKill(inst, data)
	if data and data.victim:HasTag("player") then
		inst.killedplayer = true
	end
end

local function OnDead(inst)
	TheWorld:PushEvent("beargerkilled", inst)
	inst.components.shedder:StopShedding()
end

local function OnRemove(inst)
	TheWorld:PushEvent("beargerremoved", inst)
end

local function OnPlayerAction(inst, player, data)
	if inst.components.sleeper and inst.components.sleeper:IsAsleep() then 
		return -- don't react to things when asleep
	end

	local playerAction = data.action
	local selfAction = inst:GetBufferedAction()

	if not playerAction or not selfAction then return end --You're not doing anything so whatever.

	if playerAction.target == selfAction.target then -- We got a problem bud.

		inst.num_food_cherrypicked = inst.num_food_cherrypicked + 1
		if inst.num_food_cherrypicked < TUNING.BEARGER_STOLEN_TARGETS_FOR_AGRO then
			inst.sg:GoToState("targetstolen")
		else
			inst.num_food_cherrypicked = TUNING.BEARGER_STOLEN_TARGETS_FOR_AGRO - 1
			inst.components.combat:SuggestTarget(player)
		end
	end
end

--[[ PLAYER TRACKING ]]


local function OnPlayerJoined(inst, player)
	for i, v in ipairs(inst._activeplayers) do
		if v == player then
			return
		end
	end

	inst:ListenForEvent("performaction", function(player, data) OnPlayerAction(inst, player, data) end, player)
	table.insert(inst._activeplayers, player)
end

local function OnPlayerLeft(inst, player)
	for i, v in ipairs(inst._activeplayers) do
		if v == player then
			table.remove(inst._activeplayers, i)
			return
		end
	end
end

--[[ END PLAYER TRACKING ]]

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()
	inst.DynamicShadow:SetSize(6, 3.5)
	local s = 1
	inst.Transform:SetScale(s,s,s)

	MakeGiantCharacterPhysics(inst, 1000, 1.5)

	inst.AnimState:SetBank("bearger")
	inst.AnimState:SetBuild("bearger_build")
	inst.AnimState:PlayAnimation("idle_loop", true)

	------------------------------------------

	inst:AddTag("epic")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("bearger")
	inst:AddTag("scarytoprey")
	inst:AddTag("largecreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnCollide)

	------------------------------------------

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = CalcSanityAura

	------------------

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.BEARGER_HEALTH)
	inst.components.health.destroytime = 5

	------------------

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.BEARGER_DAMAGE)
	inst.components.combat.playerdamagepercent = .5
	inst.components.combat:SetRange(TUNING.BEARGER_ATTACK_RANGE, TUNING.BEARGER_MELEE_RANGE)
	inst.components.combat:SetAreaDamage(6, 0.8)
	inst.components.combat.hiteffectsymbol = "bearger_body"
	inst.components.combat:SetAttackPeriod(TUNING.BEARGER_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/bearger/hurt")
	inst:ListenForEvent("killed", function(inst, data)
		if inst.components.combat and data and data.victim == inst.components.combat.target then
			inst.components.combat.target = nil
		end
	end)

	------------------------------------------
	inst:AddComponent("shedder")
	inst.components.shedder.shedItemPrefab = "furtuft"
	inst.components.shedder.shedHeight = 6.5
	inst.components.shedder:StartShedding(TUNING.BEARGER_SHED_INTERVAL)

	------------------------------------------

	inst.shouldgoaway = false
	inst:AddComponent("sleeper")
	inst.components.sleeper:SetResistance(4)
	inst.components.sleeper:SetSleepTest(ShouldSleep)
	inst.components.sleeper:SetWakeTest(ShouldWake)
	inst:ListenForEvent("onwakeup", function() inst.homelocation = inst:GetPosition() end )

	------------------------------------------

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("bearger")

	------------------------------------------

	inst:AddComponent("inspectable")
	inst.components.inspectable:RecordViews()

	------------------------------------------

	inst:AddComponent("knownlocations")
	inst:AddComponent("thief")
	inst:AddComponent("inventory")
	inst:AddComponent("groundpounder")
	inst.components.groundpounder.destroyer = true
	SetGroundPounderSettings(inst, "normal")
	--inst.components.groundpounder.damageRings = 2
	--inst.components.groundpounder.destructionRings = 2
	--inst.components.groundpounder.numRings = 3
	inst.components.groundpounder.groundpoundFn = OnGroundPound
	inst:AddComponent("timer")
	inst:AddComponent("eater")
	inst.components.eater:SetDiet({ FOODGROUP.BEARGER }, { FOODGROUP.BEARGER })
	inst.components.eater.eatwholestack = true

	------------------------------------------

	inst:WatchWorldState("season", OnSeasonChange)
	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onhitother", OnHitOther)
	inst:ListenForEvent("timerdone", ontimerdone)
	inst:ListenForEvent("death", OnDead)
	inst:ListenForEvent("onremove", OnRemove)

	------------------------------------------

	MakeLargeBurnableCharacter(inst, "swap_fire")
	MakeHugeFreezableCharacter(inst, "bearger_body")

	SetStandState(inst, "quad")--SetStandState(inst, "BI")
	inst.SetStandState = SetStandState
	inst.IsStandState = IsStandState
	inst.seenbase = false
	inst.WorkEntities = WorkEntities
	inst.cangroundpound = false
	inst.killedplayer = false

	inst.num_good_food_eaten = 0
	inst.num_food_cherrypicked = 0

	inst:DoTaskInTime(0, function() inst.homelocation = inst:GetPosition() end)

	inst:ListenForEvent("killed", OnKill)
	inst:ListenForEvent("newcombattarget", OnCombatTarget)

    inst.seenbase = nil -- for brain

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	------------------------------------------

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.BEARGER_CALM_WALK_SPEED
	inst.components.locomotor.runspeed = TUNING.BEARGER_RUN_SPEED
	inst.components.locomotor:SetShouldRun(true)

	inst:SetStateGraph("SGbearger")
	inst:SetBrain(brain)

	--[[ PLAYER TRACKING ]]

	inst._activeplayers = {}
	inst:ListenForEvent("ms_playerjoined", function(src, player) OnPlayerJoined(inst, player) end, TheWorld)
	inst:ListenForEvent("ms_playerleft", function(src, player) OnPlayerLeft(inst, player) end, TheWorld)

	for i, v in ipairs(AllPlayers) do
		OnPlayerJoined(inst, v)
	end

	--[[ END PLAYER TRACKING ]]

	return inst
end

return Prefab("common/monsters/bearger", fn, assets, prefabs)
