local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_survivor.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_skinny_survivor.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_mighty_survivor.zip"),
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
}

local skins =
{
	wimpy_skin = "wolfgang_skinny_survivor",
	normal_skin = "wolfgang_survivor",
	mighty_skin = "wolfgang_mighty_survivor",
	ghost_skin = "ghost_wolfgang_build",
}

local base_prefab = "wolfgang"

local tags = {"WOLFGANG", "CHARACTER", "SURVIVOR"}

local ui_preview =
{
	build = "wolfgang_survivor",
}

return CreatePrefabSkin("wolfgang_survivor",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wolfgang_survivor", "wolfgang_skinny_survivor", "wolfgang_mighty_survivor" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,

	rarity = "Elegant",
})