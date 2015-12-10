local assets =
{
	Asset("ANIM", "anim/wes.zip"),
	Asset("ANIM", "anim/ghost_wes_build.zip"),
}

local skins =
{
	normal_skin = "wes",
	ghost_skin = "ghost_wes_build",
}

local base_prefab = "wes"

local tags = {"WES", "CHARACTER"}

return CreatePrefabSkin("wes_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
	
	torso_tuck_builds = { "wes" },
	has_alternate_body = { "wes" },
	
	skip_item_gen = true,
	skip_giftable_gen = true,
})