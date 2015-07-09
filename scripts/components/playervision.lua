local GHOSTVISION_COLOURCUBES =
{
    day = "images/colour_cubes/ghost_cc.tex",
    dusk = "images/colour_cubes/ghost_cc.tex",
    night = "images/colour_cubes/ghost_cc.tex",
    full_moon = "images/colour_cubes/ghost_cc.tex",
}

local NIGHTVISION_COLOURCUBES =
{
    day = "images/colour_cubes/mole_vision_off_cc.tex",
    dusk = "images/colour_cubes/mole_vision_on_cc.tex",
    night = "images/colour_cubes/mole_vision_on_cc.tex",
    full_moon = "images/colour_cubes/mole_vision_off_cc.tex",
}

local function OnEquip(inst, data)
    local self = inst.components.playervision
    if not self.nightvision and data.item:HasTag("nightvision") then
        self.nightvision = true
        if not self.forcenightvision then
            self:UpdateCCTable()
            inst:PushEvent("nightvision", true)
        end
    end
end

local function OnUnequip(inst)
    local self = inst.components.playervision
    if self.nightvision and not inst.replica.inventory:EquipHasTag("nightvision") then
        self.nightvision = false
        if not self.forcenightvision then
            self:UpdateCCTable()
            inst:PushEvent("nightvision", false)
        end
    end
end

local function OnInit(inst, self)
    inst:ListenForEvent("equip", OnEquip)
    inst:ListenForEvent("unequip", OnUnequip)
    if not self.nightvision and inst.replica.inventory:EquipHasTag("nightvision") then
        self.nightvision = true
        if not self.forcenightvision then
            self:UpdateCCTable()
            inst:PushEvent("nightvision", true)
        end
    end
end

local PlayerVision = Class(function(self, inst)
    self.inst = inst

    self.ghostvision = false
    self.nightvision = false
    self.forcenightvision = false
    self.overridecctable = nil
    self.currentcctable = nil

    inst:DoTaskInTime(0, OnInit, self)
end)

function PlayerVision:HasNightVision()
    return self.nightvision or self.forcenightvision
end

function PlayerVision:GetCCTable()
    return self.currentcctable
end

function PlayerVision:UpdateCCTable()
    local cctable =
        (self.ghostvision and GHOSTVISION_COLOURCUBES) or
        self.overridecctable or
        ((self.nightvision or self.forcenightvision) and NIGHTVISION_COLOURCUBES) or
        nil

    if cctable ~= self.currentcctable then
        self.currentcctable = cctable
        self.inst:PushEvent("ccoverrides", cctable)
    end
end

function PlayerVision:SetGhostVision(enabled)
    if not self.ghostvision ~= not enabled then
        self.ghostvision = enabled == true
        self:UpdateCCTable()
    end
end

function PlayerVision:ForceNightVision(force)
    if not self.forcenightvision ~= not force then
        self.forcenightvision = force == true
        if not self.nightvision then
            self:UpdateCCTable()
            self.inst:PushEvent("nightvision", self.forcenightvision)
        end
    end
end

function PlayerVision:SetCustomCCTable(cctable)
    if self.overridecctable ~= cctable then
        self.overridecctable = cctable
        self:UpdateCCTable()
    end
end

return PlayerVision
