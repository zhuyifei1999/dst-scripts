local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wilson_young.zip"),
	Asset("ANIM", "anim/ghost_wilson_build.zip"),
}

local skins =
{
	normal_skin = "wilson_young",
	ghost_skin = "ghost_wilson_build",
}

local base_prefab = "wilson"

local tags = {"WILSON", "CHARACTER"}

local ui_preview =
{
	build = "wilson_young",
}

return CreatePrefabSkin("wilson_young",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})