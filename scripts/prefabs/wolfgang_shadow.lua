local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_shadow.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_skinny_shadow.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_mighty_shadow.zip"),
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
}

local skins =
{
	wimpy_skin = "wolfgang_skinny_shadow",
	normal_skin = "wolfgang_shadow",
	mighty_skin = "wolfgang_mighty_shadow",
	ghost_skin = "ghost_wolfgang_build",
}

local base_prefab = "wolfgang"

local tags = {"WOLFGANG", "CHARACTER"}

local ui_preview =
{
	build = "wolfgang_shadow",
}

return CreatePrefabSkin("wolfgang_shadow",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wolfgang_shadow", "wolfgang_skinny_shadow", "wolfgang_mighty_shadow" },
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})