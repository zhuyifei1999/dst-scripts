local assets =
{
	Asset("ANIM", "anim/wilson.zip"),
	Asset("ANIM", "anim/ghost_wilson_build.zip"),
}

local skins =
{
	normal_skin = "wilson",
	ghost_skin = "ghost_wilson_build",
}

local base_prefab = "wilson"

local tags = {"WILSON", "CHARACTER"}

return CreatePrefabSkin("wilson_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
	
	skip_item_gen = true,
	skip_giftable_gen = true,
})