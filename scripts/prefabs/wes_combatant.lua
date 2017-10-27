-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_wes_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wes_combatant.zip"),
}

return CreatePrefabSkin("wes_combatant",
{
	base_prefab = "wes",
	type = "base",
	assets = assets,
	build_name = "wes_combatant",
	rarity = "Event",
	skin_tags = { "LAVA", "BASE", "CHARACTER", "WES", },
	skins = { ghost_skin = "ghost_wes_build", normal_skin = "wes_combatant", },
	torso_tuck_builds = { "wes_combatant", },
	has_alternate_for_body = { "wes_combatant", },
	has_alternate_for_skirt = { "wes_combatant", },
	release_group = 32,
})
