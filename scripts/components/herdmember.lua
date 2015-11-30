--- Tracks the herd that the object belongs to, and creates one if missing
local function OnInit(inst)
    inst.components.herdmember.task = nil
    inst.components.herdmember:CreateHerd()
end

local HerdMember = Class(function(self, inst)
    self.inst = inst

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("herdmember")

    self.herd = nil
    self.herdprefab = "beefaloherd"
    
    self.task = self.inst:DoTaskInTime(5, OnInit)
end)

function HerdMember:OnRemoveFromEntity()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
    self.inst:RemoveTag("herdmember")
end

function HerdMember:SetHerd(herd)
    self.herd = herd
end

function HerdMember:SetHerdPrefab(prefab)
    self.herdprefab = prefab
end

function HerdMember:GetHerd()
    return self.herd
end

function HerdMember:CreateHerd()
    if not self.herd then
        local herd = SpawnPrefab(self.herdprefab)
        if herd then
            herd.Transform:SetPosition(self.inst.Transform:GetWorldPosition() )
            if herd.components.herd then
                herd.components.herd:GatherNearbyMembers()
            end
        end
    end
end

function HerdMember:GetDebugString()
    return string.format("herd:%s",tostring(self.herd))
end

return HerdMember
