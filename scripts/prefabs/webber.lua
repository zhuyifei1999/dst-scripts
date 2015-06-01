local MakePlayerCharacter = require "prefabs/player_common"

local assets =
{
    Asset("ANIM", "anim/webber.zip"),
    Asset("SOUND", "sound/webber.fsb"),
    Asset("ANIM", "anim/beard_silk.zip"),
    Asset("ANIM", "anim/ghost_webber_build.zip"),
}

local prefabs =
{
    "silk",
}

local start_inv =
{
    "spidereggsack",
    "monstermeat",
    "monstermeat",
}

local function common_postinit(inst)
    inst:AddTag("spiderwhisperer")
    inst:AddTag("monster")
    inst:AddTag(UPGRADETYPES.SPIDER.."_upgradeuser")
end

--tune the beard economy...
local BEARD_DAYS = { 3, 6, 9 }
local BEARD_BITS = { 1, 3, 6 }

local function OnResetBeard(inst)
    inst.AnimState:ClearOverrideSymbol("beard")
end

local function OnGrowShortBeard(inst)
    inst.AnimState:OverrideSymbol("beard", "beard_silk", "beardsilk_short")
    inst.components.beard.bits = BEARD_BITS[1]
end

local function OnGrowMediumBeard(inst)
    inst.AnimState:OverrideSymbol("beard", "beard_silk", "beardsilk_medium")
    inst.components.beard.bits = BEARD_BITS[2]
end

local function OnGrowLongBeard(inst)
    inst.AnimState:OverrideSymbol("beard", "beard_silk", "beardsilk_long")
    inst.components.beard.bits = BEARD_BITS[3]
end

local function master_postinit(inst)
    inst.talker_path_override = "dontstarve_DLC001/characters/"

    inst.components.eater.strongstomach = true

    inst.components.health:SetMaxHealth(TUNING.WEBBER_HEALTH)
    inst.components.hunger:SetMax(TUNING.WEBBER_HUNGER)
    inst.components.sanity:SetMax(TUNING.WEBBER_SANITY)

    inst:AddComponent("beard")
    inst.components.beard.insulation_factor = TUNING.WEBBER_BEARD_INSULATION_FACTOR
    inst.components.beard.onreset = OnResetBeard
    inst.components.beard.prize = "silk"
    inst.components.beard:AddCallback(BEARD_DAYS[1], OnGrowShortBeard)
    inst.components.beard:AddCallback(BEARD_DAYS[2], OnGrowMediumBeard)
    inst.components.beard:AddCallback(BEARD_DAYS[3], OnGrowLongBeard)

    inst.components.locomotor:SetTriggersCreep(false)
end

return MakePlayerCharacter("webber", prefabs, assets, common_postinit, master_postinit, start_inv)
