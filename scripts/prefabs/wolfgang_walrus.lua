local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_walrus.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_skinny_walrus.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_mighty_walrus.zip"),
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
}

local skins =
{
	wimpy_skin = "wolfgang_skinny_walrus",
	normal_skin = "wolfgang_walrus",
	mighty_skin = "wolfgang_mighty_walrus",
	ghost_skin = "ghost_wolfgang_build",
}

local base_prefab = "wolfgang"

local tags = {"WOLFGANG", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "wolfgang_walrus",
}

return CreatePrefabSkin("wolfgang_walrus",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})