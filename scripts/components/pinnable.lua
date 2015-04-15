
local pinsymbols = {
    "swap_goo6",
    "swap_goo5",
    "swap_goo4",
    "swap_goo3",
    "swap_goo2",
    "swap_goo1",
}

local splashprefabs = {
    "spat_splash_fx_melted",
    "spat_splash_fx_low",
    "spat_splash_fx_med",
    "spat_splash_fx_full",
}

local function WearOff(inst)
    local pinnable = inst.components.pinnable
    if pinnable then
        pinnable:UpdateStuckStatus()
    end
end

local function OnStuckChanged(self, stuck)
    if stuck then
        self.inst:AddTag("pinned")
    else
        self.inst:RemoveTag("pinned")
    end
end

local function OnUnpinned(inst)
    local pinnable = inst.components.pinnable
    if pinnable then
        if pinnable:IsStuck() then
            pinnable:Unstick()
        end
    end
end

local function OnAttacked(inst)
    local pinnable = inst.components.pinnable
    if pinnable and pinnable:IsStuck() then
        pinnable.attacks_since_pinned = pinnable.attacks_since_pinned + 1
        -- print("attacks since pinned", pinnable.attacks_since_pinned)
        pinnable:SpawnShatterFX()
        pinnable:UpdateStuckStatus()
    end
end

local function OnDied(inst)
    local pinnable = inst.components.pinnable
    if pinnable then
        if pinnable.wearofftask then
            pinnable.wearofftask:Cancel()
            pinnable.wearofftask = nil
        end
    end
end

-----------------------------------------------------------------------------------------------------

local Pinnable = Class(function(self, inst)
    self.inst = inst
    self.stuck = false
    self.wearofftime = TUNING.PINNABLE_WEAR_OFF_TIME
    self.attacks_since_pinned = 0
    self.last_unstuck_time = 0
    self.last_stuck_time = 0

    self.fxlevel = 1
    self.fxdata = {}
    
    self.inst:ListenForEvent("unpinned", OnUnpinned)
    self.inst:ListenForEvent("attacked", OnAttacked)
    self.inst:ListenForEvent("playerdied", OnDied)

    self.inst:AddTag("pinnable")
end,
nil,
{
    stuck = OnStuckChanged,
})

function Pinnable:SetDefaultWearOffTime(wearofftime)
    self.wearofftime = wearofftime
end

function Pinnable:SpawnShatterFX(ratio)
    local ratio = self:RemainingRatio()
    local index = math.clamp(math.floor(#splashprefabs*ratio)+1, 1, #splashprefabs)
    local fx = SpawnPrefab(splashprefabs[index])
    if fx then
        self.inst:AddChild(fx)
    end
end

function Pinnable:IsStuck( )
    return self.stuck
end

function Pinnable:IsValidPinTarget()
    return not self.stuck and (GetTime() > self.last_unstuck_time + TUNING.PINNABLE_RECOVERY_LEEWAY)
end

function Pinnable:StartWearingOff(wearofftime)
    if self.wearofftask then
        self.wearofftask:Cancel()
        self.wearofftask = nil
    end
    local mintime = wearofftime < 1 and wearofftime or 1
    self.wearofftask = self.inst:DoTaskInTime(mintime, WearOff)
end

function Pinnable:Stick()
    if self.inst.entity:IsVisible() and not (self.inst.components.health and self.inst.components.health:IsDead()) then
        local prevState = self.stuck
        self.stuck = true

        if self.inst.brain then
            self.inst.brain:Stop()
        end
        
        if self.inst.components.combat then
            self.inst.components.combat:SetTarget(nil)
        end
        
        if self.inst.components.locomotor then
            self.inst.components.locomotor:Stop()
        end

        if self.stuck ~= prevState then 
            self.attacks_since_pinned = 0
            self.last_stuck_time = GetTime()
            self:UpdateStuckStatus()

            self.inst:PushEvent("pinned")
        end
    end
end

function Pinnable:UpdateStuckStatus()
    if self:IsStuck() then
        local remaining = self:RemainingRatio()
        -- print("remaining:", remaining)
        if remaining <= 0 then
            self:Unstick()
        else
            local index = math.clamp(math.floor(#pinsymbols*remaining)+1, 1, #pinsymbols)
            self.inst.AnimState:OverrideSymbol("swap_goo", "goo", pinsymbols[index])

            self:StartWearingOff(remaining)
        end
    end
end

function Pinnable:RemainingRatio()
    local remaining = self.wearofftime - ( GetTime() - self.last_stuck_time )
    remaining = remaining - self.attacks_since_pinned * TUNING.PINNABLE_ATTACK_WEAR_OFF
    return remaining / self.wearofftime
end

function Pinnable:Unstick()
    if (not self.inst.components.health or not self.inst.components.health:IsDead()) and self:IsStuck() then

        self.stuck = false
        
        self:SpawnShatterFX()
        
        if self.inst.brain then
            self.inst.brain:Start()
        end

        if self.wearofftask then
            self.wearofftask:Cancel()
            self.wearofftask = nil
        end

        self.last_unstuck_time = GetTime()

        self.inst.AnimState:ClearOverrideSymbol("swap_goo")

        self.inst:PushEvent("onunpin")
    end
end

function Pinnable:OnRemoveFromEntity()
    self.inst:RemoveTag("pinnable") 
end

return Pinnable
