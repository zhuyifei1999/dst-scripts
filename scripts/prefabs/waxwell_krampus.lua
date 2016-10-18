local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/waxwell_krampus.zip"),
	Asset("ANIM", "anim/ghost_waxwell_build.zip"),
}

local skins =
{
	normal_skin = "waxwell_krampus",
	ghost_skin = "ghost_waxwell_build",
}

local base_prefab = "waxwell"

local tags = {"WAXWELL", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "waxwell_krampus",
}

return CreatePrefabSkin("waxwell_krampus",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})