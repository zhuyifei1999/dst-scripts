-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_webber_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_formal.zip"),
}

return CreatePrefabSkin("webber_formal",
{
	base_prefab = "webber",
	type = "base",
	assets = assets,
	build_name = "webber_formal",
	rarity = "Elegant",
	skins = { ghost_skin = "ghost_webber_build", normal_skin = "webber_formal", },
	torso_tuck_builds = { "webber_formal", },
	marketable = true,
	release_group = 2,
})
