local function oncanride(self, canride)
    if canride then
        self.inst:AddTag("rideable")
    else
        self.inst:RemoveTag("rideable")
    end
end

local function RiddenTick(inst, dt)
    inst:PushEvent("beingridden", dt)
end

local function StartRiddenTick(self)
    if self.riddentask == nil then
        self.riddentask = self.inst:DoPeriodicTask(6, RiddenTick, 0, 6)
    end
end

local function StopRiddenTick(self)
    if self.riddentask ~= nil then
        self.riddentask:Cancel()
        self.riddentask = nil
    end
end

local Rideable = Class(function(self, inst)
    self.inst = inst
    self.saddleable = false
    self.canride = false
    self.saddle = nil
    self.rider = nil

    self.riddentask = nil

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("saddleable")
end,
nil,
{
    canride = oncanride,
})

function Rideable:OnRemoveFromEntity()
    StopRiddenTick(self)
    self.inst:RemoveTag("saddleable")
    self.inst:RemoveTag("rideable")
end

function Rideable:SetSaddle(doer, newsaddle)
    --print("setting saddle to "..(newsaddle.prefab or 'nil'))
    if self.saddle ~= nil then
        self.inst.AnimState:ClearOverrideSymbol("swap_saddle")

        self.inst:RemoveChild(self.saddle)
        self.saddle:ReturnToScene()

        self.inst.components.lootdropper:FlingItem(self.saddle, nil, self.saddle.components.saddler.discardedcb)
        self.canride = false
        self.saddle = nil
        self.inst:PushEvent("saddlechanged", { saddle = nil })
    end

    if newsaddle ~= nil then
        if self.saddleable then
            self.inst:AddChild(newsaddle)
            newsaddle.Transform:SetPosition(0,0,0) -- make sure we're centered, so poop lands in the right spot!
            newsaddle:RemoveFromScene()
            self.saddle = newsaddle
            self.inst:PushEvent("saddlechanged", { saddle = newsaddle })

            self.inst.AnimState:OverrideSymbol("swap_saddle", self.saddle.components.saddler.swapbuild, self.saddle.components.saddler.swapsymbol)
            self.canride = true
            if doer ~= nil then
                self.inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
            end
        else
            self.inst.components.lootdropper:FlingItem(newsaddle)
            if self.inst.components.combat then
                self.inst.components.combat:SuggestTarget(doer)
            end
        end
    end
end

function Rideable:SetSaddleable(saddleable)
    self.saddleable = saddleable
end

function Rideable:IsSaddled()
    return self.saddle ~= nil
end

function Rideable:SetRider(rider)
    local oldrider = self.rider
    self.rider = rider

    if rider ~= nil then
        StartRiddenTick(self)
    else
        StopRiddenTick(self)
    end

    self.inst:PushEvent("riderchanged", { oldrider = oldrider, newrider = self.rider })
end

function Rideable:GetRider()
    return self.rider
end

function Rideable:IsBeingRidden()
    return self.rider ~= nil
end

function Rideable:Buck(gentle)
    if self.rider ~= nil and self.rider.components.rider ~= nil then
        self.rider:PushEvent("bucked", { gentle = gentle })
    end
end

--V2C: domesticatable MUST load b4 rideable, see domesticatable.lua
--     (we aren't using the usual OnLoadPostPass method)
function Rideable:OnSaveDomesticatable()
    local data =
    {
        saddle = self.saddle ~= nil and self.saddle:GetSaveRecord() or nil,
    }
    return next(data) ~= nil and data or nil
end

function Rideable:OnLoadDomesticatable(data)
    if data ~= nil and data.saddle ~= nil then
        self:SetSaddle(nil, SpawnSaveRecord(data.saddle))
    end
end

function Rideable:GetDebugString()
    return "saddle:"..(self.saddle ~= nil and self.saddle.prefab or "nil")
end

return Rideable
