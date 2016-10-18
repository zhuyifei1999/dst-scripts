require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/strawhat_floppy.zip"),
}

local base_prefab = "strawhat"

local tags = {"STRAWHAT", "CRAFTABLE"}

local ui_preview =
{
	build = "strawhat_floppy",
}

return CreatePrefabSkin("strawhat_floppy",
{
	base_prefab = base_prefab,
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) hat_init_fn(inst, ui_preview.build) end,
	assets = assets,
	tags = tags,
	build_name = "strawhat_floppy",
	rarity = "Elegant",
})