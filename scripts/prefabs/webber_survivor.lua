local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_survivor.zip"),
	Asset("ANIM", "anim/ghost_webber_build.zip"),
}

local skins =
{
	normal_skin = "webber_survivor",
	ghost_skin = "ghost_webber_build",
}

local base_prefab = "webber"

local tags = {"WEBBER", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "webber_survivor",
}

return CreatePrefabSkin("webber_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "webber_survivor" },

	rarity = "Elegant",
})