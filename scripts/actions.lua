require "class"
require "bufferedaction"

local function DefaultRangeCheck(doer, target)
    if target == nil then
        return
    end
    local target_x, target_y, target_z = target.Transform:GetWorldPosition()
    local doer_x, doer_y, doer_z = doer.Transform:GetWorldPosition()
    local dst = distsq(target_x, target_z, doer_x, doer_z)
    return dst <= 16
end

Action = Class(function(self, priority, instant, rmb, distance, ghost_valid, ghost_exclusive, canforce, rangecheckfn)
    self.priority = priority or 0
    self.fn = function() return false end
    self.strfn = nil
    self.testfn = nil -- Don't use this for multiplayer
    self.instant = instant or false
    self.rmb = rmb or nil
    self.distance = distance or nil
    self.ghost_valid = ghost_valid or false
    self.ghost_exclusive = ghost_exclusive or false
    if self.ghost_exclusive then self.ghost_valid = true end -- If it's ghost-exclusive, then it must be ghost-valid
    self.canforce = canforce or nil
    self.rangecheckfn = self.canforce ~= nil and rangecheckfn or nil
    self.mod_name = nil
end)

ACTIONS =
{
	REPAIR = Action(),
    READ = Action(),
    DROP = Action(-1),
    TRAVEL = Action(),
    CHOP = Action(),
    ATTACK = Action(2, nil, nil, nil, nil, nil, true), -- No custom range check, attack already handles that
    EAT = Action(),
    PICK = Action(),
    PICKUP = Action(1),
    MINE = Action(),
    DIG = Action(nil, nil, true),
    GIVE = Action(nil, nil, nil, nil, nil, nil, true, DefaultRangeCheck),
    GIVETOPLAYER = Action(3, nil, nil, nil, nil, nil, true, DefaultRangeCheck),
    GIVEALLTOPLAYER = Action(3, nil, nil, nil, nil, nil, true, DefaultRangeCheck),
    FEEDPLAYER = Action(3, nil, true, nil, nil, nil, true, DefaultRangeCheck),
    COOK = Action(),
    DRY = Action(),
    ADDFUEL = Action(),
    LIGHT = Action(-4),
    EXTINGUISH = Action(0),
    LOOKAT = Action(-3, true, nil, nil, true),
    TALKTO = Action(3, true),
    WALKTO = Action(-4, nil, nil, nil, true),
    BAIT = Action(),
    CHECKTRAP = Action(2),
    BUILD = Action(),
    PLANT = Action(),
    HARVEST = Action(),
    GOHOME = Action(),
    SLEEPIN = Action(),
    EQUIP = Action(0,true),
    UNEQUIP = Action(-2,true),
    --OPEN_SHOP = Action(),
    SHAVE = Action(),
    STORE = Action(),
    RUMMAGE = Action(-1),
    DEPLOY = Action(),
    PLAY = Action(),
    CREATE = Action(),
	JOIN = Action(),
    NET = Action(3, nil, nil, nil, nil, nil, true, DefaultRangeCheck),
    CATCH = Action(3, nil, nil, math.huge),
    FISH = Action(),
    REEL = Action(0, true),
    POLLINATE = Action(),
    FERTILIZE = Action(),
    LAYEGG = Action(),
    HAMMER = Action(3),
    TERRAFORM = Action(),
	JUMPIN = Action(),
	RESETMINE = Action(3),
    ACTIVATE = Action(),
    MURDER = Action(0),
    HEAL = Action(),
    INVESTIGATE = Action(),
    UNLOCK = Action(),
    TEACH = Action(),
    TURNON = Action(2),
    TURNOFF = Action(2),
    SEW = Action(),
    STEAL = Action(),
    USEITEM = Action(1, true),
    TAKEITEM = Action(),
    MAKEBALLOON = Action(),
    CASTSPELL = Action(-1, false, true, 20),
    BLINK = Action(10, false, true, 36),
    COMBINESTACK = Action(),
    TOGGLE_DEPLOY_MODE = Action(1),
    HAUNT = Action(0, false, false, 2, true, true, true, DefaultRangeCheck),
    UNPIN = Action(),
}

