local assets =
{
	Asset("ANIM", "anim/woodie.zip"),
	Asset("ANIM", "anim/ghost_woodie_build.zip"),
}

local skins =
{
	normal_skin = "woodie",
	ghost_skin = "ghost_woodie_build",
	werebeaver_skin = "werebeaver_build",
	ghost_werebeaver_skin = "ghost_werebeaver_build",
}

local base_prefab = "woodie"

local tags = {"WOODIE", "CHARACTER"}

return CreatePrefabSkin("woodie_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
	
	feet_cuff_size = { woodie = 3 },
	
	skip_item_gen = true,
	skip_giftable_gen = true,
})