local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wathgrithr_shadow.zip"),
	Asset("ANIM", "anim/ghost_wathgrithr_build.zip"),
}

local skins =
{
	normal_skin = "wathgrithr_shadow",
	ghost_skin = "ghost_wathgrithr_build",
}

local base_prefab = "wathgrithr"

local tags = {"WATHGRITHR", "CHARACTER"}

local ui_preview =
{
	build = "wathgrithr_shadow",
}


return CreatePrefabSkin("wathgrithr_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,

	rarity = "Elegant",
})