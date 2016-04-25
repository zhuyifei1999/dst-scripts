local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wes_shadow.zip"),
	Asset("ANIM", "anim/ghost_wes_build.zip"),
}

local skins =
{
	normal_skin = "wes_shadow",
	ghost_skin = "ghost_wes_build",
}

local base_prefab = "wes"

local tags = {"WES", "CHARACTER", "SHADOW"}

local ui_preview =
{
	build = "wes_shadow",
}

return CreatePrefabSkin("wes_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wes_shadow" },
	has_alternate_for_body = { "wes_shadow" },
	has_alternate_for_skirt = { "wes_shadow" },

	rarity = "Elegant",
})