-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/flowerhat_holly_wreath.zip"),
}

return CreatePrefabSkin("flowerhat_holly_wreath",
{
	base_prefab = "flowerhat",
	type = "item",
	assets = assets,
	build_name = "flowerhat_holly_wreath",
	rarity = "Spiffy",
	init_fn = function(inst) flowerhat_init_fn(inst, "flowerhat_holly_wreath") end,
})