ACTION_IDS = {}
for k, v in pairs(ACTIONS) do
    v.str = STRINGS.ACTIONS[k] or "ACTION"
    v.id = k
    table.insert(ACTION_IDS, k)
    v.code = #ACTION_IDS
end

ACTION_MOD_IDS = {} --This will be filled in when mods add actions via AddAction in modutil.lua

----set up the action functions!

ACTIONS.EAT.fn = function(act)
    local obj = act.target or act.invobject
    if act.doer.components.eater and obj and obj.components.edible then
    	return act.doer.components.eater:Eat(obj) 
    end
end

ACTIONS.STEAL.fn = function(act)
    local obj = act.target
    local attack = false
    if act.attack then attack = act.attack end    

    if (obj.components.inventoryitem and obj.components.inventoryitem:IsHeld()) then
        return act.doer.components.thief:StealItem(obj.components.inventoryitem.owner, obj, attack)
    end
end

ACTIONS.MAKEBALLOON.fn = function(act)
    if act.doer and act.invobject and act.invobject.components.balloonmaker then
        if act.doer.components.sanity then
            act.doer.components.sanity:DoDelta(-TUNING.SANITY_TINY)
        end
        local x,y,z = act.doer.Transform:GetWorldPosition()
        local angle = TheCamera.headingtarget + math.random()*10*DEGREES-5*DEGREES
        x = x + .5*math.cos(angle)
        z = z + .5*math.sin(angle)
        act.invobject.components.balloonmaker:MakeBalloon(x,y,z)
    end
    return true
end

ACTIONS.EQUIP.fn = function(act)
    if act.doer.components.inventory then
        return act.doer.components.inventory:Equip(act.invobject)
    end
end

ACTIONS.UNEQUIP.fn = function(act)
    if act.doer.components.inventory and act.invobject and act.invobject.components.inventoryitem.cangoincontainer then
		act.doer.components.inventory:GiveItem(act.invobject)
    	--return act.doer.components.inventory:Unequip(act.invobject)
    	return true
    elseif act.doer.components.inventory and act.invobject and not act.invobject.components.inventoryitem.cangoincontainer then
        act.doer.components.inventory:DropItem(act.invobject, true, true)
        return true
    end
end

ACTIONS.PICKUP.fn = function(act)
    if act.doer.components.inventory ~= nil and
        act.target ~= nil and
        act.target.components.inventoryitem ~= nil and
        not act.target:IsInLimbo() and
        not act.target:HasTag("catchable") then

        act.doer:PushEvent("onpickup", {item = act.target})

        --special case for trying to carry two backpacks
        if not act.target.components.inventoryitem.cangoincontainer and act.target.components.equippable and act.doer.components.inventory:GetEquippedItem(act.target.components.equippable.equipslot) then
            local item = act.doer.components.inventory:GetEquippedItem(act.target.components.equippable.equipslot)
            if item.components.inventoryitem and item.components.inventoryitem.cangoincontainer then
                
                --act.doer.components.inventory:SelectActiveItemFromEquipSlot(act.target.components.equippable.equipslot)
                act.doer.components.inventory:GiveItem(act.doer.components.inventory:Unequip(act.target.components.equippable.equipslot))
            else
                act.doer.components.inventory:DropItem(act.doer.components.inventory:GetEquippedItem(act.target.components.equippable.equipslot))
            end
            act.doer.components.inventory:Equip(act.target)
            return true
        end

        if act.doer:HasTag("player") and act.target.components.equippable and not act.doer.components.inventory:GetEquippedItem(act.target.components.equippable.equipslot) then
            act.doer.components.inventory:Equip(act.target)
        else
            act.doer.components.inventory:GiveItem(act.target, nil, act.target:GetPosition())
        end
        return true 
    end
end

ACTIONS.REPAIR.fn = function(act)
	if act.target and act.target.components.repairable and act.invobject and act.invobject.components.repairer then
		return act.target.components.repairable:Repair(act.doer, act.invobject)
	end
end

ACTIONS.SEW.fn = function(act)
	if act.target and act.target.components.fueled and act.invobject and act.invobject.components.sewing then
		return act.invobject.components.sewing:DoSewing(act.target, act.doer)
	end
