local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/firepit_hole.zip"),
}

local base_prefab = "firepit"

local tags = {"FIREPIT", "CRAFTABLE"}

local ui_preview =
{
	build = "firepit_hole",
	bank = "firepit",
}

return CreatePrefabSkin("firepit_hole",
{
	base_prefab = base_prefab, 
	assets = assets,
	tags = tags,
	init_fn = function(inst) firepit_init_fn(inst, ui_preview.build, Vector3(0, 26, 0)) end,
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN_LOYAL",
	rarity = "Loyal",
})
