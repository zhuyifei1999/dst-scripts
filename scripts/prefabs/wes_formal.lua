local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wes_formal.zip"),
	Asset("ANIM", "anim/ghost_wes_build.zip"),
}

local skins =
{
	normal_skin = "wes_formal",
	ghost_skin = "ghost_wes_build",
}

local base_prefab = "wes"

local tags = {"WES", "CHARACTER"}

local ui_preview =
{
	build = "wes_formal",
}

return CreatePrefabSkin("wes_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wes_formal" },
	has_alternate_body = { "wes_formal" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
	
	rarity = "Elegant",
})