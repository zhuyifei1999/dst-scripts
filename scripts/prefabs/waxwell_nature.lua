-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_waxwell_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/waxwell_nature.zip"),
	Asset("ATLAS_BUILD", "bigportraits/waxwell_nature.xml", 192),
}

return CreatePrefabSkin("waxwell_nature",
{
	base_prefab = "waxwell",
	type = "base",
	assets = assets,
	build_name = "waxwell_nature",
	rarity = "Elegant",
	rarity_modifier = "Seasonal",
	skin_tags = { "VARG", "BASE", "CHARACTER", "WAXWELL", },
	bigportrait = { build = "bigportraits/waxwell_nature.xml", symbol = "waxwell_nature_oval.tex"},
	skins = { ghost_skin = "ghost_waxwell_build", normal_skin = "waxwell_nature", },
	release_group = 40,
})