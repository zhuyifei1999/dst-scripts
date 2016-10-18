local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/wilson_pigguard.zip"),
	Asset("ANIM", "anim/ghost_wilson_build.zip"),
}

local skins =
{
	normal_skin = "wilson_pigguard",
	ghost_skin = "ghost_wilson_build",
}

local base_prefab = "wilson"

local tags = {"WILSON", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "wilson_pigguard",
}

return CreatePrefabSkin("wilson_pigguard",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	torso_tuck_builds = { "wilson_pigguard" },
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})