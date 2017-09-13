local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/winona.fsb"),
}

local prefabs =
{
    "sewing_tape",
}

local start_inv =
{
    "sewing_tape",
    "sewing_tape",
    "sewing_tape",
}

local function common_postinit(inst)
    inst:AddTag("handyperson")
    inst:AddTag("fastbuilder")
end

local function master_postinit(inst)
    inst.components.grue:SetResistance(1)
end

return MakePlayerCharacter("winona", prefabs, assets, common_postinit, master_postinit, start_inv)
