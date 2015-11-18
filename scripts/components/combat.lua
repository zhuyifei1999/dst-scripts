local function onattackrange(self, attackrange)
    self.inst.replica.combat:SetAttackRange(attackrange)
end

local function onminattackperiod(self, minattackperiod)
    self.inst.replica.combat:SetMinAttackPeriod(minattackperiod)
end

local function oncanattack(self, canattack)
    self.inst.replica.combat:SetCanAttack(canattack)
end

local function ontarget(self, target)
    self.inst.replica.combat:SetTarget(target)
end

local function onpanicthresh(self, panicthresh)
    self.inst.replica.combat:SetIsPanic(panicthresh ~= nil and self.inst.components.health ~= nil and panicthresh > self.inst.components.health:GetPercent())
end

local Combat = Class(function(self, inst)
    self.inst = inst

    self.nextbattlecrytime = nil
    self.battlecryenabled = true
    self.attackrange = 3
    self.hitrange = 3
    self.areahitrange = nil
    self.areahitdamagepercent = nil
    self.defaultdamage = 0
    self.playerdamagepercent = 1
    self.pvp_damagemod = 1
    self.min_attack_period = 4
    self.onhitfn = nil
    self.onhitotherfn = nil
    self.laststartattacktime = 0
    self.lastwasattackedtime = 0
    self.keeptargetfn = nil
    self.keeptargettimeout = 0
    self.hiteffectsymbol = "marker"
    self.canattack = true
    self.lasttargetGUID = nil
    self.target = nil
    self.panic_thresh = nil
    self.forcefacing = true
    self.bonusdamagefn = nil
    self.playerstunlock = PLAYERSTUNLOCK.NORMAL
end,
nil,
{
    attackrange = onattackrange,
    min_attack_period = onminattackperiod,
    canattack = oncanattack,
    target = ontarget,
    panic_thresh = onpanicthresh,
})

local function SetLastTarget(self, target)
    self.lasttargetGUID = target and target:IsValid() and target.GUID or nil
    self.inst.replica.combat:SetLastTarget(target and target:IsValid() and target or nil)
end

function Combat:SetAttackPeriod(period)
    self.min_attack_period = period
end

function Combat:TargetIs(target)
    return target ~= nil and self.target == target
end

function Combat:InCooldown()
    if self.laststartattacktime then
        local time_since_doattack = GetTime() - self.laststartattacktime
        
        if time_since_doattack < self.min_attack_period then
            return true
        end
    end
	return false
end

function Combat:ResetCooldown()
    self.laststartattacktime = 0
end

function Combat:SetRange(attack, hit)
    self.attackrange = attack
    self.hitrange = hit or self.attackrange
end

function Combat:SetPlayerStunlock(stunlock)
    self.playerstunlock = stunlock
end

function Combat:SetAreaDamage(range, percent)
    self.areahitrange = range
    if self.areahitrange then
        self.areahitdamagepercent = percent or 1
    else
        self.areahitdamagepercent = nil
    end
end

function Combat:BlankOutAttacks(fortime)
	self.canattack = false
	
	if self.blanktask then
		self.blanktask:Cancel()
	end
	self.blanktask = self.inst:DoTaskInTime(fortime, function() self.canattack = true self.blanktask = nil end)
end


function Combat:ShareTarget(target, range, fn, maxnum)
    if maxnum <= 0 then
        return
    end

    --print("Combat:ShareTarget", self.inst, target)

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, SpringCombatMod(range), { "_combat" })

    local num_helpers = 0
    for i, v in ipairs(ents) do
        if v ~= self.inst
            and not (v.components.health ~= nil and
                    v.components.health:IsDead())
            and fn(v)
            and v.components.combat:SuggestTarget(target) then

            --print("    share with", v)
            num_helpers = num_helpers + 1

            if num_helpers >= maxnum then
                return
            end
        end
    end
end

function Combat:SetDefaultDamage(damage)
    self.defaultdamage = damage
end

function Combat:SetOnHit(fn)
    self.onhitfn = fn
end

function Combat:SuggestTarget(target)
    if self.target == nil and target ~= nil then
        --print("Combat:SuggestTarget", self.inst, target)
        self:SetTarget(target)
        return true
    end
