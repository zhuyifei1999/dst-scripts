-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_wx78_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wx78_gladiator.zip"),
	Asset("ATLAS_BUILD", "bigportraits/wx78_gladiator.xml", 128),
}

return CreatePrefabSkin("wx78_gladiator",
{
	base_prefab = "wx78",
	type = "base",
	assets = assets,
	build_name = "wx78_gladiator",
	rarity = "Elegant",
	rarity_modifier = "EventModifier",
	bigportrait = { build = "bigportraits/wx78_gladiator.xml", symbol = "wx78_gladiator_oval.tex"},
	skins = { ghost_skin = "ghost_wx78_build", normal_skin = "wx78_gladiator", },
	feet_cuff_size = { wx78_gladiator = 3, },
	release_group = 32,
})
