local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_shadow.zip"),
	Asset("ANIM", "anim/ghost_webber_build.zip"),
}

local skins =
{
	normal_skin = "webber_shadow",
	ghost_skin = "ghost_webber_build",
}

local base_prefab = "webber"

local tags = {"WEBBER", "CHARACTER"}

local ui_preview =
{
	build = "webber_shadow",
}

return CreatePrefabSkin("webber_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "webber_shadow" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})