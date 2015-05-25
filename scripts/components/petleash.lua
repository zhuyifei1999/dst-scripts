local PetLeash = Class(function(self, inst)
    self.inst = inst

    self.petprefab = nil
    self.pet = nil

    self.onspawnfn = nil
    self.ondespawnfn = nil
end)

function PetLeash:SetPetPrefab(prefab)
    self.petprefab = prefab
end

function PetLeash:SetOnSpawnFn(fn)
    self.onspawnfn = fn
end

function PetLeash:SetOnDespawnFn(fn)
    self.ondespawnfn = fn
end

function PetLeash:SpawnPetAt(x, y, z)
    if self.pet ~= nil or self.petprefab == nil then
        return
    end

    self.pet = SpawnPrefab(self.petprefab)

    if self.pet ~= nil then
        self.inst:ListenForEvent("onremove", function() self.pet = nil end, self.pet)
        self.pet.persists = false

        if self.pet.Physics ~= nil then
            self.pet.Physics:Teleport(x, y, z)
        elseif self.pet.Transform ~= nil then
            self.pet.Transform:SetPosition(x, y, z)
        end

        if self.inst.components.leader ~= nil then
            self.inst.components.leader:AddFollower(self.pet)
        end

        if self.onspawnfn ~= nil then
            self.onspawnfn(self.inst, self.pet)
        end
    end
end

function PetLeash:DespawnPet()
    if self.pet ~= nil then
        if self.ondespawnfn ~= nil then
            self.ondespawnfn(self.inst, self.pet)
        else
            self.pet:Remove()
        end
    end
end

function PetLeash:OnSave()
    if self.pet ~= nil then
        return
        {
            pet = self.pet:GetSaveRecord(),
        }
    end
end

function PetLeash:OnLoad(data)
    if data ~= nil and data.pet ~= nil and self.pet == nil then
        self.pet = SpawnSaveRecord(data.pet)

        if self.pet ~= nil then
            self.inst:ListenForEvent("onremove", function() self.pet = nil end, self.pet)
            self.pet.persists = false

            if self.inst.components.leader ~= nil then
                self.inst.components.leader:AddFollower(self.pet)
            end

            if self.onspawnfn ~= nil then
                self.onspawnfn(self.inst, self.pet)
            end
        end
    end
end

PetLeash.OnRemoveEntity = PetLeash.DespawnPet

return PetLeash
