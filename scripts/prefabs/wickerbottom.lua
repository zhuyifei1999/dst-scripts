local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/wickerbottom.fsb"),
    Asset("ANIM", "anim/player_knockedout_wickerbottom.zip"),
}

local prefabs =
{
    "book_birds",
    "book_tentacles",
    "book_gardening",
    "book_sleep",
    "book_brimstone",
}

local start_inv =
{
    "papyrus",
    "papyrus",
}

local function common_postinit(inst)
    inst:AddTag("insomniac")
    inst:AddTag("bookbuilder")
end

local function master_postinit(inst)
    inst:AddComponent("reader")
    
    inst.components.eater.stale_hunger = TUNING.WICKERBOTTOM_STALE_FOOD_HUNGER
    inst.components.eater.stale_health = TUNING.WICKERBOTTOM_STALE_FOOD_HEALTH
    inst.components.eater.spoiled_hunger = TUNING.WICKERBOTTOM_SPOILED_FOOD_HUNGER
    inst.components.eater.spoiled_health = TUNING.WICKERBOTTOM_SPOILED_FOOD_HEALTH

    inst.components.sanity:SetMax(TUNING.WICKERBOTTOM_SANITY)

    inst.components.builder.science_bonus = 1
end

return MakePlayerCharacter("wickerbottom", prefabs, assets, common_postinit, master_postinit, start_inv)
