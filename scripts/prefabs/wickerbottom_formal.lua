local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wickerbottom_formal.zip"),
	Asset("ANIM", "anim/ghost_wickerbottom_build.zip"),
}

local skins =
{
	normal_skin = "wickerbottom_formal",
	ghost_skin = "ghost_wickerbottom_build",
}

local base_prefab = "wickerbottom"

local tags = {"WICKERBOTTOM", "CHARACTER"}

local ui_preview =
{
	build = "wickerbottom_formal",
}

return CreatePrefabSkin("wickerbottom_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wickerbottom_formal" },
	has_alternate_body = { "wickerbottom_formal" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
	
	rarity = "Elegant",
})