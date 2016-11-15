-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_mighty_shadow.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_shadow.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_skinny_shadow.zip"),
}

return CreatePrefabSkin("wolfgang_shadow",
{
	base_prefab = "wolfgang",
	type = "base",
	assets = assets,
	build_name = "wolfgang_shadow",
	rarity = "Elegant",
	skins = { ghost_skin = "ghost_wolfgang_build", mighty_skin = "wolfgang_mighty_shadow", normal_skin = "wolfgang_shadow", wimpy_skin = "wolfgang_skinny_shadow", },
	torso_tuck_builds = { "wolfgang_shadow", "wolfgang_skinny_shadow", "wolfgang_mighty_shadow", },
})
