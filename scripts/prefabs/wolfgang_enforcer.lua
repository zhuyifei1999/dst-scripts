local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_enforcer.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_skinny_enforcer.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_mighty_enforcer.zip"),
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
}

local skins =
{
	wimpy_skin = "wolfgang_skinny_enforcer",
	normal_skin = "wolfgang_enforcer",
	mighty_skin = "wolfgang_mighty_enforcer",
	ghost_skin = "ghost_wolfgang_build",
}

local base_prefab = "wolfgang"

local tags = {"WOLFGANG", "CHARACTER"}

local ui_preview =
{
	build = "wolfgang_enforcer",
}

return CreatePrefabSkin("wolfgang_enforcer",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	skip_item_gen = false,
	skip_giftable_gen = false,
})