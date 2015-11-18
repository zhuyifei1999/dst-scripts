local Wisecracker = Class(function(self, inst)
    self.inst = inst
    self.time_in_lightstate = 0
    self.inlight = true

    inst:ListenForEvent("oneat",
        function(inst, data) 
            if data.food ~= nil and data.food.components.edible ~= nil then
                if data.food.prefab == "spoiled_food" then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "SPOILED"))
                elseif data.food.components.edible:GetHealth(inst) < 0 and
                    data.food.components.edible:GetSanity(inst) <= 0 and
                    not (inst.components.eater ~= nil and
                        inst.components.eater.strongstomach and
                        data.food:HasTag("monstermeat")) then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "PAINFUL"))
                elseif data.food.components.perishable ~= nil and
                    data.food.components.edible.degrades_with_spoilage and
                    not data.food.components.perishable:IsFresh() then
                    if data.food.components.perishable:IsStale() then
                        inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "STALE"))
                    elseif data.food.components.perishable:IsSpoiled() then
                        inst.components.talker:Say(GetString(inst, "ANNOUNCE_EAT", "SPOILED"))
                    end
                end
            end
        end)

    inst:StartUpdatingComponent(self)

    -- if not TheWorld:HasTag("cave") or not data.newdusk then
    --     inst:WatchWorldState("startdusk", function()
    --         if inst.components.talker then inst.components.talker:Say(GetString(inst, "ANNOUNCE_DUSK")) end
    --     end)
    -- end

    inst:ListenForEvent("itemranout", function(inst, data)
        inst.components.talker:Say(GetString(inst, data.announce))
    end)

    inst:ListenForEvent("heargrue", function(inst, data)
        if inst.components.talker then inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARLIE")) end
    end)

    inst:ListenForEvent("accomplishment", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_ACCOMPLISHMENT"))
    end)

    inst:ListenForEvent("accomplishment_done", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_ACCOMPLISHMENT_DONE"))
    end)

    inst:ListenForEvent("attacked", function(inst, data)
        if data.weapon and data.weapon.prefab == "boomerang" then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_BOOMERANG"))
        end
    end)

    inst:ListenForEvent("insufficientfertilizer", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_INSUFFICIENTFERTILIZER"))
    end)

    inst:ListenForEvent("attackedbygrue", function(inst, data)
        if inst.components.talker then inst.components.talker:Say(GetString(inst, "ANNOUNCE_CHARLIE_ATTACK")) end
    end)

    inst:ListenForEvent("thorns", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_THORNS"))
    end)

    inst:ListenForEvent("burnt", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_BURNT"))
    end)

    inst:ListenForEvent("hungerdelta",
        function(inst, data)
            if data.newpercent <= TUNING.HUNGRY_THRESH and data.oldpercent > TUNING.HUNGRY_THRESH then
                inst.components.talker:Say(GetString(inst, "ANNOUNCE_HUNGRY"))
            end
        end)

    inst:ListenForEvent("ghostdelta",
        function(inst, data) 
            if data.newpercent <= TUNING.GHOST_THRESH and data.oldpercent > TUNING.GHOST_THRESH then
                inst.components.talker:Say(GetString(inst, "ANNOUNCE_GHOSTDRAIN"))
            end
        end)

    inst:ListenForEvent("startfreezing",
        function(inst, data)
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_COLD"))
        end)

    inst:ListenForEvent("startoverheating",
        function(inst, data) 
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_HOT"))
        end)

    inst:ListenForEvent("inventoryfull", function(it, data)
        if inst.components.inventory:IsFull() then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_INV_FULL"))
        end
    end)

    inst:ListenForEvent("coveredinbees", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_BEES"))
    end)

    inst:ListenForEvent("wormholespit", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_WORMHOLE"))
    end)

    inst:ListenForEvent("huntlosttrail", function(inst, data)
        inst.components.talker:Say(GetString(inst, data.washedaway and "ANNOUNCE_HUNT_LOST_TRAIL_SPRING" or "ANNOUNCE_HUNT_LOST_TRAIL"))
    end)

    inst:ListenForEvent("huntbeastnearby", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_HUNT_BEAST_NEARBY"))
    end)

    inst:ListenForEvent("lightningdamageavoided", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_LIGHTNING_DAMAGE_AVOIDED"))
    end)
end)

function Wisecracker:OnUpdate(dt)
    local nightvision = CanEntitySeeInDark(self.inst)
    if nightvision or self.inst.LightWatcher:IsInLight() then
        if not self.inlight and (nightvision or self.inst.LightWatcher:GetTimeInLight() >= .5) then
            self.inlight = true
            if self.inst.components.talker ~= nil and not self.inst:HasTag("playerghost") then
                self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_ENTER_LIGHT"))
            end
        end
    elseif self.inlight and self.inst.LightWatcher:GetTimeInDark() >= .5 then
        self.inlight = false
        if self.inst.components.talker ~= nil then
            self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_ENTER_DARK"))
        end
    end
end

return Wisecracker