end

function Combat:SetKeepTargetFunction(fn)
    self.keeptargetfn = fn
end

function tryretarget(inst)
    inst.components.combat:TryRetarget()
end

function Combat:TryRetarget()
    if self.targetfn ~= nil
        and not (self.inst.components.health ~= nil and
                self.inst.components.health:IsDead())
        and not (self.inst.components.sleeper ~= nil and
                self.inst.components.sleeper:IsInDeepSleep()) then

        local newtarget, forcechange = self.targetfn(self.inst)
        if newtarget ~= nil and newtarget ~= self.target and not newtarget:HasTag("notarget") then

            if forcechange then
                self:SetTarget(newtarget)
            elseif self.target ~= nil and self.target:HasTag("structure") and not newtarget:HasTag("structure") then
                self:SetTarget(newtarget)
            else
                self:SuggestTarget(newtarget)
            end
        end
    end
end

function Combat:SetRetargetFunction(period, fn)
    self.targetfn = fn
    self.retargetperiod = period
    
	if self.retargettask then
		self.retargettask:Cancel()
		self.retargettask = nil
	end
    
    if period and fn then
        self.retargettask = self.inst:DoPeriodicTask(period, tryretarget)
    end
end

function Combat:OnEntitySleep()
	if self.retargettask then
		self.retargettask:Cancel()
		self.retargettask = nil
	end
end

function Combat:OnEntityWake()
	if self.retargettask then
		self.retargettask:Cancel()
		self.retargettask = nil
	end

	if self.retargetperiod then
		self.retargettask = self.inst:DoPeriodicTask(self.retargetperiod, tryretarget)
	end
end

function Combat:OnUpdate(dt)
    if not self.target then
        self.inst:StopUpdatingComponent(self)
        return
    end

    if self.keeptargetfn then
        self.keeptargettimeout = self.keeptargettimeout - dt
        if self.keeptargettimeout < 0 then
			if self.inst:IsAsleep() then
		        self.inst:StopUpdatingComponent(self)
		        return
			end
            self.keeptargettimeout = 1
            if not self.target:IsValid() or 
				self.target:IsInLimbo() or
				not self.keeptargetfn(self.inst, self.target) or not 
                (self.target and self.target.components.combat and self.target.components.combat:CanBeAttacked(self.inst)) then    
                self.inst:PushEvent("losttarget")            
                self:DropTarget()
            end
        end
    end
end

function Combat:IsRecentTarget(target)
	return target and (target == self.target or target.GUID == self.lasttargetGUID)
end

local function TargetDisappeared(self, target)
	self:DropTarget()
end

function Combat:StartTrackingTarget(target)
	if target then
		self.losetargetcallback = function() 
			TargetDisappeared(self, target) 
		end
		self.inst:ListenForEvent("enterlimbo", self.losetargetcallback, target)
		self.inst:ListenForEvent("onremove", self.losetargetcallback, target)
	end
end

function Combat:StopTrackingTarget(target)
	self.inst:RemoveEventCallback("enterlimbo", self.losetargetcallback, target)
	self.inst:RemoveEventCallback("onremove", self.losetargetcallback, target)
end

function Combat:DropTarget(hasnexttarget)
	if self.target then
	    SetLastTarget(self, self.target)
		self:StopTrackingTarget(self.target)
		self.inst:StopUpdatingComponent(self)
		local oldtarget = self.target
		self.target = nil
		if not hasnexttarget then
			self.inst:PushEvent("droppedtarget", {target=oldtarget})
		end
	end
end

function Combat:EngageTarget(target)
	if target then
        local oldtarget = self.target
		self.target = target
		self.inst:PushEvent("newcombattarget", {target=target, oldtarget=oldtarget})
		self:StartTrackingTarget(target)
	    if self.keeptargetfn then
    	    self.inst:StartUpdatingComponent(self)
	    end
        if self.inst.components.follower and self.inst.components.follower.leader == target and self.inst.components.follower.leader.components.leader then
			self.inst.components.follower.leader.components.leader:RemoveFollower(self.inst)
        end
	end
