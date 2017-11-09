-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_wickerbottom_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wickerbottom_combatant.zip"),
}

return CreatePrefabSkin("wickerbottom_combatant",
{
	base_prefab = "wickerbottom",
	type = "base",
	assets = assets,
	build_name = "wickerbottom_combatant",
	rarity = "Event",
	skin_tags = { "LAVA", "BASE", "CHARACTER", "WICKERBOTTOM", },
	skins = { ghost_skin = "ghost_wickerbottom_build", normal_skin = "wickerbottom_combatant", },
	torso_tuck_builds = { "wickerbottom_combatant", },
	has_alternate_for_body = { "wickerbottom_combatant", },
	has_alternate_for_skirt = { "wickerbottom_combatant", },
	feet_cuff_size = { wickerbottom_combatant = 3, },
	release_group = 32,
})
