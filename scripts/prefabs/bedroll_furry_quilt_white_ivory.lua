require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_bedroll_furry_quilt_white_ivory.zip"),
}

local base_prefab = "bedroll_furry"

local tags = {"BEDROLL", "CRAFTABLE"}

local ui_preview =
{
	build = "swap_bedroll_furry_quilt_white_ivory",
}

return CreatePrefabSkin("bedroll_furry_quilt_white_ivory",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) bedroll_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "swap_bedroll_furry_quilt_white_ivory",
	rarity = "Distinguished",
})