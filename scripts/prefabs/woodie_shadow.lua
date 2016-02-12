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
}

local base_prefab = "woodie"

local tags = {"WOODIE", "CHARACTER"}

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
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})