require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/tophat_derby.zip"),
}

local base_prefab = "tophat"

local tags = {"TOPHAT", "CRAFTABLE"}

local ui_preview =
{
	build = "tophat_derby",
	bank = "tophat_derby",
}

return CreatePrefabSkin("tophat_derby",
{
	base_prefab = base_prefab,
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) hat_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "tophat_derby",
	rarity = "Elegant",
})