end

ACTIONS.RUMMAGE.fn = function(act)
    local targ = act.target or act.invobject

    if targ ~= nil and targ.components.container ~= nil then
        if targ.components.container:IsOpenedBy(act.doer) then
            targ.components.container:Close()
            return true
        elseif targ.components.container:IsOpen() then
            return false, "INUSE"
        elseif targ.components.container.canbeopened then
            --Silent fail for opening containers in the dark
            if CanEntitySeeTarget(act.doer, targ) then
                targ.components.container:Open(act.doer)
            end
            return true
        end
    end
end

ACTIONS.RUMMAGE.strfn = function(act)
    local targ = act.target or act.invobject

    if targ ~= nil and targ.replica.container ~= nil and targ.replica.container:IsOpenedBy(act.doer) then
        return "CLOSE"
    end
end

ACTIONS.DROP.fn = function(act)
    return act.doer.components.inventory ~= nil
        and act.doer.components.inventory:DropItem(
                act.invobject,
                act.options.wholestack and
                not (act.invobject ~= nil and
                    act.invobject.components.stackable ~= nil and
                    act.invobject.components.stackable.forcedropsingle),
                false,
                act.pos)
        or nil
end

ACTIONS.DROP.strfn = function(act)
    if act.invobject ~= nil and not act.invobject:HasActionComponent("deployable") then
        if act.invobject:HasTag("trap") then
            return "SETTRAP"
        elseif act.invobject:HasTag("mine") then
            return "SETMINE"
        elseif act.invobject.prefab == "pumpkin_lantern" then
            return "PLACELANTERN"
        end
    end
end

ACTIONS.LOOKAT.fn = function(act)
    local targ = act.target or act.invobject
    if targ ~= nil and targ.components.inspectable ~= nil then
        local desc = targ.components.inspectable:GetDescription(act.doer)
        if desc ~= nil then
            if act.doer.components.playercontroller == nil or
                not act.doer.components.playercontroller.directwalking then
                act.doer.components.locomotor:Stop()
            end
            if act.doer.components.talker ~= nil then
                act.doer.components.talker:Say(desc, 2.5, targ.components.inspectable.noanim)
            end
            return true
        end
    end
end

ACTIONS.READ.fn = function(act)
    local targ = act.target or act.invobject
    if targ and targ.components.book and act.doer and act.doer.components.reader then
        return act.doer.components.reader:Read(targ)
    end
end

ACTIONS.TALKTO.fn = function(act)
    local targ = act.target or act.invobject
    if targ and targ.components.talkable then
        act.doer.components.locomotor:Stop()

        if act.target.components.maxwelltalker then
            if not act.target.components.maxwelltalker:IsTalking() then
                act.target:PushEvent("talkedto")
                act.target.task = act.target:StartThread(function() act.target.components.maxwelltalker:DoTalk(act.target) end)
            end
        end
        return true
    end
end

ACTIONS.BAIT.fn = function(act)
    if act.target.components.trap then
	    act.target.components.trap:SetBait(act.doer.components.inventory:RemoveItem(act.invobject))
	    return true
	end
end

ACTIONS.DEPLOY.fn = function(act)
    if act.invobject and act.invobject.components.deployable and act.invobject.components.deployable:CanDeploy(act.pos) then
        local container = act.invobject.components.inventoryitem and act.invobject.components.inventoryitem:GetContainer()
	    local obj = container and container:RemoveItem(act.invobject) or act.invobject
	    if obj then
			if obj.components.deployable:Deploy(act.pos, act.doer) then
				return true
            elseif container then
                container:GiveItem(obj)
            else
                act.doer.components.inventory:GiveItem(obj)
			end
		end
    end
end

ACTIONS.DEPLOY.strfn = function(act)
    if act.invobject ~= nil then
        if act.invobject:HasTag("groundtile") then
            return "GROUNDTILE"
        elseif act.invobject:HasTag("wallbuilder") then
            return "WALL"
        elseif act.invobject:HasTag("eyeturret") then
            return "TURRET"
        end
    end
