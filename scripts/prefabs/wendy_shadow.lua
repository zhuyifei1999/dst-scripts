local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wendy_shadow.zip"),
	Asset("ANIM", "anim/ghost_wendy_build.zip"),
}

local skins =
{
	normal_skin = "wendy_shadow",
	ghost_skin = "ghost_wendy_build",
}

local base_prefab = "wendy"

local tags = {"WENDY", "CHARACTER", "SHADOW"}

local ui_preview =
{
	build = "wendy_shadow",
}

return CreatePrefabSkin("wendy_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_untuck_builds = { "wendy_shadow" },

	rarity = "Elegant",
})