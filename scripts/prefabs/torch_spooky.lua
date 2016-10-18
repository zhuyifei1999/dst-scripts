require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_torch_spooky.zip"),
}

local prefabs = { "torchfire_spooky" }

local base_prefab = "torch"

local tags = {"TORCH", "CRAFTABLE", "COSTUME"}

local ui_preview =
{
	build = "swap_torch_spooky",
}

return CreatePrefabSkin("torch_spooky",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) torch_init_fn(inst, ui_preview.build) end,
	assets = assets,
	prefabs = prefabs,
	fx_prefab = {"torchfire_spooky"},
	tags = tags,
	build_name = "swap_torch_spooky",
	rarity = "Elegant",
})