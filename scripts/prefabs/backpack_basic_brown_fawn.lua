require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_basic_brown_fawn.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_mushy.zip"),
}

local base_prefab = "backpack"

local tags = {"BACKPACK", "CRAFTABLE"}

local ui_preview =
{
	build = "swap_backpack_basic_brown_fawn",
	bank = "swap_backpack_basic_brown_fawn",
}

return CreatePrefabSkin("backpack_basic_brown_fawn",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN",
	init_fn = function(inst) backpack_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "swap_backpack_basic_brown_fawn",
	rarity = "Spiffy",
})