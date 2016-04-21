local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/willow_formal.zip"),
	Asset("ANIM", "anim/ghost_willow_build.zip"),
}

local skins =
{
	normal_skin = "willow_formal",
	ghost_skin = "ghost_willow_build",
}

local base_prefab = "willow"

local tags = {"WILLOW", "CHARACTER", "FORMAL"}

local ui_preview =
{
	build = "willow_formal",
}

return CreatePrefabSkin("willow_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	--torso_tuck_builds = { "willow_formal" },
	
	rarity = "Elegant",
})