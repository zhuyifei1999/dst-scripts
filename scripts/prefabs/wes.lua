local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/player_mime.zip"),
}

local prefabs =
{
    "balloons_empty",
}

local function common_postinit(inst)
    inst:AddTag("mime")
    inst:AddTag("balloonomancer")
end

local function master_postinit(inst)
    inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * .75)
    inst.components.hunger:SetMax(TUNING.WILSON_HUNGER * .75)
    inst.components.combat.damagemultiplier = .75
    inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE * 1.25)
    inst.components.sanity:SetMax(TUNING.WILSON_SANITY * .75)
end

return MakePlayerCharacter("wes", prefabs, assets, common_postinit, master_postinit, prefabs)
