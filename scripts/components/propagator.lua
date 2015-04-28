local Propagator = Class(function(self, inst)
    self.inst = inst
    self.flashpoint = 100
    self.currentheat = 0
    self.decayrate = 1

    self.propagaterange = 3
    self.heatoutput = 5
    
    self.damages = false
    self.damagerange = 3

    self.pvp_damagemod = TUNING.PVP_DAMAGE_MOD or 1 -- players shouldn't hurt other players very much, even with fire

    self.acceptsheat = false
    self.spreading = false
    self.delay = false

    self.inst:AddTag("propagator")
end)


function Propagator:SetOnFlashPoint(fn)
    self.onflashpoint = fn
end

function Propagator:Delay(time)
    self.delay = true
    self.inst:DoTaskInTime(time, function() self.delay = false end)
end

function Propagator:StopUpdating()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

function Propagator:StartUpdating()
    if not self.task then
        local dt = .5
        self.task = self.inst:DoPeriodicTask(dt, function() self:OnUpdate(dt) end, dt + math.random()*.67)
    end
end

function Propagator:StartSpreading(source)
    self.source = source
    self.spreading = true
    self:StartUpdating()
end

function Propagator:StopSpreading(reset, heatpct)
    self.source = nil
    self.spreading = false
    if reset then
        self.currentheat = heatpct and (heatpct * self.flashpoint) or 0
        self.acceptsheat = true
    end
end

function Propagator:AddHeat(amount)
    
    if self.delay or self.inst:HasTag("fireimmune") then
        return
    end
    
    if self.currentheat <= 0 then
        self:StartUpdating()        
    end
    
    self.currentheat = self.currentheat + amount

    if self.currentheat > self.flashpoint then
        self.acceptsheat = false
        if self.onflashpoint then
            self.onflashpoint(self.inst)
        end
    end
end

function Propagator:Flash()
    if self.acceptsheat and not self.delay then
        self:AddHeat(self.flashpoint+1)
    end
end

function Propagator:OnUpdate(dt)
    
    if self.currentheat > 0 then
        self.currentheat = self.currentheat - dt*self.decayrate
    end

    if self.spreading then
        
        local pos = Vector3(self.inst.Transform:GetWorldPosition())
        local prop_range = self.propagaterange
        if TheWorld.state.isspring then prop_range = prop_range * TUNING.SPRING_FIRE_RANGE_MOD end
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, prop_range, {"propagator"})
        
        for k,v in pairs(ents) do
            if not v:IsInLimbo() then

                local dsq = distsq(pos, Vector3(v.Transform:GetWorldPosition()))
                local percent_heat = math.max(0.1, 1- (dsq / (self.propagaterange*self.propagaterange)))

			    if v ~= self.inst and v.components.propagator and v.components.propagator.acceptsheat then
                    v.components.propagator:AddHeat(self.heatoutput*percent_heat*dt)
			    end

                if v ~= self.inst and v.components.freezable ~= nil then
                    v.components.freezable:AddColdness(-.25 * self.heatoutput *dt)
                    if v.components.freezable:IsFrozen() and v.components.freezable.coldness <= 0 then
                        --Skip thawing
                        v.components.freezable:Unfreeze()
                    end
                end

                if v ~= self.inst and v:HasTag("frozen") and not (self.inst.components.heater and self.inst.components.heater:IsEndothermic()) then
                    v:PushEvent("firemelt")
                    if not v:HasTag("firemelt") then v:AddTag("firemelt") end
                end
    			
			    if self.damages and v.components.health and v.components.health.vulnerabletoheatdamage then
				    local dsq = distsq(pos, Vector3(v.Transform:GetWorldPosition()))
                    local dmg_range = self.damagerange*self.damagerange
                    if TheWorld.state.isspring then dmg_range = dmg_range * TUNING.SPRING_FIRE_RANGE_MOD end
				    if dsq < dmg_range then
					    --local percent_damage = math.min(.5, 1- (math.min(1, dsq / self.damagerange*self.damagerange)))
                        if self.source and self.source:HasTag("player") then
                            v.components.health:DoFireDamage(self.heatoutput*dt*self.pvp_damagemod)
                        else
					       v.components.health:DoFireDamage(self.heatoutput*dt)
                        end
				    end
			    end
			end
        end
    end
        
    if not self.spreading and not (self.inst.components.heater and self.inst.components.heater:IsEndothermic()) then
        local pos = Vector3(self.inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, self.propagaterange, {"frozen", "firemelt"})
        if #ents > 0 then
            for k,v in pairs(ents) do
                v:PushEvent("stopfiremelt")
                v:RemoveTag("firemelt")
            end
        end
        if self.currentheat <= 0 then
            self:StopUpdating()
        end
    end
    
end

function Propagator:GetDebugString()
    return string.format("range: %.2f output: %.2f flashpoint: %.2f delay: %s -- spreading: %s acceptsheat: %s currentheat: %s", self.propagaterange, self.heatoutput, self.flashpoint, tostring(self.delay), tostring(self.spreading), tostring(self.acceptsheat), tostring(self.currentheat))
end

return Propagator
