-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/catcoonhat_trapperup_rooster.zip"),
}

return CreatePrefabSkin("catcoonhat_trapperup_rooster",
{
	base_prefab = "catcoonhat",
	type = "item",
	assets = assets,
	build_name = "catcoonhat_trapperup_rooster",
	rarity = "Distinguished",
	init_fn = function(inst) catcoonhat_init_fn(inst, "catcoonhat_trapperup_rooster") end,
	skin_tags = { "CATCOONHAT", "LUNAR", "CRAFTABLE", },
	marketable = true,
	release_group = 23,
})
