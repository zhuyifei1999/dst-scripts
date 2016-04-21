local assets =
{
	Asset("ANIM", "anim/wolfgang.zip"),
	Asset("ANIM", "anim/wolfgang_mighty.zip"),
	Asset("ANIM", "anim/wolfgang_skinny.zip"),
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
}

local skins =
{
	wimpy_skin = "wolfgang_skinny",
	normal_skin = "wolfgang",
	mighty_skin = "wolfgang_mighty",
	ghost_skin = "ghost_wolfgang_build",
}

local base_prefab = "wolfgang"

local tags = {"WOLFGANG", "CHARACTER"}

return CreatePrefabSkin("wolfgang_none",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	tags = tags,
	
	torso_tuck_builds = { "wolfgang", "wolfgang_skinny", "wolfgang_mighty" },
})