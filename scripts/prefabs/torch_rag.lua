require("tuning")

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/swap_torch_rag.zip"),
}

local prefabs = { "torchfire_rag" }

local base_prefab = "torch"

local tags = {"TORCH", "CRAFTABLE", "SURVIVOR"}

local ui_preview =
{
	build = "swap_torch_rag",
}

return CreatePrefabSkin("torch_rag",
{
	base_prefab = base_prefab, 
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN",
	init_fn = function(inst) torch_init_fn(inst, ui_preview.build) end,
	assets = assets,
	prefabs = prefabs,
	fx_prefab = {"torchfire_rag"},
	tags = tags,
	build_name = "swap_torch_rag",
	rarity = "Elegant",
})