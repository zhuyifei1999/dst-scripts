-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/researchlab4_festive_bell_red_firehound.zip"),
}

return CreatePrefabSkin("researchlab4_festive_bell_red_firehound",
{
	base_prefab = "researchlab4",
	type = "item",
	assets = assets,
	build_name = "researchlab4_festive_bell_red_firehound",
	rarity = "Event",
	init_fn = function(inst) researchlab4_init_fn(inst, "researchlab4_festive_bell_red_firehound") end,
	release_group = 26,
})
