local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/waxwell_survivor.zip"),
	Asset("ANIM", "anim/ghost_waxwell_build.zip"),
}

local skins =
{
	normal_skin = "waxwell_survivor",
	ghost_skin = "ghost_waxwell_build",
}

local base_prefab = "waxwell"

local tags = {"WAXWELL", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "waxwell_survivor",
}

return CreatePrefabSkin("waxwell_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "waxwell_survivor" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,

	rarity = "Elegant",
})