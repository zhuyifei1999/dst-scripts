local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wilson_shadow.zip"),
	Asset("ANIM", "anim/ghost_wilson_build.zip"),
}

local skins =
{
	normal_skin = "wilson_shadow",
	ghost_skin = "ghost_wilson_build",
}

local base_prefab = "wilson"

local tags = {"WILSON", "CHARACTER", "SHADOW"}

local ui_preview =
{
	build = "wilson_shadow",
}

return CreatePrefabSkin("wilson_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,

	rarity = "Elegant",
})