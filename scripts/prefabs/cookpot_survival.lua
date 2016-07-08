local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/cookpot_survival.zip"),
}

local base_prefab = "cookpot"

local tags = {"CROCKPOT", "CRAFTABLE", "SURVIVOR"}

-- TODO: maybe set a init_placer function?


local ui_preview =
{
	build = "cookpot_survival",
	bank = "cook_pot",
}

return CreatePrefabSkin("cookpot_survival",
{
	base_prefab = base_prefab, 
	assets = assets,
	tags = tags,
	init_fn = function(inst) cookpot_init_fn(inst, ui_preview.build) end,
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN",
	rarity = "Elegant",
})