local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/willow_survivor.zip"),
	Asset("ANIM", "anim/ghost_willow_build.zip"),
}

local skins =
{
	normal_skin = "willow_survivor",
	ghost_skin = "ghost_willow_build",
}

local base_prefab = "willow"

local tags = {"WILLOW", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "willow_survivor",
}

return CreatePrefabSkin("willow_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	rarity = "Elegant",
})