local SPACER = 40
local TEXT_SPACER = SPACER * 0.75
local LOCK_SPACER = SPACER * 0.85

local ORIGIN_CIRCUITRY_X = -149 -- Bigger top gear.
local ORIGIN_CIRCUITRY_Y = 105

local ORIGIN_CIRCUITRY_FLOATING_1_X = -203 -- Left most floating gear moving right.
local ORIGIN_CIRCUITRY_FLOATING_1_Y = 56
local ORIGIN_CIRCUITRY_FLOATING_2_X = ORIGIN_CIRCUITRY_FLOATING_1_X + 42
local ORIGIN_CIRCUITRY_FLOATING_2_Y = ORIGIN_CIRCUITRY_FLOATING_1_Y - 37
local ORIGIN_CIRCUITRY_FLOATING_3_X = ORIGIN_CIRCUITRY_FLOATING_1_X + 91
local ORIGIN_CIRCUITRY_FLOATING_3_Y = ORIGIN_CIRCUITRY_FLOATING_1_Y - 8
local ORIGIN_CIRCUITRY_FLOATING_4_X = ORIGIN_CIRCUITRY_FLOATING_1_X + 139
local ORIGIN_CIRCUITRY_FLOATING_4_Y = ORIGIN_CIRCUITRY_FLOATING_1_Y - 41

local ORIGIN_CHASSIS_SMALL_X = 25 -- Small bottom gear.
local ORIGIN_CHASSIS_SMALL_Y = 16
local ORIGIN_CHASSIS_BIG_X = ORIGIN_CHASSIS_SMALL_X -- Bigger top gear.
local ORIGIN_CHASSIS_BIG_Y = ORIGIN_CHASSIS_SMALL_Y + 65

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

-- FIXME(JBK): WX: Final pass: Rename icons to skill tree skill names.

