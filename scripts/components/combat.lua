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
    self.keeptargetfn = nil
    self.keeptargettimeout = 0
    self.hiteffectsymbol = "marker"
    self.canattack = true
    self.lasttargetGUID = nil
    self.target = nil
    self.panic_thresh = nil
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
    local ents = TheSim:FindEntities(x, y, z, range, { "_combat" })

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

        local newtarget = self.targetfn(self.inst)
        if newtarget ~= nil and newtarget ~= self.target and not newtarget:HasTag("notarget") then
            if self.target ~= nil and self.target:HasTag("structure") and not newtarget:HasTag("structure") then
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

function Combat:DropTarget()
	if self.target then
	    SetLastTarget(self, self.target)
		self:StopTrackingTarget(self.target)
		self.inst:StopUpdatingComponent(self)
		self.target = nil
	end
end

function Combat:EngageTarget(target)
	if target then
		self.target = target
		self.inst:PushEvent("newcombattarget", {target=target})
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
		self:DropTarget()
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

    if not self.nextbattlecrytime or GetTime() > self.nextbattlecrytime then
        self.nextbattlecrytime = GetTime() + 5+math.random()*3
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

function Combat:GetAttacked(attacker, damage, weapon)
    --print ("ATTACKED", self.inst, attacker, damage)
    local blocked = false
-- KAJ: TODO: Metrics related. disabled until we know what to do
--    local player = GetPlayer()
    local init_damage = damage

    self.lastattacker = attacker
    if self.inst.components.health and damage then   
        if self.inst.components.inventory then
            damage = self.inst.components.inventory:ApplyDamage(damage, attacker)
        end
-- KAJ: TODO: Metrics related. disabled until we know what to do
--        if METRICS_ENABLED and GetPlayer() == self.inst then
--            local prefab = (attacker and (attacker.prefab or attacker.inst.prefab)) or "NIL"
--            ProfileStatsAdd("hitsby_"..prefab,math.floor(damage))
--            FightStat_AttackedBy(attacker,damage,init_damage-damage)
--        end
        if damage > 0 and self.inst.components.health:IsInvincible() == false then
            self.inst.components.health:DoDelta(-damage, nil, attacker and attacker.prefab or "NIL", nil, attacker)
            if self.inst.components.health:GetPercent() <= 0 then
				if attacker then
					attacker:PushEvent("killed", {victim = self.inst})
				end

-- KAJ: TODO: Metrics related. disabled until we know what to do
--                if METRICS_ENABLED and attacker and attacker == GetPlayer() then
--                    ProfileStatsAdd("kill_"..self.inst.prefab)
--                    FightStat_AddKill(self.inst,damage,weapon)
--                end
--                if METRICS_ENABLED and attacker and attacker.components.follower and attacker.components.follower.leader == GetPlayer() then
--                    ProfileStatsAdd("kill_by_minion"..self.inst.prefab)
--                    FightStat_AddKillByFollower(self.inst,damage,weapon)
--                end
--                if METRICS_ENABLED and attacker and attacker.components.mine then
--                    ProfileStatsAdd("kill_by_trap_"..self.inst.prefab)
--                    FightStat_AddKillByMine(self.inst,damage)
--                end
                
                if self.onkilledbyother then
					self.onkilledbyother(self.inst, attacker)
                end
            end
        else
            blocked = true
        end
    end
    

    if self.inst.SoundEmitter then
        local hitsound = self:GetImpactSound(self.inst, weapon)
        if hitsound then
            self.inst.SoundEmitter:PlaySound(hitsound)
            --print (hitsound)
        end

        if self.hurtsound then
            self.inst.SoundEmitter:PlaySound(self.hurtsound)
        end

    end
    
    if not blocked then
        self.inst:PushEvent("attacked", {attacker = attacker, damage = damage, weapon = weapon})
    
        if self.onhitfn then
            self.onhitfn(self.inst, attacker, damage)
        end
        
        if attacker then
            attacker:PushEvent("onhitother", {target = self.inst, damage = damage})
            if attacker.components.combat and attacker.components.combat.onhitotherfn then
                attacker.components.combat.onhitotherfn(attacker, self.inst, damage)
            end
        end
    else
        self.inst:PushEvent("blocked", {attacker = attacker})
    end
    
    return not blocked
end