end

ACTIONS.CHECKTRAP.fn = function(act)
    if act.target.components.trap then
	    act.target.components.trap:Harvest(act.doer)
	    return true
    end
end

ACTIONS.CHOP.fn = function(act)
    if act.target.components.workable and act.target.components.workable.action == ACTIONS.CHOP then
        local numworks = 1

        if act.invobject and act.invobject.components.tool then
            numworks = act.invobject.components.tool:GetEffectiveness(ACTIONS.CHOP)
        elseif act.doer and act.doer.components.worker then
            numworks = act.doer.components.worker:GetEffectiveness(ACTIONS.CHOP)
        end
        act.target.components.workable:WorkedBy(act.doer, numworks)
    end
    return true
end

ACTIONS.FERTILIZE.fn = function(act)
    if act.target.components.crop and not act.target.components.crop:IsReadyForHarvest() and act.invobject and act.invobject.components.fertilizer then
		local obj = act.doer.components.inventory:RemoveItem(act.invobject)
        if act.target.components.crop:Fertilize(obj) then
			return true
		else
			act.doer.components.inventory:GiveItem(obj)
			return false
		end
    elseif act.target.components.grower and act.target.components.grower:IsEmpty() and act.invobject and act.invobject.components.fertilizer then
		local obj = act.doer.components.inventory:RemoveItem(act.invobject)
        act.target.components.grower:Fertilize(obj)
        return true
	elseif act.target.components.pickable and act.target.components.pickable:CanBeFertilized() and act.invobject and act.invobject.components.fertilizer then
		local obj = act.doer.components.inventory:RemoveItem(act.invobject)
        act.target.components.pickable:Fertilize(obj)
		return true		
	end
end

ACTIONS.MINE.fn = function(act)
    if act.target.components.workable and act.target.components.workable.action == ACTIONS.MINE then
        local numworks = 1

        if act.invobject and act.invobject.components.tool then
            numworks = act.invobject.components.tool:GetEffectiveness(ACTIONS.MINE)
        elseif act.doer and act.doer.components.worker then
            numworks = act.doer.components.worker:GetEffectiveness(ACTIONS.MINE)
        end
        act.target.components.workable:WorkedBy(act.doer, numworks)
    end
    return true
end

ACTIONS.HAMMER.fn = function(act)
    if act.target.components.workable and act.target.components.workable.action == ACTIONS.HAMMER then
        local numworks = 1

        if act.invobject and act.invobject.components.tool then
            numworks = act.invobject.components.tool:GetEffectiveness(ACTIONS.HAMMER)
        elseif act.doer and act.doer.components.worker then
            numworks = act.doer.components.worker:GetEffectiveness(ACTIONS.HAMMER)
        end
        act.target.components.workable:WorkedBy(act.doer, numworks)
    end
    return true
end

ACTIONS.NET.fn = function(act)
    if act.target ~= nil and act.target.components.workable and act.target.components.workable.action == ACTIONS.NET then
        act.target.components.workable:WorkedBy(act.doer)
    end
    return true
end

ACTIONS.CATCH.fn = function(act)
    return true
end

ACTIONS.FISH.fn = function(act)
    local fishingrod = act.invobject.components.fishingrod
    if fishingrod then
        fishingrod:StartFishing(act.target, act.doer)
    end
    return true
end

ACTIONS.REEL.fn = function(act)
    local fishingrod = act.invobject.components.fishingrod
    if fishingrod and fishingrod:IsFishing() then
        if fishingrod:HasHookedFish() then
            fishingrod:Reel()
        elseif fishingrod:FishIsBiting() then
            fishingrod:Hook()
        else
            fishingrod:StopFishing()
        end
    end
    return true
end

ACTIONS.REEL.strfn = function(act)
    local fishingrod = act.invobject.replica.fishingrod
    if fishingrod ~= nil and fishingrod:GetTarget() == act.target then
        if fishingrod:HasHookedFish() then
            return "REEL"
        elseif act.doer:HasTag("nibble") then
            return "HOOK"
        else
            return "CANCEL"
        end
    end
end

