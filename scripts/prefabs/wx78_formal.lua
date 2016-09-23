local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wx78_formal.zip"),
	Asset("ANIM", "anim/ghost_wx78_build.zip"),
}

local skins =
{
	normal_skin = "wx78_formal",
	ghost_skin = "ghost_wx78_build",
}

local base_prefab = "wx78"

local tags = {"WX78", "CHARACTER", "FORMAL"}

local ui_preview =
{
	build = "wx78_formal",
}


return CreatePrefabSkin("wx78_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	--torso_tuck_builds = { "wx78_formal" },
	has_alternate_for_body = { "wx78_formal" },
	
	feet_cuff_size = { wx78_formal = 3 },
	
	rarity = "Elegant",
})