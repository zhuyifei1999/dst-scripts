local MapRevealable = Class(function(self, inst)
    self.inst = inst

    self.refreshperiod = 1.5
    self.iconname = nil
    self.iconpriority = nil
    self.icon = nil
    self.task = nil

    self:Start(math.random() * self.refreshperiod)
end)

function MapRevealable:SetIcon(iconname)
    self.iconname = iconname
    if self.icon ~= nil then
        self.icon.MiniMapEntity:SetIcon(iconname)
    end
end

function MapRevealable:SetIconPriority(priority)
    self.iconpriority = priority
    if self.icon ~= nil then
        self.icon.MiniMapEntity:SetPriority(priority)
    end
end

function MapRevealable:StartRevealing()
    if self.icon == nil then
        self.icon = SpawnPrefab("globalmapicon")
        if self.iconpriority ~= nil then
            self.icon.MiniMapEntity:SetPriority(self.iconpriority)
        end
        self.icon:TrackEntity(self.inst, nil, self.iconname)
    end
end

function MapRevealable:StopRevealing()
    if self.icon ~= nil then
        self.icon:Remove()
        self.icon = nil
    end
end

function MapRevealable:Refresh()
    if self.task ~= nil then
        if GetClosestInstWithTag("maprevealer", self.inst, 30) ~= nil then
            self:StartRevealing()
        else
            self:StopRevealing()
        end
    end
end

local function Refresh(inst, self)
    self:Refresh()
end

function MapRevealable:Start(delay)
    if self.task == nil then
        self.task = self.inst:DoPeriodicTask(self.refreshperiod, Refresh, delay, self)
    end
end

function MapRevealable:Stop()
    self:StopRevealing()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

MapRevealable.OnRemoveFromEntity = MapRevealable.Stop

return MapRevealable
