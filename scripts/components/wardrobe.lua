local function oncanuseaction(self, canuseaction)
    if canuseaction then
        --V2C: Recommended to explicitly add tag to prefab pristine state
        self.inst:AddTag("wardrobe")
    else
        self.inst:RemoveTag("wardrobe")
    end
end

local Wardrobe = Class(function(self, inst)
    self.inst = inst

    self.changers = {}
    self.canuseaction = true
    self.canbeshared = false
    self.range = 3
    self.changeindelay = 0
    self.onchangeinfn = nil
    self.onopenfn = nil
    self.onclosefn = nil

    self.onclosewardrobe = function(doer, skins) -- yay closures ~gj -- yay ~v2c
        if self.changers[doer] and not self:ActivateChanging(doer, skins) then
            self:EndChanging(doer)
        end
    end
end,
nil,
{
    canuseaction = oncanuseaction,
})

--Whether this is included in player action collection or not
function Wardrobe:SetCanUseAction(canuseaction)
    self.canuseaction = canuseaction
end

--Whether multiple people can use the wardrobe at once or not
function Wardrobe:SetCanBeShared(canbeshared)
    self.canbeshared = canbeshared
end

function Wardrobe:SetRange(range)
    self.range = range
end

function Wardrobe:SetChangeInDelay(delay)
    self.changeindelay = delay
end

function Wardrobe:CanBeginChanging(doer)
    if self.changers[doer] or
        doer.sg == nil or
        (doer.sg:HasStateTag("busy") and doer.sg.currentstate.name ~= "opengift") then
        return false
    elseif not self.shareable and next(self.changers) ~= nil then
        return false, "INUSE"
    end
    return true
end

function Wardrobe:BeginChanging(doer)
    if not self.changers[doer] then
        local wasclosed = next(self.changers) == nil

        self.changers[doer] = true

        self.inst:ListenForEvent("onremove", self.onclosewardrobe, doer)
        self.inst:ListenForEvent("ms_closewardrobe", self.onclosewardrobe, doer)

        if doer.sg.currentstate.name == "opengift" then
            doer.sg.statemem.isopeningwardrobe = true
            doer.sg:GoToState("openwardrobe", true)
        else
            doer.sg:GoToState("openwardrobe")
        end

        if wasclosed then
            self.inst:StartUpdatingComponent(self)

            if self.onopenfn ~= nil then
                self.onopenfn(self.inst)
            end
        end
        return true
    end
    return false
end

function Wardrobe:EndChanging(doer)
    if self.changers[doer] then
        self.inst:RemoveEventCallback("onremove", self.onclosewardrobe, doer)
        self.inst:RemoveEventCallback("ms_closewardrobe", self.onclosewardrobe, doer)

        self.changers[doer] = nil

        if doer.sg:HasStateTag("inwardrobe") and not doer.sg.statemem.isclosingwardrobe then
            doer.sg.statemem.isclosingwardrobe = true
            doer.sg:GoToState("idle")
        end

        if next(self.changers) == nil then
            self.inst:StopUpdatingComponent(self)

            if self.onclosefn ~= nil then
                self.onclosefn(self.inst)
            end
        end
    end
end

function Wardrobe:EndAllChanging()
    local toend = {}
    for k, v in pairs(self.changers) do
        table.insert(toend, k)
    end
    for i, v in ipairs(toend) do
        self:EndChanging(v)
    end
end

function Wardrobe:ActivateChanging(doer, skins)
    if skins ~= nil and
        next(skins) ~= nil and
        doer.sg.currentstate.name == "openwardrobe" and
        doer.components.skinner ~= nil then
        local old = doer.components.skinner:GetClothing()
        local diff =
        {
            base = skins.base ~= nil and skins.base ~= old.base and skins.base or nil,
            body = skins.body ~= nil and skins.body ~= old.body and skins.body or nil,
            hand = skins.hand ~= nil and skins.hand ~= old.hand and skins.hand or nil,
            legs = skins.legs ~= nil and skins.legs ~= old.legs and skins.legs or nil,
        }

        if next(diff) ~= nil then
            doer.sg.statemem.ischanging = true

            if self.canbeshared then
                doer.sg:GoToState("changeoutsidewardrobe", function() self:ApplySkins(doer, diff) end)
            else
                self:ApplySkins(doer, diff)

                doer.sg:GoToState("changeinwardrobe", self.changeindelay)

                if self.onchangeinfn ~= nil then
                    self.onchangeinfn(self.inst)
                end
            end
            return true
        end
    end
    return false
end

function Wardrobe:ApplySkins(doer, skins)
    if doer.components.skinner ~= nil then
        if skins.base ~= nil then
            doer.components.skinner:SetSkinName(skins.base)
        end

        -- Must clear clothing items in case the new value is nil
        if skins.body ~= nil then
            doer.components.skinner:ClearClothing("body")
            doer.components.skinner:SetClothing(skins.body)
        end

        if skins.hand ~= nil then
            doer.components.skinner:ClearClothing("hand")
            doer.components.skinner:SetClothing(skins.hand)
        end

        if skins.legs ~= nil then
            doer.components.skinner:ClearClothing("legs")
            doer.components.skinner:SetClothing(skins.legs)
        end
    end
end

--------------------------------------------------------------------------
--Check for auto-closing conditions
--------------------------------------------------------------------------

function Wardrobe:OnUpdate(dt)
    if next(self.changers) == nil then
        self.inst:StopUpdatingComponent(self)
    else
        local toend = {}
        for k, v in pairs(self.changers) do
            if not (k:IsNear(self.inst, self.range) and
                    CanEntitySeeTarget(k, self.inst)) then
                table.insert(toend, k)
            end
        end
        for i, v in ipairs(toend) do
            self:EndChanging(v)
        end
    end
end

--------------------------------------------------------------------------

Wardrobe.OnRemoveFromEntity = Wardrobe.EndAllChanging
Wardrobe.OnRemoveEntity = Wardrobe.EndAllChanging

return Wardrobe
