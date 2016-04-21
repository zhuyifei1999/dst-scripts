local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wilson_formal.zip"),
	Asset("ANIM", "anim/ghost_wilson_build.zip"),
}

local skins =
{
	normal_skin = "wilson_formal",
	ghost_skin = "ghost_wilson_build",
}

local base_prefab = "wilson"

local tags = {"WILSON", "CHARACTER", "FORMAL"}

local ui_preview =
{
	build = "wilson_formal",
}

return CreatePrefabSkin("wilson_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	rarity = "Elegant",
})