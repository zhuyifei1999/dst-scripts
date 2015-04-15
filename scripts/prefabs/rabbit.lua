local assets =
{
	Asset("ANIM", "anim/ds_rabbit_basic.zip"),
	Asset("ANIM", "anim/rabbit_build.zip"),
	Asset("ANIM", "anim/beard_monster.zip"),
	Asset("ANIM", "anim/rabbit_winter_build.zip"),
	Asset("SOUND", "sound/rabbit.fsb"),
}

local prefabs =
{
    "smallmeat",
    "cookedsmallmeat",
    "beardhair",
}

local rabbitsounds =
{
    scream = "dontstarve/rabbit/scream",
    hurt = "dontstarve/rabbit/scream_short",
}

local beardsounds =
{
    scream = "dontstarve/rabbit/beardscream",
    hurt = "dontstarve/rabbit/beardscream_short",
}

local wintersounds =
{
    scream = "dontstarve/rabbit/winterscream",
    hurt = "dontstarve/rabbit/winterscream_short",
}

local function onpickup(inst)
end

local brain = require "brains/rabbitbrain"

local function BecomeRabbit(inst)
	if not inst.israbbit or inst.iswinterrabbit then
		inst.AnimState:SetBuild("rabbit_build")

	    inst.israbbit = true
	    inst.iswinterrabbit = false
		-- TODO, not sure where to fit this
		inst.components.inventoryitem:ChangeImageName("rabbit")
		-- TODO: sounds need to be overridden clientside as well
		inst.sounds = rabbitsounds
		if inst.components.hauntable then 
            inst.components.hauntable.haunted = false 
        end
	end
end

local function DonWinterFur(inst)
	if not inst.iswinterrabbit or inst.israbbit then
		inst.AnimState:SetBuild("rabbit_winter_build")

		inst.israbbit = false
	    inst.iswinterrabbit = true
		-- TODO, not sure where to fit this
		inst.components.inventoryitem:ChangeImageName("rabbit_winter")
		-- TODO: sounds need to be overridden clientside as well
		inst.sounds = wintersounds
		if inst.components.hauntable then 
            inst.components.hauntable.haunted = false 
        end

	end
end

local function CheckTransformState(inst)
	if not inst.components.health:IsDead() then
		if TheWorld.state.issummer then
			BecomeRabbit(inst)
		else
			DonWinterFur(inst)
		end
	end
end

local function ondrop(inst)
	inst.sg:GoToState("stunned")
	CheckTransformState(inst)
end


local function OnWake(inst)
	CheckTransformState(inst)
	inst.checktask = inst:DoPeriodicTask(10, CheckTransformState)
end

local function OnSleep(inst)
	 if inst.checktask then
	 	inst.checktask:Cancel()
	 	inst.checktask = nil
	 end
end

local function GetCookProductFn(inst)
	if inst.israbbit or inst.iswinterrabbit then
		return "cookedsmallmeat" 
	else 
		return "cookedmonstermeat"
	end
end

local function OnCookedFn(inst)
	inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
end

local function OnAttacked(inst, data)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 30, {'rabbit'})
    
    local num_friends = 0
    local maxnum = 5
    for k,v in pairs(ents) do
        v:PushEvent("gohome")
        num_friends = num_friends + 1
        
        if num_friends > maxnum then
            break
        end
    end
end

local function OnSave(inst, data)
    if not inst.israbbit then
        data.israbbit = inst.israbbit
    end
    data.iswinterrabbit = inst.iswinterrabbit or nil
end        

local function OnLoad(inst, data)
    if data ~= nil and data.israbbit == false then
        if data.iswinterrabbit then
            DonWinterFur(inst)                  
        end
    end 
end

