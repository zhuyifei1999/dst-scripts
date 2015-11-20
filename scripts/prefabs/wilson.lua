local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("ANIM", "anim/wilson.zip"),
    Asset("ANIM", "anim/beard.zip"),

    Asset("ANIM", "anim/ghost_wilson_build.zip"),
}

local prefabs =
{
    "beardhair",
}

local function common_postinit(inst)
    inst:AddTag("ghostwithhat")

    --bearded (from beard component) added to pristine state for optimization
    inst:AddTag("bearded")
end

local function OnResetBeard(inst)
    inst.AnimState:ClearOverrideSymbol("beard")
end

--tune the beard economy...
local BEARD_DAYS = { 4, 8, 16 }
local BEARD_BITS = { 1, 3,  9 }

local function OnGrowShortBeard(inst)
    inst.AnimState:OverrideSymbol("beard", "beard", "beard_short")
    inst.components.beard.bits = BEARD_BITS[1]
end

local function OnGrowMediumBeard(inst)
    inst.AnimState:OverrideSymbol("beard", "beard", "beard_medium")
    inst.components.beard.bits = BEARD_BITS[2]
end

local function OnGrowLongBeard(inst)
    inst.AnimState:OverrideSymbol("beard", "beard", "beard_long")
    inst.components.beard.bits = BEARD_BITS[3]
end

local function master_postinit(inst)
    inst:AddComponent("beard")
    inst.components.beard.onreset = OnResetBeard
    inst.components.beard.prize = "beardhair"
    inst.components.beard:AddCallback(BEARD_DAYS[1], OnGrowShortBeard)
    inst.components.beard:AddCallback(BEARD_DAYS[2], OnGrowMediumBeard)
    inst.components.beard:AddCallback(BEARD_DAYS[3], OnGrowLongBeard)
end

return MakePlayerCharacter("wilson", prefabs, assets, common_postinit, master_postinit)
