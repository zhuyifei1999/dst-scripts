local module_defs = require("wx78_moduledefs").module_definitions

local function on_charge_level_changed(self, new_charge, old_charge)
    local max_charge = self.max_charge
    self.inst:PushEvent("energylevelupdate", {
        new_level = new_charge,
        old_level = old_charge,
        old_max_level = max_charge,
        new_max_level = max_charge,
        isloading = self.isloading or nil,
    })
    if self.inst.wx78_classified ~= nil then
        self.inst.wx78_classified.currentenergylevel:set(new_charge)
    end
end

local function on_max_charge_changed(self, new_max, old_max)
    local charge = self.charge_level
    self.inst:PushEvent("energylevelupdate", {
        new_level = charge,
        old_level = charge,
        old_max_level = old_max,
        new_max_level = new_max,
        isloading = self.isloading or nil,
    })
    if self.inst.wx78_classified ~= nil then
        self.inst.wx78_classified.maxenergylevel:set(new_max)
    end
end

local function on_inspecting_changed(self, new_inspect, old_inspect)
    if self.inst.wx78_classified ~= nil then
        self.inst.wx78_classified.inspectupgrademodulebars:set(new_inspect)
    end
end

local UpgradeModuleOwner = Class(function(self, inst)
    self.inst = inst

    self.module_bars = {}
    for i, v in pairs(CIRCUIT_BARS) do
        self.module_bars[v] = {}
    end

    self.charge_level = 0
    self.max_charge = TUNING.WX78_INITIAL_MAXCHARGELEVEL

    self.inspecting = false -- Inspecting our modules
    self.inspecter = nil -- The inspecter

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("upgrademoduleowner")

    --self.onmoduleadded = nil
    --self.onmoduleremoved = nil
    --self.onallmodulespopped = nil
    --self.canupgradefn = nil
end,
nil,
{
    charge_level = on_charge_level_changed,
    max_charge = on_max_charge_changed,
    inspecting = on_inspecting_changed,
})

-- Remove Callbacks -----------------------------------------------------------------

function UpgradeModuleOwner:OnRemoveFromEntity()
    self.inst:RemoveTag("upgrademoduleowner")
    self.inst:RemoveTag("inspectingupgrademodules")
end

-------------------------------------------------------------------------------------

function UpgradeModuleOwner:StartInspecting(inspecter)
    if not self.inspecting then
        self.inst.SoundEmitter:PlaySound("WX_rework/module_tray/open")
        self.inst:AddTag("inspectingupgrademodules")
        self.inspecting = true
        self.inspecter = inspecter

        if inspecter.HUD then
			inspecter.HUD:ShowUpgradeModuleWidget()
        end

        return true
    end
end

function UpgradeModuleOwner:StopInspecting()
    if self.inspecting then
        self.inst.SoundEmitter:PlaySound("WX_rework/module_tray/close")
        self.inst:RemoveTag("inspectingupgrademodules")
        self.inspecting = false

        if self.inspecter.HUD then
            self.inspecter.HUD:CloseUpgradeModuleWidget()
        end

        self.inspecter = nil
    end
end

-------------------------------------------------------------------------------------

function UpgradeModuleOwner:GetModuleTypeCount(moduletype)
    local module_prefab = "wx78module_"..moduletype
    local count = 0

    for bartype, modules in pairs(self.module_bars) do
        local remaining_charge = self.charge_level
        for _, moduleent in ipairs(modules) do
            remaining_charge = remaining_charge - moduleent.components.upgrademodule.slots
            if remaining_charge < 0 then
                break
            elseif moduleent.prefab == module_prefab then
                count = count + 1
            end
        end
    end

    return count
end

function UpgradeModuleOwner:GetUsedSlotCount(bartype)
    local cost = 0

    for i, module in ipairs(self.module_bars[bartype]) do
        cost = cost + module.components.upgrademodule.slots
    end

    return cost
end

function UpgradeModuleOwner:GetAllModules()
    local modules = {}
    for moduletype, bar_modules in pairs(self.module_bars) do
        for i, moduleent in ipairs(bar_modules) do
            table.insert(modules, moduleent)
        end
    end
    return modules
end

function UpgradeModuleOwner:GetModules(bartype)
    return self.module_bars[bartype]
end

function UpgradeModuleOwner:GetNumModules(bartype)
    return #self.module_bars[bartype]
end

