local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wes_survivor.zip"),
	Asset("ANIM", "anim/ghost_wes_build.zip"),
}

local skins =
{
	normal_skin = "wes_survivor",
	ghost_skin = "ghost_wes_build",
}

local base_prefab = "wes"

local tags = {"WES", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "wes_survivor",
}

return CreatePrefabSkin("wes_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wes_survivor" },
	has_alternate_for_body = { "wes_survivor" },
	has_alternate_for_skirt = { "wes_survivor" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,

	rarity = "Elegant",
})