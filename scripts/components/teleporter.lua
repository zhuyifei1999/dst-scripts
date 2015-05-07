local function ontargetteleporter(self, targetteleporter)
    if targetteleporter ~= nil then
        self.inst:AddTag("teleporter")
    else
        self.inst:RemoveTag("teleporter")
    end
end

local Teleporter = Class(function(self, inst)
    self.inst = inst
    self.targetTeleporter = nil
    self.onActivate = nil
    self.onActivateOther = nil
    self.offset = 2
end,
nil,
{
    targetTeleporter = ontargetteleporter,
})

function Teleporter:OnRemoveFromEntity()
    self.inst:RemoveTag("teleporter")
end

function Teleporter:Activate(doer)
    if self.targetTeleporter == nil then
        return
    end

    if self.onActivate ~= nil then
        self.onActivate(self.inst, doer)
    end

    if self.onActivateOther ~= nil then
        self.onActivateOther(self.inst, self.targetTeleporter, doer)
    end

    self:Teleport(doer)

    if doer.components.leader ~= nil then
        for follower, v in pairs(doer.components.leader.followers) do
            self:Teleport(follower)
        end
    end

    --special case for the chester_eyebone: look for inventory items with followers
    if doer.components.inventory ~= nil then
        for k, item in pairs(doer.components.inventory.itemslots) do
            if item.components.leader ~= nil then
                for follower, v in pairs(item.components.leader.followers) do
                    self:Teleport(follower)
                end
            end
        end
        -- special special case, look inside equipped containers
        for k, equipped in pairs(doer.components.inventory.equipslots) do
            if equipped.components.container ~= nil then
                for j, item in pairs(equipped.components.container.slots) do
                    if item.components.leader ~= nil then
                        for follower, v in pairs(item.components.leader.followers) do
                            self:Teleport(follower)
                        end
                    end
                end
            end
        end
    end
end

-- You probably don't want this, call Activate instead.
function Teleporter:Teleport(obj)
    if self.targetTeleporter ~= nil then
        local target_x, target_y, target_z = self.targetTeleporter.Transform:GetWorldPosition()
        if self.offset ~= 0 then
            local angle = math.random() * 2 * PI
            target_x = target_x + math.cos(angle) * self.offset
            target_z = target_z - math.sin(angle) * self.offset
        end
        if obj.Physics ~= nil then
            obj.Physics:Teleport(target_x, target_y, target_z)
        elseif obj.Transform ~= nil then
            obj.Transform:SetPosition(target_x, target_y, target_z)
        end
    end
end

function Teleporter:Target(otherTeleporter)
    self.targetTeleporter = otherTeleporter
end

function Teleporter:OnSave()
    if self.targetTeleporter ~= nil then
        return { target = self.targetTeleporter.GUID }, { self.targetTeleporter.GUID }
    end
end

function Teleporter:LoadPostPass(newents, savedata)
    if savedata ~= nil and savedata.target ~= nil then
        local targEnt = newents[savedata.target]
        if targEnt ~= nil and targEnt.entity.components.teleporter ~= nil then
            self.targetTeleporter = targEnt.entity
        end
    end
end

return Teleporter