function UpgradeModuleOwner:GetModule(bartype, moduleindex)
    return self.module_bars[bartype][moduleindex]
end

function UpgradeModuleOwner:NumModules() -- DEPRECATED
    return 0
end

-------------------------------------------------------------------------------------

function UpgradeModuleOwner:CanUpgrade(module_instance)
    if self.canupgradefn ~= nil then
        return self.canupgradefn(self.inst, module_instance)
    else
        return true
    end
end

-------------------------------------------------------------------------------------

function UpgradeModuleOwner:UpdateActivatedModules(isloading)
    for bartype, modules in pairs(self.module_bars) do
        local remaining_charge = self.charge_level
        for _, module in ipairs(modules) do
            remaining_charge = remaining_charge - module.components.upgrademodule.slots
            if remaining_charge < 0 then
                module.components.upgrademodule:TryDeactivate()
            elseif not self.prevent_automatic_module_activations then
                module.components.upgrademodule:TryActivate(isloading)
            end
        end
    end
end

function UpgradeModuleOwner:SetAutomaticModuleActivations(enabled)
    self.prevent_automatic_module_activations = not enabled or nil
end

-------------------------------------------------------------------------------------

function UpgradeModuleOwner:PushModule(bartype, module, isloading)
    bartype = bartype or module.components.upgrademodule:GetType()
    local bar_modules = self.module_bars[bartype]
    table.insert(bar_modules, module)

    module.components.inventoryitem:RemoveFromOwner()
	module.components.upgrademodule:SetTarget(self.inst, isloading)

    self.inst:AddChild(module)
    module:RemoveFromScene()
    module.Transform:SetPosition(0, 0, 0)
    --module.Network:SetClassifiedTarget(self.inst)

    self:UpdateActivatedModules(isloading)

    if self.onmoduleadded then
        self.onmoduleadded(self.inst, module)
    end
end

function UpgradeModuleOwner:PopModule(bartype, index)
    local bar_modules = self.module_bars[bartype]
    local top_module, was_activated = nil, nil

    if #bar_modules > 0 then
        top_module = table.remove(bar_modules, index)

        self.inst:RemoveChild(top_module)
        top_module:ReturnToScene()
        top_module.Transform:SetPosition(self.inst.Transform:GetWorldPosition())

        if top_module.components.upgrademodule.activated then
            was_activated = true
        end
        top_module.components.upgrademodule:TryDeactivate()

        if self.onmoduleremoved then
            self.onmoduleremoved(self.inst, top_module)
        end

        -- Tell the module it's removed the very end; TryDeactivate needs the target,
        -- and the moduleremoved callback might want to access it too.
        top_module.components.upgrademodule:RemoveFromOwner()

        -- Re-settle our activated and de-activated modules, since one was removed from the table.
        self:UpdateActivatedModules()
    end

    return top_module, was_activated
end

function UpgradeModuleOwner:FindAndPopModule(moduletofind)
    for bartype, modules in pairs(self.module_bars) do
        for i, module in ipairs(modules) do
            if module == moduletofind then
                self:PopOneModule(bartype, i)
                return
            end
        end
    end
end

function UpgradeModuleOwner:PopAllModules(bartype)
    local popped_modules = {}
    local pop_all_bars = bartype == nil
    if pop_all_bars then
        for bar, modules in pairs(self.module_bars) do
            while #modules > 0 do
                local mod, activated = self:PopModule(bar, 1)
                table.insert(popped_modules, mod)
            end
        end

        if self.onallmodulespopped then
            self.onallmodulespopped(self.inst)
        end
    elseif #self.module_bars[bartype] > 0 then
        while #self.module_bars[bartype] > 0 do
            local mod, activated = self:PopModule(bartype, 1)
            table.insert(popped_modules, mod)
        end

        if self.onallmodulespopped then
            self.onallmodulespopped(self.inst)
        end
    end
    return popped_modules
end

function UpgradeModuleOwner:PopOneModule(bartype, index)
    local bar_modules = self.module_bars[bartype]

    if #bar_modules > 0 then
        local popped_module, was_activated = self:PopModule(bartype, index)

        if self.ononemodulepopped then
            self.ononemodulepopped(self.inst, popped_module, was_activated)
        end
    end

    return 0 -- This is the energy cost that is deprecated from this function handling it. Kept for now in case of mods
end

-------------------------------------------------------------------------------------