end

function Combat:SetTarget(target)
    local new = target ~= self.target
    if new and (not target or self:IsValidTarget(target) ) and not (target and target.sg and target.sg:HasStateTag("hiding") and target:HasTag("player")) then
		self:DropTarget(target ~= nil)
		self:EngageTarget(target)
    end
end

function Combat:IsValidTarget(target)
    return self.inst.replica.combat:IsValidTarget(target)
end

function Combat:ValidateTarget()
    if self.target then
		if self:IsValidTarget(self.target) then
			return true
		else
			self:DropTarget()
		end
    end
end

function Combat:GetDebugString()
    
    local str = string.format("target:%s, damage:%d", tostring(self.target), self.defaultdamage or 0 )
    if self.target then
        local dist = math.sqrt(self.inst:GetDistanceSqToInst(self.target)) or 0
        local atkrange = math.sqrt(self:CalcAttackRangeSq()) or 0
        str = str .. string.format(" dist/range: %2.2f/%2.2f", dist, atkrange)
    end
    if self.targetfn and self.retargetperiod then
        str = str.. " Retarget set"
    end
	str = str..string.format(" can attack:%s", tostring(self:CanAttack(self.target)))

    str = str..string.format(" can be attacked: %s", tostring(self:CanBeAttacked()))
    
    return str
end

function Combat:GetGiveUpString(target)
    return nil
end

function Combat:GiveUp()
    if self.inst.components.talker then
        local str = self:GetGiveUpString(self.target)
        if str then
            self.inst.components.talker:Say(str)
        end
    end

-- KAJ: TODO: Metrics related. disabled until we know what to do
--    if METRICS_ENABLED and GetPlayer() == self.target then
--        FightStat_GaveUp(self.inst)
--    end
    self.inst:PushEvent("giveuptarget", {target = self.target})
	self:DropTarget()
end

function Combat:GetBattleCryString(target)
    return nil
end

function Combat:BattleCry()

    if self.battlecryenabled and (not self.nextbattlecrytime or GetTime() > self.nextbattlecrytime) then
        self.nextbattlecrytime = GetTime() + (self.battlecryinterval and self.battlecryinterval or 5)+math.random()*3
        if self.inst.components.talker then            
            local cry = self:GetBattleCryString(self.target)
            if cry then
                self.inst.components.talker:Say{Line(cry, 2)}
            end
        elseif self.inst.sg.sg.states.taunt and not self.inst.sg:HasStateTag("busy") then
            self.inst.sg:GoToState("taunt")
        end
    end
end

function Combat:SetHurtSound(sound)
    self.hurtsound = sound
end

function Combat:GetAttacked(attacker, damage, weapon, stimuli)
    self.lastwasattackedtime = GetTime()

    --print ("ATTACKED", self.inst, attacker, damage)
    local blocked = false

    self.lastattacker = attacker

    if self.inst.components.health ~= nil and damage ~= nil then
        if self.inst.components.inventory ~= nil then
            damage = self.inst.components.inventory:ApplyDamage(damage, attacker, weapon)
        end
        if damage > 0 and not self.inst.components.health:IsInvincible() then
            --Bonus damage only applies after unabsorbed damage gets through your armor
            if attacker ~= nil and attacker.components.combat ~= nil and attacker.components.combat.bonusdamagefn ~= nil then
                damage = damage + attacker.components.combat.bonusdamagefn(attacker, self.inst, damage, weapon) or 0
            end
            self.inst.components.health:DoDelta(-damage, nil, attacker ~= nil and attacker.prefab or "NIL", nil, attacker)
            if self.inst.components.health:IsDead() then
                if attacker ~= nil then
                    attacker:PushEvent("killed", { victim = self.inst })
                end
                if self.onkilledbyother ~= nil then
                    self.onkilledbyother(self.inst, attacker)
                end
            end
        else
            blocked = true
        end
    end

    if self.inst.SoundEmitter ~= nil then
        local hitsound = self:GetImpactSound(self.inst, weapon)
        if hitsound ~= nil then
            self.inst.SoundEmitter:PlaySound(hitsound)
        end
        if self.hurtsound ~= nil then
            self.inst.SoundEmitter:PlaySound(self.hurtsound)
        end
    end

    if not blocked then
        self.inst:PushEvent("attacked", { attacker = attacker, damage = damage, weapon = weapon, stimuli = stimuli })

        if self.onhitfn ~= nil then
            self.onhitfn(self.inst, attacker, damage)
        end

        if attacker ~= nil then
            attacker:PushEvent("onhitother", { target = self.inst, damage = damage, stimuli = stimuli })
            if attacker.components.combat ~= nil and attacker.components.combat.onhitotherfn ~= nil then
                attacker.components.combat.onhitotherfn(attacker, self.inst, damage, stimuli)
            end
        end
    else
        self.inst:PushEvent("blocked", { attacker = attacker })
    end

    return not blocked
