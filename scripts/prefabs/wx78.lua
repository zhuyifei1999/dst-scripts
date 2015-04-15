local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("ANIM", "anim/wx78.zip"),
	Asset("SOUND", "sound/wx78.fsb"),

    Asset("ANIM", "anim/ghost_wx78_build.zip"),   
}

local prefabs =
{
	"sparks",
}

--hunger, health, sanity
local function applyupgrades(inst)
	local max_upgrades = 15
    inst.level = math.min(inst.level, max_upgrades)

	local hunger_percent = inst.components.hunger:GetPercent()
	local health_percent = inst.components.health:GetPercent()
	local sanity_percent = inst.components.sanity:GetPercent()

	inst.components.hunger.max = math.ceil(TUNING.WX78_MIN_HUNGER + inst.level * (TUNING.WX78_MAX_HUNGER - TUNING.WX78_MIN_HUNGER) / max_upgrades)
	inst.components.health:SetMaxHealth(math.ceil(TUNING.WX78_MIN_HEALTH + inst.level * (TUNING.WX78_MAX_HEALTH - TUNING.WX78_MIN_HEALTH) / max_upgrades))
	inst.components.sanity.max = math.ceil(TUNING.WX78_MIN_SANITY + inst.level * (TUNING.WX78_MAX_SANITY - TUNING.WX78_MIN_SANITY) / max_upgrades)

	inst.components.hunger:SetPercent(hunger_percent)
	inst.components.health:SetPercent(health_percent)
	inst.components.sanity:SetPercent(sanity_percent)
end

local function oneat(inst, food)
	
	if food and food.components.edible and food.components.edible.foodtype == FOODTYPE.GEARS then
		--give an upgrade!
		inst.level = inst.level + 1
		applyupgrades(inst)	
		inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
		
		-- MarkL Can't do this here, need to do it inside the component
		-- todo pax Move upgrade logic elsewhere.  
		--inst.HUD.controls.status.heart:PulseGreen()
		--inst.HUD.controls.status.stomach:PulseGreen()
		--inst.HUD.controls.status.brain:PulseGreen()
		
		--inst.HUD.controls.status.brain:ScaleTo(1.3,1,.7)
		--inst.HUD.controls.status.heart:ScaleTo(1.3,1,.7)
		--inst.HUD.controls.status.stomach:ScaleTo(1.3,1,.7)
		
	end
end

local function onupdate(inst, dt)
	inst.charge_time = inst.charge_time - dt
	if inst.charge_time <= 0 then
		inst.charge_time = 0
		if inst.charged_task ~= nil then
			inst.charged_task:Cancel()
			inst.charged_task = nil
		end
		inst.SoundEmitter:KillSound("overcharge_sound")
		inst.Light:Enable(false)
		inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED 
		inst.AnimState:SetBloomEffectHandle("")
		inst.components.temperature.mintemp = -20
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_DISCHARGE"))
	else
    	local runspeed_bonus = .5
    	local rad = 3
    	if inst.charge_time < 60 then
    		rad = math.max(.1, rad * (inst.charge_time / 60))
    		runspeed_bonus = (inst.charge_time / 60)*runspeed_bonus
    	end

    	inst.Light:Enable(true)
    	inst.Light:SetRadius(rad)
		inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED*(1+runspeed_bonus)
		inst.components.temperature.mintemp = 10
	end

end

local function onlongupdate(inst, dt)
    inst.charge_time = math.max(0, inst.charge_time - dt)
end

local function onpreload(inst, data)
    if data ~= nil and data.level ~= nil then
        inst.level = data.level
        applyupgrades(inst)
        --re-set these from the save data, because of load-order clipping issues
        if data.health and data.health.health then inst.components.health:SetCurrentHealth(data.health.health) end
        if data.hunger and data.hunger.hunger then inst.components.hunger.current = data.hunger.hunger end
        if data.sanity and data.sanity.current then inst.components.sanity.current = data.sanity.current end
        inst.components.health:DoDelta(0)
        inst.components.hunger:DoDelta(0)
        inst.components.sanity:DoDelta(0)
    end
end

local function startovercharge(inst, duration)
    inst.charge_time = duration

    inst.SoundEmitter:KillSound("overcharge_sound")
    inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/charged", "overcharge_sound")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    if inst.charged_task == nil then
        inst.charged_task = inst:DoPeriodicTask(1, onupdate, nil, 1)
        onupdate(inst, 0)
    end
end

local function onload(inst, data)
    if data ~= nil and data.charge_time ~= nil then
        startovercharge(inst, data.charge_time)
    end
