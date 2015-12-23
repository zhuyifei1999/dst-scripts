local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/waxwell.zip"),
	Asset("SOUND", "sound/maxwell.fsb"),

    Asset("ANIM", "anim/ghost_waxwell_build.zip"),
}

local prefabs = 
{
	"shadowwaxwell",	
}

local start_inv = 
{
	"waxwelljournal",
	"nightsword",
	"armor_sanity",
	"purplegem",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
}

local function common_postinit(inst)
    inst:AddTag("ghostwithhat")
end

local function master_postinit(inst)
	inst:AddComponent("reader")

	inst.components.sanity.dapperness = TUNING.DAPPERNESS_HUGE
	inst.components.health:SetMaxHealth(TUNING.WILSON_HEALTH * .5)
	inst.soundsname = "maxwell"
end

return MakePlayerCharacter("waxwell", prefabs, assets, common_postinit, master_postinit, start_inv)