ACTIONS.DIG.fn = function(act)
    if act.target.components.workable and act.target.components.workable.action == ACTIONS.DIG then
        local numworks = 1

        if act.invobject and act.invobject.components.tool then
            numworks = act.invobject.components.tool:GetEffectiveness(ACTIONS.DIG)
        elseif act.doer and act.doer.components.worker then
            numworks = act.doer.components.worker:GetEffectiveness(ACTIONS.DIG)
        end
        act.target.components.workable:WorkedBy(act.doer, numworks)
    end
    return true
end

ACTIONS.PICK.fn = function(act)
    if act.target.components.pickable then
        act.target.components.pickable:Pick(act.doer)
        return true
    end
end

ACTIONS.ATTACK.fn = function(act)
    act.doer.components.combat:DoAttack(act.target)
    return true
end

ACTIONS.ATTACK.strfn = function(act)
    local targ = act.target or act.invobject
    
    if targ and targ:HasTag("smashable") then
        return "SMASHABLE"
    end
end

ACTIONS.COOK.fn = function(act)
	if act.target.components.cooker ~= nil then
	    local ingredient = act.doer.components.inventory:RemoveItem(act.invobject)
        ingredient.Transform:SetPosition(act.target.Transform:GetWorldPosition())

        if ingredient.components.health and ingredient.components.combat then
            act.doer:PushEvent("killed", {victim = ingredient})
        end

	    local product = act.target.components.cooker:CookItem(ingredient, act.doer)
	    if product then
	        act.doer.components.inventory:GiveItem(product, nil, act.target:GetPosition())
	        return true
	    end
    elseif act.target.components.stewer ~= nil then
        if act.target.components.stewer.cooking then
            --Already cooking
            return true
        end
        local container = act.target.components.container
        if container ~= nil and container:IsOpen() and not container:IsOpenedBy(act.doer) then
            return false, "INUSE"
        elseif not act.target.components.stewer:CanCook() then
            return false
        end
		act.target.components.stewer:StartCooking()
		return true
    end
end

ACTIONS.DRY.fn = function(act)
    if act.target.components.dryer then
        if not act.target.components.dryer:CanDry(act.invobject) then
            return false
        end

        local ingredient = act.doer.components.inventory:RemoveItem(act.invobject)
        if not act.target.components.dryer:StartDrying(ingredient) then
            act.doer.components.inventory:GiveItem(ingredient, nil, act.target:GetPosition())
            return false 
        end
        return true
    end
end

ACTIONS.ADDFUEL.fn = function(act)
    if act.doer.components.inventory then
        local fuel = act.doer.components.inventory:RemoveItem(act.invobject)
        if fuel then
            if act.target.components.fueled:TakeFuelItem(fuel) then
                return true
            else
                --print("False")
                act.doer.components.inventory:GiveItem(fuel)
            end
        end
    end
end

ACTIONS.GIVE.fn = function(act)
    if act.target ~= nil and act.target.components.trader ~= nil then
        act.target.components.trader:AcceptGift(act.doer, act.invobject)
        return true
    end
end

ACTIONS.GIVETOPLAYER.fn = function(act)
    if act.target ~= nil and act.target.components.trader ~= nil and act.target.components.inventory ~= nil then
        if act.target.components.inventory:CanAcceptCount(act.invobject, 1) <= 0 then
            return false, "FULL"
        end
        act.target.components.trader:AcceptGift(act.doer, act.invobject, 1)
        return true
    end
end

ACTIONS.GIVEALLTOPLAYER.fn = function(act)
    if act.target ~= nil and act.target.components.trader ~= nil and act.target.components.inventory ~= nil then
        local count = act.target.components.inventory:CanAcceptCount(act.invobject)
        if count <= 0 then
            return false, "FULL"
        end
        act.target.components.trader:AcceptGift(act.doer, act.invobject, count)
        return true
    end
end

