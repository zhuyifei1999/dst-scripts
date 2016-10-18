local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/treasurechest_poshprint.zip"),
}

local base_prefab = "treasurechest"

local tags = {"CHEST", "CRAFTABLE", "MERCH"}

local ui_preview =
{
	build = "treasurechest_poshprint",
}

return CreatePrefabSkin("treasurechest_poshprint",
{
	base_prefab = base_prefab, 
	assets = assets,
	tags = tags,
	init_fn = function(inst) chest_init_fn(inst, ui_preview.build) end,
	ui_preview = ui_preview,
	inheritance = "ITEM_SKIN_LOYAL",
	rarity = "Loyal",
})
