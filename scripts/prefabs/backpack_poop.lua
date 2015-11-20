require("tuning")

local assets =
{
	Asset("ANIM", "anim/swap_backpack_poop.zip"),
	Asset("ANIM", "anim/swap_backpack_mushy.zip"),
}

local base_prefab = "backpack"

local tags = {"BACKPACK", "CRAFTABLE"}

local ui_preview =
{
	build = "swap_backpack_poop",
	bank = "swap_backpack_poop",
}

return CreatePrefabSkin("backpack_poop",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN",
	init_fn = function(inst) backpack_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "swap_backpack_poop",
	rarity = "Elegant",
})