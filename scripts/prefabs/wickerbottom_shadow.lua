local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wickerbottom_shadow.zip"),
	Asset("ANIM", "anim/ghost_wickerbottom_build.zip"),
}

local skins =
{
	normal_skin = "wickerbottom_shadow",
	ghost_skin = "ghost_wickerbottom_build",
}

local base_prefab = "wickerbottom"

local tags = {"WICKERBOTTOM", "CHARACTER"}

local ui_preview =
{
	build = "wickerbottom_shadow",
}

return CreatePrefabSkin("wickerbottom_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wickerbottom_shadow" },
	has_alternate_for_body = { "wickerbottom_shadow" },
	has_alternate_for_skirt = { "wickerbottom_shadow" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})