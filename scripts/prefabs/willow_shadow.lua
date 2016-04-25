local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/willow_shadow.zip"),
	Asset("ANIM", "anim/ghost_willow_build.zip"),
}

local skins =
{
	normal_skin = "willow_shadow",
	ghost_skin = "ghost_willow_build",
}

local base_prefab = "willow"

local tags = {"WILLOW", "CHARACTER", "SHADOW"}

local ui_preview =
{
	build = "willow_shadow",
}

return CreatePrefabSkin("willow_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	--torso_tuck_builds = { "willow_shadow" },

	rarity = "Elegant",
})