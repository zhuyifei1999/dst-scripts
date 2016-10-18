local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/willow_dragonfly.zip"),
	Asset("ANIM", "anim/ghost_willow_build.zip"),
}

local skins =
{
	normal_skin = "willow_dragonfly",
	ghost_skin = "ghost_willow_build",
}

local base_prefab = "willow"

local tags = {"WILLOW", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "willow_dragonfly",
}

return CreatePrefabSkin("willow_dragonfly",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",	
	rarity = "Event",
})