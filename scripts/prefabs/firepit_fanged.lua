local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/firepit_fanged.zip"),
}

local base_prefab = "firepit"

local tags = {"FIREPIT", "CRAFTABLE"}

local ui_preview =
{
	build = "firepit_fanged",
	bank = "firepit",
}

return CreatePrefabSkin("firepit_fanged",
{
	base_prefab = base_prefab, 
	assets = assets,
	tags = tags,
	init_fn = function(inst) firepit_init_fn(inst, ui_preview.build, Vector3(0, 20, 0)) end,
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN",
	rarity = "Distinguished",
})