ACTIONS.FEEDPLAYER.fn = function(act)
    if act.target ~= nil and
        act.target:IsValid() and
        act.target.sg:HasStateTag("idle") and
        not (act.target.sg:HasStateTag("busy") or
            act.target.sg:HasStateTag("attacking") or
            act.target.sg:HasStateTag("sleeping") or
            act.target:HasTag("playerghost")) and
        act.target.components.eater ~= nil and
        act.invobject.components.edible ~= nil and
        act.target.components.eater:CanEat(act.invobject) and
        (TheNet:GetPVPEnabled() or
        not (act.invobject:HasTag("badfood") or
            act.invobject:HasTag("spoiled"))) then

        local food = act.invobject.components.inventoryitem:RemoveFromOwner()
        if food ~= nil then
            act.target:AddChild(food)
            food:RemoveFromScene()
            food.components.inventoryitem:HibernateLivingItem()
            food.persists = false
            if food.components.edible.foodtype == FOODTYPE.MEAT then
                act.target.sg:GoToState("eat", food)
            else
                act.target.sg:GoToState("quickeat", food)
            end
            return true
        end
    end
end

ACTIONS.GIVE.strfn = function(act)
    local targ = act.target or act.invobject
    
    if targ ~= nil and targ:HasTag("altar") then
        if targ.state:value() then
            return "READY"
        else
            return "NOTREADY"
        end
    end
end

ACTIONS.STORE.fn = function(act)
    if act.target.components.container and act.invobject.components.inventoryitem and act.doer.components.inventory then
        
        if act.target.components.container:IsOpen() and not act.target.components.container:IsOpenedBy(act.doer) then
            return false, "INUSE"
        end

        if not act.target.components.container:CanTakeItemInSlot(act.invobject) then
			return false, "NOTALLOWED"
        end

		local item = act.invobject.components.inventoryitem:RemoveFromOwner(act.target.components.container.acceptsstacks)
        if item then
			if not act.target.components.inventoryitem then
				act.target.components.container:Open(act.doer)
			end
			
            if not act.target.components.container:GiveItem(item,nil,nil,false) then
                if TheInput:ControllerAttached() then
				    act.doer.components.inventory:GiveItem(item)
                else
                    act.doer.components.inventory:GiveActiveItem(item)
                end
				return false
            end
				return true
            
        end
    elseif act.target.components.occupiable and act.invobject and act.invobject.components.occupier and act.target.components.occupiable:CanOccupy(act.invobject) then
		local item = act.invobject.components.inventoryitem:RemoveFromOwner()
		return act.target.components.occupiable:Occupy(item)
    end
end

ACTIONS.STORE.strfn = function(act)
    if act.target ~= nil then
        if act.target.prefab == "cookpot" then
            return "COOK"
        elseif act.target.prefab == "birdcage" then
            return "IMPRISON"
        end
    end
end

ACTIONS.BUILD.fn = function(act)
    if act.doer.components.builder then
	    if act.doer.components.builder:DoBuild(act.recipe, act.pos) then
	        return true
	    end
	end
end

ACTIONS.PLANT.fn = function(act)
    if act.doer.components.inventory then
	    local seed = act.doer.components.inventory:RemoveItem(act.invobject)
	    if seed then
	        if act.target.components.grower:PlantItem(seed) then
	            return true
	        else
	            act.doer.components.inventory:GiveItem(seed)
	        end
	    end
   end
end

ACTIONS.HARVEST.fn = function(act)
    if act.target.components.crop then
    	return act.target.components.crop:Harvest(act.doer)
    elseif act.target.components.harvestable then
        return act.target.components.harvestable:Harvest(act.doer)
    elseif act.target.components.stewer then
		return act.target.components.stewer:Harvest(act.doer)
    elseif act.target.components.dryer then
		return act.target.components.dryer:Harvest(act.doer)
    elseif act.target.components.occupiable and act.target.components.occupiable:IsOccupied() then
		local item =act.target.components.occupiable:Harvest(act.doer)
		if item then
			act.doer.components.inventory:GiveItem(item)
			return true
		end
    end
end

ACTIONS.HARVEST.strfn = function(act)
    if act.target ~= nil and act.target.prefab == "birdcage" then
        return "FREE"
    end
end

ACTIONS.LIGHT.fn = function(act)
    if act.invobject and act.invobject.components.lighter then
		act.invobject.components.lighter:Light(act.target)
		return true
    end
end

