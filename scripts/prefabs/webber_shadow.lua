-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_webber_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_shadow.zip"),
}

return CreatePrefabSkin("webber_shadow",
{
	base_prefab = "webber",
	type = "base",
	assets = assets,
	build_name = "webber_shadow",
	rarity = "Elegant",
	skins = { ghost_skin = "ghost_webber_build", normal_skin = "webber_shadow", },
	torso_tuck_builds = { "webber_shadow", },
	marketable = true,
	release_group = 6,
})
