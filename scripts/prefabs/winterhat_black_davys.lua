require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/winterhat_black_davys.zip"),
}

local base_prefab = "winterhat"

local tags = {"STRAWHAT", "CRAFTABLE", "MERCH"}

local ui_preview =
{
	build = "winterhat_black_davys",
}

return CreatePrefabSkin("winterhat_black_davys",
{
	base_prefab = base_prefab,
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN_LOYAL",
	init_fn = function(inst) hat_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "winterhat_black_davys",
	rarity = "Loyal",
})