DAYLIGHT_SEARCH_RANGE = 30

local function onmatured(self, matured)
    if matured then
        self.inst:AddTag("readyforharvest")
        self.inst:RemoveTag("notreadyforharvest")
    else
        self.inst:RemoveTag("readyforharvest")
        self.inst:AddTag("notreadyforharvest")
    end
end

local Crop = Class(function(self, inst)
    self.inst = inst
    self.product_prefab = nil
    self.growthpercent = 0
    self.rate = 1 / 120
    self.task = nil
    self.matured = false
    self.onmatured = nil
    self.cantgrowtime = 0
end,
nil,
{
    matured = onmatured,
})

function Crop:OnRemoveFromEntity()
    self.inst:RemoveTag("readyforharvest")
    self.inst:RemoveTag("notreadyforharvest")
end

function Crop:SetOnMatureFn(fn)
    self.onmatured = fn
end

function Crop:OnSave()
    return
    {
        prefab = self.product_prefab,
        percent = self.growthpercent,
        rate = self.rate,
        matured = self.matured,
    }
end

function Crop:OnLoad(data)
    if data ~= nil then
        self.product_prefab = data.prefab or self.product_prefab
        self.growthpercent = data.percent or self.growthpercent
        self.rate = data.rate or self.rate
        self.matured = data.matured or self.matured
    end

    if not self.inst:HasTag("withered") then
        self:DoGrow(0)
        if self.product_prefab ~= nil and self.matured then
            self.inst.AnimState:PlayAnimation("grow_pst")
            if self.onmatured ~= nil then
                self.onmatured(self.inst)
            end
        end
    end
end

function Crop:Fertilize(fertilizer, doer)
    if self.inst.components.burnable ~= nil then
        self.inst.components.burnable:StopSmoldering()
    end

    if not (TheWorld.state.iswinter and TheWorld.state.temperature <= 0) then
        if fertilizer.components.fertilizer ~= nil then
            if doer ~= nil and
                doer.SoundEmitter ~= nil and
                fertilizer.components.fertilizer.fertilize_sound ~= nil then
                doer.SoundEmitter:PlaySound(fertilizer.components.fertilizer.fertilize_sound)
            end
            self.growthpercent = self.growthpercent + fertilizer.components.fertilizer.fertilizervalue * self.rate
        end
        self.inst.AnimState:SetPercent("grow", self.growthpercent)
        if self.growthpercent >= 1 then
            self.inst.AnimState:PlayAnimation("grow_pst")
            self:Mature()
            self.task:Cancel()
            self.task = nil
        end
        if fertilizer.components.finiteuses ~= nil then
            fertilizer.components.finiteuses:Use()
        else
            fertilizer.components.stackable:Get():Remove()
        end
        return true
    end
end

function Crop:DoGrow(dt, nowither)
    if not self.inst:HasTag("withered") then 
        self.inst.AnimState:SetPercent("grow", self.growthpercent)

        local shouldgrow = nowither or not TheWorld.state.isnight
        if not shouldgrow then
            local x,y,z = self.inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x,0,z, DAYLIGHT_SEARCH_RANGE, { "daylight", "lightsource" })
            for i,v in ipairs(ents) do
                local lightrad = v.Light:GetCalculatedRadius() * .7
                if v:GetDistanceSqToPoint(x,y,z) < lightrad * lightrad then
                    shouldgrow = true
                    break
                end
            end
        end
        if shouldgrow then
            local temp_rate =
                (TheWorld.state.temperature < TUNING.MIN_CROP_GROW_TEMP and 0) or
                (TheWorld.state.israining and 1 + TUNING.CROP_RAIN_BONUS * TheWorld.state.precipitationrate) or
                (TheWorld.state.isspring and 1 + TUNING.SPRING_GROWTH_MODIFIER / 3) or
                1
            self.growthpercent = self.growthpercent + dt * self.rate * temp_rate
            self.cantgrowtime = 0
        else
            self.cantgrowtime = self.cantgrowtime + dt
            if self.cantgrowtime > TUNING.CROP_DARK_WITHER_TIME
                and self.inst.components.witherable then
                self.inst.components.witherable:ForceWither()
            end
        end

        if self.growthpercent >= 1 then
            self.inst.AnimState:PlayAnimation("grow_pst")
            self:Mature()
            if self.task ~= nil then
                self.task:Cancel()
                self.task = nil
            end
        end
    end
end

function Crop:GetDebugString()
    return (self.inst:HasTag("withered") and "WITHERED")
        or (self.matured and string.format("[%s] DONE", tostring(self.product_prefab)))
        or string.format("[%s] %.2f%% (done in %.2f) darkwither: %.2f", tostring(self.product_prefab), self.growthpercent, (1 - self.growthpercent) / self.rate, TUNING.CROP_DARK_WITHER_TIME - self.cantgrowtime)
end

local function _DoGrow(inst, self, dt)
    self:DoGrow(dt)
end

function Crop:Resume()
    if not (self.matured or self.inst:HasTag("withered")) then
        self.inst.AnimState:SetPercent("grow", self.growthpercent)
        local dt = 2
        if self.task ~= nil then
            self.task:Cancel()
        end
        self.task = self.inst:DoPeriodicTask(dt, _DoGrow, nil, self, dt)
    end
end

function Crop:StartGrowing(prod, grow_time, grower, percent)
    self.product_prefab = prod
    self.rate = 1/ grow_time
    self.growthpercent = percent or 0
    self.inst.AnimState:SetPercent("grow", self.growthpercent)
    self.grower = grower

    local dt = 2
    if self.task ~= nil then
        self.task:Cancel()
    end
    self.task = self.inst:DoPeriodicTask(dt, _DoGrow, nil, self, dt)
end

function Crop:Harvest(harvester)
    if self.matured or self.inst:HasTag("withered") then
        local product = nil
        if self.grower ~= nil and
            (self.grower.components.burnable ~= nil and self.grower.components.burnable:IsBurning()) or
            (self.inst.components.burnable ~= nil and self.inst.components.burnable:IsBurning()) then
            local temp = SpawnPrefab(self.product_prefab)
            product = SpawnPrefab(temp.components.cookable ~= nil and temp.components.cookable.product or "seeds_cooked")
            temp:Remove()
        else
            product = SpawnPrefab(self.product_prefab)
        end

        if product ~= nil then
            if product.components.inventoryitem ~= nil then
                product.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
            end

            if harvester ~= nil then
                harvester.components.inventory:GiveItem(product, nil, self.inst:GetPosition())
            else
                -- just drop the thing (happens if you haunt the fully grown crop)
                product.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
            end
            ProfileStatsAdd("grown_"..product.prefab)
        end

        self.matured = false
        self.growthpercent = 0
        self.product_prefab = nil
        if self.grower ~= nil and self.grower:IsValid() and self.grower.components.grower ~= nil then
            self.grower.components.grower:RemoveCrop(self.inst)
        end
        self.grower = nil

        return true, product
    end
end

function Crop:Mature()
    if self.product_prefab ~= nil and not (self.matured or self.inst:HasTag("withered")) then
        self.matured = true
        if self.onmatured ~= nil then
            self.onmatured(self.inst)
        end
    end
end

function Crop:IsReadyForHarvest()
    return self.matured
end

function Crop:LongUpdate(dt)
    self:DoGrow(dt)
end

return Crop