end

function Combat:GetImpactSound(target, weapon)
    if target == nil then
        return
    end

    --V2C: Considered creating a mapping for tags to strings, but we cannot really
    --     rely on these tags being properly mutually exclusive, so it's better to
    --     leave it like this as if explicitly ordered by priority.

    local hitsound = "dontstarve/impacts/impact_"
    local weaponmod = weapon ~= nil and weapon:HasTag("sharp") and "sharp" or "dull"
    local tgtinv = target.components.inventory
    if tgtinv ~= nil and tgtinv:IsWearingArmor() then
        return
            hitsound..(
                (tgtinv:ArmorHasTag("grass") and "straw_armour_") or
                (tgtinv:ArmorHasTag("forcefield") and "forcefield_armour_") or
                (tgtinv:ArmorHasTag("sanity") and "sanity_armour_") or
                (tgtinv:ArmorHasTag("sanity") and "sanity_armour_") or
                (tgtinv:ArmorHasTag("marble") and "marble_armour_") or
                (tgtinv:ArmorHasTag("shell") and "shell_armour_") or
                (tgtinv:ArmorHasTag("fur") and "fur_armour_") or
                (tgtinv:ArmorHasTag("metal") and "metal_armour_") or
                "wood_armour_"
            )..weaponmod

    elseif target:HasTag("wall") then
        return
            hitsound..(
                (target:HasTag("grass") and "straw_wall_") or
                (target:HasTag("stone") and "stone_wall_") or
                (target:HasTag("marble") and "marble_wall_") or
                "wood_wall_"
            )..weaponmod

    elseif target:HasTag("object") then
        return
            hitsound..(
                (target:HasTag("clay") and "clay_object_") or
                (target:HasTag("stone") and "stone_object_") or
                "object_"
            )..weaponmod

    else
        local tgttype =
            ((target:HasTag("hive") or target:HasTag("eyeturret") or target:HasTag("houndmound")) and "hive_") or
            (target:HasTag("ghost") and "ghost_") or
            ((target:HasTag("insect") or target:HasTag("spider")) and "insect_") or
            ((target:HasTag("chess") or target:HasTag("mech")) and "mech_") or
            (target:HasTag("mound") and "mound_") or
            (target:HasTag("shadow") and "shadow_") or
            (target:HasTag("tree") and "tree_") or
            (target:HasTag("veggie") and "vegetable_") or
            (target:HasTag("shell") and "shell_") or
            (target:HasTag("rocky") and "stone_") or
            nil
        return
            hitsound..(
                tgttype or "flesh_"
            )..(
                ((target:HasTag("smallcreature") or target:HasTag("small")) and "sml_") or
                ((target:HasTag("largecreature") or target:HasTag("epic") or target:HasTag("large")) and "lrg_") or
                (tgttype == nil and target:GetIsWet() and "wet_") or
                "med_"
            )..weaponmod
    end
end

function Combat:StartAttack()
    if self.target and self.forcefacing then
        self.inst:ForceFacePoint(self.target:GetPosition())
    end
    self.laststartattacktime = GetTime()
end

function Combat:CancelAttack()
    self.laststartattacktime = 0
end

function Combat:CanTarget(target)
    return self.inst.replica.combat:CanTarget(target)
end

function Combat:HasTarget()
    return self.target ~= nil
end

