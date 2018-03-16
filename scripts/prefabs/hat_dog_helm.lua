-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/hat_dog_helm.zip"),
}

return CreatePrefabSkin("hat_dog_helm",
{
	base_prefab = "footballhat",
	type = "item",
	assets = assets,
	build_name = "hat_dog_helm",
	rarity = "Elegant",
	rarity_modifier = "Seasonal",
	init_fn = function(inst) footballhat_init_fn(inst, "hat_dog_helm") end,
	skin_tags = { "FOOTBALLHAT", "VARG", "CRAFTABLE", },
	release_group = 40,
})