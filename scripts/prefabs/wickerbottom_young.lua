local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wickerbottom_young.zip"),
	Asset("ANIM", "anim/ghost_wickerbottom_build.zip"),
}

local skins =
{
	normal_skin = "wickerbottom_young",
	ghost_skin = "ghost_wickerbottom_build",
}

local base_prefab = "wickerbottom"

local tags = {"WICKERBOTTOM", "CHARACTER"}

local ui_preview =
{
	build = "wickerbottom_young",
}

return CreatePrefabSkin("wickerbottom_young",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})