ACTIONS.SLEEPIN.fn = function(act)

	local bag = nil
	if act.target and act.target.components.sleepingbag then bag = act.target end
	if act.invobject and act.invobject.components.sleepingbag then bag = act.invobject end
	
	if bag and act.doer then
		bag.components.sleepingbag:DoSleep(act.doer)
		return true
	end
	
end

ACTIONS.SHAVE.fn = function(act)
    
    if act.invobject and act.invobject.components.shaver then
        local shavee = act.target or act.doer
        if shavee and shavee.components.beard then
            return shavee.components.beard:Shave(act.doer, act.invobject)
        end
    end
    
end

ACTIONS.PLAY.fn = function(act)
    if act.invobject and act.invobject.components.instrument then
        return act.invobject.components.instrument:Play(act.doer)
    end
end

ACTIONS.POLLINATE.fn = function(act)
    if act.doer.components.pollinator then
		if act.target then
			return act.doer.components.pollinator:Pollinate(act.target)
		else
			return act.doer.components.pollinator:CreateFlower()
		end
    end
end

ACTIONS.TERRAFORM.fn = function(act)
	if act.invobject and act.invobject.components.terraformer then
		return act.invobject.components.terraformer:Terraform(act.pos)
	end
end

ACTIONS.EXTINGUISH.fn = function(act)
    if act.target.components.burnable
       and act.target.components.burnable:IsBurning() then
        if act.target.components.fueled and not act.target.components.fueled:IsEmpty() then
            act.target.components.fueled:ChangeSection(-1)
        else
            act.target.components.burnable:Extinguish()
        end
        return true
    end
end

ACTIONS.LAYEGG.fn = function(act)
    if act.target.components.pickable and not act.target.components.pickable.canbepicked then
		return act.target.components.pickable:Regen()
    end
end

ACTIONS.INVESTIGATE.fn = function(act)
    local investigatePos = act.doer.components.knownlocations and act.doer.components.knownlocations:GetLocation("investigate")
    if investigatePos then
        act.doer.components.knownlocations:RememberLocation("investigate", nil)
        --try to get a nearby target
        if act.doer.components.combat then
            act.doer.components.combat:TryRetarget()
        end
		return true
    end
end


ACTIONS.GOHOME.fn = function(act)
    --this is gross. make it better later.
    if act.target.components.spawner then
        return act.target.components.spawner:GoHome(act.doer)
    elseif act.target.components.childspawner then
        return act.target.components.childspawner:GoHome(act.doer)
    elseif act.pos then
        if act.target then
            act.target:PushEvent("onwenthome", {doer = act.doer})
        end
        act.doer:Remove()
        return true
    end
end

ACTIONS.JUMPIN.fn = function(act)
    if act.target.components.teleporter then
	    act.target.components.teleporter:Activate(act.doer)
	    return true
	end
end

ACTIONS.RESETMINE.fn = function(act)
    if act.target.components.mine then
	    act.target.components.mine:Reset()
	    return true
	end
end

ACTIONS.ACTIVATE.fn = function(act)
    if act.target.components.activatable then
        act.target.components.activatable:DoActivate(act.doer)
        return true
    end
end

ACTIONS.ACTIVATE.strfn = function(act)
    if act.target.GetActivateVerb ~= nil then
        return act.target:GetActivateVerb(act.doer)
    end
end

ACTIONS.HAUNT.fn = function(act)
    if act.target ~= nil and
        act.target:IsValid() and
        act.target.components.hauntable ~= nil and
        not act.target:HasTag("haunted") then
        act.doer:PushEvent("haunt", { target = act.target })
        act.target.components.hauntable:DoHaunt(act.doer)
        return true
    end
end

