local assets =
{
	Asset("ANIM", "anim/wx78.zip"),
	Asset("ANIM", "anim/ghost_wx78_build.zip"),
}

local skins =
{
	normal_skin = "wx78",
	ghost_skin = "ghost_wx78_build",
}

local base_prefab = "wx78"

local tags = {"WX78", "CHARACTER"}

return CreatePrefabSkin("wx78_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
	
	torso_tuck_builds = { "wx78" },
	has_alternate_for_body = { "wx78" },
	
	skip_item_gen = true,
	skip_giftable_gen = true,
})