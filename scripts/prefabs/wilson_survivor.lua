local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wilson_survivor.zip"),
	Asset("ANIM", "anim/ghost_wilson_build.zip"),
}

local skins =
{
	normal_skin = "wilson_survivor",
	ghost_skin = "ghost_wilson_build",
}

local base_prefab = "wilson"

local tags = {"WILSON", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "wilson_survivor",
}

return CreatePrefabSkin("wilson_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,

	rarity = "Elegant",
})