require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_moosegoose.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_backpack_mushy.zip"),
}

local base_prefab = "backpack"

local tags = {"BACKPACK", "CRAFTABLE"}

local ui_preview =
{
	build = "swap_backpack_moosegoose",
	bank = "swap_backpack_moosegoose",
}

return CreatePrefabSkin("backpack_moosegoose_loyal",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN_LOYAL",
	init_fn = function(inst) backpack_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "swap_backpack_moosegoose",
	rarity = "Loyal",
	
	skip_giftable_gen = true,
})