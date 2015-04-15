
local MakePlayerCharacter = require "prefabs/player_common"

local assets = 
{
    Asset("ANIM", "anim/webber.zip"),
    Asset("ANIM", "anim/ghost_webber_build.zip"),
	Asset("SOUND", "sound/webber.fsb"),
}

local prefabs = 
{
}


local function custom_init(inst)
end

return MakePlayerCharacter("webber", prefabs, assets, custom_init, {}) 
