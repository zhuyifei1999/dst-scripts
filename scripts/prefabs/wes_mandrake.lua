local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wes_mandrake.zip"),
	Asset("ANIM", "anim/ghost_wes_build.zip"),
}

local skins =
{
	normal_skin = "wes_mandrake",
	ghost_skin = "ghost_wes_build",
}

local base_prefab = "wes"

local tags = {"WES", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "wes_mandrake",
}

return CreatePrefabSkin("wes_mandrake",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	has_alternate_for_body = { "wes_mandrake" },
	has_alternate_for_skirt = { "wes_mandrake" },
	torso_tuck_builds = { "wes_mandrake" },
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})