local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wendy_formal.zip"),
	Asset("ANIM", "anim/ghost_wendy_build.zip"),
}

local skins =
{
	normal_skin = "wendy_formal",
	ghost_skin = "ghost_wendy_build",
}

local base_prefab = "wendy"

local tags = {"WENDY", "CHARACTER", "FORMAL"}

local ui_preview =
{
	build = "wendy_formal",
}

return CreatePrefabSkin("wendy_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_untuck_builds = { "wendy_formal" },
	
	rarity = "Elegant",
})