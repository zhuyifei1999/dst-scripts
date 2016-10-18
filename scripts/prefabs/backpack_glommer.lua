require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_glommer.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_mushy.zip"),
}

local base_prefab = "backpack"

local tags = {"BACKPACK", "CRAFTABLE", "MERCH"}

local ui_preview =
{
	build = "swap_backpack_glommer",
}

return CreatePrefabSkin("backpack_glommer",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN_LOYAL",
	init_fn = function(inst) backpack_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "swap_backpack_glommer",
	rarity = "Loyal",
})