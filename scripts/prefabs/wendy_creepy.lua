local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wendy_creepy.zip"),
	Asset("ANIM", "anim/ghost_wendy_build.zip"),
}

local skins =
{
	normal_skin = "wendy_creepy",
	ghost_skin = "ghost_wendy_build",
}

local base_prefab = "wendy"

local tags = {"WENDY", "CHARACTER"}

local ui_preview =
{
	build = "wendy_creepy",
}

return CreatePrefabSkin("wendy_creepy",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	item_type = "RARE_CHARACTER_SKIN",
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})