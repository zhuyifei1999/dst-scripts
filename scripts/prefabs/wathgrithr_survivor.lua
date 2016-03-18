local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wathgrithr_survivor.zip"),
	Asset("ANIM", "anim/ghost_wathgrithr_build.zip"),
}

local skins =
{
	normal_skin = "wathgrithr_survivor",
	ghost_skin = "ghost_wathgrithr_build",
}

local base_prefab = "wathgrithr"

local tags = {"WATHGRITHR", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "wathgrithr_survivor",
}


return CreatePrefabSkin("wathgrithr_survivor",
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