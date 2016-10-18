local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wickerbottom_lightninggoat.zip"),
	Asset("ANIM", "anim/ghost_wickerbottom_build.zip"),
}

local skins =
{
	normal_skin = "wickerbottom_lightninggoat",
	ghost_skin = "ghost_wickerbottom_build",
}

local base_prefab = "wickerbottom"

local tags = {"WICKERBOTTOM", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "wickerbottom_lightninggoat",
}

return CreatePrefabSkin("wickerbottom_lightninggoat",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wickerbottom_lightninggoat" },
	has_alternate_for_body = { "wickerbottom_lightninggoat" },
	has_alternate_for_skirt = { "wickerbottom_lightninggoat" },
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})