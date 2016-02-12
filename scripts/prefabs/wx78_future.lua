local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wx78_future.zip"),
	Asset("ANIM", "anim/ghost_wx78_build.zip"),
}

local skins =
{
	normal_skin = "wx78_future",
	ghost_skin = "ghost_wx78_build",
}

local base_prefab = "wx78"

local tags = {"WX78", "CHARACTER"}

local ui_preview =
{
	build = "wx78_future",
}

return CreatePrefabSkin("wx78_future",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})