local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/woodie_shadow.zip"),
	Asset("ANIM", "anim/ghost_woodie_build.zip"),
}

local skins =
{
	normal_skin = "woodie_shadow",
	ghost_skin = "ghost_woodie_build",
	werebeaver_skin = "werebeaver_build",
	ghost_werebeaver_skin = "ghost_werebeaver_build",
}

local base_prefab = "woodie"

local tags = {"WOODIE", "CHARACTER", "SHADOW"}

local ui_preview =
{
	build = "woodie_shadow",
}

return CreatePrefabSkin("woodie_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,

	rarity = "Elegant",
})