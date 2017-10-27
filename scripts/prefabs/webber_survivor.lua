-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_webber_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_survivor.zip"),
}

return CreatePrefabSkin("webber_survivor",
{
	base_prefab = "webber",
	type = "base",
	assets = assets,
	build_name = "webber_survivor",
	rarity = "Elegant",
	skin_tags = { "SURVIVOR", "BASE", "CHARACTER", "WEBBER", },
	skins = { ghost_skin = "ghost_webber_build", normal_skin = "webber_survivor", },
	torso_tuck_builds = { "webber_survivor", },
	marketable = true,
	release_group = 4,
})
