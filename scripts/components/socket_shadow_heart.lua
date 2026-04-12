local TICK_PERIOD = TUNING.SKILLS.WX78.SHADOWHEART_PASSIVE_TICK_PERIOD

local Socket_Shadow_Heart = Class(function(self, inst)
    self.inst = inst
    self.debuffradius = 4
    self.damagemult = 1.25
    
    self.DEBUFF_MUST_TAGS = {"_combat"}
    self.DEBUFF_CANT_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO"}
    if not TheNet:GetPVPEnabled() then
        table.insert(self.DEBUFF_CANT_TAGS, "player")
    end

    if self.inst.isplayer then
        self.OnTick = function(inst)
            local combat = inst.components.combat
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, self.debuffradius, self.DEBUFF_MUST_TAGS, self.DEBUFF_CANT_TAGS)
            local maxfx = 3
            for _, ent in ipairs(ents) do
                if ent:IsValid()
                    and (ent.components.health == nil or not ent.components.health:IsDead())
                    and (combat == nil or (combat:CanTarget(ent) and not combat:IsAlly(ent)))
                    and (inst.TargetForceAttackOnly == nil or not inst:TargetForceAttackOnly(ent))
                then
                    if maxfx > 0 and not ent:HasDebuff("wx78_shadow_heart_debuff") then
                        local ex, ey, ez = ent.Transform:GetWorldPosition()
                        local fx = SpawnPrefab("wx78_possessed_shadow")
                        fx.Transform:SetPosition(x, y, z)
                        fx:ForceFacePoint(ex, ey, ez)
                        maxfx = maxfx - 1
                    end
                    ent:AddDebuff("wx78_shadow_heart_debuff", "wx78_shadow_heart_debuff")
                end
            end
        end
        self.periodictask = self.inst:DoPeriodicTask(TICK_PERIOD, self.OnTick)
    else
        if self.inst.prefab == "wx78_backupbody" then
            self.spawner = SpawnPrefab("wx78_heartveinspawner")
            self.spawner:ListenForEvent("onremove", function()
                self.spawner = nil
            end)
            self.spawner.entity:SetParent(self.inst.entity)
        end
    end
end)

function Socket_Shadow_Heart:OnRemoveFromEntity()
    if self.periodictask then
        self.periodictask:Cancel()
        self.periodictask = nil
    end
    if self.spawner then
        self.spawner:Remove()
    end
end

function Socket_Shadow_Heart:SetDebuffRadius(debuffradius)
    self.debuffradius = debuffradius
end

function Socket_Shadow_Heart:SetDamageMult(damagemult)
    self.damagemult = damagemult
end

return Socket_Shadow_Heart
