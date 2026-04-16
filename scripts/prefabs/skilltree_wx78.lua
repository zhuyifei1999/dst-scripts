local WX78Common = require("prefabs/wx78_common")

local SPACER = 40
local TEXT_SPACER = SPACER * 0.75
local LOCK_SPACER = SPACER * 0.85

local BIG_GEAR_SHIFT = SPACER * 0.05

local ORIGIN_CIRCUITRY_X = -149 -- Bigger top gear.
local ORIGIN_CIRCUITRY_Y = 16 + 65 + BIG_GEAR_SHIFT --105 + BIG_GEAR_SHIFT

local ORIGIN_CIRCUITRY_FLOATING_1_X = -206 -- Left most floating gear moving right.
local ORIGIN_CIRCUITRY_FLOATING_1_Y = 31
local ORIGIN_CIRCUITRY_FLOATING_2_X = ORIGIN_CIRCUITRY_FLOATING_1_X + 118
local ORIGIN_CIRCUITRY_FLOATING_2_Y = ORIGIN_CIRCUITRY_FLOATING_1_Y + 5

local ORIGIN_CHASSIS_SMALL_X = 25 -- Small bottom gear.
local ORIGIN_CHASSIS_SMALL_Y = 16
local ORIGIN_CHASSIS_BIG_X = ORIGIN_CHASSIS_SMALL_X -- Bigger top gear.
local ORIGIN_CHASSIS_BIG_Y = ORIGIN_CHASSIS_SMALL_Y + 65 + BIG_GEAR_SHIFT

-- Inside middle medium gear.
local ORIGIN_DRONES_X = 165
local ORIGIN_DRONES_Y = 62
-- Orbiting gears.
local ORIGIN_DRONES_BOTTOMLEFT_X = ORIGIN_DRONES_X - 65
local ORIGIN_DRONES_BOTTOMLEFT_Y = ORIGIN_DRONES_Y - 55
local ORIGIN_DRONES_BOTTOMRIGHT_X = ORIGIN_DRONES_X + 61
local ORIGIN_DRONES_BOTTOMRIGHT_Y = ORIGIN_DRONES_Y - 49
local ORIGIN_DRONES_TOPRIGHT_X = ORIGIN_DRONES_X + 51
local ORIGIN_DRONES_TOPRIGHT_Y = ORIGIN_DRONES_Y + 57

local ORIGIN_ALLEGIANCE_X = 180
local ORIGIN_ALLEGIANCE_Y = 183


local GROUPS = {
    CIRCUITRY = "circuitry",
    CHASSIS = "chassis",
    DRONES = "drones",
    ALLEGIANCE = "allegiance",
}

local ORDERS = {
    {GROUPS.CIRCUITRY, {ORIGIN_CIRCUITRY_X, ORIGIN_CIRCUITRY_Y + SPACER * 2.4 + LOCK_SPACER * 0 + TEXT_SPACER}},
    {GROUPS.CHASSIS, {ORIGIN_CHASSIS_BIG_X, ORIGIN_CHASSIS_BIG_Y + SPACER * 2.4 + LOCK_SPACER * 0 + TEXT_SPACER}},
    {GROUPS.DRONES, {ORIGIN_DRONES_X - SPACER * 0.55, ORIGIN_DRONES_Y + SPACER * 0.78 + LOCK_SPACER * 0 + TEXT_SPACER}},
    {GROUPS.ALLEGIANCE, {ORIGIN_ALLEGIANCE_X, ORIGIN_ALLEGIANCE_Y + SPACER * 0 + LOCK_SPACER * 0 + TEXT_SPACER}},
}


local function ActivateBetaCircuitsInBody(item, player)
    if item.TryToActivateBetaCircuitStates then
        item:TryToActivateBetaCircuitStates()
    end
end
local function DeactivateBetaCircuitsInBody(item, player)
    if item.TryToDeactivateBetaCircuitStates then
        item:TryToDeactivateBetaCircuitStates()
    end
end

