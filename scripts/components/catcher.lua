local function oncancatch(self)
    if self.canact and next(self.watchlist) ~= nil then
        self.inst:AddTag("cancatch")
    else
        self.inst:RemoveTag("cancatch")
    end
end

local Catcher = Class(function(self, inst)
    self.inst = inst
    self.actiondistance = 12
    self.catchdistance = 2
    self.canact = false
    self.watchlist = {}
end,
nil,
{
    canact = oncancatch,
})

function Catcher:OnRemoveFromEntity()
    self.inst:RemoveTag("cancatch")
end

---this is the distance at which the action to catch the projectile appears
function Catcher:SetActionDistance(dist)
    self.actiondistance = dist
end

--this is the distance at which the projectile will be caught, if ready
function Catcher:SetCatchDistance(dist)
    self.catchdistance = dist
end

function Catcher:StartWatching(projectile)
    self.watchlist[projectile] = true
    oncancatch(self)
    self.inst:StartUpdatingComponent(self)
end

function Catcher:StopWatching(projectile)
    self.watchlist[projectile] = nil
    oncancatch(self)
    if next(self.watchlist) == nil then
        self.inst:StopUpdatingComponent(self)
    end
end

function Catcher:CanCatch()
    return next(self.watchlist) ~= nil and self.canact
end

function Catcher:OnUpdate()
    if not self.inst:IsValid() then
        return
    end

    local isreadytocatch = self.inst.sg:HasStateTag("readytocatch")
    self.canact = false

    for k, v in pairs(self.watchlist) do
        if not k:IsValid() or k.components.projectile == nil or not k.components.projectile:IsThrown() then
            self:StopWatching(k)
        elseif isreadytocatch then
            local distsq = k:GetDistanceSqToInst(self.inst)
            if distsq <= self.catchdistance * self.catchdistance then
                self.inst:PushEvent("catch", { projectile = k })
                k:PushEvent("caught", { catcher = self.inst })
                k.components.projectile:Catch(self.inst)
                self:StopWatching(k)
            elseif not self.canact and distsq < self.actiondistance * self.actiondistance then
                self.canact = true
            end
        elseif not self.canact and k:IsNear(self.inst, self.actiondistance) then
            self.canact = true
        end
    end
end

return Catcher