local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wathgrithr_deerclops.zip"),
	Asset("ANIM", "anim/ghost_wathgrithr_build.zip"),
}

local skins =
{
	normal_skin = "wathgrithr_deerclops",
	ghost_skin = "ghost_wathgrithr_build",
}

local base_prefab = "wathgrithr"

local tags = {"WATHGRITHR", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "wathgrithr_deerclops",
}


return CreatePrefabSkin("wathgrithr_deerclops",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})