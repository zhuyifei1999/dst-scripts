local assets =
{
	Asset("ANIM", "anim/wathgrithr.zip"),
	Asset("ANIM", "anim/ghost_wathgrithr_build.zip"),
}

local skins =
{
	normal_skin = "wathgrithr",
	ghost_skin = "ghost_wathgrithr_build",
}

local base_prefab = "wathgrithr"

local tags = {"WATHGRITHR", "CHARACTER"}

return CreatePrefabSkin("wathgrithr_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
})