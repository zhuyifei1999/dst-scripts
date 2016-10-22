require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/winterhat_pink_hibiscus.zip"),
}

local base_prefab = "winterhat"

local tags = {"WINTERHAT", "CRAFTABLE", "MERCH"}

local ui_preview =
{
	build = "winterhat_pink_hibiscus",
}

return CreatePrefabSkin("winterhat_pink_hibiscus",
{
	base_prefab = base_prefab,
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN_LOYAL",
	init_fn = function(inst) hat_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "winterhat_pink_hibiscus",
	rarity = "Loyal",
})