local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/willow_burnt.zip"),
	Asset("ANIM", "anim/ghost_willow_build.zip"),
}

local skins =
{
	normal_skin = "willow_burnt",
	ghost_skin = "ghost_willow_build",
}

local base_prefab = "willow"

local tags = {"WILLOW", "CHARACTER"}

local ui_preview =
{
	build = "willow_burnt",
}

return CreatePrefabSkin("willow_burnt",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})