end

local function onsave(inst, data)
	data.level = inst.level > 0 and inst.level or nil
	data.charge_time = inst.charge_time > 0 and inst.charge_time or nil
end

local function onlightingstrike(inst)
	inst.components.health:DoDelta(TUNING.HEALING_SUPERHUGE, false, "lightning")
	inst.components.sanity:DoDelta(-TUNING.SANITY_LARGE)
	inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARGE"))

    startovercharge(inst, inst.charge_time + TUNING.TOTAL_DAY_TIME * (.5 + .5 * math.random()))
end

local function dorainsparks(inst, dt)
	for k, v in pairs(inst.components.inventory.equipslots) do
		if v.components.dapperness ~= nil and v.components.dapperness.mitigates_rain then
            --Mitigates rain, no sparks
            return
		end
	end

    if inst.spark_time > dt then
        inst.spark_time = inst.spark_time - dt
    else
		inst.spark_time = 3 + math.random() * 2
		inst.components.health:DoDelta(-.5, false, "rain")
		local sparks = SpawnPrefab("sparks")
        sparks.entity:SetParent(inst.entity)
        sparks.Transform:SetPosition(0, 1 + math.random() * 1.5, 0)
	end
end

local function onisraining(inst, israining)
    if israining then
        if inst.spark_task == nil then
            inst.spark_task = inst:DoPeriodicTask(.1, dorainsparks, nil, .1)
        end
    elseif inst.spark_task ~= nil then
        inst.spark_task:Cancel()
        inst.spark_task = nil
    end
end

local function onbecamerobot(inst)
    if inst.components.playerlightningtarget == nil then
        inst:AddComponent("playerlightningtarget")
        inst:ListenForEvent("lightningstrike", onlightingstrike)
        inst:WatchWorldState("israining", onisraining)
        onisraining(inst, TheWorld.state.israining)
    end

    inst.Light:Enable(false)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.75)
    inst.Light:SetIntensity(.9)
    inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)
end

local function onbecameghost(inst)
    --Cancel overcharge mode
    if inst.charged_task ~= nil then
        inst.charged_task:Cancel()
        inst.charged_task = nil
        inst.charge_time = 0
        inst.SoundEmitter:KillSound("overcharge_sound")
        inst.components.temperature.mintemp = -20
        --Ghost mode already sets light and bloom
    end

    if inst.spark_task ~= nil then
        inst.spark_task:Cancel()
        inst.spark_task = nil
    end

    if inst.components.playerlightningtarget ~= nil then
        inst:RemoveComponent("playerlightningtarget")
        inst:RemoveEventCallback("lightningstrike", onlightingstrike)
        inst:StopWatchingWorldState("israining", onisraining)
    end
end

local function ondeath(inst)
    if inst.level > 0 then
        local dropgears = math.random(math.floor(inst.level / 3), math.ceil(inst.level / 2))
        if dropgears > 0 then
            for i = 1, dropgears do
                local gear = SpawnPrefab("gears")
                if gear ~= nil then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    if gear.Physics ~= nil then
                        local speed = 2 + math.random()
                        local angle = math.random() * 2 * PI
                        gear.Transform:SetPosition(x, y + 1, z)
                        gear.Physics:SetVel(speed * math.cos(angle), speed * 3, speed * math.sin(angle))
                    else
                        gear.Transform:SetPosition(x, y, z)
                    end
                    if gear.components.propagator ~= nil then
                        gear.components.propagator:Delay(5)
                    end
                end
            end
        end
        inst.level = 0
        applyupgrades(inst)
    end
end

local function common_postinit(inst)
	inst:AddTag("nofiredamagefromlightning")
    inst.foleysound = "dontstarve/movement/foley/wx78"
end

local function master_postinit(inst)
	inst.level = 0
    inst.charged_task = nil
	inst.charge_time = 0
    inst.spark_task = nil
	inst.spark_time = 3

	inst.components.eater.ignoresspoilage = true
    inst.components.eater:SetCanEatGears()
	inst.components.eater:SetOnEatFn(oneat)
	applyupgrades(inst)

    inst:ListenForEvent("ms_respawnedfromghost", onbecamerobot)
    inst:ListenForEvent("ms_becameghost", onbecameghost)
    inst:ListenForEvent("death", ondeath)

    onbecamerobot(inst)

    inst.OnLongUpdate = onlongupdate
	inst.OnSave = onsave
	inst.OnLoad = onload
	inst.OnPreLoad = onpreload
end

return MakePlayerCharacter("wx78", prefabs, assets, common_postinit, master_postinit)