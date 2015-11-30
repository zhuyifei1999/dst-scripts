local Combat = Class(function(self, inst)
    self.inst = inst

    self._target = net_entity(inst.GUID, "combat._target")
    self._ispanic = net_bool(inst.GUID, "combat._ispanic")
    self._attackrange = net_float(inst.GUID, "combat._attackrange")
    self._laststartattacktime = nil

    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)

--------------------------------------------------------------------------

function Combat:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Combat.OnRemoveEntity = Combat.OnRemoveFromEntity

function Combat:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
    self._laststartattacktime = 0
end

function Combat:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
    self._laststartattacktime = nil
end

--------------------------------------------------------------------------

function Combat:SetTarget(target)
    self._target:set(target)
end

function Combat:GetTarget()
    return self._target:value()
end

function Combat:SetLastTarget(target)
    if self.classified ~= nil then
        self.classified.lastcombattarget:set(target)
    end
end

function Combat:IsRecentTarget(target)
    if self.inst.components.combat ~= nil then
        return self.inst.components.combat:IsRecentTarget(target)
    elseif target == nil then
        return false
    elseif self.classified ~= nil and target == self.classified.lastcombattarget:value() then
        return true
    else
        return target == self._target:value()
    end
end

function Combat:SetIsPanic(ispanic)
    self._ispanic:set(ispanic)
end

function Combat:SetAttackRange(attackrange)
    self._attackrange:set(attackrange)
end

function Combat:GetAttackRangeWithWeapon()
    if self.inst.components.combat ~= nil then
        return self.inst.components.combat:GetAttackRange()
    end
    if self.inst.replica.inventory ~= nil then
        local item = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item ~= nil and item.replica.inventoryitem ~= nil then
            return self._attackrange:value() + item.replica.inventoryitem:AttackRange()
        end
    end
    return self._attackrange:value()
end

function Combat:GetWeapon()
    if self.inst.replica.inventory ~= nil then
        local item = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        return item ~= nil and item:HasTag("weapon") and item or nil
    end
end

function Combat:SetMinAttackPeriod(minattackperiod)
    if self.classified ~= nil then
        self.classified.minattackperiod:set(minattackperiod)
    end
end

function Combat:MinAttackPeriod()
    if self.inst.components.combat ~= nil then
        return self.inst.components.combat.min_attack_period
    elseif self.classified ~= nil then
        return self.classified.minattackperiod:value()
    else
        return 0
    end
end

function Combat:SetCanAttack(canattack)
    if self.classified ~= nil then
        self.classified.canattack:set(canattack)
    end
end

function Combat:StartAttack()
    if self.inst.components.combat ~= nil then
        self.inst.components.combat:StartAttack()
    elseif self.classified ~= nil then
        self._laststartattacktime = GetTime()
    end
end

function Combat:CancelAttack()
    if self.inst.components.combat ~= nil then
        self.inst.components.combat:CancelAttack()
    elseif self.classified ~= nil then
        self._laststartattacktime = 0
    end
end

function Combat:CanAttack(target)
    if self.inst.components.combat ~= nil then
        return self.inst.components.combat:CanAttack(target)
    elseif self.classified ~= nil then
        if not self.classified.canattack:value() then
            return false
        end

        if self._laststartattacktime ~= nil and
            GetTime() - self._laststartattacktime < self.classified.minattackperiod:value() then
            return false
        end

        if not self:IsValidTarget(target) or
            self.inst:HasTag("busy") or
            (self.inst.sg ~= nil and self.inst.sg:HasStateTag("busy")) then
            return false
        end

        local range = target.Physics ~= nil and target.Physics:GetRadius() + self:GetAttackRangeWithWeapon() or self:GetAttackRangeWithWeapon()
        local error_threshold = .5
        --account for position error due to prediction
        range = math.max(range - error_threshold, 0)

        -- V2C: this is 3D distsq
        if distsq(target:GetPosition(), self.inst:GetPosition()) > range * range then
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
    else
        return false
    end
end

