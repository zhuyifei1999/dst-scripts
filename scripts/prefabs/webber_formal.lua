local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_formal.zip"),
	Asset("ANIM", "anim/ghost_webber_build.zip"),
}

local skins =
{
	normal_skin = "webber_formal",
	ghost_skin = "ghost_webber_build",
}

local base_prefab = "webber"

local tags = {"WEBBER", "CHARACTER"}

local ui_preview =
{
	build = "webber_formal",
}

return CreatePrefabSkin("webber_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "webber_formal" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
	
	rarity = "Elegant",
})