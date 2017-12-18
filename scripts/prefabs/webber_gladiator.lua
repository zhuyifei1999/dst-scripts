-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_webber_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_gladiator.zip"),
	Asset("ATLAS_BUILD", "bigportraits/webber_gladiator.xml", 192),
}

return CreatePrefabSkin("webber_gladiator",
{
	base_prefab = "webber",
	type = "base",
	assets = assets,
	build_name = "webber_gladiator",
	rarity = "Elegant",
	rarity_modifier = "EventModifier",
	skin_tags = { "LAVA", "BASE", "CHARACTER", "WEBBER", },
	bigportrait = { build = "bigportraits/webber_gladiator.xml", symbol = "webber_gladiator_oval.tex"},
	skins = { ghost_skin = "ghost_webber_build", normal_skin = "webber_gladiator", },
	release_group = 32,
})