function Combat:CanAttack(target)
    if not self.canattack then 
		return false 
	end

    if self.laststartattacktime ~= nil and
        GetTime() - self.laststartattacktime < self.min_attack_period then
        return false
    end

	if not self:IsValidTarget(target) or
        (self.inst.sg ~= nil and (not self.inst.sg:HasStateTag("hit") and self.inst.sg:HasStateTag("busy"))) then
		return false
	end

    -- V2C: this is 3D distsq
    if distsq(target:GetPosition(), self.inst:GetPosition()) > self:CalcAttackRangeSq(target) then
        return false
    end

    -- gjans: Some specific logic so the birchnutter doesn't attack it's spawn with it's AOE
    -- This could possibly be made more generic so that "things" don't attack other things in their "group" or something
    if self.inst:HasTag("birchnutroot")
        and (target:HasTag("birchnutroot") or
            target:HasTag("birchnut") or
            target:HasTag("birchnutdrage")) then
        return false
    end

    return true
end


function Combat:TryAttack(target)
    
    local target = target or self.target 
    
    local is_attacking = self.inst.sg:HasStateTag("attack")
    if is_attacking then
        return true
    end
    
    if self:CanAttack(target) then
        self.inst:PushEvent("doattack", {target = target})
        return true
    end
    
    return false
end

function Combat:ForceAttack()
    if self.target and self:TryAttack() then
        return true
    else
        self.inst:PushEvent("doattack")
    end
end

function Combat:GetWeapon()
    if self.inst.components.inventory ~= nil then
        local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        return item ~= nil and item.components.weapon ~= nil and item or nil
    end
end

function Combat:GetLastAttackedTime()
    return self.lastwasattackedtime
end

function Combat:CalcDamage(target, weapon, multiplier)
    if target:HasTag("alwaysblock") then
        return 0
    end
    multiplier = (multiplier or 1) * (self.damagemultiplier or 1)
    local bonus = self.damagebonus or 0
    if weapon ~= nil then
        local weapondamage = weapon.components.weapon.damage or 0

        return target ~= nil
            and target:HasTag("player")
            and self.inst:HasTag("player")
            and weapondamage * multiplier * self.pvp_damagemod + bonus
            or weapondamage * multiplier + bonus
    end

    return (target == nil or not target:HasTag("player"))
        and self.defaultdamage * multiplier + bonus
        or (self.inst:HasTag("player") and
            self.defaultdamage * self.playerdamagepercent * self.pvp_damagemod * multiplier + bonus or
            self.defaultdamage * self.playerdamagepercent * multiplier + bonus)
end

function Combat:GetAttackRange()
    local weapon = self:GetWeapon()
    return (weapon == nil and self.attackrange)
        or (weapon.components.weapon.attackrange ~= nil and self.attackrange + weapon.components.weapon.attackrange)
        or self.attackrange
end

function Combat:CalcAttackRangeSq(target)
    target = target or self.target
    local range = self:GetAttackRange() + (target.Physics ~= nil and target.Physics:GetRadius() or 0)
    return range * range
end

function Combat:GetHitRange()
    local weapon = self:GetWeapon()
    return (weapon == nil and self.hitrange)
        or (weapon.components.weapon.hitrange ~= nil and self.hitrange + weapon.components.weapon.hitrange)
        or self.hitrange
end

function Combat:CalcHitRangeSq(target)
    target = target or self.target
    local range = self:GetHitRange() + (target.Physics ~= nil and target.Physics:GetRadius() or 0)
    return range * range
end

function Combat:CanHitTarget(target, weapon)
    if self.inst ~= nil and
        self.inst:IsValid() and
        target ~= nil and
        target:IsValid() and
        not target:IsInLimbo() then

        local specialcase_target =
            weapon ~= nil
            and ((weapon:HasTag("extinguisher") and target.components.burnable ~= nil and (target.components.burnable:IsSmoldering() or target.components.burnable:IsBurning())) or
                (weapon:HasTag("rangedlighter") and target:HasTag("canlight")))

        if specialcase_target or 
            (target.components.combat ~= nil and target.components.combat:CanBeAttacked(self.inst)) then

            local targetpos = target:GetPosition()
            -- V2C: this is 3D distsq
            if distsq(targetpos, self.inst:GetPosition()) <= self:CalcHitRangeSq(target) then
                return true
            elseif weapon ~= nil and weapon.components.projectile ~= nil then
                local range = weapon.components.projectile.hitdist + (target.Physics ~= nil and target.Physics:GetRadius() or 0)
                -- V2C: this is 3D distsq
                return distsq(targetpos, weapon:GetPosition()) <= range * range
            end
        end
    end
