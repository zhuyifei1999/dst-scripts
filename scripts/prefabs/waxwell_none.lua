local assets =
{
	Asset("ANIM", "anim/waxwell.zip"),
	Asset("ANIM", "anim/ghost_waxwell_build.zip"),
}

local skins =
{
	normal_skin = "waxwell",
	ghost_skin = "ghost_waxwell_build",
}

local base_prefab = "waxwell"

local tags = {"WAXWELL", "CHARACTER"}

return CreatePrefabSkin("waxwell_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
	
	torso_untuck_builds = {"waxwell"},
})