local function CheckCircuitSlotStatesInBody(item, player)
    if item.CheckCircuitSlotStatesFrom then
        item:CheckCircuitSlotStatesFrom(player)
    end
end

local function ActivateGestaltTrapSocketsInBody(item, player)
    WX78Common.ActivateSocketsIn(item, 1, "socket_gestalttrapper")
end

local function DeactivateGestaltTrapSocketsInBody(item, player)
    WX78Common.DeactivateSocketsIn(item, 1)
end

local function ActivateShadowSocketsInBody(item, player)
    WX78Common.ActivateSocketsIn(item, 1, "socket_shadow")
end

local function DeactivateSocketsInBody(item, player)
    WX78Common.DeactivateSocketsIn(item, 1)
end

local function OnBackupBodyMaxCountLowered(inst)
    if inst.wx78_classified then
        local maxbodies = (inst.components.skilltreeupdater == nil and 0) or inst.components.skilltreeupdater:CountSkillTag("wx78_maxbody")
        inst.wx78_classified:DetachBodiesToMaximumCount(maxbodies)
    end
end

local function BuildSkillsData(SkillTreeFns)
    local skills = {
        ------------------------------------------------------------------------------------------------------------------------
        -- CIRCUITRY
        ------------------------------------------------------------------------------------------------------------------------
        -- Gear 1 

        wx78_circuitry_betterunplug = {
            title = STRINGS.SKILLTREE.WX78.WX78_BETTER_UNPLUG_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_BETTER_UNPLUG_DESC,
            icon = "wx78_circuitry_betterunplug",
            pos = {ORIGIN_CIRCUITRY_FLOATING_1_X, ORIGIN_CIRCUITRY_FLOATING_1_Y},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
        },

        wx78_circuitry_bettercharge = {
            title = STRINGS.SKILLTREE.WX78.WX78_BETTER_CHARGE_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_BETTER_CHARGE_DESC,
            icon = "wx78_circuitry_bettercharge",
            pos = {ORIGIN_CIRCUITRY_FLOATING_2_X, ORIGIN_CIRCUITRY_FLOATING_2_Y},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
            forced_focus = {
                up = "wx78_circuitry_betabuffs_1",
            },

            onactivate = function(inst, fromload)
                if not fromload then
                    local chargetime = inst.components.timer:GetTimeLeft("chargeregenupdate")
                    if chargetime and chargetime > 0 then
                        inst.components.timer:SetTimeLeft("chargeregenupdate", chargetime / TUNING.SKILLS.WX78.FASTER_CHARGE_MULTIPLIER)
                    end
                end
            end,
            ondeactivate = function(inst, fromload)
                if not fromload then
                    local chargetime = inst.components.timer:GetTimeLeft("chargeregenupdate")
                    if chargetime and chargetime > 0 then
                        inst.components.timer:SetTimeLeft("chargeregenupdate", chargetime * TUNING.SKILLS.WX78.FASTER_CHARGE_MULTIPLIER)
                    end
                end
            end,
        },

        -- Gear 2
        wx78_circuitry_alphabuffs_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_ALPHA_CIRCUIT_BUFFS_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ALPHA_CIRCUIT_BUFFS_1_DESC,
            icon = "wx78_circuitry_alphabuffs_1",
            pos = {ORIGIN_CIRCUITRY_X - SPACER, ORIGIN_CIRCUITRY_Y + SPACER * 0.5 - BIG_GEAR_SHIFT},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
            connects = {
                "wx78_circuitry_alphabuffs_2",
            },
            forced_focus = {
                down = "wx78_circuitry_betterunplug",
            },
        },

        wx78_circuitry_alphabuffs_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_ALPHA_CIRCUIT_BUFFS_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ALPHA_CIRCUIT_BUFFS_2_DESC,
            icon = "wx78_circuitry_alphabuffs_2",
            pos = {ORIGIN_CIRCUITRY_X - SPACER, ORIGIN_CIRCUITRY_Y + SPACER * 1.5 - BIG_GEAR_SHIFT},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            connects = {
                "wx78_circuitry_slot_1",
            },
        },

        wx78_circuitry_betabuffs_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_BETA_CIRCUIT_BUFFS_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_BETA_CIRCUIT_BUFFS_1_DESC,
            icon = "wx78_circuitry_betabuffs_1",
            pos = {ORIGIN_CIRCUITRY_X, ORIGIN_CIRCUITRY_Y},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
            connects = {
                "wx78_circuitry_betabuffs_2",
            },
            forced_focus = {
                down = "wx78_circuitry_bettercharge",
            },
        },

        wx78_circuitry_betabuffs_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_BETA_CIRCUIT_BUFFS_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_BETA_CIRCUIT_BUFFS_2_DESC,
            icon = "wx78_circuitry_betabuffs_2",
            pos = {ORIGIN_CIRCUITRY_X, ORIGIN_CIRCUITRY_Y + SPACER},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            connects = {
                "wx78_circuitry_slot_1",
            },
        },

        wx78_circuitry_gammabuffs_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_GAMMA_CIRCUIT_BUFFS_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_GAMMA_CIRCUIT_BUFFS_1_DESC,
            icon = "wx78_circuitry_gammabuffs_1",
            pos = {ORIGIN_CIRCUITRY_X + SPACER, ORIGIN_CIRCUITRY_Y + SPACER * 0.5 - BIG_GEAR_SHIFT},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
            connects = {
                "wx78_circuitry_gammabuffs_2",
            },
            forced_focus = {
                down = "wx78_circuitry_betterunplug",
                right = "wx78_extrabody_2",
            },
        },

        wx78_circuitry_gammabuffs_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_GAMMA_CIRCUIT_BUFFS_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_GAMMA_CIRCUIT_BUFFS_2_DESC,
            icon = "wx78_circuitry_gammabuffs_2",
            pos = {ORIGIN_CIRCUITRY_X + SPACER, ORIGIN_CIRCUITRY_Y + SPACER * 1.5 - BIG_GEAR_SHIFT},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            connects = {
                "wx78_circuitry_slot_1",
            },
        },

        wx78_circuitry_slot_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_CIRCUITRY_SLOT_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_CIRCUITRY_SLOT_1_DESC,
            icon = "wx78_circuitry_slot_1",
            pos = {ORIGIN_CIRCUITRY_X, ORIGIN_CIRCUITRY_Y + SPACER * 2},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},

            onactivate = function(inst)
                inst.components.upgrademoduleowner:SetMaxCharge(TUNING.WX78_MAXCHARGELEVEL_SKILL)
                if TheWorld.components.linkeditemmanager then
                    TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", CheckCircuitSlotStatesInBody)
                end
            end,
            ondeactivate = function(inst)
                inst.components.upgrademoduleowner:SetMaxCharge(TUNING.WX78_INITIAL_MAXCHARGELEVEL)
                if TheWorld.components.linkeditemmanager then
                    TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", CheckCircuitSlotStatesInBody)
                end
            end,
        },

        ------------------------------------------------------------------------------------------------------------------------
        -- CHASSIS
        ------------------------------------------------------------------------------------------------------------------------
        wx78_extrabody_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_1_DESC,
            icon = "wx78_extrabody_1",
            pos = {ORIGIN_CHASSIS_SMALL_X, ORIGIN_CHASSIS_SMALL_Y},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS, "wx78_maxbody"},
            root = true,
            defaultfocus = true,
            connects = {
                "wx78_ghostrevive_1",
            },
            ondeactivate = function(inst)
                OnBackupBodyMaxCountLowered(inst)
            end,
        },
        wx78_ghostrevive_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_1_DESC,
            icon = "wx78_ghostrevive_1",
            pos = {ORIGIN_CHASSIS_BIG_X, ORIGIN_CHASSIS_BIG_Y},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS},
            connects = {
                "wx78_extrabody_2",
                "wx78_bodycircuits",
                "wx78_ghostrevive_2",
            },
        },
        wx78_ghostrevive_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_2_DESC,
            icon = "wx78_ghostrevive_2",
            pos = {ORIGIN_CHASSIS_BIG_X + SPACER, ORIGIN_CHASSIS_BIG_Y + SPACER * 0.5 - BIG_GEAR_SHIFT},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS},
            connects = {
                "wx78_ghostrevive_3",
            },
        },
        wx78_ghostrevive_3 = {
            title = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_3_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_3_DESC,
            icon = "wx78_ghostrevive_3",
            pos = {ORIGIN_CHASSIS_BIG_X + SPACER, ORIGIN_CHASSIS_BIG_Y + SPACER * 1.5 - BIG_GEAR_SHIFT},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS},
        },
        wx78_extrabody_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_2_DESC,
            icon = "wx78_extrabody_2",
            pos = {ORIGIN_CHASSIS_BIG_X - SPACER, ORIGIN_CHASSIS_BIG_Y + SPACER * 0.5 - BIG_GEAR_SHIFT},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS, "wx78_maxbody"},
            connects = {
                "wx78_extrabody_3",
            },
            ondeactivate = function(inst)
                OnBackupBodyMaxCountLowered(inst)
            end,
        },
        wx78_extrabody_3 = {
            title = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_3_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_3_DESC,
            icon = "wx78_extrabody_2",
            pos = {ORIGIN_CHASSIS_BIG_X - SPACER, ORIGIN_CHASSIS_BIG_Y + SPACER * 1.5 - BIG_GEAR_SHIFT},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS, "wx78_maxbody"},
            forced_focus = {
                left = "wx78_circuitry_gammabuffs_2",
            },
            connects = {
                "wx78_remotebodyswap",
            },
            ondeactivate = function(inst)
                OnBackupBodyMaxCountLowered(inst)
            end,
        },
        wx78_remotebodyswap = {
            title = STRINGS.SKILLTREE.WX78.WX78_REMOTEBODYSWAP_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_REMOTEBODYSWAP_DESC,
            icon = "wx78_remotebodyswap",
            pos = {ORIGIN_CHASSIS_BIG_X, ORIGIN_CHASSIS_BIG_Y + SPACER * 2},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS},
        },
        wx78_bodycircuits = {
            title = STRINGS.SKILLTREE.WX78.WX78_BODYCIRCUITS_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_BODYCIRCUITS_DESC,
            icon = "wx78_bodycircuits",
            pos = {ORIGIN_CHASSIS_BIG_X, ORIGIN_CHASSIS_BIG_Y + SPACER},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS},
            onactivate = function(inst)
                if TheWorld.components.linkeditemmanager then
                    TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", ActivateBetaCircuitsInBody)
                end
            end,
            ondeactivate = function(inst)
                if TheWorld.components.linkeditemmanager then
                    TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", DeactivateBetaCircuitsInBody)
                end
            end,
        },
        ------------------------------------------------------------------------------------------------------------------------
        -- DRONES
        ------------------------------------------------------------------------------------------------------------------------
        wx78_scoutdrone_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_SCOUTDRONE_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_SCOUTDRONE_1_DESC,
			icon = "wx78_scoutdrone_1",
            pos = {ORIGIN_DRONES_X - SPACER * 0.5, ORIGIN_DRONES_Y - SPACER * 0.5},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
            root = true,
            connects = {
                "wx78_scoutdrone_2",
            },
        },
        wx78_scoutdrone_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_SCOUTDRONE_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_SCOUTDRONE_2_DESC,
			icon = "wx78_scoutdrone_2",
            pos = {ORIGIN_DRONES_BOTTOMLEFT_X, ORIGIN_DRONES_BOTTOMLEFT_Y},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
        },
        wx78_deliverydrone_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_DELIVERYDRONE_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_DELIVERYDRONE_1_DESC,
			icon = "wx78_deliverydrone_1",
            pos = {ORIGIN_DRONES_X - SPACER * 0.5, ORIGIN_DRONES_Y + SPACER * 0.5},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
            root = true,
            connects = {
                "wx78_deliverydrone_2",
            },
            forced_focus = {
                right = "wx78_deliverydrone_2",
            },
        },
        wx78_deliverydrone_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_DELIVERYDRONE_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_DELIVERYDRONE_2_DESC,
			icon = "wx78_deliverydrone_2",
            pos = {ORIGIN_DRONES_TOPRIGHT_X, ORIGIN_DRONES_TOPRIGHT_Y},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
            forced_focus = {
                up = "wx78_allegiance_shadow",
                down = "wx78_zapdrone_1",
                left = "wx78_deliverydrone_1",
            },
        },
        wx78_zapdrone_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_ZAPDRONE_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ZAPDRONE_1_DESC,
			icon = "wx78_zapdrone_1",
            pos = {ORIGIN_DRONES_X + SPACER * 0.5, ORIGIN_DRONES_Y},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
            root = true,
			onactivate = function(inst) inst:AddTag("drone_zap_user") end,
			ondeactivate = function(inst) inst:RemoveTag("drone_zap_user") end,
            connects = {
                "wx78_zapdrone_2",
            },
            forced_focus = {
                up = "wx78_deliverydrone_2",
                down = "wx78_zapdrone_2",
            },
        },
        wx78_zapdrone_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_ZAPDRONE_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ZAPDRONE_2_DESC,
			icon = "wx78_zapdrone_2",
            pos = {ORIGIN_DRONES_BOTTOMRIGHT_X, ORIGIN_DRONES_BOTTOMRIGHT_Y},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
        },
        ------------------------------------------------------------------------------------------------------------------------
        -- ALLEGIANCE
        ------------------------------------------------------------------------------------------------------------------------
        wx78_allegiance_lunar_lock_1 = {
            desc = STRINGS.SKILLTREE.WX78.WX78_LUNAR_ALLEGIANCE_LOCK_1_DESC,
            pos = {ORIGIN_ALLEGIANCE_X - 12, ORIGIN_ALLEGIANCE_Y + 9},
            group = "allegiance",
            tags = {"allegiance", "lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                local maxbodies = SkillTreeFns.CountTags(prefabname, "wx78_maxbody", activatedskills)
                if maxbodies == 0 then
                    return false
                end

                local shadow_skills = SkillTreeFns.CountTags(prefabname, "shadow_favor", activatedskills)
                if shadow_skills > 0 then
                    return false
                end

                if readonly then
                    return "question"
                end

                return TheGenericKV:GetKV("celestialchampion_killed") == "1"
            end,
        },
        wx78_allegiance_lunar = {
            title = STRINGS.SKILLTREE.WX78.WX78_ALLEGIANCE_LUNAR_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ALLEGIANCE_LUNAR_DESC,
            icon = "wx78_allegiance_lunar",
            pos = {ORIGIN_ALLEGIANCE_X - 53, ORIGIN_ALLEGIANCE_Y},
            group = GROUPS.ALLEGIANCE,
            tags = {"lunar_favor", "allegiance"},
            forced_focus = {
                down = "wx78_deliverydrone_1",
            },
            locks = {"wx78_allegiance_lunar_lock_1"},
            onactivate = function(inst)
                inst:AddTag("player_lunar_aligned")
                if inst.components.damagetyperesist ~= nil then
                    inst.components.damagetyperesist:AddResist("lunar_aligned", inst, TUNING.SKILLS.WX78.ALLEGIANCE_LUNAR_RESIST, "allegiance_lunar")
                end
                if inst.components.damagetypebonus ~= nil then
                    inst.components.damagetypebonus:AddBonus("shadow_aligned", inst, TUNING.SKILLS.WX78.ALLEGIANCE_VS_SHADOW_BONUS, "allegiance_lunar")
                end

                if TheWorld.components.linkeditemmanager then
                    TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", ActivateGestaltTrapSocketsInBody)
                end
            end,
            ondeactivate = function(inst)
                inst:RemoveTag("player_lunar_aligned")
                if inst.components.damagetyperesist ~= nil then
                    inst.components.damagetyperesist:RemoveResist("lunar_aligned", inst, "allegiance_lunar")
                end
                if inst.components.damagetypebonus ~= nil then
                    inst.components.damagetypebonus:RemoveBonus("shadow_aligned", inst, "allegiance_lunar")
                end

                if inst.components.leader ~= nil then
                    for k in pairs(inst.components.leader.followers) do
                        if k:HasTag("possessedbody") then
                            inst.components.leader:RemoveFollower(k)
                        end
                    end
                end

                if TheWorld.components.linkeditemmanager then
                    TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", DeactivateGestaltTrapSocketsInBody)
                end
            end,
        },
        ------------------------------------------------------------------------------------------------------------------------
        wx78_shadow_allegiance_lock_1 = {
            --desc = STRINGS.SKILLTREE.WX78.WX78_SHADOW_ALLEGIANCE_LOCK_1_DESC,
            desc = STRINGS.SKILLTREE.TEMPORARILY_DISABLED, -- FIXME(JBK): WX: Remove this when finished.
            pos = {ORIGIN_ALLEGIANCE_X + 7, ORIGIN_ALLEGIANCE_Y - 18},
            group = "allegiance",
            tags = {"allegiance", "lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                if true then -- FIXME(JBK): WX: Remove this when finished.
                    return false
                end

                local maxbodies = SkillTreeFns.CountTags(prefabname, "wx78_maxbody", activatedskills)
                if maxbodies == 0 then
                    return false
                end

                local lunar_skills = SkillTreeFns.CountTags(prefabname, "lunar_favor", activatedskills)
                if lunar_skills > 0 then
                    return false
                end

                if readonly then
                    return "question"
                end

                return TheGenericKV:GetKV("fuelweaver_killed") == "1"
            end,
        },
        wx78_allegiance_shadow = {
            title = STRINGS.SKILLTREE.WX78.WX78_ALLEGIANCE_SHADOW_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ALLEGIANCE_SHADOW_DESC,
            icon = "wx78_allegiance_shadow",
            pos = {ORIGIN_ALLEGIANCE_X + 50, ORIGIN_ALLEGIANCE_Y - 3},
            group = GROUPS.ALLEGIANCE,
            tags = {"shadow_favor", "allegiance"},
            locks = {"wx78_shadow_allegiance_lock_1"},
            onactivate = function(inst)
                inst:AddTag("player_shadow_aligned")
                if inst.components.damagetyperesist ~= nil then
                    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.SKILLS.WX78.ALLEGIANCE_SHADOW_RESIST, "allegiance_shadow")
                end
                if inst.components.damagetypebonus ~= nil then
                    inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.SKILLS.WX78.ALLEGIANCE_VS_LUNAR_BONUS, "allegiance_shadow")
                end

                WX78Common.ActivateSocketsIn(inst, 1, "socket_shadow")
                if TheWorld.components.linkeditemmanager then
                    TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", ActivateShadowSocketsInBody)
                end
            end,
            ondeactivate = function(inst)
                inst:RemoveTag("player_shadow_aligned")
                if inst.components.damagetyperesist ~= nil then
                    inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "allegiance_shadow")
                end
                if inst.components.damagetypebonus ~= nil then
                    inst.components.damagetypebonus:RemoveBonus("lunar_aligned", inst, "allegiance_shadow")
                end

                WX78Common.DeactivateSocketsIn(inst, 1)
                if TheWorld.components.linkeditemmanager then
                    TheWorld.components.linkeditemmanager:ForEachLinkedItemForPlayerOfPrefab(inst, "wx78_backupbody", DeactivateSocketsInBody)
                end
            end,
        },
    }

    return {
        SKILLS = skills,
        ORDERS = ORDERS,
    }
end

--------------------------------------------------------------------------------------------------

return BuildSkillsData