local Explosive = Class(function(self,inst)
    self.inst = inst
    self.explosiverange = 3
    self.explosivedamage = 200
    self.buildingdamage = 10
    self.lightonexplode = true
    self.onexplodefn = nil
    self.onignitefn = nil
end)

function Explosive:SetOnExplodeFn(fn)
    self.onexplodefn = fn
end

function Explosive:SetOnIgniteFn(fn)
    self.onignitefn = fn
end

function Explosive:OnIgnite()
    DefaultBurnFn(self.inst)
    if self.onignitefn then
        self.onignitefn(self.inst)
    end
end

function Explosive:OnBurnt()   
    for i, v in ipairs(AllPlayers) do
        local distSq = v:GetDistanceSqToInst(self.inst)
        local k = math.max(0, math.min(1, distSq / 1600))
        local intensity = k * (k - 2) + 1 --easing.outQuad(k, 1, -1, 1)
        if intensity > 0 then
            v:ScreenFlash(intensity)
            v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, intensity / 2)
        end
    end

    if self.onexplodefn ~= nil then
        self.onexplodefn(self.inst)
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, self.explosiverange)

    for k, v in pairs(ents) do
        local inpocket = v.components.inventoryitem and v.components.inventoryitem:IsHeld()

        if not inpocket then

            if v.components.workable and not v.isresurrecting then --Haaaaaaack! (see resurrectionstatue & resurrectionstone prefabs)
                v.components.workable:WorkedBy(self.inst, self.buildingdamage)
            elseif v.components.burnable and not v.components.fueled and self.lightonexplode then
                v.components.burnable:Ignite()
            end

            self.stacksize = 1

            if self.inst.components.stackable then
                self.stacksize =  self.inst.components.stackable.stacksize
            end

            if v.components.combat and v ~= self.inst then
                v.components.combat:GetAttacked(self.inst, self.explosivedamage * self.stacksize or 1, nil)
            end

            v:PushEvent("explosion", {explosive = self.inst})
        end
    end

    local world = TheWorld
    for i = 1, self.stacksize, 1 do
        world:PushEvent("explosion", { damage = self.explosivedamage })
    end

    --self.inst:PushEvent("explosion")

    if self.inst.components.health ~= nil then
        self.inst:PushEvent("death")
    end

    self.inst:Remove()
end

return Explosive