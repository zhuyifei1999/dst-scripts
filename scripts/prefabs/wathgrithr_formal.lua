local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wathgrithr_formal.zip"),
	Asset("ANIM", "anim/ghost_wathgrithr_build.zip"),
}

local skins =
{
	normal_skin = "wathgrithr_formal",
	ghost_skin = "ghost_wathgrithr_build",
}

local base_prefab = "wathgrithr"

local tags = {"WATHGRITHR", "CHARACTER", "FORMAL"}

local ui_preview =
{
	build = "wathgrithr_formal",
}


return CreatePrefabSkin("wathgrithr_formal",
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