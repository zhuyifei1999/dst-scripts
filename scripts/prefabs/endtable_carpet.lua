-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/endtable_carpet.zip"),
}

return CreatePrefabSkin("endtable_carpet",
{
	base_prefab = "endtable",
	type = "item",
	assets = assets,
	build_name = "endtable_carpet",
	rarity = "Distinguished",
	init_fn = function(inst) endtable_init_fn(inst, "endtable_carpet") end,
	skin_tags = { "ENDTABLE", "CRAFTABLE", },
	marketable = true,
	release_group = 18,
})