function Combat:CanHitTarget(target)
    if self.inst.components.combat ~= nil then
        return self.inst.components.combat:CanHitTarget(target)
    elseif self.classified ~= nil then
        if target ~= nil and
            target:IsValid() and
            not target:HasTag("INLIMBO") then

            local weapon = self:GetWeapon()
            local specialcase_target =
                weapon ~= nil
                and ((weapon:HasTag("extinguisher") and (target:HasTag("smolder") or target:HasTag("fire"))) or
                    (weapon:HasTag("rangedlighter") and target:HasTag("canlight")))

            if specialcase_target or
                (target.replica.combat ~= nil and target.replica.combat:CanBeAttacked(self.inst)) then

                local range = target.Physics ~= nil and target.Physics:GetRadius() + self:GetAttackRangeWithWeapon() or self:GetAttackRangeWithWeapon()
                local error_threshold = .5
                --account for position error due to prediction
                range = math.max(range - error_threshold, 0)

                -- V2C: this is 3D distsq
                return distsq(target:GetPosition(), self.inst:GetPosition()) <= range * range
            end
        end
    else
        return false
    end
end

function Combat:IsValidTarget(target)
    if target == nil or
        target == self.inst or
        not (target.entity:IsValid() and target.entity:IsVisible()) then
        return false
    end

    local weapon = self:GetWeapon()
    if weapon ~= nil then
        -- Light fire with ranged lighter
        if weapon:HasTag("rangedlighter")
            and target:HasTag("canlight")
            and not (target:HasTag("fire") or target:HasTag("burnt")) then
            return true

        -- Extinguish smoldering fire
        elseif weapon:HasTag("extinguisher")
            and (target:HasTag("smolder") or target:HasTag("fire")) then
            return true
        end
    end

    return
        target.replica.combat ~= nil and
        target.replica.health ~= nil and
        not target.replica.health:IsDead() and
        not (target:HasTag("shadow") and self.inst.replica.sanity == nil) and
        not (target:HasTag("playerghost") and (self.inst.replica.sanity == nil or self.inst.replica.sanity:IsSane())) and
        -- gjans: Some specific logic so the birchnutter doesn't attack it's spawn with it's AOE
        -- This could possibly be made more generic so that "things" don't attack other things in their "group" or something
        (not self.inst:HasTag("birchnutroot") or not (target:HasTag("birchnutroot") or target:HasTag("birchnut") or target:HasTag("birchnutdrake"))) and 
        (TheNet:GetPVPEnabled() or not (self.inst:HasTag("player") and target:HasTag("player"))) and
        target:GetPosition().y <= self._attackrange:value() 
end

function Combat:CanTarget(target)
    return self:IsValidTarget(target)
        and not (self._ispanic:value()
                or target:HasTag("INLIMBO")
                or target:HasTag("invisible")
                or target:HasTag("debugnoattack"))
        and (target.replica.combat == nil
            or target.replica.combat:CanBeAttacked(self.inst))
end

function Combat:IsAlly(guy)
    return guy == self.inst or
        (self.inst.replica.follower ~= nil and guy == self.inst.replica.follower:GetLeader()) or
        (guy.replica.follower ~= nil and self.inst == guy.replica.follower:GetLeader()) or
        (self.inst:HasTag("player") and guy:HasTag("companion"))
end

function Combat:CanBeAttacked(attacker)
    if self.inst:HasTag("playerghost") or
        self.inst:HasTag("noattack") or
        self.inst:HasTag("flight") or
        self.inst:HasTag("invisible") then
        --Can't be attacked by anyone
        return false
    elseif attacker ~= nil then
        --Attacker checks
        if self.inst:HasTag("birchnutdrake")
            and (attacker:HasTag("birchnutdrake") or
                attacker:HasTag("birchnutroot") or
                attacker:HasTag("birchnut")) then
            --Birchnut check
            return false
        elseif attacker ~= self.inst and
            not TheNet:GetPVPEnabled() and
            attacker:HasTag("player") and
            self.inst:HasTag("player") then
            --PVP check
            return false
        elseif attacker.replica.sanity ~= nil and
            attacker.replica.sanity:IsCrazy() then
            --Insane attacker can pretty much attack anything
            return true
        end
    end

    if self.inst:HasTag("shadowcreature") and self._target:value() == nil then
        --Not insane attacker cannot attack shadow creatures
        --(unless shadow creature has a target)
        return false
    end

    --Passed all checks, can be attacked by anyone
    return true
end

return Combat