function Combat:GetImpactSound(target, weapon)
    if not target then
        return
    end
    local hitsound = "dontstarve/impacts/impact_"
    local specialtype = nil
    if target.components.inventory and target.components.inventory:IsWearingArmor() then
        if target.components.inventory:ArmorHasTag("grass") then
            hitsound = hitsound.."straw_"
        elseif target.components.inventory:ArmorHasTag("forcefield") then
            hitsound = hitsound.."forcefield_"        
        elseif target.components.inventory:ArmorHasTag("sanity") then
            hitsound = hitsound.."sanity_"
        elseif target.components.inventory:ArmorHasTag("sanity") then
            hitsound = hitsound.."sanity_"
        elseif target.components.inventory:ArmorHasTag("marble") then
            hitsound = hitsound.."marble_"
        elseif target.components.inventory:ArmorHasTag("shell") then
            hitsound = hitsound.."shell_"                
        elseif target.components.inventory:ArmorHasTag("fur") then
            hitsound = hitsound.."fur_"
        elseif target.components.inventory:ArmorHasTag("metal") then
            hitsound = hitsound.."metal_"
        else
            hitsound = hitsound.."wood_"
        end
        specialtype = "armour"
    elseif target:HasTag("wall") then
        if target:HasTag("grass") then
            hitsound = hitsound.."straw_"
        elseif target:HasTag("stone") then
            hitsound = hitsound.."stone_"
        elseif target:HasTag("marble") then
            hitsound = hitsound.."marble_"
        else
            hitsound = hitsound.."wood_"
        end
        specialtype = "wall"   
    elseif target:HasTag("object") then
        if target:HasTag("clay") then
            hitsound = hitsound.."clay_"
        elseif target:HasTag("stone") then
            hitsound = hitsound.."stone_"
        end
        specialtype = "object"
    elseif target:HasTag("hive") or target:HasTag("eyeturret") then
        hitsound = hitsound.."hive_"
    elseif target:HasTag("ghost") then
        hitsound = hitsound.."ghost_"
    elseif target:HasTag("insect") or target:HasTag("spider") then
        hitsound = hitsound.."insect_"
    elseif target:HasTag("chess") or target:HasTag("mech") then
        hitsound = hitsound.."mech_"
    elseif target:HasTag("mound") then
        hitsound = hitsound.."mound_"
    elseif target:HasTag("shadow") then
        hitsound = hitsound.."shadow_"
    elseif target:HasTag("tree") then
        hitsound = hitsound.."tree_"
    elseif target:HasTag("veggie") then
        hitsound = hitsound.."vegetable_"
    elseif target:HasTag("shell") then
        hitsound = hitsound.."shell_"
    elseif target:HasTag("rocky") then
        hitsound = hitsound.."stone_"
    else
        hitsound = hitsound.."flesh_"
    end
 




    if specialtype then
        hitsound = hitsound..specialtype.."_"
    elseif target:HasTag("smallcreature") or target:HasTag("small") then
        hitsound = hitsound.."sml_"
    elseif target:HasTag("largecreature") or target:HasTag("epic") or target:HasTag("large") then
        hitsound = hitsound.."lrg_"
    elseif target:HasTag("wet") then
        hitsound = hitsound.."wet_"
    else
        hitsound = hitsound.."med_"
    end
    
    if weapon and weapon:HasTag("sharp") then
        hitsound = hitsound.."sharp"
    else
        hitsound = hitsound.."dull"
    end
    return hitsound
end

function Combat:StartAttack()
    self.laststartattacktime = GetTime()
end

function Combat:CancelAttack()
    self.laststartattacktime = 0
end

function Combat:CanTarget(target)
    return self.inst.replica.combat:CanTarget(target)
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
    
	return distsq(target:GetPosition(), self.inst:GetPosition()) <= self:CalcAttackRangeSq(target)
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
    if self.inst.components.inventory then
        local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item and item.components.weapon then
            return item
        end
    end
end

function Combat:CalcDamage(target, weapon, multiplier)

    if target:HasTag("alwaysblock") then
        return 0
    end
	local multiplier = multiplier or self.damagemultiplier or 1
	local bonus = self.damagebonus or 0
    if weapon then
        local weapondamage = 0
        if weapon.components.weapon.variedmodefn then
            local d = weapon.components.weapon.variedmodefn(weapon)
            weapondamage = d.damage        
        else
            weapondamage = weapon.components.weapon.damage
        end
        if not weapondamage then weapondamage = 0 end

        if target and target:HasTag("player") and self.inst:HasTag("player") then
            return weapondamage*multiplier*self.pvp_damagemod + bonus
        else
            return weapondamage*multiplier + bonus
        end
    end
    
    if target and target:HasTag("player") then
        if self.inst:HasTag("player") then
            return self.defaultdamage * self.playerdamagepercent * self.pvp_damagemod * multiplier + bonus
        else
		    return self.defaultdamage * self.playerdamagepercent * multiplier + bonus
        end
    end

    
    return self.defaultdamage * multiplier + bonus
