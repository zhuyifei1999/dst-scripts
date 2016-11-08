require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_spear_bee.zip"),
}


local base_prefab = "spear"

local tags = {"SPEAR", "CRAFTABLE"}

local ui_preview =
{
	build = "swap_spear_bee",
}

return CreatePrefabSkin("spear_bee",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) spear_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "swap_spear_bee",
	rarity = "Elegant",
})