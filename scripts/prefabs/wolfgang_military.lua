local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_skinny_military.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_military.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_mighty_military.zip"),
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
}

local skins =
{
	wimpy_skin = "wolfgang_skinny_military",
	normal_skin = "wolfgang_military",
	mighty_skin = "wolfgang_mighty_military",
	ghost_skin = "ghost_wolfgang_build",
}

local base_prefab = "wolfgang"

local tags = {"WOLFGANG", "CHARACTER"}

local ui_preview =
{
	build = "wolfgang_military",
}

return CreatePrefabSkin("wolfgang_military",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})