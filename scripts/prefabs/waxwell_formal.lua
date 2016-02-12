local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/waxwell_formal.zip"),
	Asset("ANIM", "anim/ghost_waxwell_build.zip"),
}

local skins =
{
	normal_skin = "waxwell_formal",
	ghost_skin = "ghost_waxwell_build",
}

local base_prefab = "waxwell"

local tags = {"WAXWELL", "CHARACTER"}

local ui_preview =
{
	build = "waxwell_formal",
}

return CreatePrefabSkin("waxwell_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "waxwell_formal" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})