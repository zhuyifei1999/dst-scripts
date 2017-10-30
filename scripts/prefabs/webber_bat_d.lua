-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_webber_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_bat_d.zip"),
}

return CreatePrefabSkin("webber_bat_d",
{
	base_prefab = "webber",
	type = "base",
	assets = assets,
	build_name = "webber_bat_d",
	rarity = "Elegant",
	skin_tags = { "COSTUME", "BASE", "CHARACTER", "WEBBER", },
	skins = { ghost_skin = "ghost_webber_build", normal_skin = "webber_bat_d", },
	torso_tuck_builds = { "webber_bat_d", },
	marketable = true,
	release_group = 31,
})
