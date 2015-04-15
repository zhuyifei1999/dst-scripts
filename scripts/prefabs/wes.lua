local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    --Asset("ANIM", "anim/wendy.zip"),
    Asset("ANIM", "anim/wes.zip"),
	Asset("ANIM", "anim/player_mime.zip"),    

    Asset("ANIM", "anim/ghost_wes_build.zip"),
}

local prefabs =
{
    "balloons_empty",
}

local function common_postinit(inst)
    inst:AddTag("mime")
end

local function master_postinit(inst)
	inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * .75)
	inst.components.hunger:SetMax(TUNING.WILSON_HUNGER * .75)
	inst.components.combat.damagemultiplier = .75
	inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE * 1.25)
	inst.components.sanity:SetMax(TUNING.WILSON_SANITY * .75)
end

return MakePlayerCharacter("wes", prefabs, assets, common_postinit, master_postinit, prefabs)