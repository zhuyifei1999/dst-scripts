local Widget           = require "widgets/widget"
local UIAnim           = require "widgets/uianim"
local UpgradeModulesDisplay   = require "widgets/upgrademodulesdisplay"

local function OnSetPlayerMode(inst, self)
    self.modetask = nil

    if self.upgrademodulesdisplay ~= nil then
        if self.onmodulesdirty == nil then
            self.onmodulesdirty = function(owner, data) self:ModulesDirty(data) end
            self.inst:ListenForEvent("upgrademodulesdirty", self.onmodulesdirty, self.owner)
        end

        if self.onpopallmodulesevent == nil then
            self.onpopallmodulesevent = function(owner) self:PopAllUpgradeModules() end
            self.inst:ListenForEvent("upgrademoduleowner_popallmodules", self.onpopallmodulesevent, self.owner)
        end

        if self.onupgrademodulesenergylevelupdated == nil then
            self.onupgrademodulesenergylevelupdated = function(owner, data) self:UpgradeModulesEnergyLevelDelta(data) end
            self.inst:ListenForEvent("energylevelupdate", self.onupgrademodulesenergylevelupdated, self.owner)
        end

        -- statusdisplays hasn't hooked up its listener events when we load prefabs and components,
        -- so we need to actively seek out our initial state here.
        self:SetUpgradeModuleMaxEnergyLevel(self.owner:GetMaxEnergy(), 0)
        self:SetUpgradeModuleEnergyLevel(self.owner:GetEnergyLevel(), 0, true)
        self:ModulesDirty(self.owner:GetModulesData())
    end
end

local function OnSetGhostMode(inst, self)
    self.modetask = nil

    if self.onupgrademodulesenergylevelupdated ~= nil then
        self.inst:RemoveEventCallback("energylevelupdate", self.onupgrademodulesenergylevelupdated, self.owner)
        self.onupgrademodulesenergylevelupdated = nil
    end
end

-- Like StatusDisplays, but aligned on the opposite side for splitscreen
local SecondaryStatusDisplays = Class(Widget, function(self, owner)
    Widget._ctor(self, "Status")
    self:UpdateWhilePaused(false)
    self.owner = owner

    if IsGameInstance(Instances.Player1) then
        self.column1 = 60
    else
        self.column1 = -60
    end

    self.modetask = nil
    self.isghostmode = true --force the initial SetGhostMode call to be dirty
    self:SetGhostMode(false)

    self.side_inv = self:AddChild(Widget("side_inv"))
    self.side_inv:SetPosition(self.column1, 0, 0)

    if owner:HasTag("upgrademoduleowner") then
        self:AddModuleOwnerDisplay()
    end
end)

function SecondaryStatusDisplays:ShowStatusNumbers()
    if self.upgrademodulesdisplay ~= nil then
        self.upgrademodulesdisplay:Open()
    end
end

function SecondaryStatusDisplays:HideStatusNumbers()
    if self.upgrademodulesdisplay ~= nil then
        self.upgrademodulesdisplay:Close()
    end
end

function SecondaryStatusDisplays:Layout()
end

---------------------------------------------------------------------------------------------

function SecondaryStatusDisplays:AddModuleOwnerDisplay()
    if self.upgrademodulesdisplay == nil then
        self.upgrademodulesdisplay = self:AddChild(UpgradeModulesDisplay(self.owner))
        self:SetUpgradeModuleEnergyLevel(self.owner:GetEnergyLevel(), 0, true)
        self:ModulesDirty(self.owner:GetModulesData())

        self.upgrademodulesdisplay:SetPosition(self.column1, -132, 0)
    end
end

function SecondaryStatusDisplays:HideModuleOwnerDisplay()
    if self.upgrademodulesdisplay ~= nil then
        self.upgrademodulesdisplay:HideUpgradeModulesDisplay()
    end
end

function SecondaryStatusDisplays:ShowModuleOwnerDisplay()
    if self.upgrademodulesdisplay ~= nil then
        self.upgrademodulesdisplay:ShowUpgradeModulesDisplay()
    end
end

local SIX_SLOT_MODULEDISPLAY_Y = -133
local SEVEN_SLOT_MODULEDISPLAY_Y = -145
function SecondaryStatusDisplays:UpdateModuleOwnerDisplayPosition()
    if self.upgrademodulesdisplay ~= nil then
        local y_offset = self.upgrademodulesdisplay:IsExtended() and SEVEN_SLOT_MODULEDISPLAY_Y or SIX_SLOT_MODULEDISPLAY_Y
        self.upgrademodulesdisplay:SetPosition(self.column1, y_offset, 0)
    end
end

---------------------------------------------------------------------------------------------

function SecondaryStatusDisplays:SetGhostMode(ghostmode)
    if not self.isghostmode == not ghostmode then --force boolean
        return
    elseif ghostmode then
        self.isghostmode = true

        if self.side_inv ~= nil then
            self.side_inv:Hide()
        end

        if self.upgrademodulesdisplay ~= nil then
            self.upgrademodulesdisplay:Hide()
        end
    else
        self.isghostmode = nil

        if self.side_inv ~= nil then
            self.side_inv:Show()
        end

        if self.upgrademodulesdisplay ~= nil then
            self.upgrademodulesdisplay:Show()
        end
    end

    if self.modetask ~= nil then
        self.modetask:Cancel()
    end
    self.modetask = self.inst:DoStaticTaskInTime(0, ghostmode and OnSetGhostMode or OnSetPlayerMode, self)
end

----------------------------------------------------------------------------------------------------------
-- WX modules UI

function SecondaryStatusDisplays:ModulesDirty(data)
    self.upgrademodulesdisplay:OnModulesDirty(data)

    if self.owner.HUD.upgrademodulewidget then
        self.owner.HUD.upgrademodulewidget:OnModulesDirty(data)
    end
end

function SecondaryStatusDisplays:PopAllUpgradeModules()
    self.upgrademodulesdisplay:PopAllModules()

    if self.owner.HUD.upgrademodulewidget then
        self.owner.HUD.upgrademodulewidget:PopAllModules()
    end
end

function SecondaryStatusDisplays:SetUpgradeModuleEnergyLevel(new_level, old_level, skipsound)
    self.upgrademodulesdisplay:UpdateEnergyLevel(new_level, old_level, skipsound)

    if self.owner.HUD.upgrademodulewidget then
        self.owner.HUD.upgrademodulewidget:UpdateEnergyLevel(new_level, old_level, skipsound)
    end
end

function SecondaryStatusDisplays:SetUpgradeModuleMaxEnergyLevel(new_level, old_level)
    self.upgrademodulesdisplay:UpdateMaxEnergy(new_level, old_level)

    if self.owner.HUD.upgrademodulewidget then
        self.owner.HUD.upgrademodulewidget:UpdateMaxEnergy(new_level, old_level)
    end

    self:UpdateModuleOwnerDisplayPosition()
end

function SecondaryStatusDisplays:UpgradeModulesEnergyLevelDelta(data)
    local new_max_level = (data == nil and 0) or data.new_max_level
    local old_max_level = (data == nil and 0) or data.old_max_level
    local new_level = (data == nil and 0) or data.new_level
    local old_level = (data == nil and 0) or data.old_level

    if new_max_level ~= old_max_level then
        self:SetUpgradeModuleMaxEnergyLevel(new_max_level, old_max_level)
    end
    self:SetUpgradeModuleEnergyLevel(new_level, old_level)
end

----------------------------------------------------------------------------------------------------------

return SecondaryStatusDisplays
