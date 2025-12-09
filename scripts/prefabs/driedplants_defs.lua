local DRIED_DEFS =
{
    {
        name = "petals",
        --
        build = "flower_petals",
    },
    {
        name = "petals_evil",
        --
        bank = "flower_petals_evil",
        build = "flower_petals_evil",
    },
    {
        name = "foliage",
    },
    {
        name = "succulent_picked",
    },
    {
        name = "firenettles",
        healthvalue = -TUNING.HEALING_SMALL,
        sanityvalue = -TUNING.SANITY_TINY,
        oneaten = function(inst, eater)
        	if not eater:HasTag("plantkin") then
                eater:AddDebuff("firenettle_toxin", "firenettle_toxin")
        	end
        end,
    },
    {
        name = "tillweed",
    },
    {
        name = "moon_tree_blossom",
        --
        bank = "moon_tree_petal",
        build = "moon_tree_petal",
    },
    {
        name = "forgetmelots",
    },
}

--[[ Omar: For searching
petals_dried
petals_evil_dried
foliage_dried
succulent_picked_dried
firenettles_dried
tillweed_dried
moon_tree_blossom_dried
forgetmelots_dried
]]
return {
    plants = DRIED_DEFS
}