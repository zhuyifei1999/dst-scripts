local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/woodie_treeguard.zip"),
	Asset("ANIM", "anim/ghost_woodie_build.zip"),
}

local skins =
{
	normal_skin = "woodie_treeguard",
	ghost_skin = "ghost_woodie_build",
	werebeaver_skin = "werebeaver_build",
	ghost_werebeaver_skin = "ghost_werebeaver_build",
}

local base_prefab = "woodie"

local tags = {"WOODIE", "CHARACTER", "COSTUME"}

local ui_preview =
{
	build = "woodie_treeguard",
}

return CreatePrefabSkin("woodie_treeguard",
{
	base_prefab = base_prefab, 
	skins = skins, 
	assets = assets,
	ui_preview = ui_preview,
	tags = tags,
	
	inheritance = "CHARACTER_SKIN_NO_MARKET",
	rarity = "Event",
})