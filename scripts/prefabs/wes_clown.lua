local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wes_clown.zip"),
	Asset("ANIM", "anim/ghost_wes_build.zip"),
}

local skins =
{
	normal_skin = "wes_clown",
	ghost_skin = "ghost_wes_build",
}

local base_prefab = "wes"

local tags = {"WES", "CHARACTER"}

local ui_preview =
{
	build = "wes_clown",
}

return CreatePrefabSkin("wes_clown",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wes_clown" },
	has_alternate_for_body = { "wes_clown" },
	has_alternate_for_skirt = { "wes_clown" },
		
	skip_item_gen = false,
	skip_giftable_gen = false,
})