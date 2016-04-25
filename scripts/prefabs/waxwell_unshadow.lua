local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/waxwell_unshadow.zip"),
	Asset("ANIM", "anim/ghost_waxwell_build.zip"),
}

local skins =
{
	normal_skin = "waxwell_unshadow",
	ghost_skin = "ghost_waxwell_build",
}

local base_prefab = "waxwell"

local tags = {"WAXWELL", "CHARACTER", "SHADOW"}

local ui_preview =
{
	build = "waxwell_unshadow",
}

return CreatePrefabSkin("waxwell_unshadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "waxwell_unshadow" },

	rarity = "Elegant",
})