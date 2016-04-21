local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wendy_survivor.zip"),
	Asset("ANIM", "anim/ghost_wendy_build.zip"),
}

local skins =
{
	normal_skin = "wendy_survivor",
	ghost_skin = "ghost_wendy_build",
}

local base_prefab = "wendy"

local tags = {"WENDY", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "wendy_survivor",
}

return CreatePrefabSkin("wendy_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_untuck_builds = { "wendy_survivor" },

	rarity = "Elegant",
})