local MakePlayerCharacter = require "prefabs/player_common"

local assets = 
{
    Asset("ANIM", "anim/wathgrithr.zip"),
    Asset("ANIM", "anim/ghost_wigfrid_build.zip"),
	Asset("SOUND", "sound/wathgrithr.fsb"),
}

local prefabs = 
{
}


local function custom_init(inst)
end

return MakePlayerCharacter("wathgrithr", prefabs, assets, custom_init, {}) 
