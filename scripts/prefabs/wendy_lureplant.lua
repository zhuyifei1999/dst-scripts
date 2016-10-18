local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wendy_lureplant.zip"),
	Asset("ANIM", "anim/ghost_wendy_build.zip"),
}

local skins =
{
	normal_skin = "wendy_lureplant",
	ghost_skin = "ghost_wendy_build",
}

local base_prefab = "wendy"

local tags = {"WENDY", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "wendy_lureplant",
}

return CreatePrefabSkin("wendy_lureplant",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	has_alternate_for_body = { "wendy_lureplant" },
	torso_tuck_builds = { "wendy_lureplant" },
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})