end

function Combat:DoAttack(target_override, weapon, projectile, stimuli, instancemult)
    local targ = target_override or self.target
    local weapon = weapon or self:GetWeapon()

    if not self:CanHitTarget(targ, weapon) then
        self.inst:PushEvent("onmissother", { target = targ, weapon = weapon })
        if self.areahitrange ~= nil then
            self:DoAreaAttack(projectile or self.inst, self.areahitrange, weapon, nil, stimuli)
        end
        return
    end

    self.inst:PushEvent("onattackother", { target = targ, weapon = weapon, projectile = projectile, stimuli = stimuli })

    if weapon ~= nil and projectile == nil then
        if weapon.components.projectile ~= nil then
            local projectile = self.inst.components.inventory:DropItem(weapon, false)
            if projectile ~= nil then
                projectile.components.projectile:Throw(self.inst, targ)
            end
            return

        elseif weapon.components.complexprojectile ~= nil then
            local projectile = self.inst.components.inventory:DropItem(weapon, false)
            if projectile ~= nil then
                projectile.components.complexprojectile:Launch(targ:GetPosition(), self.inst)
            end
            return

        elseif weapon.components.weapon:CanRangedAttack() then
            weapon.components.weapon:LaunchProjectile(self.inst, targ)
            return
        end
    end

    if targ.components.combat ~= nil then
        local mult =
            (stimuli == "electric" or
            (weapon ~= nil and weapon.components.weapon ~= nil and weapon.components.weapon.stimuli == "electric"))
            and not (targ:HasTag("electricdamageimmune") or
                    (targ.components.inventory ~= nil and targ.components.inventory:IsInsulated()))
            and TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * (targ.components.moisture ~= nil and targ.components.moisture:GetMoisturePercent() or (targ:GetIsWet() and 1 or 0))
            or 1
        targ.components.combat:GetAttacked(self.inst, self:CalcDamage(targ, weapon, mult) * (instancemult or 1), weapon, stimuli)
    end

    if weapon ~= nil then
        weapon.components.weapon:OnAttack(self.inst, targ, projectile)
    end
    if self.areahitrange ~= nil then
        self:DoAreaAttack(targ, self.areahitrange, weapon, nil, stimuli)
    end
    self.lastdoattacktime = GetTime()
end

function Combat:DoAreaAttack(target, range, weapon, validfn, stimuli)
    local hitcount = 0
    local x, y, z = target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, range, { "_combat" })
    for i, ent in ipairs(ents) do
        if ent ~= target and
            ent ~= self.inst and
            self:IsValidTarget(ent) and
            (validfn == nil or validfn(ent)) then
            self.inst:PushEvent("onareaattackother", { target = target, weapon = weapon, stimuli = stimuli })
            ent.components.combat:GetAttacked(self.inst, self:CalcDamage(ent, weapon, self.areahitdamagepercent), weapon, stimuli)
            hitcount = hitcount + 1
        end
    end
    return hitcount
end

function Combat:IsAlly(guy)
    return self.inst.replica.combat:IsAlly(guy)
end

function Combat:CanBeAttacked(attacker)
    return self.inst.replica.combat:CanBeAttacked(attacker)
end

function Combat:OnSave()
    if self.target ~= nil then
        return { target = self.target.GUID }, { self.target.GUID }
    end
end

function Combat:LoadPostPass(newents, data)
    if data.target ~= nil then
        local target = newents[data.target]
        if target ~= nil then
            self:SetTarget(target.entity)
        end
    end
end

function Combat:OnRemoveFromEntity()
    if self.target ~= nil then
        self:StopTrackingTarget(self.target)
    end
end

return Combat
