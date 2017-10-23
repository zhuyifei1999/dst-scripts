-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/tophat_derby.zip"),
}

return CreatePrefabSkin("tophat_derby",
{
	base_prefab = "tophat",
	type = "item",
	assets = assets,
	build_name = "tophat_derby",
	rarity = "Elegant",
	init_fn = function(inst) tophat_init_fn(inst, "tophat_derby") end,
	marketable = true,
	release_group = 14,
	granted_items = { "researchlab4_derby", },
})
