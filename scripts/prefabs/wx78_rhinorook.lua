local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wx78_rhinorook.zip"),
	Asset("ANIM", "anim/ghost_wx78_build.zip"),
}

local skins =
{
	normal_skin = "wx78_rhinorook",
	ghost_skin = "ghost_wx78_build",
}

local base_prefab = "wx78"

local tags = {"WX78", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "wx78_rhinorook",
}


return CreatePrefabSkin("wx78_rhinorook",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	feet_cuff_size = { wx78_rhinorook = 10 },
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})