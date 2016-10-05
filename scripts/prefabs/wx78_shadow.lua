local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wx78_shadow.zip"),
	Asset("ANIM", "anim/ghost_wx78_build.zip"),
}

local skins =
{
	normal_skin = "wx78_shadow",
	ghost_skin = "ghost_wx78_build",
}

local base_prefab = "wx78"

local tags = {"WX78", "CHARACTER", "SHADOW"}

local ui_preview =
{
	build = "wx78_shadow",
}


return CreatePrefabSkin("wx78_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	--torso_tuck_builds = { "wx78_shadow" },
	has_alternate_for_body = { "wx78_shadow" },

	rarity = "Elegant",
})