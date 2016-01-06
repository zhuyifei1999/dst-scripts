local function DefaultOnHauntFn(inst, haunter)
    return true
end

local function onhaunted(self, haunted)
    if haunted then
        self.inst:AddTag("haunted")
    else
        self.inst:RemoveTag("haunted")
    end
end

local Hauntable = Class(function(self, inst)
    self.inst = inst

    self.onhaunt = DefaultOnHauntFn
    self.onunhaunt = nil

    self.haunted = false
    self.hauntvalue = nil
    self.no_wipe_value = false

    self.cooldowntimer = 0
    self.cooldown = nil
    
    self.cooldown_on_successful_haunt = true

    self.panic = false
    self.panictimer = 0

    self.usefx = true
    self.fx = nil
    self.flicker = "off"
end,
nil,
{
    haunted = onhaunted,
})

function Hauntable:SetOnHauntFn(fn)
    -- This function, whatever it is, should return true for successful haunts (to trigger haunter effects) and nil or false for unsuccessful haunts
    -- A successful haunt should be determined on a per-entity basis (i.e. rates/conditions might vary for different ents)
    self.onhaunt = fn
end

-- Function that fires when something is done being haunted (i.e. its haunt expires)
function Hauntable:SetOnUnHauntFn(fn)
    self.onunhaunt = fn
end

function Hauntable:SetHauntValue(val)
    if not val then return end
    self.hauntvalue = val
    self.no_wipe_value = true
end

function Hauntable:Panic(panictime)
    self.haunted = true
    self.panic = true
    self.panictimer = panictime or TUNING.HAUNT_PANIC_TIME_SMALL
    self.cooldowntimer = self.panictimer
    self.inst:StartUpdatingComponent(self)
end

function Hauntable:StartFX(noflicker)
    if self.usefx then
        if not self.fx then

--          self.fx = SpawnPrefab("hauntfx")
--          if self.fx then
--              local follower = self.fx.entity:AddFollower()
--              follower:FollowSymbol(self.inst.GUID, self.inst.components.combat and self.inst.components.combat.hiteffectsymbol or "swap_object", 0, 0, 0)
--          end
        end
        if not noflicker then self:AdvanceFlickerState() end
    end
end

function Hauntable:AdvanceFlickerState()
    if self.flicker == "off" then
        self.flicker = "on"
    elseif self.flicker == "on" then
        self.flicker = "fadeout"
    elseif self.flicker == "fadeout" then
        self.flicker = "off"
        self.inst.AnimState:SetMultColour(1, 1, 1, 1)
    end
end

function Hauntable:StopFX()
    if self.fx ~= nil then
        self.fx:Remove()
        self.fx = nil
    end
    self.flicker = "fadeout" -- guarantee that we turn flicker off
    self:AdvanceFlickerState()
end

function Hauntable:DoHaunt(doer)
    if self.onhaunt ~= nil then
        self.haunted = self.onhaunt(self.inst, doer)
        if self.haunted then
            if doer ~= nil then
                if self.hauntvalue == TUNING.HAUNT_INSTANT_REZ and doer:HasTag("playerghost") then
                    doer:PushEvent("respawnfromghost", { source = self.inst })
                end
                if not self.no_wipe_value then
                    self.hauntvalue = nil
                end
            end
            if self.cooldown_on_successful_haunt then
                self.cooldowntimer = self.cooldown or TUNING.HAUNT_COOLDOWN_MEDIUM
                self:StartFX(true)
                self:StartShaderFx()
                self.inst:StartUpdatingComponent(self)
            end
        else
            self.haunted = true
            self.cooldowntimer = self.cooldown or TUNING.HAUNT_COOLDOWN_SMALL
            self:StartFX(true)
            self:StartShaderFx()
            self.inst:StartUpdatingComponent(self)
        end
    end
end

function Hauntable:StartShaderFx()
    self.inst.AnimState:SetHaunted(true)
end

function Hauntable:StopShaderFX()
    if self.inst:IsValid() then
        self.inst.AnimState:SetHaunted(false)
    end
end

function Hauntable:OnUpdate(dt)
    if self.cooldowntimer <= 0 then
        self.cooldowntimer = 0
        self.haunted = false
        if self.onunhaunt then
            self.onunhaunt(self.inst)
        end
        self:StopShaderFX()
    else
        self.cooldowntimer = self.cooldowntimer - dt

        if self.cooldowntimer < .4 and self.flickering == "on" then
            self:AdvanceFlickerState()
        end
        if self.cooldowntimer < .2 and self.fx then
            self:StopFX()
        end

        if self.flicker == "on" then
            if math.random() <= .5 then
                self.inst.AnimState:SetMultColour(1, 1, 1, 1)
            else
                self.inst.AnimState:SetMultColour(.7, .7, .7, 1)
            end
        elseif self.flicker == "fadeout" then
            if math.random() <= .2 then
                self.inst.AnimState:SetMultColour(1, 1, 1, 1)
            else
                self.inst.AnimState:SetMultColour(.7, .7, .7, 1)
            end
        end
    end

    if self.panictimer <= 0 then
        self.panictimer = 0
        self.panic = false
    else
        self.panictimer = self.panictimer - dt
    end

    if not self.haunted and not self.panic then
        self.inst:StopUpdatingComponent(self)
    end

end

function Hauntable:OnRemoveEntity()
    if self.fx ~= nil then
        self.fx:Remove()
        self.fx = nil
    end
end

function Hauntable:OnRemoveFromEntity()
    self:StopFX()
    self.inst:RemoveTag("haunted")
end

return Hauntable
