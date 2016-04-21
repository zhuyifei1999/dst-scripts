local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wx78_survivor.zip"),
	Asset("ANIM", "anim/ghost_wx78_build.zip"),
}

local skins =
{
	normal_skin = "wx78_survivor",
	ghost_skin = "ghost_wx78_build",
}

local base_prefab = "wx78"

local tags = {"WX78", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "wx78_survivor",
}


return CreatePrefabSkin("wx78_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wx78_survivor" },
	has_alternate_for_body = { "wx78_survivor" },

	rarity = "Elegant",
})