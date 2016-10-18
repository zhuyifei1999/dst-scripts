local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_bat.zip"),
	Asset("ANIM", "anim/ghost_webber_build.zip"),
}

local skins =
{
	normal_skin = "webber_bat",
	ghost_skin = "ghost_webber_build",
}

local base_prefab = "webber"

local tags = {"WEBBER", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "webber_bat",
}

return CreatePrefabSkin("webber_bat",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	--torso_tuck_builds = { "webber_bat" },
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})