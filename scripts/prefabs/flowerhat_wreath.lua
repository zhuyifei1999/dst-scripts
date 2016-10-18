require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/flowerhat_wreath.zip"),
}

local base_prefab = "flowerhat"

local tags = {"FLOWERHAT", "CRAFTABLE"}

local ui_preview =
{
	build = "flowerhat_wreath",
	bank = "flowerhat_wreath",
}

return CreatePrefabSkin("flowerhat_wreath",
{
	base_prefab = base_prefab,
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) hat_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "flowerhat_wreath",
	rarity = "Elegant",
})