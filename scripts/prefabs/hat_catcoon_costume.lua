require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/hat_catcoon_costume.zip"),
}

local base_prefab = "tophat"

local tags = {"TOPHAT", "CRAFTABLE", "COSTUME"}

local ui_preview =
{
	build = "hat_catcoon_costume",
}

return CreatePrefabSkin("hat_catcoon_costume",
{
	base_prefab = base_prefab,
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) hat_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "hat_catcoon_costume",
	rarity = "Elegant",
})