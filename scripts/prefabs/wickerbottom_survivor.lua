local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wickerbottom_survivor.zip"),
	Asset("ANIM", "anim/ghost_wickerbottom_build.zip"),
}

local skins =
{
	normal_skin = "wickerbottom_survivor",
	ghost_skin = "ghost_wickerbottom_build",
}

local base_prefab = "wickerbottom"

local tags = {"WICKERBOTTOM", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "wickerbottom_survivor",
}

return CreatePrefabSkin("wickerbottom_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wickerbottom_survivor" },
	has_alternate_for_body = { "wickerbottom_survivor" },
	has_alternate_for_skirt = { "wickerbottom_survivor" },

	rarity = "Elegant",
})