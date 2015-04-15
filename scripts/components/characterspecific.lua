local CharacterSpecific = Class(function(self, inst)
    self.inst = inst

    self.character = nil
end)

function CharacterSpecific:SetOwner(name)
    self.character = name 
    --V2C: This doesn't make sense in a multiplayer environment anymore
    --[[if ThePlayer.prefab ~= name then
        self.inst.entity:Hide()
        self.inst:DoTaskInTime(0, self.inst.Remove)
    end]]
end

return CharacterSpecific