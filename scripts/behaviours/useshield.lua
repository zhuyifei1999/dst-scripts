UseShield = Class(BehaviourNode, function(self, inst, damageforshield, shieldtime, hidefromprojectiles, hidewhenscared)
    BehaviourNode._ctor(self, "UseShield")
    self.inst = inst
    self.damageforshield = damageforshield or 100
    self.hidefromprojectiles = hidefromprojectiles or false
    self.scareendtime = 0
    self.damagetaken = 0
    self.timelastattacked = 1
    self.shieldtime = shieldtime or 2
    self.projectileincoming = false

    if hidewhenscared then
        self.inst:ListenForEvent("epicscare", function(inst, data)
            self.scareendtime = math.max(self.scareendtime, data.duration + GetTime() + math.random())
        end)
    end
    self.inst:ListenForEvent("attacked", function(inst, data) self:OnAttacked(data.attacker, data.damage) end)
    self.inst:ListenForEvent("hostileprojectile", function() self:OnAttacked(nil, 0, true) end)
    self.inst:ListenForEvent("firedamage", function() self:OnAttacked() end)
    self.inst:ListenForEvent("startfiredamage", function() self:OnAttacked() end)
end)

function UseShield:TimeToEmerge()
    local t = GetTime()
    return t - self.timelastattacked > self.shieldtime
        and t >= self.scareendtime
end

function UseShield:ShouldShield()
    return not self.inst.components.health:IsDead()
        and (self.damagetaken > self.damageforshield or
            self.inst.components.health.takingfiredamage or
            self.projectileincoming or
            GetTime() < self.scareendtime)
end

function UseShield:OnAttacked(attacker, damage, projectile)
    if not self.inst.sg:HasStateTag("frozen") then
        self.timelastattacked = GetTime()

        if self.inst.sg.currentstate.name == "shield" and not projectile then
            self.inst.AnimState:PlayAnimation("hit_shield")
            self.inst.AnimState:PushAnimation("hide_loop")
            return
        end

        if damage then
            self.damagetaken = self.damagetaken + damage
        end

        if projectile and self.hidefromprojectiles then
            self.projectileincoming = true
            return
        end
    end
end

function UseShield:Visit()
    local combat = self.inst.components.combat
    local statename = self.inst.sg.currentstate.name

    if self.status == READY  then
        if self:ShouldShield() or self.inst.sg:HasStateTag("shield") then
            self.damagetaken = 0
            self.projectileincoming = false
            self.inst:PushEvent("entershield")
            --self.inst.sg:GoToState("shield")
            self.status = RUNNING
        else
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
        if not self:TimeToEmerge() or self.inst.components.health.takingfiredamage then 
            self.status = RUNNING
        else
            self.inst:PushEvent("exitshield")
            --self.inst.sg:GoToState("shield_end")
            self.status = SUCCESS
        end
    end
end