local function BuildSkillsData(SkillTreeFns)
    local skills = {
        -- FIXME(JBK): WX: Remove these temporary beta locks!
        wx78_beta_lock = {
            desc = "Coming soon.",
            pos = {ORIGIN_ALLEGIANCE_X - LOCK_SPACER * 0.5, ORIGIN_ALLEGIANCE_Y - LOCK_SPACER * 0.5},
            group = GROUPS.ALLEGIANCE,
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                return false
            end,
        },
        ------------------------------------------------------------------------------------------------------------------------
        -- CIRCUITRY
        ------------------------------------------------------------------------------------------------------------------------
        -- Gear 1 
        wx78_circuitry_halfmoduleuses = {
            title = STRINGS.SKILLTREE.WX78.WX78_HALF_MODULE_USES_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_HALF_MODULE_USES_DESC,
            icon = "wx78_reduce_break",
            pos = {ORIGIN_CIRCUITRY_FLOATING_1_X, ORIGIN_CIRCUITRY_FLOATING_1_Y},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
        },

        wx78_circuitry_fastercharge = {
            title = STRINGS.SKILLTREE.WX78.WX78_FASTER_CHARGE_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_FASTER_CHARGE_DESC,
            icon = "wx78_fast_regen",
            pos = {ORIGIN_CIRCUITRY_FLOATING_2_X, ORIGIN_CIRCUITRY_FLOATING_2_Y},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,

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

        wx78_circuitry_unpluganycircuit = {
            title = STRINGS.SKILLTREE.WX78.WX78_UNPLUG_ANY_CIRCUIT_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_UNPLUG_ANY_CIRCUIT_DESC,
            icon = "wx78_right_to_modify",
            pos = {ORIGIN_CIRCUITRY_FLOATING_3_X, ORIGIN_CIRCUITRY_FLOATING_3_Y},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
        },

        wx78_circuitry_lesschargeloss = {
            title = STRINGS.SKILLTREE.WX78.WX78_LESS_CHARGE_LOSS_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_LESS_CHARGE_LOSS_DESC,
            icon = "wx78_half_removal",
            pos = {ORIGIN_CIRCUITRY_FLOATING_4_X, ORIGIN_CIRCUITRY_FLOATING_4_Y},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
        },

        -- Gear 2
        wx78_circuitry_alphabuffs_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_ALPHA_CIRCUIT_BUFFS_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ALPHA_CIRCUIT_BUFFS_1_DESC,
            icon = "wx78_circuit_alpha_1",
            pos = {ORIGIN_CIRCUITRY_X - SPACER, ORIGIN_CIRCUITRY_Y + SPACER * 0.5},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
            connects = {
                "wx78_circuitry_alphabuffs_2",
            },
        },

        wx78_circuitry_alphabuffs_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_ALPHA_CIRCUIT_BUFFS_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ALPHA_CIRCUIT_BUFFS_2_DESC,
            icon = "wx78_circuit_alpha_2",
            pos = {ORIGIN_CIRCUITRY_X - SPACER, ORIGIN_CIRCUITRY_Y + SPACER * 1.5},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            connects = {
                "wx78_circuitry_slot_1",
            },
        },

        wx78_circuitry_betabuffs_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_BETA_CIRCUIT_BUFFS_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_BETA_CIRCUIT_BUFFS_1_DESC,
            icon = "wx78_circuit_beta_1",
            pos = {ORIGIN_CIRCUITRY_X, ORIGIN_CIRCUITRY_Y},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
            connects = {
                "wx78_circuitry_betabuffs_2",
            },
        },

        wx78_circuitry_betabuffs_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_BETA_CIRCUIT_BUFFS_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_BETA_CIRCUIT_BUFFS_2_DESC,
            icon = "wx78_circuit_beta_2",
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
            icon = "wx78_circuit_gamma_1",
            pos = {ORIGIN_CIRCUITRY_X + SPACER, ORIGIN_CIRCUITRY_Y + SPACER * 0.5},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            root = true,
            connects = {
                "wx78_circuitry_gammabuffs_2",
            },
        },

        wx78_circuitry_gammabuffs_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_GAMMA_CIRCUIT_BUFFS_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_GAMMA_CIRCUIT_BUFFS_2_DESC,
            icon = "wx78_circuit_gamma_2",
            pos = {ORIGIN_CIRCUITRY_X + SPACER, ORIGIN_CIRCUITRY_Y + SPACER * 1.5},
            group = GROUPS.CIRCUITRY,
            tags = {GROUPS.CIRCUITRY},
            connects = {
                "wx78_circuitry_slot_1",
            },
        },

        wx78_circuitry_slot_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_CIRCUITRY_SLOT_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_CIRCUITRY_SLOT_1_DESC,
            icon = "wx78_add_slot",
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
            icon = "wx78_body_multiple",
            pos = {ORIGIN_CHASSIS_SMALL_X, ORIGIN_CHASSIS_SMALL_Y},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS, "wx78_maxbody"},
            root = true,
            defaultfocus = true,
            connects = {
                "wx78_ghostrevive_1",
            },
        },
        wx78_ghostrevive_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_1_DESC,
            icon = "wx78_ghost_revive_1",
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
            icon = "wx78_ghost_revive_2",
            pos = {ORIGIN_CHASSIS_BIG_X + SPACER, ORIGIN_CHASSIS_BIG_Y + SPACER * 0.5},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS},
            connects = {
                "wx78_ghostrevive_3",
            },
        },
        wx78_ghostrevive_3 = {
            title = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_3_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_GHOSTREVIVE_3_DESC,
            icon = "wx78_ghost_revive_3",
            pos = {ORIGIN_CHASSIS_BIG_X + SPACER, ORIGIN_CHASSIS_BIG_Y + SPACER * 1.5},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS},
        },
        wx78_extrabody_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_2_DESC,
            icon = "wx78_body_plus_one",
            pos = {ORIGIN_CHASSIS_BIG_X - SPACER, ORIGIN_CHASSIS_BIG_Y + SPACER * 0.5},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS, "wx78_maxbody"},
            connects = {
                "wx78_extrabody_3",
            },
        },
        wx78_extrabody_3 = {
            title = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_3_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_EXTRABODY_3_DESC,
            icon = "wx78_body_plus_one",
            pos = {ORIGIN_CHASSIS_BIG_X - SPACER, ORIGIN_CHASSIS_BIG_Y + SPACER * 1.5},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS, "wx78_maxbody"},
            connects = {
                "wx78_remotebodyswap",
            },
        },
        wx78_remotebodyswap = {
            title = STRINGS.SKILLTREE.WX78.WX78_REMOTEBODYSWAP_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_REMOTEBODYSWAP_DESC,
            icon = "wx78_body_swap_knowledge",
            pos = {ORIGIN_CHASSIS_BIG_X, ORIGIN_CHASSIS_BIG_Y + SPACER * 2},
            group = GROUPS.CHASSIS,
            tags = {GROUPS.CHASSIS},
        },
        wx78_bodycircuits = {
            title = STRINGS.SKILLTREE.WX78.WX78_BODYCIRCUITS_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_BODYCIRCUITS_DESC,
            icon = "wx78_backup_beta",
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
			icon = "wx78_drone_scout_1",
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
			icon = "wx78_drone_scout_2",
            pos = {ORIGIN_DRONES_BOTTOMLEFT_X, ORIGIN_DRONES_BOTTOMLEFT_Y},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
        },
        wx78_deliverydrone_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_DELIVERYDRONE_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_DELIVERYDRONE_1_DESC,
			icon = "wx78_drone_delivery_1",
            pos = {ORIGIN_DRONES_X - SPACER * 0.5, ORIGIN_DRONES_Y + SPACER * 0.5},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
            root = true,
            connects = {
                "wx78_deliverydrone_2",
            },
        },
        wx78_deliverydrone_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_DELIVERYDRONE_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_DELIVERYDRONE_2_DESC,
			icon = "wx78_drone_delivery_2",
            pos = {ORIGIN_DRONES_TOPRIGHT_X, ORIGIN_DRONES_TOPRIGHT_Y},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
        },
        wx78_zapdrone_1 = {
            title = STRINGS.SKILLTREE.WX78.WX78_ZAPDRONE_1_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ZAPDRONE_1_DESC,
			icon = "wx78_drone_zap_1",
            pos = {ORIGIN_DRONES_X + SPACER * 0.5, ORIGIN_DRONES_Y},
            group = GROUPS.DRONES,
            tags = {GROUPS.DRONES},
            root = true,
			onactivate = function(inst) inst:AddTag("drone_zap_user") end,
			ondeactivate = function(inst) inst:RemoveTag("drone_zap_user") end,
            connects = {
                "wx78_zapdrone_2",
            },
        },
        wx78_zapdrone_2 = {
            title = STRINGS.SKILLTREE.WX78.WX78_ZAPDRONE_2_TITLE,
            desc = STRINGS.SKILLTREE.WX78.WX78_ZAPDRONE_2_DESC,
			icon = "wx78_drone_zap_2",
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
                if true then return false end -- FIXME(JBK): WX: Remove this temporary lock!

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
            --icon = "wx78_allegiance_lunar",
            pos = {ORIGIN_ALLEGIANCE_X - 53, ORIGIN_ALLEGIANCE_Y},
            group = GROUPS.ALLEGIANCE,
            tags = {"lunar_favor", "allegiance"},
            locks = {"wx78_allegiance_lunar_lock_1",
                "wx78_beta_lock", -- FIXME(JBK): WX: Remove this temporary lock!
            },
            onactivate = function(inst)
                inst:AddTag("player_lunar_aligned")
                -- FIXME(JBK): WX: Perk.
            end,
            ondeactivate = function(inst)
                inst:RemoveTag("player_lunar_aligned")
                -- FIXME(JBK): WX: Perk.
            end,
        },
        ------------------------------------------------------------------------------------------------------------------------
        wx78_shadow_allegiance_lock_1 = {
            desc = STRINGS.SKILLTREE.WX78.WX78_SHADOW_ALLEGIANCE_LOCK_1_DESC,
            pos = {ORIGIN_ALLEGIANCE_X + 7, ORIGIN_ALLEGIANCE_Y - 18},
            group = "allegiance",
            tags = {"allegiance", "lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                if true then return false end -- FIXME(JBK): WX: Remove this temporary lock!

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
            --icon = "wx78_allegiance_shadow",
            pos = {ORIGIN_ALLEGIANCE_X + 50, ORIGIN_ALLEGIANCE_Y - 3},
            group = GROUPS.ALLEGIANCE,
            tags = {"shadow_favor", "allegiance"},
            locks = {"wx78_shadow_allegiance_lock_1",
                "wx78_beta_lock", -- FIXME(JBK): WX: Remove this temporary lock!
            },
            onactivate = function(inst)
                inst:AddTag("player_shadow_aligned")
                -- FIXME(JBK): WX: Perk.
            end,
            ondeactivate = function(inst)
                inst:RemoveTag("player_shadow_aligned")
                -- FIXME(JBK): WX: Perk.
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