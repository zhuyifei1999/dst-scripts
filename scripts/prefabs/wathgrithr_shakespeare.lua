local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wathgrithr_shakespeare.zip"),
	Asset("ANIM", "anim/ghost_wathgrithr_build.zip"),
}

local skins =
{
	normal_skin = "wathgrithr_shakespeare",
	ghost_skin = "ghost_wathgrithr_build",
}

local base_prefab = "wathgrithr"

local tags = {"WATHGRITHR", "CHARACTER"}

local ui_preview =
{
	build = "wathgrithr_shakespeare",
}


return CreatePrefabSkin("wathgrithr_shakespeare",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})