-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_wendy_build.zip"),
	Asset("ANIM", "anim/wendy.zip"),
}

return CreatePrefabSkin("wendy_none",
{
	base_prefab = "wendy",
	type = "base",
	assets = assets,
	build_name = "wendy",
	rarity = "Common",
	skins = { ghost_skin = "ghost_wendy_build", normal_skin = "wendy", },
	torso_untuck_wide_builds = { "wendy", },
	has_alternate_for_body = { "wendy", },
	has_alternate_for_skirt = { "wendy", },
	release_group = 999,
})
