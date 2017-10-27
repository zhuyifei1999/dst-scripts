-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_wilson_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wilson_shadow.zip"),
}

return CreatePrefabSkin("wilson_shadow",
{
	base_prefab = "wilson",
	type = "base",
	assets = assets,
	build_name = "wilson_shadow",
	rarity = "Elegant",
	skin_tags = { "SHADOW", "BASE", "CHARACTER", "WILSON", },
	skins = { ghost_skin = "ghost_wilson_build", normal_skin = "wilson_shadow", },
	marketable = true,
	release_group = 6,
})
