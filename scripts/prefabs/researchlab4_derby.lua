-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/researchlab4_derby.zip"),
}

return CreatePrefabSkin("researchlab4_derby",
{
	base_prefab = "researchlab4",
	type = "item",
	assets = assets,
	build_name = "researchlab4_derby",
	rarity = "Elegant",
	init_fn = function(inst) researchlab4_init_fn(inst, "researchlab4_derby") end,
	release_group = 26,
})
