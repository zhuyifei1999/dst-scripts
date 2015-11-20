local MakePlayerCharacter = require("prefabs/player_common")

local function DoCharacter(name)
	return MakePlayerCharacter(name, {}, 
	{
		Asset("ANIM", "anim/"..name..".zip"),
		Asset("SOUND", "sound/"..name..".fsb")
	})
end

return DoCharacter("wilton")