function UpgradeModuleOwner:SetMaxCharge(max_charge) -- This determines circuit slots too.
    local old_level = self.max_charge
    self.max_charge = max_charge

    -- Pop off modules that are over the new limit
    if old_level > self.max_charge then
        for bartype, modules in pairs(self.module_bars) do
            local remaining_level = self.max_charge
            for i, moduleent in ipairs(modules) do
                while moduleent ~= nil do
                    remaining_level = remaining_level - moduleent.components.upgrademodule.slots
                    if remaining_level < 0 then
                        self:PopOneModule(bartype, i)
                        moduleent = modules[i]
                    else
                        moduleent = nil
                    end
                end
            end
        end
    end
end

function UpgradeModuleOwner:SetChargeLevel(new_level)
    local old_level = self.charge_level
    self.charge_level = math.clamp(new_level, 0, self.max_charge)

    if old_level ~= self.charge_level then
        self:UpdateActivatedModules()
    end
end

function UpgradeModuleOwner:DoDeltaCharge(n)
    self:SetChargeLevel(self.charge_level + n)
end
UpgradeModuleOwner.AddCharge = UpgradeModuleOwner.DoDeltaCharge -- backwards compat

function UpgradeModuleOwner:IsChargeMaxed()
    return self.charge_level == self.max_charge
end
UpgradeModuleOwner.ChargeIsMaxed = UpgradeModuleOwner.IsChargeMaxed -- backwards compat

function UpgradeModuleOwner:IsChargeEmpty()
    return self.charge_level == 0
end

function UpgradeModuleOwner:GetChargeLevel()
    return self.charge_level
end

function UpgradeModuleOwner:GetMaxChargeLevel()
    return self.max_charge
end
-------------------------------------------------------------------------------------

function UpgradeModuleOwner:IsSwapping()
    return self.is_swapping
end
function UpgradeModuleOwner:SwapUpgradeModules(otherupgrademoduleowner)
    self.is_swapping = true
    otherupgrademoduleowner.is_swapping = true

    local our_modules = self:PopAllModules()
    local their_modules = otherupgrademoduleowner:PopAllModules()

    for i, module in ipairs(our_modules) do
        otherupgrademoduleowner:PushModule(nil, module)
    end

    for i, module in ipairs(their_modules) do
        self:PushModule(nil, module)
    end

    self.is_swapping = nil
    otherupgrademoduleowner.is_swapping = nil
end

---- SAVE/LOAD ----------------------------------------------------------------------

function UpgradeModuleOwner:OnSave()
    local data = {
        module_bars = {},
        charge_level = self.charge_level,
    }
    for i, v in pairs(CIRCUIT_BARS) do
        data.module_bars[v] = {}
    end
    local our_references = {}
    local saved_object_references = {}
    for bartype, modules in pairs(self.module_bars) do
        for i, module in ipairs(modules) do
            -- modules should persist so we're ok grabbing save records
            data.module_bars[bartype][i], saved_object_references = module:GetSaveRecord()
            if saved_object_references then
                for k, v in pairs(saved_object_references) do
                    table.insert(our_references, v)
                end
            end
        end
    end

    return data, our_references
end

function UpgradeModuleOwner:OnLoad(data, newents)
    self.isloading = true
    if data ~= nil then
        if data.charge_level ~= nil then
            self.charge_level = data.charge_level
        end

        if data.modules ~= nil then -- Backwards compat
            for _, module_record in ipairs(data.modules) do
				local _module = SpawnSaveRecord(module_record, newents)
				if _module then
					self:PushModule(nil, _module, true)
				end
			end
        elseif data.module_bars ~= nil then
            for bartype, modules in pairs(data.module_bars) do
                for i, module_record in ipairs(modules) do
                    local module = SpawnSaveRecord(module_record, newents)
                    if module ~= nil then
                        self:PushModule(bartype, module, true)
                    end
                end
            end
        end
    end
    self.isloading = nil
end

-------------------------------------------------------------------------------------

function UpgradeModuleOwner:GetDebugString()
    local str = "Charge: " .. tostring(self.charge_level)

    for bartype, modules in pairs(self.module_bars) do
        str = str .. "\nCircuit Bar ("..bartype.."): " .. tostring(#modules)

        for _, module in ipairs(modules) do
            str = str .. "\n  " .. tostring(module.prefab)
        end
    end

    return str
end

-------------------------------------------------------------------------------------

return UpgradeModuleOwner