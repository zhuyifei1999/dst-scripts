-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/treasurechest_posh.zip"),
}

return CreatePrefabSkin("treasurechest_posh",
{
	base_prefab = "treasurechest",
	type = "item",
	assets = assets,
	build_name = "treasurechest_posh",
	rarity = "Distinguished",
	init_fn = function(inst) treasurechest_init_fn(inst, "treasurechest_posh") end,
	marketable = true,
	release_group = 19,
})
