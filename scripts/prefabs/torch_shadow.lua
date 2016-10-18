require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_torch_shadow.zip"),
}

local prefabs = { "torchfire_shadow" }

local base_prefab = "torch"

local tags = {"TORCH", "CRAFTABLE", "SHADOW"}

local ui_preview =
{
	build = "swap_torch_shadow",
}

return CreatePrefabSkin("torch_shadow",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN_LOYAL",
	init_fn = function(inst) torch_init_fn(inst, ui_preview.build) end,
	assets = assets,
	prefabs = prefabs,
	fx_prefab = {"torchfire_shadow"},
	tags = tags,
	build_name = "swap_torch_shadow",
	rarity = "Loyal",
})