ACTIONS.MURDER.fn = function(act)

    local murdered = act.invobject or act.target
    if murdered and murdered.components.health then

        murdered.components.inventoryitem:RemoveFromOwner(true)
        murdered.Transform:SetPosition(act.doer.Transform:GetWorldPosition())

        if murdered.components.health.murdersound then
            act.doer.SoundEmitter:PlaySound(murdered.components.health.murdersound)
        end

        local stacksize = 1
        if murdered.components.stackable then
            stacksize = murdered.components.stackable.stacksize
        end

        if murdered.components.lootdropper then
            for i = 1, stacksize do
                local loots = murdered.components.lootdropper:GenerateLoot()
                for k, v in pairs(loots) do
                    local loot = SpawnPrefab(v)
                    act.doer.components.inventory:GiveItem(loot)
                end
            end
        end

        act.doer:PushEvent("killed", {victim = murdered})
        murdered:Remove()

        return true
    end
end

ACTIONS.HEAL.fn = function(act)
    if act.invobject and act.invobject.components.healer then
        local target = act.target or act.doer
    	return act.invobject.components.healer:Heal(target)
    elseif act.invobject and act.invobject.components.maxhealer then
        local target = act.target or act.doer
        return act.invobject.components.maxhealer:Heal(target)
    end
end

ACTIONS.UNLOCK.fn = function(act)
    if act.target.components.lock then
        if act.target.components.lock:IsLocked() then
            act.target.components.lock:Unlock(act.invobject, act.doer)
        --else
            --act.target.components.lock:Lock(act.doer)
        end
        return true
    end
end

ACTIONS.TEACH.fn = function(act)
    if act.invobject and act.invobject.components.teacher then
        local target = act.target or act.doer
        return act.invobject.components.teacher:Teach(target)
    end
end

ACTIONS.TURNON.fn = function(act)
    local tar = act.target or act.invobject
    if tar and tar.components.machine and not tar.components.machine:IsOn() then
        tar.components.machine:TurnOn(tar)
        return true
    end
end

ACTIONS.TURNOFF.fn = function(act)
    local tar = act.target or act.invobject
    if tar and tar.components.machine and tar.components.machine:IsOn() then
            tar.components.machine:TurnOff(tar)
        return true
    end
end

ACTIONS.USEITEM.fn = function(act)
    if act.invobject and act.invobject.components.useableitem then
        if act.invobject.components.useableitem:CanInteract() then
            act.invobject.components.useableitem:StartUsingItem()
        end
    end
end

ACTIONS.TAKEITEM.fn = function(act)
--Use this for taking a specific item as opposed to having an item be generated as it is in Pick/ Harvest
    if act.target and act.target.components.shelf and act.target.components.shelf.cantakeitem then
        act.target.components.shelf:TakeItem(act.doer)
        return true
    end
end

ACTIONS.CASTSPELL.fn = function(act)
    --For use with magical staffs
    local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    if staff and staff.components.spellcaster and staff.components.spellcaster:CanCast(act.doer, act.target, act.pos) then
        staff.components.spellcaster:CastSpell(act.target, act.pos)
        return true
    end
end


ACTIONS.BLINK.fn = function(act)
    if act.invobject and act.invobject.components.blinkstaff then
        return act.invobject.components.blinkstaff:Blink(act.pos, act.doer)
    end
end

ACTIONS.COMBINESTACK.fn = function(act)
    local target = act.target
    local invobj = act.invobject
    if invobj and target and invobj.prefab == target.prefab and target.components.stackable and not target.components.stackable:IsFull() then
        target.components.stackable:Put(invobj)
        return true
    end 
end

ACTIONS.TRAVEL.fn = function(act)
	if act.target and act.target.travel_action_fn then
		act.target.travel_action_fn(act.doer)
		return true
	end
end

ACTIONS.UNPIN.fn = function(act)
    if act.doer ~= act.target and act.target.components.pinnable and act.target.components.pinnable:IsStuck() then
        act.target:PushEvent("unpinned")
        return true
    end
end

--[[ACTIONS.OPEN_SHOP.fn = function(act)
    if act.target.components.shop then
		local trigger = json.encode({shop={title=act.target.components.shop.title,
										   name=act.target.components.shop.name, 
										   id=act.target.entity:GetGUID(),
										   tab=act.target.components.shop.tab,
										   filter=act.doer.components.builder.recipes,
                                           gold=act.doer.profile:GetGold(),
										   }
									})
		TheSim:SendUITrigger(trigger)
		TheSim:SetTimeScale(0)
        return true
    end
end
--]]