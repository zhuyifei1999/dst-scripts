local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/woodie_survivor.zip"),
	Asset("ANIM", "anim/ghost_woodie_build.zip"),
}

local skins =
{
	normal_skin = "woodie_survivor",
	ghost_skin = "ghost_woodie_build",
	werebeaver_skin = "werebeaver_build",
}

local base_prefab = "woodie"

local tags = {"WOODIE", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "woodie_survivor",
}

return CreatePrefabSkin("woodie_survivor",
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