local function LootSetupFunction(self)
	local sane = true
	-- were we killed by an insane player?
	if self.inst.causeofdeath and self.inst.causeofdeath:HasTag("player") then
		if self.inst.causeofdeath.components.sanity ~= nil and self.inst.causeofdeath.components.sanity:IsCrazy() then
			sane = false
		end
	end
	if not sane then
		-- beardling loot
   		self:SetLoot{}
		self:AddRandomLoot("beardhair", .5)	    
		self:AddRandomLoot("monstermeat", 1)	    
		self:AddRandomLoot("nightmarefuel", 1)	  
		self.numrandomloot = 1  
	else
		-- regular loot
		self:SetLoot({"smallmeat"})
	end
end

local function PlayerSanityListener()
	return ThePlayer.components.sanity:GetPercent() > TUNING.BEARDLING_SANITY
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1, 0.5)

    inst.DynamicShadow:SetSize(1, .75)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("rabbit")
    inst.AnimState:SetBuild("rabbit_build")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddTag("animal")
    inst:AddTag("prey")
    inst:AddTag("rabbit")
    inst:AddTag("smallcreature")
    inst:AddTag("canbetrapped")

	inst.AnimState:SetClientsideBuildOverride("insane", "rabbit_build", "beard_monster")
	inst.AnimState:SetClientsideBuildOverride("insane", "rabbit_winter_build", "beard_monster")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.RABBIT_RUN_SPEED
    inst:SetStateGraph("SGrabbit")

    inst:SetBrain(brain)
    
    inst.data = {}
    
    inst:AddComponent("eater")
    inst.components.eater:SetVegetarian()

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.nobounce = true
	inst.components.inventoryitem.canbepickedup = false
	inst.components.inventoryitem:SetOnPickupFn(onpickup)
	inst.components.inventoryitem:SetOnDroppedFn(ondrop)
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = function(inst, observer)
											local sane = true
											-- were we killed by an insane player?
											if observer and observer:HasTag("player") then
												if observer.components.sanity ~= nil and observer.components.sanity:IsCrazy() then
													sane = false
												end
											end
											if not sane then
												return -TUNING.SANITYAURA_MED		
											else
												return 0
											end
										end

    inst:AddComponent("cookable")
    inst.components.cookable.product = GetCookProductFn
    inst.components.cookable:SetOnCookedFn(OnCookedFn)
    
    inst:AddComponent("knownlocations")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "chest"

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.RABBIT_HEALTH)
    inst.components.health.murdersound = "dontstarve/rabbit/scream_short"
    
    MakeSmallBurnableCharacter(inst, "chest")
    MakeTinyFreezableCharacter(inst, "chest")

    inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLootSetupFn(
						LootSetupFunction
--[[
						function(self)
							local sane = true
							-- were we killed by an insane player?
							if self.inst.causeofdeath and self.inst.causeofdeath:HasTag("player") then
								if self.inst.causeofdeath.components.sanity ~= nil and self.inst.causeofdeath.components.sanity:IsCrazy() then
									sane = false
								end
							end
							if not sane then
								-- beardling loot
					    		self:SetLoot{}
								self:AddRandomLoot("beardhair", .5)	    
								self:AddRandomLoot("monstermeat", 1)	    
								self:AddRandomLoot("nightmarefuel", 1)	  
								self.numrandomloot = 1  
							else
								-- regular loot
								self:SetLoot({"smallmeat"})
							end
						end
]]
						)

    
    inst:AddComponent("inspectable")
    inst:AddComponent("sleeper")

	BecomeRabbit(inst)
    CheckTransformState(inst)
    inst.CheckTransformState = CheckTransformState
	
	inst.OnEntityWake = OnWake
	inst.OnEntitySleep = OnSleep    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntablePanic(inst)
    -- AddHauntableCustomReaction(inst, function(inst, haunter)
    --     if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
    --         BecomeBeardling(inst)
    --         inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
    --         if inst.checktask then
    --             inst.checktask:Cancel()
    --             inst.checktask = nil
    --         end
    --     end
    -- end, true, nil, true)
        
    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

return Prefab("forest/animals/rabbit", fn, assets, prefabs)