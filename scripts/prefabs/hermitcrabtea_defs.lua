local TEA_DEFS =
{
    {
        name = "petals",
        buff = "hermitcrabtea_petals_buff",
    },
    {
        name = "petals_evil",
        buff = "hermitcrabtea_petals_evil_buff",
    },
    {
        name = "foliage",
        -- buff = "",
    },
    {
        name = "succulent_picked",
        -- buff = "",
        --
        temperaturedelta = TUNING.HERMITCRABTEA_COLD_BONUS_TEMP,
        temperatureduration = TUNING.HERMITCRABTEA_TEMP_TIME,
    },
    {
        name = "firenettles",
        -- buff = "",
        --
        temperaturedelta = TUNING.HERMITCRABTEA_HOT_BONUS_TEMP,
        temperatureduration = TUNING.HERMITCRABTEA_TEMP_TIME,
    },
    {
        name = "tillweed",
        buff = "hermitcrabtea_tillweed_buff",
    },
    {
        name = "moon_tree_blossom",
        -- buff = "",
    },
    {
        name = "forgetmelots",
        buff = "hermitcrabtea_forgetmelots_buff",
    },
}

---------------------

-- petals

local function Petals_OnTick(inst, target)
    if not IsEntityDead(inst) and inst.components.sanity ~= nil and not inst:HasTag("playerghost") then
        target.components.sanity:DoDelta(TUNING.HERMITCRAB_PETALTEA_SANITY_DELTA)
    else
        inst.components.debuff:Stop()
    end
end

-- petals_evil

local function Petals_Evil_OnTick(inst, target)
    if not IsEntityDead(inst) and inst.components.sanity ~= nil and not inst:HasTag("playerghost") then
        target.components.sanity:DoDelta(TUNING.HERMITCRAB_EVILPETALTEA_SANITY_DELTA)
    else
        inst.components.debuff:Stop()
    end
end

-- tillweed

local function Tillweed_OnTick(inst, target)
    if not IsEntityDead(inst) and not inst:HasTag("playerghost") then
        target.components.health:DoDelta(TUNING.HERMITCRAB_TILLWEEDTEA_HEALTH_DELTA, nil, "hermitcrabtea_tillweed")
    else
        inst.components.debuff:Stop()
    end
end

-- forgetmelots

local function ForgetMeLots_OnTick(inst, target)
    if not IsEntityDead(inst) and inst.components.sanity ~= nil and not inst:HasTag("playerghost") then
        target.components.sanity:DoDelta(TUNING.HERMITCRAB_FORGETMELOTTEA_SANITY_DELTA)
    else
        inst.components.debuff:Stop()
    end
end

local BUFF_DEFS =
{
    {
        name = "petals",
        duration = TUNING.HERMITCRAB_PETALTEA_DURATION,
        --
        onattachedfn = function(inst, target)
            inst.task = inst:DoPeriodicTask(TUNING.HERMITCRAB_PETALTEA_TICK_RATE, Petals_OnTick, nil, target)
        end,

        onextendedfn = function(inst, target)
            inst.task:Cancel()
            inst.task = inst:DoPeriodicTask(TUNING.HERMITCRAB_PETALTEA_TICK_RATE, Petals_OnTick, nil, target)
        end,
    },

    {
        name = "petals_evil",
        duration = TUNING.HERMITCRAB_EVILPETALTEA_DURATION,
        --
        onattachedfn = function(inst, target)
            inst.task = inst:DoPeriodicTask(TUNING.HERMITCRAB_EVILPETALTEA_TICK_RATE, Petals_Evil_OnTick, nil, target)
        end,

        onextendedfn = function(inst, target)
            inst.task:Cancel()
            inst.task = inst:DoPeriodicTask(TUNING.HERMITCRAB_EVILPETALTEA_TICK_RATE, Petals_Evil_OnTick, nil, target)
        end,
    },

    {
        name = "foliage",
        --
        onattachedfn = function(inst)

        end,

        onextendedfn = function(inst)

        end,

        ondetachedfn = function(inst)

        end,
    },

    {
        name = "succulent_picked",
        --
        onattachedfn = function(inst)

        end,

        onextendedfn = function(inst)

        end,

        ondetachedfn = function(inst)

        end,
    },

    {
        name = "firenettles",
        --
        onattachedfn = function(inst)

        end,

        onextendedfn = function(inst)

        end,

        ondetachedfn = function(inst)

        end,
    },

    {
        name = "tillweed",
        duration = TUNING.HERMITCRAB_TILLWEEDTEA_DURATION,
        --
        onattachedfn = function(inst, target)
            inst.task = inst:DoPeriodicTask(TUNING.HERMITCRAB_TILLWEEDTEA_TICK_RATE, Tillweed_OnTick, nil, target)
        end,

        onextendedfn = function(inst, target)
            inst.task:Cancel()
            inst.task = inst:DoPeriodicTask(TUNING.HERMITCRAB_TILLWEEDTEA_TICK_RATE, Tillweed_OnTick, nil, target)
        end,
    },

    {
        name = "moon_tree_blossom",
        --
        onattachedfn = function(inst)

        end,

        onextendedfn = function(inst)

        end,

        ondetachedfn = function(inst)

        end,
    },

    {
        name = "forgetmelots",
        duration = TUNING.HERMITCRAB_FORGETMELOTTEA_DURATION,
        --
        onattachedfn = function(inst, target)
            inst.task = inst:DoPeriodicTask(TUNING.HERMITCRAB_FORGETMELOTTEA_TICK_RATE, ForgetMeLots_OnTick, nil, target)
        end,

        onextendedfn = function(inst, target)
            inst.task:Cancel()
            inst.task = inst:DoPeriodicTask(TUNING.HERMITCRAB_FORGETMELOTTEA_TICK_RATE, ForgetMeLots_OnTick, nil, target)
        end,
    },
}

--[[ Omar: For searching
hermitcrabtea_petals
hermitcrabtea_petals_evil
hermitcrabtea_foliage
hermitcrabtea_succulent_picked
hermitcrabtea_firenettles
hermitcrabtea_tillweed
hermitcrabtea_moon_tree_blossom
hermitcrabtea_forgetmelots

hermitcrabtea_petals_buff
hermitcrabtea_petals_evil_buff
hermitcrabtea_foliage_buff
hermitcrabtea_succulent_picked_buff
hermitcrabtea_firenettles_buff
hermitcrabtea_tillweed_buff
hermitcrabtea_moon_tree_blossom_buff
hermitcrabtea_forgetmelots_buff
]]
return {
    teas = TEA_DEFS,
    buffs = BUFF_DEFS,
}