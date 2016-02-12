local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wendy_funeral.zip"),
	Asset("ANIM", "anim/ghost_wendy_build.zip"),
}

local skins =
{
	normal_skin = "wendy_funeral",
	ghost_skin = "ghost_wendy_build",
}

local base_prefab = "wendy"

local tags = {"WENDY", "CHARACTER"}

local ui_preview =
{
	build = "wendy_funeral",
}

return CreatePrefabSkin("wendy_funeral",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})