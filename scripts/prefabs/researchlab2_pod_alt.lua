-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/researchlab2_pod_alt.zip"),
}

return CreatePrefabSkin("researchlab2_pod_alt",
{
	base_prefab = "researchlab2",
	type = "item",
	assets = assets,
	build_name = "researchlab2_pod_alt",
	rarity = "Elegant",
	rarity_modifier = "Lustrous",
	prefabs = { "researchlab2_pod_alt_fx", },
	init_fn = function(inst) researchlab2_init_fn(inst, "researchlab2_pod_alt") end,
	fx_prefab = { "researchlab2_pod_alt_fx", },
	marketable = true,
	release_group = 29,
})
