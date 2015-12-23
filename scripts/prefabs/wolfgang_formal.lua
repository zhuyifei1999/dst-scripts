local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_formal.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_skinny_formal.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_mighty_formal.zip"),
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
}

local skins =
{
	wimpy_skin = "wolfgang_skinny_formal",
	normal_skin = "wolfgang_formal",
	mighty_skin = "wolfgang_mighty_formal",
	ghost_skin = "ghost_wolfgang_build",
}

local base_prefab = "wolfgang"

local tags = {"WOLFGANG", "CHARACTER"}

local ui_preview =
{
	build = "wolfgang_formal",
}

return CreatePrefabSkin("wolfgang_formal",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wolfgang_formal", "wolfgang_skinny_formal", "wolfgang_mighty_formal" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
	
	rarity = "Elegant",
})