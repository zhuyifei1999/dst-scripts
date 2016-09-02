require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_camping_red_koalefant.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_mushy.zip"),
}

local base_prefab = "backpack"

local tags = {"BACKPACK", "CRAFTABLE"}

local ui_preview =
{
	build = "swap_backpack_camping_red_koalefant",
	bank = "swap_backpack_camping_red_koalefant",
}

return CreatePrefabSkin("backpack_camping_red_koalefant",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) backpack_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "swap_backpack_camping_red_koalefant",
	rarity = "Spiffy",
})