end

function Combat:GetAttackRange()
    local range = self.attackrange
    local weapon = self:GetWeapon()

    if weapon and weapon.components.weapon.variedmodefn then
        local weaponrange = weapon.components.weapon.variedmodefn(weapon)
        range = range + weaponrange.attackrange
    elseif weapon and weapon.components.weapon.attackrange then
        range = range + weapon.components.weapon.attackrange
    end

    return range
end

function Combat:CalcAttackRangeSq(target)
    target = target or self.target
    local range = self:GetAttackRange() + (target.Physics and target.Physics:GetRadius() or 0)
    return range*range
end

function Combat:GetHitRange()
    local range = self.hitrange
    local weapon = self:GetWeapon()
    if weapon and weapon.components.weapon.variedmodefn then
        local weaponrange = weapon.components.weapon.variedmodefn(weapon)
        range = range + weaponrange.hitrange
    elseif weapon and weapon.components.weapon.hitrange then
        range = range + weapon.components.weapon.hitrange
    end
    --print("GetHitRange", self.inst, self.hitrange, range)
    return range
end

function Combat:CalcHitRangeSq(target)
    target = target or self.target
    local range = self:GetHitRange() + (target.Physics and target.Physics:GetRadius() or 0)
    return range*range
end

function Combat:CanHitTarget(target, weapon)
    if self.inst ~= nil and
        self.inst:IsValid() and
        target ~= nil and
        target:IsValid() and
        not target:IsInLimbo() and
        target.components.combat ~= nil and
        target.components.combat:CanBeAttacked(self.inst) then

        if self.inst:GetDistanceSqToInst(target) <= self:CalcHitRangeSq(target) then
            return true
        end

        if weapon ~= nil and weapon.components.projectile ~= nil then
            local range = weapon.components.projectile.hitdist + (target.Physics ~= nil and target.Physics:GetRadius() or 0)
            if weapon:GetDistanceSqToInst(target) < range * range then
                return true
            end
        end
    end
end

function Combat:CanAreaHitTarget(targ)
    if self:IsValidTarget(targ) then
        return true
    end
end

function Combat:DoAttack(target_override, weapon, projectile)
    
    local targ = target_override or self.target
    local weapon = weapon or self:GetWeapon()
    
    if self:CanHitTarget(targ, weapon) then
        self.inst:PushEvent("onattackother", {target = targ, weapon = weapon, projectile = projectile})
        if weapon and weapon.components.projectile and not projectile then
            local projectile = self.inst.components.inventory:DropItem(weapon, false)
            if projectile then
                projectile.components.projectile:Throw(self.inst, targ)
            end
        elseif weapon and weapon.components.weapon:CanRangedAttack() and not projectile then
            weapon.components.weapon:LaunchProjectile(self.inst, targ)
        else
            local damage = self:CalcDamage(targ, weapon)
            targ.components.combat:GetAttacked(self.inst, damage, weapon)

-- KAJ: TODO: Metrics related. disabled until we know what to do
--            if METRICS_ENABLED and self.inst:HasTag( "player" ) then
--                ProfileStatsAdd("hitson_"..targ.prefab,math.floor(damage))
--                FightStat_Attack(targ,weapon,projectile,damage)
--            end
--            if METRICS_ENABLED and self.inst.components.follower
--					and self.inst.components.follower.leader == GetPlayer() then
--                FightStat_AttackByFollower(targ,weapon,projectile,damage)
--            end
            
            if weapon then
                weapon.components.weapon:OnAttack(self.inst, targ, projectile)
            end
            if self.areahitrange then
                self:DoAreaAttack(targ, self.areahitrange, weapon)
            end
            self.lastdoattacktime = GetTime()
        end
    else
        self.inst:PushEvent("onmissother", {target = targ, weapon = weapon})
        if self.areahitrange then
            local epicentre = projectile or self.inst
            self:DoAreaAttack(epicentre, self.areahitrange, weapon)
        end
    end

end

function Combat:DoAreaAttack(target, range, weapon, validfn)
    local hitcount = 0
    local x, y, z = target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, range, { "_combat" })
    for i, ent in ipairs(ents) do
        if ent ~= target and
            ent ~= self.inst and
            self:CanAreaHitTarget(ent) and
            (validfn == nil or validfn(ent)) then
            self.inst:PushEvent("onareaattackother", { target = target, weapon = weapon })
            ent.components.combat:GetAttacked(self.inst, self:CalcDamage(ent, weapon, self.areahitdamagepercent), weapon)
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

return Combat