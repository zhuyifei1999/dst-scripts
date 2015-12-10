local assets =
{
	Asset("ANIM", "anim/wickerbottom.zip"),
	Asset("ANIM", "anim/ghost_wickerbottom_build.zip"),
}

local skins =
{
	normal_skin = "wickerbottom",
	ghost_skin = "ghost_wickerbottom_build",
}

local base_prefab = "wickerbottom"

local tags = {"WICKERBOTTOM", "CHARACTER"}

return CreatePrefabSkin("wickerbottom_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
	
	torso_tuck_builds = { "wickerbottom" },
	has_alternate_body = { "wickerbottom" },
	
	skip_item_gen = true,
	skip_giftable_gen = true,
})